-- Example Mod Main Script
-- This is loaded by the JSON mod management system

local mod_name = "ExampleMod"
local player_position = {x = 0, y = 0}
local is_initialized = false

-- Lifecycle hooks
function on_init()
    print("[" .. mod_name .. "] Initializing mod from JSON...")
    is_initialized = true
    
    -- Set up initial state
    player_position = {x = 100, y = 100}
    
    -- Register some global variables
    _G.mod_version = "1.0.0"
    _G.mod_author = "Example Author"
    
    print("[" .. mod_name .. "] Mod initialized successfully!")
end

function on_ready()
    print("[" .. mod_name .. "] Mod is ready!")
    
    -- This is called after the mod is loaded and ready to run
    -- You can set up event listeners, start timers, etc.
    
    -- Example: Set up a simple timer
    local timer = 0
    _G.update_timer = function(delta)
        timer = timer + delta
        if timer >= 5.0 then
            print("[" .. mod_name .. "] 5 seconds have passed!")
            timer = 0
        end
    end
end

function on_update(delta)
    -- This is called every frame with the delta time
    if not is_initialized then
        return
    end
    
    -- Call our timer function
    if _G.update_timer then
        _G.update_timer(delta)
    end
    
    -- Example: Move player in a circle
    local time = os.time() -- Note: os.time() is safe in sandboxed mode
    player_position.x = 100 + math.cos(time * 0.1) * 50
    player_position.y = 100 + math.sin(time * 0.1) * 50
end

function on_exit()
    print("[" .. mod_name .. "] Mod is shutting down...")
    
    -- Clean up resources
    _G.update_timer = nil
    is_initialized = false
    
    print("[" .. mod_name .. "] Mod cleanup complete!")
end

-- Utility functions that can be called from the game
function get_player_position()
    return player_position
end

function set_player_position(x, y)
    player_position.x = x
    player_position.y = y
    print("[" .. mod_name .. "] Player position set to: " .. x .. ", " .. y)
end

function get_mod_info()
    return {
        name = mod_name,
        version = _G.mod_version,
        author = _G.mod_author,
        initialized = is_initialized
    }
end

-- Example of a function that can be called with arguments
function calculate_damage(base_damage, weapon_multiplier, armor_reduction)
    local final_damage = base_damage * weapon_multiplier * (1 - armor_reduction)
    print("[" .. mod_name .. "] Damage calculation: " .. base_damage .. " * " .. weapon_multiplier .. " * (1 - " .. armor_reduction .. ") = " .. final_damage)
    return final_damage
end

print("[" .. mod_name .. "] Script loaded successfully from JSON mod!") 