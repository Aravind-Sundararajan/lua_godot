# Quick Start Guide

## 🚀 Get Started in 3 Steps

### 1. Build the Extension
```bash
# In the parent directory (lua_godot/)
scons platform=windows
```

### 2. Set Up the Example Project
```bash
# In the project_example directory
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### 3. Open in Godot
- Open Godot 4.3+
- Import the `project_example` folder as a project
- Press F5 to run

## 🎮 What You'll See

The example project provides a comprehensive UI to test all Lua modding features:

### Mod Management Panel
- **Load Mods**: Automatically discovers and loads mods with JSON metadata
- **Enable/Disable**: Toggle mods on/off at runtime
- **Mod Info**: View detailed information about loaded mods

### Lua Scripting Panel
- **Execute Code**: Run arbitrary Lua scripts
- **Call Functions**: Invoke specific Lua functions with parameters
- **Global Variables**: Set and retrieve Lua global state

### Lifecycle Hooks Panel
- **Init/Ready/Exit**: Test mod lifecycle management
- **Update Loop**: See mods running every frame

### Security Panel
- **Sandbox Toggle**: Switch between safe and unsafe modes
- **Security Test**: See how unsafe operations are blocked

## 📁 Project Structure

```
project_example/
├── bin/                                    # Extension binaries
├── main.tscn                              # Main UI scene
├── main.gd                                # UI logic and testing
├── project.godot                          # Project config
├── lua_bridge.gdextension                 # Extension config
├── setup.ps1                              # Setup script
└── README.md                              # Detailed documentation
```

## 🔧 Troubleshooting

### Extension Not Loading
- Ensure you built the extension with `scons platform=windows`
- Check that `lua_bridge.dll` exists in the parent directory
- Run `setup.ps1` to copy the DLL to the correct location

### Mods Not Loading
- The example mod is in `../example_mod/`
- Check the output console for error messages
- Verify JSON syntax in `mod.json` files

### UI Not Responding
- Make sure you're running Godot 4.3 or later
- Check the output console for any error messages
- Try restarting the project

## 🎯 Next Steps

1. **Explore the Code**: Look at `main.gd` to see how the API is used
2. **Create Your Own Mod**: Copy `example_mod` and modify it
3. **Integrate into Your Game**: Use the same patterns in your own project
4. **Extend the System**: Add new features like dependency management

## 📚 Learn More

- See `README.md` for detailed documentation
- Check the parent directory for the full extension source code
- Look at `example_mod/` to see how mods are structured 