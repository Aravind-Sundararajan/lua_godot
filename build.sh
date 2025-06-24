#!/bin/bash

echo "Building Lua GDExtension for Godot..."

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

# Check if godot-cpp is built
if [ ! -f "godot-cpp/bin/libgodot-cpp.$PLATFORM.template_debug.x86_64.a" ]; then
    echo "Building godot-cpp debug version..."
    cd godot-cpp
    scons platform=$PLATFORM target=template_debug
    cd ..
fi

if [ ! -f "godot-cpp/bin/libgodot-cpp.$PLATFORM.template_release.x86_64.a" ]; then
    echo "Building godot-cpp release version..."
    cd godot-cpp
    scons platform=$PLATFORM target=template_release
    cd ..
fi

echo "Building Lua GDExtension..."
scons platform=$PLATFORM target=template_debug
scons platform=$PLATFORM target=template_release

echo "Build complete!" 