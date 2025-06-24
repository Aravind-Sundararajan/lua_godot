#ifndef LUA_BRIDGE_H
#define LUA_BRIDGE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <map>
#include <vector>

extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

namespace godot {

class LuaBridge;

// Wrapper structure for Godot objects in Lua
struct GodotObjectWrapper {
    Object* object;
    String class_name;
    bool is_valid;
    
    GodotObjectWrapper(Object* obj, String cls_name) : object(obj), class_name(cls_name), is_valid(obj != nullptr) {}
};

class LuaBridge : public RefCounted {
    GDCLASS(LuaBridge, RefCounted)

private:
    lua_State* L = nullptr;
    Array loaded_mods;
    bool sandboxed = true;
    
    // Mod management
    Dictionary mod_metadata;  // mod_name -> mod_info
    Array enabled_mods;       // list of enabled mod names

    // Event bus
    std::map<String, std::vector<String>> event_subscribers;

    // Coroutine support
    std::map<String, lua_State*> active_coroutines;

    // Custom require handler
    static int lua_require_mod(lua_State* L);
    void setup_require_handler();
    // Stack trace helper
    String get_lua_stack_trace();

protected:
    static void _bind_methods();

public:
    /**
     * Constructs a new LuaBridge and initializes the Lua state.
     */
    LuaBridge();
    /**
     * Destroys the LuaBridge and cleans up the Lua state and coroutines.
     */
    ~LuaBridge();

    // Core scripting features
    /**
     * Executes a Lua code string in the Lua state with error isolation.
     * @param code The Lua code to execute.
     * @return The return value of the code, or Variant() on error.
     */
    Variant exec_string(String code);
    /**
     * Executes a Lua script file.
     * @param path The path to the Lua file.
     */
    void exec_file(String path);
    /**
     * Loads a Lua script file into the Lua state.
     * @param path The path to the Lua file.
     * @return True if loaded successfully, false otherwise.
     */
    bool load_file(String path);
    /**
     * Reloads the Lua state, reinitializing the environment.
     */
    void reload();
    /**
     * Unloads the Lua state and all loaded mods.
     */
    void unload();

    // Global variable management
    /**
     * Sets a global variable in the Lua state.
     * @param name The variable name.
     * @param value The value to set.
     */
    void set_global(String name, Variant value);
    /**
     * Gets a global variable from the Lua state.
     * @param name The variable name.
     * @return The value of the variable, or Variant() if not found.
     */
    Variant get_global(String name) const;

    // Function calling
    /**
     * Calls a Lua function by name with arguments, with error isolation.
     * @param func_name The Lua function name.
     * @param args The arguments to pass.
     * @return The return value, or Variant() on error.
     */
    Variant call_function(String func_name, Array args);
    /**
     * Registers a Godot Callable as a Lua function (not yet implemented).
     * @param name The function name.
     * @param cb The Callable to register.
     */
    void register_function(String name, Callable cb);

    // Type checking and validation
    /**
     * Checks if a Variant is a Godot Object of the given class.
     * @param obj The object to check.
     * @param class_name The class name.
     * @return True if obj is of the class, false otherwise.
     */
    bool is_instance(Variant obj, String class_name);
    /**
     * Gets the class name of a Godot Object Variant.
     * @param obj The object.
     * @return The class name as a string.
     */
    String get_class(Variant obj);
    /**
     * Validates arguments for a Lua function call.
     * @param func_name The Lua function name.
     * @param args The arguments to check.
     * @return True if valid, false otherwise.
     */
    bool validate_function_args(String func_name, Array args);

