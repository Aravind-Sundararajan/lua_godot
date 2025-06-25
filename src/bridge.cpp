#include "bridge.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/node.hpp>

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
	
	// Type checking and validation
	ClassDB::bind_method(D_METHOD("is_instance", "obj", "class_name"), &LuaBridge::is_instance);
	ClassDB::bind_method(D_METHOD("get_class", "obj"), &LuaBridge::get_class);
	ClassDB::bind_method(D_METHOD("validate_function_args", "func_name", "args"), &LuaBridge::validate_function_args);
	
	// Safe casting wrappers
	ClassDB::bind_method(D_METHOD("create_wrapper", "obj", "class_name"), &LuaBridge::create_wrapper);
	ClassDB::bind_method(D_METHOD("is_wrapper", "obj"), &LuaBridge::is_wrapper);
	ClassDB::bind_method(D_METHOD("unwrap_object", "wrapper"), &LuaBridge::unwrap_object);
	ClassDB::bind_method(D_METHOD("get_wrapper_class", "wrapper"), &LuaBridge::get_wrapper_class);
	ClassDB::bind_method(D_METHOD("is_wrapper_valid", "wrapper"), &LuaBridge::is_wrapper_valid);
	ClassDB::bind_method(D_METHOD("safe_call_method", "wrapper", "method_name", "args"), &LuaBridge::safe_call_method);
	
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
	
	// Signal and property access
	ClassDB::bind_method(D_METHOD("connect_signal", "obj", "signal_name", "lua_func_name"), &LuaBridge::connect_signal);
	ClassDB::bind_method(D_METHOD("get_property", "obj", "property_name"), &LuaBridge::get_property);
	ClassDB::bind_method(D_METHOD("set_property", "obj", "property_name", "value"), &LuaBridge::set_property);
	
	// Scene and resource management
	ClassDB::bind_method(D_METHOD("get_node", "obj", "path"), &LuaBridge::get_node);
	ClassDB::bind_method(D_METHOD("get_children", "obj"), &LuaBridge::get_children);
	ClassDB::bind_method(D_METHOD("load_resource", "path"), &LuaBridge::load_resource);
	ClassDB::bind_method(D_METHOD("instance_scene", "path"), &LuaBridge::instance_scene);

	// Event bus
	ClassDB::bind_method(D_METHOD("emit_event", "name", "data"), &LuaBridge::emit_event);
	ClassDB::bind_method(D_METHOD("subscribe_event", "name", "func"), &LuaBridge::subscribe_event);

	// Error isolation and mod reloading
	ClassDB::bind_method(D_METHOD("reload_mod", "mod_name"), &LuaBridge::reload_mod);

	// Coroutine support
	ClassDB::bind_method(D_METHOD("create_coroutine", "name", "func_name", "args"), &LuaBridge::create_coroutine);
	ClassDB::bind_method(D_METHOD("resume_coroutine", "name", "data"), &LuaBridge::resume_coroutine);
	ClassDB::bind_method(D_METHOD("is_coroutine_active", "name"), &LuaBridge::is_coroutine_active);
	ClassDB::bind_method(D_METHOD("cleanup_coroutines"), &LuaBridge::cleanup_coroutines);
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
		setup_require_handler();
	}
}

LuaBridge::~LuaBridge() {
	if (L) {
		call_on_exit(); // Call exit hooks before cleanup
		cleanup_coroutines(); // Clean up any active coroutines
		lua_close(L);
		L = nullptr;
	}
}

void LuaBridge::setup_require_handler() {
	if (!L) return;
	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, lua_require_mod, 1);
	lua_setglobal(L, "require");
}

int LuaBridge::lua_require_mod(lua_State* L) {
	// Upvalue 1: LuaBridge*
	LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
	if (!bridge) {
		lua_pushstring(L, "[LuaBridge] require: No bridge context");
		lua_error(L);
		return 1;
	}
	const char* modname = luaL_checkstring(L, 1);
	String modfile = "mods/" + String(modname) + ".lua";
	if (!FileAccess::file_exists(modfile)) {
		lua_pushfstring(L, "[LuaBridge] require: Module not found: %s", modfile.utf8().get_data());
		lua_error(L);
		return 1;
	}
	Ref<FileAccess> file = FileAccess::open(modfile, FileAccess::READ);
	String code = file->get_as_text();
	file->close();
	if (luaL_loadstring(L, code.utf8().get_data()) != LUA_OK) {
		lua_pushfstring(L, "[LuaBridge] require: Load error: %s", lua_tostring(L, -1));
		lua_error(L);
		return 1;
	}
	if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
		lua_pushfstring(L, "[LuaBridge] require: Runtime error: %s", lua_tostring(L, -1));
		lua_error(L);
		return 1;
	}
	return 1;
}

