#include "bridge.h"
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/main_loop.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/resource.hpp>

// Lua includes
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

using namespace godot;

// Forward declarations for static helper functions
static int lua_method_wrapper(lua_State *L);

// Move ResourceUserData struct to file scope
struct ResourceUserData {
	Object* obj_ptr;
	Ref<Resource> resource_ref;
};

// Add size/alignment check
static_assert(sizeof(ResourceUserData) == sizeof(Object*) + sizeof(Ref<Resource>), "ResourceUserData size mismatch");
static_assert(alignof(ResourceUserData) >= alignof(Object*), "ResourceUserData alignment issue with Object*");
static_assert(alignof(ResourceUserData) >= alignof(Ref<Resource>), "ResourceUserData alignment issue with Ref<Resource>");

// Add at the top of the file, after includes
// static std::vector<Ref<Resource>> g_resource_registry;

// Add stack dump function
void dump_lua_stack(lua_State* L) {
	int top = lua_gettop(L);
	UtilityFunctions::print("[LuaBridge] Stack dump - top: " + String::num_int64(top));
	for (int i = 1; i <= top; ++i) {
		int t = lua_type(L, i);
		const char* type_name = lua_typename(L, t);
		UtilityFunctions::print("[LuaBridge] Stack[" + String::num_int64(i) + "]: " + String(type_name));
	}
}


extern "C" int lua_test_return_42(lua_State* L) {
    UtilityFunctions::print("[LuaBridge] lua_test_return_42 called (with Lua C API)");
    lua_pushinteger(L, 42);
    dump_lua_stack(L);
    UtilityFunctions::print("[LuaBridge] About to return from lua_test_return_42");
    return 1;
}

void LuaBridge::_bind_methods() {
	ClassDB::bind_method(D_METHOD("exec_string", "code"), &LuaBridge::exec_string);
	ClassDB::bind_method(D_METHOD("load_file", "path"), &LuaBridge::load_file);
	ClassDB::bind_method(D_METHOD("unload"), &LuaBridge::unload);
	
	ClassDB::bind_method(D_METHOD("set_global", "name", "value"), &LuaBridge::set_global);
	ClassDB::bind_method(D_METHOD("get_global", "name"), &LuaBridge::get_global);
	
	ClassDB::bind_method(D_METHOD("call_function", "func_name", "args"), &LuaBridge::call_function);
	ClassDB::bind_method(D_METHOD("register_function", "name", "cb"), &LuaBridge::register_function);
	
	// Object access
	ClassDB::bind_method(D_METHOD("get_property", "obj", "property_name"), &LuaBridge::get_property);
	ClassDB::bind_method(D_METHOD("set_property", "obj", "property_name", "value"), &LuaBridge::set_property);
	ClassDB::bind_method(D_METHOD("call_method", "obj", "method_name", "args"), &LuaBridge::call_method);
	ClassDB::bind_method(D_METHOD("get_class", "obj"), &LuaBridge::get_class);
	
	// Scene and resource management
	ClassDB::bind_method(D_METHOD("get_node", "obj", "path"), &LuaBridge::get_node);
	ClassDB::bind_method(D_METHOD("get_children", "obj"), &LuaBridge::get_children);
	ClassDB::bind_method(D_METHOD("get_autoload_singleton", "singleton_name"), &LuaBridge::get_autoload_singleton);
	ClassDB::bind_method(D_METHOD("load_resource", "path"), &LuaBridge::load_resource);
	ClassDB::bind_method(D_METHOD("instance_scene", "path"), &LuaBridge::instance_scene);

	// Event bus
	ClassDB::bind_method(D_METHOD("emit_event", "name", "data"), &LuaBridge::emit_event);
	ClassDB::bind_method(D_METHOD("subscribe_event", "name", "func"), &LuaBridge::subscribe_event);

	// Signal connection
	ClassDB::bind_method(D_METHOD("connect_signal", "obj", "signal_name", "lua_func_name"), &LuaBridge::connect_signal);

	// Security & sandboxing
	ClassDB::bind_method(D_METHOD("set_sandboxed", "enabled"), &LuaBridge::set_sandboxed);
	ClassDB::bind_method(D_METHOD("is_sandboxed"), &LuaBridge::is_sandboxed);
	ClassDB::bind_method(D_METHOD("setup_safe_environment"), &LuaBridge::setup_safe_environment);
	
	// Utility methods
	ClassDB::bind_method(D_METHOD("print_to_console", "message"), &LuaBridge::print_to_console);
	ClassDB::bind_method(D_METHOD("log_error", "error_message"), &LuaBridge::log_error);
	ClassDB::bind_method(D_METHOD("get_last_error"), &LuaBridge::get_last_error);
	ClassDB::bind_method(D_METHOD("clear_last_error"), &LuaBridge::clear_last_error);
	
	// Verbose logging control
	ClassDB::bind_method(D_METHOD("set_verbose_logging", "enabled"), &LuaBridge::set_verbose_logging);
	ClassDB::bind_method(D_METHOD("is_verbose_logging"), &LuaBridge::is_verbose_logging);

	// Signals
	ADD_SIGNAL(MethodInfo("lua_error_occurred", PropertyInfo(Variant::STRING, "error_message"), PropertyInfo(Variant::STRING, "error_type"), PropertyInfo(Variant::STRING, "file_path")));

	// Mod management
	ClassDB::bind_method(D_METHOD("load_mods_from_directory", "mods_dir"), &LuaBridge::load_mods_from_directory);
	ClassDB::bind_method(D_METHOD("load_mod_from_json", "mod_json_path"), &LuaBridge::load_mod_from_json);
	ClassDB::bind_method(D_METHOD("enable_mod", "mod_name"), &LuaBridge::enable_mod);
	ClassDB::bind_method(D_METHOD("disable_mod", "mod_name"), &LuaBridge::disable_mod);
	ClassDB::bind_method(D_METHOD("reload_mod", "mod_name"), &LuaBridge::reload_mod);
	ClassDB::bind_method(D_METHOD("get_all_mod_info"), &LuaBridge::get_all_mod_info);
	ClassDB::bind_method(D_METHOD("get_mod_info", "mod_name"), &LuaBridge::get_mod_info);
	ClassDB::bind_method(D_METHOD("is_mod_enabled", "mod_name"), &LuaBridge::is_mod_enabled);

	// Lifecycle hooks
	ClassDB::bind_method(D_METHOD("call_on_init"), &LuaBridge::call_on_init);
	ClassDB::bind_method(D_METHOD("call_on_ready"), &LuaBridge::call_on_ready);
	ClassDB::bind_method(D_METHOD("call_on_update", "delta"), &LuaBridge::call_on_update);
	ClassDB::bind_method(D_METHOD("call_on_exit"), &LuaBridge::call_on_exit);

	// Coroutines
	ClassDB::bind_method(D_METHOD("create_coroutine", "name", "func_name", "args"), &LuaBridge::create_coroutine);
	ClassDB::bind_method(D_METHOD("resume_coroutine", "name", "data"), &LuaBridge::resume_coroutine);
	ClassDB::bind_method(D_METHOD("is_coroutine_active", "name"), &LuaBridge::is_coroutine_active);
	ClassDB::bind_method(D_METHOD("cleanup_coroutines"), &LuaBridge::cleanup_coroutines);

	// Object wrappers
	ClassDB::bind_method(D_METHOD("create_wrapper", "obj", "class_name"), &LuaBridge::create_wrapper);
	ClassDB::bind_method(D_METHOD("is_wrapper", "obj"), &LuaBridge::is_wrapper);
	ClassDB::bind_method(D_METHOD("unwrap_object", "wrapper"), &LuaBridge::unwrap_object);
	ClassDB::bind_method(D_METHOD("get_wrapper_class", "wrapper"), &LuaBridge::get_wrapper_class);
	ClassDB::bind_method(D_METHOD("is_wrapper_valid", "wrapper"), &LuaBridge::is_wrapper_valid);
	ClassDB::bind_method(D_METHOD("safe_call_method", "wrapper", "method_name", "args"), &LuaBridge::safe_call_method);

	// Instance checking
	ClassDB::bind_method(D_METHOD("is_instance", "obj", "class_name"), &LuaBridge::is_instance);

	// Class instantiation
	ClassDB::bind_method(D_METHOD("create_instance", "class_name", "args"), &LuaBridge::create_instance, DEFVAL(Array()));
	ClassDB::bind_method(D_METHOD("can_instantiate_class", "class_name"), &LuaBridge::can_instantiate_class);
	ClassDB::bind_method(D_METHOD("get_instantiable_classes"), &LuaBridge::get_instantiable_classes);
}

LuaBridge::LuaBridge() {
	L = luaL_newstate();
	if (L) {
		if (sandboxed) {
			setup_safe_environment();
		} else {
			luaL_openlibs(L);
		}
		setup_godot_object_metatable();
		setup_game_api();
		setup_require_handler();

		// In the LuaBridge initialization, after setting up the Lua state, register the function:
		lua_register(L, "test_return_42", lua_test_return_42);
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Registered test_return_42");
		}

		// In LuaBridge constructor, after initializing L:
		lua_pushlightuserdata(L, this);
		lua_setfield(L, LUA_REGISTRYINDEX, "godot_lua_bridge_ptr");
	}
}

LuaBridge::LuaBridge(bool verbose) : verbose_logging(verbose) {
	L = luaL_newstate();
	if (L) {
		if (sandboxed) {
			setup_safe_environment();
		} else {
			luaL_openlibs(L);
		}
		setup_godot_object_metatable();
		setup_game_api();
		setup_require_handler();

		// In the LuaBridge initialization, after setting up the Lua state, register the function:
		lua_register(L, "test_return_42", lua_test_return_42);
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Registered test_return_42");
		}

		// In LuaBridge constructor, after initializing L:
		lua_pushlightuserdata(L, this);
		lua_setfield(L, LUA_REGISTRYINDEX, "godot_lua_bridge_ptr");
	}
}

