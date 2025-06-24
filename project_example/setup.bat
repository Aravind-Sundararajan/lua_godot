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

REM Copy the extension DLL
echo Copying extension DLL...
copy "..\lua_bridge.dll" "bin\lua_bridge.windows.template_debug.x86_64.dll"

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
echo 2. Run the project (F5)
echo 3. Use the UI buttons to test different features
echo.
pause 