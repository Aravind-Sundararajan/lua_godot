-- Test script for accessing autoload singletons from Lua
-- This demonstrates how to manipulate autoload singletons like an inventory manager

print("=== Testing Autoload Singleton Access from Lua ===")

-- Get the TestAutoload singleton (this would be your inventory manager)
local test_autoload = get_autoload_singleton("TestAutoload")
if test_autoload then
    print("✓ Successfully retrieved TestAutoload singleton")
    
    -- Get initial player info
    local player_info = test_autoload:get_player_info()
    if player_info then
        print("Initial player info:")
        print("  Name: " .. (player_info.name or "Unknown"))
        print("  Score: " .. (player_info.score or 0))
        print("  Game time: " .. (player_info.game_time or 0))
        print("  Is active: " .. tostring(player_info.is_active or false))
    end
    
    -- Set player name (like setting inventory owner)
    test_autoload:set_player_name("LuaInventoryPlayer")
    print("✓ Set player name to: LuaInventoryPlayer")
    
    -- Add score (like adding items to inventory)
    test_autoload:add_score(150)
    print("✓ Added 150 points to score")
    
    -- Start game (like initializing inventory)
    test_autoload:start_game()
    print("✓ Started game (inventory initialized)")
    
    -- Get updated player info
    local updated_info = test_autoload:get_player_info()
    if updated_info then
        print("Updated player info:")
        print("  Name: " .. (updated_info.name or "Unknown"))
        print("  Score: " .. (updated_info.score or 0))
        print("  Is active: " .. tostring(updated_info.is_active or false))
    end
    
    -- Test utility methods (like inventory calculations)
    local random_num = test_autoload:get_random_number(1, 100)
    print("✓ Random number (1-100): " .. random_num)
    
    local damage = test_autoload:calculate_damage(100.0, 1.5, 0.2)
    print("✓ Damage calculation (100 * 1.5 * 0.8): " .. damage)
    
    -- Test event emission (like inventory events)
    local event_data = {
        item_id = "sword_001",
        quantity = 5,
        rarity = "rare"
    }
    test_autoload:emit_game_event("item_added", event_data)
    print("✓ Emitted game event: item_added")
    
    -- Stop game (like closing inventory)
    test_autoload:stop_game()
    print("✓ Stopped game (inventory closed)")
    
    -- Get final info
    local final_info = test_autoload:get_player_info()
    if final_info then
        print("Final player info:")
        print("  Name: " .. (final_info.name or "Unknown"))
        print("  Score: " .. (final_info.score or 0))
        print("  Is active: " .. tostring(final_info.is_active or false))
    end
    
    print("✓ All autoload singleton tests completed successfully!")
    
else
    print("✗ Failed to retrieve TestAutoload singleton")
    print("Make sure TestAutoload is configured as an autoload singleton in project settings")
end

-- Example of how you would use this with an inventory manager
print("\n=== Example: Inventory Manager Usage ===")

-- This is how you would access an inventory manager autoload
local inventory_manager = get_autoload_singleton("InventoryManager")
if inventory_manager then
    print("✓ Inventory manager found!")
    
    -- Example inventory operations (these methods would need to exist on your InventoryManager)
    -- local items = inventory_manager:get_all_items()
    -- inventory_manager:add_item("sword", 1)
    -- inventory_manager:remove_item("sword", 1)
    -- local has_item = inventory_manager:has_item("sword")
    -- local item_count = inventory_manager:get_item_count("sword")
    
    print("Inventory manager is ready for use!")
else
    print("✗ Inventory manager not found")
    print("To use this, create an InventoryManager autoload singleton")
end

print("\n=== Test Complete ===") 