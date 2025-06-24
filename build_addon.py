#!/usr/bin/env python3
"""
Build script for Lua Bridge Addon
Automatically builds the extension and copies it to the correct platform-specific directories.
"""

import os
import sys
import subprocess
import shutil
import platform


def get_platform():
    """Get the current platform"""
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    elif system == "darwin":
        return "macos"
    elif system == "linux":
        return "linux"
    else:
        return "unknown"


def get_target_filename(platform_name, target="debug"):
    """Get the target filename for the given platform"""
    if platform_name == "windows":
        return f"lua_bridge.windows.template_{target}.x86_64.dll"
    elif platform_name == "linux":
        return f"lua_bridge.linux.template_{target}.x86_64.so"
    elif platform_name == "macos":
        return f"lua_bridge.macos.template_{target}.framework"
    else:
        return None


def get_target_directory(platform_name):
    """Get the target directory for the given platform"""
    return f"project_example/addons/lua_bridge/bin/{platform_name}"


def build_extension(platform_name, target="debug"):
    """Build the extension using scons"""
    print(f"Building for {platform_name} ({target})...")

    cmd = ["scons", f"platform={platform_name}"]
    if target == "release":
        cmd.append("target=release")

    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True)
        print("Build completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Build failed: {e}")
        print(f"Error output: {e.stderr}")
        return False


def copy_to_addon(platform_name, target="debug"):
    """Copy the built extension to the addon directory"""
    target_filename = get_target_filename(platform_name, target)
    target_dir = get_target_directory(platform_name)

    if not target_filename:
        print(f"Unknown platform: {platform_name}")
        return False

    # Create target directory if it doesn't exist
    os.makedirs(target_dir, exist_ok=True)

    # Find the built library
    if platform_name == "windows":
        source_file = "lua_bridge.dll"
    elif platform_name == "linux":
        source_file = "libluabridge.so"
    elif platform_name == "macos":
        source_file = "libluabridge.dylib"
    else:
        print(f"Unknown platform: {platform_name}")
        return False

    # Check if source file exists
    if not os.path.exists(source_file):
        print(f"Built library not found: {source_file}")
        return False

    # Copy to addon directory
    target_path = os.path.join(target_dir, target_filename)
    shutil.copy2(source_file, target_path)
    print(f"Copied {source_file} to {target_path}")

    return True


def build_all_platforms():
    """Build for all supported platforms"""
    platforms = ["windows", "linux", "macos"]
    current_platform = get_platform()

    print(f"Current platform: {current_platform}")
    print("Building for all platforms...")

    success_count = 0

    for platform_name in platforms:
        print(f"\n--- Building for {platform_name} ---")

        # Build debug version
        if build_extension(platform_name, "debug"):
            if copy_to_addon(platform_name, "debug"):
                success_count += 1
                print(f"✓ {platform_name} debug build completed")
            else:
                print(f"✗ Failed to copy {platform_name} debug build")
        else:
            print(f"✗ {platform_name} debug build failed")

        # Build release version
        if build_extension(platform_name, "release"):
            if copy_to_addon(platform_name, "release"):
                success_count += 1
                print(f"✓ {platform_name} release build completed")
            else:
                print(f"✗ Failed to copy {platform_name} release build")
        else:
            print(f"✗ {platform_name} release build failed")

    print(
        f"\nBuild summary: {success_count}/{len(platforms) * 2} builds completed successfully")
    return success_count > 0


def build_current_platform():
    """Build for the current platform only"""
    current_platform = get_platform()

    if current_platform == "unknown":
        print("Unknown platform, cannot build")
        return False

    print(f"Building for current platform: {current_platform}")

    # Build debug version
    if build_extension(current_platform, "debug"):
        if copy_to_addon(current_platform, "debug"):
            print(f"✓ {current_platform} debug build completed")
            return True
        else:
            print(f"✗ Failed to copy {current_platform} debug build")
            return False
    else:
        print(f"✗ {current_platform} debug build failed")
        return False


def main():
    """Main function"""
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()

        if command == "all":
            build_all_platforms()
        elif command == "current":
            build_current_platform()
        elif command == "windows":
            build_extension("windows", "debug")
            copy_to_addon("windows", "debug")
        elif command == "linux":
            build_extension("linux", "debug")
            copy_to_addon("linux", "debug")
        elif command == "macos":
            build_extension("macos", "debug")
            copy_to_addon("macos", "debug")
        elif command == "help":
            print("Usage:")
            print("  python build_addon.py [command]")
            print("")
            print("Commands:")
            print("  all     - Build for all platforms (debug and release)")
            print("  current - Build for current platform only (debug)")
            print("  windows - Build for Windows only")
            print("  linux   - Build for Linux only")
            print("  macos   - Build for macOS only")
            print("  help    - Show this help message")
        else:
            print(f"Unknown command: {command}")
            print("Use 'python build_addon.py help' for usage information")
    else:
        # Default: build for current platform
        build_current_platform()


if __name__ == "__main__":
    main()