LuaBridge::~LuaBridge() {
	if (L) {
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Destructor called, cleaning up...");
		}
		
		// Set cleanup flag to prevent __gc from accessing bridge during cleanup
		is_cleaning_up = true;
		
		// Clear all global references first to prevent use-after-free
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Clearing global references...");
		}
		
		// Clear event subscribers to prevent callbacks after cleanup
		event_subscribers.clear();
		
		// Clear coroutines to prevent them from running after cleanup
		coroutine_active.clear();
		
		// Clear wrapper objects map to prevent cleanup issues
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Clearing wrapper objects map...");
		}
		wrapper_objects.clear();
		object_wrappers.clear();
		
		// Force garbage collection to clean up all wrapped objects
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Running garbage collection...");
		}
		lua_gc(L, LUA_GCCOLLECT, 0);
		
		// Wait a moment for GC to complete
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Garbage collection completed");
		}
		
		// NOW clear the registry pointer after GC is complete
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Clearing registry pointer...");
		}
		lua_pushnil(L);
		lua_setfield(L, LUA_REGISTRYINDEX, "godot_lua_bridge_ptr");
		
		// Close the Lua state
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Closing Lua state...");
		}
		lua_close(L);
		L = nullptr;
		
		if (verbose_logging) {
			UtilityFunctions::print("[LuaBridge] Destructor cleanup completed");
		}
	}
}

void LuaBridge::setup_require_handler() {
	if (!L) return;
	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, lua_require_mod, 1);
	lua_setglobal(L, "require");
}

int LuaBridge::lua_require_mod(lua_State* L) {
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
		// String error_msg = "Lua Runtime Error: " + get_lua_error();
		// log_error(error_msg);
		return 1;
	}
	return 1;
}

int LuaBridge::lua_class_constructor(lua_State* L) {
	LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
	if (!bridge) {
		lua_pushstring(L, "[LuaBridge] lua_class_constructor: No bridge context");
		lua_error(L);
		return 0;
	}
	
	const char* class_name = lua_tostring(L, lua_upvalueindex(2));
	if (!class_name) {
		lua_pushstring(L, "[LuaBridge] lua_class_constructor: No class name");
		lua_error(L);
		return 0;
	}
	
	String name = String(class_name);
	
	// Convert Lua arguments to Godot Array
	Array args;
	int num_args = lua_gettop(L);
	
	for (int i = 1; i <= num_args; i++) {
		Variant arg = bridge->lua_to_godot(L, i);
		args.append(arg);
	}
	
	// Create the instance
	Variant instance = bridge->create_instance(name, args);
	
	// Convert back to Lua
	bridge->godot_to_lua(L, instance);
	
	return 1;
}

Variant LuaBridge::exec_string(String code) {
	if (!L) return Variant();
	if (is_cleaning_up) return Variant();
	
	int result = luaL_loadstring(L, code.utf8().get_data());
	if (result != LUA_OK) {
		String error_msg = "Lua Load Error: " + get_lua_error();
		log_lua_error(error_msg, "syntax", "");
		return Variant();
	}
	result = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (result != LUA_OK) {
		String error_msg = "Lua Runtime Error: " + get_lua_error();
		log_lua_error(error_msg, "runtime", "");
		return Variant();
	}
	return get_global("_return_value");
}

bool LuaBridge::load_file(String path) {
	if (!L) return false;
	if (is_cleaning_up) return false;

	String resolved_path = path;
	if (path.begins_with("res://")) {
		resolved_path = ProjectSettings::get_singleton()->globalize_path(path);
	} else if (path.begins_with("user://")) {
		resolved_path = ProjectSettings::get_singleton()->globalize_path(path);
	}

	if (!FileAccess::file_exists(resolved_path)) {
		String error_msg = "Lua file not found: " + resolved_path;
		log_lua_error(error_msg, "file_not_found", path);
		return false;
	}

	// Try to load the file with better error handling
	int result = luaL_dofile(L, resolved_path.utf8().get_data());
	if (result != LUA_OK) {
		String error_msg = "Lua File Error in " + path + ": " + get_lua_error();
		log_lua_error(error_msg, "file_error", path);
		return false;
	}

	return true;
}

void LuaBridge::unload() {
	if (L) {
		UtilityFunctions::print("[LuaBridge] Unload called, cleaning up...");
		
		// Set cleanup flag to prevent __gc from accessing bridge during cleanup
		is_cleaning_up = true;
		
		// Clear wrapper objects map first to prevent cleanup issues
		UtilityFunctions::print("[LuaBridge] Clearing wrapper objects map...");
		wrapper_objects.clear();
		object_wrappers.clear();
		
		// Clear event subscribers and coroutines
		event_subscribers.clear();
		coroutine_active.clear();
		
		// Force garbage collection to clean up all wrapped objects
		UtilityFunctions::print("[LuaBridge] Running garbage collection...");
		lua_gc(L, LUA_GCCOLLECT, 0);
		
		// NOW clear the registry pointer after GC is complete
		lua_pushnil(L);
		lua_setfield(L, LUA_REGISTRYINDEX, "godot_lua_bridge_ptr");
		
		// Close the Lua state
		UtilityFunctions::print("[LuaBridge] Closing Lua state...");
		lua_close(L);
		L = nullptr;
		UtilityFunctions::print("[LuaBridge] Unload completed");
	}
}

void LuaBridge::set_global(String name, Variant value) {
	if (!L) return;
	if (is_cleaning_up) return;
	
	godot_to_lua(L, value);
	lua_setglobal(L, name.utf8().get_data());
}

Variant LuaBridge::get_global(String name) const {
	if (!L) return Variant();
	if (is_cleaning_up) return Variant();
	
	lua_getglobal(L, name.utf8().get_data());
	Variant result = lua_to_godot(L, -1);
	lua_pop(L, 1);
	return result;
}

Variant LuaBridge::call_function(String func_name, Array args) {
	if (!L) return Variant();
	if (is_cleaning_up) return Variant();
	
	// Split function name by dots to handle nested calls
	PackedStringArray parts = func_name.split(".");
	if (parts.size() == 0) {
		log_error("Empty function name");
		return Variant();
	}
	
	// Get the base object
	lua_getglobal(L, parts[0].utf8().get_data());
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);
		log_error("Function not found: " + func_name);
		return Variant();
	}
	
	// Navigate through nested tables
	for (int i = 1; i < parts.size() - 1; i++) {
		if (!lua_istable(L, -1)) {
			lua_pop(L, 1);
			log_error("Not a table: " + parts[i]);
			return Variant();
		}
		lua_getfield(L, -1, parts[i].utf8().get_data());
		lua_remove(L, -2); // Remove the previous table
		if (lua_isnil(L, -1)) {
			lua_pop(L, 1);
			log_error("Field not found: " + parts[i]);
			return Variant();
		}
	}
	
	// Get the final function
	if (parts.size() > 1) {
		if (!lua_istable(L, -1)) {
			lua_pop(L, 1);
			log_error("Not a table: " + parts[parts.size() - 2]);
			return Variant();
		}
		lua_getfield(L, -1, parts[parts.size() - 1].utf8().get_data());
		lua_remove(L, -2); // Remove the table
	}
	
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		log_error("Not a function: " + func_name);
		return Variant();
	}

	// Push arguments
	for (int i = 0; i < args.size(); i++) {
		godot_to_lua(L, args[i]);
	}

	// Call function with error handling
	int result = lua_pcall(L, args.size(), 1, 0);
	if (result != LUA_OK) {
		String error_msg = "Lua Error in " + func_name + ": " + get_lua_error();
		log_lua_error(error_msg, "function_call", "");
		lua_pop(L, 1);
		return Variant();
	}

	// Get return value
	Variant return_value = lua_to_godot(L, -1);
	lua_pop(L, 1);
	return return_value;
}

void LuaBridge::register_function(String name, Callable cb) {
	if (!L) {
		// log_error("Cannot register function: Lua state not initialized");
		return;
	}
	
	registered_functions[name] = cb;
	
	lua_pushlightuserdata(L, this);
	lua_pushstring(L, name.utf8().get_data());
	lua_pushcclosure(L, lua_call_godot_function, 2);
	lua_setglobal(L, name.utf8().get_data());
	
	print_to_console("Registered Godot function: " + name);
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

Variant LuaBridge::call_method(Variant obj, String method_name, Array args) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("call_method: Not a Godot object");
		return Variant();
	}
	
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("call_method: Invalid object");
		return Variant();
	}
	
	if (!object->has_method(method_name)) {
		print_to_console("Method does not exist: " + method_name);
		return Variant();
	}
	
	Callable callable(object, method_name);
	return callable.callv(args);
}

String LuaBridge::get_class(Variant obj) const {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("get_class: Not a Godot object");
		return "";
	}
	
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		print_to_console("get_class: Invalid object");
		return "";
	}
	
	// Get the actual class name from the script if available
	String class_name = object->get_class();
	Script *script = Object::cast_to<Script>(object->get_script());
	if (script) {
		class_name = script->get_global_name();
		if (class_name.is_empty()) {
			// Fallback to script class name
			class_name = script->get_class();
		}
	}
	
	return class_name;
}

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

