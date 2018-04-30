--[[
MIT License

Copyright (c) 2018 Luca Anzalone

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
-------------------------------------------------------------------------------
local setmetatable = setmetatable 
local assert = assert 
local select = select 
local insert = table.insert 
local remove = table.remove 
local concat = table.concat 
local maxlen = table.maxn 
local format = string.format 
local random = math.random 
local floor  = math.floor 
local abs    = math.abs 
local type   = type 
-------------------------------------------------------------------------------
math.randomseed(os.time())
-------------------------------------------------------------------------------
-- assertions / warnings
-------------------------------------------------------------------------------
local function assert_init(t)
    assert(type(t) == "table", 
        format("[Table.init()] optional parameter <table> must be a not-nil table!", msg))
end

local function assert_table(msg, t)
    assert(type(t) == "table", 
        format("[Table.%s()] parameter <table> must be a not-nil table!", msg))
end

local function assert_table_func(msg, t, f)
    assert(type(t) == "table", 
        format("[Table.%s()] require a not-nil table!", msg))

    assert(type(f) == "function", 
        format("[Table.%s()] require a not-nil function!", msg))
end

local function assert_number(fn, num)
    assert(type(num) == "number", 
        format("[Table.%s()] require a number!", fn))
end
-------------------------------------------------------------------------------
-- LuaTable: lua tables with steroids
-------------------------------------------------------------------------------
local Table = {
    __VERSION = "0.1",
    __AUTHOR  = "Luca Anzalone",
}

function Table.methods()
    -- print all module methods name
    local t = getmetatable(Table).__index

    for k, _ in pairs(t) do
        print(k)
    end
end

local mt = nil
-------------------------------------------------------------------------------
-- operators (use these with map, reduce, each, ecc..)
-------------------------------------------------------------------------------
function Table.void()
end

function Table.nils(a)
    return a == nil
end

function Table.odd(a)
    return a % 2 == 1
end

function Table.even(a)
    return a % 2 == 0
end

function Table.half(a)
    return a * .5
end

-- square

-- square_root

Table.abs = abs

function Table.double(a)
    return a * 2
end

function Table.positive(a)
   return a >= 0
end

function Table.negative(a)
   return a < 0
end

function Table.asc_compare(a, b)
    return a >= b
end

function Table.dsc_compare(a, b)
    return a <= b
end
-------------------------------------------------------------------------------
-- Iterator and for-each
-------------------------------------------------------------------------------
local function iter(table)
    -- build an iterator over the given table
    assert_table("iter", table)

    local i = 1

    return function()
        local v = table[i]
        i = i + 1

        return v
    end
end

local function range(table, start, count, step)
    -- build a range iterator over a table
    assert_table("range", table)

    step  = step  or 1
    count = count or 0
    start = start or 1

    local i = start
    local c = count

    return function()

        if c > 0 then
            local v = table[i]
            i = i + step
            c = c - 1

            return v
        end
    end
end

local function step(table, start, step)
    -- build a step iterator over a table
    assert_table("step", table)

    step  = step  or 1
    start = start or 1

    local i = start

    return function()
        local v = table[i]
        i = i + step

        return v
    end
end

local function eachi(table, func)
    -- apply the given function to all elements of the table (int indexes)
    assert_table_func("each", table, func)

    local len = #table

    for i = 1, len do
        func(table[i])
    end

    return table
end

local function each(table, func)
    -- apply the given function on all (key, value) pairs of table
    assert_table_func("eachKeys", table, func)

    for k, v in pairs(table) do
        func(k, v)
    end

    return Table(table)
end
-------------------------------------------------------------------------------
-- Functional utils
-------------------------------------------------------------------------------
local function map(table, transform)
    -- returns a new table which elements are the result of applying the transformation function
    assert_table_func("map", table, transform)

    local len = #table
    local map = {}

    for i = 1, len do
        map[i] = transform(table[i])
    end

    return Table(map)
end

local function accept(table, criteria)
    -- accept elements that matches the criteria
    assert_table_func("accept", table, criteria)

    local len, k = #table, 1
    local subset = {}

    for i = 1, len do
        local item = table[i]

        if criteria(item) then
            subset[k] = item
            k = k + 1
        end
    end

    return Table(subset)
end

local function reject(table, criteria)
    -- remove elements that matches the criteria
    assert_table_func("reject", table, criteria)

    local len, k = #table, 1
    local subset = {}

    for i = 1, len do
        local item = table[i]

        if not criteria(item) then
            subset[k] = item
            k = k + 1
        end
    end

    return Table(subset)
end

local function reduce(table, base, reduction)
    -- reduce a table into a single value, base is the initial value
    assert_table_func("reduce", table, reduction)

    local value = base
    local len = #table

    for i = 1, len do
        value = reduction(value, table[i])
    end

    return value
end

local function flatten(table)
    -- flattens a nested table (over int indexes)
    assert_table("flatten", table)

    local t = {}
    local k = 1
    local q = { table }
    local n = 1

    while n > 0 do
        local item = remove(q, n)
        local l = #item
        n = n - 1      

        for i = 1, l do
            local v = item[i]

            if type(v) == "table" then
                n = n + 1
                insert(q, n, v)
            else
                t[k] = v
                k = k + 1
            end
        end
    end

    return Table(t)
end

local function flatten2(table)
    -- flattens a nested table (over all key-value pairs)
    assert_table("flatten2", table)

    local t = {}
    local k = 1
    local q = { table }
    local n = 1

    while n > 0 do
        local item = remove(q, n)
        n = n - 1

        for _, v in pairs(item) do

            if type(v) == "table" then
                n = n + 1
                insert(q, n, v)
            else
                t[k] = v
                k = k + 1
            end
        end
    end

   return Table(t)
end
-------------------------------------------------------------------------------
-- Table utils
-------------------------------------------------------------------------------
local function removeNils(table)
    -- remove all nil values along all key-value pairs (event nested) 
    assert_table("removeNils", table)

    local t, i = {}, 1

    for k, v in pairs(table) do
        if type(v) == "table" then
            v = removeNils(v)
        end

        if type(k) == "number" then
            t[i] = v
            i = i + 1
        else
            t[k] = v
        end
    end

    return Table(t)
end

local function max(table, comparator)
    -- return the biggest value of the input based on a comparator
    assert_table("max", table)
    comparator = comparator or Table.asc_compare

    local max = table[1]
    local len = #table

    for i = 2, len do
        local item = table[i]

        if comparator(item, max) then
            max = item
        end
    end

    return max, table
end

local function min(table, comparator)
    -- return the smallest value of the input based on a comparator
    assert_table("min", table)
    comparator = comparator or Table.dsc_compare

    local min = table[1]
    local len = #table

    for i = 2, len do
        local item = table[i]

        if comparator(item, min) then
            min = item
        end
    end

    return min, table
end

local function sum(table)
    -- returns the sum of all elements of the table
    assert_table("sum", table)

    local len = #table
    local sum = 0

    for i = 1, len do
        sum = sum + table[i]
    end

    return sum, table
end

-- mul, sub, div

local function sample(table)
    -- returns a random element of the table
    assert_table("sample", table)

    local size = #table

    if size == 0 then
        return nil
    end

    return table[random(size)]
end

local function shuffle(table)
    -- mix the values inside the given table
    assert_table("shuffle", table)

    local len = #table

    for i = 1, len do
        local k = random(len)

        table[i], table[k] = table[k], table[i]
    end

    return table
end

local function keys(table)
    -- return a table of keys
    assert_table("keys", table)

    local keys = {}
    local i = 1

    for k, _ in pairs(table) do
        keys[i] = k
        i = i + 1
    end

    return Table(keys)
end

local function values(table)
    -- return a table of values
    assert_table("values", table)

    local values = {}

    for i, v in ipairs(table) do
        values[i] = v
    end

    return Table(values)
end

local function reverse(table)
    -- return a table which values are in opposite order
    assert_table("reverse", table)

    local n = floor(#table * .5)

    for i = 1, n do
      local k = n - i + 1
        local x = table[i]
        local y = table[k]

        table[i], table[k] = y, x
    end

    return table
end

local function copy(table)
    -- copy each key-value of the input table
    assert_table("copy", table)

    local clone = {}

    for k, v in pairs(table) do
        clone[k] = v
    end

    return Table(clone)
end

local function deepCopy(table)
    -- deepCopy each key-value of the input table into a new table
    assert_table("deepCopy", table)
    
    local clone = {} 

    for k, v in pairs(table) do
        if type(v) == "table" then
            v = copy(v)
        end
           
        clone[k] = v
    end

    return Table(clone)
end

local function pack(...)
    -- pack a sequence of elements into a single table (keeping nils)
    return Table { select(1, ...) }
end

local function pack2(...)
    -- pack a sequence of elements into a single table (whithout nils)
    local temp = { select(1, ...) }
    local data = {}
    local n, k = maxlen(temp), 1

    for i = 1, n do
        local value = temp[i]

        if not (value == nil) then
            data[k] = value
            k = k + 1
        end

        temp[i] = nil
    end

    return Table(data)
end

local function tostring(table, tab)
    tab = tab or "  "

    local b = { "Table [" }
    local i = 2

    for k, v in pairs(table) do
        if type(v) == "table" then
            b[i] = format(tab .. "k: %s, v: %s", k, tostring(v, tab .. "  "))
        else
            b[i] = format(tab .. "k: %s, v: %s", k, v)
        end

        i = i + 1
    end

    b[i] = (tab .. "]"):sub(3)

    return concat(b, "\n")
end

local function init(self, ...)

    if arg then
        self = { select(1, ...) }

        if #self == 1 and type(self[1] == "table") then
            self = self[1]
        end
    end

   return setmetatable(self, mt)     
end
-------------------------------------------------------------------------------
-- table init helpers
-------------------------------------------------------------------------------
function Table.zeros(size)
    -- fill the table with zeros
    assert_number("zeros", size)

    local t = {}

    for i = 1, size do
        t[i] = 0
    end

    return Table(t)
end

function Table.ones(size)
    -- fill the table with ones
    assert_number("ones", size)

    local t = {}

    for i = 1, size do
        t[i] = 1
    end

    return Table(t)
end

function Table.create(size, init_val)
    -- fill the table with a custom init-value
    assert_number("create", size)

    local t = {}

    for i = 1, size do
        t[i] = init_val
    end

    return Table(t)
end
-------------------------------------------------------------------------------
-- class metatable
-------------------------------------------------------------------------------
mt = {
    __index = {
        -- functional
        map = map,
        accept = accept,
        reject = reject,
        reduce = reduce,
        flatten  = flatten,
        flatten2 = flatten2,

        -- iterators
        iter  = iter,
        each  = each,
        eachi = eachi,
        step  = step,
        range = range,

        -- table utils
        max = max,
        min = min,
        sum = sum,
        keys = keys,
        copy = copy,
        pack = pack,
        pack2 = pack2,
        values = values,
        sample = sample,
        shuffle = shuffle,
        reverse = reverse,
        deepCopy = deepCopy,
        removeNils = removeNils,

        -- init helpers
    },

    __tostring  = tostring,
    __call = init,
}
-------------------------------------------------------------------------------
return setmetatable(Table, mt)
-------------------------------------------------------------------------------