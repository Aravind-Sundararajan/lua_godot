extends Node

var lua_bridge: LuaBridge

func _ready():
    print("Starting Lua Bridge Test...")
    
    # Create the Lua bridge
    lua_bridge = LuaBridge.new()
    
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

func test_basic_operations():
    print("\n=== Testing Basic Operations ===")
    
    # Test exec_string
    lua_bridge.exec_string("print('Hello from Lua!')")
    lua_bridge.exec_string("x = 42; y = 'test'")
    
    # Test get_global
    var x_value = lua_bridge.get_global("x")
    var y_value = lua_bridge.get_global("y")
    print("x = ", x_value, " (type: ", typeof(x_value), ")")
    print("y = ", y_value, " (type: ", typeof(y_value), ")")
    
    # Test set_global
    lua_bridge.set_global("game_time", 123.45)
    lua_bridge.set_global("player_name", "TestPlayer")
    
    # Test reload
    print("Reloading Lua VM...")
    lua_bridge.reload()
    
    # Verify globals are cleared after reload
    var x_after_reload = lua_bridge.get_global("x")
    print("x after reload = ", x_after_reload, " (should be null)")

func test_mod_loading():
    print("\n=== Testing Mod Loading ===")
    
    # Load the example mod
    var success = lua_bridge.load_file("example_mod.lua")
    print("Mod loading success: ", success)
    
    # List loaded mods
    var loaded_mods = lua_bridge.list_loaded_mods()
    print("Loaded mods: ", loaded_mods)

func test_lifecycle_hooks():
    print("\n=== Testing Lifecycle Hooks ===")
    
    # Call lifecycle hooks
    lua_bridge.call_on_init()
    lua_bridge.call_on_ready()
    
    # Simulate a few update calls
    for i in range(3):
        lua_bridge.call_on_update(0.016) # 60 FPS delta
        await get_tree().create_timer(0.1).timeout

func test_function_calling():
    print("\n=== Testing Function Calling ===")
    
    # Call functions with arguments
    var args = Array()
    args.append(100)  # base_damage
    args.append(1.5)  # weapon_multiplier
    args.append(0.2)  # armor_reduction
    
    var result = lua_bridge.call_function("calculate_damage", args)
    print("Damage calculation result: ", result)
    
    # Call function without arguments
    var mod_info = lua_bridge.call_function("get_mod_info", Array())
    print("Mod info: ", mod_info)
    
    # Call function with different arguments
    var pos_args = Array()
    pos_args.append(200)
    pos_args.append(300)
    lua_bridge.call_function("set_player_position", pos_args)
    
    var player_pos = lua_bridge.call_function("get_player_position", Array())
    print("Player position: ", player_pos)

func test_error_handling():
    print("\n=== Testing Error Handling ===")
    
    # Test invalid Lua code
    lua_bridge.exec_string("this is invalid lua code!")
    var last_error = lua_bridge.get_last_error()
    print("Last error: ", last_error)
    
    # Test calling non-existent function
    lua_bridge.call_function("non_existent_function", Array())
    last_error = lua_bridge.get_last_error()
    print("Last error after non-existent function: ", last_error)

func test_sandboxing():
    print("\n=== Testing Sandboxing ===")
    
    print("Sandboxed mode: ", lua_bridge.is_sandboxed())
    
    # Try to use potentially dangerous functions (should be disabled in sandboxed mode)
    lua_bridge.exec_string("print('os.time() = ', os.time())")
    
    # Try to use disabled functions
    lua_bridge.exec_string("print('Trying to use io...')")
    lua_bridge.exec_string("io.write('test')")  # This should fail in sandboxed mode
    
    var last_error = lua_bridge.get_last_error()
    print("Sandbox error: ", last_error)

func test_json_mod_management():
    print("\n=== Testing JSON Mod Management ===")
    
    # Load mods from directory (looks for mod.json files)
    var success = lua_bridge.load_mods_from_directory("example_mod")
    print("JSON mod loading success: ", success)
    
    # Get all mod info
    var all_mod_info = lua_bridge.get_all_mod_info()
    print("All mod info: ", all_mod_info)
    
    # Get specific mod info
    var mod_info = lua_bridge.get_mod_info("ExampleMod")
    print("ExampleMod info: ", mod_info)
    
    # Check if mod is enabled
    var is_enabled = lua_bridge.is_mod_enabled("ExampleMod")
    print("ExampleMod enabled: ", is_enabled)
    
    # Test enabling/disabling mods
    if is_enabled:
        print("Disabling ExampleMod...")
        lua_bridge.disable_mod("ExampleMod")
        print("ExampleMod enabled after disable: ", lua_bridge.is_mod_enabled("ExampleMod"))
        
        print("Re-enabling ExampleMod...")
        lua_bridge.enable_mod("ExampleMod")
        print("ExampleMod enabled after enable: ", lua_bridge.is_mod_enabled("ExampleMod"))
    
    # Test loading a specific mod JSON file
    var json_success = lua_bridge.load_mod_from_json("example_mod/mod.json")
    print("Direct JSON loading success: ", json_success)

func _process(delta):
    # Call update hook every frame
    if lua_bridge:
        lua_bridge.call_on_update(delta)

func _exit_tree():
    # Clean up
    if lua_bridge:
        lua_bridge.call_on_exit()
        lua_bridge.unload() 