Variant LuaBridge::get_autoload_singleton(String singleton_name) const {
	// Get the main loop and cast to SceneTree
	MainLoop *main_loop = Engine::get_singleton()->get_main_loop();
	SceneTree *scene_tree = Object::cast_to<SceneTree>(main_loop);
	if (!scene_tree) {
		print_to_console("get_autoload_singleton: SceneTree not available");
		return Variant();
	}

	// Get the root window node
	Window *root = scene_tree->get_root();
	if (!root) {
		print_to_console("get_autoload_singleton: No root window node available");
		return Variant();
	}

	// Look for the autoload singleton as a child of the root
	Node *singleton = root->get_node_or_null(NodePath(singleton_name));
	if (singleton) {
		print_to_console("get_autoload_singleton: Found singleton: " + singleton_name);
		return Variant(singleton);
	}

	print_to_console("get_autoload_singleton: Singleton not found: " + singleton_name);
	return Variant();
}


Variant LuaBridge::load_resource(String path) const {
	// Handle mod:// protocol for mod assets
	if (path.begins_with("mod://")) {
		// Extract mod name and asset path from mod://mod_name/path/to/asset
		String mod_path = path.substr(6); // Remove "mod://"
		int slash_pos = mod_path.find("/");
		if (slash_pos == -1) {
			print_to_console("load_resource: Invalid mod path format: " + path);
			return Variant();
		}
		
		String mod_name = mod_path.substr(0, slash_pos);
		String asset_path = mod_path.substr(slash_pos + 1);
		
		// Find the mod directory
		auto mod_it = loaded_mods.find(mod_name);
		if (mod_it == loaded_mods.end()) {
			print_to_console("load_resource: Mod not found: " + mod_name);
			return Variant();
		}
		
		Dictionary mod_info = mod_it->second;
		String mod_dir = mod_info.get("mod_dir", "");
		if (mod_dir.is_empty()) {
			print_to_console("load_resource: Mod directory not found for: " + mod_name);
			return Variant();
		}
		
		// Ensure mod_dir is a resource path
		if (!mod_dir.begins_with("res://") && !mod_dir.begins_with("user://")) {
			mod_dir = "res://" + mod_dir.trim_prefix("./").trim_prefix("/");
		}
		
		// Normalize path components to avoid double slashes and path issues
		String normalized_dir = mod_dir.trim_suffix("/");
		String normalized_asset = asset_path.trim_prefix("/");
		String full_path = normalized_dir + "/" + normalized_asset;
		full_path = full_path.simplify_path();
		
		// Debug: Print all path components
		print_to_console("load_resource: mod_name: " + mod_name);
		print_to_console("load_resource: mod_dir: " + mod_dir);
		print_to_console("load_resource: asset_path: " + asset_path);
		print_to_console("load_resource: full_path: " + full_path);
		
		// Check if file exists before attempting to load
		if (!FileAccess::file_exists(full_path)) {
			print_to_console("load_resource: File does not exist: " + full_path);
			return Variant();
		}
		
		// Load the resource
		Ref<Resource> resource = ResourceLoader::get_singleton()->load(full_path);
		if (!resource.is_valid()) {
			print_to_console("load_resource: Failed to load mod resource: " + full_path);
			return Variant();
		}
		
		print_to_console("load_resource: Successfully loaded mod resource: " + full_path);
		return resource;
	}
	
	// Handle standard res:// paths for base game assets
	Ref<Resource> resource = ResourceLoader::get_singleton()->load(path);
	if (!resource.is_valid()) {
		print_to_console("load_resource: Failed to load resource: " + path);
		return Variant();
	}
	
	return resource;
}

Variant LuaBridge::instance_scene(String path) const {
	Ref<PackedScene> scene = ResourceLoader::get_singleton()->load(path);
	if (!scene.is_valid()) {
		print_to_console("instance_scene: Failed to load scene: " + path);
		return Variant();
	}
	
	Node* instance = scene->instantiate();
	if (!instance) {
		print_to_console("instance_scene: Failed to instantiate scene: " + path);
		return Variant();
	}
	
	return instance;
}

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
	
	Ref<LuaSignalRelay> relay = memnew(LuaSignalRelay);
	relay->setup(this, lua_func_name);
	object->connect(signal_name, Callable(relay.ptr(), StringName("_on_signal")));
	print_to_console("Connected signal '" + signal_name + "' to Lua function '" + lua_func_name + "'");
	return true;
}

void LuaBridge::set_sandboxed(bool enabled) {
	sandboxed = enabled;
}

bool LuaBridge::is_sandboxed() const {
	return sandboxed;
}

void LuaBridge::setup_safe_environment() {
	if (!L) return;
	
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

void LuaBridge::print_to_console(String message) const {
	UtilityFunctions::print("[LuaBridge] " + message);
}

void LuaBridge::log_error(String error_message) {
	UtilityFunctions::print("[LuaBridge Error] " + error_message);
	last_error = error_message;
	
	// Emit signal for error handling
	emit_signal("lua_error_occurred", error_message, "general", "");
}

void LuaBridge::log_lua_error(String error_message, String error_type, String file_path) {
	// Print error in red using ANSI escape codes
	UtilityFunctions::print("\033[31m[LuaBridge " + error_type + " Error] " + error_message + "\033[0m");
	if (!file_path.is_empty()) {
		UtilityFunctions::print("\033[31m[LuaBridge] File: " + file_path + "\033[0m");
	}
	last_error = error_message;
	
	// Emit signal for error handling
	emit_signal("lua_error_occurred", error_message, error_type, file_path);
}

String LuaBridge::get_last_error() const {
	return last_error;
}

void LuaBridge::clear_last_error() {
	last_error = "";
}

void LuaBridge::setup_game_api() {
	if (!L) return;

	// Register a print function that forwards to GDScript lua_print if available
	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, [](lua_State* L) -> int {
		LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
		Array args;
		int nargs = lua_gettop(L);
		
		// Debug: Log that the C++ print function was called
		UtilityFunctions::print("[LuaBridge] C++ print function called with " + String::num_int64(nargs) + " args");
		
		for (int i = 1; i <= nargs; ++i) {
			switch (lua_type(L, i)) {
				case LUA_TSTRING:
					args.append(String(lua_tostring(L, i)));
					break;
				case LUA_TNUMBER:
					args.append(lua_tonumber(L, i));
					break;
				case LUA_TBOOLEAN:
					args.append(lua_toboolean(L, i) != 0);
					break;
				default:
					args.append("[non-printable]");
					break;
			}
		}

		// Try to call the registered GDScript lua_print function
		auto it = bridge->registered_functions.find("print");
		if (it != bridge->registered_functions.end()) {
			UtilityFunctions::print("[LuaBridge] Found registered print function, calling GDScript...");
			it->second.callv(args);
		} else {
			// fallback: print from C++
			UtilityFunctions::print("[LuaBridge] No registered print function found, using C++ fallback");
			String joined;
			for (int i = 0; i < args.size(); i++) {
				joined += args[i].operator String();
				if (i < args.size() - 1)
					joined += " ";
			}
			UtilityFunctions::print("[Lua] " + joined);
		}
		return 0;
	}, 1);
	lua_setglobal(L, "print");
	
	// Debug: Confirm print function was installed
	UtilityFunctions::print("[LuaBridge] print() override installed in setup_game_api()");

	// Expose Resource-derived classes for direct instantiation
	expose_classes_to_lua();

	print_to_console("Game API setup complete");
}

void LuaBridge::setup_safe_libraries() {
	if (!L) return;
	
	luaopen_base(L);
	luaopen_table(L);
	luaopen_string(L);
	luaopen_math(L);
	luaopen_utf8(L);
	luaopen_coroutine(L);
}

String LuaBridge::get_lua_error() {
	if (!L) return "";
	
	const char* error_msg = lua_tostring(L, -1);
	if (error_msg) {
		String error = String(error_msg);
		lua_pop(L, 1);
		return error;
	}
	return "";
}

bool LuaBridge::call_lua_function(String func_name, Array args) {
	if (!L) return false;
	
	lua_getglobal(L, func_name.utf8().get_data());
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		return false;
	}
	
	for (int i = 0; i < args.size(); i++) {
		godot_to_lua(L, args[i]);
	}
	
	if (lua_pcall(L, args.size(), 1, 0) != LUA_OK) {
		String error_msg = "Lua Error in " + func_name + ": " + get_lua_error();
		log_error(error_msg);
		lua_pop(L, 1);
		return false;
	}
	
	lua_pop(L, 1);
	return true;
}

void LuaBridge::godot_to_lua(lua_State* L, const Variant& value) {
	switch (value.get_type()) {
		case Variant::Type::STRING:
			lua_pushstring(L, ((String)value).utf8().get_data());
			break;
		case Variant::Type::INT:
			lua_pushinteger(L, (int)value);
			break;
		case Variant::Type::FLOAT:
			lua_pushnumber(L, (double)value);
			break;
		case Variant::Type::BOOL:
			lua_pushboolean(L, (bool)value);
			break;
		case Variant::Type::ARRAY:
			{
				Array arr = value;
				lua_newtable(L);
				for (int i = 0; i < arr.size(); i++) {
					lua_pushinteger(L, i + 1);
					godot_to_lua(L, arr[i]);
					lua_settable(L, -3);
				}
			}
			break;
		case Variant::Type::DICTIONARY:
			{
				Dictionary dict = value;
				lua_newtable(L);
				
				// Get all keys and values
				Array keys = dict.keys();
				Array values = dict.values();
				
				for (int i = 0; i < keys.size(); i++) {
					Variant key = keys[i];
					Variant val = values[i];
					
					// Push the key
					push_variant_to_lua(L, key);
					
					// Push the value
					push_variant_to_lua(L, val);
					
					// Set the key-value pair in the table
					lua_settable(L, -3);
				}
			}
			break;
		case Variant::Type::OBJECT:
			{
				Object* obj = Object::cast_to<Object>(value.operator Object*());
				if (obj) {
					this->push_godot_object_as_userdata(L, obj);
				} else {
					lua_pushnil(L);
				}
			}
			break;
		default:
			lua_pushnil(L);
			break;
	}
}

