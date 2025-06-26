-- Simple test script for accessing Godot autoload singletons from Lua

print("=== Simple Autoload Singleton Test ===")

-- Test 1: Get the TestAutoload singleton
print("Getting TestAutoload singleton...")
local test_autoload = get_autoload_singleton("TestAutoload")

if test_autoload then
    print("✓ Successfully retrieved TestAutoload singleton")
    
    -- Test 2: Call a simple method
    print("\nCalling get_player_info()...")
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
    
    -- Test 3: Set player name
    print("\nSetting player name to 'LuaPlayer'...")
    test_autoload:set_player_name("LuaPlayer")
    
    -- Test 4: Add some score
    print("\nAdding 50 points to score...")
    test_autoload:add_score(50)
    
    -- Test 5: Get updated info
    print("\nGetting updated player info...")
    local updated_info = test_autoload:get_player_info()
    if updated_info then
        print("✓ Updated player info:")
        print("  Name: " .. (updated_info.name or "Unknown"))
        print("  Score: " .. (updated_info.score or 0))
        print("  Game Time: " .. (updated_info.game_time or 0))
        print("  Is Active: " .. (updated_info.is_active and "true" or "false"))
    end
    
    print("\n✓ Simple autoload singleton test completed successfully!")
    
else
    print("✗ Failed to retrieve TestAutoload singleton")
    print("Make sure TestAutoload is configured as an autoload singleton")
end

print("\n=== Test Complete ===") 