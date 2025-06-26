-- Minimal autoload singleton test

print("=== Minimal Autoload Test ===")

-- Test 1: Try to get the singleton
print("Getting TestAutoload singleton...")
local test_autoload = get_autoload_singleton("TestAutoload")

if test_autoload then
    print("✓ Successfully retrieved TestAutoload singleton")
    print("Singleton type: " .. type(test_autoload))
    
    -- Test 2: Try to call a simple method
    print("\nCalling get_player_info()...")
    local player_info = test_autoload:get_player_info()
    if player_info then
        print("✓ Player info retrieved:")
        print("  Name: " .. (player_info.name or "Unknown"))
        print("  Score: " .. (player_info.score or 0))
    else
        print("✗ Failed to get player info")
    end
    
    print("\n✓ Minimal autoload test completed!")
else
    print("✗ Failed to retrieve TestAutoload singleton")
    print("The singleton might not be registered or accessible")
end

print("\n=== Test Complete ===") 