Variant LuaBridge::lua_to_godot(lua_State* L, int index) const {
	// Convert negative index to absolute index
	int abs_index = index;
	if (index < 0) {
		abs_index = lua_gettop(L) + index + 1;
	}
	
	// Add safety check for valid absolute index
	if (abs_index < 1 || abs_index > lua_gettop(L)) {
		UtilityFunctions::print("[LuaBridge] lua_to_godot: Invalid index " + String::num_int64(index) + " (abs: " + String::num_int64(abs_index) + ")");
		return Variant();
	}
	
	if (lua_isstring(L, abs_index)) {
		return String(lua_tostring(L, abs_index));
	} else if (lua_isnumber(L, abs_index)) {
		// Check if it's an integer first
		if (lua_isinteger(L, abs_index)) {
			return (int64_t)lua_tointeger(L, abs_index);
		} else {
			return lua_tonumber(L, abs_index);
		}
	} else if (lua_isboolean(L, abs_index)) {
		return (bool)lua_toboolean(L, abs_index);
	} else if (lua_istable(L, abs_index)) {
		// Handle Lua tables - convert to either Array or Dictionary
		Array arr;
		Dictionary dict;
		
		try {
			// First, try to determine if it's an array by checking sequential numeric keys
			bool is_array = true;
			int max_index = 0;
			
			// First pass: check if it's a sequential array
			lua_pushnil(L);
			while (lua_next(L, abs_index)) {
				// Check if key is a number
				if (lua_type(L, -2) == LUA_TNUMBER) {
					int key = (int)lua_tonumber(L, -2);
					if (key > 0 && key <= 1000) { // Reasonable array size limit
						max_index = (key > max_index) ? key : max_index;
					} else {
						is_array = false;
						lua_pop(L, 2); // pop key and value
						break;
					}
				} else {
					is_array = false;
					lua_pop(L, 2); // pop key and value
					break;
				}
				lua_pop(L, 1); // pop value, keep key for next iteration
			}
			
			// If it's an array, populate it
			if (is_array && max_index > 0) {
				for (int i = 1; i <= max_index; i++) {
					lua_rawgeti(L, abs_index, i);
					if (lua_isnil(L, -1)) {
						arr.append(Variant()); // nil becomes null
					} else {
						Variant value = lua_to_godot(L, -1);
						arr.append(value);
					}
					lua_pop(L, 1);
				}
				return arr;
			} else {
				// Convert to dictionary - iterate through all key-value pairs
				int pair_count = 0;
				const int MAX_PAIRS = 1000;
				
				lua_pushnil(L);
				while (lua_next(L, abs_index)) {
					if (pair_count++ > MAX_PAIRS) {
						UtilityFunctions::print("[LuaBridge] lua_to_godot: Dictionary too large, stopping at " + String::num_int64(MAX_PAIRS) + " pairs");
						lua_pop(L, 2); // pop key and value
						break;
					}
					
					// Convert key
					Variant key;
					if (lua_type(L, -2) == LUA_TSTRING) {
						key = String(lua_tostring(L, -2));
					} else if (lua_type(L, -2) == LUA_TNUMBER) {
						key = String::num_int64((int)lua_tonumber(L, -2));
					} else {
						key = String::num_int64(pair_count); // fallback
					}
					
					// Convert value
					Variant value;
					if (lua_isnil(L, -1)) {
						value = Variant();
					} else {
						value = lua_to_godot(L, -1);
					}
					
					dict[key] = value;
					lua_pop(L, 1); // pop value, keep key for next iteration
				}
				return dict;
			}
		} catch (...) {
			UtilityFunctions::print("[LuaBridge] lua_to_godot: Exception occurred while converting table, returning empty dictionary");
			return Dictionary();
		}
	} else if (lua_isuserdata(L, abs_index)) {
		// Handle userdata (wrapped objects)
		void* userdata_ptr = lua_touserdata(L, abs_index);
		Variant wrapper_key = Variant((int64_t)userdata_ptr);
		
		// Look up the actual object in the wrapper_objects map
		auto it = this->wrapper_objects.find(wrapper_key);
		if (it != this->wrapper_objects.end()) {
			UtilityFunctions::print("[LuaBridge] Found wrapped object for key: " + String::num_int64((int64_t)userdata_ptr));
			return it->second;
		} else {
			UtilityFunctions::print("[LuaBridge] No wrapped object found for key: " + String::num_int64((int64_t)userdata_ptr));
			return Variant();  // Return nil if not found
		}
	} else if (lua_isnil(L, abs_index)) {
		return Variant();
	} else {
		// For unsupported types, return null
		UtilityFunctions::print("[LuaBridge] lua_to_godot: Unsupported type at index " + String::num_int64(index));
		return Variant();
	}
}

int LuaBridge::lua_call_godot_function(lua_State* L) {
	LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
	if (!bridge) {
		lua_pushnil(L);
		return 1;
	}
	
	const char* func_name = lua_tostring(L, lua_upvalueindex(2));
	if (!func_name) {
		lua_pushnil(L);
		return 1;
	}
	
	String name = String(func_name);
	
	// Debug: Log function call and stack state
	UtilityFunctions::print("[LuaBridge] lua_call_godot_function called for: " + name);
	UtilityFunctions::print("[LuaBridge] Stack top at function entry: " + String::num_int64(lua_gettop(L)));
	
	// Debug: Log when the dictionary function is called
	if (name == "lua_base_item_factory") {
		UtilityFunctions::print("[LuaBridge] lua_call_godot_function: Dictionary function called!");
	}
	
	auto it = bridge->registered_functions.find(name);
	if (it == bridge->registered_functions.end()) {
		lua_pushfstring(L, "[LuaBridge] lua_call_godot_function: Function not found: %s", func_name);
		lua_error(L);
		return 0;
	}
	
	Callable& callable = it->second;
	
	// Convert Lua arguments to Godot Array
	Array args = bridge->lua_to_variant_array(L);
	
	UtilityFunctions::print("[LuaBridge] About to call Godot function: " + name);
	UtilityFunctions::print("[LuaBridge] Arguments array size: " + String::num_int64(args.size()));
	for (int i = 0; i < args.size(); i++) {
		UtilityFunctions::print("[LuaBridge] Arg " + String::num_int64(i) + ": " + String(args[i]) + " (type: " + String::num_int64(args[i].get_type()) + ")");
	}
	
	// Call the Godot function
	Variant result = callable.callv(args);
	
	UtilityFunctions::print("[LuaBridge] Godot function call completed");
	UtilityFunctions::print("[LuaBridge] Result type: " + String::num_int64(result.get_type()));

	if (result.get_type() == Variant::OBJECT) {
		Object *obj = result.operator Object *();
		if (obj) {
			// Debug the object being returned
			UtilityFunctions::print("[LuaBridge] get_class(): " + obj->get_class());  // will be "Resource"

			Ref<Script> attached_script = obj->get_script();
			UtilityFunctions::print("Resource script attached: " + String(!attached_script.is_null() ? "true" : "false"));

			if (!attached_script.is_null()) {
				UtilityFunctions::print("Script class: " + attached_script->get_class());
				UtilityFunctions::print("Script has methods: " + String::num_int64(attached_script->get_script_method_list().size()));
			}
			
			bridge->push_godot_object_as_userdata(L, obj);
			return 1;
		}
		lua_pushnil(L);
		return 1;
	}
	bridge->push_variant_to_lua(L, result);
	return 1;
}

bool LuaBridge::load_mods_from_directory(String mods_dir) {
	if (!L) return false;
	
	print_to_console("Loading mods from directory: " + mods_dir);
	
	// Get the directory access
	Ref<DirAccess> dir = DirAccess::open(mods_dir);
	if (!dir.is_valid()) {
		String error_msg = "Failed to open mods directory: " + mods_dir;
		log_error(error_msg);
		return false;
	}
	
	// List all subdirectories (each should be a mod)
	dir->list_dir_begin();
	String filename = dir->get_next();
	
	while (!filename.is_empty()) {
		if (filename != "." && filename != ".." && dir->current_is_dir()) {
			String mod_path = mods_dir.path_join(filename);
			String mod_json_path = mod_path.path_join("mod.json");
			
			print_to_console("Checking for mod.json in: " + mod_json_path);
			
			// Check if mod.json exists
			if (FileAccess::file_exists(mod_json_path)) {
				print_to_console("Found mod.json: " + mod_json_path);
				
				// Load the mod
				if (load_mod_from_json(mod_json_path)) {
					print_to_console("Successfully loaded mod from: " + mod_json_path);
				} else {
					print_to_console("Failed to load mod from: " + mod_json_path);
				}
			} else {
				print_to_console("No mod.json found in: " + mod_path);
			}
		}
		
		filename = dir->get_next();
	}
	
	dir->list_dir_end();
	
	print_to_console("Mod loading completed. Loaded " + String::num_int64(loaded_mods.size()) + " mods");
	return true;
}

