@echo off
echo Lua Bridge Addon Builder
echo ======================
echo.

if "%1"=="" (
    echo Building for current platform (Windows)...
    scons platform=windows
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo Copying to addon directory...
        if not exist "project_example\addons\lua_bridge\bin\windows" mkdir "project_example\addons\lua_bridge\bin\windows"
        copy "lua_bridge.dll" "project_example\addons\lua_bridge\bin\windows\lua_bridge.windows.template_debug.x86_64.dll"
        echo Build completed successfully!
    ) else (
        echo Build failed!
    )
    goto :end
)

if "%1"=="help" (
    echo Usage: build_addon.bat [command]
    echo.
    echo Commands:
    echo   windows - Build for Windows (default)
    echo   all     - Build for all platforms (requires Python)
    echo   help    - Show this help message
    goto :end
)

if "%1"=="all" (
    echo Building for all platforms...
    python build_addon.py all
    goto :end
)

if "%1"=="windows" (
    echo Building for Windows...
    scons platform=windows
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo Copying to addon directory...
        if not exist "project_example\addons\lua_bridge\bin\windows" mkdir "project_example\addons\lua_bridge\bin\windows"
        copy "lua_bridge.dll" "project_example\addons\lua_bridge\bin\windows\lua_bridge.windows.template_debug.x86_64.dll"
        echo Build completed successfully!
    ) else (
        echo Build failed!
    )
    goto :end
)

echo Unknown command: %1
echo Use 'build_addon.bat help' for usage information

:end
pause 