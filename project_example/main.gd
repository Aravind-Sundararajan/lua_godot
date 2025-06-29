extends Control

var output_buffer: String = ""

func _ready():
	#print("=== Main Scene Starting ===")
	
	# Fix text field size policies
	$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$VBoxContainer/ScrollContainer/MainContent/ModInfoTextEdit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$VBoxContainer/ScrollContainer/MainContent/ModInfoTextEdit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Test if TestAutoload is accessible
	#print("Testing TestAutoload accessibility...")
	if Engine.has_singleton("TestAutoload"):
		#print("✓ TestAutoload singleton found via Engine.has_singleton")
	else:
		#print("✗ TestAutoload singleton NOT found via Engine.has_singleton")
	
	# Test the engine-registered TestAutoload singleton
	#print("Testing engine-registered TestAutoload singleton...")
	test_engine_autoload()
	
	# Initialize Lua bridge for testing
	#print("Initializing Lua bridge...")
	initialize_lua_bridge()
	
	# Test basic LuaBridge functionality
	test_basic_lua_bridge()
	
	# Load mods automatically (now that JSON parsing is fixed)
	await get_tree().process_frame
	await get_tree().process_frame  # Wait for 2 frames to ensure everything is initialized
	#print("Loading mods automatically...")
	load_mods_automatically()
	
	# Test autoload singleton manipulation directly through Lua
	test_autoload_manipulation_direct()
	
	# Test step-by-step mod loading to verify fix
	test_step_by_step_mod_loading()
	
	# Test autoload access from Lua bridge
	test_autoload_from_lua_bridge()
	
	#print("=== Main Scene Ready ===")

func test_engine_autoload():
	# Test the engine-registered singleton
	#print("Testing engine-registered TestAutoload singleton...")
	
	# Access the singleton through the engine
	var test_autoload = TestAutoload
	#print("✓ Engine-registered TestAutoload singleton found!")
	
	# Test various methods
	var player_info = TestAutoload.get_player_info()
	#print("Initial player info: " + str(player_info))
	
	# Test setting player name
	TestAutoload.set_player_name("EnginePlayer")
	
	# Test adding score
	TestAutoload.add_score(200)
	
	# Test starting the game
	TestAutoload.start_game()
	
	# Get updated info
	var updated_info = TestAutoload.get_player_info()
	#print("Updated player info: " + str(updated_info))
	
	# Test utility methods
	var random_num = TestAutoload.get_random_number(1, 100)
	#print("Random number: " + str(random_num))
	
	var damage = TestAutoload.calculate_damage(75.0, 2.0, 0.3)
	#print("Damage calculation: " + str(damage))
	
	# Stop and reset
	TestAutoload.stop_game()
	TestAutoload.reset_game()
	
	var final_info = TestAutoload.get_player_info()
	#print("Final player info: " + str(final_info))
	
	#print("✓ All engine-registered autoload singleton methods tested successfully!")

func initialize_lua_bridge():
	# Use the LuaBridgeManager singleton instead of creating our own instance
	if LuaBridgeManager.is_bridge_ready():
		#print("✓ Lua Bridge already initialized!")
	else:
		#print("Initializing Lua Bridge through manager...")
		LuaBridgeManager.initialize_bridge()
		#print("✓ Lua Bridge initialized successfully!")

func test_basic_lua_bridge():
	#print("Testing basic LuaBridge functionality...")
	
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ LuaBridge not ready for testing!")
		return
	
	# Test basic Lua execution
	#print("Testing Lua code execution...")
	var result = LuaBridgeManager.execute_lua("#print('Hello from Lua!'); _return_value = 'Test successful'")
	#print("Lua execution result: " + str(result))
	
	# Test setting and getting globals
	#print("Testing global variable access...")
	LuaBridgeManager.set_global("test_var", 42)
	var test_value = LuaBridgeManager.get_global("test_var")
	#print("Global variable test: " + str(test_value))
	
	# Test function calling
	#print("Testing function calling...")
	LuaBridgeManager.execute_lua("function test_func(x) return x * 2 end")
	var func_result = LuaBridgeManager.call_function("test_func", [21])
	#print("Function call result: " + str(func_result))
	
	#print("✓ Basic LuaBridge functionality tested successfully!")

