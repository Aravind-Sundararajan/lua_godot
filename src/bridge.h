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
#include <godot_cpp/classes/script.hpp>
#include <map>
#include <vector>

// Forward declarations
struct lua_State;

namespace godot {

class SceneTree;
class Engine;

class LuaBridge;

class LuaBridge : public RefCounted {
    GDCLASS(LuaBridge, RefCounted)

private:
    lua_State* L = nullptr;
    bool sandboxed = true;
    String last_error = "";
    
    // Registered Godot functions
    std::map<String, Callable> registered_functions;

    // Event bus
    std::map<String, std::vector<String>> event_subscribers;

    // Mod management
    std::map<String, Dictionary> loaded_mods;
    std::map<String, bool> mod_enabled_status;

    // Lifecycle hooks
    bool lifecycle_initialized = false;
    bool lifecycle_ready = false;
    float update_delta = 0.0f;

    // Coroutines
    std::map<String, bool> coroutine_active;

    // Object wrappers
    std::map<Variant, String> object_wrappers;
    mutable std::map<Variant, Variant> wrapper_objects;

    // Static Lua callback functions
    static int lua_require_mod(lua_State* L);
    static int lua_class_constructor(lua_State* L);
    static int lua_call_godot_function(lua_State* L);
    static int godot_object_index(lua_State* L);
    static int lua_godot_object_newindex(lua_State* L);
    static int lua_godot_object_tostring(lua_State* L);
    static int lua_godot_object_gc(lua_State* L);
    
    // Setup functions
    void setup_require_handler();
    void setup_game_api();
    void setup_safe_libraries();
    void setup_godot_object_metatable();
    void setup_safe_environment();
    
    // Class exposure
    void expose_classes_to_lua();
    void expose_class_to_lua(String class_name);
    
    // Data conversion helpers
    void godot_to_lua(lua_State* L, const Variant& value);
    Variant lua_to_godot(lua_State* L, int index) const;
    static Variant lua_to_variant(lua_State* L, int index);
    void push_variant_to_lua(lua_State* L, const Variant& value);
    Array lua_to_variant_array(lua_State* L, int start = 1);
    
    // Object wrapping
    void push_godot_object_as_userdata(lua_State* L, Object* obj);
    
    // Utility functions
    String get_lua_error();
    bool call_lua_function(String func_name, Array args);

protected:
    static void _bind_methods();

public:
    // Signals
    /**
     * Emitted when a Lua error occurs.
     * @param error_message The error message.
     * @param error_type The type of error (syntax, runtime, etc.).
     * @param file_path The file path where the error occurred (if applicable).
     */
    void lua_error_occurred(String error_message, String error_type, String file_path);

    /**
     * Constructs a new LuaBridge and initializes the Lua state.
     */
    LuaBridge();
    /**
     * Destroys the LuaBridge and cleans up the Lua state.
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
     * Loads and executes a Lua script file.
     * @param path The path to the Lua file.
     * @return True if loaded successfully, false otherwise.
     */
    bool load_file(String path);
    /**
     * Unloads the Lua state.
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
     * Registers a Godot Callable as a Lua function.
     * @param name The function name.
     * @param cb The Callable to register.
     */
    void register_function(String name, Callable cb);

    // Object access
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
    /**
     * Safely calls a method on a Godot object.
     * @param obj The object.
     * @param method_name The method to call.
     * @param args The arguments to pass.
     * @return The return value, or Variant() on error.
     */
    Variant call_method(Variant obj, String method_name, Array args);
    /**
     * Gets the class name of a Godot object.
     * @param obj The object.
     * @return The class name as a string, or empty string if invalid.
     */
    String get_class(Variant obj) const;

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
     * Gets an autoload singleton by name.
     * @param singleton_name The autoload singleton name.
     * @return The singleton object, or Variant() if not found.
     */
    Variant get_autoload_singleton(String singleton_name) const;
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

    // Signal connection
    /**
     * Connects a Godot signal to a Lua function.
     * @param obj The Godot object emitting the signal.
     * @param signal_name The signal name.
     * @param lua_func_name The Lua function to call.
     * @return True if connected, false otherwise.
     */
    bool connect_signal(Variant obj, String signal_name, String lua_func_name);

    // Security & sandboxing
    void set_sandboxed(bool enabled);
    bool is_sandboxed() const;

    // Utility methods
    void print_to_console(String message) const;
    void log_error(String error_message);
    void log_lua_error(String error_message, String error_type, String file_path);
    String get_last_error() const;
    void clear_last_error();

    // Mod management
    bool load_mods_from_directory(String mods_dir);
    bool load_mod_from_json(String mod_json_path);
    void enable_mod(String mod_name);
    void disable_mod(String mod_name);
    bool reload_mod(String mod_name);
    Array get_all_mod_info() const;
    Dictionary get_mod_info(String mod_name) const;
    bool is_mod_enabled(String mod_name) const;

    // Lifecycle hooks
    void call_on_init();
    void call_on_ready();
    void call_on_update(float delta);
    void call_on_exit();

    // Coroutines
    bool create_coroutine(String name, String func_name, Array args);
    bool resume_coroutine(String name, Variant data);
    bool is_coroutine_active(String name) const;
    void cleanup_coroutines();

    // Object wrappers
    Variant create_wrapper(Variant obj, String class_name);
    bool is_wrapper(Variant obj) const;
    Variant unwrap_object(Variant wrapper) const;
    /**
     * Gets the class name of a wrapper.
     * @param wrapper The wrapper object.
     * @return The class name, or empty string if failed.
     */
    String get_wrapper_class(Variant wrapper) const;
    /**
     * Checks if a wrapper is valid.
     * @param wrapper The wrapper object.
     * @return True if valid, false otherwise.
     */
    bool is_wrapper_valid(Variant wrapper) const;
    /**
     * Safely calls a method on a wrapper.
     * @param wrapper The wrapper object.
     * @param method_name The method name.
     * @param args The arguments to pass.
     * @return The result, or null if failed.
     */
    Variant safe_call_method(Variant wrapper, String method_name, Array args);

    // Instance checking
    bool is_instance(Variant obj, String class_name) const;

    // Class instantiation
    Variant create_instance(String class_name, Array args = Array());
    bool can_instantiate_class(String class_name) const;
    Array get_instantiable_classes() const;
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