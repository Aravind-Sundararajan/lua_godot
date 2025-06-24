#include "bridge.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>

using namespace godot;

void LuaBridge::_bind_methods() {
	ClassDB::bind_method(D_METHOD("exec_string", "code"), &LuaBridge::exec_string);
	ClassDB::bind_method(D_METHOD("exec_file", "path"), &LuaBridge::exec_file);
	ClassDB::bind_method(D_METHOD("load_file", "path"), &LuaBridge::load_file);
	ClassDB::bind_method(D_METHOD("reload"), &LuaBridge::reload);
	ClassDB::bind_method(D_METHOD("unload"), &LuaBridge::unload);
	
	ClassDB::bind_method(D_METHOD("set_global", "name", "value"), &LuaBridge::set_global);
	ClassDB::bind_method(D_METHOD("get_global", "name"), &LuaBridge::get_global);
	
	ClassDB::bind_method(D_METHOD("call_function", "func_name", "args"), &LuaBridge::call_function);
	ClassDB::bind_method(D_METHOD("register_function", "name", "cb"), &LuaBridge::register_function);
	
	// Mod management
	ClassDB::bind_method(D_METHOD("load_script_from_directory", "mod_dir"), &LuaBridge::load_script_from_directory);
	ClassDB::bind_method(D_METHOD("call_event", "event_name", "args"), &LuaBridge::call_event);
	ClassDB::bind_method(D_METHOD("list_loaded_mods"), &LuaBridge::list_loaded_mods);
	ClassDB::bind_method(D_METHOD("unload_mod", "mod_name"), &LuaBridge::unload_mod);
	
	// JSON mod management
	ClassDB::bind_method(D_METHOD("load_mod_from_json", "mod_json_path"), &LuaBridge::load_mod_from_json);
	ClassDB::bind_method(D_METHOD("load_mods_from_directory", "mods_dir"), &LuaBridge::load_mods_from_directory);
	ClassDB::bind_method(D_METHOD("get_mod_info", "mod_name"), &LuaBridge::get_mod_info);
	ClassDB::bind_method(D_METHOD("get_all_mod_info"), &LuaBridge::get_all_mod_info);
	ClassDB::bind_method(D_METHOD("is_mod_enabled", "mod_name"), &LuaBridge::is_mod_enabled);
	ClassDB::bind_method(D_METHOD("enable_mod", "mod_name"), &LuaBridge::enable_mod);
	ClassDB::bind_method(D_METHOD("disable_mod", "mod_name"), &LuaBridge::disable_mod);
	
	// Lifecycle hooks
	ClassDB::bind_method(D_METHOD("call_on_init"), &LuaBridge::call_on_init);
	ClassDB::bind_method(D_METHOD("call_on_ready"), &LuaBridge::call_on_ready);
	ClassDB::bind_method(D_METHOD("call_on_update", "delta"), &LuaBridge::call_on_update);
	ClassDB::bind_method(D_METHOD("call_on_exit"), &LuaBridge::call_on_exit);
	
	// Security & sandboxing
	ClassDB::bind_method(D_METHOD("set_sandboxed", "enabled"), &LuaBridge::set_sandboxed);
	ClassDB::bind_method(D_METHOD("is_sandboxed"), &LuaBridge::is_sandboxed);
	ClassDB::bind_method(D_METHOD("setup_safe_environment"), &LuaBridge::setup_safe_environment);
	
	// Utility methods
	ClassDB::bind_method(D_METHOD("print_to_console", "message"), &LuaBridge::print_to_console);
	ClassDB::bind_method(D_METHOD("log_error", "error_message"), &LuaBridge::log_error);
	ClassDB::bind_method(D_METHOD("get_last_error"), &LuaBridge::get_last_error);
}

LuaBridge::LuaBridge() {
	L = luaL_newstate();
	if (L) {
		if (sandboxed) {
			setup_safe_environment();
		} else {
			luaL_openlibs(L);
		}
		setup_game_api();
	}
}

LuaBridge::~LuaBridge() {
	if (L) {
		call_on_exit(); // Call exit hooks before cleanup
		lua_close(L);
		L = nullptr;
	}
}

void LuaBridge::exec_string(String code) {
	if (!L) return;
	
	if (luaL_dostring(L, code.utf8().get_data()) != LUA_OK) {
		log_error(get_lua_error());
	}
}

void LuaBridge::exec_file(String path) {
	if (!L) return;
	
	if (luaL_dofile(L, path.utf8().get_data()) != LUA_OK) {
		log_error("Lua File Error: " + get_lua_error());
	}
}

