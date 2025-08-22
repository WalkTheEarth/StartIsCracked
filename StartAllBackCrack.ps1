# PowerShell script to replace StartAllBackX64.dll with self-elevation

param(
    [string]$TargetDirectory = "C:\Program Files\StartAllBack",
    [string]$DownloadUrl = "https://github.com/WalkTheEarth/StartIsCracked/raw/refs/heads/main/StartAllBackX64.dll"
)

# Self-elevation function
function Elevate-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Elevating to administrator privileges..." -ForegroundColor Yellow
        
        # Restart script with elevated privileges
        $arguments = "-File `"$($MyInvocation.MyCommand.Path)`" -TargetDirectory `"$TargetDirectory`" -DownloadUrl `"$DownloadUrl`""
        Start-Process PowerShell.exe -ArgumentList $arguments -Verb RunAs -Wait
        
        # Exit current non-elevated instance
        exit
    }
}

# Elevate to admin if not already
Elevate-Admin

# Function to restart Explorer
function Restart-Explorer {
    Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
    try {
        # Get explorer process info before stopping
        $explorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        # Restart explorer
        Start-Process "explorer.exe"
        Write-Host "Explorer restarted successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error restarting explorer: $($_.Exception.Message)" -ForegroundColor Red
        # Try to restart explorer anyway as a fallback
        try {
            Start-Process "explorer.exe"
            Write-Host "Fallback: Explorer started." -ForegroundColor Yellow
        }
        catch {
            Write-Host "Critical: Could not restart explorer. You may need to restart manually." -ForegroundColor Red
        }
    }
}

# Function to download file
function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Host "Downloading file from $Url..." -ForegroundColor Yellow
        
        # Use different methods for compatibility
        try {
            # Method 1: Invoke-WebRequest (modern PowerShell)
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -ErrorAction Stop
        }
        catch {
            # Method 2: WebClient (older PowerShell compatibility)
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutputPath)
        }
        
        Write-Host "Download completed successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main script execution
try {
    Write-Host "=== StartAllBack DLL Replacement Script ===" -ForegroundColor Cyan
    Write-Host "Running with administrator privileges..." -ForegroundColor Green
    
    # Set target file paths
    $originalFile = Join-Path $TargetDirectory "StartAllBackX64.dll"
    $backupFile = Join-Path $TargetDirectory "StartAllBackX64.dll.bak"
    $newFile = Join-Path $TargetDirectory "StartAllBackX64.dll"

    # Check if target directory exists
    if (-not (Test-Path $TargetDirectory)) {
        Write-Host "Target directory does not exist: $TargetDirectory" -ForegroundColor Red
        Write-Host "Creating directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
    }

    Write-Host "Working in directory: $TargetDirectory" -ForegroundColor Yellow

    # Check if original file exists and create backup
    if (Test-Path $originalFile) {
        Write-Host "Found original file. Creating backup..." -ForegroundColor Yellow
        Rename-Item -Path $originalFile -NewName "StartAllBackX64.dll.bak" -Force
        Write-Host "Backup created: $backupFile" -ForegroundColor Green
    }
    else {
        Write-Host "Original file not found: $originalFile" -ForegroundColor Yellow
        Write-Host "Proceeding with download only..." -ForegroundColor Yellow
    }

    # Download new file
    Write-Host "Starting download process..." -ForegroundColor Yellow
    $downloadSuccess = Download-File -Url $DownloadUrl -OutputPath $newFile
    
    if ($downloadSuccess) {
        # Verify the new file was downloaded
        if (Test-Path $newFile) {
            Write-Host "New file successfully placed: $newFile" -ForegroundColor Green
            
            # Verify file properties
            $fileInfo = Get-Item $newFile
            Write-Host "File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
            
            # Basic verification that it's a DLL file
            if ($fileInfo.Extension -eq ".dll") {
                Write-Host "File verification passed - appears to be a valid DLL." -ForegroundColor Green
                
                # Add a small delay before restarting explorer
                Write-Host "Waiting 3 seconds before restarting explorer..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
                
                # Restart Explorer
                Restart-Explorer
            }
            else {
                Write-Host "Warning: Downloaded file doesn't have .dll extension" -ForegroundColor Yellow
                Write-Host "File extension: $($fileInfo.Extension)" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "Error: New file was not created successfully" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Operation failed during download." -ForegroundColor Red
        # If we created a backup but download failed, restore the backup?
        if (Test-Path $backupFile) {
            $choice = Read-Host "Download failed. Restore backup? (y/n)"
            if ($choice -eq 'y') {
                Rename-Item -Path $backupFile -NewName "StartAllBackX64.dll" -Force
                Write-Host "Backup restored." -ForegroundColor Green
            }
        }
    }
}
catch {
    Write-Host "An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.ScriptStackTrace)" -ForegroundColor Gray
}

Write-Host "`nScript execution completed." -ForegroundColor Cyan
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")