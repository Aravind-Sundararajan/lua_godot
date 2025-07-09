#pragma once

#include <godot_cpp/classes/resource_format_loader.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/string_name.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

using namespace godot;

class ModResourceLoader : public ResourceFormatLoader {
    GDCLASS(ModResourceLoader, ResourceFormatLoader);

public:
    ModResourceLoader() = default;
    ~ModResourceLoader() = default;

    PackedStringArray _get_recognized_extensions() const override;
    bool _recognize_path(const String &path, const StringName &type) const override;
    String _get_resource_type(const String &path) const override;
    Variant _load(const String &path, const String &original_path, bool use_sub_threads, int32_t cache_mode) const override;
    
    // Cleanup method to ensure no references are held
    void cleanup();

protected:
    static void _bind_methods();
}; 