extends Node

func _ready():
	#print("=== Testing Mod Loading After JSON Fix ===")
	
	# Initialize LuaBridge
	if not LuaBridgeManager.is_bridge_ready():
		#print("Initializing LuaBridge...")
		LuaBridgeManager.initialize_bridge()
	
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ Failed to initialize LuaBridge!")
		return
	
	#print("✓ LuaBridge initialized successfully!")
	
	# Test 1: Create a simple test JSON file
	#print("\nTest 1: Creating test JSON file...")
	var test_json = {
		"name": "TestMod",
		"version": "1.0.0",
		"author": "Test Author",
		"description": "Test mod for JSON parsing",
		"enabled": false
	}
	
	var file = FileAccess.open("res://mods/test_parsing.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(test_json))
		file.close()
		#print("✓ Created test JSON file")
	else:
		#print("✗ Failed to create test JSON file")
		return
	
	# Test 2: Load the test JSON file
	#print("\nTest 2: Loading test JSON file...")
	var result = LuaBridgeManager.load_mod_from_json("res://mods/test_parsing.json")
	#print("JSON loading result: " + str(result))
	
	if result:
		#print("✓ JSON parsing successful!")
	else:
		#print("✗ JSON parsing failed!")
		return
	
	# Test 3: Get mod info
	#print("\nTest 3: Getting mod info...")
	var mod_info = LuaBridgeManager.get_mod_info("TestMod")
	#print("Mod info: " + str(mod_info))
	
	# Test 4: Get all mods
	#print("\nTest 4: Getting all mods...")
	var all_mods = LuaBridgeManager.get_all_mod_info()
	#print("All mods: " + str(all_mods))
	
	# Test 5: Load the simple test mod (with entry script)
	#print("\nTest 5: Loading simple test mod with entry script...")
	var simple_result = LuaBridgeManager.load_mod_from_json("res://mods/simple_test_mod.json")
	#print("Simple mod loading result: " + str(simple_result))
	
	# Test 6: Load mods from directory
	#print("\nTest 6: Loading mods from directory...")
	var dir_result = LuaBridgeManager.load_mods_from_directory("res://mods")
	#print("Directory loading result: " + str(dir_result))
	
	# Test 7: Final mod list
	#print("\nTest 7: Final mod list...")
	var final_mods = LuaBridgeManager.get_all_mod_info()
	#print("Final mods: " + str(final_mods))
	
	#print("\n=== Mod Loading Test Complete ===")
	#print("✓ All tests completed without crashes!")
	
	# Clean up test file
	DirAccess.remove_absolute("res://mods/test_parsing.json")
	
	# Exit after testing
	get_tree().quit() 