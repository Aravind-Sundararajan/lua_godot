extends Control

var lua_bridge: LuaBridge
var output_buffer: String = ""

func _ready():
	# Initialize Lua bridge
	lua_bridge = LuaBridge.new()
	
	# Connect button signals
	$VBoxContainer/HBoxContainer/VBoxContainer/LoadModsButton.pressed.connect(_on_load_mods_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer/LoadSpecificModButton.pressed.connect(_on_load_specific_mod_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer/EnableModButton.pressed.connect(_on_enable_mod_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer/DisableModButton.pressed.connect(_on_disable_mod_button_pressed)
	
	$VBoxContainer/HBoxContainer/VBoxContainer2/ExecuteStringButton.pressed.connect(_on_execute_string_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer2/CallFunctionButton.pressed.connect(_on_call_function_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer2/SetGlobalButton.pressed.connect(_on_set_global_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer2/GetGlobalButton.pressed.connect(_on_get_global_button_pressed)
	
	$VBoxContainer/HBoxContainer/VBoxContainer3/CallInitButton.pressed.connect(_on_call_init_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer3/CallReadyButton.pressed.connect(_on_call_ready_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer3/CallExitButton.pressed.connect(_on_call_exit_button_pressed)
	
	$VBoxContainer/HBoxContainer/VBoxContainer4/ToggleSandboxButton.pressed.connect(_on_toggle_sandbox_button_pressed)
	$VBoxContainer/HBoxContainer/VBoxContainer4/TestUnsafeCodeButton.pressed.connect(_on_test_unsafe_code_button_pressed)
	
	# Initialize the bridge
	lua_bridge.setup_safe_environment()
	append_output("Lua Bridge initialized successfully!")
	
	# Load the example mod
	_load_example_mod()

func _load_example_mod():
	# Copy the example mod to the project directory if it doesn't exist
	var mod_dir = "res://mods"
	var example_mod_dir = mod_dir.path_join("example_mod")
	
	# Create mods directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("mods"):
		dir.make_dir("mods")
	
	# Copy example mod files
	_copy_example_mod_files()

func _copy_example_mod_files():
	# This is a simplified version - in a real project you'd want to copy the files
	# For now, we'll just try to load from the relative path
	append_output("Attempting to load example mod...")

func append_output(text: String):
	output_buffer += text + "\n"
	$VBoxContainer/OutputTextEdit.text = output_buffer
	$VBoxContainer/OutputTextEdit.scroll_vertical = $VBoxContainer/OutputTextEdit.get_line_count()

func update_mod_info():
	var all_mod_info = lua_bridge.get_all_mod_info()
	var info_text = "Loaded Mods:\n"
	
	if all_mod_info.size() == 0:
		info_text += "No mods loaded"
	else:
		for mod_info in all_mod_info:
			info_text += "• " + mod_info["name"] + " v" + mod_info["version"] + " by " + mod_info["author"]
			if lua_bridge.is_mod_enabled(mod_info["name"]):
				info_text += " (ENABLED)"
			else:
				info_text += " (DISABLED)"
			info_text += "\n  " + mod_info["description"] + "\n\n"
	
	$VBoxContainer/ModInfoTextEdit.text = info_text

# Mod Management Functions
func _on_load_mods_button_pressed():
	append_output("Loading mods from directory...")
	var success = lua_bridge.load_mods_from_directory("../example_mod")
	append_output("Load result: " + str(success))
	update_mod_info()

func _on_load_specific_mod_button_pressed():
	append_output("Loading specific mod JSON...")
	var success = lua_bridge.load_mod_from_json("../example_mod/mod.json")
	append_output("Load result: " + str(success))
	update_mod_info()

func _on_enable_mod_button_pressed():
	append_output("Enabling ExampleMod...")
	lua_bridge.enable_mod("ExampleMod")
	update_mod_info()

func _on_disable_mod_button_pressed():
	append_output("Disabling ExampleMod...")
	lua_bridge.disable_mod("ExampleMod")
	update_mod_info()

# Lua Scripting Functions
func _on_execute_string_button_pressed():
	append_output("Executing Lua string...")
	var lua_code = """
print("Hello from Lua!")
local x = 10
local y = 20
print("Sum: " .. (x + y))
return "Lua execution completed"
"""
	lua_bridge.exec_string(lua_code)

func _on_call_function_button_pressed():
	append_output("Calling Lua function...")
	var args = Array()
	args.append(100)  # base_damage
	args.append(1.5)  # weapon_multiplier
	args.append(0.2)  # armor_reduction
	
	var result = lua_bridge.call_function("calculate_damage", args)
	append_output("Function result: " + str(result))

func _on_set_global_button_pressed():
	append_output("Setting global variable...")
	lua_bridge.set_global("player_health", 100)
	lua_bridge.set_global("player_level", 5)
	lua_bridge.set_global("player_name", "Hero")
	append_output("Global variables set")

func _on_get_global_button_pressed():
	append_output("Getting global variables...")
	var health = lua_bridge.get_global("player_health")
	var level = lua_bridge.get_global("player_level")
	var name = lua_bridge.get_global("player_name")
	append_output("Player: " + str(name) + ", Level: " + str(level) + ", Health: " + str(health))

# Lifecycle Functions
func _on_call_init_button_pressed():
	append_output("Calling on_init()...")
	lua_bridge.call_on_init()

func _on_call_ready_button_pressed():
	append_output("Calling on_ready()...")
	lua_bridge.call_on_ready()

func _on_call_exit_button_pressed():
	append_output("Calling on_exit()...")
	lua_bridge.call_on_exit()

# Sandboxing Functions
func _on_toggle_sandbox_button_pressed():
	var current_sandboxed = lua_bridge.is_sandboxed()
	lua_bridge.set_sandboxed(!current_sandboxed)
	append_output("Sandbox mode: " + str(lua_bridge.is_sandboxed()))

func _on_test_unsafe_code_button_pressed():
	append_output("Testing unsafe code...")
	var unsafe_code = """
-- This should fail in sandboxed mode
os.execute("echo 'This is unsafe!'")
"""
	lua_bridge.exec_string(unsafe_code)

func _process(delta):
	# Call update hook every frame for mods
	lua_bridge.call_on_update(delta)

func _exit_tree():
	# Clean up when the scene is destroyed
	if lua_bridge:
		lua_bridge.call_on_exit()
		lua_bridge.unload() 