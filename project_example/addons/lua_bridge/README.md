# Lua Bridge Addon

A comprehensive Lua scripting and modding system for Godot with JSON mod management, security features, and an integrated editor interface.

## Features

### Editor Integration
- **Editor Dock**: Integrated UI in Godot's editor for easy mod management
- **Tabbed Interface**: Organized sections for mods, scripting, lifecycle, security, and output
- **Real-time Output**: Live feedback from Lua script execution
- **Auto-update**: Optional automatic lifecycle hook calling

### Mod Management
- **JSON Metadata**: Structured mod information with versioning
- **Directory Scanning**: Automatic mod discovery
- **Runtime Control**: Enable/disable mods without restart
- **Mod List**: Visual interface for managing loaded mods

### Lua Scripting
- **Code Execution**: Run arbitrary Lua code with immediate feedback
- **Function Calling**: Call specific Lua functions with parameters
- **Global Variables**: Set and retrieve Lua global state
- **Error Handling**: Comprehensive error reporting

### Security & Sandboxing
- **Safe Environment**: Restricted Lua libraries by default
- **Sandbox Toggle**: Switch between safe and unsafe modes
- **Security Testing**: Built-in tools to test security restrictions
- **Status Display**: Clear indication of current security state

### Lifecycle Management
- **Hook System**: Standardized mod lifecycle (init, ready, update, exit)
- **Manual Control**: Trigger lifecycle events manually
- **Auto-update**: Optional automatic update loop
- **Cleanup**: Proper resource management and cleanup

## Installation

### For This Project
The addon is already configured for this example project. Simply:

1. Enable the plugin in Project Settings → Plugins
2. The Lua Bridge dock will appear in the editor
3. Start testing the features!

### For Your Own Project
1. Copy the `addons/lua_bridge` folder to your project's `addons` directory
2. Copy the extension DLL to `addons/lua_bridge/bin/windows/` (or appropriate platform)
3. Enable the plugin in Project Settings → Plugins

## File Structure

```
addons/lua_bridge/
├── bin/                                    # Extension binaries
│   ├── windows/                           # Windows binaries
│   │   └── lua_bridge.windows.template_debug.x86_64.dll
│   ├── linux/                             # Linux binaries
│   │   └── lua_bridge.linux.template_debug.x86_64.so
│   ├── macos/                             # macOS binaries
│   │   └── lua_bridge.macos.template_debug.framework
│   └── lua_bridge.gdextension             # GDExtension configuration
├── ui/                                     # Editor interface
│   ├── lua_bridge_dock.tscn               # Main dock scene
│   └── lua_bridge_dock.gd                 # Dock logic
├── icons/                                  # Plugin icons
│   └── icon.svg                           # Addon icon
├── plugin.cfg                             # Plugin configuration
├── luabridge_plugin.gd                    # Main plugin script
└── README.md                              # This documentation
```

## Usage

### Editor Interface

#### Mods Tab
- **Load Mods from Directory**: Scans for mod.json files and loads them
- **Load Specific Mod JSON**: Loads a specific mod.json file
- **Mod List**: Shows all loaded mods with their status
- **Enable/Disable/Unload**: Control mod states with selected mods

#### Scripting Tab
- **Execute Lua String**: Run predefined Lua code examples
- **Call Lua Function**: Call specific functions with parameters
- **Set/Get Global Variables**: Manage Lua global state
- **Code Input**: Write and execute custom Lua code
- **Execute Code**: Run the code in the text area

#### Lifecycle Tab
- **Call on_init()**: Initialize loaded mods
- **Call on_ready()**: Signal mods that they're ready
- **Call on_exit()**: Clean up mods before shutdown
- **Auto Update**: Toggle automatic update loop

#### Security Tab
- **Toggle Sandbox Mode**: Switch between safe and unsafe modes
- **Test Unsafe Code**: Demonstrate security restrictions
- **Sandbox Status**: Current security state indicator

