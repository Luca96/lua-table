-------------------------------------------------------------------------------
-- LuaTable: lua tables with steroids
-------------------------------------------------------------------------------
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
local tsort  = table.sort 
local format = string.format 
local random = math.random 
local floor  = math.floor 
local abs    = math.abs 
local print  = print 
local pairs  = pairs 
local ipairs = ipairs 
local type   = type 
-------------------------------------------------------------------------------
math.randomseed(os.time())
-------------------------------------------------------------------------------
-- assertions / warnings
-------------------------------------------------------------------------------
local warn = "\27[1;33mWarning at\27[0m"
local term = "\27[1;36m>>>\27[0m"
local err  = "\27[1;31mError at\27[0m"

local function assert_init(t)
    assert(type(t) == "table", 
        format("%s Table.init(): optional parameter <table> must be a not-nil table!", 
            err, msg))
end

local function assert_table(msg, t)
    assert(type(t) == "table", 
        format("%s Table.%s(): parameter <table> must be a not-nil table!", 
            err, msg))
end

local function assert_table_func(msg, t, f)
    assert(type(t) == "table", 
        format("%s Table.%s(): require a not-nil table!", err, msg))

    assert(type(f) == "function", 
        format("%s Table.%s(): require a not-nil function!", err, msg))
end

local function assert_number(fn, num)
    assert(type(num) == "number", 
        format("%s Table.%s(): require a number!", err, fn))
end

local function assert_true(f, msg, test)
    assert(test, format("%s Table.%s(): %s", err, f, msg))
end

local function warn_nil(fn, value)
    if value == nil then
        print(format("%s %s Table.%s(): nil value", term, warn, fn))
    end
end

local function warn_if(f, msg, test)
    if test then
        print(format("%s %s Table.%s(): %s", term, warn, f, msg))
    end
