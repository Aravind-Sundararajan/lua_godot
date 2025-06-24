# Lua Modding System Example Project

This is a complete example Godot project that demonstrates the Lua modding system with JSON mod management.

## Features Demonstrated

### 🎮 Interactive UI
- **Mod Management**: Load, enable, disable mods with JSON metadata
- **Lua Scripting**: Execute Lua code, call functions, manage globals
- **Lifecycle Hooks**: Test mod initialization, ready, and exit events
- **Security**: Toggle sandbox mode and test unsafe code prevention

### 📦 JSON Mod Management
- Load mods from directories containing `mod.json` files
- Automatic mod discovery and metadata parsing
- Runtime enable/disable mods
- Mod information display

### 🔒 Security & Sandboxing
- Safe Lua environment with restricted libraries
- Prevention of unsafe operations (file system, network, etc.)
- Toggle between sandboxed and unsafe modes

## Project Structure

```
project_example/
├── bin/                                    # Extension binaries
│   └── lua_bridge.windows.template_debug.x86_64.dll
├── main.tscn                              # Main scene with UI
├── main.gd                                # Main script handling UI logic
├── project.godot                          # Project configuration
├── lua_bridge.gdextension                 # GDExtension configuration
├── icon.png                               # Project icon
└── README.md                              # This file
```

## How to Use

1. **Open the Project**: Open `project_example` folder in Godot 4.3+
2. **Run the Project**: Press F5 or click the Play button
3. **Test Features**: Use the UI buttons to test different aspects of the modding system

## UI Sections

### Mod Management
- **Load Mods from Directory**: Scans for mod.json files and loads them
- **Load Specific Mod JSON**: Loads a specific mod.json file
- **Enable/Disable Mods**: Toggle mod states at runtime

### Lua Scripting
- **Execute Lua String**: Run arbitrary Lua code
- **Call Lua Function**: Call specific functions with arguments
- **Set/Get Global Variables**: Manage Lua global state

### Lifecycle Hooks
- **Call on_init()**: Initialize loaded mods
- **Call on_ready()**: Signal mods that they're ready
- **Call on_exit()**: Clean up mods before shutdown

### Security & Sandboxing
- **Toggle Sandbox Mode**: Switch between safe and unsafe modes
- **Test Unsafe Code**: Demonstrate security restrictions

## Example Mod

The project includes an example mod in the parent directory (`../example_mod/`):

```json
{
    "name": "ExampleMod",
    "version": "1.0.0",
    "author": "Example Author",
    "description": "An example mod that demonstrates the Lua modding system",
    "entry_script": "main.lua",
    "enabled": true
}
```

The mod provides:
- Lifecycle hooks (`on_init`, `on_ready`, `on_update`, `on_exit`)
- Utility functions (`get_player_position`, `set_player_position`)
- Damage calculation function (`calculate_damage`)
- Global variable management

## Building Your Own Mods

1. **Create a mod directory** with a `mod.json` file
2. **Define metadata** (name, version, author, description)
3. **Specify entry script** that will be loaded
4. **Implement lifecycle hooks** as needed
5. **Add your Lua code** with game-specific functionality

### Example Mod Structure
```
my_mod/
├── mod.json          # Mod metadata
├── main.lua          # Entry script
├── utils.lua         # Utility functions
└── assets/           # Mod assets (if any)
```

## Integration with Your Game

To integrate this system into your own game:

1. **Copy the extension** (`lua_bridge.dll` and `lua_bridge.gdextension`)
2. **Initialize LuaBridge** in your game's main script
3. **Set up mod directories** for your game
4. **Call lifecycle hooks** at appropriate times in your game loop
5. **Register game-specific functions** for mods to call

## Troubleshooting

### Extension Not Loading
- Ensure the DLL is in the correct `bin/` directory
- Check that the GDExtension file points to the right DLL
- Verify Godot version compatibility (4.3+)

### Mods Not Loading
- Check that mod.json files are valid JSON
- Ensure entry scripts exist and are valid Lua
- Look for error messages in the output console

### Sandbox Issues
- Unsafe operations are blocked in sandboxed mode
- Use `set_sandboxed(false)` only for trusted mods
- Always validate mod code before running

## Next Steps

- Add dependency management between mods
- Implement mod conflict detection
- Create a mod manager UI for your game
- Add version compatibility checking
- Implement mod hot-reloading for development

## License

This example project is provided as-is for educational purposes. The Lua modding system can be integrated into your own projects. 