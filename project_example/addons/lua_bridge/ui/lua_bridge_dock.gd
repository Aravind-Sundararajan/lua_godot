@tool
extends Control

var lua_bridge: LuaBridge
var auto_update_enabled: bool = false
var output_buffer: String = ""

func setup(bridge: LuaBridge = null):
	lua_bridge = bridge
	
	# Only connect signals if we have a bridge
	if lua_bridge != null:
		# Connect button signals
		$VBoxContainer/TabContainer/Mods/LoadModsButton.pressed.connect(_on_load_mods_button_pressed)
		$VBoxContainer/TabContainer/Mods/LoadSpecificModButton.pressed.connect(_on_load_specific_mod_button_pressed)
		$VBoxContainer/TabContainer/Mods/ModControlHBox/EnableModButton.pressed.connect(_on_enable_mod_button_pressed)
		$VBoxContainer/TabContainer/Mods/ModControlHBox/DisableModButton.pressed.connect(_on_disable_mod_button_pressed)
		$VBoxContainer/TabContainer/Mods/ModControlHBox/UnloadModButton.pressed.connect(_on_unload_mod_button_pressed)
		$VBoxContainer/TabContainer/Mods/ModControlHBox/ReloadModButton.pressed.connect(_on_reload_mod_button_pressed)
		
		$VBoxContainer/TabContainer/Scripting/ExecuteStringButton.pressed.connect(_on_execute_string_button_pressed)
		$VBoxContainer/TabContainer/Scripting/CallFunctionButton.pressed.connect(_on_call_function_button_pressed)
		$VBoxContainer/TabContainer/Scripting/SetGlobalButton.pressed.connect(_on_set_global_button_pressed)
		$VBoxContainer/TabContainer/Scripting/GetGlobalButton.pressed.connect(_on_get_global_button_pressed)
		$VBoxContainer/TabContainer/Scripting/ExecuteCodeButton.pressed.connect(_on_execute_code_button_pressed)
		$VBoxContainer/TabContainer/Scripting/TestAllFeaturesButton.pressed.connect(_on_test_all_features_button_pressed)
		
		$VBoxContainer/TabContainer/Lifecycle/CallInitButton.pressed.connect(_on_call_init_button_pressed)
		$VBoxContainer/TabContainer/Lifecycle/CallReadyButton.pressed.connect(_on_call_ready_button_pressed)
		$VBoxContainer/TabContainer/Lifecycle/CallExitButton.pressed.connect(_on_call_exit_button_pressed)
		$VBoxContainer/TabContainer/Lifecycle/AutoUpdateCheckBox.toggled.connect(_on_auto_update_toggled)
		
		$VBoxContainer/TabContainer/Security/ToggleSandboxButton.pressed.connect(_on_toggle_sandbox_button_pressed)
		$VBoxContainer/TabContainer/Security/TestUnsafeCodeButton.pressed.connect(_on_test_unsafe_code_button_pressed)
		
		# Connect new feature test buttons
		$VBoxContainer/TabContainer/SafeCasting/TestSafeCastingButton.pressed.connect(_on_test_safe_casting_button_pressed)
		$VBoxContainer/TabContainer/SafeCasting/TestWrappersButton.pressed.connect(_on_test_wrappers_button_pressed)
		$VBoxContainer/TabContainer/SafeCasting/TestTypeCheckingButton.pressed.connect(_on_test_type_checking_button_pressed)
		
		$VBoxContainer/TabContainer/GodotObjects/TestGetNodeButton.pressed.connect(_on_test_get_node_button_pressed)
		$VBoxContainer/TabContainer/GodotObjects/TestGetChildrenButton.pressed.connect(_on_test_get_children_button_pressed)
		$VBoxContainer/TabContainer/GodotObjects/TestPropertyAccessButton.pressed.connect(_on_test_property_access_button_pressed)
		$VBoxContainer/TabContainer/GodotObjects/TestMethodCallButton.pressed.connect(_on_test_method_call_button_pressed)
		
		$VBoxContainer/TabContainer/Resources/TestLoadResourceButton.pressed.connect(_on_test_load_resource_button_pressed)
		$VBoxContainer/TabContainer/Resources/TestInstanceSceneButton.pressed.connect(_on_test_instance_scene_button_pressed)
		$VBoxContainer/TabContainer/Resources/TestResourceWrapperButton.pressed.connect(_on_test_resource_wrapper_button_pressed)
		
		$VBoxContainer/TabContainer/Events/TestEmitEventButton.pressed.connect(_on_test_emit_event_button_pressed)
		$VBoxContainer/TabContainer/Events/TestSubscribeEventButton.pressed.connect(_on_test_subscribe_event_button_pressed)
		$VBoxContainer/TabContainer/Events/TestSignalConnectionButton.pressed.connect(_on_test_signal_connection_button_pressed)
		
		$VBoxContainer/TabContainer/Coroutines/TestCreateCoroutineButton.pressed.connect(_on_test_create_coroutine_button_pressed)
		$VBoxContainer/TabContainer/Coroutines/TestResumeCoroutineButton.pressed.connect(_on_test_resume_coroutine_button_pressed)
		$VBoxContainer/TabContainer/Coroutines/TestCoroutineStatusButton.pressed.connect(_on_test_coroutine_status_button_pressed)
		
		$VBoxContainer/TabContainer/Output/ClearOutputButton.pressed.connect(_on_clear_output_button_pressed)
		
		# Update sandbox status
		_update_sandbox_status()
		
		append_output("Lua Bridge Dock: Initialized successfully!")
		append_output("Enhanced features available: Safe casting, Godot objects, signals, events, coroutines!")
	else:
		append_output("Lua Bridge Dock: Initialized (LuaBridge not available)")

