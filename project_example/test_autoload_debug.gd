extends Node

# Simple debug script to test autoload singleton functionality

func _ready():
	#print("=== Autoload Debug Test ===")
	
	# Test 1: Check if the singleton exists in the engine
	if Engine.has_singleton("TestAutoload"):
		#print("✓ TestAutoload singleton is registered in the engine")
	else:
		#print("✗ TestAutoload singleton is NOT registered in the engine")
	
	# Test 2: Try to get the singleton directly
	var test_autoload = Engine.get_singleton("TestAutoload")
	if test_autoload:
		#print("✓ Successfully retrieved TestAutoload singleton directly")
		#print("Singleton class: ", test_autoload.get_class())
	else:
		#print("✗ Failed to retrieve TestAutoload singleton directly")
	
	# Test 3: Try to access it as a global variable
	if has_node("/root/TestAutoload"):
		#print("✓ TestAutoload node exists in the scene tree")
		var node = get_node("/root/TestAutoload")
		#print("Node class: ", node.get_class())
	else:
		#print("✗ TestAutoload node does not exist in the scene tree")
	
	# Test 4: List all autoload singletons
	#print("\n--- All Autoload Singletons ---")
	var autoloads = Engine.get_singleton_list()
	for singleton_name in autoloads:
		#print("Found singleton: " + singleton_name)
	
	if autoloads.size() == 0:
		#print("No autoload singletons found!")
	
	#print("=== Debug Test Complete ===") 