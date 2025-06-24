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

extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}

namespace godot {

class LuaBridge : public RefCounted {
    GDCLASS(LuaBridge, RefCounted)

private:
    lua_State* L = nullptr;
    Array loaded_mods;
    bool sandboxed = true;
    
    // Mod management
    Dictionary mod_metadata;  // mod_name -> mod_info
    Array enabled_mods;       // list of enabled mod names

protected:
    static void _bind_methods();

public:
    LuaBridge();
    ~LuaBridge();

    // Core scripting features
    void exec_string(String code);
    void exec_file(String path);
    bool load_file(String path);
    void reload();
    void unload();

    // Global variable management
    void set_global(String name, Variant value);
    Variant get_global(String name) const;

    // Function calling
    Variant call_function(String func_name, Array args);
    void register_function(String name, Callable cb);

    // Mod management
    bool load_script_from_directory(String mod_dir);
    bool call_event(String event_name, Array args);
    Array list_loaded_mods() const;
    void unload_mod(String mod_name);
    
    // JSON mod management
    bool load_mod_from_json(String mod_json_path);
    bool load_mods_from_directory(String mods_dir);
    Dictionary get_mod_info(String mod_name) const;
    Array get_all_mod_info() const;
    bool is_mod_enabled(String mod_name) const;
    void enable_mod(String mod_name);
    void disable_mod(String mod_name);

    // Lifecycle hooks
    void call_on_init();
    void call_on_ready();
    void call_on_update(double delta);
    void call_on_exit();

    // Security & sandboxing
    void set_sandboxed(bool enabled);
    bool is_sandboxed() const;
    void setup_safe_environment();

    // Utility methods
    void print_to_console(String message);
    void log_error(String error_message);
    String get_last_error() const;

private:
    void setup_game_api();
    void setup_safe_libraries();
    void setup_unsafe_libraries();
    String get_lua_error();
    bool call_lua_function(String func_name, Array args);
};

}

#endif // LUA_BRIDGE_H