bool LuaBridge::load_mod_from_json(String mod_json_path) {
	if (!L) return false;
	
	print_to_console("Loading mod from JSON: " + mod_json_path);
	
	// Read the JSON file
	Ref<FileAccess> file = FileAccess::open(mod_json_path, FileAccess::READ);
	if (!file.is_valid()) {
		String error_msg = "Failed to open mod JSON file: " + mod_json_path;
		log_error(error_msg);
		return false;
	}
	
	// Try to read as text with better error handling
	String json_text;
	try {
		json_text = file->get_as_text();
	} catch (...) {
		String error_msg = "Failed to read mod JSON file as text (encoding issue): " + mod_json_path;
		log_error(error_msg);
		file->close();
		return false;
	}
	file->close();
	
	// Check if the text is empty or contains invalid characters
	if (json_text.is_empty()) {
		String error_msg = "Mod JSON file is empty: " + mod_json_path;
		log_error(error_msg);
		return false;
	}
	
	// Parse JSON using Godot's built-in JSON functionality
	Variant mod_data = JSON::parse_string(json_text);
	
	if (mod_data.get_type() == Variant::Type::NIL) {
		String error_msg = "Failed to parse mod JSON: " + mod_json_path;
		log_error(error_msg);
		return false;
	}
	
	if (mod_data.get_type() != Variant::Type::DICTIONARY) {
		String error_msg = "Mod JSON must be a dictionary";
		log_error(error_msg);
		return false;
	}
	
	Dictionary mod_dict = mod_data;
	
	// Extract mod information
	String mod_name = mod_dict.get("name", "");
	String version = mod_dict.get("version", "");
	String author = mod_dict.get("author", "");
	String description = mod_dict.get("description", "");
	String entry_script = mod_dict.get("entry_script", "");
	bool enabled = mod_dict.get("enabled", true);
	int priority = mod_dict.get("priority", 0);
	
	if (mod_name.is_empty()) {
		String error_msg = "Mod JSON missing required 'name' field";
		log_error(error_msg);
		return false;
	}
	
	print_to_console("Mod info - Name: " + mod_name + ", Version: " + version + ", Enabled: " + (enabled ? "true" : "false"));
	
	// Store mod information
	Dictionary mod_info;
	mod_info["name"] = mod_name;
	mod_info["version"] = version;
	mod_info["author"] = author;
	mod_info["description"] = description;
	mod_info["entry_script"] = entry_script;
	mod_info["enabled"] = enabled;
	mod_info["priority"] = priority;
	mod_info["json_path"] = mod_json_path;
	
	// Get the mod directory path
	String mod_dir = mod_json_path.get_base_dir();
	print_to_console("load_mod_from_json: Raw mod_dir from get_base_dir(): " + mod_dir);
	
	// Ensure mod_dir is a resource path
	if (!mod_dir.begins_with("res://") && !mod_dir.begins_with("user://")) {
		mod_dir = "res://" + mod_dir.trim_prefix("./").trim_prefix("/");
		print_to_console("load_mod_from_json: Normalized mod_dir to: " + mod_dir);
	}
	
	mod_info["mod_dir"] = mod_dir;
	print_to_console("load_mod_from_json: Stored mod_dir for " + mod_name + ": " + mod_dir);
	
	loaded_mods[mod_name] = mod_info;
	mod_enabled_status[mod_name] = enabled;
	
	// Load the entry script if it exists and mod is enabled
	if (enabled && !entry_script.is_empty()) {
		String script_path = mod_dir.path_join(entry_script);
		print_to_console("Loading entry script: " + script_path);
		
		if (FileAccess::file_exists(script_path)) {
			if (load_file(script_path)) {
				print_to_console("Successfully loaded entry script: " + script_path);
			} else {
				String error_msg = "Failed to load entry script: " + script_path;
				log_error(error_msg);
				return false;
			}
		} else {
			String error_msg = "Entry script not found: " + script_path;
			log_error(error_msg);
			return false;
		}
	}
	
	print_to_console("Successfully loaded mod: " + mod_name);
	return true;
}

void LuaBridge::enable_mod(String mod_name) {
	print_to_console("Enabling mod: " + mod_name);
	mod_enabled_status[mod_name] = true;
}

void LuaBridge::disable_mod(String mod_name) {
	print_to_console("Disabling mod: " + mod_name);
	mod_enabled_status[mod_name] = false;
}

bool LuaBridge::reload_mod(String mod_name) {
	print_to_console("Reloading mod: " + mod_name);
	
	auto it = loaded_mods.find(mod_name);
	if (it == loaded_mods.end()) {
		String error_msg = "Mod not found for reload: " + mod_name;
		log_error(error_msg);
		return false;
	}
	
	Dictionary mod_info = it->second;
	String json_path = mod_info.get("json_path", "");
	
	if (json_path.is_empty()) {
		String error_msg = "Mod JSON path not found for: " + mod_name;
		log_error(error_msg);
		return false;
	}
	
	// Remove the old mod
	loaded_mods.erase(mod_name);
	mod_enabled_status.erase(mod_name);
	
	// Reload the mod
	bool success = load_mod_from_json(json_path);
	
	if (success) {
		print_to_console("Successfully reloaded mod: " + mod_name);
	} else {
		print_to_console("Failed to reload mod: " + mod_name);
	}
	
	return success;
}

Array LuaBridge::get_all_mod_info() const {
	Array mod_info_array;
	
	for (const auto& pair : loaded_mods) {
		const String& mod_name = pair.first;
		const Dictionary& mod_info = pair.second;
		
		// Create a copy of the mod info and add the enabled status
		Dictionary info_copy = mod_info;
		info_copy["enabled"] = is_mod_enabled(mod_name);
		
		mod_info_array.append(info_copy);
	}
	
	print_to_console("Returning info for " + String::num_int64(mod_info_array.size()) + " mods");
	return mod_info_array;
}

Dictionary LuaBridge::get_mod_info(String mod_name) const {
	auto it = loaded_mods.find(mod_name);
	if (it == loaded_mods.end()) {
		print_to_console("Mod not found: " + mod_name);
		return Dictionary();
	}
	
	// Create a copy of the mod info and add the enabled status
	Dictionary info_copy = it->second;
	info_copy["enabled"] = is_mod_enabled(mod_name);
	
	print_to_console("Returning info for mod: " + mod_name);
	return info_copy;
}

bool LuaBridge::is_mod_enabled(String mod_name) const {
	auto it = mod_enabled_status.find(mod_name);
	return it != mod_enabled_status.end() && it->second;
}

void LuaBridge::call_on_init() {
	if (!L) return;
	
	print_to_console("Calling on_init lifecycle hook");
	lifecycle_initialized = true;
	
	// Call the on_init function if it exists
	call_function("on_init", Array());
}

void LuaBridge::call_on_ready() {
	if (!L) return;
	
	print_to_console("Calling on_ready lifecycle hook");
	lifecycle_ready = true;
	
	// Call the on_ready function if it exists
	call_function("on_ready", Array());
}

void LuaBridge::call_on_update(float delta) {
	if (!L) return;
	
	update_delta = delta;
	
	// Call the on_update function if it exists
	call_function("on_update", Array::make(delta));
}

void LuaBridge::call_on_exit() {
	if (!L) return;
	
	print_to_console("Calling on_exit lifecycle hook");
	lifecycle_initialized = false;
	lifecycle_ready = false;
	
	// Call the on_exit function if it exists with better error handling
	try {
		call_function("on_exit", Array());
	} catch (...) {
		print_to_console("Exception during on_exit call, continuing cleanup...");
	}
}

bool LuaBridge::create_coroutine(String name, String func_name, Array args) {
	if (!L) return false;
	
	print_to_console("Creating coroutine: " + name + " with function: " + func_name);
	
	// For now, just mark as active
	coroutine_active[name] = true;
	return true;
}

bool LuaBridge::resume_coroutine(String name, Variant data) {
	if (!L) return false;
	
	print_to_console("Resuming coroutine: " + name);
	
	// For now, just return true
	return true;
}

bool LuaBridge::is_coroutine_active(String name) const {
	auto it = coroutine_active.find(name);
	return it != coroutine_active.end() && it->second;
}

void LuaBridge::cleanup_coroutines() {
	print_to_console("Cleaning up coroutines");
	coroutine_active.clear();
}

Variant LuaBridge::create_wrapper(Variant obj, String class_name) {
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("create_wrapper: Not a Godot object");
		return Variant();
	}
	
	print_to_console("Creating wrapper for: " + class_name);
	
	// Store the wrapper mapping
	object_wrappers[obj] = class_name;
	wrapper_objects[obj] = obj;
	
	return obj;
}

bool LuaBridge::is_wrapper(Variant obj) const {
	return object_wrappers.find(obj) != object_wrappers.end();
}

Variant LuaBridge::unwrap_object(Variant wrapper) const {
	if (!is_wrapper(wrapper)) {
		print_to_console("unwrap_object: Not a wrapper");
		return Variant();
	}
	
	auto it = wrapper_objects.find(wrapper);
	if (it != wrapper_objects.end()) {
		return it->second;
	}
	
	return Variant();
}

String LuaBridge::get_wrapper_class(Variant wrapper) const {
	if (!is_wrapper(wrapper)) {
		return "";
	}
	
	auto it = object_wrappers.find(wrapper);
	if (it != object_wrappers.end()) {
		return it->second;
	}
	
	return "";
}

bool LuaBridge::is_wrapper_valid(Variant wrapper) const {
	return is_wrapper(wrapper) && wrapper_objects.find(wrapper) != wrapper_objects.end();
}

Variant LuaBridge::safe_call_method(Variant wrapper, String method_name, Array args) {
	if (!is_wrapper_valid(wrapper)) {
		print_to_console("safe_call_method: Invalid wrapper");
		return Variant();
	}
	
	Variant obj = unwrap_object(wrapper);
	if (obj.get_type() != Variant::Type::OBJECT) {
		print_to_console("safe_call_method: Cannot unwrap object");
		return Variant();
	}
	
	return call_method(obj, method_name, args);
}

bool LuaBridge::is_instance(Variant obj, String class_name) const {
	if (obj.get_type() != Variant::Type::OBJECT) {
		return false;
	}
	
	Object* object = Object::cast_to<Object>(obj.operator Object*());
	if (!object) {
		return false;
	}
	
	// Check if the object is an instance of the specified class
	// This is a simplified check - in a real implementation you'd want more sophisticated class checking
	return object->get_class() == class_name;
}

