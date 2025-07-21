#!/usr/bin/env python
import os
import sys
import glob
import shutil

# Import the godot-cpp environment
env = SConscript("godot-cpp/SConstruct")

# Add Lua include path
lua_dir = "lua-5.4.8"
env.Append(CPPPATH=[lua_dir + "/src"])

# Add our source directory
env.Append(CPPPATH=["src/"])

# Add godot-cpp bin directory to LIBPATH
if env["platform"] == "windows":
    env.Append(LIBPATH=["godot-cpp/bin"])

# Get our source files
sources = Glob("src/*.cpp")

# Build Lua static library
lua_sources = Glob(lua_dir + "/src/*.c")
lua_lib = env.StaticLibrary('lua', lua_sources)

# Build the GDExtension shared library
if env["platform"] == "windows":
    # Use the correct target-specific godot-cpp library
    godot_cpp_lib = f"godot-cpp/bin/libgodot-cpp.windows.{env['target']}.x86_64"

    library = env.SharedLibrary(
        "lua_bridge",
        source=sources,
        LIBS=[lua_lib, godot_cpp_lib]
    )

    # Define the target filename for the addon based on the target
    target_filename = f"lua_bridge.windows.{env['target']}.x86_64.dll"
    target_dir = "project_example/addons/lua_bridge/bin/windows"

elif env["platform"] == "macos":
    library = env.SharedLibrary(
        "libluabridge.{}.{}.framework/libluabridge.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
        LIBS=[lua_lib, 'godot-cpp']
    )

    # Define the target filename for the addon
    target_filename = f"lua_bridge.macos.{env['target']}.framework"
    target_dir = "project_example/addons/lua_bridge/bin/macos"

elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "libluabridge.{}.{}.simulator.a".format(
                env["platform"], env["target"]),
            source=sources,
            LIBS=[lua_lib, 'godot-cpp']
        )
    else:
        library = env.StaticLibrary(
            "libluabridge.{}.{}.a".format(
                env["platform"], env["target"]),
            source=sources,
            LIBS=[lua_lib, 'godot-cpp']
        )
else:
    library = env.SharedLibrary(
        "libluabridge{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
        LIBS=[lua_lib, 'godot-cpp']
    )

    # Define the target filename for the addon (Linux)
    target_filename = f"lua_bridge.linux.{env['target']}.x86_64.so"
    target_dir = "project_example/addons/lua_bridge/bin/linux"

# Function to copy the built library to the addon directory


def copy_to_addon(target, source, env):
    # Create target directory if it doesn't exist
    os.makedirs(target_dir, exist_ok=True)

    # Get the built library path
    built_library = str(source[0])

    # Copy to the addon directory
    target_path = os.path.join(target_dir, target_filename)
    shutil.copy2(built_library, target_path)

    print(f"Copied {built_library} to {target_path}")

    # Also copy to the root directory for backward compatibility
    root_target = f"lua_bridge.dll" if env[
        "platform"] == "windows" else f"lua_bridge{env['SHLIBSUFFIX']}"
    shutil.copy2(built_library, root_target)
    print(f"Copied {built_library} to {root_target}")

    # Copy to main project directory
    main_project_dir = "../addons/lua_bridge/bin/windows"
    if env["platform"] == "windows":
        os.makedirs(main_project_dir, exist_ok=True)
        main_target_path = os.path.join(main_project_dir, target_filename)
        shutil.copy2(built_library, main_target_path)
        print(f"Copied {built_library} to {main_target_path}")


# Create a custom target that copies the library after building
if env["platform"] in ["windows", "linux", "macos"]:
    copy_target = env.Command(
        target_dir + "/" + target_filename,
        library,
        copy_to_addon
    )

    # Make the copy target depend on the library
    env.Depends(copy_target, library)

    # Add the copy target to the default targets
    Default(copy_target)
else:
    Default(library)
