@tool
extends Control

var auto_update_enabled: bool = false
var output_buffer: String = ""
var lua_bridge: LuaBridge = null  # Store the bridge instance

func setup(bridge: LuaBridge = null):
	# Store the bridge instance
	lua_bridge = bridge
	
	# Only use the bridge parameter - skip the problematic autoload
	if bridge == null:
		print("No bridge provided, dock will work without Lua functionality")
		append_output("Lua Bridge Dock: Initialized (LuaBridge not available)")
		return
	
	# Connect button signals only if we have a bridge
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
	$VBoxContainer/TabContainer/Scripting/TestAutoloadButton.pressed.connect(_on_test_autoload_button_pressed)
	
	$VBoxContainer/TabContainer/Lifecycle/CallInitButton.pressed.connect(_on_call_init_button_pressed)
	$VBoxContainer/TabContainer/Lifecycle/CallReadyButton.pressed.connect(_on_call_ready_button_pressed)
	$VBoxContainer/TabContainer/Lifecycle/CallExitButton.pressed.connect(_on_call_exit_button_pressed)
	$VBoxContainer/TabContainer/Lifecycle/LoadLifecycleTestButton.pressed.connect(_on_load_lifecycle_test_button_pressed)
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

# Helper function to get the bridge instance
func get_bridge() -> LuaBridge:
	return lua_bridge

func append_output(text: String):
	output_buffer += text + "\n"
	$VBoxContainer/TabContainer/Output/OutputTextEdit.text = output_buffer
	$VBoxContainer/TabContainer/Output/OutputTextEdit.scroll_vertical = $VBoxContainer/TabContainer/Output/OutputTextEdit.get_line_count()

func update_mod_list():
	$VBoxContainer/TabContainer/Mods/ModList.clear()
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		return
		
	var all_mod_info = lua_bridge.get_all_mod_info()
	for mod_info in all_mod_info:
		var mod_name = mod_info["name"]
		var status = " (ENABLED)" if lua_bridge.is_mod_enabled(mod_name) else " (DISABLED)"
		$VBoxContainer/TabContainer/Mods/ModList.add_item(mod_name + status)

func _update_sandbox_status():
	var lua_bridge = get_bridge()
	if not lua_bridge:
		return
		
	var status = "ENABLED" if lua_bridge.is_sandboxed() else "DISABLED"
	$VBoxContainer/TabContainer/Security/SandboxStatusLabel.text = "Sandbox Status: " + status

# Mod Management Functions
func _on_load_mods_button_pressed():
	append_output("Loading mods from directory...")
	# Use absolute path to the mods directory
	var mod_path = "res://mods"
	append_output("Loading from: " + mod_path)
	var lua_bridge = get_bridge()
	if lua_bridge:
		var success = lua_bridge.load_mods_from_directory(mod_path)
		append_output("Load result: " + str(success))
		update_mod_list()
	else:
		append_output("ERROR: Lua bridge not available")

func _on_load_specific_mod_button_pressed():
	append_output("Loading specific mod JSON...")
	# Use absolute path to the mod.json file
	var mod_json_path = "res://mods/mod.json"
	append_output("Loading from: " + mod_json_path)
	var lua_bridge = get_bridge()
	if lua_bridge:
		var success = lua_bridge.load_mod_from_json(mod_json_path)
		append_output("Load result: " + str(success))
		update_mod_list()
	else:
		append_output("ERROR: Lua bridge not available")

func _on_enable_mod_button_pressed():
	var selected_items = $VBoxContainer/TabContainer/Mods/ModList.get_selected_items()
	if selected_items.size() == 0:
		append_output("No mod selected!")
		return
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
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
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
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
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
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
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
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
	append_output("Executing Lua string with lifecycle functions...")
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