func test_autoload_manipulation_direct():
	#print("Testing autoload singleton manipulation directly through Lua...")
	
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ LuaBridge not ready for autoload manipulation!")
		return
	
	# Get the TestAutoload singleton through the bridge
	var test_autoload = LuaBridgeManager.get_autoload_singleton("TestAutoload")
	if not test_autoload:
		#print("✗ Could not get TestAutoload singleton!")
		return
	
	#print("✓ Got TestAutoload singleton: " + str(test_autoload))
	
	# Test calling methods on the singleton
	var args = Array()
	var player_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", args)
	#print("Initial player info from Lua: " + str(player_info))
	
	# Test setting player name
	var set_name_args = Array()
	set_name_args.append("LuaPlayer")
	LuaBridgeManager.safe_call_method(test_autoload, "set_player_name", set_name_args)
	
	# Test adding score
	var add_score_args = Array()
	add_score_args.append(300)
	LuaBridgeManager.safe_call_method(test_autoload, "add_score", add_score_args)
	
	# Get updated info
	var updated_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", args)
	#print("Updated player info from Lua: " + str(updated_info))
	
	# Test utility methods
	var random_args = Array()
	random_args.append(1)
	random_args.append(100)
	var random_num = LuaBridgeManager.safe_call_method(test_autoload, "get_random_number", random_args)
	#print("Random number from Lua: " + str(random_num))
	
	var damage_args = Array()
	damage_args.append(50.0)
	damage_args.append(2.0)
	damage_args.append(0.1)
	var damage = LuaBridgeManager.safe_call_method(test_autoload, "calculate_damage", damage_args)
	#print("Damage calculation from Lua: " + str(damage))
	
	#print("✓ Autoload manipulation test completed successfully!")

func test_step_by_step_mod_loading():
	"""
	Test step-by-step mod loading to isolate crash
	"""
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ Lua bridge not ready for mod loading!")
		append_output("Lua bridge not ready for mod loading!")
		return
	
	#print("=== Testing Simple Mod Loading ===")
	append_output("=== Testing Simple Mod Loading ===")
	
	# Test 1: Check if simple mod files exist
	#print("Test 1: Checking if simple mod files exist...")
	append_output("Test 1: Checking if simple mod files exist...")
	
	var simple_json_exists = FileAccess.file_exists("res://mods/simple_test_mod.json")
	var simple_lua_exists = FileAccess.file_exists("res://mods/simple_test.lua")
	
	#print("Simple JSON exists: " + str(simple_json_exists))
	#print("Simple Lua exists: " + str(simple_lua_exists))
	append_output("Simple JSON exists: " + str(simple_json_exists))
	append_output("Simple Lua exists: " + str(simple_lua_exists))
	
	if not simple_json_exists:
		#print("✗ Simple mod JSON not found!")
		append_output("Simple mod JSON not found!")
		return
	
	#print("✓ Simple mod JSON found")
	append_output("Simple mod JSON found")
	
	# Test 2: Create a mod JSON without entry script to test JSON parsing only
	#print("Test 2: Testing JSON parsing without entry script...")
	append_output("Test 2: Testing JSON parsing without entry script...")
	
	# Create a temporary JSON file without entry script
	var temp_json = {
		"name": "TestModNoScript",
		"enabled": false
	}
	
	var temp_file = FileAccess.open("res://mods/temp_test.json", FileAccess.WRITE)
	if temp_file:
		temp_file.store_string(JSON.stringify(temp_json))
		temp_file.close()
		#print("✓ Created temporary test JSON")
		append_output("Created temporary test JSON")
		
		# Try to load the temporary JSON
		var temp_result = LuaBridgeManager.load_mod_from_json("res://mods/temp_test.json")
		#print("Temporary JSON loading result: " + str(temp_result))
		append_output("Temporary JSON loading result: " + str(temp_result))
		
		# Clean up
		DirAccess.remove_absolute("res://mods/temp_test.json")
	else:
		#print("✗ Could not create temporary test JSON")
		append_output("Could not create temporary test JSON")
	
	# Test 3: Try to load just the simple mod JSON (this will crash if file loading is the issue)
	if simple_lua_exists:
		#print("Test 3: Loading simple mod JSON with entry script...")
		append_output("Test 3: Loading simple mod JSON with entry script...")
		
		var simple_result = LuaBridgeManager.load_mod_from_json("res://mods/simple_test_mod.json")
		#print("Simple mod JSON loading result: " + str(simple_result))
		append_output("Simple mod JSON loading result: " + str(simple_result))
		
		if simple_result:
			#print("✓ Simple mod loaded successfully!")
			append_output("Simple mod loaded successfully!")
			
			# Show what mods are available
			var all_mod_info = LuaBridgeManager.get_all_mod_info()
			#print("Available mods: " + str(all_mod_info))
			append_output("Available mods: " + str(all_mod_info))
		else:
			#print("✗ Simple mod loading failed!")
			append_output("Simple mod loading failed!")
	
	#print("=== Simple Mod Loading Test Complete ===")
	append_output("=== Simple Mod Loading Test Complete ===")