String LuaBridge::get_lua_stack_trace() {
	if (!L) return "";
	luaL_traceback(L, L, nullptr, 1);
	if (lua_isstring(L, -1)) {
		String trace = lua_tostring(L, -1);
		lua_pop(L, 1);
		return trace;
	}
	lua_pop(L, 1);
	return "";
}

// Error-isolated exec_string
Variant LuaBridge::exec_string(String code) {
	if (!L) return Variant();
	int result = luaL_loadstring(L, code.utf8().get_data());
	if (result != LUA_OK) {
		log_error("Lua Load Error: " + get_lua_error());
		print_to_console(get_lua_stack_trace());
		return Variant();
	}
	result = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (result != LUA_OK) {
		log_error("Lua Runtime Error: " + get_lua_error());
		print_to_console(get_lua_stack_trace());
		return Variant();
	}
	return get_global("_return_value");
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

// Error-isolated call_function
Variant LuaBridge::call_function(String func_name, Array args) {
	if (!L) return Variant();
	// Validate arguments before calling
	if (!validate_function_args(func_name, args)) {
		print_to_console("Argument validation failed for function: " + func_name);
		return Variant();
	}
	// Push function
	lua_getglobal(L, func_name.utf8().get_data());
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		print_to_console("Function not found: " + func_name);
		return Variant();
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
	// Protected call
	int result = lua_pcall(L, args.size(), 1, 0);
	if (result != LUA_OK) {
		log_error("Lua Error in " + func_name + ": " + get_lua_error());
		print_to_console(get_lua_stack_trace());
		lua_pop(L, 1);
		return Variant();
	}
	// Store return value in global for retrieval
	lua_setglobal(L, "_return_value");
	return get_global("_return_value");
}

void LuaBridge::register_function(String name, Callable cb) {
	if (!L) {
		log_error("Cannot register function: Lua state not initialized");
		return;
	}
	
	if (name.is_empty()) {
		log_error("Cannot register function: Empty function name");
		return;
	}
	
	// Store the callable for later use
	registered_functions[name] = cb;
	
	// Create a closure that captures the bridge instance and function name
	lua_pushlightuserdata(L, this);
	lua_pushstring(L, name.utf8().get_data());
	lua_pushcclosure(L, lua_call_godot_function, 2);
	
	// Register it as a global function
	lua_setglobal(L, name.utf8().get_data());
	
	print_to_console("Registered Godot function: " + name);
}

// Type checking and validation
bool LuaBridge::is_instance(Variant obj, String class_name) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		return false;
	}
	Object *object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		return false;
	}
	return object->is_class(class_name);
}

String LuaBridge::get_class(Variant obj) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		return "Variant";
	}
	Object *object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		return "Invalid Object";
	}
	return object->get_class();
}

bool LuaBridge::validate_function_args(String func_name, Array args) {
	if (!L) return false;
	// Get the function from Lua
	lua_getglobal(L, func_name.utf8().get_data());
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return false;
	}
	// Get function info (number of parameters)
	int num_params = 0;
	if (lua_isfunction(L, -1)) {
		lua_Debug ar;
		if (lua_getinfo(L, ">u", &ar)) {
			num_params = ar.nups;
		}
	}
	lua_pop(L, 1);
	// Basic validation: check if we have the right number of arguments
	if (args.size() != num_params) {
		print_to_console("Function " + func_name + " expects " + String::num_int64(num_params) + " arguments, got " + String::num_int64(args.size()));
		return false;
	}
	return true;
}

