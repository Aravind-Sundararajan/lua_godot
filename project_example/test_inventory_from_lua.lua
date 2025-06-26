-- Test script for accessing InventoryManager autoload from Lua
-- This shows how to manipulate an inventory system from Lua scripts

print("=== Testing Inventory Manager from Lua ===")

-- Get the InventoryManager singleton
local inventory = get_autoload_singleton("InventoryManager")
if inventory then
    print("✓ Successfully retrieved InventoryManager singleton")
    
    -- Get initial inventory info
    local info = inventory:get_inventory_info()
    if info then
        print("Initial inventory info:")
        print("  Player: " .. (info.player_name or "Unknown"))
        print("  Gold: " .. (info.gold or 0))
        print("  Items: " .. (info.total_items or 0) .. "/" .. (info.max_items or 0))
        print("  Free space: " .. (info.free_space or 0))
        
        -- Show all items
        if info.items then
            print("  Current items:")
            for item_id, quantity in pairs(info.items) do
                print("    " .. item_id .. ": " .. quantity)
            end
        end
    end
    
    -- Set player name
    inventory:set_player_name("LuaPlayer")
    print("✓ Set player name to: LuaPlayer")
    
    -- Add some items
    inventory:add_item("sword", 1)
    inventory:add_item("shield", 1)
    inventory:add_item("health_potion", 10)
    print("✓ Added items to inventory")
    
    -- Check if we have specific items
    local has_sword = inventory:has_item("sword")
    local sword_count = inventory:get_item_count("sword")
    print("✓ Has sword: " .. tostring(has_sword) .. " (count: " .. sword_count .. ")")
    
    -- Add gold
    inventory:add_gold(500)
    print("✓ Added 500 gold")
    
    -- Buy items
    local bought_sword = inventory:buy_item("sword", 1)
    print("✓ Bought sword: " .. tostring(bought_sword))
    
    local bought_armor = inventory:buy_item("armor", 1)
    print("✓ Bought armor: " .. tostring(bought_armor))
    
    -- Sell items
    local sold_potion = inventory:sell_item("health_potion", 2)
    print("✓ Sold health potions: " .. tostring(sold_potion))
    
    -- Get updated info
    local updated_info = inventory:get_inventory_info()
    if updated_info then
        print("Updated inventory info:")
        print("  Player: " .. (updated_info.player_name or "Unknown"))
        print("  Gold: " .. (updated_info.gold or 0))
        print("  Items: " .. (updated_info.total_items or 0) .. "/" .. (updated_info.max_items or 0))
        print("  Free space: " .. (updated_info.free_space or 0))
        
        -- Show all items
        if updated_info.items then
            print("  Current items:")
            for item_id, quantity in pairs(updated_info.items) do
                print("    " .. item_id .. ": " .. quantity)
            end
        end
    end
    
    -- Test utility methods
    local item_value = inventory:calculate_item_value("sword", 1)
    print("✓ Sword value: " .. item_value .. " gold")
    
    local can_afford = inventory:can_afford_item("shield", 1)
    print("✓ Can afford shield: " .. tostring(can_afford))
    
    local is_full = inventory:is_inventory_full()
    print("✓ Inventory full: " .. tostring(is_full))
    
    local free_space = inventory:get_free_space()
    print("✓ Free space: " .. free_space)
    
    print("✓ All inventory manager tests completed successfully!")
    
else
    print("✗ Failed to retrieve InventoryManager singleton")
    print("To test this:")
    print("1. Add InventoryManager as an autoload singleton in project settings")
    print("2. Set the path to: res://inventory_manager_example.gd")
    print("3. Run this test again")
end

print("\n=== Test Complete ===") 