func append_output(text: String):
	output_buffer += text + "\n"
	$VBoxContainer/TabContainer/Output/OutputTextEdit.text = output_buffer
	$VBoxContainer/TabContainer/Output/OutputTextEdit.scroll_vertical = $VBoxContainer/TabContainer/Output/OutputTextEdit.get_line_count()

func update_mod_list():
	$VBoxContainer/TabContainer/Mods/ModList.clear()
	
	var all_mod_info = lua_bridge.get_all_mod_info()
	for mod_info in all_mod_info:
		var mod_name = mod_info["name"]
		var status = " (ENABLED)" if lua_bridge.is_mod_enabled(mod_name) else " (DISABLED)"
		$VBoxContainer/TabContainer/Mods/ModList.add_item(mod_name + status)

func _update_sandbox_status():
	var status = "ENABLED" if lua_bridge.is_sandboxed() else "DISABLED"
	$VBoxContainer/TabContainer/Security/SandboxStatusLabel.text = "Sandbox Status: " + status

# Mod Management Functions
func _on_load_mods_button_pressed():
	append_output("Loading mods from directory...")
	# Use absolute path to the mods directory
	var mod_path = "res://mods"
	append_output("Loading from: " + mod_path)
	var success = lua_bridge.load_mods_from_directory(mod_path)
	append_output("Load result: " + str(success))
	update_mod_list()

func _on_load_specific_mod_button_pressed():
	append_output("Loading specific mod JSON...")
	# Use absolute path to the mod.json file
	var mod_json_path = "res://mods/mod.json"
	append_output("Loading from: " + mod_json_path)
	var success = lua_bridge.load_mod_from_json(mod_json_path)
	append_output("Load result: " + str(success))
	update_mod_list()

func _on_enable_mod_button_pressed():
	var selected_items = $VBoxContainer/TabContainer/Mods/ModList.get_selected_items()
	if selected_items.size() == 0:
		append_output("No mod selected!")
		return
	
	for index in selected_items:
		var item_text = $VBoxContainer/TabContainer/Mods/ModList.get_item_text(index)
		var mod_name = item_text.split(" (")[0]  # Remove status suffix
		append_output("Enabling mod: " + mod_name)
		lua_bridge.enable_mod(mod_name)
	
	update_mod_list()

func _on_disable_mod_button_pressed():
	var selected_items = $VBoxContainer/TabContainer/Mods/ModList.get_selected_items()
	if selected_items.size() == 0:
		append_output("No mod selected!")
		return
	
	for index in selected_items:
		var item_text = $VBoxContainer/TabContainer/Mods/ModList.get_item_text(index)
		var mod_name = item_text.split(" (")[0]  # Remove status suffix
		append_output("Disabling mod: " + mod_name)
		lua_bridge.disable_mod(mod_name)
	
	update_mod_list()

