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
    library = env.SharedLibrary(
        "lua_bridge",
        source=sources,
        LIBS=[lua_lib, "godot-cpp/bin/libgodot-cpp.windows.template_debug.x86_64"]
    )
elif env["platform"] == "macos":
    library = env.SharedLibrary(
        "libluabridge.{}.{}.framework/libluabridge.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
        LIBS=[lua_lib, 'godot-cpp']
    )
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

Default(library)