bool LuaBridge::load_file(String path) {
	if (!L) return false;
	
	if (luaL_dofile(L, path.utf8().get_data()) != LUA_OK) {
		log_error("Lua File Error: " + get_lua_error());
		return false;
	}
	
	// Add to loaded mods list
	String mod_name = path.get_file().get_basename();
	if (!loaded_mods.has(mod_name)) {
		loaded_mods.append(mod_name);
	}
	
	return true;
}

void LuaBridge::reload() {
	if (L) {
		call_on_exit(); // Call exit hooks
		lua_close(L);
	}
	
	L = luaL_newstate();
	if (L) {
		if (sandboxed) {
			setup_safe_environment();
		} else {
			luaL_openlibs(L);
		}
		setup_game_api();
		print_to_console("Lua VM reloaded successfully");
	} else {
		log_error("Failed to reload Lua VM");
	}
}

void LuaBridge::unload() {
	if (L) {
		call_on_exit();
		lua_close(L);
		L = nullptr;
		loaded_mods.clear();
	}
}

void LuaBridge::set_global(String name, Variant value) {
	if (!L) return;
	
	if (value.get_type() == Variant::Type::STRING) {
		lua_pushstring(L, ((String)value).utf8().get_data());
	} else if (value.get_type() == Variant::Type::INT) {
		lua_pushinteger(L, (int)value);
	} else if (value.get_type() == Variant::Type::FLOAT) {
		lua_pushnumber(L, (double)value);
	} else if (value.get_type() == Variant::Type::BOOL) {
		lua_pushboolean(L, (bool)value);
	} else {
		lua_pushnil(L);
	}
	
	lua_setglobal(L, name.utf8().get_data());
}

Variant LuaBridge::get_global(String name) const {
	if (!L) return Variant();
	
	lua_getglobal(L, name.utf8().get_data());
	
	Variant result;
	if (lua_isstring(L, -1)) {
		result = String(lua_tostring(L, -1));
	} else if (lua_isnumber(L, -1)) {
		result = lua_tonumber(L, -1);
	} else if (lua_isboolean(L, -1)) {
		result = (bool)lua_toboolean(L, -1);
	} else {
		result = Variant();
	}
	
	lua_pop(L, 1);
	return result;
}

Variant LuaBridge::call_function(String func_name, Array args) {
	if (!L) return Variant();
	
	return call_lua_function(func_name, args) ? get_global("_return_value") : Variant();
}

void LuaBridge::register_function(String name, Callable cb) {
	// This is a placeholder for registering Godot functions with Lua
	// Implementation would require more complex callback handling
	print_to_console("Function registration not yet implemented: " + name);
}

// Mod management
bool LuaBridge::load_script_from_directory(String mod_dir) {
	Ref<DirAccess> dir = DirAccess::open(mod_dir);
	if (!dir.is_valid()) {
		log_error("Cannot open directory: " + mod_dir);
		return false;
	}
	
	dir->list_dir_begin();
	String file_name = dir->get_next();
	
	while (!file_name.is_empty()) {
		if (file_name.ends_with(".lua")) {
			String full_path = mod_dir.path_join(file_name);
			if (load_file(full_path)) {
				print_to_console("Loaded mod: " + file_name);
			}
		}
		file_name = dir->get_next();
	}
	
	dir->list_dir_end();
	return true;
}

bool LuaBridge::call_event(String event_name, Array args) {
	return call_lua_function(event_name, args);
}

Array LuaBridge::list_loaded_mods() const {
	return loaded_mods;
}

void LuaBridge::unload_mod(String mod_name) {
	if (loaded_mods.has(mod_name)) {
		// Call exit hook for the mod
		call_on_exit();
		loaded_mods.erase(mod_name);
		print_to_console("Unloaded mod: " + mod_name);
	}
}

