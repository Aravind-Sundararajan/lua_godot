@echo off
echo Setting up Lua Modding Example Project...
echo.

REM Check if the extension DLL exists
if not exist "..\lua_bridge.dll" (
    echo ERROR: lua_bridge.dll not found in parent directory!
    echo Please build the extension first using 'scons platform=windows'
    pause
    exit /b 1
)

REM Create platform directories if they don't exist
if not exist "addons\lua_bridge\bin\windows" mkdir "addons\lua_bridge\bin\windows"
if not exist "addons\lua_bridge\bin\linux" mkdir "addons\lua_bridge\bin\linux"
if not exist "addons\lua_bridge\bin\macos" mkdir "addons\lua_bridge\bin\macos"

REM Copy the extension DLL to the correct platform directory
echo Copying extension DLL...
copy "..\lua_bridge.dll" "addons\lua_bridge\bin\windows\lua_bridge.windows.template_debug.x86_64.dll"

REM Check if example mod exists
if not exist "..\example_mod" (
    echo WARNING: example_mod directory not found in parent directory!
    echo The example mod features may not work properly.
) else (
    echo Example mod found in parent directory.
)

echo.
echo Setup complete! You can now open this project in Godot 4.3+
echo.
echo To test the modding system:
echo 1. Open project_example folder in Godot
echo 2. Enable the Lua Bridge plugin in Project Settings → Plugins
echo 3. The Lua Bridge dock will appear in the editor
echo 4. Use the dock to test all features
echo.
pause 