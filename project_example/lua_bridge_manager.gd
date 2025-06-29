extends Node

# LuaBridgeManager - Singleton for managing Lua bridge instances
# This ensures only one Lua bridge is created and managed centrally

var lua_bridge = null
var is_initialized: bool = false
var initialization_error: String = ""

# Signal emitted when the bridge is initialized
signal bridge_initialized()
signal bridge_initialization_failed(error: String)

func _ready():
	#print("LuaBridgeManager: Singleton loaded")

func get_bridge():
	"""
	Get the Lua bridge instance. Creates it if it doesn't exist.
	Returns null if initialization fails.
	"""
	if lua_bridge == null:
		initialize_bridge()
	return lua_bridge

func initialize_bridge() -> bool:
	"""
	Initialize the Lua bridge if not already initialized.
	Returns true if successful, false otherwise.
	"""
	if is_initialized:
		return lua_bridge != null
	
	#print("LuaBridgeManager: Attempting to initialize bridge...")
	
	# Reset bridge
	lua_bridge = null
	
	# Try to get the bridge from the engine singleton first (if it exists)
	if Engine.has_singleton("LuaBridge"):
		lua_bridge = Engine.get_singleton("LuaBridge")
		#print("LuaBridgeManager: Found LuaBridge singleton")
	else:
		# Try to create using the GDExtension class
		if ClassDB.class_exists("LuaBridge"):
			#print("LuaBridgeManager: Creating LuaBridge instance from GDExtension...")
			lua_bridge = ClassDB.instantiate("LuaBridge")
			if lua_bridge:
				#print("LuaBridgeManager: Created LuaBridge instance")
			else:
				initialization_error = "Failed to instantiate LuaBridge"
				#print("✗ LuaBridgeManager: " + initialization_error)
				bridge_initialization_failed.emit(initialization_error)
				return false
		else:
			initialization_error = "LuaBridge class not found - GDExtension may not be loaded"
			#print("✗ LuaBridgeManager: " + initialization_error)
			bridge_initialization_failed.emit(initialization_error)
			return false
	
	if lua_bridge:
		# Verify the bridge has the required methods
		if not lua_bridge.has_method("exec_string"):
			initialization_error = "LuaBridge instance missing required methods"
			#print("✗ LuaBridgeManager: " + initialization_error)
			bridge_initialization_failed.emit(initialization_error)
			return false
		
		# Set up the bridge with safe environment
		if lua_bridge.has_method("setup_safe_environment"):
			lua_bridge.setup_safe_environment()
		
		is_initialized = true
		initialization_error = ""
		#print("✓ LuaBridgeManager: Bridge initialized successfully")
		bridge_initialized.emit()
		return true
	else:
		initialization_error = "Failed to create LuaBridge instance"
		#print("✗ LuaBridgeManager: " + initialization_error)
		bridge_initialization_failed.emit(initialization_error)
		return false

func unload_bridge():
	"""
	Unload and cleanup the Lua bridge.
	"""
	if lua_bridge:
		if lua_bridge.has_method("unload"):
			lua_bridge.unload()
		lua_bridge = null
		is_initialized = false
		#print("✓ LuaBridgeManager: Bridge unloaded")

func is_bridge_ready() -> bool:
	"""
	Check if the bridge is ready to use.
	"""
	return is_initialized and lua_bridge != null

func get_initialization_error() -> String:
	"""
	Get the last initialization error message.
	"""
	return initialization_error

func get_is_initialized() -> bool:
	"""
	Get the initialization status.
	"""
	return is_initialized

# Convenience methods that delegate to the bridge
func execute_lua(code: String):
	"""
	Execute Lua code through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("exec_string"):
		return bridge.exec_string(code)
	return null

func load_lua_file(file_path: String) -> bool:
	"""
	Load a Lua file through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("load_lua_file"):
		return bridge.load_lua_file(file_path)
	return false

func get_autoload_singleton(singleton_name: String):
	"""
	Get an autoload singleton through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_autoload_singleton"):
		return bridge.get_autoload_singleton(singleton_name)
	return null

func safe_call_method(obj: Variant, method_name: String, args: Array):
	"""
	Safely call a method on an object through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("safe_call_method"):
		return bridge.safe_call_method(obj, method_name, args)
	return null

func get_object_class(obj: Object) -> String:
	"""
	Get the class name of an object through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_object_class"):
		return bridge.get_object_class(obj)
	return ""

# Additional wrapper methods for all bridge functions
func call_function(func_name: String, args: Array):
	"""
	Call a Lua function through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("call_function"):
		return bridge.call_function(func_name, args)
	return null

func set_global(name: String, value: Variant):
	"""
	Set a global variable in Lua.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("set_global"):
		bridge.set_global(name, value)
		return true
	return false

func get_global(name: String) -> Variant:
	"""
	Get a global variable from Lua.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_global"):
		return bridge.get_global(name)
	return null