Variant LuaBridge::create_instance(String class_name, Array args) {
	if (!L) return Variant();
	
	print_to_console("Creating instance of class: " + class_name);
	
	// Check if the class can be instantiated
	if (!ClassDB::can_instantiate(class_name)) {
		print_to_console("Cannot instantiate class: " + class_name);
		return Variant();
	}
	
	// Create the instance
	Object* instance = ClassDB::instantiate(class_name);
	if (!instance) {
		print_to_console("Failed to create instance of class: " + class_name);
		return Variant();
	}
	
	print_to_console("Successfully created instance of class: " + class_name);
	return Variant(instance);
}

bool LuaBridge::can_instantiate_class(String class_name) const {
	return ClassDB::can_instantiate(class_name);
}

Array LuaBridge::get_instantiable_classes() const {
	Array classes;
	PackedStringArray class_list = ClassDB::get_class_list();
	
	for (int i = 0; i < class_list.size(); i++) {
		String class_name = class_list[i];
		if (ClassDB::can_instantiate(class_name)) {
			classes.append(class_name);
		}
	}
	
	return classes;
}

void LuaBridge::expose_classes_to_lua() {
	if (!L) return;
	
	print_to_console("Exposing classes to Lua...");
	
	// Create a global table for classes
	lua_newtable(L);
	
	// Expose specific Resource-derived classes
	expose_class_to_lua("BaseItem");
	expose_class_to_lua("ChassisItem");
	expose_class_to_lua("ComponentItem");
	expose_class_to_lua("ConsumableItem");
	expose_class_to_lua("WeaponItem");
	
	// Set the classes table as a global
	lua_setglobal(L, "Classes");
	
	print_to_console("Classes exposed to Lua");
}

void LuaBridge::expose_class_to_lua(String class_name) {
	if (!L) return;
	
	// The Classes table should already be on the stack from expose_classes_to_lua
	// If not, we need to get it from global scope (fallback)
	if (!lua_istable(L, -1)) {
		lua_getglobal(L, "Classes");
		if (!lua_istable(L, -1)) {
			print_to_console("Classes table not found, creating it...");
			lua_pop(L, 1); // Pop the nil value
			lua_newtable(L); // Create a new table
		}
	}
	
	// Create a class constructor function
	lua_pushlightuserdata(L, this);
	lua_pushstring(L, class_name.utf8().get_data());
	lua_pushcclosure(L, lua_class_constructor, 2);
	
	// Set it in the Classes table
	lua_setfield(L, -2, class_name.utf8().get_data());
	
	// Don't pop the table - keep it on stack for next class
	// The table will be popped when we set it as global in expose_classes_to_lua
	
	print_to_console("Exposed class: " + class_name);
}

// Definitions for static helper functions
int LuaBridge::lua_godot_object_newindex(lua_State *L) {
	Object **ud = static_cast<Object **>(luaL_checkudata(L, 1, "GodotObject"));
	if (!ud || !*ud) return 0;
	
	Object *obj = *ud;
	const char *key = lua_tostring(L, 2);
	if (!key) return 0;
	
	Variant value;
	switch (lua_type(L, 3)) {
		case LUA_TSTRING: value = String(lua_tostring(L, 3)); break;
		case LUA_TNUMBER: value = lua_tonumber(L, 3); break;
		case LUA_TBOOLEAN: value = lua_toboolean(L, 3); break;
		case LUA_TUSERDATA: {
			void* userdata_ptr = lua_touserdata(L, 3);
			Variant wrapper_key = Variant((int64_t)userdata_ptr);
			return wrapper_key;
		}
		default: value = Variant(); break;
	}
	
	obj->set(String(key), value);
	return 0;
}

int LuaBridge::lua_godot_object_tostring(lua_State *L) {
	UtilityFunctions::print("[LuaBridge] __tostring called");
	
	// Safety check: ensure we have userdata
	if (!lua_isuserdata(L, 1)) {
		UtilityFunctions::print("[LuaBridge] __tostring: argument is not userdata");
		lua_pushstring(L, "GodotObject: <invalid - not userdata>");
		return 1;
	}
	
	// Get the userdata
	Object **ud = static_cast<Object **>(luaL_checkudata(L, 1, "GodotObject"));
	if (!ud) {
		UtilityFunctions::print("[LuaBridge] __tostring: failed to get userdata");
		lua_pushstring(L, "GodotObject: <invalid - no userdata>");
		return 1;
	}
	
	if (!*ud) {
		UtilityFunctions::print("[LuaBridge] __tostring: object pointer is null");
		lua_pushstring(L, "GodotObject: <null>");
		return 1;
	}
	
	Object *obj = *ud;
	UtilityFunctions::print("[LuaBridge] __tostring: object pointer valid: " + String::num_int64((int64_t)obj));
	
	// Create a safe string representation without calling object methods
	String obj_id = String::num_int64((int64_t)obj);
	String result = "GodotObject:" + obj_id;
	
	UtilityFunctions::print("[LuaBridge] __tostring: returning: " + result);
	
	lua_pushstring(L, result.utf8().get_data());
	return 1;
}

int LuaBridge::lua_godot_object_gc(lua_State *L) {
	UtilityFunctions::print("[LuaBridge] __gc called");
	
	// Check if Lua state is still valid
	if (!L) {
		UtilityFunctions::print("[LuaBridge] __gc: Lua state is null, skipping...");
		return 0;
	}
	
	// Retrieve LuaBridge pointer from Lua registry
	lua_getfield(L, LUA_REGISTRYINDEX, "godot_lua_bridge_ptr");
	LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, -1));
	lua_pop(L, 1);
	
	// If bridge pointer is not found, we're in cleanup mode - just clean up the userdata directly
	if (!bridge) {
		UtilityFunctions::print("[LuaBridge] __gc: bridge pointer not found - cleaning up userdata directly");
		
		// Get the userdata size to determine the type
		size_t userdata_size = lua_rawlen(L, 1);
		UtilityFunctions::print("[LuaBridge] __gc: userdata size: " + String::num_int64(userdata_size));
		
		// Check if this is ResourceUserData (should be sizeof(ResourceUserData))
		if (userdata_size == sizeof(ResourceUserData)) {
			ResourceUserData* resource_ud = static_cast<ResourceUserData*>(lua_touserdata(L, 1));
			if (resource_ud) {
				UtilityFunctions::print("[LuaBridge] __gc: cleaning up ResourceUserData directly");
				
				// Clean up the resource reference
				if (resource_ud->resource_ref.is_valid()) {
					UtilityFunctions::print("[LuaBridge] __gc: resource_ref is valid, cleaning up");
					resource_ud->resource_ref.~Ref<Resource>(); // Explicitly call destructor
				} else {
					UtilityFunctions::print("[LuaBridge] __gc: resource_ref is not valid, cleaning up anyway");
					resource_ud->resource_ref.~Ref<Resource>(); // Explicitly call destructor
				}
				
				resource_ud->obj_ptr = nullptr;
				UtilityFunctions::print("[LuaBridge] __gc: ResourceUserData cleaned up directly");
			}
		} else if (userdata_size == sizeof(Object*)) {
			// This is a regular Object** userdata
			Object **ud = static_cast<Object **>(lua_touserdata(L, 1));
			if (ud && *ud) {
				UtilityFunctions::print("[LuaBridge] __gc: cleaning up Object** structure directly, obj ptr: " + String::num_int64((int64_t)*ud));
				*ud = nullptr;
				UtilityFunctions::print("[LuaBridge] __gc: Object** cleaned up directly");
			}
		} else {
			UtilityFunctions::print("[LuaBridge] __gc: unknown userdata size: " + String::num_int64(userdata_size));
		}
		return 0;
	}
	
	// Check if bridge is being cleaned up
	if (bridge->is_cleaning_up) {
		UtilityFunctions::print("[LuaBridge] __gc: bridge is being cleaned up, skipping...");
		return 0;
	}
	
	// Check if bridge's Lua state is still valid
	if (!bridge->L) {
		UtilityFunctions::print("[LuaBridge] __gc: bridge Lua state is null, skipping...");
		return 0;
	}
	
	try {
		// First, check if this is a ResourceUserData by checking the size
		void* userdata_ptr = lua_touserdata(L, 1);
		if (!userdata_ptr) {
			UtilityFunctions::print("[LuaBridge] __gc: userdata pointer is null");
			return 0;
		}
		
		// Get the userdata size to determine the type
		size_t userdata_size = lua_rawlen(L, 1);
		UtilityFunctions::print("[LuaBridge] __gc: userdata size: " + String::num_int64(userdata_size));
		
		// Check if this is ResourceUserData (should be sizeof(ResourceUserData))
		if (userdata_size == sizeof(ResourceUserData)) {
			ResourceUserData* resource_ud = static_cast<ResourceUserData*>(userdata_ptr);
			if (resource_ud) {
				UtilityFunctions::print("[LuaBridge] __gc: cleaning up ResourceUserData");
				
				// Remove from wrapper map first
				Variant wrapper_key = Variant((int64_t)userdata_ptr);
				std::map<Variant, Variant>::iterator it = bridge->wrapper_objects.find(wrapper_key);
				if (it != bridge->wrapper_objects.end()) {
					bridge->wrapper_objects.erase(it);
					UtilityFunctions::print("[LuaBridge] __gc: removed from wrapper_objects map");
				}
				
				// Clean up the resource reference
				if (resource_ud->resource_ref.is_valid()) {
					UtilityFunctions::print("[LuaBridge] __gc: resource_ref is valid, cleaning up");
					resource_ud->resource_ref.~Ref<Resource>(); // Explicitly call destructor
				} else {
					UtilityFunctions::print("[LuaBridge] __gc: resource_ref is not valid, cleaning up anyway");
					resource_ud->resource_ref.~Ref<Resource>(); // Explicitly call destructor
				}
				
				resource_ud->obj_ptr = nullptr;
				UtilityFunctions::print("[LuaBridge] __gc: ResourceUserData cleaned up");
			}
		} else if (userdata_size == sizeof(Object*)) {
			// This is a regular Object** userdata
			Object **ud = static_cast<Object **>(userdata_ptr);
			if (ud && *ud) {
				UtilityFunctions::print("[LuaBridge] __gc: cleaning up Object** structure, obj ptr: " + String::num_int64((int64_t)*ud));
				
				// Remove from wrapper map first
				Variant wrapper_key = Variant((int64_t)userdata_ptr);
				std::map<Variant, Variant>::iterator it = bridge->wrapper_objects.find(wrapper_key);
				if (it != bridge->wrapper_objects.end()) {
					bridge->wrapper_objects.erase(it);
					UtilityFunctions::print("[LuaBridge] __gc: removed from wrapper_objects map");
				}
				
				*ud = nullptr;
				UtilityFunctions::print("[LuaBridge] __gc: Object** cleaned up");
			}
		} else {
			UtilityFunctions::print("[LuaBridge] __gc: unknown userdata size: " + String::num_int64(userdata_size));
		}
	} catch (...) {
		UtilityFunctions::print("[LuaBridge] __gc: Exception during cleanup, continuing...");
	}
	return 0;
}

