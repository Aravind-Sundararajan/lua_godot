# Lua Bridge for Godot

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

## Quick Start

### 1. Build the Extension

**Option A: Automatic Build (Recommended)**
```bash
# Build for current platform (Windows)
.\build_addon.ps1

# Or using Python script
python build_addon.py current

# Build for all platforms
python build_addon.py all
```

**Option B: Manual Build**
```bash
# Build using scons (automatically copies to addon directory)
scons platform=windows
```

### 2. Use the Example Project

1. Open the `project_example` folder in Godot 4.3+
2. Enable the "Lua Bridge" plugin in Project Settings → Plugins
3. The Lua Bridge dock will appear in the editor
4. Start testing the features!

## Build System

### Automatic Build Scripts

The project includes several build scripts that automatically handle platform-specific builds and file copying:

#### PowerShell Script (Windows)
```powershell
.\build_addon.ps1 [command]
```
- `current` - Build for current platform (default)
- `windows` - Build for Windows only
- `all` - Build for all platforms (requires Python)
- `help` - Show help message

#### Python Script (Cross-platform)
```bash
python build_addon.py [command]
```
- `current` - Build for current platform only
- `all` - Build for all platforms (debug and release)
- `windows` - Build for Windows only
- `linux` - Build for Linux only
- `macos` - Build for macOS only
- `help` - Show help message

#### Batch Script (Windows)
```cmd
build_addon.bat [command]
```
- `windows` - Build for Windows (default)
- `all` - Build for all platforms (requires Python)
- `help` - Show help message

### Manual Build

If you prefer to build manually:

```bash
# Build the extension
scons platform=windows

# The SConstruct automatically copies the DLL to:
# project_example/addons/lua_bridge/bin/windows/lua_bridge.windows.template_debug.x86_64.dll
```

## Project Structure

```
lua_godot/
├── src/                                    # Extension source code
│   ├── bridge.cpp                          # Main Lua bridge implementation
│   ├── bridge.h                            # Header file
│   └── register_types.cpp                  # GDExtension registration
├── godot-cpp/                              # Godot C++ bindings
├── lua-5.4.8/                              # Lua 5.4.8 source
├── project_example/                        # Example Godot project
│   ├── addons/lua_bridge/                  # Lua Bridge addon
│   │   ├── bin/                            # Extension binaries
│   │   │   ├── windows/                    # Windows binaries
│   │   │   ├── linux/                      # Linux binaries
│   │   │   ├── macos/                      # macOS binaries
│   │   │   └── lua_bridge.gdextension      # GDExtension configuration
│   │   ├── ui/                             # Editor interface
│   │   ├── icons/                          # Plugin icons
│   │   ├── plugin.cfg                      # Plugin configuration
│   │   ├── luabridge_plugin.gd             # Main plugin script
│   │   └── README.md                       # Addon documentation
│   ├── main.tscn                           # Main scene
│   ├── main.gd                             # Main script
│   ├── project.godot                       # Project configuration
│   └── README.md                           # Project documentation
├── example_mod/                            # Example Lua mod
│   ├── mod.json                            # Mod metadata
│   └── main.lua                            # Mod entry script
├── SConstruct                              # Build configuration
├── build_addon.py                          # Python build script
├── build_addon.ps1                         # PowerShell build script
├── build_addon.bat                         # Batch build script
└── README.md                               # This documentation
```

## Installation

### For Your Own Project

1. **Copy the addon**: Copy `project_example/addons/lua_bridge` to your project's `addons` directory
2. **Build the extension**: Use one of the build scripts above
3. **Enable the plugin**: Go to Project Settings → Plugins and enable "Lua Bridge"
4. **Use the editor dock**: The Lua Bridge dock will appear in the editor

### Platform Support

The build system automatically handles:
- **Windows**: `lua_bridge.windows.template_debug.x86_64.dll`
- **Linux**: `lua_bridge.linux.template_debug.x86_64.so`
- **macOS**: `lua_bridge.macos.template_debug.framework`

## Usage

### Editor Interface

The addon provides a comprehensive editor dock with tabs for:

#### Mods Tab
- Load mods from directories with JSON metadata
- Visual mod list with enable/disable/unload controls
- Runtime mod state management

#### Scripting Tab
- Execute predefined Lua code examples
- Custom code input and execution
- Function calling with parameters
- Global variable management

#### Lifecycle Tab
- Manual lifecycle hook triggering
- Auto-update option
- Proper cleanup and resource management

#### Security Tab
- Sandbox mode toggle
- Security testing tools
- Status display

#### Output Tab
- Live output from Lua execution
- Clear output buffer
- Scrollable history

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

## Troubleshooting

### Build Issues
- Ensure you have the required build tools (Visual Studio, Python, etc.)
- Check that all dependencies are properly installed
- Verify the build script paths are correct

### Extension Not Loading
- Ensure the DLL is in the correct platform directory
- Check Godot version compatibility (4.3+)
- Verify the GDExtension file paths

### Plugin Not Appearing
- Make sure the plugin is enabled in Project Settings → Plugins
- Check that all addon files are in the correct locations
- Restart the Godot editor if needed

### Mods Not Loading
- Check mod.json syntax
- Ensure entry scripts exist and are valid Lua
- Look for error messages in the output console

## License

This project is provided as-is for educational and development purposes. The Lua modding system can be integrated into your own projects. 