func call_lua_function(func_name: String, args: Array) -> bool:
	"""
	Call a Lua function through the bridge.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("call_lua_function"):
		return bridge.call_lua_function(func_name, args)
	return false

func set_sandboxed(enabled: bool) -> bool:
	"""
	Set sandbox mode.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("set_sandboxed"):
		bridge.set_sandboxed(enabled)
		return true
	return false

func is_sandboxed() -> bool:
	"""
	Check if sandbox mode is enabled.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("is_sandboxed"):
		return bridge.is_sandboxed()
	return false

func create_wrapper(obj: Object, class_type: String) -> Variant:
	"""
	Create a wrapper for a Godot object.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("create_wrapper"):
		return bridge.create_wrapper(obj, class_type)
	return null

func is_wrapper(obj: Variant) -> bool:
	"""
	Check if an object is a wrapper.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("is_wrapper"):
		return bridge.is_wrapper(obj)
	return false

func is_instance(obj: Object, class_type: String) -> bool:
	"""
	Check if an object is an instance of a class.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("is_instance"):
		return bridge.is_instance(obj, class_type)
	return false

func get_node_wrapper(obj: Object, path: String) -> Variant:
	"""
	Get a node at the specified path.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_node"):
		return bridge.get_node(obj, path)
	return null

func get_children_wrapper(obj: Object) -> Array:
	"""
	Get all children of a node.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_children"):
		return bridge.get_children(obj)
	return []

func get_property(obj: Object, property_name: String) -> Variant:
	"""
	Get a property of an object.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_property"):
		return bridge.get_property(obj, property_name)
	return null

func set_property(obj: Object, property_name: String, value: Variant) -> bool:
	"""
	Set a property of an object.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("set_property"):
		bridge.set_property(obj, property_name, value)
		return true
	return false

func load_resource(path: String) -> Variant:
	"""
	Load a resource.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("load_resource"):
		return bridge.load_resource(path)
	return null

func instance_scene(path: String) -> Variant:
	"""
	Instance a scene.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("instance_scene"):
		return bridge.instance_scene(path)
	return null

func emit_event(name: String, data: Variant) -> bool:
	"""
	Emit an event.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("emit_event"):
		bridge.emit_event(name, data)
		return true
	return false

func subscribe_event(name: String, func_name: String) -> bool:
	"""
	Subscribe to an event.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("subscribe_event"):
		bridge.subscribe_event(name, func_name)
		return true
	return false

func connect_signal(obj: Object, signal_name: String, lua_func_name: String) -> bool:
	"""
	Connect a signal to a Lua function.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("connect_signal"):
		return bridge.connect_signal(obj, signal_name, lua_func_name)
	return false

func create_coroutine(name: String, func_name: String, args: Array) -> bool:
	"""
	Create a coroutine.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("create_coroutine"):
		return bridge.create_coroutine(name, func_name, args)
	return false

func resume_coroutine(name: String, data: Variant) -> bool:
	"""
	Resume a coroutine.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("resume_coroutine"):
		return bridge.resume_coroutine(name, data)
	return false

func is_coroutine_active(name: String) -> bool:
	"""
	Check if a coroutine is active.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("is_coroutine_active"):
		return bridge.is_coroutine_active(name)
	return false

func load_mods_from_directory(mods_dir: String) -> bool:
	"""
	Load mods from a directory.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("load_mods_from_directory"):
		return bridge.load_mods_from_directory(mods_dir)
	return false

func load_mod_from_json(mod_json_path: String) -> bool:
	"""
	Load a mod from a JSON file.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("load_mod_from_json"):
		return bridge.load_mod_from_json(mod_json_path)
	return false

func enable_mod(mod_name: String) -> bool:
	"""
	Enable a mod.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("enable_mod"):
		bridge.enable_mod(mod_name)
		return true
	return false

func disable_mod(mod_name: String) -> bool:
	"""
	Disable a mod.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("disable_mod"):
		bridge.disable_mod(mod_name)
		return true
	return false

func reload_mod(mod_name: String) -> bool:
	"""
	Reload a mod.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("reload_mod"):
		return bridge.reload_mod(mod_name)
	return false

func get_all_mod_info() -> Array:
	"""
	Get information about all loaded mods.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_all_mod_info"):
		return bridge.get_all_mod_info()
	return []

func get_mod_info(mod_name: String) -> Dictionary:
	"""
	Get information about a specific mod.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("get_mod_info"):
		return bridge.get_mod_info(mod_name)
	return {}

func is_mod_enabled(mod_name: String) -> bool:
	"""
	Check if a mod is enabled.
	"""
	var bridge = get_bridge()
	if bridge and bridge.has_method("is_mod_enabled"):
		return bridge.is_mod_enabled(mod_name)
	return false

# Cleanup on exit
func _exit_tree():
	unload_bridge() 