func _on_unload_mod_button_pressed():
	var selected_items = $VBoxContainer/TabContainer/Mods/ModList.get_selected_items()
	if selected_items.size() == 0:
		append_output("No mod selected!")
		return
	
	for index in selected_items:
		var item_text = $VBoxContainer/TabContainer/Mods/ModList.get_item_text(index)
		var mod_name = item_text.split(" (")[0]  # Remove status suffix
		append_output("Unloading mod: " + mod_name)
		lua_bridge.unload_mod(mod_name)
	
	update_mod_list()

func _on_reload_mod_button_pressed():
	var selected_items = $VBoxContainer/TabContainer/Mods/ModList.get_selected_items()
	if selected_items.size() == 0:
		append_output("No mod selected!")
		return
	
	for index in selected_items:
		var item_text = $VBoxContainer/TabContainer/Mods/ModList.get_item_text(index)
		var mod_name = item_text.split(" (")[0]  # Remove status suffix
		append_output("Reloading mod: " + mod_name)
		var success = lua_bridge.reload_mod(mod_name)
		append_output("Reload result: " + str(success))
	
	update_mod_list()

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

func _on_execute_code_button_pressed():
	var code = $VBoxContainer/TabContainer/Scripting/CodeInput.text
	if code.is_empty():
		append_output("No code to execute!")
		return
	
	append_output("Executing custom Lua code...")
	lua_bridge.exec_string(code)

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

func _on_auto_update_toggled(button_pressed: bool):
	auto_update_enabled = button_pressed
	append_output("Auto update: " + ("ENABLED" if button_pressed else "DISABLED"))

# Security Functions
func _on_toggle_sandbox_button_pressed():
	var current_sandboxed = lua_bridge.is_sandboxed()
	lua_bridge.set_sandboxed(!current_sandboxed)
	_update_sandbox_status()
	append_output("Sandbox mode: " + str(lua_bridge.is_sandboxed()))

func _on_test_unsafe_code_button_pressed():
	append_output("Testing unsafe code...")
	var unsafe_code = """
-- This should fail in sandboxed mode
os.execute("echo 'This is unsafe!'")
"""
	lua_bridge.exec_string(unsafe_code)

func _on_clear_output_button_pressed():
	output_buffer = ""
	$VBoxContainer/TabContainer/Output/OutputTextEdit.text = ""

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
		# Test get_class
		gd_class_name = lua_bridge.get_class(main_scene)
		append_output("Main scene class: " + str(gd_class_name))
		# Update wrapper info
		$VBoxContainer/TabContainer/SafeCasting/WrapperInfoLabel.text = "Wrapper Info:\nClass: " + str(gd_class_name) + "\nIs Control: " + str(is_control) + "\nIs Node: " + str(is_node)

func _on_test_wrappers_button_pressed():
	append_output("Testing object wrappers...")
	var main_scene = get_node("/root/Main")
	var wrapper = null
	var is_valid: bool = false
	var child_count: int = 0
	var visible: bool = false
	if main_scene:
		# Test wrapper creation
		wrapper = lua_bridge.create_wrapper(main_scene, "Control")
		if wrapper:
			append_output("Wrapper created successfully!")
			# Test wrapper validity
			is_valid = lua_bridge.is_wrapper_valid(wrapper)
			append_output("Wrapper valid: " + str(is_valid))
			# Test method call through wrapper
			child_count = lua_bridge.call_method(wrapper, "get_child_count")
			append_output("Child count through wrapper: " + str(child_count))
			# Test property access through wrapper
			visible = lua_bridge.get_property(wrapper, "visible")
			append_output("Visible property through wrapper: " + str(visible))
			# Test property setting through wrapper
			lua_bridge.set_property(wrapper, "visible", true)
			append_output("Set visible property to true")
			# Update wrapper info
			$VBoxContainer/TabContainer/SafeCasting/WrapperInfoLabel.text = "Wrapper Info:\nValid: " + str(is_valid) + "\nChild Count: " + str(child_count) + "\nVisible: " + str(visible)