// Safe casting wrappers
Variant LuaBridge::create_wrapper(Variant obj, String class_name) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("Cannot create wrapper for non-object type");
		return Variant();
	}
	
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("Invalid object cast");
		return Variant();
	}
	
	// Check if object is actually of the specified class
	if (!object->is_class(class_name)) {
		print_to_console("Object is not of class: " + class_name);
		return Variant();
	}
	
	// Create a wrapper that can be passed to Lua
	// For now, we'll return the object itself with metadata
	// In a full implementation, this would create Lua userdata
	Dictionary wrapper;
	wrapper["_object"] = obj;
	wrapper["_class_name"] = class_name;
	wrapper["_is_wrapper"] = true;
	
	return wrapper;
}

bool LuaBridge::is_wrapper(Variant obj) const {
	if (obj.get_type() != Variant::Type::DICTIONARY) {
		return false;
	}
	
	Dictionary dict = obj;
	return dict.has("_is_wrapper") && dict["_is_wrapper"];
}

Variant LuaBridge::unwrap_object(Variant wrapper) const {
	if (!is_wrapper(wrapper)) {
		print_to_console("Not a valid wrapper");
		return Variant();
	}
	
	Dictionary dict = wrapper;
	return dict.get("_object", Variant());
}

String LuaBridge::get_wrapper_class(Variant wrapper) const {
	if (!is_wrapper(wrapper)) {
		return "Invalid";
	}
	
	Dictionary dict = wrapper;
	return dict.get("_class_name", "Unknown");
}

bool LuaBridge::is_wrapper_valid(Variant wrapper) const {
	if (!is_wrapper(wrapper)) {
		return false;
	}
	
	Variant obj = unwrap_object(wrapper);
	if (obj.get_type() != Variant::Type::OBJECT) {
		return false;
	}
	
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	return object != nullptr;
}

Variant LuaBridge::safe_call_method(Variant wrapper, String method_name, Array args) {
	if (!is_wrapper_valid(wrapper)) {
		print_to_console("Invalid or expired wrapper");
		return Variant();
	}
	
	Variant obj = unwrap_object(wrapper);
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	
	if (!object) {
		print_to_console("Failed to unwrap object");
		return Variant();
	}
	
	// Check if the method exists
	if (!object->has_method(method_name)) {
		print_to_console("Method does not exist: " + method_name);
		return Variant();
	}
	
	// Call the method safely
	try {
		Callable callable(object, method_name);
		return callable.callv(args);
	} catch (...) {
		print_to_console("Exception occurred while calling method: " + method_name);
		return Variant();
	}
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
void LuaBridge::print_to_console(String message) const {
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
	if (!L) return;
	
	// Register wrapper functions to Lua
	lua_register(L, "create_wrapper", [](lua_State* L) -> int {
		// This would need to be implemented with proper Lua C API
		// For now, we'll expose the wrapper methods through the bridge
		return 0;
	});
	
	// Register utility functions
	lua_register(L, "print", [](lua_State* L) -> int {
		const char* msg = lua_tostring(L, 1);
		if (msg) {
			UtilityFunctions::print("[Lua] " + String(msg));
		}
		return 0;
	});
	
	// Register type checking functions
	lua_register(L, "is_instance", [](lua_State* L) -> int {
		// This would need proper implementation
		return 0;
	});
	
	// Register wrapper helper functions
	lua_register(L, "get_class", [](lua_State* L) -> int {
		// This would need proper implementation
		return 0;
	});
	
	print_to_console("Game API setup complete with wrapper support");
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

// Signal and property access
bool LuaBridge::connect_signal(Variant obj, String signal_name, String lua_func_name) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("connect_signal: Not a Godot object");
		return false;
	}
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("connect_signal: Invalid object");
		return false;
	}
	// Create a relay and connect
	Ref<LuaSignalRelay> relay = memnew(LuaSignalRelay);
	relay->setup(this, lua_func_name);
	object->connect(signal_name, Callable(relay.ptr(), StringName("_on_signal")));
	print_to_console("Connected signal '" + signal_name + "' to Lua function '" + lua_func_name + "'");
	return true;
}

Variant LuaBridge::get_property(Variant obj, String property_name) const {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("get_property: Not a Godot object");
		return Variant();
	}
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("get_property: Invalid object");
		return Variant();
	}
	return object->get(property_name);
}

