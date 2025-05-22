param (
    [string]$Config = "C:\AtomicRedTeam\config.json",
    [switch]$CheckPrereqs
)

# Ensure script stops on error
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

# --- 5. Process Test CSV ---
$tests = Import-Csv $csvPath
Invoke-AtomicTest T1204.002  -TestNumbers 8

foreach ($test in $tests) {
    $technique = $test.Technique
    $testNumbers = $test.TestNumbers -split ',' | ForEach-Object { $_.Trim() }
    $requiresAdmin = ($test.Admin -eq "1")
    $sleepSeconds = [int]$test.Sleep
    $desc = $test.Description

    Log-Message "Atomic $technique - Test(s) $testNumbers started: $desc"

    if ($requiresAdmin -and -not $IsAdmin) {
        Log-Message "Skipped $technique - Admin required but not available."
        continue
    }

    try {
        if ($CheckPrereqs) {
            Write-Host "`nChecking prerequisites for $technique (Test $testNumbers)..." -ForegroundColor Yellow
            Invoke-AtomicTest $technique -TestNumbers $testNumbers -CheckPrereqs
        } else {
            Invoke-AtomicTest $technique -TestNumbers $testNumbers -GetPrereq
            Invoke-AtomicTest $technique -TestNumbers $testNumbers -InputArgs $myArgs *>&1 | Out-File -FilePath $debugLogPath -Append
            Invoke-AtomicTest $technique -TestNumbers $testNumbers -Cleanup
        }
        Log-Message "Atomic $technique - Test(s) $testNumbers finished successfully."
    } catch {
        Log-Message "ERROR during $technique Test ${testNumbers}: $_"
    }

    Start-Sleep -Seconds $sleepSeconds
}
