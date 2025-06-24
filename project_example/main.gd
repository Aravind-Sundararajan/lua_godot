extends Control

var lua_bridge: LuaBridge
var output_buffer: String = ""

func _ready():
	# Initialize Lua bridge
	lua_bridge = LuaBridge.new()
	
	# Connect button signals
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer/LoadModsButton.pressed.connect(_on_load_mods_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer/LoadSpecificModButton.pressed.connect(_on_load_specific_mod_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer/EnableModButton.pressed.connect(_on_enable_mod_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer/DisableModButton.pressed.connect(_on_disable_mod_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer/ReloadModButton.pressed.connect(_on_reload_mod_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer2/ExecuteStringButton.pressed.connect(_on_execute_string_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer2/CallFunctionButton.pressed.connect(_on_call_function_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer2/SetGlobalButton.pressed.connect(_on_set_global_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer2/GetGlobalButton.pressed.connect(_on_get_global_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer2/TestAllFeaturesButton.pressed.connect(_on_test_all_features_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer3/CallInitButton.pressed.connect(_on_call_init_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer3/CallReadyButton.pressed.connect(_on_call_ready_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer3/CallExitButton.pressed.connect(_on_call_exit_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer4/ToggleSandboxButton.pressed.connect(_on_toggle_sandbox_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/HBoxContainer/VBoxContainer4/TestUnsafeCodeButton.pressed.connect(_on_test_unsafe_code_button_pressed)
	
	# Connect new feature test buttons
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer5/TestSafeCastingButton.pressed.connect(_on_test_safe_casting_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer5/TestWrappersButton.pressed.connect(_on_test_wrappers_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer5/TestTypeCheckingButton.pressed.connect(_on_test_type_checking_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer6/TestGetNodeButton.pressed.connect(_on_test_get_node_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer6/TestGetChildrenButton.pressed.connect(_on_test_get_children_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer6/TestPropertyAccessButton.pressed.connect(_on_test_property_access_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer6/TestMethodCallButton.pressed.connect(_on_test_method_call_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer7/TestLoadResourceButton.pressed.connect(_on_test_load_resource_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer7/TestInstanceSceneButton.pressed.connect(_on_test_instance_scene_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer7/TestResourceWrapperButton.pressed.connect(_on_test_resource_wrapper_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer8/TestEmitEventButton.pressed.connect(_on_test_emit_event_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer8/TestSubscribeEventButton.pressed.connect(_on_test_subscribe_event_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer8/TestSignalConnectionButton.pressed.connect(_on_test_signal_connection_button_pressed)
	
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer9/TestCreateCoroutineButton.pressed.connect(_on_test_create_coroutine_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer9/TestResumeCoroutineButton.pressed.connect(_on_test_resume_coroutine_button_pressed)
	$VBoxContainer/ScrollContainer/MainContent/NewFeaturesHBox/VBoxContainer9/TestCoroutineStatusButton.pressed.connect(_on_test_coroutine_status_button_pressed)
	
	# Initialize the bridge
	lua_bridge.setup_safe_environment()
	append_output("Lua Bridge initialized successfully!")
	append_output("Enhanced features available: Safe casting, Godot objects, signals, events, coroutines!")
	
	# Load the example mod
	_load_example_mod()

func _load_example_mod():
	# Copy the example mod to the project directory if it doesn't exist
	var mod_dir = "res://mods"
	var example_mod_dir = mod_dir.path_join("example_mod")
	
	# Create mods directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("mods"):
		dir.make_dir("mods")
	
	# Copy example mod files
	_copy_example_mod_files()

func _copy_example_mod_files():
	# This is a simplified version - in a real project you'd want to copy the files
	# For now, we'll just try to load from the relative path
	append_output("Attempting to load example mod...")

func append_output(text: String):
	output_buffer += text + "\n"
	$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.text = output_buffer
	$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.scroll_vertical = $VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.get_line_count()

func update_mod_info():
	var all_mod_info = lua_bridge.get_all_mod_info()
	var info_text = "Loaded Mods:\n"
	
	if all_mod_info.size() == 0:
		info_text += "No mods loaded"
	else:
		for mod_info in all_mod_info:
			info_text += "• " + mod_info["name"] + " v" + mod_info["version"] + " by " + mod_info["author"]
			if lua_bridge.is_mod_enabled(mod_info["name"]):
				info_text += " (ENABLED)"
			else:
				info_text += " (DISABLED)"
			info_text += "\n  " + mod_info["description"] + "\n\n"
	
	$VBoxContainer/ScrollContainer/MainContent/ModInfoTextEdit.text = info_text

# Mod Management Functions
func _on_load_mods_button_pressed():
	append_output("Loading mods from directory...")
	var success = lua_bridge.load_mods_from_directory("res://mods")
	append_output("Load result: " + str(success))
	update_mod_info()

func _on_load_specific_mod_button_pressed():
	append_output("Loading specific mod JSON...")
	var success = lua_bridge.load_mod_from_json("res://mods/mod.json")
	append_output("Load result: " + str(success))
	update_mod_info()

func _on_enable_mod_button_pressed():
	append_output("Enabling ExampleMod...")
	lua_bridge.enable_mod("ExampleMod")
	update_mod_info()

func _on_disable_mod_button_pressed():
	append_output("Disabling ExampleMod...")
	lua_bridge.disable_mod("ExampleMod")
	update_mod_info()

func _on_reload_mod_button_pressed():
	append_output("Reloading ExampleMod...")
	var success = lua_bridge.reload_mod("ExampleMod")
	append_output("Reload result: " + str(success))
	update_mod_info()

# Lua Scripting Functions
func _on_execute_string_button_pressed():
	append_output("Executing Lua string...")
	var lua_code = """
print("Hello from Lua!")
print("Line 2")
print("Line 3")
print("Line 4")
print("Line 5")
print("Line 6")
print("Line 7")
print("Line 8 - this should work")

-- Test variables
local x = 10
local y = 20
print("Sum: " .. (x + y))

-- Test tables
local table_test = {name = "test", value = 42}
print("Table test: " .. table_test.name .. " = " .. table_test.value)

-- Test local function
local function simple_calc(a, b)
    return a + b
end
print("Simple calculation: " .. simple_calc(5, 3))

-- Test global variable access
_G.test_global = "Hello from Lua global!"
print("Set global variable: test_global")

-- Define the advanced_calculation function in global scope
_G.advanced_calculation = function(base, multiplier, options)
    local bonus = options.bonus or 0
    local percentage = options.percentage or 0
    local result = (base * multiplier) + bonus
    result = result * (1 + percentage / 100)
    return result
end
print("Defined advanced_calculation function")

-- Test new features
print("Testing new features...")
local result = _G.advanced_calculation(100, 1.5, {bonus = 25, percentage = 10})
print("Advanced calculation result: " .. result)

return "Lua execution completed with new features!"
"""
	lua_bridge.exec_string(lua_code)

func _on_call_function_button_pressed():
	append_output("Calling Lua function...")
	var args = Array()
	args.append(100)  # base_damage
	args.append(1.5)  # weapon_multiplier
	args.append(0.2)  # armor_reduction
	
	var result = lua_bridge.call_function("calculate_damage", args)
	append_output("Function result: " + str(result))

func _on_set_global_button_pressed():
	append_output("Setting global variable...")
	lua_bridge.set_global("player_health", 100)
	lua_bridge.set_global("player_level", 5)
	lua_bridge.set_global("player_name", "Hero")
	append_output("Global variables set")

func _on_get_global_button_pressed():
	append_output("Getting global variables...")
	var health = lua_bridge.get_global("player_health")
	var level = lua_bridge.get_global("player_level")
	var name = lua_bridge.get_global("player_name")
	append_output("Player: " + str(name) + ", Level: " + str(level) + ", Health: " + str(health))

func _on_test_all_features_button_pressed():
	append_output("Testing all new features...")
	lua_bridge.call_function("test_all_features", Array())

# Lifecycle Functions
func _on_call_init_button_pressed():
	append_output("Calling on_init()...")
	lua_bridge.call_on_init()

func _on_call_ready_button_pressed():
	append_output("Calling on_ready()...")
	lua_bridge.call_on_ready()

func _on_call_exit_button_pressed():
	append_output("Calling on_exit()...")
	lua_bridge.call_on_exit()

# Sandboxing Functions
func _on_toggle_sandbox_button_pressed():
	var current_sandboxed = lua_bridge.is_sandboxed()
	lua_bridge.set_sandboxed(!current_sandboxed)
	append_output("Sandbox mode: " + str(lua_bridge.is_sandboxed()))

func _on_test_unsafe_code_button_pressed():
	append_output("Testing unsafe code...")
	var unsafe_code = """
-- This should fail in sandboxed mode
os.execute("echo 'This is unsafe!'")
"""
	lua_bridge.exec_string(unsafe_code)

# Safe Casting & Wrappers
func _on_test_safe_casting_button_pressed():
	append_output("Testing safe casting features...")
	var main_scene = get_node("/root/Main")
	var is_control: bool = false
	var is_node: bool = false
	var gd_class_name: String = ""
	if main_scene:
		is_control = lua_bridge.is_instance(main_scene, "Control")
		is_node = lua_bridge.is_instance(main_scene, "Node")
		append_output("Main scene is Control: " + str(is_control))
		append_output("Main scene is Node: " + str(is_node))
		gd_class_name = lua_bridge.get_class(main_scene)
		append_output("Main scene class: " + str(gd_class_name))

func _on_test_wrappers_button_pressed():
	append_output("Testing object wrappers...")
	var main_scene = get_node("/root/Main")
	var wrapper = null
	var is_valid: bool = false
	var child_count: int = 0
	var visible: bool = false
	if main_scene:
		wrapper = lua_bridge.create_wrapper(main_scene, "Control")
		if wrapper:
			append_output("Wrapper created successfully!")
			is_valid = lua_bridge.is_wrapper_valid(wrapper)
			append_output("Wrapper valid: " + str(is_valid))
			child_count = lua_bridge.call_method(wrapper, "get_child_count")
			append_output("Child count through wrapper: " + str(child_count))
			visible = lua_bridge.get_property(wrapper, "visible")
			append_output("Visible property through wrapper: " + str(visible))
			lua_bridge.set_property(wrapper, "visible", true)
			append_output("Set visible property to true")

func _on_test_type_checking_button_pressed():
	append_output("Testing type checking...")
	var main_scene = get_node("/root/Main")
	var vbox = get_node("/root/Main/VBoxContainer/ScrollContainer/MainContent")
	var is_control: bool = false
	var is_node: bool = false
	var is_object: bool = false
	var gd_class_name: String = ""
	var is_vbox: bool = false
	if main_scene:
		append_output("Main scene type checks:")
		is_control = lua_bridge.is_instance(main_scene, "Control")
		is_node = lua_bridge.is_instance(main_scene, "Node")
		is_object = lua_bridge.is_instance(main_scene, "Object")
		gd_class_name = lua_bridge.get_class(main_scene)
		append_output("  is Control: " + str(is_control))
		append_output("  is Node: " + str(is_node))
		append_output("  is Object: " + str(is_object))
		append_output("  class: " + str(gd_class_name))
	if vbox:
		append_output("VBoxContainer type checks:")
		is_vbox = lua_bridge.is_instance(vbox, "VBoxContainer")
		is_control = lua_bridge.is_instance(vbox, "Control")
		gd_class_name = lua_bridge.get_class(vbox)
		append_output("  is VBoxContainer: " + str(is_vbox))
		append_output("  is Control: " + str(is_control))
		append_output("  class: " + str(gd_class_name))

# Godot Object Access
func _on_test_get_node_button_pressed():
	append_output("Testing get_node()...")
	
	# Test get_node - need to pass both object and path
	var main_scene = get_node("/root/Main")
	if main_scene:
		append_output("Found main scene via get_node!")
		
		# Test getting a specific child - need to pass the main scene object and the path
		var vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		if vbox:
			append_output("Found VBoxContainer via get_node!")
		else:
			append_output("Could not find VBoxContainer via get_node")
	else:
		append_output("Could not find main scene via get_node")

func _on_test_get_children_button_pressed():
	append_output("Testing get_children()...")
	
	var main_scene = get_node("/root/Main")
	if main_scene:
		# Test get_children - need to pass the object
		var children = lua_bridge.get_children(main_scene)
		if children:
			append_output("Main scene has " + str(children.size()) + " children")
			for i in range(min(children.size(), 5)):  # Show first 5 children
				var child = children[i]
				var gd_class_name = lua_bridge.get_class(child)
				append_output("  Child " + str(i) + ": " + str(gd_class_name))
		else:
			append_output("Could not get children")

func _on_test_property_access_button_pressed():
	append_output("Testing property access...")
	
	var main_scene = get_node("/root/Main")
	if main_scene:
		var vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		if vbox:
			# Test property access
			var visible = lua_bridge.get_property(vbox, "visible")
			append_output("VBoxContainer visible: " + str(visible))
			
			# Test property setting
			lua_bridge.set_property(vbox, "visible", true)
			append_output("Set VBoxContainer visible to true")
			
			# Test getting the property again
			visible = lua_bridge.get_property(vbox, "visible")
			append_output("VBoxContainer visible after setting: " + str(visible))

func _on_test_method_call_button_pressed():
	append_output("Testing method calls...")
	
	var main_scene = get_node("/root/Main")
	if main_scene:
		var vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		if vbox:
			# Test method call
			var child_count = lua_bridge.call_method(vbox, "get_child_count")
			append_output("VBoxContainer child count: " + str(child_count))
			
			# Test another method
			var is_visible = lua_bridge.call_method(vbox, "is_visible")
			append_output("VBoxContainer is_visible: " + str(is_visible))

# Resource & Scene Management
func _on_test_load_resource_button_pressed():
	append_output("Testing load_resource()...")
	
	# Test load_resource
	var resource = lua_bridge.load_resource("res://icon.png")
	if resource:
		append_output("Successfully loaded resource!")
		
		# Test get_class
		var gd_class_name = lua_bridge.get_class(resource)
		append_output("Resource class: " + str(gd_class_name))
	else:
		append_output("Could not load resource (this is expected)")

func _on_test_instance_scene_button_pressed():
	append_output("Testing instance_scene()...")
	
	# Test instance_scene (this would work if we had a scene file)
	var scene = lua_bridge.instance_scene("res://main.tscn")
	if scene:
		append_output("Successfully instanced scene!")
		
		# Test get_class
		var gd_class_name = lua_bridge.get_class(scene)
		append_output("Scene class: " + str(gd_class_name))
	else:
		append_output("Could not instance scene (this is expected)")

func _on_test_resource_wrapper_button_pressed():
	append_output("Testing resource wrappers...")
	
	var resource = lua_bridge.load_resource("res://icon.png")
	if resource:
		# Create a wrapper
		var wrapper = lua_bridge.create_wrapper(resource, "Resource")
		if wrapper:
			append_output("Resource wrapper created!")
			
			# Test wrapper validity
			var is_valid = lua_bridge.is_wrapper_valid(wrapper)
			append_output("Resource wrapper valid: " + str(is_valid))
			
			# Test property access through wrapper
			var resource_path = lua_bridge.get_property(wrapper, "resource_path")
			append_output("Resource path through wrapper: " + str(resource_path))

# Events & Signals
func _on_test_emit_event_button_pressed():
	append_output("Testing emit_event()...")
	
	# Test emit_event
	lua_bridge.emit_event("test_event", {"message": "Hello from GDScript!", "timestamp": Time.get_time_dict_from_system()})
	append_output("Emitted test_event")
	
	# Test another event
	lua_bridge.emit_event("player_damaged", {"damage": 25, "health": 75})
	append_output("Emitted player_damaged event")

func _on_test_subscribe_event_button_pressed():
	append_output("Testing subscribe_event()...")
	
	# This would typically be done in Lua, but we can test the system
	append_output("Event system ready for Lua subscriptions")
	append_output("Lua mods can subscribe to events using subscribe_event()")

func _on_test_signal_connection_button_pressed():
	append_output("Testing signal connection...")
	
	var main_scene = get_node("/root/Main")
	if main_scene:
		# Try to connect to a signal (this would work if the signal exists)
		var success = lua_bridge.connect_signal(main_scene, "ready", "on_main_ready")
		if success:
			append_output("Successfully connected to ready signal!")
		else:
			append_output("Could not connect to ready signal (this is expected)")

# Coroutines
func _on_test_create_coroutine_button_pressed():
	append_output("Testing create_coroutine()...")
	
	# Test create_coroutine - need name, function name, and arguments
	var args = Array()
	args.append("test_data")
	var co_id = lua_bridge.create_coroutine("test_coroutine", "test_coroutine", args)
	if co_id:
		append_output("Created coroutine with ID: " + str(co_id))
	else:
		append_output("Could not create coroutine")

func _on_test_resume_coroutine_button_pressed():
	append_output("Testing resume_coroutine()...")
	
	# First create a coroutine
	var args = Array()
	args.append("test_data")
	var co_id = lua_bridge.create_coroutine("test_coroutine", "test_coroutine", args)
	if co_id:
		append_output("Created coroutine with ID: " + str(co_id))
		
		# Test resume_coroutine - need coroutine name and data
		var result = lua_bridge.resume_coroutine("test_coroutine", "resume_data")
		append_output("Coroutine resume result: " + str(result))
	else:
		append_output("Could not create coroutine for testing")

func _on_test_coroutine_status_button_pressed():
	append_output("Testing coroutine status...")
	
	# Create a coroutine
	var args = Array()
	args.append("test_data")
	var co_id = lua_bridge.create_coroutine("test_coroutine", "test_coroutine", args)
	if co_id:
		append_output("Created coroutine with ID: " + str(co_id))
		
		# Test is_coroutine_active
		var is_active = lua_bridge.is_coroutine_active("test_coroutine")
		append_output("Coroutine active: " + str(is_active))
		
		# Resume it
		lua_bridge.resume_coroutine("test_coroutine", "resume_data")
		
		# Check status again
		is_active = lua_bridge.is_coroutine_active("test_coroutine")
		append_output("Coroutine active after resume: " + str(is_active))
		
		# Clean up
		lua_bridge.cleanup_coroutines()
		append_output("Cleaned up coroutines")

func _process(delta):
	# Call update hook every frame for mods
	lua_bridge.call_on_update(delta)

func _exit_tree():
	# Clean up when the scene is destroyed
	if lua_bridge:
		lua_bridge.call_on_exit()
		lua_bridge.unload() 
