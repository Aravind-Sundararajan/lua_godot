extends Node

# Simple autoload singleton for testing Lua bridge access

var player_score: int = 0
var game_time: float = 0.0
var player_name: String = "DefaultPlayer"
var is_game_active: bool = false

func _ready():
	print("TestAutoload singleton initialized!")

func _process(delta):
	if is_game_active:
		game_time += delta

func get_player_info() -> Dictionary:
	return {
		"name": player_name,
		"score": player_score,
		"game_time": game_time,
		"is_active": is_game_active
	}

func set_player_name(name: String):
	player_name = name
	print("Player name set to: ", name)

func add_score(points: int):
	player_score += points
	print("Score updated: ", player_score)

func start_game():
	is_game_active = true
	game_time = 0.0
	print("Game started!")

func stop_game():
	is_game_active = false
	print("Game stopped! Final score: ", player_score)

func reset_game():
	player_score = 0
	game_time = 0.0
	is_game_active = false
	print("Game reset!")

func get_random_number(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

func calculate_damage(base_damage: float, multiplier: float, armor: float) -> float:
	var final_damage = base_damage * multiplier * (1.0 - armor)
	return max(0.0, final_damage)

func emit_game_event(event_name: String, data: Variant):
	# This would emit a signal in a real implementation
	print("Game event: ", event_name, " with data: ", data) 