// JSON mod management
bool LuaBridge::load_mod_from_json(String mod_json_path) {
	if (!FileAccess::file_exists(mod_json_path)) {
		log_error("Mod JSON file not found: " + mod_json_path);
		return false;
	}
	
	Ref<FileAccess> file = FileAccess::open(mod_json_path, FileAccess::READ);
	if (!file.is_valid()) {
		log_error("Cannot open mod JSON file: " + mod_json_path);
		return false;
	}
	
	String json_string = file->get_as_text();
	file->close();
	
	Ref<JSON> json = JSON::new();
	Error parse_result = json->parse(json_string);
	
	if (parse_result != OK) {
		log_error("Failed to parse mod JSON: " + json->get_error_message());
		return false;
	}
	
	Variant mod_data = json->get_data();
	if (mod_data.get_type() != Variant::Type::DICTIONARY) {
		log_error("Mod JSON must be a dictionary");
		return false;
	}
	
	Dictionary mod_dict = (Dictionary)mod_data;
	String mod_name = mod_dict.get("name", "");
	String entry_script = mod_dict.get("entry_script", "");
	String version = mod_dict.get("version", "1.0.0");
	String author = mod_dict.get("author", "");
	String description = mod_dict.get("description", "");
	bool enabled = mod_dict.get("enabled", true);
	
	if (mod_name.is_empty()) {
		log_error("Mod JSON must contain a 'name' field");
		return false;
	}
	
	// Store mod metadata
	Dictionary mod_info;
	mod_info["name"] = mod_name;
	mod_info["version"] = version;
	mod_info["author"] = author;
	mod_info["description"] = description;
	mod_info["entry_script"] = entry_script;
	mod_info["enabled"] = enabled;
	mod_info["json_path"] = mod_json_path;
	
	mod_metadata[mod_name] = mod_info;
	
	// Load the entry script if specified and mod is enabled
	if (!entry_script.is_empty() && enabled) {
		String mod_dir = mod_json_path.get_base_dir();
		String script_path = mod_dir.path_join(entry_script);
		
		if (load_file(script_path)) {
			if (!enabled_mods.has(mod_name)) {
				enabled_mods.append(mod_name);
			}
			print_to_console("Loaded mod: " + mod_name + " v" + version);
			return true;
		} else {
			log_error("Failed to load entry script for mod: " + mod_name);
			return false;
		}
	}
	
	print_to_console("Registered mod: " + mod_name + " v" + String(mod_info["version"]) + " (disabled: " + String(mod_info["enabled"]) + ")");
	return true;
}

bool LuaBridge::load_mods_from_directory(String mods_dir) {
	Ref<DirAccess> dir = DirAccess::open(mods_dir);
	if (!dir.is_valid()) {
		log_error("Cannot open mods directory: " + mods_dir);
		return false;
	}
	
	dir->list_dir_begin();
	String file_name = dir->get_next();
	int loaded_count = 0;
	
	while (!file_name.is_empty()) {
		if (file_name == "." || file_name == "..") {
			file_name = dir->get_next();
			continue;
		}
		
		String full_path = mods_dir.path_join(file_name);
		
		if (dir->current_is_dir()) {
			// Check if this directory contains a mod.json
			String mod_json_path = full_path.path_join("mod.json");
			if (FileAccess::file_exists(mod_json_path)) {
				if (load_mod_from_json(mod_json_path)) {
					loaded_count++;
				}
			}
		} else if (file_name.ends_with(".json")) {
			// Direct JSON file
			if (load_mod_from_json(full_path)) {
				loaded_count++;
			}
		}
		
		file_name = dir->get_next();
	}
	
	dir->list_dir_end();
	print_to_console("Loaded " + String::num_int64(loaded_count) + " mods from directory: " + mods_dir);
	return loaded_count > 0;
}

Dictionary LuaBridge::get_mod_info(String mod_name) const {
	if (mod_metadata.has(mod_name)) {
		return (Dictionary)mod_metadata[mod_name];
	}
	return Dictionary();
}

Array LuaBridge::get_all_mod_info() const {
	Array all_info;
	Array keys = mod_metadata.keys();
	for (int i = 0; i < keys.size(); i++) {
		String key = keys[i];
		Dictionary info = mod_metadata[key];
		all_info.append(info);
	}
	return all_info;
}

bool LuaBridge::is_mod_enabled(String mod_name) const {
	return enabled_mods.has(mod_name);
}

void LuaBridge::enable_mod(String mod_name) {
	if (!mod_metadata.has(mod_name)) {
		log_error("Cannot enable unknown mod: " + mod_name);
		return;
	}
	
	if (enabled_mods.has(mod_name)) {
		print_to_console("Mod already enabled: " + mod_name);
		return;
	}
	
	Dictionary mod_info = (Dictionary)mod_metadata[mod_name];
	String entry_script = mod_info.get("entry_script", "");
	String json_path = mod_info.get("json_path", "");
	
	if (entry_script.is_empty()) {
		log_error("Mod has no entry script: " + mod_name);
		return;
	}
	
	String mod_dir = json_path.get_base_dir();
	String script_path = mod_dir.path_join(entry_script);
	
	if (load_file(script_path)) {
		enabled_mods.append(mod_name);
		mod_info["enabled"] = true;
		mod_metadata[mod_name] = mod_info;
		print_to_console("Enabled mod: " + mod_name);
	} else {
		log_error("Failed to load entry script for mod: " + mod_name);
	}
}

