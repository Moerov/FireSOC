param (
    [string]$Config = "C:\AtomicRedTeam\config.json",
    [switch]$CheckPrereqs
)

# --- Proxy Configuration ---
$useProxy = $false
$proxyUrl = "http://proxy.yourcompany.local:8080"

if ($useProxy) {
    Write-Host "[*] Proxy is enabled: $proxyUrl"
    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxyUrl, "Process")
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyUrl, "Process")
    netsh winhttp set proxy $proxyUrl | Out-Null
} else {
    Write-Host "[*] Proxy is disabled"
}

$webParams = @{}
if ($useProxy) {
    $webParams["Proxy"] = $proxyUrl
}

$ErrorActionPreference = "Stop"

# --- Helper Functions ---
function Is-Admin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Pause-WithMessage($msg) {
    Write-Host $msg -ForegroundColor Cyan
    Read-Host "Press any key to continue"
}

function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "${timestamp}: $Message"
}

# --- 1. Install Execution Framework ---
IEX (Invoke-WebRequest 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -InstallPath "C:\AtomicRedTeam" -Force

# --- 2. Admin Check ---
$IsAdmin = Is-Admin
if ($IsAdmin) {
    Pause-WithMessage "Admin shell is detected. Tests requiring admin will be executed."
} else {
    Pause-WithMessage "Non-admin shell detected. Tests requiring admin will NOT be executed."
}

# --- 3. EDR Warning ---
Pause-WithMessage "Please make sure your EDR is NOT in blocking mode and C:\AtomicRedTeam is whitelisted."

# --- 4. Load Config ---
$configData = Get-Content $Config | ConvertFrom-Json
$logPath = $configData.log_path
$debugLogPath = $configData.debug_log_path
$csvPath = $configData.csv_path

$myArgs = @{}
foreach ($key in $configData.test_params.PSObject.Properties.Name) {
    $myArgs[$key] = $configData.test_params.$key
}

### CSV LOGGING: Prepare result CSV
$scriptStartTime = Get-Date
$timestamp = $scriptStartTime.ToString("yyyy-MM-dd_HH-mm-ss")
$resultsCsvPath = "C:\AtomicRedTeam\${timestamp}_results.csv"
"Description,Technique,TestNumber,Admin,StartTime,EndTime,Command,Result" | Out-File -FilePath $resultsCsvPath -Encoding UTF8

# --- 5. Process Test CSV ---
$tests = Import-Csv $csvPath

foreach ($test in $tests) {
    $technique = $test.Technique
    $testNumber = $test.TestNumbers.Trim()
    $requiresAdmin = ($test.Admin -eq "1")
    $sleepSeconds = [int]$test.Sleep
    $desc = $test.Description

    Log-Message "Atomic $technique - Test $testNumber started: $desc"

    if ($requiresAdmin -and -not $IsAdmin) {
        Log-Message "Skipped $technique - Admin required but not available."
        continue
    }

    $startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $command = "Invoke-AtomicTest $technique -TestNumbers $testNumber -InputArgs `$myArgs"

    try {
        if ($CheckPrereqs) {
            Write-Host "`nChecking prerequisites for $technique (Test $testNumber)..." -ForegroundColor Yellow
            Invoke-AtomicTest $technique -TestNumbers $testNumber -CheckPrereqs
        } else {
            Invoke-AtomicTest $technique -TestNumbers $testNumber -GetPrereq
            Invoke-AtomicTest $technique -TestNumbers $testNumber -InputArgs $myArgs *>&1 | Out-File -FilePath $debugLogPath -Append
            Invoke-AtomicTest $technique -TestNumbers $testNumber -Cleanup
        }
        Log-Message "Atomic $technique - Test $testNumber finished successfully."
    } catch {
        Log-Message "ERROR during $technique Test ${testNumber}: $_"
    }

    $endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    ### CSV LOGGING: Append result
    $line = '"{0}","{1}","{2}","{3}","{4}","{5}","{6}","{7}"' -f `
        $desc, $technique, $testNumber, $requiresAdmin, $startTime, $endTime, $command, "TBD"
    Add-Content -Path $resultsCsvPath -Value $line

    Start-Sleep -Seconds $sleepSeconds
}
