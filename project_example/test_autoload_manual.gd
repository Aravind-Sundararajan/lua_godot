extends Node

# Manual test script to check singleton registration

func _ready():
	print("=== Manual Singleton Test ===")
	
	# Check if TestAutoload exists
	if Engine.has_singleton("TestAutoload"):
		print("✓ TestAutoload singleton exists")
		var test_autoload = Engine.get_singleton("TestAutoload")
		if test_autoload:
			print("✓ TestAutoload singleton retrieved successfully")
			print("Class: " + test_autoload.get_class())
		else:
			print("✗ TestAutoload singleton is null")
	else:
		print("✗ TestAutoload singleton does not exist")
	
	# List all singletons
	print("All available singletons:")
	var singletons = Engine.get_singleton_list()
	for i in range(singletons.size()):
		print("  - " + str(singletons[i]))
	
	print("=== Manual Test Complete ===") 