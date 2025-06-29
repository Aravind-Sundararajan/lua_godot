extends Node

func _ready():
    #print("Starting Lua Bridge Test...")
    
    # Use LuaBridgeManager instead of direct instantiation
    if not LuaBridgeManager.is_bridge_ready():
        #print("Initializing LuaBridge through manager...")
        LuaBridgeManager.initialize_bridge()
    
    if not LuaBridgeManager.is_bridge_ready():
        #print("✗ Failed to initialize LuaBridge!")
        return
    
    #print("✓ LuaBridge initialized through manager")
    
    # Test basic functionality
    test_basic_operations()
    
    # Test mod loading
    test_mod_loading()
    
    # Test lifecycle hooks
    test_lifecycle_hooks()
    
    # Test function calling with arguments
    test_function_calling()
    
    # Test error handling
    test_error_handling()
    
    # Test sandboxing
    test_sandboxing()
    
    # Test JSON mod management
    test_json_mod_management()
    
    # Test function registration
    test_function_registration()
    
    # Test autoload singleton access
    test_autoload_singleton()

func test_basic_operations():
    #print("\n=== Testing Basic Operations ===")
    
    # Test exec_string
    LuaBridgeManager.execute_lua("#print('Hello from Lua!')")
    LuaBridgeManager.execute_lua("x = 42; y = 'test'")
    
    # Test get_global
    var x_value = LuaBridgeManager.get_global("x")
    var y_value = LuaBridgeManager.get_global("y")
    #print("x = ", x_value, " (type: ", typeof(x_value), ")")
    #print("y = ", y_value, " (type: ", typeof(y_value), ")")
    
    # Test set_global
    LuaBridgeManager.set_global("game_time", 123.45)
    LuaBridgeManager.set_global("player_name", "TestPlayer")
    
    # Test reload (through manager)
    #print("Reloading Lua VM...")
    var bridge = LuaBridgeManager.get_bridge()
    if bridge and bridge.has_method("reload"):
        bridge.reload()
    
    # Verify globals are cleared after reload
    var x_after_reload = LuaBridgeManager.get_global("x")
    #print("x after reload = ", x_after_reload, " (should be null)")

func test_mod_loading():
    #print("\n=== Testing Mod Loading ===")
    
    # Load the example mod
    var bridge = LuaBridgeManager.get_bridge()
    if bridge and bridge.has_method("load_file"):
        var success = bridge.load_file("example_mod.lua")
        #print("Mod loading success: ", success)
        
        # List loaded mods
        var loaded_mods = bridge.list_loaded_mods()
        #print("Loaded mods: ", loaded_mods)
    else:
        #print("✗ Bridge doesn't have load_file method")

func test_lifecycle_hooks():
    #print("\n=== Testing Lifecycle Hooks ===")
    
    # Call lifecycle hooks
    LuaBridgeManager.call_lua_function("on_init", [])
    LuaBridgeManager.call_lua_function("on_ready", [])
    
    # Simulate a few update calls
    for i in range(3):
        LuaBridgeManager.call_lua_function("on_update", [0.016]) # 60 FPS delta
        await get_tree().create_timer(0.1).timeout

func test_function_calling():
    #print("\n=== Testing Function Calling ===")
    
    # Call functions with arguments
    var args = Array()
    args.append(100)  # base_damage
    args.append(1.5)  # weapon_multiplier
    args.append(0.2)  # armor_reduction
    
    var result = LuaBridgeManager.call_function("calculate_damage", args)
    #print("Damage calculation result: ", result)
    
    # Call function without arguments
    var mod_info = LuaBridgeManager.call_function("get_mod_info", Array())
    #print("Mod info: ", mod_info)
    
    # Call function with different arguments
    var pos_args = Array()
    pos_args.append(200)
    pos_args.append(300)
    LuaBridgeManager.call_function("set_player_position", pos_args)
    
    var player_pos = LuaBridgeManager.call_function("get_player_position", Array())
    #print("Player position: ", player_pos)

func test_error_handling():
    #print("\n=== Testing Error Handling ===")
    
    # Test invalid Lua code
    LuaBridgeManager.execute_lua("this is invalid lua code!")
    # Note: get_last_error might not be available through manager
    
    # Test calling non-existent function
    LuaBridgeManager.call_function("non_existent_function", Array())
    #print("Error handling test completed")

func test_sandboxing():
    #print("\n=== Testing Sandboxing ===")
    
    #print("Sandboxed mode: ", LuaBridgeManager.is_sandboxed())
    
    # Try to use potentially dangerous functions (should be disabled in sandboxed mode)
    LuaBridgeManager.execute_lua("#print('os.time() = ', os.time())")
    
    # Try to use disabled functions
    LuaBridgeManager.execute_lua("#print('Trying to use io...')")
    LuaBridgeManager.execute_lua("io.write('test')")  # This should fail in sandboxed mode
    
    #print("Sandboxing test completed")

func test_json_mod_management():
    #print("\n=== Testing JSON Mod Management ===")
    
    # Load mods from directory (looks for mod.json files)
    var success = LuaBridgeManager.load_mods_from_directory("example_mod")
    #print("JSON mod loading success: ", success)
    
    # Get all mod info
    var all_mod_info = LuaBridgeManager.get_all_mod_info()
    #print("All mod info: ", all_mod_info)
    
    # Get specific mod info
    var mod_info = LuaBridgeManager.get_mod_info("ExampleMod")
    #print("ExampleMod info: ", mod_info)
    
    # Check if mod is enabled
    var is_enabled = LuaBridgeManager.is_mod_enabled("ExampleMod")
    #print("ExampleMod enabled: ", is_enabled)
    
    # Test enabling/disabling mods
    if is_enabled:
        #print("Disabling ExampleMod...")
        LuaBridgeManager.disable_mod("ExampleMod")
        #print("ExampleMod enabled after disable: ", LuaBridgeManager.is_mod_enabled("ExampleMod"))
        
        #print("Re-enabling ExampleMod...")
        LuaBridgeManager.enable_mod("ExampleMod")
        #print("ExampleMod enabled after enable: ", LuaBridgeManager.is_mod_enabled("ExampleMod"))
    
    # Test loading a specific mod JSON file
    var json_success = LuaBridgeManager.load_mod_from_json("example_mod/mod.json")
    #print("Direct JSON loading success: ", json_success)

