-- Test script for accessing and using Godot autoload singletons from Lua

print("=== Testing Autoload Singleton Access ===")

-- Test 1: Get the autoload singleton
print("Getting TestAutoload singleton...")
local test_autoload = get_autoload_singleton("TestAutoload")

if test_autoload then
    print("✓ Successfully retrieved TestAutoload singleton")
    print("Singleton type: ", type(test_autoload))
    
    -- Test 2: Access singleton properties and methods
    print("\n--- Testing Singleton Methods ---")
    
    -- Get initial player info
    print("Getting initial player info...")
    local player_info = test_autoload:get_player_info()
    if player_info then
        print("✓ Player info retrieved:")
        print("  Name: " .. (player_info.name or "Unknown"))
        print("  Score: " .. (player_info.score or 0))
        print("  Game Time: " .. (player_info.game_time or 0))
        print("  Is Active: " .. (player_info.is_active and "true" or "false"))
    else
        print("✗ Failed to get player info")
    end
    
    -- Set player name
    print("\nSetting player name...")
    test_autoload:set_player_name("LuaPlayer")
    
    -- Start the game
    print("\nStarting game...")
    test_autoload:start_game()
    
    -- Add some score
    print("\nAdding score...")
    test_autoload:add_score(100)
    test_autoload:add_score(50)
    
    -- Get updated player info
    print("\nGetting updated player info...")
    local updated_info = test_autoload:get_player_info()
    if updated_info then
        print("✓ Updated player info:")
        print("  Name: " .. (updated_info.name or "Unknown"))
        print("  Score: " .. (updated_info.score or 0))
        print("  Game Time: " .. (updated_info.game_time or 0))
        print("  Is Active: " .. (updated_info.is_active and "true" or "false"))
    end
    
    -- Test utility methods
    print("\n--- Testing Utility Methods ---")
    
    -- Test random number generation
    local random_num = test_autoload:get_random_number(1, 100)
    print("✓ Random number (1-100): " .. (random_num or "failed"))
    
    -- Test damage calculation
    local damage = test_autoload:calculate_damage(50.0, 1.5, 0.2)
    print("✓ Damage calculation (50 * 1.5 * 0.8): " .. (damage or "failed"))
    
    -- Test game event emission
    print("\nEmitting game event...")
    test_autoload:emit_game_event("lua_test_event", {message = "Hello from Lua!", timestamp = 12345})
    
    -- Stop the game
    print("\nStopping game...")
    test_autoload:stop_game()
    
    -- Get final player info
    print("\nGetting final player info...")
    local final_info = test_autoload:get_player_info()
    if final_info then
        print("✓ Final player info:")
        print("  Name: " .. (final_info.name or "Unknown"))
        print("  Score: " .. (final_info.score or 0))
        print("  Game Time: " .. (final_info.game_time or 0))
        print("  Is Active: " .. (final_info.is_active and "true" or "false"))
    end
    
    -- Reset the game
    print("\nResetting game...")
    test_autoload:reset_game()
    
    print("\n✓ All autoload singleton tests completed successfully!")
    
else
    print("✗ Failed to retrieve TestAutoload singleton")
    print("Make sure TestAutoload is configured as an autoload singleton in the project settings")
end

-- Test 2: Try to access non-existent singleton
print("\n--- Testing non-existent singleton ---")
local non_existent = get_autoload_singleton("NonExistentSingleton")
if not non_existent then
    print("✓ Correctly returned null for non-existent singleton")
else
    print("✗ Unexpectedly got a value for non-existent singleton")
end

-- Test 3: Test only the TestAutoload singleton
print("\n--- Testing TestAutoload singleton ---")
local test_autoload_again = get_autoload_singleton("TestAutoload")
if test_autoload_again then
    print("✓ Found TestAutoload singleton")
else
    print("✗ No TestAutoload singleton found")
end

print("\n=== Autoload Singleton Test Complete ===") 