@tool
extends EditorPlugin

var dock: Control

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
	
	# Setup the dock initially without bridge
	dock.setup()  # Setup without bridge initially
	print("Dock setup without Lua functionality initially")
	
	# Try to get the bridge on the next frame when autoloads are fully ready
	call_deferred("_try_initialize_bridge")
	
	print("Dock setup completed")
	
	# Add the dock to the editor
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, dock)
	print("Lua Bridge Plugin: Full dock added to LEFT side!")

func _exit_tree():
	print("Lua Bridge Plugin: Cleaning up...")
	
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	
	# Note: No need to manually clean up Lua bridge - the manager handles it
	print("Lua Bridge Plugin: Cleanup complete!")

func _has_main_screen():
	return false
	
func _get_plugin_name():
	return "Lua Bridge"

func _get_plugin_icon():
	return preload("res://addons/lua_bridge/icons/icon.svg") 

func _try_initialize_bridge():
	# This runs on the next frame when autoloads should be fully ready
	print("Attempting to initialize bridge on deferred call...")
	
	var bridge = null
	
	# Skip the problematic autoload entirely and create bridge directly
	print("Creating LuaBridge directly...")
	
	# Try direct LuaBridge creation
	if ClassDB.class_exists("LuaBridge"):
		bridge = ClassDB.instantiate("LuaBridge")
		if bridge:
			print("LuaBridge created successfully")
			# Set up the bridge
			if bridge.has_method("setup_safe_environment"):
				bridge.setup_safe_environment()
				print("LuaBridge setup completed")
		else:
			print("Failed to create LuaBridge instance")
	else:
		print("LuaBridge class not available")
	
	# If we got a bridge, update the dock
	if bridge and dock:
		print("Updating dock with bridge...")
		dock.setup(bridge)  # Pass the bridge directly
		print("Dock updated with Lua functionality")
	else:
		print("Dock remains without Lua functionality")
