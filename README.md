# Lua Bridge for Godot - Advanced Modding System

A comprehensive Lua scripting bridge for Godot 4 that provides a complete modding system with lifecycle hooks, sandboxing, and mod management.

## 🎯 Features

### ✅ Core Scripting Features
- **Game API Exposure**: Register Godot types and methods as Lua globals
- **Dynamic Script Loading**: Load/unload scripts at runtime with `load_file()` and `reload()`
- **Error Handling**: Graceful error catching with stack traces and logging
- **Script Execution Context**: Each mod gets its own Lua environment

### ✅ Lifecycle Hooks
Mods can implement these standard lifecycle functions:
```lua
function on_init() end      -- Called when mod is first loaded
function on_ready() end     -- Called after mod is ready to run
function on_update(delta) end -- Called every frame with delta time
function on_exit() end      -- Called when mod is unloaded
```

### ✅ Security & Sandboxing
- **Safe Environment**: Disabled dangerous Lua libraries (os, io, package, etc.)
- **Limited Standard Library**: Only safe libraries loaded by default
- **Configurable**: Toggle sandboxing on/off with `set_sandboxed()`

### ✅ Mod Management
- **Directory Scanning**: Load all `.lua` files from a directory
- **Mod Tracking**: Keep track of loaded mods with `list_loaded_mods()`
- **Individual Unloading**: Unload specific mods with `unload_mod()`

## 🚀 Quick Start

### 1. Basic Usage
```gdscript
var lua_bridge = LuaBridge.new()

# Execute Lua code
lua_bridge.exec_string("print('Hello from Lua!')")

# Set and get global variables
lua_bridge.set_global("player_health", 100)
var health = lua_bridge.get_global("player_health")

# Load a mod file
lua_bridge.load_file("res://mods/my_mod.lua")

# Call lifecycle hooks
lua_bridge.call_on_init()
lua_bridge.call_on_ready()
lua_bridge.call_on_update(delta)
```

### 2. Creating a Mod
Create a Lua file (e.g., `my_mod.lua`):
```lua
local mod_name = "MyMod"

function on_init()
    print("[" .. mod_name .. "] Initializing...")
end

function on_ready()
    print("[" .. mod_name .. "] Ready!")
end

function on_update(delta)
    -- Called every frame
    -- Update your mod logic here
end

function on_exit()
    print("[" .. mod_name .. "] Shutting down...")
end

-- Custom functions that can be called from Godot
function get_player_info()
    return {health = 100, level = 5}
end

function calculate_damage(base_damage, multiplier)
    return base_damage * multiplier
end
```

### 3. Mod Management
```gdscript
# Load all mods from a directory
lua_bridge.load_script_from_directory("res://mods/")

# List loaded mods
var mods = lua_bridge.list_loaded_mods()
print("Loaded mods: ", mods)

# Unload a specific mod
lua_bridge.unload_mod("MyMod")

# Call mod functions with arguments
var args = Array()
args.append(50)   # base_damage
args.append(1.5)  # multiplier
var damage = lua_bridge.call_function("calculate_damage", args)
```

## 🔧 API Reference

### Core Methods
- `exec_string(String code)` - Execute Lua code from string
- `exec_file(String path)` - Execute Lua code from file
- `load_file(String path)` - Load and execute a Lua file, returns success
- `reload()` - Reset the Lua VM (hot reload)
- `unload()` - Completely unload the Lua VM

### Global Variable Management
- `set_global(String name, Variant value)` - Set a global variable
- `get_global(String name)` - Get a global variable

### Function Calling
- `call_function(String func_name, Array args)` - Call a Lua function with arguments
- `register_function(String name, Callable cb)` - Register a Godot function with Lua

### Mod Management
- `load_script_from_directory(String mod_dir)` - Load all `.lua` files from directory
- `call_event(String event_name, Array args)` - Call a lifecycle event
- `list_loaded_mods()` - Get array of loaded mod names
- `unload_mod(String mod_name)` - Unload a specific mod

### Lifecycle Hooks
- `call_on_init()` - Call `on_init()` in all loaded mods
- `call_on_ready()` - Call `on_ready()` in all loaded mods
- `call_on_update(double delta)` - Call `on_update(delta)` in all loaded mods
- `call_on_exit()` - Call `on_exit()` in all loaded mods

### Security & Sandboxing
- `set_sandboxed(bool enabled)` - Enable/disable sandboxing
- `is_sandboxed()` - Check if sandboxing is enabled
- `setup_safe_environment()` - Manually setup safe environment

### Utility Methods
- `print_to_console(String message)` - Print to Godot console
- `log_error(String error_message)` - Log an error
- `get_last_error()` - Get the last Lua error message

## 🔒 Security Features

### Sandboxed Mode (Default)
In sandboxed mode, the following Lua libraries are disabled:
- `os` (except `os.time()` and `os.date()`)
- `io` (file operations)
- `package` (module loading)
- `loadfile` and `dofile` (file execution)

### Safe Libraries Available
- `base` (basic functions)
- `table` (table manipulation)
- `string` (string operations)
- `math` (mathematical functions)
- `utf8` (UTF-8 support)

### Disabling Sandboxing
```gdscript
lua_bridge.set_sandboxed(false)
lua_bridge.reload()  # Must reload to apply changes
```

## 🧪 Testing

Run the test script to see all features in action:
```gdscript
# Attach test_lua_bridge.gd to a Node and run
```

The test script demonstrates:
- Basic operations (exec_string, globals, reload)
- Mod loading and lifecycle hooks
- Function calling with arguments
- Error handling
- Sandboxing features

## 📁 File Structure
```
lua_godot/
├── src/
│   ├── bridge.h          # Main header file
│   ├── bridge.cpp        # Implementation
│   ├── register_types.h  # Registration header
│   └── register_types.cpp # Registration implementation
├── example_mod.lua       # Example mod script
├── test_lua_bridge.gd    # Test script
├── SConstruct           # Build script
└── README.md           # This file
```

## 🔧 Building

### Windows
```bash
scons platform=windows
```

### Linux/macOS
```bash
scons platform=linux  # or macos
```

## 🎮 Integration with Godot

1. Build the extension
2. Copy `lua_bridge.dll` (or `.so`/`.dylib`) to your Godot project
3. Create a `.gdextension` file:
```ini
[configuration]
entry_symbol = "lua_bridge_library_init"
compatibility_minimum = "4.3"

[libraries]
windows.debug.x86_64 = "res://lua_bridge.dll"
windows.release.x86_64 = "res://lua_bridge.dll"
```

4. Use the `LuaBridge` class in your GDScript code

## 🚀 Advanced Usage

### Custom Game API
Extend the `setup_game_api()` method in `bridge.cpp` to expose your game's types and methods to Lua.

### Mod Configuration
Create a `mod.json` system for mod metadata:
```json
{
    "name": "MyMod",
    "version": "1.0.0",
    "author": "Your Name",
    "entry_script": "main.lua"
}
```

### In-Game Console
Use `exec_string()` to create an in-game Lua console for debugging and testing.

## 🤝 Contributing

Feel free to contribute improvements, bug fixes, or new features!

## 📄 License

This project is open source. See the LICENSE file for details. 