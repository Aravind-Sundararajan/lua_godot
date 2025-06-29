extends Node

# Simple test script to verify autoload singleton functionality
# Run this script to test the Lua bridge's ability to access autoload singletons

func _ready():
    #print("=== Autoload Singleton Test ===")
    
    # Use the LuaBridgeManager singleton instead of creating our own instance
    if not LuaBridgeManager.is_bridge_ready():
        LuaBridgeManager.initialize_bridge()
    
    # Test basic autoload singleton access
    test_autoload_access()
    
    # Test singleton method calling
    test_singleton_methods()
    
    # Note: No need to manually unload - the manager handles cleanup

func test_autoload_access():
    #print("\n--- Testing Autoload Singleton Access ---")
    
    # Test getting TestAutoload singleton
    var test_autoload = LuaBridgeManager.get_autoload_singleton("TestAutoload")
    if test_autoload:
        #print("✓ Successfully retrieved TestAutoload singleton")
        #print("Singleton class: ", LuaBridgeManager.get_object_class(test_autoload))
    else:
        #print("✗ Failed to retrieve TestAutoload singleton")
        #print("Make sure TestAutoload is configured as an autoload singleton")
    
    # Test non-existent singleton
    var non_existent = LuaBridgeManager.get_autoload_singleton("NonExistentSingleton")
    if not non_existent:
        #print("✓ Correctly returned null for non-existent singleton")
    else:
        #print("✗ Unexpectedly got a value for non-existent singleton")

func test_singleton_methods():
    #print("\n--- Testing Singleton Method Calls ---")
    
    var test_autoload = LuaBridgeManager.get_autoload_singleton("TestAutoload")
    if not test_autoload:
        #print("Cannot test methods - TestAutoload singleton not available")
        return
    
    # Test get_player_info method
    var player_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", Array())
    #print("Initial player info: ", player_info)
    
    # Test set_player_name method
    var name_args = Array()
    name_args.append("LuaTestPlayer")
    LuaBridgeManager.safe_call_method(test_autoload, "set_player_name", name_args)
    
    # Test add_score method
    var score_args = Array()
    score_args.append(100)
    LuaBridgeManager.safe_call_method(test_autoload, "add_score", score_args)
    
    # Test start_game method
    LuaBridgeManager.safe_call_method(test_autoload, "start_game", Array())
    
    # Get updated player info
    var updated_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", Array())
    #print("Updated player info: ", updated_info)
    
    # Test calculate_damage method
    var damage_args = Array()
    damage_args.append(100.0)  # base damage
    damage_args.append(1.5)    # multiplier
    damage_args.append(0.2)    # armor
    var damage = LuaBridgeManager.safe_call_method(test_autoload, "calculate_damage", damage_args)
    #print("Calculated damage: ", damage)
    
    # Test get_random_number method
    var random_args = Array()
    random_args.append(1)
    random_args.append(100)
    var random_num = LuaBridgeManager.safe_call_method(test_autoload, "get_random_number", random_args)
    #print("Random number: ", random_num)
    
    # Test emit_game_event method
    var event_args = Array()
    event_args.append("test_event")
    event_args.append({"level": 5, "experience": 1000})
    LuaBridgeManager.safe_call_method(test_autoload, "emit_game_event", event_args)
    
    # Test stop_game method
    LuaBridgeManager.safe_call_method(test_autoload, "stop_game", Array())
    
    # Get final player info
    var final_info = LuaBridgeManager.safe_call_method(test_autoload, "get_player_info", Array())
    #print("Final player info: ", final_info)
    
    #print("✓ All singleton method tests completed") 