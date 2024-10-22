# Define the current version number
$versionNumber = 4

# Get the current timestamp
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))

# Define the URLs for version checking and script update with the timestamp as a parameter
$versionUrl = "https://raw.githubusercontent.com/adi6409/wallpaperchanger/refs/heads/main/latestVersion.txt?timestamp=$timestamp"
$scriptUrl = "https://raw.githubusercontent.com/adi6409/wallpaperchanger/refs/heads/main/ChangeWallpaper.ps1?timestamp=$timestamp"
$localScriptPath = $MyInvocation.MyCommand.Definition

# Check for the latest version
try {
    $latestVersion = Invoke-RestMethod -Uri $versionUrl
    Write-Output "Latest version available: $latestVersion"
    
    # Compare versions and update if necessary
    if ([int]$latestVersion -gt $versionNumber) {
        Write-Output "A newer version is available. Updating the script..."
        
        # Download the updated script
        Invoke-WebRequest -Uri $scriptUrl -OutFile $localScriptPath -UseBasicParsing
        
        Write-Output "Script updated. Restarting..."
        
        # Rerun the updated script
        & $localScriptPath
        exit
    } else {
        Write-Output "The script is up to date."
    }
} catch {
    Write-Output "Failed to check for the latest version: $_"
}

# Get the path of the script and cd to the folder containing the wallpapers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -Path $scriptPath
$wallpaperFolder = $scriptPath

# Path to store the last used wallpaper
$lastWallpaperPath = "$wallpaperFolder\lastWallpaper.txt"

# List all the files in the folder
$Files = Get-ChildItem -Path $wallpaperFolder
# Get all image files from the folder
$wallpapers = Get-ChildItem -Path $wallpaperFolder -Filter "*.jpg" -File
$wallpapers += Get-ChildItem -Path $wallpaperFolder -Filter "*.jpeg" -File
$wallpapers += Get-ChildItem -Path $wallpaperFolder -Filter "*.png" -File
$wallpapers += Get-ChildItem -Path $wallpaperFolder -Filter "*.bmp" -File

# Exit if no wallpapers found
if ($wallpapers.Count -eq 0) {
    Write-Output "ERR_NO_FILES_FOUND"
    exit 1
}

# Read the last used wallpaper if it exists
$lastWallpaper = if (Test-Path $lastWallpaperPath) { Get-Content -Path $lastWallpaperPath } else { "" }

# Filter out the last used wallpaper from the list, if there are other options
if ($wallpapers.Count -gt 1 -and $lastWallpaper -ne "") {
    $wallpapers = $wallpapers | Where-Object { $_.FullName -ne $lastWallpaper }
}

# Pick a random wallpaper
$randomWallpaper = $wallpapers | Get-Random

# Save the selected wallpaper as the last used wallpaper
Set-Content -Path $lastWallpaperPath -Value $randomWallpaper.FullName

# Set the wallpaper
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@

# Set the wallpaper using the SystemParametersInfo function
$SPI_SETDESKWALLPAPER = 0x0014
$UPDATE_INI_FILE = 0x01
$SEND_CHANGE = 0x02
[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $randomWallpaper.FullName, $UPDATE_INI_FILE -bor $SEND_CHANGE)

Write-Output "OK_CODE_SUCCESS"
