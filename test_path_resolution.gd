extends Node

func _ready():
	#print("=== Testing Path Resolution ===")
	
	# Test if LuaBridgeManager is available
	if not Engine.has_singleton("LuaBridgeManager"):
		#print("✗ LuaBridgeManager singleton not found!")
		return
	
	#print("✓ LuaBridgeManager singleton found!")
	
	# Initialize the bridge
	if not LuaBridgeManager.is_bridge_ready():
		#print("Initializing LuaBridge...")
		LuaBridgeManager.initialize_bridge()
	
	if not LuaBridgeManager.is_bridge_ready():
		#print("✗ Failed to initialize LuaBridge!")
		return
	
	#print("✓ LuaBridge initialized!")
	
	# Test loading the simple mod
	#print("Testing simple mod loading...")
	var result = LuaBridgeManager.load_mod_from_json("res://mods/simple_test_mod.json")
	#print("Simple mod loading result: " + str(result))
	
	if result:
		#print("✓ Simple mod loaded successfully!")
		
		# Get mod info
		var all_mod_info = LuaBridgeManager.get_all_mod_info()
		#print("All mod info: " + str(all_mod_info))
		
		# Check if the mod is enabled
		var is_enabled = LuaBridgeManager.is_mod_enabled("SimpleTestMod")
		#print("SimpleTestMod enabled: " + str(is_enabled))
	else:
		#print("✗ Simple mod loading failed!")
	
	#print("=== Path Resolution Test Complete ===")
	
	# Quit after a short delay
	await get_tree().create_timer(1.0).timeout
	get_tree().quit() 