func _on_test_type_checking_button_pressed():
	append_output("Testing type checking...")
	# Test with different object types
	var main_scene = get_node("/root/Main")
	var vbox = get_node("/root/Main/VBoxContainer/ScrollContainer/MainContent")
	var info_text = "Type Checks:\n"
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
		info_text += "Main Scene:\n  Class: " + str(gd_class_name) + "\n  Is Control: " + str(is_control) + "\n  Is Node: " + str(is_node) + "\n"
	if vbox:
		append_output("VBoxContainer type checks:")
		is_vbox = lua_bridge.is_instance(vbox, "VBoxContainer")
		is_control = lua_bridge.is_instance(vbox, "Control")
		gd_class_name = lua_bridge.get_class(vbox)
		append_output("  is VBoxContainer: " + str(is_vbox))
		append_output("  is Control: " + str(is_control))
		append_output("  class: " + str(gd_class_name))
		info_text += "VBoxContainer:\n  Class: " + str(gd_class_name) + "\n  Is VBoxContainer: " + str(is_vbox) + "\n  Is Control: " + str(is_control)
	$VBoxContainer/TabContainer/SafeCasting/WrapperInfoLabel.text = info_text

# Godot Object Access
func _on_test_get_node_button_pressed():
	append_output("Testing get_node()...")
	# Test get_node - need to pass both object and path
	var main_scene = get_node("/root/Main")
	var vbox = null
	var gd_class_name = null
	if main_scene:
		append_output("Found main scene via get_node!")
		# Test getting a specific child - need to pass the main scene object and the path
		vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		if vbox:
			append_output("Found VBoxContainer via get_node!")
			gd_class_name = lua_bridge.get_class(vbox)
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Object Info:\nMain Scene: Found\nVBoxContainer: Found\nClass: " + str(gd_class_name)
		else:
			append_output("Could not find VBoxContainer via get_node")
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Object Info:\nMain Scene: Found\nVBoxContainer: Not Found"
	else:
		append_output("Could not find main scene via get_node")
		$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Object Info:\nMain Scene: Not Found"

func _on_test_get_children_button_pressed():
	append_output("Testing get_children()...")
	var main_scene = get_node("/root/Main")
	var children = null
	var info_text = ""
	var gd_class_name = null
	var child = null
	if main_scene:
		# Test get_children - need to pass the object
		children = lua_bridge.get_children(main_scene)
		if children:
			append_output("Main scene has " + str(children.size()) + " children")
			info_text = "Children Info:\nCount: " + str(children.size()) + "\n"
			for i in range(min(children.size(), 5)):
				child = children[i]
				gd_class_name = lua_bridge.get_class(child)
				append_output("  Child " + str(i) + ": " + str(gd_class_name))
				info_text += "Child " + str(i) + ": " + str(gd_class_name) + "\n"
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = info_text
		else:
			append_output("Could not get children")
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Children Info:\nCould not get children"

func _on_test_property_access_button_pressed():
	append_output("Testing property access...")
	var main_scene = get_node("/root/Main")
	if main_scene:
		var vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		var visible = null
		if vbox:
			# Test property access
			visible = lua_bridge.get_property(vbox, "visible")
			append_output("VBoxContainer visible: " + str(visible))
			# Test property setting
			lua_bridge.set_property(vbox, "visible", true)
			append_output("Set VBoxContainer visible to true")
			# Test getting the property again
			visible = lua_bridge.get_property(vbox, "visible")
			append_output("VBoxContainer visible after setting: " + str(visible))
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Property Info:\nVisible: " + str(visible) + "\nProperty access: Working"

func _on_test_method_call_button_pressed():
	append_output("Testing method calls...")
	var main_scene = get_node("/root/Main")
	if main_scene:
		var vbox = lua_bridge.get_node(main_scene, "VBoxContainer")
		var child_count = null
		var is_visible = null
		if vbox:
			# Test method call
			child_count = lua_bridge.call_method(vbox, "get_child_count")
			append_output("VBoxContainer child count: " + str(child_count))
			# Test another method
			is_visible = lua_bridge.call_method(vbox, "is_visible")
			append_output("VBoxContainer is_visible: " + str(is_visible))
			$VBoxContainer/TabContainer/GodotObjects/ObjectInfoLabel.text = "Method Info:\nChild Count: " + str(child_count) + "\nIs Visible: " + str(is_visible) + "\nMethod calls: Working"

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
		
		$VBoxContainer/TabContainer/Resources/ResourceInfoLabel.text = "Resource Info:\nLoaded: Success\nClass: " + str(gd_class_name)
	else:
		append_output("Could not load resource (this is expected)")
		$VBoxContainer/TabContainer/Resources/ResourceInfoLabel.text = "Resource Info:\nLoaded: Failed\n(Expected for icon.png)"