    // Safe casting wrappers
    /**
     * Creates a safe wrapper for a Godot Object for use in Lua.
     * @param obj The object to wrap.
     * @param class_name The class name to check.
     * @return A wrapper dictionary, or Variant() on error.
     */
    Variant create_wrapper(Variant obj, String class_name);
    /**
     * Checks if a Variant is a wrapper created by create_wrapper().
     * @param obj The object to check.
     * @return True if it is a wrapper, false otherwise.
     */
    bool is_wrapper(Variant obj) const;
    /**
     * Unwraps a wrapper to get the original Godot Object.
     * @param wrapper The wrapper.
     * @return The original object, or Variant() on error.
     */
    Variant unwrap_object(Variant wrapper) const;
    /**
     * Gets the class name stored in a wrapper.
     * @param wrapper The wrapper.
     * @return The class name as a string.
     */
    String get_wrapper_class(Variant wrapper) const;
    /**
     * Checks if a wrapper is still valid (object not freed).
     * @param wrapper The wrapper.
     * @return True if valid, false otherwise.
     */
    bool is_wrapper_valid(Variant wrapper) const;
    /**
     * Safely calls a method on a wrapped object.
     * @param wrapper The wrapper.
     * @param method_name The method to call.
     * @param args The arguments to pass.
     * @return The return value, or Variant() on error.
     */
    Variant safe_call_method(Variant wrapper, String method_name, Array args);

    // Mod management
    /**
     * Loads all Lua scripts from a directory as mods.
     * @param mod_dir The directory path.
     * @return True if successful, false otherwise.
     */
    bool load_script_from_directory(String mod_dir);
    /**
     * Calls a Lua event function with arguments.
     * @param event_name The event function name.
     * @param args The arguments to pass.
     * @return True if the function was called, false otherwise.
     */
    bool call_event(String event_name, Array args);
    /**
     * Lists all loaded mods.
     * @return An array of mod names.
     */
    Array list_loaded_mods() const;
    /**
     * Unloads a mod by name.
     * @param mod_name The mod name.
     */
    void unload_mod(String mod_name);
    
    // JSON mod management
    /**
     * Loads a mod from a JSON metadata file.
     * @param mod_json_path The path to the mod.json file.
     * @return True if loaded successfully, false otherwise.
     */
    bool load_mod_from_json(String mod_json_path);
    /**
     * Loads all mods from a directory containing mod.json files.
     * @param mods_dir The directory path.
     * @return True if successful, false otherwise.
     */
    bool load_mods_from_directory(String mods_dir);
    /**
     * Gets metadata for a mod by name.
     * @param mod_name The mod name.
     * @return A dictionary of mod info.
     */
    Dictionary get_mod_info(String mod_name) const;
    /**
     * Gets metadata for all loaded mods.
     * @return An array of mod info dictionaries.
     */
    Array get_all_mod_info() const;
    /**
     * Checks if a mod is enabled.
     * @param mod_name The mod name.
     * @return True if enabled, false otherwise.
     */
    bool is_mod_enabled(String mod_name) const;
    /**
     * Enables a mod by name.
     * @param mod_name The mod name.
     */
    void enable_mod(String mod_name);
    /**
     * Disables a mod by name.
     * @param mod_name The mod name.
     */
    void disable_mod(String mod_name);

    // Lifecycle hooks
    /**
     * Calls the on_init() hook in all enabled mods.
     */
    void call_on_init();
    /**
     * Calls the on_ready() hook in all enabled mods.
     */
    void call_on_ready();
    /**
     * Calls the on_update(delta) hook in all enabled mods.
     * @param delta The frame delta time.
     */
    void call_on_update(double delta);
    /**
     * Calls the on_exit() hook in all enabled mods.
     */
    void call_on_exit();

    // Security & sandboxing
    /**
     * Enables or disables Lua sandboxing.
     * @param enabled True to enable, false to disable.
     */
    void set_sandboxed(bool enabled);
    /**
     * Checks if Lua sandboxing is enabled.
     * @return True if sandboxed, false otherwise.
     */
    bool is_sandboxed() const;
    /**
     * Sets up a safe Lua environment with restricted libraries.
     */
    void setup_safe_environment();

    // Utility methods
    /**
     * Prints a message to the Godot output log.
     * @param message The message to print.
     */
    void print_to_console(String message) const;
    /**
     * Logs an error message to the Godot output log.
     * @param error_message The error message.
     */
    void log_error(String error_message);
    /**
     * Gets the last Lua error message.
     * @return The last error as a string.
     */
    String get_last_error() const;

