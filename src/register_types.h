#ifndef LUABRIDGE_REGISTER_TYPES_H
#define LUABRIDGE_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_bridge_module(ModuleInitializationLevel p_level);
void uninitialize_bridge_module(ModuleInitializationLevel p_level);

#endif // LUABRIDGE_REGISTER_TYPES_H