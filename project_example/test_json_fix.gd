extends Node

func _ready():
	#print("=== Testing JSON Parsing Fix ===")
	
	# Initialize LuaBridge
	if not LuaBridgeManager.is_bridge_ready():
		#print("Initializing LuaBridge...")
		LuaBridgeManager.initialize_bridge()
	
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ Failed to initialize LuaBridge!")
		return
	
	#print("✓ LuaBridge initialized successfully!")
	
	# Test 1: Load the simple test mod JSON
	#print("\nTest 1: Loading simple test mod JSON...")
	var result1 = LuaBridgeManager.load_mod_from_json("res://mods/simple_test_mod.json")
	#print("Simple mod loading result: " + str(result1))
	
	# Test 2: Load the temporary test JSON (without entry script)
	#print("\nTest 2: Loading temporary test JSON...")
	var result2 = LuaBridgeManager.load_mod_from_json("res://mods/temp_test.json")
	#print("Temporary JSON loading result: " + str(result2))
	
	# Test 3: Get all mod info
	#print("\nTest 3: Getting all mod info...")
	var all_mod_info = LuaBridgeManager.get_all_mod_info()
	#print("All mod info: " + str(all_mod_info))
	
	#print("\n=== JSON Parsing Test Complete ===")
	
	# Exit after testing
	get_tree().quit() 