func test_autoload_from_lua_bridge():
	#print("Testing autoload singleton access from Lua bridge...")

	var test_autoload = LuaBridgeManager.get_autoload_singleton("TestAutoload")
	#print("test_autoload type: ", typeof(test_autoload), " is_wrapper: ", LuaBridgeManager.is_wrapper(test_autoload))
	if test_autoload and not LuaBridgeManager.is_wrapper(test_autoload):
		test_autoload = LuaBridgeManager.create_wrapper(test_autoload, "Node") # or use the actual class name if known

	if test_autoload and LuaBridgeManager.is_wrapper(test_autoload):
		#print("✓ TestAutoload singleton accessible from Lua bridge!")

		var args = Array()
		var player_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", args)
		#print("Player info from Lua bridge: " + str(player_info))

		var set_name_args = Array()
		set_name_args.append("LuaPlayer")
		LuaBridgeManager.safe_call_method(test_autoload, "set_player_name", set_name_args)

		var add_score_args = Array()
		add_score_args.append(300)
		LuaBridgeManager.safe_call_method(test_autoload, "add_score", add_score_args)

		var updated_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", args)
		#print("Updated player info from Lua bridge: " + str(updated_info))

		#print("✓ All Lua bridge autoload singleton methods tested successfully!")
	else:
		#print("✗ TestAutoload singleton not accessible from Lua bridge")

func load_mods_automatically():
	"""
	Automatically load mods from the mods directory on startup.
	"""
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ Lua bridge not ready for mod loading!")
		append_output("Lua bridge not ready for mod loading!")
		return
	
	#print("Loading mods from res://mods...")
	append_output("Loading mods from res://mods...")
	
	# Check if the mods directory exists
	var dir = DirAccess.open("res://mods")
	if not dir:
		#print("✗ Mods directory not found!")
		append_output("Mods directory not found!")
		return
	
	#print("✓ Mods directory found")
	append_output("Mods directory found")
	
	# List contents of mods directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var file_count = 0
	while file_name != "":
		if file_name != "." and file_name != "..":
			#print("Found: " + file_name + " (dir: " + str(dir.current_is_dir()) + ")")
			append_output("Found: " + file_name + " (dir: " + str(dir.current_is_dir()) + ")")
			file_count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	
	#print("Total files/dirs in mods: " + str(file_count))
	append_output("Total files/dirs in mods: " + str(file_count))
	
	# Try to load mods
	#print("Attempting to load mods...")
	append_output("Attempting to load mods...")
	var result = LuaBridgeManager.load_mods_from_directory("res://mods")
	
	if result:
		#print("✓ Mods loaded successfully!")
		append_output("Mods loaded successfully!")
		# Show what mods were loaded
		var all_mod_info = LuaBridgeManager.get_all_mod_info()
		#print("Loaded mods: " + str(all_mod_info))
		append_output("Loaded mods: " + str(all_mod_info))
	else:
		#print("✗ Failed to load mods!")
		append_output("Failed to load mods!")