-- Define the advanced_calculation function in global scope with better error handling
_G.advanced_calculation = function(base, multiplier, options)
	-- Ensure options is a table, even if nil is passed
	options = options or {}
	
	-- Validate inputs
	if type(base) ~= "number" then
		error("base must be a number, got " .. type(base))
	end
	
	if type(multiplier) ~= "number" then
		error("multiplier must be a number, got " .. type(multiplier))
	end
	
	-- Calculate base result
	local result = base * multiplier
	
	-- Apply bonus if provided
	if options.bonus and type(options.bonus) == "number" then
		result = result + options.bonus
	end
	
	-- Apply percentage if provided
	if options.percentage and type(options.percentage) == "number" then
		result = result * (1 + options.percentage / 100)
	end
	
	return result
end

-- Test the function
local result1 = _G.advanced_calculation(100, 1.5, {bonus = 25, percentage = 10})
print("Advanced calculation result (with options): " .. result1)

local result2 = _G.advanced_calculation(50, 2.0)
print("Advanced calculation result (no options): " .. result2)

print("Lifecycle functions defined: on_init(), on_ready(), on_exit()")
return "Lua execution completed with lifecycle functions!"
"""
	var lua_bridge = get_bridge()
	if lua_bridge:
		lua_bridge.exec_string(lua_code)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_call_function_button_pressed():
	print("DEBUG: Call function button pressed")  # Debug print
	append_output("=== CALL FUNCTION BUTTON PRESSED ===")
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("❌ ERROR: LuaBridge is not available!")
		append_output("  Make sure the LuaBridge extension is loaded properly.")
		return
		
	append_output("Calling Lua function...")
	
	# First check what functions are available
	var available_functions = ["get_lifecycle_state", "get_player_info", "advanced_calculation"]
	var function_to_call = ""
	
	# Try to find an available function
	for func_name in available_functions:
		print("DEBUG: Checking function: " + func_name)  # Debug print
		# Just check if the function exists by trying to get it as a global
		var test_func = lua_bridge.get_global(func_name)
		print("DEBUG: Function " + func_name + " result: " + str(test_func))  # Debug print
		if test_func != null and str(test_func).begins_with("LuaFunction:"):
			function_to_call = func_name
			break
	
	print("DEBUG: Function to call: " + function_to_call)  # Debug print
	
	if function_to_call.is_empty():
		append_output("❌ No available functions found!")
		append_output("  Try loading a script first:")
		append_output("  - Click 'Execute Lua String' to load basic functions")
		append_output("  - Click 'Load Lifecycle Test Script' to load comprehensive functions")
		return
	
	# Call the available function
	append_output("Calling function: " + function_to_call)
	var args = Array()
	var result = lua_bridge.call_function(function_to_call, args)
	var last_error = lua_bridge.get_last_error()
	
	print("DEBUG: Function call result: " + str(result))  # Debug print
	print("DEBUG: Last error: " + last_error)  # Debug print
	
	if last_error.is_empty():
		append_output("✅ Function called successfully!")
		append_output("  Result: " + str(result))
	else:
		append_output("❌ Function call failed: " + last_error)
		append_output("  This might be normal if the function requires arguments")

func _on_set_global_button_pressed():
	print("DEBUG: Set global button pressed")  # Debug print
	append_output("=== SET GLOBAL BUTTON PRESSED ===")
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("❌ ERROR: LuaBridge is not available!")
		append_output("  Make sure the LuaBridge extension is loaded properly.")
		return
		
	append_output("Setting global variables...")
	
	# Set multiple global variables
	lua_bridge.set_global("player_health", 100)
	lua_bridge.set_global("player_level", 5)
	lua_bridge.set_global("player_name", "Hero")
	lua_bridge.set_global("game_time", 123.45)
	lua_bridge.set_global("is_game_running", true)
	
	print("DEBUG: Global variables set")  # Debug print
	append_output("✅ Global variables set successfully!")
	append_output("  - player_health = 100")
	append_output("  - player_level = 5")
	append_output("  - player_name = 'Hero'")
	append_output("  - game_time = 123.45")
	append_output("  - is_game_running = true")

func _on_get_global_button_pressed():
	print("DEBUG: Get global button pressed")  # Debug print
	append_output("=== GET GLOBAL BUTTON PRESSED ===")
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("❌ ERROR: LuaBridge is not available!")
		append_output("  Make sure the LuaBridge extension is loaded properly.")
		return
		
	append_output("Getting global variables...")
	
	# Get the global variables we set
	var health = lua_bridge.get_global("player_health")
	var level = lua_bridge.get_global("player_level")
	var name = lua_bridge.get_global("player_name")
	var game_time = lua_bridge.get_global("game_time")
	var is_running = lua_bridge.get_global("is_game_running")
	
	print("DEBUG: Retrieved values - health: " + str(health) + ", level: " + str(level))  # Debug print
	
	append_output("✅ Retrieved global variables:")
	append_output("  - player_health = " + str(health))
	append_output("  - player_level = " + str(level))
	append_output("  - player_name = " + str(name))
	append_output("  - game_time = " + str(game_time))
	append_output("  - is_game_running = " + str(is_running))
	
	# Also try to get some variables that might exist from scripts
	var lifecycle_state = lua_bridge.get_global("lifecycle_state")
	var player_data = lua_bridge.get_global("player_data")
	
	if lifecycle_state != null:
		append_output("  - lifecycle_state = " + str(lifecycle_state))
	if player_data != null:
		append_output("  - player_data = " + str(player_data))

func _on_execute_code_button_pressed():
	var code = $VBoxContainer/TabContainer/Scripting/CodeInput.text
	if code.is_empty():
		append_output("No code to execute!")
		return
	
	append_output("Executing custom Lua code...")
	var lua_bridge = get_bridge()
	if lua_bridge:
		lua_bridge.exec_string(code)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_test_all_features_button_pressed():
	print("DEBUG: Test all features button pressed")  # Debug print
	append_output("=== TEST ALL FEATURES BUTTON PRESSED ===")
	
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("❌ ERROR: LuaBridge is not available!")
		append_output("  Make sure the LuaBridge extension is loaded properly.")
		return
		
	append_output("Testing all available features...")
	
	# Test 1: Check if lifecycle functions exist
	append_output("1. Testing lifecycle functions...")
	var lifecycle_functions = ["on_init", "on_ready", "on_exit", "get_lifecycle_state", "get_player_info"]
	var available_count = 0
	
	for func_name in lifecycle_functions:
		print("DEBUG: Checking lifecycle function: " + func_name)  # Debug print
		var test_func = lua_bridge.get_global(func_name)
		print("DEBUG: Lifecycle function " + func_name + " result: " + str(test_func))  # Debug print
		if test_func != null and str(test_func).begins_with("LuaFunction:"):
			append_output("  ✅ " + func_name + "() - Available")
			available_count += 1
		else:
			append_output("  ❌ " + func_name + "() - Not available")
	
	append_output("  Lifecycle functions available: " + str(available_count) + "/" + str(lifecycle_functions.size()))
	
	# Test 2: Check global variables
	append_output("2. Testing global variables...")
	var global_vars = ["player_health", "player_level", "player_name", "lifecycle_state", "player_data"]
	var global_count = 0
	
	for var_name in global_vars:
		print("DEBUG: Checking global var: " + var_name)  # Debug print
		var value = lua_bridge.get_global(var_name)
		print("DEBUG: Global var " + var_name + " value: " + str(value))  # Debug print
		if value != null:
			append_output("  ✅ " + var_name + " = " + str(value))
			global_count += 1
		else:
			append_output("  ❌ " + var_name + " = null")
	
	append_output("  Global variables found: " + str(global_count) + "/" + str(global_vars.size()))
	
	# Test 3: Test advanced_calculation if available
	append_output("3. Testing advanced_calculation...")
	var calc_func = lua_bridge.get_global("advanced_calculation")
	print("DEBUG: advanced_calculation function result: " + str(calc_func))  # Debug print
	
	if calc_func != null and str(calc_func).begins_with("LuaFunction:"):
		append_output("  ✅ advanced_calculation() - Available")
		# Try calling it with arguments
		var args = Array()
		args.append(100)  # base
		args.append(1.5)  # multiplier
		args.append({"bonus": 25, "percentage": 10})  # options
		var result = lua_bridge.call_function("advanced_calculation", args)
		var last_error = lua_bridge.get_last_error()
		
		print("DEBUG: advanced_calculation call result: " + str(result))  # Debug print
		print("DEBUG: advanced_calculation last error: " + last_error)  # Debug print
		
		if last_error.is_empty():
			append_output("  ✅ Function call successful: " + str(result))
		else:
			append_output("  ❌ Function call failed: " + last_error)
	else:
		append_output("  ❌ advanced_calculation() - Not available")
	
	# Test 4: Provide guidance
	append_output("4. Recommendations:")
	if available_count == 0:
		append_output("  📝 No lifecycle functions found. Try loading a script:")
		append_output("     - Click 'Execute Lua String' for basic functions")
		append_output("     - Click 'Load Lifecycle Test Script' for full features")
	else:
		append_output("  ✅ Script loaded successfully!")
		append_output("  📝 You can now test individual functions using the buttons above")
	
	append_output("✅ Feature test completed!")
	print("DEBUG: Test all features completed")  # Debug print

# Lifecycle Functions
func _on_call_init_button_pressed():
	append_output("Calling on_init()...")
	var lua_bridge = get_bridge()
	if lua_bridge:
		var has_init = lua_bridge.call_function("on_init", Array())
		var last_error = lua_bridge.get_last_error()
		
		if last_error.is_empty():
			append_output("✅ on_init() called successfully!")
			append_output("  Result: " + str(has_init))
		else:
			append_output("❌ on_init() call failed: " + last_error)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_call_ready_button_pressed():
	append_output("Calling on_ready()...")
	var lua_bridge = get_bridge()
	if lua_bridge:
		var has_ready = lua_bridge.call_function("on_ready", Array())
		var last_error = lua_bridge.get_last_error()
		
		if last_error.is_empty():
			append_output("✅ on_ready() called successfully!")
			append_output("  Result: " + str(has_ready))
		else:
			append_output("❌ on_ready() call failed: " + last_error)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_call_exit_button_pressed():
	append_output("Calling on_exit()...")
	var lua_bridge = get_bridge()
	if lua_bridge:
		var has_exit = lua_bridge.call_function("on_exit", Array())
		var last_error = lua_bridge.get_last_error()
		
		if last_error.is_empty():
			append_output("✅ on_exit() called successfully!")
			append_output("  Result: " + str(has_exit))
		else:
			append_output("❌ on_exit() call failed: " + last_error)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_load_lifecycle_test_button_pressed():
	append_output("Loading lifecycle test script...")
	var lua_code = """