func test_function_registration():
    #print("\n=== Testing Function Registration ===")
    
    var bridge = LuaBridgeManager.get_bridge()
    if not bridge:
        #print("✗ No bridge available for function registration")
        return
    
    # Register a simple function that returns a string
    if bridge.has_method("register_function"):
        bridge.register_function("godot_hello", func(args):
            #print("Godot function called with arguments: ", args)
            return "Hello from Godot!"
        )
        
        # Register a function that adds numbers
        bridge.register_function("godot_add", func(args):
            if args.size() >= 2:
                var a = args[0]
                var b = args[1]
                if typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT:
                    if typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT:
                        return a + b
            return 0
        )
        
        # Call the registered functions from Lua
        LuaBridgeManager.execute_lua("#print('Calling godot_hello(): ', godot_hello())")
        LuaBridgeManager.execute_lua("#print('Calling godot_add(5, 3): ', godot_add(5, 3))")
        LuaBridgeManager.execute_lua("#print('Calling godot_add(10.5, 2.5): ', godot_add(10.5, 2.5))")
        
        # Test calling with arguments
        LuaBridgeManager.execute_lua("result = godot_add(100, 200)")
        var result = LuaBridgeManager.get_global("result")
        #print("Result from Lua: ", result)
        
        # Test error handling for non-existent function
        LuaBridgeManager.execute_lua("#print('Trying to call non-existent function...')")
        LuaBridgeManager.execute_lua("non_existent()")  # This should cause an error
        #print("Error handling test completed")
    else:
        #print("✗ Bridge doesn't have register_function method")

func test_autoload_singleton():
    #print("\n=== Testing Autoload Singleton Access ===")
    
    # Load the autoload singleton test script
    var bridge = LuaBridgeManager.get_bridge()
    if bridge and bridge.has_method("load_file"):
        var success = bridge.load_file("test_autoload_singleton.lua")
        #print("Autoload singleton test script loaded: ", success)
        
        if not success:
            #print("Error loading autoload test script")
            return
    else:
        #print("✗ Bridge doesn't have load_file method")
        return
    
    # Test getting a specific autoload singleton
    var test_autoload = LuaBridgeManager.get_autoload_singleton("TestAutoload")
    if test_autoload:
        #print("✓ Successfully retrieved TestAutoload singleton")
        
        # Test calling methods on the singleton
        var args = Array()
        var player_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", args)
        #print("Player info from singleton: ", player_info)
        
        # Test setting player name
        var name_args = Array()
        name_args.append("LuaTestPlayer")
        LuaBridgeManager.safe_call_method(test_autoload, "set_player_name", name_args)
        
        # Test adding score
        var score_args = Array()
        score_args.append(100)
        LuaBridgeManager.safe_call_method(test_autoload, "add_score", score_args)
        
        # Test starting game
        LuaBridgeManager.safe_call_method(test_autoload, "start_game", Array())
        
        # Get updated player info
        var updated_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", Array())
        #print("Updated player info: ", updated_info)
        
        # Test damage calculation
        var damage_args = Array()
        damage_args.append(100.0)  # base damage
        damage_args.append(1.5)    # multiplier
        damage_args.append(0.2)    # armor
        var damage = LuaBridgeManager.safe_call_method(test_autoload, "calculate_damage", damage_args)
        #print("Calculated damage: ", damage)
        
        # Test random number generation
        var random_args = Array()
        random_args.append(1)
        random_args.append(100)
        var random_num = LuaBridgeManager.safe_call_method(test_autoload, "get_random_number", random_args)
        #print("Random number: ", random_num)
        
        # Test game event emission
        var event_args = Array()
        event_args.append("test_event")
        event_args.append({"level": 5, "experience": 1000})
        LuaBridgeManager.safe_call_method(test_autoload, "emit_game_event", event_args)
        
        # Stop game
        LuaBridgeManager.safe_call_method(test_autoload, "stop_game", Array())
        
        # Get final info
        var final_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", Array())
        #print("Final player info: ", final_info)
        
    else:
        #print("✗ Failed to retrieve TestAutoload singleton")
        #print("Make sure TestAutoload is configured as an autoload singleton in project settings")
    
    # Test non-existent singleton
    var non_existent = LuaBridgeManager.get_autoload_singleton("NonExistentSingleton")
    if not non_existent:
        #print("✓ Correctly returned null for non-existent singleton")
    else:
        #print("✗ Unexpectedly got a value for non-existent singleton")
    
    # Test various singleton names
    var test_names = ["GameManager", "AudioManager", "InputManager", "SaveManager"]
    for name in test_names:
        var singleton = LuaBridgeManager.get_autoload_singleton(name)
        if singleton:
            #print("✓ Found singleton: ", name)
        else:
            #print("✗ No singleton found: ", name)

func _process(delta):
    # Call update hook every frame
    LuaBridgeManager.call_lua_function("on_update", [delta])

func _exit_tree():
    # Clean up
    LuaBridgeManager.call_lua_function("on_exit", [])
    LuaBridgeManager.unload_bridge() 