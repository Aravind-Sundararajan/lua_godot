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