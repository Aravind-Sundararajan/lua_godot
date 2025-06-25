-- Base Game Mod
-- This mod contains the core game functionality

local BaseGame = {}

-- Mod metadata
BaseGame.name = "BaseGame"
BaseGame.version = "1.0.0"
BaseGame.author = "Game Developer"

-- Game state
BaseGame.player = {
    health = 100,
    level = 1,
    experience = 0,
    position = {x = 0, y = 0}
}

BaseGame.game_state = {
    is_running = false,
    current_scene = "main_menu",
    time_elapsed = 0
}

-- Initialize the base game
function on_init()
    print("[BaseGame] Initializing base game...")
    
    -- Set up global game functions
    _G.get_player_health = function()
        return BaseGame.player.health
    end
    
    _G.set_player_health = function(health)
        BaseGame.player.health = math.max(0, math.min(100, health))
        print("[BaseGame] Player health set to: " .. BaseGame.player.health)
    end
    
    _G.get_player_level = function()
        return BaseGame.player.level
    end
    
    _G.get_player_position = function()
        return BaseGame.player.position
    end
    
    _G.set_player_position = function(x, y)
        BaseGame.player.position.x = x
        BaseGame.player.position.y = y
        print("[BaseGame] Player position set to: (" .. x .. ", " .. y .. ")")
    end
    
    -- Game utility functions
    _G.calculate_damage = function(base_damage, weapon_multiplier, armor_reduction)
        local damage = base_damage * weapon_multiplier
        damage = damage * (1 - armor_reduction)
        return math.floor(damage)
    end
    
    _G.advanced_calculation = function(base, multiplier, options)
        local bonus = options.bonus or 0
        local percentage = options.percentage or 0
        local result = (base * multiplier) + bonus
        result = result * (1 + percentage / 100)
        return result
    end
    
    print("[BaseGame] Base game initialized successfully!")
end

-- Called when the game is ready to start
function on_ready()
    print("[BaseGame] Base game is ready!")
    BaseGame.game_state.is_running = true
    
    -- Set up initial game state
    BaseGame.player.health = 100
    BaseGame.player.level = 1
    BaseGame.player.experience = 0
    BaseGame.player.position = {x = 0, y = 0}
    
    print("[BaseGame] Player initialized: Level " .. BaseGame.player.level .. ", Health " .. BaseGame.player.health)
end

-- Called every frame
function on_update(delta)
    BaseGame.game_state.time_elapsed = BaseGame.game_state.time_elapsed + delta
    
    -- Example: Regenerate health over time (1 HP per second)
    if BaseGame.player.health < 100 then
        BaseGame.player.health = math.min(100, BaseGame.player.health + delta)
    end
end

-- Called when the game is shutting down
function on_exit()
    print("[BaseGame] Base game shutting down...")
    BaseGame.game_state.is_running = false
    
    -- Save game state here if needed
    print("[BaseGame] Game state saved. Total time played: " .. math.floor(BaseGame.game_state.time_elapsed) .. " seconds")
end

-- Test function for the "Test All Features" button
function test_all_features()
    print("[BaseGame] Testing all base game features...")
    
    -- Test player functions
    print("Player health: " .. get_player_health())
    set_player_health(75)
    print("Player level: " .. get_player_level())
    set_player_position(10, 20)
    
    -- Test damage calculation
    local damage = calculate_damage(100, 1.5, 0.2)
    print("Damage calculation: " .. damage)
    
    -- Test advanced calculation
    local result = advanced_calculation(100, 1.5, {bonus = 25, percentage = 10})
    print("Advanced calculation: " .. result)
    
    print("[BaseGame] All features tested successfully!")
    return "Base game features working correctly!"
end

-- Get mod info
function get_mod_info()
    return {
        name = BaseGame.name,
        version = BaseGame.version,
        author = BaseGame.author,
        description = "The base game functionality implemented as a mod",
        player_health = BaseGame.player.health,
        player_level = BaseGame.player.level,
        game_time = math.floor(BaseGame.game_state.time_elapsed)
    }
end

print("[BaseGame] Base game mod loaded successfully!") 