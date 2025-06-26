extends Node

func _ready():
	print("Testing Lua Bridge Extension...")
	
	# Test if the extension is loaded
	if ClassDB.class_exists("LuaBridge"):
		print("✓ LuaBridge class found!")
		
		# Use LuaBridgeManager instead of direct instantiation
		if not LuaBridgeManager.is_bridge_ready():
			print("Initializing LuaBridge through manager...")
			LuaBridgeManager.initialize_bridge()
		
		if LuaBridgeManager.is_bridge_ready():
			print("✓ LuaBridge initialized through manager!")
			
			# Test basic functionality
			LuaBridgeManager.set_sandboxed(true)
			print("✓ Safe environment setup completed!")
			
			# Test Lua execution
			LuaBridgeManager.execute_lua("print('Hello from Lua!')")
			print("✓ Lua execution test completed!")
			
			# Cleanup
			LuaBridgeManager.unload_bridge()
			print("✓ Cleanup completed!")
		else:
			print("✗ Failed to initialize LuaBridge through manager")
	else:
		print("✗ LuaBridge class not found!")
		print("Make sure the extension is properly loaded and the plugin is enabled.")
	
	print("Extension test completed!") 