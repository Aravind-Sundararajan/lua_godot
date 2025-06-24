@tool
extends EditorPlugin

var dock: Control
var lua_bridge: LuaBridge

func _enter_tree():
	print("Lua Bridge Plugin: Starting initialization...")
	
	# Create the main dock
	var dock_scene = preload("res://addons/lua_bridge/ui/lua_bridge_dock.tscn")
	if dock_scene == null:
		print("ERROR: Could not load dock scene!")
		return
	
	dock = dock_scene.instantiate()
	if dock == null:
		print("ERROR: Could not instantiate dock!")
		return
	
	print("Dock created successfully")
	
	# Try to initialize Lua bridge
	lua_bridge = LuaBridge.new()
	if lua_bridge == null:
		print("WARNING: Could not create LuaBridge - dock will work without Lua functionality")
		dock.setup()  # Setup without bridge
	else:
		print("LuaBridge created successfully")
		lua_bridge.setup_safe_environment()
		dock.setup(lua_bridge)  # Setup with bridge
	
	print("Dock setup completed")
	
	# Add the dock to the editor
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, dock)
	print("Lua Bridge Plugin: Full dock added to LEFT side!")

func _exit_tree():
	print("Lua Bridge Plugin: Cleaning up...")
	
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	
	# Clean up Lua bridge
	if lua_bridge:
		lua_bridge.call_on_exit()
		lua_bridge.unload()
	
	print("Lua Bridge Plugin: Cleanup complete!")

func _has_main_screen():
	return false
	
func _get_plugin_name():
	return "Lua Bridge"

func _get_plugin_icon():
	return preload("res://addons/lua_bridge/icons/icon.svg") 