void LuaBridge::disable_mod(String mod_name) {
	if (!enabled_mods.has(mod_name)) {
		print_to_console("Mod not enabled: " + mod_name);
		return;
	}
	
	// Call exit hook before disabling
	call_on_exit();
	
	enabled_mods.erase(mod_name);
	
	if (mod_metadata.has(mod_name)) {
		Dictionary mod_info = (Dictionary)mod_metadata[mod_name];
		mod_info["enabled"] = false;
		mod_metadata[mod_name] = mod_info;
	}
	
	print_to_console("Disabled mod: " + mod_name);
}

// Lifecycle hooks
void LuaBridge::call_on_init() {
	call_lua_function("on_init", Array());
}

void LuaBridge::call_on_ready() {
	call_lua_function("on_ready", Array());
}

void LuaBridge::call_on_update(double delta) {
	Array args;
	args.append(delta);
	call_lua_function("on_update", args);
}

void LuaBridge::call_on_exit() {
	call_lua_function("on_exit", Array());
}

// Security & sandboxing
void LuaBridge::set_sandboxed(bool enabled) {
	sandboxed = enabled;
}

bool LuaBridge::is_sandboxed() const {
	return sandboxed;
}

void LuaBridge::setup_safe_environment() {
	if (!L) return;
	
	// Only load safe libraries
	setup_safe_libraries();
	
	// Remove dangerous functions
	lua_pushnil(L);
	lua_setglobal(L, "os");
	lua_pushnil(L);
	lua_setglobal(L, "io");
	lua_pushnil(L);
	lua_setglobal(L, "package");
	lua_pushnil(L);
	lua_setglobal(L, "loadfile");
	lua_pushnil(L);
	lua_setglobal(L, "dofile");
}

// Utility methods
void LuaBridge::print_to_console(String message) {
	UtilityFunctions::print("[LuaBridge] " + message);
}

void LuaBridge::log_error(String error_message) {
	UtilityFunctions::print("[LuaBridge Error] " + error_message);
}

String LuaBridge::get_last_error() const {
	if (!L) return "";
	
	lua_getglobal(L, "_last_error");
	if (lua_isstring(L, -1)) {
		String error = lua_tostring(L, -1);
		lua_pop(L, 1);
		return error;
	}
	lua_pop(L, 1);
	return "";
}

// Private methods
void LuaBridge::setup_game_api() {
	// Register basic game API functions
	// This is where you'd expose Godot types and methods to Lua
	print_to_console("Game API setup complete");
}

void LuaBridge::setup_safe_libraries() {
	if (!L) return;
	
	// Load only safe libraries
	luaopen_base(L);
	luaopen_table(L);
	luaopen_string(L);
	luaopen_math(L);
	luaopen_utf8(L);
}

void LuaBridge::setup_unsafe_libraries() {
	if (!L) return;
	
	// Load all libraries (unsafe)
	luaL_openlibs(L);
}

String LuaBridge::get_lua_error() {
	if (!L) return "";
	
	const char* error_msg = lua_tostring(L, -1);
	if (error_msg) {
		String error = String(error_msg);
		lua_pop(L, 1);
		
		// Store error for later retrieval
		set_global("_last_error", error);
		return error;
	}
	return "";
}

bool LuaBridge::call_lua_function(String func_name, Array args) {
	if (!L) return false;
	
	// Get the function from global scope
	lua_getglobal(L, func_name.utf8().get_data());
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return false; // Function doesn't exist, not an error
	}
	
	// Push arguments
	for (int i = 0; i < args.size(); i++) {
		Variant arg = args[i];
		if (arg.get_type() == Variant::Type::STRING) {
			lua_pushstring(L, ((String)arg).utf8().get_data());
		} else if (arg.get_type() == Variant::Type::INT) {
			lua_pushinteger(L, (int)arg);
		} else if (arg.get_type() == Variant::Type::FLOAT) {
			lua_pushnumber(L, (double)arg);
		} else if (arg.get_type() == Variant::Type::BOOL) {
			lua_pushboolean(L, (bool)arg);
		} else {
			lua_pushnil(L);
		}
	}
	
	// Call the function
	if (lua_pcall(L, args.size(), 1, 0) != LUA_OK) {
		log_error("Lua Error in " + func_name + ": " + get_lua_error());
		return false;
	}
	
	// Store return value in global for retrieval
	lua_setglobal(L, "_return_value");
	return true;
}