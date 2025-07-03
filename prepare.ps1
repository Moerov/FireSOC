# ─── CONFIGURATION ──────────────────────────────────────────────────────────────
$useProxy = $false # Change if needed
$proxyUrl = "http://proxy.company.local:8080"  # Change if needed

if ($useProxy) {
    Write-Host "[*] Proxy is set to $proxyUrl"
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
} else {
    Write-Host "[*] No proxy used."
    Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue
}

# ─── STEP 1: Create Working Directory ───────────────────────────────────────────
$targetPath = "C:\AtomicRedTeam"
if (-Not (Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force
    Write-Host "Created directory: $targetPath"
} else {
    Write-Host "Directory already exists: $targetPath"
}

# ─── STEP 2: User Prompt ────────────────────────────────────────────────────────
Write-Host "`nPlease whitelist the directory '$targetPath' (e.g. in AV/EDR settings)."
Read-Host -Prompt "Press any key to continue after whitelisting"

# ─── STEP 3: Download FireSOC-main.zip ──────────────────────────────────────────
$zipUrl = "https://github.com/Moerov/FireSOC/archive/refs/heads/main.zip"
$zipPath = Join-Path $targetPath "FireSOC-main.zip"
Write-Host "Downloading FireSOC-main.zip..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseDefaultCredentials

# ─── STEP 4: Extract FireSOC ────────────────────────────────────────────────────
$tempExtractPath = Join-Path $targetPath "TempExtract"
Expand-Archive -Path $zipPath -DestinationPath $tempExtractPath -Force

$extractedMainFolder = Join-Path $tempExtractPath "FireSOC-main"
Write-Host "Moving extracted files to $targetPath..."
Get-ChildItem -Path $extractedMainFolder | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $targetPath -Force
}

Remove-Item -Path $zipPath -Force
Remove-Item -Path $tempExtractPath -Recurse -Force

# ─── STEP 5: Download Portable 7-Zip ────────────────────────────────────────────
$sevenZipUrl = "https://www.7-zip.org/a/7za920.zip"
$sevenZipZipPath = Join-Path $targetPath "7za.zip"
$sevenZipExePath = Join-Path $targetPath "7za.exe"

if (-Not (Test-Path $sevenZipExePath)) {
    Write-Host "Downloading 7za.zip..."
    Invoke-WebRequest -Uri $sevenZipUrl -OutFile $sevenZipZipPath -UseDefaultCredentials
    Expand-Archive -Path $sevenZipZipPath -DestinationPath $targetPath -Force
    Remove-Item -Path $sevenZipZipPath -Force
}

# ─── STEP 6: Extract Protected ZIPs ─────────────────────────────────────────────
$utilsZip = Join-Path $targetPath "utils.zip"
$utilsOut = Join-Path $targetPath "utils"
$extZip = Join-Path $targetPath "ExternalPayloads.zip"
$extOut = Join-Path $targetPath "ExternalPayloads"

if (-Not (Test-Path $utilsOut)) { New-Item -ItemType Directory -Path $utilsOut | Out-Null }
if (-Not (Test-Path $extOut)) { New-Item -ItemType Directory -Path $extOut | Out-Null }

if (Test-Path $utilsZip) {
    & $sevenZipExePath x $utilsZip "-o$utilsOut" -p"nevermind" -y | Out-Null
    Write-Host "Extracted utils.zip"
} else {
    Write-Warning "utils.zip not found!"
}

if (Test-Path $extZip) {
    & $sevenZipExePath x $extZip "-o$extOut" -p"nevermind" -y | Out-Null
    Write-Host "Extracted ExternalPayloads.zip"
} else {
    Write-Warning "ExternalPayloads.zip not found!"
}

# ─── STEP 7: Cleanup ──────────────────────────────────────────────────────────────
$filesToDelete = @("readme.txt", "license.txt", "7-zip.chm", "7za.exe")

foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $targetPath $file
    if (Test-Path $fullPath) {
        Remove-Item $fullPath -Force
        Write-Host "Deleted: $fullPath"
    } else {
        Write-Host "Not found: $fullPath"
    }
}

Write-Host "`n✅ Setup complete!"
