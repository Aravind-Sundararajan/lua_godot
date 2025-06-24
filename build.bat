@echo off
echo Building Lua GDExtension for Godot...

REM Check if godot-cpp is built
if not exist "godot-cpp\bin\libgodot-cpp.windows.template_debug.x86_64.lib" (
    echo Building godot-cpp debug version...
    cd godot-cpp
    scons platform=windows target=template_debug
    cd ..
)

if not exist "godot-cpp\bin\libgodot-cpp.windows.template_release.x86_64.lib" (
    echo Building godot-cpp release version...
    cd godot-cpp
    scons platform=windows target=template_release
    cd ..
)

echo Building Lua GDExtension...
scons platform=windows target=template_debug
scons platform=windows target=template_release

echo Build complete!
pause 