    // Signal and property access
    /**
     * Connects a Godot signal to a Lua function.
     * @param obj The Godot object emitting the signal.
     * @param signal_name The signal name.
     * @param lua_func_name The Lua function to call.
     * @return True if connected, false otherwise.
     */
    bool connect_signal(Variant obj, String signal_name, String lua_func_name);
    /**
     * Gets a property value from a Godot object.
     * @param obj The object.
     * @param property_name The property name.
     * @return The property value, or Variant() if not found.
     */
    Variant get_property(Variant obj, String property_name) const;
    /**
     * Sets a property value on a Godot object.
     * @param obj The object.
     * @param property_name The property name.
     * @param value The value to set.
     */
    void set_property(Variant obj, String property_name, Variant value);

    // Scene and resource management
    /**
     * Gets a node at a given path relative to a Node.
     * @param obj The Node object.
     * @param path The node path.
     * @return The target Node, or Variant() if not found.
     */
    Variant get_node(Variant obj, String path) const;
    /**
     * Gets all children of a Node as an array.
     * @param obj The Node object.
     * @return An array of child nodes.
     */
    Array get_children(Variant obj) const;
    /**
     * Loads a Godot resource (scene, texture, etc.) from a path.
     * @param path The resource path.
     * @return The loaded resource, or Variant() if not found.
     */
    Variant load_resource(String path) const;
    /**
     * Loads and instances a scene from a path.
     * @param path The scene path.
     * @return The new Node instance, or Variant() if failed.
     */
    Variant instance_scene(String path) const;

    // Event bus
    /**
     * Emits an event to all Lua subscribers.
     * @param name The event name.
     * @param data The event data.
     */
    void emit_event(String name, Variant data);
    /**
     * Subscribes a Lua function to an event name.
     * @param name The event name.
     * @param func The Lua function name.
     */
    void subscribe_event(String name, String func);

    // Error isolation and mod reloading
    /**
     * Reloads a mod by name (unloads and re-enables it).
     * @param mod_name The mod name.
     * @return True if reloaded, false otherwise.
     */
    bool reload_mod(String mod_name);

    // Coroutine support
    /**
     * Creates a new Lua coroutine for a function and arguments.
     * @param name The coroutine name.
     * @param func_name The Lua function name.
     * @param args The arguments to pass.
     * @return True if created, false otherwise.
     */
    bool create_coroutine(String name, String func_name, Array args);
    /**
     * Resumes a suspended Lua coroutine with data.
     * @param name The coroutine name.
     * @param data The data to pass to the coroutine.
     * @return True if resumed, false otherwise.
     */
    bool resume_coroutine(String name, Variant data);
    /**
     * Checks if a coroutine is still active.
     * @param name The coroutine name.
     * @return True if active, false otherwise.
     */
    bool is_coroutine_active(String name) const;
    /**
     * Cleans up all active coroutines.
     */
    void cleanup_coroutines();

private:
    void setup_game_api();
    void setup_safe_libraries();
    void setup_unsafe_libraries();
    String get_lua_error();
    bool call_lua_function(String func_name, Array args);
    
    // Wrapper helper methods
    void setup_wrapper_metatable();
    static int lua_wrapper_index(lua_State* L);
    static int lua_wrapper_newindex(lua_State* L);
    static int lua_wrapper_tostring(lua_State* L);
    static int lua_wrapper_gc(lua_State* L);
    void push_wrapper_to_lua(Object* obj, String class_name);
    GodotObjectWrapper* get_wrapper_from_lua(int index);
    bool validate_wrapper_call(GodotObjectWrapper* wrapper, String method_name);
};

// Helper relay for forwarding Godot signals to Lua
class LuaSignalRelay : public RefCounted {
    GDCLASS(LuaSignalRelay, RefCounted)
    LuaBridge* bridge = nullptr;
    String lua_func_name;
public:
    void setup(LuaBridge* b, String func) { bridge = b; lua_func_name = func; }
    void _on_signal(Variant arg) {
        if (bridge) bridge->call_function(lua_func_name, Array::make(arg));
    }
    static void _bind_methods() {}
};

}

#endif // LUA_BRIDGE_H