#### Output Tab
- **Live Output**: Real-time feedback from Lua execution
- **Clear Output**: Clear the output buffer
- **Scrollable History**: Review previous executions

### Programmatic Usage

```gdscript
# Initialize the bridge
var lua_bridge = LuaBridge.new()
lua_bridge.setup_safe_environment()

# Load mods
lua_bridge.load_mods_from_directory("res://mods")

# Execute Lua code
lua_bridge.exec_string("print('Hello from Lua!')")

# Call functions
var args = Array()
args.append(100)
args.append(1.5)
var result = lua_bridge.call_function("calculate_damage", args)

# Lifecycle management
lua_bridge.call_on_init()
lua_bridge.call_on_ready()

# In your game loop
func _process(delta):
    lua_bridge.call_on_update(delta)

# Cleanup
func _exit_tree():
    lua_bridge.call_on_exit()
    lua_bridge.unload()
```

## Mod Development

### Mod Structure
```
my_mod/
├── mod.json          # Mod metadata
├── main.lua          # Entry script
├── utils.lua         # Utility functions
└── assets/           # Mod assets (if any)
```

### mod.json Format
```json
{
    "name": "MyMod",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "A description of your mod",
    "entry_script": "main.lua",
    "enabled": true,
    "dependencies": [],
    "tags": ["example", "demo"]
}
```

### Lifecycle Hooks
```lua
-- Called when the mod is loaded
function on_init()
    print("Mod initialized!")
end

-- Called when the mod is ready to run
function on_ready()
    print("Mod is ready!")
end

-- Called every frame (if auto-update is enabled)
function on_update(delta)
    -- Your update logic here
end

-- Called when the mod is unloaded
function on_exit()
    print("Mod is shutting down!")
end
```

## Configuration

### Plugin Settings
The plugin can be configured in Project Settings → Plugins → Lua Bridge:

- **Auto Update**: Enable automatic lifecycle hook calling
- **Default Sandbox**: Set default security mode
- **Mod Directories**: Configure default mod search paths

### Security Settings
- **Sandboxed Mode**: Restricts unsafe operations (default: enabled)
- **Allowed Libraries**: Configure which Lua libraries are available
- **File Access**: Control file system access permissions

## Troubleshooting

### Plugin Not Loading
- Ensure the extension DLL is in the correct platform directory
- Check Godot version compatibility (4.3+)
- Verify the GDExtension file paths in `bin/lua_bridge.gdextension`

### Mods Not Loading
- Check mod.json syntax
- Ensure entry scripts exist and are valid Lua
- Look for error messages in the output console

### Security Issues
- Unsafe operations are blocked in sandboxed mode
- Use `set_sandboxed(false)` only for trusted mods
- Always validate mod code before running

## API Reference

### Core Methods
- `setup_safe_environment()`: Initialize secure Lua environment
- `exec_string(code)`: Execute Lua code string
- `load_file(path)`: Load and execute Lua file
- `call_function(name, args)`: Call Lua function with arguments

### Mod Management
- `load_mod_from_json(path)`: Load mod from JSON file
- `load_mods_from_directory(dir)`: Load all mods from directory
- `enable_mod(name)`: Enable a specific mod
- `disable_mod(name)`: Disable a specific mod
- `unload_mod(name)`: Unload a mod completely

### Lifecycle
- `call_on_init()`: Call init hooks on all mods
- `call_on_ready()`: Call ready hooks on all mods
- `call_on_update(delta)`: Call update hooks on all mods
- `call_on_exit()`: Call exit hooks on all mods

### Security
- `set_sandboxed(enabled)`: Toggle sandbox mode
- `is_sandboxed()`: Check current sandbox status

### Variables
- `set_global(name, value)`: Set Lua global variable
- `get_global(name)`: Get Lua global variable

## License

This addon is provided as-is for educational and development purposes. The Lua modding system can be integrated into your own projects. 