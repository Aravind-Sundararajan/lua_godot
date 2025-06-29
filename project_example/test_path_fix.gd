extends Node

func _ready():
	#print("=== Testing Path Resolution Fix ===")
	
	# Test if the LuaBridge class exists
	if not ClassDB.class_exists("LuaBridge"):
		#print("✗ LuaBridge class not found!")
		get_tree().quit()
		return
	
	#print("✓ LuaBridge class found!")
	
	# Create a LuaBridge instance directly
	var bridge = ClassDB.instantiate("LuaBridge")
	if not bridge:
		#print("✗ Failed to create LuaBridge instance!")
		get_tree().quit()
		return
	
	#print("✓ LuaBridge instance created!")
	
	# Test 1: Check if the simple mod files exist
	#print("\nTest 1: Checking file existence...")
	var json_exists = FileAccess.file_exists("res://mods/simple_test_mod.json")
	var lua_exists = FileAccess.file_exists("res://mods/simple_test.lua")
	#print("JSON file exists: " + str(json_exists))
	#print("Lua file exists: " + str(lua_exists))
	
	if not json_exists or not lua_exists:
		#print("✗ Required files not found!")
		bridge.queue_free()
		get_tree().quit()
		return
	
	#print("✓ All required files found!")
	
	# Test 2: Load the simple mod
	#print("\nTest 2: Loading simple mod...")
	var result = bridge.load_mod_from_json("res://mods/simple_test_mod.json")
	#print("Simple mod loading result: " + str(result))
	
	if result:
		#print("✓ Simple mod loaded successfully!")
		
		# Test 3: Get mod info
		#print("\nTest 3: Getting mod info...")
		var all_mod_info = bridge.get_all_mod_info()
		#print("All mod info: " + str(all_mod_info))
		
		# Test 4: Check if the mod is enabled
		#print("\nTest 4: Checking mod status...")
		var is_enabled = bridge.is_mod_enabled("SimpleTestMod")
		#print("SimpleTestMod enabled: " + str(is_enabled))
		
		#print("\n=== Path Resolution Test Complete ===")
		#print("✓ All tests completed successfully!")
		#print("✓ Path resolution fix appears to be working!")
	else:
		#print("✗ Simple mod loading failed!")
		#print("✗ Path resolution fix may not be working!")
	
	# Clean up
	bridge.queue_free()
	
	# Quit after a short delay
	await get_tree().create_timer(2.0).timeout
	get_tree().quit() 