# Mod Management Button Handlers
func _on_LoadModsButton_pressed():
	append_output("Loading mods from directory...")
	if LuaBridgeManager.is_bridge_ready():
		var result = LuaBridgeManager.load_mods_from_directory("res://mods")
		append_output("Load mods result: " + str(result))
		
		if result:
			append_output("✓ Mods loaded successfully!")
			# Show what mods were loaded
			var all_mod_info = LuaBridgeManager.get_all_mod_info()
			append_output("Loaded mods: " + str(all_mod_info))
		else:
			append_output("✗ Failed to load mods!")
	else:
		append_output("Lua bridge is not ready!")

func _on_LoadSpecificModButton_pressed():
	append_output("Loading specific mod JSON...")
	if LuaBridgeManager.is_bridge_ready():
		var result = LuaBridgeManager.load_mod_from_json("res://mods/example_mod/mod.json")
		append_output("Load specific mod result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

func _on_EnableModButton_pressed():
	append_output("Enabling ExampleMod...")
	if not LuaBridgeManager.is_bridge_ready():
		append_output("Lua bridge is not ready!")
		return
	
	# Check if mods are loaded
	var all_mod_info = LuaBridgeManager.get_all_mod_info()
	if all_mod_info.size() == 0:
		append_output("No mods are loaded! Please load mods first using 'Load Mods from Directory' button.")
		return
	
	append_output("Available mods: " + str(all_mod_info))
	
	# Try to enable ExampleMod
	LuaBridgeManager.enable_mod("ExampleMod")
	append_output("ExampleMod enable attempt completed!")

func _on_DisableModButton_pressed():
	append_output("Disabling ExampleMod...")
	if not LuaBridgeManager.is_bridge_ready():
		append_output("Lua bridge is not ready!")
		return
	
	# Check if mods are loaded
	var all_mod_info = LuaBridgeManager.get_all_mod_info()
	if all_mod_info.size() == 0:
		append_output("No mods are loaded! Please load mods first using 'Load Mods from Directory' button.")
		return
	
	LuaBridgeManager.disable_mod("ExampleMod")
	append_output("ExampleMod disable attempt completed!")

func _on_ReloadModButton_pressed():
	append_output("Reloading ExampleMod...")
	if not LuaBridgeManager.is_bridge_ready():
		append_output("Lua bridge is not ready!")
		return
	
	# Check if mods are loaded
	var all_mod_info = LuaBridgeManager.get_all_mod_info()
	if all_mod_info.size() == 0:
		append_output("No mods are loaded! Please load mods first using 'Load Mods from Directory' button.")
		return
	
	append_output("Available mods: " + str(all_mod_info))
	
	var result = LuaBridgeManager.reload_mod("ExampleMod")
	append_output("ExampleMod reload attempt completed! Result: " + str(result))

# Lua Scripting Button Handlers
func _on_ExecuteStringButton_pressed():
	append_output("Executing Lua string...")
	append_output("Bridge ready: " + str(LuaBridgeManager.is_bridge_ready()))
	append_output("Bridge initialized: " + str(LuaBridgeManager.get_is_initialized()))
	append_output("Initialization error: " + str(LuaBridgeManager.get_initialization_error()))
	
	if LuaBridgeManager.is_bridge_ready():
		var bridge = LuaBridgeManager.get_bridge()
		append_output("Bridge object: " + str(bridge))
		append_output("Bridge has exec_string method: " + str(bridge.has_method("exec_string")))
		
		var result = LuaBridgeManager.execute_lua("#print('Hello from Lua!'); _return_value = 'Lua executed successfully'")
		append_output("Lua execution result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")
		# Try to initialize it
		append_output("Attempting to initialize bridge...")
		var init_result = LuaBridgeManager.initialize_bridge()
		append_output("Initialization result: " + str(init_result))
		if init_result:
			var result = LuaBridgeManager.execute_lua("#print('Hello from Lua!'); _return_value = 'Lua executed successfully'")
			append_output("Lua execution result after init: " + str(result))

func _on_CallFunctionButton_pressed():
	append_output("Calling Lua function...")
	if LuaBridgeManager.is_bridge_ready():
		# First define a function
		LuaBridgeManager.execute_lua("function test_function(x) return x * 2 end")
		# Then call it
		var result = LuaBridgeManager.call_function("test_function", [5])
		append_output("Function call result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

func _on_SetGlobalButton_pressed():
	append_output("Setting global variable...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.set_global("test_global", "Hello from GDScript!")
		append_output("Global variable set!")
	else:
		append_output("Lua bridge is not ready!")

func _on_GetGlobalButton_pressed():
	append_output("Getting global variable...")
	if LuaBridgeManager.is_bridge_ready():
		var result = LuaBridgeManager.get_global("test_global")
		append_output("Global variable value: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestAllFeaturesButton_pressed():
	append_output("Testing all new features...")
	test_autoload_from_lua_bridge()
	append_output("All features test completed!")

# Lifecycle Hooks Button Handlers
func _on_CallInitButton_pressed():
	append_output("Calling on_init()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.call_lua_function("on_init", [])
		append_output("on_init() called!")
	else:
		append_output("Lua bridge is not ready!")

func _on_CallReadyButton_pressed():
	append_output("Calling on_ready()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.call_lua_function("on_ready", [])
		append_output("on_ready() called!")
	else:
		append_output("Lua bridge is not ready!")

func _on_CallExitButton_pressed():
	append_output("Calling on_exit()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.call_lua_function("on_exit", [])
		append_output("on_exit() called!")
	else:
		append_output("Lua bridge is not ready!")

# Security & Sandboxing Button Handlers
func _on_ToggleSandboxButton_pressed():
	append_output("Toggling sandbox mode...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.set_sandboxed(!LuaBridgeManager.is_sandboxed())
		append_output("Sandbox mode toggled!")
	else:
		append_output("Lua bridge is not ready!")

func _on_TestUnsafeCodeButton_pressed():
	append_output("Testing unsafe code...")
	if LuaBridgeManager.is_bridge_ready():
		var result = LuaBridgeManager.execute_lua("os.execute('echo unsafe')")
		append_output("Unsafe code test result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

# Safe Casting & Wrappers Button Handlers
func _on_TestSafeCastingButton_pressed():
	append_output("Testing safe casting...")
	if LuaBridgeManager.is_bridge_ready():
		var test_node = Node.new()
		var wrapper = LuaBridgeManager.create_wrapper(test_node, "Node")
		append_output("Wrapper created: " + str(wrapper))
		test_node.queue_free()
	else:
		append_output("Lua bridge is not ready!")

func _on_TestWrappersButton_pressed():
	append_output("Testing object wrappers...")
	if LuaBridgeManager.is_bridge_ready():
		var test_node = Node.new()
		var wrapper = LuaBridgeManager.create_wrapper(test_node, "Node")
		var is_wrapper = LuaBridgeManager.is_wrapper(wrapper)
		append_output("Is wrapper: " + str(is_wrapper))
		test_node.queue_free()
	else:
		append_output("Lua bridge is not ready!")

func _on_TestTypeCheckingButton_pressed():
	append_output("Testing type checking...")
	if LuaBridgeManager.is_bridge_ready():
		var test_node = Node.new()
		var is_instance = LuaBridgeManager.is_instance(test_node, "Node")
		append_output("Is Node instance: " + str(is_instance))
		test_node.queue_free()
	else:
		append_output("Lua bridge is not ready!")

# Godot Object Access Button Handlers
func _on_TestGetNodeButton_pressed():
	append_output("Testing get_node()...")
	if LuaBridgeManager.is_bridge_ready():
		var wrapper = LuaBridgeManager.create_wrapper(self, "Control")
		var node_result = LuaBridgeManager.get_node_wrapper(wrapper, "VBoxContainer")
		append_output("get_node result: " + str(node_result))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestGetChildrenButton_pressed():
	append_output("Testing get_children()...")
	if LuaBridgeManager.is_bridge_ready():
		var wrapper = LuaBridgeManager.create_wrapper(self, "Control")
		var children = LuaBridgeManager.get_children_wrapper(wrapper)
		append_output("Children count: " + str(children.size()))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestPropertyAccessButton_pressed():
	append_output("Testing property access...")
	if LuaBridgeManager.is_bridge_ready():
		var wrapper = LuaBridgeManager.create_wrapper(self, "Control")
		var position = LuaBridgeManager.get_property(wrapper, "position")
		append_output("Position property: " + str(position))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestMethodCallButton_pressed():
	append_output("Testing method calls...")
	if LuaBridgeManager.is_bridge_ready():
		var wrapper = LuaBridgeManager.create_wrapper(self, "Control")
		var args = Array()
		var result = LuaBridgeManager.safe_call_method(wrapper, "get_child_count", args)
		append_output("Child count method result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

# Resource & Scene Management Button Handlers
func _on_TestLoadResourceButton_pressed():
	append_output("Testing load_resource()...")
	if LuaBridgeManager.is_bridge_ready():
		var resource = LuaBridgeManager.load_resource("res://icon.png")
		append_output("Resource loaded: " + str(resource != null))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestInstanceSceneButton_pressed():
	append_output("Testing instance_scene()...")
	if LuaBridgeManager.is_bridge_ready():
		var scene = LuaBridgeManager.instance_scene("res://main.tscn")
		append_output("Scene instantiated: " + str(scene != null))
		if scene:
			scene.queue_free()
	else:
		append_output("Lua bridge is not ready!")

func _on_TestResourceWrapperButton_pressed():
	append_output("Testing resource wrappers...")
	if LuaBridgeManager.is_bridge_ready():
		var resource = Resource.new()
		var wrapper = LuaBridgeManager.create_wrapper(resource, "Resource")
		append_output("Resource wrapper created: " + str(wrapper != null))
	else:
		append_output("Lua bridge is not ready!")

# Events & Signals Button Handlers
func _on_TestEmitEventButton_pressed():
	append_output("Testing emit_event()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.emit_event("test_event", "Hello from event!")
		append_output("Event emitted!")
	else:
		append_output("Lua bridge is not ready!")

func _on_TestSubscribeEventButton_pressed():
	append_output("Testing subscribe_event()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.subscribe_event("test_event", "on_test_event")
		append_output("Event subscription added!")
	else:
		append_output("Lua bridge is not ready!")

func _on_TestSignalConnectionButton_pressed():
	append_output("Testing signal connection...")
	if LuaBridgeManager.is_bridge_ready():
		var wrapper = LuaBridgeManager.create_wrapper(self, "Control")
		var result = LuaBridgeManager.connect_signal(wrapper, "ready", "on_ready_signal")
		append_output("Signal connection result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

# Coroutines Button Handlers
func _on_TestCreateCoroutineButton_pressed():
	append_output("Testing create_coroutine()...")
	if LuaBridgeManager.is_bridge_ready():
		LuaBridgeManager.execute_lua("function test_coro() coroutine.yield('step1'); return 'step2' end")
		var result = LuaBridgeManager.create_coroutine("test_coro", "test_coro", [])
		append_output("Coroutine creation result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestResumeCoroutineButton_pressed():
	append_output("Testing resume_coroutine()...")
	if LuaBridgeManager.is_bridge_ready():
		var result = LuaBridgeManager.resume_coroutine("test_coro", "resume_data")
		append_output("Coroutine resume result: " + str(result))
	else:
		append_output("Lua bridge is not ready!")

func _on_TestCoroutineStatusButton_pressed():
	append_output("Testing coroutine status...")
	if LuaBridgeManager.is_bridge_ready():
		var is_active = LuaBridgeManager.is_coroutine_active("test_coro")
		append_output("Coroutine active: " + str(is_active))
	else:
		append_output("Lua bridge is not ready!")

func append_output(text: String):
	output_buffer += text + "\n"
	if has_node("VBoxContainer/ScrollContainer/MainContent/OutputTextEdit"):
		$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.text = output_buffer
		$VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.scroll_vertical = $VBoxContainer/ScrollContainer/MainContent/OutputTextEdit.get_line_count() 
