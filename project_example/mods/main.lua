-- Example Mod Main Script
-- This is loaded by the JSON mod management system

local mod_name = "ExampleMod"
local player_position = {x = 0, y = 0}
local is_initialized = false
local coroutine_manager = nil
local event_subscriptions = {}

-- Lifecycle hooks
function on_init()
    print("[" .. mod_name .. "] Initializing mod from JSON...")
    is_initialized = true
    
    -- Set up initial state
    player_position = {x = 100, y = 100}
    
    -- Register some global variables
    _G.mod_version = "1.0.0"
    _G.mod_author = "Example Author"
    
    -- Subscribe to events
    subscribe_event("player_damaged", "on_player_damaged")
    subscribe_event("level_completed", "on_level_completed")
    
    -- Set up coroutine manager
    coroutine_manager = {
        active_coroutines = {},
        next_id = 1
    }
    
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
            
            -- Emit an event
            emit_event("mod_timer_tick", {mod_name = mod_name, timer_value = timer})
        end
    end
    
    -- Start a background coroutine
    start_background_task()
    -- Test autoload singleton
    test_autoload_singleton()
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
    
    -- Resume any active coroutines
    resume_coroutines(delta)
end

function on_exit()
    print("[" .. mod_name .. "] Mod is shutting down...")
    
    -- Clean up resources
    _G.update_timer = nil
    is_initialized = false
    
    -- Clean up coroutines
    if coroutine_manager then
        for id, co in pairs(coroutine_manager.active_coroutines) do
            cleanup_coroutine(id)
        end
    end
    
    print("[" .. mod_name .. "] Mod cleanup complete!")
end

-- Event handling functions
function on_player_damaged(data)
    print("[" .. mod_name .. "] Player damaged! Damage: " .. (data.damage or "unknown"))
    print("[" .. mod_name .. "] Player health: " .. (data.health or "unknown"))
end

function on_level_completed(data)
    print("[" .. mod_name .. "] Level completed! Level: " .. (data.level or "unknown"))
    print("[" .. mod_name .. "] Score: " .. (data.score or "unknown"))
end

-- Coroutine management
function start_background_task()
    local co_id = create_coroutine("background_task")
    if co_id then
        print("[" .. mod_name .. "] Started background task coroutine: " .. co_id)
    end
end

function background_task()
    print("[" .. mod_name .. "] Background task started")
    
    for i = 1, 10 do
        print("[" .. mod_name .. "] Background task iteration " .. i)
        coroutine.yield() -- Yield to main thread
        -- Wait 1 second
        local start_time = os.time()
        while os.time() - start_time < 1 do
            coroutine.yield()
        end
    end
    
    print("[" .. mod_name .. "] Background task completed")
    emit_event("background_task_completed", {mod_name = mod_name, iterations = 10})
end

-- Godot object interaction examples
function test_godot_objects()
    print("[" .. mod_name .. "] Testing Godot object interaction...")
    
    -- Try to get the main scene
    local main_scene = get_node("/root/Main")
    if main_scene then
        print("[" .. mod_name .. "] Found main scene!")
        
        -- Create a wrapper for safe access
        local wrapper = create_wrapper(main_scene, "Control")
        if is_wrapper_valid(wrapper) then
            print("[" .. mod_name .. "] Main scene wrapper created successfully!")
            
            -- Try to get children
            local children = get_children(main_scene)
            if children then
                print("[" .. mod_name .. "] Main scene has " .. #children .. " children")
            end
            
            -- Try to get a specific child
            local vbox = get_node("/root/Main/VBoxContainer")
            if vbox then
                print("[" .. mod_name .. "] Found VBoxContainer!")
                
                -- Test property access
                local visible = get_property(vbox, "visible")
                print("[" .. mod_name .. "] VBoxContainer visible: " .. tostring(visible))
                
                -- Test method call
                local child_count = call_method(vbox, "get_child_count")
                print("[" .. mod_name .. "] VBoxContainer child count: " .. tostring(child_count))
            end
        end
    else
        print("[" .. mod_name .. "] Could not find main scene")
    end
end

-- Resource loading example
function test_resource_loading()
    print("[" .. mod_name .. "] Testing resource loading...")
    
    -- Try to load a resource (this would work if we had resources)
    local resource = load_resource("res://icon.png")
    if resource then
        print("[" .. mod_name .. "] Successfully loaded resource!")
        
        -- Create a wrapper
        local wrapper = create_wrapper(resource, "Resource")
        if is_wrapper_valid(wrapper) then
            print("[" .. mod_name .. "] Resource wrapper created!")
        end
    else
        print("[" .. mod_name .. "] Could not load resource (this is expected)")
    end
end

-- Signal connection example
function test_signal_connection()
    print("[" .. mod_name .. "] Testing signal connection...")
    
    local main_scene = get_node("/root/Main")
    if main_scene then
        local wrapper = create_wrapper(main_scene, "Control")
        if is_wrapper_valid(wrapper) then
            -- Try to connect to a signal (this would work if the signal exists)
            local success = connect_signal(main_scene, "ready", "on_main_ready")
            if success then
                print("[" .. mod_name .. "] Successfully connected to ready signal!")
            else
                print("[" .. mod_name .. "] Could not connect to ready signal (this is expected)")
            end
        end
    end
end

function on_main_ready()
    print("[" .. mod_name .. "] Main scene ready signal received!")
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
        initialized = is_initialized,
        coroutines = coroutine_manager and #coroutine_manager.active_coroutines or 0
    }