end
-------------------------------------------------------------------------------
-- CLASS
-------------------------------------------------------------------------------
local Table = {
    __VERSION = "0.3",
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
    -- build an iterator through the given table
    assert_table("iter", table)

    local i = 1

    return function()
        local v = table[i]
        i = i + 1

        return v
    end
end

local function inverse(table)
    -- build an iterator that iterate, through the table, in reversed order
    assert_table("reverseIter", table)

    local n = #table

    return function()
        local v = table[n]
        n = n - 1

        return v
    end
end

local function range(table, start, count, step)
    -- build a range iterator over a table
    assert_table("range", table)
    assert_number("range", start)
    assert_number("range", count)
    assert_number("range", step)

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
    assert_number("range", start)
    assert_number("step", step)

    step  = step  or 1
    start = start or 1

    local i = start

    return function()
        local v = table[i]
        i = i + step

        return v
    end
end

local function group(table, k)
    -- iterate through table by grouping values together (group size is k)
    -- in each iteration, the iterator will return a k-tuple
    assert_table("group", table)
    assert_true("group", "k must be > 0!", (type(k) == "number") and (k > 0))

    local i = 0

    return function()
        local values = {}

        for j = 1, k do
            values[j] = table[i + j]
        end

        i = i + k

        return unpack(values)
    end
end

local function slide(table, k)
    -- iterate through table like a sliding-window of size k
    -- in each iteration, the iterator will return a k-tuple
    assert_table("slide", table)
    assert_true("slide", "k must be > 0!", (type(k) == "number") and (k > 0))
    
    local i = 0

    return function()
        local values = {}

        for j = 1, k do
            values[j] = table[i + j]
        end

        i = i + 1

        return unpack(values)
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
    -- returns a new table without nils along all key-value pairs (even nested) 
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

local function mul(table)
    -- returns the product of all elements of the table
    assert_table("mul", table)    

    local len = #table
    local mul = 0

    for i = 1, len do
        mul = mul * table[i]
    end

    return mul, table
end

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

local function slice(table, i, j)
    -- return a portion of the input table that ranges to i from j
    -- nil values are ignored
    assert_table("slice", table)

    j = j or #table
    i = i or 1

    assert_number("slice", i)
    assert_number("slice", j)
    warn_if("slice", i .. " > " .. j, i > j)

    local part = {}
    local n = 1

    for k = i, j do
        local v = table[k]

        if not (v == nil) then
            part[n] = v
            n = n + 1
        end
    end

    return Table(part)
end

local function clone(table)
    -- clone each key-value of the input table into a new table
    assert_table("clone", table)
    
    local copy = {} 

    for k, v in pairs(table) do
        if type(v) == "table" then
           v = clone(v)
        end
           
        copy[k] = v
    end

    return Table(copy)
end

local function pack(...)
    -- pack a sequence of elements into a single table (keeps nils)
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

local function merge(t1, t2)
    -- return a new table which values are taken by both t1 and t2
    -- it consider only values over integer indexes.
    assert_table("merge", t1)
    assert_table("merge", t2)

    local merged = {}
    local k = 1

    for i = 1, #t1 do
        merged[k] = t1[i]
        k = k + 1
    end

    for i = 1, #t2 do
       merged[k] = t2[i]
        k = k + 1
    end

    return Table(merged)
end

local function sort(table, comparator)
    -- sort the table according to the comparator function
    assert_table("sort", table)

    comparator = comparator or asc_compare
    tsort(table, comparator)

    return table
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
-------------------------------------------------------------------------------
-- table operators
-------------------------------------------------------------------------------
local function at(table, index, default_value)
    -- returns the element at the given index, if index is negative it starts
    -- counting from the end of the table and then returning the element.
    -- at works with integer indexes, use get for other key-values (index).
    -- optionally you can specify a default-value that is returned in case
    -- table[index] is nil.
    assert_number("at", index)

    -- positive index
    if index >= 0 then
        return table[index] or default_value
    end

    -- negative index
    return table[#table + index + 1]
end

local function get(table, key, default_value)
    -- returns the element at the given key, if element is nil it returns an 
    -- optional default value
    return table[key] or default_value
end

local function append(table, ...)
    -- insert one or more elements at the end of the table
    warn_nil("append", ...)

    local sequence = { select(1, ...) }

    for i = 1, #sequence do
        insert(table, sequence[i])
    end

    return table
end

local function push(table, ...)
    -- insert one or more elements at the begin of the table
    warn_nil("push", ...)

    local sequence = { select(1, ...) }

    for i = 1, #sequence do
        insert(table, 1, sequence[i])
    end

    return table
end

local function pop(table)
    -- remove and return the last element into the table
    return remove(table, #table)
end

local function last(table)
    -- return the last element into the table
    return table[#table]
end

local function first(table)
    -- return the first value into the table
    return table[1]
end

local function clear(table)
    -- empties the given table
    local n = #table

    for i = 1, n do
        table[i] = nil
    end
end

local function empty(table)
    -- check if the table has 0 elements, it not consider keys.
    return #table == 0
end

local function notEmpty(table)
    -- check if the table has at least one elements, it not consider keys.
    return #table > 0
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
-- constructor
-------------------------------------------------------------------------------
local function init(self, ...)

    if arg then
        self = { select(1, ...) }

        if #self == 1 and type(self[1]) == "table" then
            self = self[1]
        end
    end

   return setmetatable(self, mt)     
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
        group = group,
        slide = slide,
        inverse = inverse,

        -- table utils
        max = max,
        min = min,
        sum = sum,
        mul = mul,
        keys = keys,
        sort = sort,
        pack = pack,
        pack2 = pack2,
        clone = clone,
        slice = slice,
        merge = merge,
        values = values,
        sample = sample,
        shuffle = shuffle,
        reverse = reverse,
        removeNils = removeNils,

        -- table operators
        at  = at,
        get = get,
        pop = pop,
        last = last,
        push = push,
        first = first,
        empty = empty,
        clear = clear,
        append = append,
        notEmpty = notEmpty,
    },

    __tostring  = tostring,
    __call = init,
}
-------------------------------------------------------------------------------
return setmetatable(Table, mt)
-------------------------------------------------------------------------------