extends Node

func _ready():
	print("=== Testing Path Resolution Fix ===")
	
	# Test if LuaBridgeManager is available
	if not Engine.has_singleton("LuaBridgeManager"):
		print("✗ LuaBridgeManager singleton not found!")
		get_tree().quit()
		return
	
	print("✓ LuaBridgeManager singleton found!")
	
	# Initialize the bridge
	if not LuaBridgeManager.is_bridge_ready():
		print("Initializing LuaBridge...")
		LuaBridgeManager.initialize_bridge()
	
	if not LuaBridgeManager.is_bridge_ready():
		print("✗ Failed to initialize LuaBridge!")
		get_tree().quit()
		return
	
	print("✓ LuaBridge initialized!")
	
	# Test 1: Check if the simple mod files exist
	print("\nTest 1: Checking file existence...")
	var json_exists = FileAccess.file_exists("res://mods/simple_test_mod.json")
	var lua_exists = FileAccess.file_exists("res://mods/simple_test.lua")
	print("JSON file exists: " + str(json_exists))
	print("Lua file exists: " + str(lua_exists))
	
	if not json_exists or not lua_exists:
		print("✗ Required files not found!")
		get_tree().quit()
		return
	
	print("✓ All required files found!")
	
	# Test 2: Load the simple mod
	print("\nTest 2: Loading simple mod...")
	var result = LuaBridgeManager.load_mod_from_json("res://mods/simple_test_mod.json")
	print("Simple mod loading result: " + str(result))
	
	if result:
		print("✓ Simple mod loaded successfully!")
		
		# Test 3: Get mod info
		print("\nTest 3: Getting mod info...")
		var all_mod_info = LuaBridgeManager.get_all_mod_info()
		print("All mod info: " + str(all_mod_info))
		
		# Test 4: Check if the mod is enabled
		print("\nTest 4: Checking mod status...")
		var is_enabled = LuaBridgeManager.is_mod_enabled("SimpleTestMod")
		print("SimpleTestMod enabled: " + str(is_enabled))
		
		# Test 5: Try to enable the mod
		if not is_enabled:
			print("\nTest 5: Enabling mod...")
			LuaBridgeManager.enable_mod("SimpleTestMod")
			is_enabled = LuaBridgeManager.is_mod_enabled("SimpleTestMod")
			print("SimpleTestMod enabled after enable: " + str(is_enabled))
		
		print("\n=== Path Resolution Test Complete ===")
		print("✓ All tests completed successfully!")
		print("✓ Path resolution fix appears to be working!")
	else:
		print("✗ Simple mod loading failed!")
		print("✗ Path resolution fix may not be working!")
	
	# Quit after a short delay
	await get_tree().create_timer(2.0).timeout
	get_tree().quit() 