// Object wrapping implementation
void LuaBridge::setup_godot_object_metatable() {
	print_to_console("Setting up Godot object metatable...");
	
	// Register the metatable once
	luaL_newmetatable(L, "GodotObject");
	print_to_console("Created metatable 'GodotObject'");

	// __index: dynamically wrap method name as a closure
	lua_pushstring(L, "__index");
	// Push the LuaBridge instance as an upvalue
	lua_pushlightuserdata(L, this);
	lua_pushcclosure(L, [](lua_State* L) -> int {
		// Get the LuaBridge instance from upvalue
		LuaBridge* bridge = static_cast<LuaBridge*>(lua_touserdata(L, lua_upvalueindex(1)));
		if (!bridge) {
			UtilityFunctions::print("[LuaBridge] __index: No bridge instance");
			lua_pushnil(L);
			return 1;
		}
		
		UtilityFunctions::print("[LuaBridge] __index metamethod called - ENTRY");
		
		// Get the userdata
		Object* obj = nullptr;
		
		// Check if it's a userdata
		if (lua_isuserdata(L, 1)) {
			UtilityFunctions::print("[LuaBridge] Userdata found, checking type...");
			
			// Get the userdata pointer
			void* userdata_ptr = lua_touserdata(L, 1);
			if (!userdata_ptr) {
				UtilityFunctions::print("[LuaBridge] Userdata pointer is null");
				lua_pushnil(L);
				return 1;
			}
			
			// Try to get the metatable to determine the type
			if (lua_getmetatable(L, 1)) {
				UtilityFunctions::print("[LuaBridge] Got metatable from userdata");
				// Check if it's our GodotObject metatable
				// Get the GodotObject metatable for comparison
				luaL_getmetatable(L, "GodotObject");
				if (!lua_isnil(L, -1)) {
					UtilityFunctions::print("[LuaBridge] Got GodotObject metatable for comparison");
					if (lua_rawequal(L, -1, -2)) {
						UtilityFunctions::print("[LuaBridge] Metatables match - this is our wrapped object");
						// It's our wrapped object, try to get it from the wrapper map
						Variant wrapper_key = Variant((int64_t)userdata_ptr);
						
						// Look up the actual object in the wrapper_objects map
						std::map<Variant, Variant>::iterator it = bridge->wrapper_objects.find(wrapper_key);
						if (it != bridge->wrapper_objects.end()) {
							Variant wrapped_obj = it->second;
							if (wrapped_obj.get_type() == Variant::OBJECT) {
								obj = wrapped_obj.operator Object*();
								UtilityFunctions::print("[LuaBridge] Found wrapped object in map, obj ptr: " + String::num_int64((int64_t)obj));
							} else {
								UtilityFunctions::print("[LuaBridge] Wrapped object is not an Object");
								lua_pop(L, 2); // pop both metatables
								lua_pushnil(L);
								return 1;
							}
						} else {
							UtilityFunctions::print("[LuaBridge] No wrapped object found in map for key: " + String::num_int64((int64_t)userdata_ptr));
							lua_pop(L, 2); // pop both metatables
							lua_pushnil(L);
							return 1;
						}
						lua_pop(L, 2); // pop both metatables
					} else {
						UtilityFunctions::print("[LuaBridge] Metatables don't match - unknown metatable");
						lua_pop(L, 2); // pop both metatables
						lua_pushnil(L);
						return 1;
					}
				} else {
					UtilityFunctions::print("[LuaBridge] GodotObject metatable not found in registry");
					lua_pop(L, 2); // pop both metatables
					lua_pushnil(L);
					return 1;
				}
			} else {
				UtilityFunctions::print("[LuaBridge] No metatable found");
				lua_pushnil(L);
				return 1;
			}
		} else {
			UtilityFunctions::print("[LuaBridge] Not userdata, pushing nil");
			lua_pushnil(L);
			return 1;
		}

		if (!obj) {
			UtilityFunctions::print("[LuaBridge] Object is null, pushing nil");
			lua_pushnil(L);
			return 1;
		}

		// Get the key
		const char* key = lua_tostring(L, 2);
		if (!key) {
			UtilityFunctions::print("[LuaBridge] Key is not a string, pushing nil");
			lua_pushnil(L);
			return 1;
		}

		UtilityFunctions::print("[LuaBridge] Looking up key: " + String(key) + " on object: " + obj->get_class());

		// Try to get the method/property
		if (obj->has_method(key)) {
			UtilityFunctions::print("[LuaBridge] Method found: " + String(key));
			// Push method name as upvalue
			lua_pushstring(L, key);
			// Push a lightuserdata reference to the object as upvalue
			lua_pushlightuserdata(L, obj);
			// Closure: upvalue 1 = method name, upvalue 2 = object pointer
			lua_pushcclosure(L, [](lua_State* L) -> int {
				// Retrieve upvalues
				const char* method_name = lua_tostring(L, lua_upvalueindex(1));
				Object* obj = static_cast<Object*>(lua_touserdata(L, lua_upvalueindex(2)));
				if (!obj || !method_name) {
					UtilityFunctions::print("[LuaBridge] Bound method: missing object or method name");
					lua_pushnil(L);
					return 1;
				}
				UtilityFunctions::print("[LuaBridge] Bound method: " + String(method_name) + " on object: " + obj->get_class());
				// Build argument array from Lua stack
				Array args;
				int num_args = lua_gettop(L);
				for (int i = 1; i <= num_args; i++) {
					if (lua_isstring(L, i)) args.push_back(String(lua_tostring(L, i)));
					else if (lua_isnumber(L, i)) args.push_back(lua_tonumber(L, i));
					else if (lua_isboolean(L, i)) args.push_back((bool)lua_toboolean(L, i));
					else if (lua_isnil(L, i)) args.push_back(Variant());
					else args.push_back(Variant());
				}
				// Call the method
				Variant result;
				try {
					result = obj->callv(method_name, args);
					UtilityFunctions::print("[LuaBridge] Bound method call completed");
					UtilityFunctions::print("[LuaBridge] Method returned type: " + String::num_int64(result.get_type()));
				} catch (...) {
					UtilityFunctions::print("[LuaBridge] Bound method call exception");
					lua_pushnil(L);
					return 1;
				}
				// Convert result to Lua
				UtilityFunctions::print("[LuaBridge] Converting result to Lua, type: " + String::num_int64(result.get_type()));
				UtilityFunctions::print("[LuaBridge] Lua stack top before pushing result: " + String::num_int64(lua_gettop(L)));
				
				// Clear any existing values on the stack for this function call
				lua_settop(L, 0);
				UtilityFunctions::print("[LuaBridge] Lua stack cleared, top is now: " + String::num_int64(lua_gettop(L)));
				
				if (result.get_type() == Variant::BOOL) {
					lua_pushboolean(L, bool(result));
					UtilityFunctions::print("[LuaBridge] Pushed boolean result");
				} else if (result.get_type() == Variant::INT) {
					lua_pushinteger(L, int64_t(result));
					UtilityFunctions::print("[LuaBridge] Pushed integer result");
				} else if (result.get_type() == Variant::FLOAT) {
					lua_pushnumber(L, double(result));
					UtilityFunctions::print("[LuaBridge] Pushed float result");
				} else if (result.get_type() == Variant::STRING) {
					String str_result = String(result);
					CharString utf8 = str_result.utf8();
					lua_pushlstring(L, utf8.get_data(), utf8.length());
					UtilityFunctions::print("[LuaBridge] Pushed string result: " + str_result);
				} else if (result.get_type() == Variant::NIL) {
					lua_pushnil(L);
					UtilityFunctions::print("[LuaBridge] Pushed nil result");
				} else {
					lua_pushnil(L);
					UtilityFunctions::print("[LuaBridge] Pushed nil for unknown type: " + String::num_int64(result.get_type()));
				}
				
				UtilityFunctions::print("[LuaBridge] Lua stack top after pushing result: " + String::num_int64(lua_gettop(L)));
				UtilityFunctions::print("[LuaBridge] About to return from method call function");
				return 1;
			}, 2);
			UtilityFunctions::print("[LuaBridge] Bound method closure created for: " + String(key));
		} else {
			UtilityFunctions::print("[LuaBridge] Method not found: " + String(key));
			lua_pushnil(L);
		}

		return 1;
	}, 1);
	lua_settable(L, -3);

	print_to_console("Set __index metamethod");

	// __newindex for property set
	lua_pushstring(L, "__newindex");
	lua_pushcfunction(L, lua_godot_object_newindex);
	lua_settable(L, -3);
	print_to_console("Set __newindex metamethod");

	// __tostring for string representation
	lua_pushstring(L, "__tostring");
	lua_pushcfunction(L, lua_godot_object_tostring);
	lua_settable(L, -3);
	print_to_console("Set __tostring metamethod");

	// __gc for garbage collection
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, lua_godot_object_gc);
	lua_settable(L, -3);
	print_to_console("Set __gc metamethod");

	lua_pop(L, 1); // pop metatable
	print_to_console("Godot object metatable setup complete");
}

