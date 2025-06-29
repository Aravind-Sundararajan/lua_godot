param(
    [string]$Command = "current"
)

Write-Host "Lua Bridge Addon Builder" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""

switch ($Command.ToLower()) {
    "help" {
        Write-Host "Usage: .\build_addon.ps1 [command]" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor White
        Write-Host "  current - Build for current platform (default)" -ForegroundColor White
        Write-Host "  windows - Build for Windows only" -ForegroundColor White
        Write-Host "  all     - Build for all platforms (requires Python)" -ForegroundColor White
        Write-Host "  help    - Show this help message" -ForegroundColor White
        break
    }
    
    "all" {
        Write-Host "Building for all platforms..." -ForegroundColor Yellow
        python build_addon.py all
        break
    }
    
    "windows" {
        Write-Host "Building for Windows..." -ForegroundColor Yellow
        scons platform=windows
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Copying to addon directory..." -ForegroundColor Cyan
            $targetDir = "project_example\addons\lua_bridge\bin\windows"
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item "lua_bridge.dll" "$targetDir\lua_bridge.windows.template_debug.x86_64.dll" -Force
            
            Write-Host "Copying to main project..." -ForegroundColor Cyan
            $mainProjectDir = "..\addons\lua_bridge\bin\windows"
            if (-not (Test-Path $mainProjectDir)) {
                New-Item -ItemType Directory -Path $mainProjectDir -Force | Out-Null
            }
            robocopy "project_example\addons\lua_bridge\bin\windows" $mainProjectDir "*.dll" | Out-Null
            if ($LASTEXITCODE -le 7) {  # robocopy success codes are 0-7
                Write-Host "DLL copied to main project successfully!" -ForegroundColor Green
            } else {
                Write-Host "Warning: Failed to copy DLL to main project" -ForegroundColor Yellow
            }
            
            Write-Host "Build completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Build failed!" -ForegroundColor Red
        }
        break
    }
    
    "current" {
        Write-Host "Building for current platform (Windows)..." -ForegroundColor Yellow
        scons platform=windows
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Copying to addon directory..." -ForegroundColor Cyan
            $targetDir = "project_example\addons\lua_bridge\bin\windows"
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item "lua_bridge.dll" "$targetDir\lua_bridge.windows.template_debug.x86_64.dll" -Force
            
            Write-Host "Copying to main project..." -ForegroundColor Cyan
            $mainProjectDir = "..\addons\lua_bridge\bin\windows"
            if (-not (Test-Path $mainProjectDir)) {
                New-Item -ItemType Directory -Path $mainProjectDir -Force | Out-Null
            }
            robocopy "project_example\addons\lua_bridge\bin\windows" $mainProjectDir "*.dll" | Out-Null
            if ($LASTEXITCODE -le 7) {  # robocopy success codes are 0-7
                Write-Host "DLL copied to main project successfully!" -ForegroundColor Green
            } else {
                Write-Host "Warning: Failed to copy DLL to main project" -ForegroundColor Yellow
            }
            
            Write-Host "Build completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Build failed!" -ForegroundColor Red
        }
        break
    }
    
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Use '.\build_addon.ps1 help' for usage information" -ForegroundColor Yellow
        break
    }
} 