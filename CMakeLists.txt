cmake_minimum_required(VERSION 3.22)
project(lua_bridge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# Set up Godot C++ bindings
set(GODOT_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/godot-cpp")
set(GODOT_CPP_INCLUDE_DIR "${GODOT_CPP_DIR}/include")
set(GODOT_CPP_GEN_INCLUDE_DIR "${GODOT_CPP_DIR}/gen/include")

# Lua include directory
set(LUA_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lua-5.4.8/src")

# Collect Lua source files
file(GLOB LUA_SOURCES "lua-5.4.8/src/*.c")

# Collect extension source files
file(GLOB EXTENSION_SOURCES "src/*.cpp")

# Build Lua as static library
add_library(lua STATIC ${LUA_SOURCES})
target_include_directories(lua PUBLIC ${LUA_INCLUDE_DIR})

# Build the GDExtension
add_library(lua_bridge SHARED ${EXTENSION_SOURCES})
target_include_directories(lua_bridge PRIVATE 
    ${GODOT_CPP_INCLUDE_DIR}
    ${GODOT_CPP_GEN_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(lua_bridge lua godot-cpp)

# Set output directory
set_target_properties(lua_bridge PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
) 