-- Lifecycle test script
print("Loading lifecycle test script...")

-- Initialize global state
_G.lifecycle_state = {
	initialized = false,
	ready = false,
	running = false,
	cleanup = false,
	update_count = 0,
	init_time = 0,
	ready_time = 0,
	exit_time = 0
}

_G.player_data = {
	name = "TestPlayer",
	level = 1,
	health = 100,
	experience = 0
}

-- Helper function to get current time
function get_time()
	return os.time()
end

-- Lifecycle functions
function on_init()
	print("🎯 on_init() called - Initializing mod...")
	_G.mod_initialized = true
	_G.lifecycle_state.initialized = true
	_G.lifecycle_state.init_time = get_time()
	return "Mod initialized successfully!"
end

function on_ready()
	print("🚀 on_ready() called - Mod is ready!")
	_G.lifecycle_state.ready = true
	_G.lifecycle_state.ready_time = get_time()
	_G.lifecycle_state.running = true
	return "Mod is ready to run!"
end

function on_update()
	_G.lifecycle_state.update_count = _G.lifecycle_state.update_count + 1
	if _G.lifecycle_state.update_count % 60 == 0:  -- Every 60 updates
		print("Update #" .. _G.lifecycle_state.update_count)
	end
end

function on_exit()
	print("👋 on_exit() called - Cleaning up mod...")
	_G.lifecycle_state.cleanup = true
	_G.lifecycle_state.exit_time = get_time()
	_G.lifecycle_state.running = false
	return "Mod cleanup completed!"
