Write-Host "Setting up Lua Modding Example Project..." -ForegroundColor Green
Write-Host ""

# Check if the extension DLL exists
if (-not (Test-Path "..\lua_bridge.dll")) {
    Write-Host "ERROR: lua_bridge.dll not found in parent directory!" -ForegroundColor Red
    Write-Host "Please build the extension first using 'scons platform=windows'" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    exit 1
}

# Create platform directories if they don't exist
$platformDirs = @("addons\lua_bridge\bin\windows", "addons\lua_bridge\bin\linux", "addons\lua_bridge\bin\macos")
foreach ($dir in $platformDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Copy the extension DLL to the correct platform directory
Write-Host "Copying extension DLL..." -ForegroundColor Cyan
Copy-Item "..\lua_bridge.dll" "addons\lua_bridge\bin\windows\lua_bridge.windows.template_debug.x86_64.dll" -Force

# Check if example mod exists
if (-not (Test-Path "..\example_mod")) {
    Write-Host "WARNING: example_mod directory not found in parent directory!" -ForegroundColor Yellow
    Write-Host "The example mod features may not work properly." -ForegroundColor Yellow
} else {
    Write-Host "Example mod found in parent directory." -ForegroundColor Green
}

Write-Host ""
Write-Host "Setup complete! You can now open this project in Godot 4.3+" -ForegroundColor Green
Write-Host ""
Write-Host "To test the modding system:" -ForegroundColor Cyan
Write-Host "1. Open project_example folder in Godot" -ForegroundColor White
Write-Host "2. Enable the Lua Bridge plugin in Project Settings → Plugins" -ForegroundColor White
Write-Host "3. The Lua Bridge dock will appear in the editor" -ForegroundColor White
Write-Host "4. Use the dock to test all features" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue" 