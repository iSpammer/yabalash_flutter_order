# PowerShell Script to help resolve "flutter: The term 'flutter' is not recognized..."
#
# How this script works:
# 1. Defines common locations where Flutter SDK might be installed.
# 2. Checks if Flutter is already in the PATH.
# 3. If not, it searches for Flutter in the common locations.
# 4. If Flutter is found, it temporarily adds its 'bin' directory to the PATH for the current session.
# 5. It then tries to run 'flutter --version' to test.
# 6. Finally, it provides instructions on how to add Flutter to the PATH permanently.

Write-Host "Attempting to find Flutter SDK and add it to your PATH for this session..."
Write-Host "-----------------------------------------------------------------------"

# --- Configuration: Common Flutter Installation Paths ---
# Add any other paths where you might have installed Flutter
$commonFlutterPaths = @(
    "$env:USERPROFILE\flutter",
    "$env:USERPROFILE\scoop\apps\flutter\current", # Common if installed via Scoop
    "$env:USERPROFILE\dev\flutter",
    "C:\flutter",
    "C:\src\flutter",
    "$env:ProgramData\flutter",
    "$env:ProgramFiles\flutter"
)

# --- Check if Flutter is already in PATH ---
$flutterInPath = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterInPath) {
    Write-Host -ForegroundColor Green "Flutter is already found in your PATH."
    Write-Host "Current Flutter version:"
    flutter --version
    Write-Host "You should be able to run 'flutter run -d emulator-5556' now."
    exit 0
}

# --- Search for Flutter SDK ---
$flutterPath = $null
Write-Host "Searching for Flutter SDK in common locations..."

foreach ($path in $commonFlutterPaths) {
    $potentialFlutterBin = Join-Path -Path $path -ChildPath "bin"
    if (Test-Path -Path (Join-Path -Path $potentialFlutterBin -ChildPath "flutter.bat")) {
        Write-Host -ForegroundColor Green "Found Flutter SDK at: $path"
        $flutterPath = $path
        break
    } else {
        Write-Host "Checked: $path (Not found or flutter.bat missing in bin)"
    }
}

# --- If Flutter SDK not found in common locations, prompt user ---
if (-not $flutterPath) {
    Write-Host -ForegroundColor Yellow "Could not automatically find Flutter SDK in common locations."
    $manualPath = Read-Host "Please enter the full path to your Flutter SDK installation directory (e.g., C:\flutter)"
    if (Test-Path -Path (Join-Path -Path $manualPath -ChildPath "bin\flutter.bat")) {
        $flutterPath = $manualPath
        Write-Host -ForegroundColor Green "Using manually provided path: $flutterPath"
    } else {
        Write-Host -ForegroundColor Red "Error: The path '$manualPath' does not appear to be a valid Flutter SDK directory or 'bin\flutter.bat' is missing."
        Write-Host "Please ensure you provide the root directory of the Flutter SDK."
        Write-Host "-----------------------------------------------------------------------"
        Write-Host "Instructions for permanent fix (if script fails or for future sessions):"
        Write-Host "1. Find your Flutter SDK directory (it contains a 'bin' folder, which in turn contains 'flutter.bat')."
        Write-Host "2. Copy the full path to the 'bin' folder (e.g., C:\flutter\bin)."
        Write-Host "3. Add this path to your system or user Environment Variables:"
        Write-Host "   - Search for 'Edit the system environment variables' in Windows search."
        Write-Host "   - Click the 'Environment Variables...' button."
        Write-Host "   - Under 'User variables' or 'System variables', find the 'Path' variable."
        Write-Host "   - Select 'Path' and click 'Edit...'."
        Write-Host "   - Click 'New' and paste the path to your Flutter SDK's 'bin' folder."
        Write-Host "   - Click 'OK' on all dialogs to save the changes."
        Write-Host "4. IMPORTANT: You'll need to **restart PowerShell** (and possibly your computer) for the permanent changes to take effect."
        exit 1
    }
}

# --- Add Flutter to PATH for the current session ---
$flutterBinPath = Join-Path -Path $flutterPath -ChildPath "bin"
Write-Host "Adding '$flutterBinPath' to PATH for this PowerShell session."
$env:Path = "$flutterBinPath;$env:Path"

# --- Test Flutter command ---
Write-Host "Testing Flutter command..."
$flutterTest = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterTest) {
    Write-Host -ForegroundColor Green "Flutter command is now recognized in this session!"
    Write-Host "Current Flutter version:"
    flutter --version
    Write-Host ""
    Write-Host -ForegroundColor Cyan "You should now be able to run your command: flutter run -d emulator-5556"
    Write-Host ""
} else {
    Write-Host -ForegroundColor Red "Error: Still unable to recognize the Flutter command after attempting to update PATH."
    Write-Host "Please double-check your Flutter SDK path and try the manual steps below."
}

Write-Host "-----------------------------------------------------------------------"
Write-Host "IMPORTANT: This script only updates the PATH for the *current* PowerShell session."
Write-Host "To make this change permanent, you need to add Flutter to your Environment Variables:"
Write-Host ""
Write-Host "How to add Flutter to PATH permanently:"
Write-Host "1. The Flutter SDK's 'bin' directory that was used is: '$flutterBinPath'"
Write-Host "   (If this is incorrect, find the correct 'bin' directory within your Flutter SDK folder)."
Write-Host "2. Add this path to your system or user Environment Variables:"
Write-Host "   - In Windows Search, type 'env' or 'environment variables'."
Write-Host "   - Select 'Edit the system environment variables'."
Write-Host "   - In the System Properties window, click the 'Environment Variables...' button."
Write-Host "   - In the 'User variables for <your_username>' section (or 'System variables' for all users):"
Write-Host "     - Find the variable named 'Path'. If it doesn't exist, click 'New...' to create it."
Write-Host "     - Select 'Path' and click 'Edit...'."
Write-Host "     - Click 'New' and paste the path: $flutterBinPath"
Write-Host "     - Click 'OK' on all open dialog windows to save the changes."
Write-Host "3. After saving, you MUST **restart PowerShell** (or even your computer) for the changes to take full effect."
Write-Host "-----------------------------------------------------------------------"

