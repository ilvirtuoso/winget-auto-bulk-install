# =========================================
# WINGET VIRTUOSO BULK PROGRAM INSTALLER
# =========================================

function Show-Progress {
    param (
        [int]$current,
        [int]$total,
        [string]$message
    )

    $percent = [math]::Floor(($current / $total) * 100)
    $barLength = 30
    $filled = [math]::Floor(($percent / 100) * $barLength)
    $empty = $barLength - $filled

    $bar = ("█" * $filled) + ("░" * $empty)

    Write-Host "`r[$bar] $percent%  -  $message" -ForegroundColor Green -NoNewline
}

Write-Host "=== Silent Bulk Installation Started ===" -ForegroundColor Cyan

# Log
$logPath = "$PSScriptRoot\install_log.txt"
"Installation Log - $(Get-Date)" | Out-File $logPath -Encoding utf8 -Force


# ======================================================
# PROGRAM LİSTESİ
# ======================================================
$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Discord.Discord",
    "Valve.Steam",
    "Microsoft.VisualStudioCode",
    "Python.Python.3",
    "Rustlang.Rustup",
    "RARLab.WinRAR",
    "GoLang.Go",
    "OpenJS.NodeJS",
    "Oracle.JavaRuntimeEnvironment",
    "Notepad++.Notepad++",
    "OBSProject.OBSStudio",
    "TeamSpeakSystems.TeamSpeakClient",
    "voidtools.Everything",
    "SteelSeries.GG",
    "ArthurLiberman.CoreTemp",
    "ProtonTechnologies.ProtonVPN",
    "EpicGames.EpicGamesLauncher",
    "7zip.7zip",
    "M2Team.NanaZip",
    "Spotify.Spotify",
    "WinSCP.WinSCP",
    "DuckTeam.DuckDNS",
    "Tonec.InternetDownloadManager",
    "VideoLAN.VLC",
    "PuTTY.PuTTY",
    "LogMeIn.Hamachi",
    "Famatech.RadminVPN",
    "CPUID.CPU-Z",
    "PrismLauncher.PrismLauncher",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "RustDesk.RustDesk"
)


$totalSteps = $apps.Count + 4   # programs + update + gpu detect + driver install
$currentStep = 0


# ======================================================
# PROGRAM KURULUMU
# ======================================================
foreach ($app in $apps) {
    $currentStep++
    Show-Progress -current $currentStep -total $totalSteps -message "Installing $app"

    try {
        winget install --id $app --silent --disable-interactivity --accept-package-agreements --accept-source-agreements -h
        "[$(Get-Date)] SUCCESS: $app installed" | Out-File $logPath -Append
    } catch {
        "[$(Get-Date)] ERROR installing $app" | Out-File $logPath -Append
    }
}


# ======================================================
# AUTO UPDATE
# ======================================================
$currentStep++
Show-Progress -current $currentStep -total $totalSteps -message "Running auto-update..."

try {
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    "[$(Get-Date)] Auto-update completed." | Out-File $logPath -Append
} catch {
    "[$(Get-Date)] Auto-update FAILED." | Out-File $logPath -Append
}


# ======================================================
# GPU TESPİT
# ======================================================
$currentStep++
Show-Progress -current $currentStep -total $totalSteps -message "Detecting GPU..."

$gpu = (Get-WmiObject Win32_VideoController).Name
"[$(Get-Date)] GPU: $gpu" | Out-File $logPath -Append


# ======================================================
# NVIDIA DRIVER
# ======================================================
if ($gpu -match "NVIDIA") {
    $currentStep++
    Show-Progress -current $currentStep -total $totalSteps -message "Installing NVIDIA driver..."

    $driverURL = "https://us.download.nvidia.com/Windows/551.86/551.86-desktop-win10-win11-64bit-international-dch-whql.exe"
    $driverPath = "$env:TEMP\nvidia_driver.exe"

    Invoke-WebRequest -Uri $driverURL -OutFile $driverPath
    Start-Process $driverPath -ArgumentList "-s" -Wait

    "[$(Get-Date)] NVIDIA driver installed." | Out-File $logPath -Append
}


# ======================================================
# AMD DRIVER
# ======================================================
elseif ($gpu -match "AMD" -or $gpu -match "Radeon") {
    $currentStep++
    Show-Progress -current $currentStep -total $totalSteps -message "Installing AMD driver..."

    $driverURL = "https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-24.1.1-win10-win11-64bit.exe"
    $driverPath = "$env:TEMP\amd_driver.exe"

    Invoke-WebRequest -Uri $driverURL -OutFile $driverPath
    Start-Process $driverPath -ArgumentList "-INSTALL -AUTO -QUIET" -Wait

    "[$(Get-Date)] AMD driver installed." | Out-File $logPath -Append
}

else {
    $currentStep++
    Show-Progress -current $currentStep -total $totalSteps -message "GPU not supported."
    "[$(Get-Date)] GPU NOT IDENTIFIED" | Out-File $logPath -Append
}


Write-Host "`n`n=== All tasks completed ===" -ForegroundColor Green
Write-Host "Log saved to: $logPath"
