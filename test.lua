-- Test Lua file for Godot Lua Bridge
print("Loading test.lua file...")

-- Define some test functions
function calculate_fibonacci(n)
    if n <= 1 then
        return n
    else
        return calculate_fibonacci(n - 1) + calculate_fibonacci(n - 2)
    end
end

function create_table()
    local t = {}
    for i = 1, 5 do
        t[i] = i * i
    end
    return t
end

-- Set some global variables
PI = 3.14159
GREETING = "Hello from test.lua!"

print("test.lua loaded successfully!")

-- Test script for registered Godot functions
print("=== Lua Script Testing Registered Functions ===")

-- Call the registered Godot functions
print("Calling godot_hello():", godot_hello())

-- Test addition function
local result1 = godot_add(5, 3)
print("godot_add(5, 3) =", result1)

local result2 = godot_add(10.5, 2.5)
print("godot_add(10.5, 2.5) =", result2)

-- Test with more arguments (should work, extra args will be ignored)
local result3 = godot_add(100, 200, 300, 400)
print("godot_add(100, 200, 300, 400) =", result3)

-- Test with different argument types
local result4 = godot_add("hello", "world")  -- Should return 0 for non-numeric args
print("godot_add('hello', 'world') =", result4)

-- Test calling from within a Lua function
function test_registered_functions()
    print("Testing from within Lua function:")
    print("  godot_hello() =", godot_hello())
    print("  godot_add(7, 8) =", godot_add(7, 8))
end

test_registered_functions()

print("=== End of Lua Script ===") 