void LuaBridge::set_property(Variant obj, String property_name, Variant value) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("set_property: Not a Godot object");
		return;
	}
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("set_property: Invalid object");
		return;
	}
	object->set(property_name, value);
}

// Scene and resource management
Variant LuaBridge::get_node(Variant obj, String path) const {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("get_node: Not a Godot object");
		return Variant();
	}
	
	Node* node = Object::cast_to<Node>(obj.operator Object*());
	if (!node) {
		print_to_console("get_node: Object is not a Node");
		return Variant();
	}
	
	Node* target_node = node->get_node_or_null(path);
	if (!target_node) {
		print_to_console("get_node: Node not found at path: " + path);
		return Variant();
	}
	
	return target_node;
}

Array LuaBridge::get_children(Variant obj) const {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("get_children: Not a Godot object");
		return Array();
	}
	
	Node* node = Object::cast_to<Node>(obj.operator Object*());
	if (!node) {
		print_to_console("get_children: Object is not a Node");
		return Array();
	}
	
	Array children;
	for (int i = 0; i < node->get_child_count(); i++) {
		children.append(node->get_child(i));
	}
	
	return children;
}

Variant LuaBridge::load_resource(String path) const {
	Ref<Resource> resource = ResourceLoader::get_singleton()->load(path);
	if (!resource.is_valid()) {
		print_to_console("load_resource: Failed to load resource: " + path);
		return Variant();
	}
	
	print_to_console("load_resource: Successfully loaded: " + path);
	return resource;
}

Variant LuaBridge::instance_scene(String path) const {
	// First load the scene resource
	Ref<PackedScene> scene = ResourceLoader::get_singleton()->load(path);
	if (!scene.is_valid()) {
		print_to_console("instance_scene: Failed to load scene: " + path);
		return Variant();
	}
	
	// Then instance it
	Node* instance = scene->instantiate();
	if (!instance) {
		print_to_console("instance_scene: Failed to instantiate scene: " + path);
		return Variant();
	}
	
	print_to_console("instance_scene: Successfully instantiated: " + path);
	return instance;
}

// Event bus
void LuaBridge::emit_event(String name, Variant data) {
	auto it = event_subscribers.find(name);
	if (it == event_subscribers.end()) return;
	for (const String &func : it->second) {
		call_function(func, Array::make(data));
	}
}

void LuaBridge::subscribe_event(String name, String func) {
	event_subscribers[name].push_back(func);
}

// Mod reload
bool LuaBridge::reload_mod(String mod_name) {
	if (!mod_metadata.has(mod_name)) {
		log_error("Cannot reload unknown mod: " + mod_name);
		return false;
	}
	disable_mod(mod_name);
	unload_mod(mod_name);
	return enable_mod(mod_name), true;
}

// Coroutine support
bool LuaBridge::create_coroutine(String name, String func_name, Array args) {
	if (!L) return false;
	
	// Get the function from global scope
	lua_getglobal(L, func_name.utf8().get_data());
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		print_to_console("create_coroutine: Function not found: " + func_name);
		return false;
	}
	
	// Create a new thread (coroutine)
	lua_State* co = lua_newthread(L);
	if (!co) {
		lua_pop(L, 1);
		print_to_console("create_coroutine: Failed to create thread");
		return false;
	}
	
	// Copy the function to the new thread
	lua_xmove(L, co, 1);
	
	// Push arguments to the coroutine
	for (int i = 0; i < args.size(); i++) {
		Variant arg = args[i];
		if (arg.get_type() == Variant::Type::STRING) {
			lua_pushstring(co, ((String)arg).utf8().get_data());
		} else if (arg.get_type() == Variant::Type::INT) {
			lua_pushinteger(co, (int)arg);
		} else if (arg.get_type() == Variant::Type::FLOAT) {
			lua_pushnumber(co, (double)arg);
		} else if (arg.get_type() == Variant::Type::BOOL) {
			lua_pushboolean(co, (bool)arg);
		} else {
			lua_pushnil(co);
		}
	}
	
	// Store the coroutine
	active_coroutines[name] = co;
	
	print_to_console("create_coroutine: Created coroutine '" + name + "' for function '" + func_name + "'");
	return true;
}

