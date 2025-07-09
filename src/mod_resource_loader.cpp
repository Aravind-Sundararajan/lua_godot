#include "mod_resource_loader.h"
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

void ModResourceLoader::cleanup() {
    UtilityFunctions::print("ModResourceLoader: cleanup() called");
    // This method can be used to clear any cached resources or references
    // Currently, the loader doesn't cache anything, so this is mostly for future use
}

void ModResourceLoader::_bind_methods() {
    // No methods to bind for this class
}

PackedStringArray ModResourceLoader::_get_recognized_extensions() const {
    UtilityFunctions::print("ModResourceLoader: _get_recognized_extensions() called");
    return PackedStringArray();
}

bool ModResourceLoader::_recognize_path(const String &path, const StringName &type) const {
    bool recognized = path.begins_with("mod://");
    UtilityFunctions::print("ModResourceLoader: _recognize_path() called with path: ", path, ", type: ", type, ", recognized: ", recognized);
    return recognized;
}

String ModResourceLoader::_get_resource_type(const String &path) const {
    UtilityFunctions::print("ModResourceLoader: _get_resource_type() called with path: ", path);
    if (path.begins_with("mod://")) {
        return "";
    }
    return "";
}

Variant ModResourceLoader::_load(const String &path, const String &original_path, bool use_sub_threads, int32_t cache_mode) const {
    UtilityFunctions::print("ModResourceLoader: _load() called with path: ", path, ", original_path: ", original_path);
    
    if (!path.begins_with("mod://")) {
        UtilityFunctions::print("ModResourceLoader: Path does not begin with mod://, returning null");
        return Variant();
    }

    String mod_path = path.substr(6); // Remove "mod://"
    int slash_pos = mod_path.find("/");
    if (slash_pos == -1) {
        UtilityFunctions::print("ModResourceLoader: Invalid mod path (no slash found): ", path);
        return Variant();
    }
    String mod_name = mod_path.substr(0, slash_pos);
    String asset_path = mod_path.substr(slash_pos + 1);

    UtilityFunctions::print("ModResourceLoader: Parsed mod_name: ", mod_name, ", asset_path: ", asset_path);

    // Convert camelCase to snake_case for directory names
    String mod_dir_name = mod_name.to_lower();
    // Replace any remaining camelCase patterns with underscores
    mod_dir_name = mod_dir_name.replace("basegame", "base_game");

    // Try multiple possible mod locations in order of preference
    PackedStringArray possible_paths;
    
    // 1. First try user://mods (for release builds and user-installed mods)
    possible_paths.append("user://mods/" + mod_dir_name + "/" + asset_path);
    
    // 2. Then try res://mods (for development builds and bundled mods)
    possible_paths.append("res://mods/" + mod_dir_name + "/" + asset_path);
    
    // 3. Also try the original mod name without conversion (for compatibility)
    possible_paths.append("user://mods/" + mod_name + "/" + asset_path);
    possible_paths.append("res://mods/" + mod_name + "/" + asset_path);

    UtilityFunctions::print("ModResourceLoader: Trying possible paths for ", path);
    
    for (int i = 0; i < possible_paths.size(); i++) {
        String full_path = possible_paths[i];
        UtilityFunctions::print("ModResourceLoader: Trying path ", i + 1, ": ", full_path);
        
        if (FileAccess::file_exists(full_path)) {
            UtilityFunctions::print("ModResourceLoader: File exists, attempting to load: ", full_path);
            Ref<Resource> res = ResourceLoader::get_singleton()->load(full_path);
            if (res.is_valid()) {
                UtilityFunctions::print("ModResourceLoader: Successfully loaded resource: ", full_path, ", resource type: ", res->get_class());
                return res;
            } else {
                UtilityFunctions::print("ModResourceLoader: Failed to load resource: ", full_path);
            }
        } else {
            UtilityFunctions::print("ModResourceLoader: File does not exist: ", full_path);
        }
    }
    
    UtilityFunctions::print("ModResourceLoader: No valid path found for: ", path);
    return Variant();
} 