void LuaBridge::push_godot_object_as_userdata(lua_State* L, Object* obj) {
	UtilityFunctions::print("[LuaBridge] push_godot_object_as_userdata START - obj ptr: " + String::num_int64((int64_t)obj));
	
	if (!obj) {
		UtilityFunctions::print("[LuaBridge] Object is null, pushing nil");
		lua_pushnil(L);
		return;
	}

	UtilityFunctions::print("[LuaBridge] Object is not null, checking if it's a Resource...");

	// If the object is a Resource (or derived), use ResourceUserData to hold a strong reference
	Ref<Resource> res = Object::cast_to<Resource>(obj);
	if (res.is_valid()) {
		UtilityFunctions::print("[LuaBridge] Object is a Resource, creating ResourceUserData...");
		
		ResourceUserData* ud = (ResourceUserData*)lua_newuserdata(L, sizeof(ResourceUserData));
		UtilityFunctions::print("[LuaBridge] ResourceUserData allocated");
		
		ud->obj_ptr = obj;
		// Use placement new to properly construct the Ref<Resource>
		new (&ud->resource_ref) Ref<Resource>(res);
		UtilityFunctions::print("[LuaBridge] resource_ref constructed with placement new");

		// REGISTER THE OBJECT IN THE WRAPPER MAP
		Variant wrapper_key = Variant((int64_t)ud);
		wrapper_objects[wrapper_key] = Variant(obj);
		object_wrappers[wrapper_key] = obj->get_class();
		UtilityFunctions::print("[LuaBridge] Registered Resource in wrapper_objects with key: " + String::num_int64((int64_t)ud));

		UtilityFunctions::print("[LuaBridge] Getting metatable...");
		luaL_getmetatable(L, "GodotObject");
		if (!lua_isnil(L, -1)) {
			lua_setmetatable(L, -2);
			UtilityFunctions::print("[LuaBridge] Metatable set successfully");
		} else {
			lua_pop(L, 1);
			UtilityFunctions::print("Warning: GodotObject metatable not found for ResourceUserData");
		}

		UtilityFunctions::print("[LuaBridge] About to return wrapped Resource to Lua...");
		
		// Safety check - make sure the resource is still valid
		if (res.is_valid()) {
			UtilityFunctions::print("[LuaBridge] Resource is still valid, getting class...");
			UtilityFunctions::print("[LuaBridge] Wrapped Resource: " + res->get_class() + ", obj ptr: " + String::num_int64((int64_t)obj));
		} else {
			UtilityFunctions::print("[LuaBridge] WARNING: Resource became invalid after metatable setup!");
		}
	} else {
		UtilityFunctions::print("[LuaBridge] Object is not a Resource, creating Object** userdata...");
		
		// For non-Resource objects, just store the pointer
		Object** ud = (Object**)lua_newuserdata(L, sizeof(Object*));
		UtilityFunctions::print("[LuaBridge] Object** userdata allocated");
		
		*ud = obj;
		UtilityFunctions::print("[LuaBridge] Object** userdata initialized");

		// REGISTER THE OBJECT IN THE WRAPPER MAP
		Variant wrapper_key = Variant((int64_t)ud);
		wrapper_objects[wrapper_key] = Variant(obj);
		object_wrappers[wrapper_key] = obj->get_class();
		UtilityFunctions::print("[LuaBridge] Registered Object in wrapper_objects with key: " + String::num_int64((int64_t)ud));

		UtilityFunctions::print("[LuaBridge] Getting metatable...");
		luaL_getmetatable(L, "GodotObject");
		if (!lua_isnil(L, -1)) {
			lua_setmetatable(L, -2);
			UtilityFunctions::print("[LuaBridge] Metatable set successfully");
		} else {
			lua_pop(L, 1);
			UtilityFunctions::print("Warning: GodotObject metatable not found for Object*");
		}

		UtilityFunctions::print("[LuaBridge] Wrapped Object: " + obj->get_class() + ", obj ptr: " + String::num_int64((int64_t)obj));
	}
	
	UtilityFunctions::print("[LuaBridge] push_godot_object_as_userdata COMPLETED");
}

Array LuaBridge::lua_to_variant_array(lua_State* L, int start) {
	Array args;
	int num_args = lua_gettop(L);
	
	UtilityFunctions::print("[LuaBridge] lua_to_variant_array called with " + String::num_int64(num_args) + " arguments");
	UtilityFunctions::print("[LuaBridge] lua_to_variant_array start parameter: " + String::num_int64(start));
	
	// Safety check for valid start index
	if (start < 1 || start > num_args) {
		UtilityFunctions::print("[LuaBridge] lua_to_variant_array: Invalid start index " + String::num_int64(start) + " for " + String::num_int64(num_args) + " arguments");
		return args;
	}
	
	// Debug: Check what type the first argument is
	if (num_args >= 1) {
		int type = lua_type(L, 1);
		const char* type_name = lua_typename(L, type);
		UtilityFunctions::print("[LuaBridge] First argument type: " + String(type_name));
		UtilityFunctions::print("[LuaBridge] Is table check: " + String(lua_istable(L, 1) ? "true" : "false"));
	}
	
	// Check if we have exactly one argument and it's a table
	if (num_args == 1 && lua_istable(L, 1)) {
		// Convert the Lua table to a Godot Dictionary and pass it as a single argument
		try {
			Variant dict = lua_to_godot(L, 1);
			args.append(dict);
			UtilityFunctions::print("[LuaBridge] Converting Lua table to Dictionary argument");
			UtilityFunctions::print("[LuaBridge] Dictionary type: " + String::num_int64(dict.get_type()));
			if (dict.get_type() == Variant::DICTIONARY) {
				Dictionary d = dict;
				UtilityFunctions::print("[LuaBridge] Dictionary has " + String::num_int64(d.size()) + " keys");
			}
		} catch (...) {
			UtilityFunctions::print("[LuaBridge] lua_to_variant_array: Exception occurred while converting table, using empty dictionary");
			args.append(Dictionary());
		}
	} else {
		// Original behavior: convert all arguments individually
		for (int i = start; i <= num_args; ++i) {
			try {
				Variant arg = lua_to_godot(L, i);
				args.append(arg);
			} catch (...) {
				args.append(Variant());
			}
		}
	}
	return args;
}

Variant LuaBridge::lua_to_variant(lua_State* L, int index) {
	switch (lua_type(L, index)) {
		case LUA_TSTRING:
			return String(lua_tostring(L, index));
		case LUA_TNUMBER:
			// Check if it's an integer first
			if (lua_isinteger(L, index)) {
				return (int64_t)lua_tointeger(L, index);
			} else {
				return lua_tonumber(L, index);
			}
		case LUA_TBOOLEAN:
			return lua_toboolean(L, index);
		case LUA_TUSERDATA: {
			void* userdata_ptr = lua_touserdata(L, index);
			Variant wrapper_key = Variant((int64_t)userdata_ptr);
			return wrapper_key;
		}
		default:
			return Variant();  // nil or unsupported
	}
}

void LuaBridge::push_variant_to_lua(lua_State* L, const Variant& value) {
	switch (value.get_type()) {
		case Variant::BOOL:
			lua_pushboolean(L, bool(value));
			break;
		case Variant::INT:
			lua_pushinteger(L, int64_t(value));
			break;
		case Variant::FLOAT:
			lua_pushnumber(L, double(value));
			break;
		case Variant::STRING:
			lua_pushstring(L, String(value).utf8().get_data());
			break;
		case Variant::DICTIONARY: {
			Dictionary dict = value;
			lua_newtable(L);
			
			// Get all keys and values
			Array keys = dict.keys();
			Array values = dict.values();
			
			for (int i = 0; i < keys.size(); i++) {
				Variant key = keys[i];
				Variant val = values[i];
				
				// Push the key
				push_variant_to_lua(L, key);
				
				// Push the value
				push_variant_to_lua(L, val);
				
				// Set the key-value pair in the table
				lua_settable(L, -3);
			}
			break;
		}
		case Variant::ARRAY: {
			Array arr = value;
			lua_newtable(L);
			for (int i = 0; i < arr.size(); i++) {
				// Lua arrays are 1-indexed
				lua_pushinteger(L, i + 1);
				push_variant_to_lua(L, arr[i]);
				lua_settable(L, -3);
			}
			break;
		}
		case Variant::OBJECT: {
			Object *obj = Object::cast_to<Object>(value);
			if (obj) {
				push_godot_object_as_userdata(L, obj);
			} else {
				lua_pushnil(L);
			}
			break;
		}
		default:
			lua_pushnil(L);
	}
} 

void LuaBridge::set_verbose_logging(bool enabled) {
	verbose_logging = enabled;
}

bool LuaBridge::is_verbose_logging() const {
	return verbose_logging;
}