bool LuaBridge::resume_coroutine(String name, Variant data) {
	auto it = active_coroutines.find(name);
	if (it == active_coroutines.end()) {
		print_to_console("resume_coroutine: Coroutine not found: " + name);
		return false;
	}
	
	lua_State* co = it->second;
	if (!co) {
		active_coroutines.erase(it);
		print_to_console("resume_coroutine: Invalid coroutine: " + name);
		return false;
	}
	
	// Push the resume data
	if (data.get_type() == Variant::Type::STRING) {
		lua_pushstring(co, ((String)data).utf8().get_data());
	} else if (data.get_type() == Variant::Type::INT) {
		lua_pushinteger(co, (int)data);
	} else if (data.get_type() == Variant::Type::FLOAT) {
		lua_pushnumber(co, (double)data);
	} else if (data.get_type() == Variant::Type::BOOL) {
		lua_pushboolean(co, (bool)data);
	} else {
		lua_pushnil(co);
	}
	
	// Resume the coroutine
	int nresults = 0;
	int result = lua_resume(co, nullptr, 1, &nresults);
	if (result == LUA_YIELD) {
		print_to_console("resume_coroutine: Coroutine '" + name + "' yielded");
		return true;
	} else if (result == LUA_OK) {
		print_to_console("resume_coroutine: Coroutine '" + name + "' completed");
		active_coroutines.erase(it);
		return true;
	} else {
		print_to_console("resume_coroutine: Coroutine '" + name + "' error: " + String(lua_tostring(co, -1)));
		active_coroutines.erase(it);
		return false;
	}
}

bool LuaBridge::is_coroutine_active(String name) const {
	return active_coroutines.find(name) != active_coroutines.end();
}

void LuaBridge::cleanup_coroutines() {
	active_coroutines.clear();
	print_to_console("cleanup_coroutines: Cleared all active coroutines");
}

// Static function to call Godot functions from Lua
int LuaBridge::lua_call_godot_function(lua_State* L) {
	// Upvalue 1: LuaBridge*
	LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
	if (!bridge) {
		lua_pushstring(L, "[LuaBridge] lua_call_godot_function: No bridge context");
		lua_error(L);
		return 0;
	}
	
	// Upvalue 2: function name
	const char* func_name = lua_tostring(L, lua_upvalueindex(2));
	if (!func_name) {
		lua_pushstring(L, "[LuaBridge] lua_call_godot_function: No function name");
		lua_error(L);
		return 0;
	}
	
	String name = String(func_name);
	
	// Find the registered function
	auto it = bridge->registered_functions.find(name);
	if (it == bridge->registered_functions.end()) {
		lua_pushfstring(L, "[LuaBridge] lua_call_godot_function: Function not found: %s", func_name);
		lua_error(L);
		return 0;
	}
	
	Callable& callable = it->second;
	
	// Convert Lua arguments to Godot Array
	Array args;
	int num_args = lua_gettop(L);
	
	for (int i = 1; i <= num_args; i++) {
		if (lua_isstring(L, i)) {
			args.append(String(lua_tostring(L, i)));
		} else if (lua_isnumber(L, i)) {
			args.append(lua_tonumber(L, i));
		} else if (lua_isboolean(L, i)) {
			args.append((bool)lua_toboolean(L, i));
		} else if (lua_isnil(L, i)) {
			args.append(Variant());
		} else {
			// For other types, we'll pass nil for now
			// In a full implementation, you'd want to handle tables, userdata, etc.
			args.append(Variant());
		}
	}
	
	// Call the Godot function
	Variant result;
	try {
		result = callable.callv(args);
	} catch (...) {
		lua_pushfstring(L, "[LuaBridge] lua_call_godot_function: Exception in function: %s", func_name);
		lua_error(L);
		return 0;
	}
	
	// Convert result back to Lua
	if (result.get_type() == Variant::Type::STRING) {
		lua_pushstring(L, ((String)result).utf8().get_data());
	} else if (result.get_type() == Variant::Type::INT) {
		lua_pushinteger(L, (int)result);
	} else if (result.get_type() == Variant::Type::FLOAT) {
		lua_pushnumber(L, (double)result);
	} else if (result.get_type() == Variant::Type::BOOL) {
		lua_pushboolean(L, (bool)result);
	} else {
		lua_pushnil(L);
	}
	
	return 1; // Return one value
}