end

-- Example of a function that can be called with arguments
function calculate_damage(base_damage, weapon_multiplier, armor_reduction)
    local final_damage = base_damage * weapon_multiplier * (1 - armor_reduction)
    print("[" .. mod_name .. "] Damage calculation: " .. base_damage .. " * " .. weapon_multiplier .. " * (1 - " .. armor_reduction .. ") = " .. final_damage)
    return final_damage
end

-- Advanced function with type checking
function advanced_calculation(base_value, multiplier, options)
    -- Validate arguments
    if type(base_value) ~= "number" then
        error("base_value must be a number")
    end
    if type(multiplier) ~= "number" then
        error("multiplier must be a number")
    end
    if options and type(options) ~= "table" then
        error("options must be a table")
    end
    
    local result = base_value * multiplier
    
    -- Apply options if provided
    if options then
        if options.bonus then
            result = result + options.bonus
        end
        if options.percentage then
            result = result * (1 + options.percentage / 100)
        end
    end
    
    print("[" .. mod_name .. "] Advanced calculation result: " .. result)
    return result
end

-- Test all new features
function test_all_features()
    print("[" .. mod_name .. "] Testing all new features...")
    
    -- Test Godot object interaction
    test_godot_objects()
    
    -- Test resource loading
    test_resource_loading()
    
    -- Test signal connection
    test_signal_connection()
    
    -- Test advanced calculation
    local result = advanced_calculation(100, 1.5, {bonus = 25, percentage = 10})
    print("[" .. mod_name .. "] Advanced calculation test result: " .. result)
    
    print("[" .. mod_name .. "] All features tested!")
end

function test_autoload_singleton()
    print("[" .. mod_name .. "] Testing TestAutoload singleton from Lua...")
    local test_autoload = get_autoload_singleton("TestAutoload")
    if test_autoload then
        -- Get player info
        local player_info = test_autoload:get_player_info()
        print("[" .. mod_name .. "] Player info from TestAutoload: " .. tostring(player_info))

        -- Set player name
        test_autoload:set_player_name("LuaPlayer")
        print("[" .. mod_name .. "] Set player name to LuaPlayer")

        -- Add score
        test_autoload:add_score(123)
        print("[" .. mod_name .. "] Added 123 to player score")

        -- Get updated info
        local updated_info = test_autoload:get_player_info()
        print("[" .. mod_name .. "] Updated player info: " .. tostring(updated_info))

        -- Call utility methods
        local random_num = test_autoload:get_random_number(1, 100)
        print("[" .. mod_name .. "] Random number from TestAutoload: " .. tostring(random_num))

        local damage = test_autoload:calculate_damage(50, 2, 0.1)
        print("[" .. mod_name .. "] Damage calculation from TestAutoload: " .. tostring(damage))

        -- Start and stop game
        test_autoload:start_game()
        print("[" .. mod_name .. "] Started game via TestAutoload")
        test_autoload:stop_game()
        print("[" .. mod_name .. "] Stopped game via TestAutoload")
        test_autoload:reset_game()
        print("[" .. mod_name .. "] Reset game via TestAutoload")
    else
        print("[" .. mod_name .. "] Could not get TestAutoload singleton!")
    end
end

print("[" .. mod_name .. "] Script loaded successfully from JSON mod!")
print("[" .. mod_name .. "] New features available: safe casting, Godot objects, signals, events, coroutines!") 