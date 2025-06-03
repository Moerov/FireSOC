# Ransomware Simulation Script - Safe for SOC Testing

# Target extensions to simulate ransomware impact
$extensions = @("*.txt", "*.doc", "*.png", "*.xlsx", "*.docx", "*.md")

# Destination folder for simulation
$destRoot = "C:\RansomwareTest"

# Create the destination directory
if (-not (Test-Path $destRoot)) {
    New-Item -ItemType Directory -Path $destRoot | Out-Null
}

# Define where to search (user folders)
$searchPaths = @("C:\Users\", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop")

foreach ($ext in $extensions) {
    foreach ($path in $searchPaths) {
        Get-ChildItem -Path $path -Filter $ext -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $source = $_.FullName
                $relativePath = $_.FullName.Replace(":", "").Replace("\", "_")
                $destination = Join-Path -Path $destRoot -ChildPath $relativePath
                Copy-Item -Path $source -Destination $destination -Force

                # Simulate encryption for .txt files by renaming and replacing contents
                if ($_.Extension -eq ".txt") {
                    $lockedPath = "$destination.locked"
                    Rename-Item -Path $destination -NewName ($lockedPath | Split-Path -Leaf)
                    Set-Content -Path $lockedPath -Value @"
!!! Your Files Have Been Simulated !!!
This is a ransomware simulation for SOC detection testing.
No real data was encrypted.
"@
                }

            } catch {
                Write-Warning "Failed to process $_.FullName - $_"
            }
        }
    }
}

Write-Host "`nSimulation completed. Files copied to: $destRoot" -ForegroundColor Green