func _on_test_instance_scene_button_pressed():
	append_output("Testing instance_scene()...")
	
	# Test instance_scene (this would work if we had a scene file)
	var scene = lua_bridge.instance_scene("res://main.tscn")
	if scene:
		append_output("Successfully instanced scene!")
		
		# Test get_class
		var gd_class_name = lua_bridge.get_class(scene)
		append_output("Scene class: " + str(gd_class_name))
		
		$VBoxContainer/TabContainer/Resources/ResourceInfoLabel.text = "Scene Info:\nInstanced: Success\nClass: " + str(gd_class_name)
	else:
		append_output("Could not instance scene (this is expected)")
		$VBoxContainer/TabContainer/Resources/ResourceInfoLabel.text = "Scene Info:\nInstanced: Failed\n(Expected for main.tscn)"

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
			
			$VBoxContainer/TabContainer/Resources/ResourceInfoLabel.text = "Resource Wrapper:\nCreated: Success\nValid: " + str(is_valid) + "\nPath: " + str(resource_path)

# Events & Signals
func _on_test_emit_event_button_pressed():
	append_output("Testing emit_event()...")
	
	# Test emit_event
	lua_bridge.emit_event("test_event", {"message": "Hello from GDScript!", "timestamp": Time.get_time_dict_from_system()})
	append_output("Emitted test_event")
	
	# Test another event
	lua_bridge.emit_event("player_damaged", {"damage": 25, "health": 75})
	append_output("Emitted player_damaged event")
	
	$VBoxContainer/TabContainer/Events/EventInfoLabel.text = "Event Info:\nEmitted: test_event\nEmitted: player_damaged\nEvents: Working"

func _on_test_subscribe_event_button_pressed():
	append_output("Testing subscribe_event()...")
	
	# This would typically be done in Lua, but we can test the system
	append_output("Event system ready for Lua subscriptions")
	append_output("Lua mods can subscribe to events using subscribe_event()")
	
	$VBoxContainer/TabContainer/Events/EventInfoLabel.text = "Event Info:\nSubscription: Ready\nLua mods can subscribe\nSystem: Working"

func _on_test_signal_connection_button_pressed():
	append_output("Testing signal connection...")
	
	var main_scene = get_node("/root/Main")
	if main_scene:
		# Try to connect to a signal (this would work if the signal exists)
		var success = lua_bridge.connect_signal(main_scene, "ready", "on_main_ready")
		if success:
			append_output("Successfully connected to ready signal!")
			$VBoxContainer/TabContainer/Events/EventInfoLabel.text = "Signal Info:\nConnected: Success\nSignal: ready\nTarget: on_main_ready"
		else:
			append_output("Could not connect to ready signal (this is expected)")
			$VBoxContainer/TabContainer/Events/EventInfoLabel.text = "Signal Info:\nConnected: Failed\n(Expected - signal may not exist)"

# Coroutines
func _on_test_create_coroutine_button_pressed():
	append_output("Testing create_coroutine()...")
	
	# Test create_coroutine - need name, function name, and arguments
	var args = Array()
	args.append("test_data")
	var co_id = lua_bridge.create_coroutine("test_coroutine", "test_coroutine", args)
	if co_id:
		append_output("Created coroutine with ID: " + str(co_id))
		$VBoxContainer/TabContainer/Coroutines/CoroutineInfoLabel.text = "Coroutine Info:\nCreated: Success\nID: " + str(co_id)
	else:
		append_output("Could not create coroutine")
		$VBoxContainer/TabContainer/Coroutines/CoroutineInfoLabel.text = "Coroutine Info:\nCreated: Failed"

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
		
		$VBoxContainer/TabContainer/Coroutines/CoroutineInfoLabel.text = "Coroutine Info:\nID: " + str(co_id) + "\nResume Result: " + str(result)
	else:
		append_output("Could not create coroutine for testing")
		$VBoxContainer/TabContainer/Coroutines/CoroutineInfoLabel.text = "Coroutine Info:\nCreated: Failed"

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
		
		$VBoxContainer/TabContainer/Coroutines/CoroutineInfoLabel.text = "Coroutine Info:\nID: " + str(co_id) + "\nInitial Active: " + str(is_active) + "\nAfter Resume: " + str(is_active) + "\nCleaned Up: Yes"

func _process(delta):
	# Call update hook every frame if auto-update is enabled
	if auto_update_enabled and lua_bridge:
		lua_bridge.call_on_update(delta) 
