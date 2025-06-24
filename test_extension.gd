extends Node

func _ready():
	print("Testing Lua Bridge Extension...")
	
	# Test if the extension is loaded
	if ClassDB.class_exists("LuaBridge"):
		print("✓ LuaBridge class found!")
		
		# Try to create an instance
		var lua_bridge = LuaBridge.new()
		if lua_bridge:
			print("✓ LuaBridge instance created successfully!")
			
			# Test basic functionality
			lua_bridge.setup_safe_environment()
			print("✓ Safe environment setup completed!")
			
			# Test Lua execution
			lua_bridge.exec_string("print('Hello from Lua!')")
			print("✓ Lua execution test completed!")
			
			# Cleanup
			lua_bridge.unload()
			print("✓ Cleanup completed!")
		else:
			print("✗ Failed to create LuaBridge instance")
	else:
		print("✗ LuaBridge class not found!")
		print("Make sure the extension is properly loaded and the plugin is enabled.")
	
	print("Extension test completed!") 