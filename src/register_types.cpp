#include "register_types.h"
#include "mod_resource_loader.h"

#include "bridge.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

// Keep the loader alive for the lifetime of the module
static Ref<ModResourceLoader> mod_loader;

void initialize_lua_bridge_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	ClassDB::register_class<LuaBridge>();
	ClassDB::register_class<LuaSignalRelay>();
}

void uninitialize_lua_bridge_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

void initialize_lua_godot_module(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		initialize_lua_bridge_module(p_level);
		ClassDB::register_class<ModResourceLoader>();

		// Keep the loader alive by storing in a static Ref
		mod_loader.instantiate();
		ResourceLoader::get_singleton()->add_resource_format_loader(mod_loader);
	}
}

void uninitialize_lua_godot_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	
	// Remove the resource loader before cleanup to prevent it from holding references
	if (mod_loader.is_valid()) {
		mod_loader->cleanup();
		ResourceLoader::get_singleton()->remove_resource_format_loader(mod_loader);
		mod_loader.unref();
	}
}

extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT gdext_initialize(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_lua_godot_module);
	init_obj.register_terminator(uninitialize_lua_godot_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}