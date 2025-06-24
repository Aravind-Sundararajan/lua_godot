# Clean godot-cpp build artifacts
Write-Host "Cleaning godot-cpp build artifacts..."
Remove-Item -Recurse -Force .\godot-cpp\bin\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\godot-cpp\gen\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\godot-cpp\*.obj -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\godot-cpp\*.lib -ErrorAction SilentlyContinue

# Clean extension build artifacts
Write-Host "Cleaning extension build artifacts..."
Remove-Item -Recurse -Force .\build\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\bin\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\*.obj -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\*.lib -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\*.dll -ErrorAction SilentlyContinue

# Regenerate godot-cpp bindings
Write-Host "Regenerating godot-cpp bindings..."
cd godot-cpp
python binding_generator.py --api ../extension_api.json --output-path gen

# Rebuild godot-cpp (debug and release)
Write-Host "Rebuilding godot-cpp (debug)..."
scons platform=windows target=template_debug
Write-Host "Rebuilding godot-cpp (release)..."
scons platform=windows target=template_release
cd ..

# Rebuild extension (debug and release)
Write-Host "Rebuilding extension (debug)..."
scons platform=windows target=template_debug
Write-Host "Rebuilding extension (release)..."
scons platform=windows target=template_release

Write-Host "All done!"