end

function get_lifecycle_state()
	return _G.lifecycle_state
end

function get_player_info()
	return _G.player_data
end

print("Lifecycle test script loaded successfully!")
"""
	var lua_bridge = get_bridge()
	if lua_bridge:
		lua_bridge.exec_string(lua_code)
		append_output("✅ Lifecycle test script loaded successfully!")
	else:
		append_output("ERROR: Lua bridge not available")

func _on_auto_update_toggled(button_pressed: bool):
	auto_update_enabled = button_pressed
	append_output("Auto-update " + ("enabled" if button_pressed else "disabled"))

# Security Functions
func _on_toggle_sandbox_button_pressed():
	var lua_bridge = get_bridge()
	if lua_bridge:
		var current_sandboxed = lua_bridge.is_sandboxed()
		lua_bridge.set_sandboxed(!current_sandboxed)
		append_output("Sandbox mode: " + str(lua_bridge.is_sandboxed()))
		_update_sandbox_status()
	else:
		append_output("ERROR: Lua bridge not available")

func _on_test_unsafe_code_button_pressed():
	append_output("Testing unsafe code execution...")
	var unsafe_code = """
print("Testing unsafe code...")
os.execute("echo 'This is unsafe!'")
"""
	var lua_bridge = get_bridge()
	if lua_bridge:
		lua_bridge.exec_string(unsafe_code)
	else:
		append_output("ERROR: Lua bridge not available")

func _on_clear_output_button_pressed():
	output_buffer = ""
	$VBoxContainer/TabContainer/Output/OutputTextEdit.text = ""

# Safe Casting Functions
func _on_test_safe_casting_button_pressed():
	append_output("=== Testing Safe Casting ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	# Test instance checking
	var current_scene = get_tree().current_scene
	append_output("Testing instance checking...")
	
	var is_control = lua_bridge.is_instance(current_scene, "Control")
	var is_node = lua_bridge.is_instance(current_scene, "Node")
	append_output("  Current scene is Control: " + str(is_control))
	append_output("  Current scene is Node: " + str(is_node))
	
	# Test class name retrieval
	var gd_class_name = lua_bridge.get_class(current_scene)
	append_output("  Current scene class: " + gd_class_name)
	
	# Test with a VBoxContainer
	var vbox = $VBoxContainer
	append_output("Testing with VBoxContainer...")
	
	is_control = lua_bridge.is_instance(vbox, "Control")
	is_node = lua_bridge.is_instance(vbox, "Node")
	append_output("  VBoxContainer is Control: " + str(is_control))
	append_output("  VBoxContainer is Node: " + str(is_node))
	
	gd_class_name = lua_bridge.get_class(vbox)
	append_output("  VBoxContainer class: " + gd_class_name)

func _on_test_wrappers_button_pressed():
	append_output("=== Testing Object Wrappers ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	# Test wrapper creation
	var current_scene = get_tree().current_scene
	var actual_class = lua_bridge.get_class(current_scene)
	append_output("Creating wrapper for: " + actual_class)
	
	var wrapper = lua_bridge.create_wrapper(current_scene, actual_class)
	if wrapper:
		var is_valid = lua_bridge.is_wrapper_valid(wrapper)
		append_output("  Wrapper created: " + str(is_valid))
		
		# Test method call through wrapper
		var args = Array()
		var child_count = lua_bridge.safe_call_method(wrapper, "get_child_count", args)
		append_output("  Child count: " + str(child_count))
		
		# Test property access through wrapper
		var visible = lua_bridge.get_property(wrapper, "visible")
		append_output("  Visible property: " + str(visible))
		
		# Test property setting through wrapper
		lua_bridge.set_property(wrapper, "visible", true)
		visible = lua_bridge.get_property(wrapper, "visible")
		append_output("  Visible property after setting: " + str(visible))
	else:
		append_output("  Failed to create wrapper")
	
	# Test with VBoxContainer
	append_output("Testing VBoxContainer wrapper...")
	var vbox = $VBoxContainer
	var vbox_actual_class = lua_bridge.get_class(vbox)
	
	var vbox_wrapper = lua_bridge.create_wrapper(vbox, vbox_actual_class)
	if vbox_wrapper:
		var is_valid = lua_bridge.is_wrapper_valid(vbox_wrapper)
		append_output("  VBoxContainer wrapper created: " + str(is_valid))
		
		var args = Array()
		var child_count = lua_bridge.safe_call_method(vbox_wrapper, "get_child_count", args)
		append_output("  VBoxContainer child count: " + str(child_count))
	else:
		append_output("  Failed to create VBoxContainer wrapper")
	
	# Test with LuaBridge itself
	append_output("Testing LuaBridge wrapper...")
	var bridge_actual_class = lua_bridge.get_class(lua_bridge)
	
	var bridge_wrapper = lua_bridge.create_wrapper(lua_bridge, bridge_actual_class)
	if bridge_wrapper:
		var is_valid = lua_bridge.is_wrapper_valid(bridge_wrapper)
		append_output("  LuaBridge wrapper created: " + str(is_valid))
	else:
		append_output("  Failed to create LuaBridge wrapper")

func _on_test_type_checking_button_pressed():
	append_output("=== Testing Type Checking ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	# Test various type checks
	var current_scene = get_tree().current_scene
	append_output("Testing current scene...")
	
	var is_control = lua_bridge.is_instance(current_scene, "Control")
	var is_node = lua_bridge.is_instance(current_scene, "Node")
	var is_object = lua_bridge.is_instance(current_scene, "Object")
	var gd_class_name = lua_bridge.get_class(current_scene)
	
	append_output("  Is Control: " + str(is_control))
	append_output("  Is Node: " + str(is_node))
	append_output("  Is Object: " + str(is_object))
	append_output("  Class: " + gd_class_name)
	
	# Test with VBoxContainer
	var vbox = $VBoxContainer
	append_output("Testing VBoxContainer...")
	
	var is_vbox = lua_bridge.is_instance(vbox, "VBoxContainer")
	is_control = lua_bridge.is_instance(vbox, "Control")
	gd_class_name = lua_bridge.get_class(vbox)
	
	append_output("  Is VBoxContainer: " + str(is_vbox))
	append_output("  Is Control: " + str(is_control))
	append_output("  Class: " + gd_class_name)
	
	# Test with LuaBridge itself
	append_output("Testing LuaBridge...")
	is_control = lua_bridge.is_instance(lua_bridge, "Control")
	is_node = lua_bridge.is_instance(lua_bridge, "Node")
	is_object = lua_bridge.is_instance(lua_bridge, "Object")
	gd_class_name = lua_bridge.get_class(lua_bridge)
	
	append_output("  Is Control: " + str(is_control))
	append_output("  Is Node: " + str(is_node))
	append_output("  Is Object: " + str(is_object))
	append_output("  Class: " + gd_class_name)

# Godot Object Access
func _on_test_get_node_button_pressed():
	append_output("=== Testing Get Node ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	var current_scene = get_tree().current_scene
	append_output("Testing get_node with current scene...")
	
	# Test getting VBoxContainer
	var vbox = lua_bridge.get_node(current_scene, "VBoxContainer")
	if vbox:
		var gd_class_name = lua_bridge.get_class(vbox)
		append_output("  VBoxContainer found: " + gd_class_name)
		
		# Test getting nested node
		var scroll_container = lua_bridge.get_node(current_scene, "VBoxContainer/TabContainer")
		if scroll_container:
			var scroll_class = lua_bridge.get_class(scroll_container)
			append_output("  TabContainer found: " + scroll_class)
		else:
			append_output("  TabContainer not found")
	else:
		append_output("  VBoxContainer not found")

func _on_test_get_children_button_pressed():
	append_output("=== Testing Get Children ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	var current_scene = get_tree().current_scene
	append_output("Testing get_children with current scene...")
	
	var children = lua_bridge.get_children(current_scene)
	append_output("  Children count: " + str(children.size()))
	
	for i in range(children.size()):
		var child = children[i]
		var gd_class_name = lua_bridge.get_class(child)
		append_output("  Child " + str(i) + ": " + gd_class_name)
	
	# Test with VBoxContainer
	var vbox = $VBoxContainer
	append_output("Testing get_children with VBoxContainer...")
	
	var vbox_children = lua_bridge.get_children(vbox)
	append_output("  VBoxContainer children count: " + str(vbox_children.size()))
	
	for i in range(vbox_children.size()):
		var vbox_child = vbox_children[i]
		var vbox_child_class = lua_bridge.get_class(vbox_child)
		append_output("  VBoxContainer child " + str(i) + ": " + vbox_child_class)

func _on_test_property_access_button_pressed():
	append_output("=== Testing Property Access ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	var vbox = $VBoxContainer
	append_output("Testing property access with VBoxContainer...")
	
	# Test getting visible property
	var visible = lua_bridge.get_property(vbox, "visible")
	append_output("  Initial visible property: " + str(visible))
	
	# Test setting visible property
	lua_bridge.set_property(vbox, "visible", true)
	visible = lua_bridge.get_property(vbox, "visible")
	append_output("  Visible property after setting to true: " + str(visible))
	
	# Test with current scene
	var current_scene = get_tree().current_scene
	append_output("Testing property access with current scene...")
	
	var scene_visible = lua_bridge.get_property(current_scene, "visible")
	append_output("  Current scene visible property: " + str(scene_visible))

func _on_test_method_call_button_pressed():
	append_output("=== Testing Method Call ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	var vbox = $VBoxContainer
	append_output("Testing method call with VBoxContainer...")
	
	# Test get_child_count method
	var args = Array()
	var child_count = lua_bridge.safe_call_method(vbox, "get_child_count", args)
	append_output("  Child count method result: " + str(child_count))
	
	# Test is_visible method
	var is_visible = lua_bridge.safe_call_method(vbox, "is_visible", args)
	append_output("  Is visible method result: " + str(is_visible))
	
	# Test with current scene
	var current_scene = get_tree().current_scene
	append_output("Testing method call with current scene...")
	
	var scene_name = lua_bridge.safe_call_method(current_scene, "get_name", args)
	append_output("  Scene name method result: " + str(scene_name))

# Resource & Scene Management
func _on_test_load_resource_button_pressed():
	append_output("=== Testing Load Resource ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing load_resource with icon.png...")
	
	var resource = lua_bridge.load_resource("res://icon.png")
	if resource:
		var gd_class_name = lua_bridge.get_class(resource)
		append_output("  Resource loaded successfully: " + gd_class_name)
	else:
		append_output("  Failed to load resource")

func _on_test_instance_scene_button_pressed():
	append_output("=== Testing Instance Scene ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing instance_scene with main.tscn...")
	
	var scene = lua_bridge.instance_scene("res://main.tscn")
	if scene:
		var gd_class_name = lua_bridge.get_class(scene)
		append_output("  Scene instantiated successfully: " + gd_class_name)
		
		# Test getting children of the instantiated scene
		var children = lua_bridge.get_children(scene)
		append_output("  Instantiated scene has " + str(children.size()) + " children")
	else:
		append_output("  Failed to instantiate scene")

func _on_test_resource_wrapper_button_pressed():
	append_output("=== Testing Resource Wrapper ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing resource wrapper with icon.png...")
	
	var resource = lua_bridge.load_resource("res://icon.png")
	if resource:
		var wrapper = lua_bridge.create_wrapper(resource, "Resource")
		if wrapper:
			var is_valid = lua_bridge.is_wrapper_valid(wrapper)
			append_output("  Resource wrapper created: " + str(is_valid))
			
			# Test getting resource path property
			var resource_path = lua_bridge.get_property(wrapper, "resource_path")
			append_output("  Resource path: " + str(resource_path))
		else:
			append_output("  Failed to create resource wrapper")
	else:
		append_output("  Failed to load resource for wrapper test")

# Events & Signals
func _on_test_emit_event_button_pressed():
	append_output("=== Testing Emit Event ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing event emission...")
	
	# Test emitting a simple event (void method, no return value)
	var event_data = {"type": "test", "message": "Hello from Godot!"}
	lua_bridge.emit_event("test_event", event_data)
	append_output("  Event emission attempted")

func _on_test_subscribe_event_button_pressed():
	append_output("=== Testing Subscribe Event ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing event subscription...")
	
	# Test subscribing to an event (void method, no return value)
	lua_bridge.subscribe_event("test_event", "on_test_event")
	append_output("  Event subscription attempted")

func _on_test_signal_connection_button_pressed():
	append_output("=== Testing Signal Connection ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing signal connection...")
	
	# Test connecting a signal
	var current_scene = get_tree().current_scene
	var success = lua_bridge.connect_signal(current_scene, "ready", "on_scene_ready")
	
	if success:
		append_output("  Signal connection successful")
	else:
		append_output("  Failed to connect signal")

# Coroutines
func _on_test_create_coroutine_button_pressed():
	append_output("=== Testing Create Coroutine ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing coroutine creation...")
	
	# Test creating a coroutine with proper arguments
	var args = Array()
	args.append("test_data")
	var coroutine_id = lua_bridge.create_coroutine("test_coroutine", "test_coroutine", args)
	
	if coroutine_id >= 0:
		append_output("  Coroutine created with ID: " + str(coroutine_id))
	else:
		append_output("  Failed to create coroutine")

func _on_test_resume_coroutine_button_pressed():
	append_output("=== Testing Resume Coroutine ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing coroutine resumption...")
	
	# Test resuming a coroutine with proper arguments
	var coroutine_name = "test_coroutine"
	var resume_data = "resume_data"
	var success = lua_bridge.resume_coroutine(coroutine_name, resume_data)
	
	if success:
		append_output("  Coroutine resumed successfully")
	else:
		append_output("  Failed to resume coroutine")

func _on_test_coroutine_status_button_pressed():
	append_output("=== Testing Coroutine Status ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing coroutine status...")
	
	# Test getting coroutine status
	var coroutine_name = "test_coroutine"
	var is_active = lua_bridge.is_coroutine_active(coroutine_name)
	
	append_output("  Coroutine active: " + str(is_active))

# Autoload Singleton Testing
func _on_test_autoload_button_pressed():
	append_output("=== Testing Autoload Singleton ===")
	var lua_bridge = get_bridge()
	if not lua_bridge:
		append_output("ERROR: Lua bridge not available")
		return
		
	append_output("Testing autoload singleton access...")
	
	# Test getting TestAutoload singleton
	var test_autoload = lua_bridge.get_autoload_singleton("TestAutoload")
	if test_autoload:
		append_output("  TestAutoload singleton found")
		
		# Test calling a method
		var args = Array()
		var player_info = lua_bridge.safe_call_method(test_autoload, "get_player_info", args)
		append_output("  Player info: " + str(player_info))
	else:
		append_output("  TestAutoload singleton not found")
	
	# Test getting a non-existent singleton
	var non_existent = lua_bridge.get_autoload_singleton("NonExistentSingleton")
	if not non_existent:
		append_output("  Non-existent singleton correctly returned null")
	else:
		append_output("  Unexpected result for non-existent singleton")

func _process(delta):
	# Call update hook every frame if auto-update is enabled
	if auto_update_enabled:
		var lua_bridge = get_bridge()
		if lua_bridge:
			lua_bridge.call_on_update(delta) 
