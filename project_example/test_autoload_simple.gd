extends Node

func _ready():
	print("=== Testing Autoload Singleton ===")
	
	# Try to access the autoload singleton
	var test_autoload = get_node("/root/TestAutoload")
	if test_autoload:
		print("✓ TestAutoload singleton found!")
		print("Player info: ", test_autoload.get_player_info())
	else:
		print("✗ TestAutoload singleton not found")
	
	# List all autoload nodes
	print("\nAll autoload nodes:")
	var root = get_tree().root
	for child in root.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	print("=== Test Complete ===")
	get_tree().quit() 