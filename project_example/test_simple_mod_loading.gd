extends Node

func _ready():
	#print("=== Testing Simple Mod Loading ===")
	
	# Test if LuaBridgeManager is ready
	if not LuaBridgeManager or not LuaBridgeManager.is_lua_bridge_ready():
		#print("✗ LuaBridgeManager not ready!")
		return
	
	#print("✓ LuaBridgeManager is ready!")
	
	# Get the centralized LuaBridge instance
	var bridge = LuaBridgeManager.get_lua_bridge()
	if not bridge:
		#print("✗ Failed to get LuaBridge from manager!")
		return
	
	#print("✓ LuaBridge instance acquired from manager!")
	
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
	var result = bridge.load_mod_from_json("res://mods/test_parsing.json")
	#print("JSON loading result: " + str(result))
	
	if result:
		#print("✓ JSON parsing successful!")
	else:
		#print("✗ JSON parsing failed!")
	
	# Test 3: Get mod info
	#print("\nTest 3: Getting mod info...")
	var mod_info = bridge.get_mod_info("TestMod")
	#print("Mod info: " + str(mod_info))
	
	# Test 4: Get all mods
	#print("\nTest 4: Getting all mods...")
	var all_mods = bridge.get_all_mod_info()
	#print("All mods: " + str(all_mods))
	
	#print("\n=== Simple Mod Loading Test Complete ===")
	#print("✓ All tests completed without crashes!")
	
	# Clean up test file
	DirAccess.remove_absolute("res://mods/test_parsing.json")
	
	# No need to queue_free the bridge, as it's managed by the manager
	# Exit after testing
	get_tree().quit() 