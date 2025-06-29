extends Node

# Test script to check singleton timing

func _ready():
	#print("=== Singleton Timing Test ===")
	
	# Test immediately
	test_singleton_access("Immediate")
	
	# Test after a frame
	call_deferred("test_singleton_access", "Deferred")
	
	# Test after a longer delay
	get_tree().create_timer(1.0).timeout.connect(func(): test_singleton_access("Delayed"))

func test_singleton_access(timing: String):
	#print("--- Testing at: " + timing + " ---")
	
	# Method 1: Direct access (like in main.gd)
	var direct_access = null
	if Engine.has_singleton("TestAutoload"):
		direct_access = Engine.get_singleton("TestAutoload")
		#print("✓ Direct access successful")
	else:
		#print("✗ Direct access failed")
	
	# Method 2: Try to access via TestAutoload global
	var global_access = null
	if "TestAutoload" in get_global_class_list():
		#print("✓ TestAutoload in global class list")
		# Try to access it
		global_access = get_node("/root/TestAutoload")
		if global_access:
			#print("✓ Global access successful")
		else:
			#print("✗ Global access failed")
	else:
		#print("✗ TestAutoload not in global class list")
	
	# Method 3: Check if it's in the scene tree
	var scene_access = get_node_or_null("/root/TestAutoload")
	if scene_access:
		#print("✓ Scene tree access successful")
	else:
		#print("✗ Scene tree access failed")
	
	#print("--- " + timing + " test complete ---") 