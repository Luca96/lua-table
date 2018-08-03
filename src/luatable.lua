-----------------------------------------------------------------------------------------
-- LuaTable: lua tables with superpowers
-----------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable 
local assert = assert 
local unpack = unpack 
local select = select 
local error  = error 
local print  = print 
local pairs  = pairs 
local ipairs = ipairs 
local type   = type 
local insert = table.insert 
local remove = table.remove 
local concat = table.concat 
local format = string.format 
local random = math.random 
local floor  = math.floor 
local abs    = math.abs
local len    = string.len 
-----------------------------------------------------------------------------------------
-- assertions / warnings
-----------------------------------------------------------------------------------------
local warn = "\27[1;33mWarning at\27[0m"
local term = "\27[1;36m>>>\27[0m"
local err  = "\27[1;31mError at\27[0m"

local function assert_init(t)
    assert(type(t) == "table", 
        format("%s table.init(): optional parameter <table> must be a not-nil table!", 
            err, msg))
end

local function assert_table(msg, t)
    assert(type(t) == "table", 
        format("%s table.%s(): parameter <table> must be a not-nil table!", 
            err, msg))
end

local function assert_table_func(msg, t, f)
    assert(type(t) == "table", 
        format("%s table.%s(): require a not-nil table!", err, msg))

    assert(type(f) == "function", 
        format("%s table.%s(): require a not-nil function!", err, msg))
end

local function assert_number(fn, num)
    assert(type(num) == "number", 
        format("%s table.%s(): require a number!", err, fn))
end

local function assert_true(f, msg, test)
    assert(test, format("%s table.%s(): %s", err, f, msg))
end

local function warn_nil(fn, value)
    if value == nil then
        print(format("%s %s table.%s(): nil value", term, warn, fn))
    end
end

local function warn_if(f, msg, test)
    if test then
        print(format("%s %s table.%s(): %s", term, warn, f, msg))
    end
end
-----------------------------------------------------------------------------------------
-- CLASS
-----------------------------------------------------------------------------------------
local table = table

function table.tostring(t, tab)
-- returns a string representation of the given table
   tab = tab or "  "

   local b = { "table [" }
   local i = 2

   for k, v in pairs(t) do
      if v == nil then
         v = ''
         
      elseif type(v) == "table" then
         b[i] = format(tab .. "k: %s, v: %s", k, table.tostring(v, tab .. "  "))

      elseif type(v) ~= "userdata" then
         b[i] = format(tab .. "k: %s, v: %s", k, v)
      end

      i = i + 1
   end

   b[i] = (tab .. "]"):sub(3)

   return concat(b, "\n")
end

function table.info()
-- print library info
   print [[
   luatable [
      version: 0.7,
      author: Luca Anzalone,
      github: https://github.com/Luca96/lua-table
   ]
   ]]
end

local mt = { __index = table, __tostring = table.tostring }
-----------------------------------------------------------------------------------------
-- operators (use these with map, reduce, each, ecc..)
-----------------------------------------------------------------------------------------
function table.void()
end

function table.isnil(a)
   return a == nil
end

function table.odd(a)
   return a % 2 == 1
end

function table.even(a)
   return a % 2 == 0
end

function table.half(a)
   return a * .5
end

function table.double(a)
   return a * 2
end

function table.sqr(a)
   return a * a
end

function table.pow(a, b)
   return a ^ b
end

function table.increase(a)
   return a + 1
end

function table.decrease(a)
   return a - 1
end

function table.positive(a)
   return a >= 0
end

function table.negative(a)
   return a < 0
end

function table.itself(a)
   return a
end

function table.identity(a)
   return a == a
end

function table.eq(a, b)
   return a == b
end

function table.neq(a, b)
   return a ~= b
end

function table.gt(a, b)
   return a > b
end

function table.lt(a, b)
   return a < b
end

function table.ge(a, b)
   return a >= b
end

function table.le(a, b)
   return a <= b
end

function table.sum(a, b)
   return a + b
end

function table.sub(a, b)
   return a - b
end

function table.mul(a, b)
   return a * b
end

function table.div(a, b)
   return a / b
end
-----------------------------------------------------------------------------------------
-- iterators
-----------------------------------------------------------------------------------------
function table.iter(t)
-- build an iterator through the given table
   assert_table("iter", t)

   local i = 1

   return function()
      local v = t[i]
      i = i + 1

      return v
   end
end

function table.inverse(t)
-- build an iterator that iterate in reversed order
   assert_table("inverse", t)

   local i = #t

   return function()
      local v = t[i]
      i = i - 1

      return v
   end
end

function table.range(t, start, count, step)
-- build a range iterator
   assert_table ("range", t)
   
   step  = step  or 1
   count = count or #t
   start = start or 1

   assert_number("range", start)
   assert_number("range", count)
   assert_number("range", step)

   local i = start
   local c = count

   return function()

      if c > 0 then
         local k = i
         local v = t[i]
         i = i + step
         c = c - 1

         return k, v
      end
   end
end

function table.group(t, k)
-- iterate through table by grouping values together (group size is k)
-- in each iteration, the iterator will return a k-tuple
   assert_table("group", t)
   assert_true ("group", "k must be > 0!", (type(k) == "number") and (k > 0))

   local i = 0

   return function()
      local values = {}

      for j = 1, k do
         values[j] = t[i + j]
      end

      i = i + k

      return unpack(values)
   end
end

function table.slide(t, k)
-- iterate through table like a sliding-window of size k
-- in each iteration, the iterator will return a k-tuple
   assert_table("slide", t)
   assert_true ("slide", "k must be > 0!", (type(k) == "number") and (k > 0))
    
   local i = 0

   return function()
      local values = {}

      for j = 1, k do
         values[j] = t[i + j]
      end

      i = i + 1

      return unpack(values)
   end
end

function table.eachi(t, func, ...)
-- apply the given function to all the elements of the table
   assert_table_func("eachi", t, func)

   for i = 1, #t do
      func(t[i], ...)
   end

   return t
end

function table.each(t, func, ...)
-- apply the given function on all (key, value) pairs of table
   assert_table_func("each", t, func)

   for k, v in pairs(t) do
      func(k, v, ...)
   end

   return t
end

function table.keys(t)
-- iterate over all table keys 
   assert_table("keys", t)

   local keys = {}
   local j = 1

   for k, _ in pairs(t) do
      keys[j] = k
      j = j + 1
   end

   j = 1

   return function()
      local k = keys[j]
      j = j + 1

      return k
   end
end

function table.values(t)
-- iterate over all table values
   assert_table("values", t)

   local values = {}
   local k = 1

   for _, v in pairs(t) do
      values[k] = v
      k = k + 1
   end

   k = 1

   return function()
      local v = values[k]
      k = k + 1

      return v
   end
end
-----------------------------------------------------------------------------------------
-- functional utils
-----------------------------------------------------------------------------------------
function table.map(t, func, ...)
-- returns a table which elements are the result of applying the transformation function
   assert_table_func("map", t, func)

   local map = table()

   for i = 1, #t do
      map[i] = func(t[i], ...)
   end

   return map
end

function table.reduce(t, base, reduction, ...)
-- reduce a table into a single value according to the reduction function, 
-- base is the initial value of the reduction
   assert_table_func("reduce", t, reduction)

   local value = base

   for i = 1, #t do
      value = reduction(value, t[i], ...)
   end

   return value
end

function table.accept(t, criteria, ...)
-- accept elements that matches the criteria
   assert_table_func("accept", t, criteria)

   local k  = 1
   local tb = table()

   for i = 1, #t do
      local item = t[i]

      if criteria(item, ...) then
         tb[k] = item
         k = k + 1
      end
   end

   return tb
end

function table.reject(t, criteria, ...)
-- remove elements that matches the criteria
   assert_table_func("reject", t, criteria)

   local k  = 1
   local tb = table()

   for i = 1, #t do
      local item = t[i]

      if not criteria(item, ...) then
         tb[k] = item
         k = k + 1
      end
   end

   return tb
end

function table.flat(t)
-- flattens a nested table (over int indices - use table.deepflat instead)
   assert_table("flat", t)

   local queque = { t }
   local result = table()
   local base = 1
   local top  = 1
   local k = 1

   while base <= top do
      local items = queque[base]
      base = base + 1

      for i = 1, #items do
         local v = items[i]

         if type(v) == "table" then
            top = top + 1
            queque[top] = v
         else
            result[k] = v
            k = k + 1
         end
      end
   end

   return result
end

function table.deepflat(t)
-- flattens a nested table over all key-value pairs
   assert_table("deepflat", t)

   local queque = { t }
   local result = table()
   local base = 1
   local top  = 1
   local k = 1

   while base <= top do
      local items = queque[base]
      base = base + 1

      for _, v in pairs(items) do
         if type(v) == "table" then
            top = top + 1
            queque[top] = v
         else
            result[k] = v
            k = k + 1
         end
      end
   end

   return result
end

function table.flatmap(t, func, ...)
-- every element returned by the transformation function is flattened and then added
-- to the output table
   assert_table_func("flatmap", t, func)

   local tb, k = table(), 1
   local flat  = table.flat

   for i = 1, #t do
      local items = flat(func(t[i], ...))

      for j = 1, #items do
         tb[k] = items[j]
         k = k + 1
      end
   end

   return tb
end
-----------------------------------------------------------------------------------------
-- utility
-----------------------------------------------------------------------------------------
function table.purify(t)
-- recursively removes all nil values along all key-value pairs 
   assert_table("purify", t)

   local tb = table()
   local i  = 1

   for k, v in pairs(t) do
      if type(v) == "table" then
         v = table.purify(v)
      end

      if type(k) == "number" then
         tb[i] = v
         i = i + 1
      else
         tb[k] = v
      end
   end

   return tb
end

function table.max(t, comparator)
-- return the biggest value inside the table in base of a comparator function
   comparator = comparator or Table.ge
   assert_table_func("max", t, comparator)

   local max = t[1]

   for i = 2, #t do
      local item = t[i]

      if comparator(item, max) then
         max = item
      end
   end

   return max
end

function table.min(t, comparator)
-- return the smallest value inside the table in base of a comparator function
   comparator = comparator or Table.ge
   assert_table_func("min", t, comparator)

   local max = t[1]

   for i = 2, #t do
      local item = t[i]

      if comparator(item, max) then
         max = item
      end
   end

   return max
end

function table.avg(t)
-- return the average value inside table
   assert_table("avg", t)

   local avg = t[1]
   local len = #t

   if avg == nil then
      return 0
   end

   for i = 2, len do
      avg = avg + t[i]
   end

   return avg / len
end

function table.maximize(t, func, ...)
-- return the value of the table that maximize the function value
   assert_table_func("maximize", t, func)

   local max_val = t[1]
   local max_fun = func(max_val, ...)

   for i = 2, #t do
      local val  = t[i]
      local fval = func(val, ...)

      if fval > max_fun then
         max_fun = fval
         max_val = val
      end
   end

   return max_val
end

function table.minimize(t, func, ...)
-- return the value of the table that minimize the function value
   assert_table_func("minimize", t, func)

   local min_val = t[1]
   local min_fun = func(min_val, ...)

   for i = 2, #t do
      local val  = t[i]
      local fval = func(val, ...)

      if fval < min_fun then
         min_fun = fval
         min_val = val
      end
   end

   return min_val
end

function table.sample(t)
-- returns a random element of the table
   assert_table("sample", t)

   local size = #t

   if size > 0 then
      return t[random(size)]
   end
end

function table.shuffle(t)
-- mix the values inside the given table
   assert_table("shuffle", t)

   local len = #t

   for i = 1, len do
      local k = random(len)
      t[i], t[k] = t[k], t[i]
   end

   return t
end

function table.reverse(t)
-- return a table which values are in opposite order
   assert_table("reverse", t)

   local n = #t
   local m = floor(n * .5)

   for i = 1, m do
      local k = n - i + 1
      t[i], t[k] = t[k], t[i]
   end

   return t
end

function table.slice(t, i, j)
-- return a portion of the input table that ranges to i from j
-- nil values are ignored
   assert_table("slice", t)
   local n = #t
   j = j or n
   i = i or 1
   assert_number("slice", i)
   assert_number("slice", j)

   if i < 0 then
      i = n + 1 + i
      if i < 1 then i = 1 end
   end

   if j < 0 then
      j = n + 1 + j
      if j < 1 then j = 1 end
   end

   warn_if("slice", i .. " > " .. j, i > j)

   local part = table()
   local n = 1

   for k = i, j do
      local v = t[k]

      if v ~= nil then
         part[n] = v
         n = n + 1
      end
   end

   return part
end

function table.find(t, value)
-- find a value inside the given table, it returns the value's index
-- of the first occurrence if finded otherwise it returns nil
   assert_table("find", t)

   for i = 1, #t do
      if t[i] == value then
         return i
      end
   end

   return nil
end

function table.clone(t)
-- clone recursively each key-value pair of the input table
   assert_table("clone", t)
    
   local copy = table()

   for k, v in pairs(t) do
      if type(v) == "table" then
         v = table.clone(v)
      end
      
      copy[k] = v
   end

   return copy
end

function table.merge(t1, t2)
-- return a new table which values are taken by both t1 and t2
-- it doesn't remove duplicates (use table.union instead)
   assert_table("merge", t1)
   assert_table("merge", t2)

   local merged = table()
   local k = 1

   for i = 1, #t1 do
      merged[k] = t1[i]
      k = k + 1
   end

   for i = 1, #t2 do
      merged[k] = t2[i]
      k = k + 1
   end

   return merged
end

function table.unique(t)
-- remove all duplicates in table (useful to create a table as a set)
   assert_table("unique", t)

   local set = table()
   local tmp = {}
   local k = 1

    for i = 1, #t do
        local v = t[i]

        if tmp[v] == nil then
            tmp[v] = true
            set[k] = v
            k = k + 1
        end
    end

    return set
end

function table.keyList(t)
-- return a list of keys of the given table
   assert_table("keyList", t)

   local list = table()
   local i = 1

   for k, _ in pairs(t) do
      list[i] = k
      i = i + 1
   end

   return list
end

function table.valueList(t)
-- return a list of values of the given table
   assert_table("valueList", t)

   local list = table()
   local k = 1

   for _, v in pairs(t) do
      list[k] = v
      k = k + 1
   end

   return list
end

function table.valueSequence(t)
-- return a sequence of values, instead of valueList it consider only 
-- elements from index 1 to #table (values along keys are ignored)
   assert_table("valueSequence", t)

   local seq = table()

   for i = 1, #t do
        seq[i] = t[i]
   end

   return seq
end

function table.equal(t1, t2, deep)
-- check if t1 contains the same elements contained in t2, if deep is true
-- the equality is spread among all key-value pairs (so not only to int indices)
   deep = deep or false
   assert_table("equal", t1)
   assert_table("equal", t2)

   local v1 = deep and table.deepflat(t1) or table.flat(t1) 
   local v2 = deep and table.deepflat(t2) or table.flat(t2)
   local l1 = #v1
   local l2 = #v2

   if l1 == l2 then
      -- compare each values
      for i = 1, l1 do
         if v1[i] ~= v2[i] then
            return false
         end
      end

      return true
   end

   return false
end

function table.all(t, predicate)
-- returns true if all elements of table t satisfy the given predicate
   assert_table_func("all", t, predicate)

   for i = 1, #t do
      if not predicate(t[i]) then
         return false
      end
   end

   return true
end

function table.allPairs(t, predicate)
-- returns true if all key-pair elements of table t satisfy the given predicate
   assert_table_func("allPairs", t, predicate)

   for _, v in pairs(t) do
      if not predicate(v) then
         return false
      end
   end

   return true
end

function table.any(t, predicate)
-- returns true if at least an elements of table t satisfy the given predicate
   assert_table_func("any", t, predicate)

   for i = 1, #t do
      if predicate(t[i]) then
         return true
      end
   end

   return false
end

function table.anyPairs(t, predicate)
-- returns true if at least a key-pair of table t satisfy the given predicate
   assert_table_func("anyPairs", t, predicate)

   for _, v in pairs(t) do
      if predicate(v) then
         return true
      end
   end

   return false
end
-----------------------------------------------------------------------------------------
-- set utility
-----------------------------------------------------------------------------------------
function table.union(t1,  t2)
-- return a new table that is the union of t1 and t2
   assert_table("union", t1)
   assert_table("union", t2)

   local tb = table()
   local k  = 1 

   for i = 1, #t1 do
      tb[k] = t1[i]
      k = k + 1
   end

   for i = 1, #t2 do
      tb[k] = t2[i]
      k = k + 1
   end

   return tb:unique() 
end

function table.negation(t1, t2)
-- return a new table which values are in t1 but not in t2
   assert_table("negation", t1)
   assert_table("negation", t2)

   local diff = table()
   local keys = {}
   local size = #t1
   local k = 1
    
   for _, v in ipairs(t2) do
      keys[v] = true
   end

   for i = 1, size do
      local v = t1[i]

      if not keys[v] then
         diff[k] = v
         k = k + 1
      end
   end
    
   return diff
end

function table.intersect(t1, t2)
-- return a new table which values are both in t1 and t2
   assert_table("intersect", t1)
   assert_table("intersect", t2)

   local set = {}
   local len = #t1
   local t = table()
   local k = 1

   for _, v in ipairs(t2) do
      set[v] = true
   end

   for i = 1, len do
      local v = t1[i]

      if set[v] then
         t[k] = v
         k = k + 1
      end
   end

   return t
end

function table.keySet(t)
-- return a set of keys of the given table
   assert_table("keySet", t)

   local set = table()

   for k, _ in pairs(t) do
      set[k] = true
   end

   return set
end

function table.valueSet(t)
-- return a set of values of the given table
   assert_table("valueSet", t)

   local set = table()

   for _, v in pairs(t) do
      set[v] = true
   end

   return set
end
-----------------------------------------------------------------------------------------
-- table operators (no table check on self!)
-----------------------------------------------------------------------------------------
function table:at(index, default)
-- returns the element at the given index, if index is negative it starts
-- counting from the end of the table and then returning the element.
-- 'at' works with integer indices, use get for other key-values (as index).
-- optionally you can specify a default-value that is returned in case
-- table[index] is nil.
   assert_number("at", index)

   -- positive index
   if index >= 0 then
      return self[index] or default
   end

   -- negative index
   return self[#self + index + 1] or default
end

function table:get(key, default)
-- returns the element at the given key, if element is nil it returns an 
-- optional default value
   return self[key] or default
end

function table:append(...)
-- insert one or more elements at the end of the table
   local len = #self
   local elements = { ... }

   for i = 1, #elements do
      self[len + i] = elements[i]
   end

   return self
end

function table:push(...)
-- insert one or more elements at the begin of the table
   local elements = { ... }

   for i = #elements, 1, -1 do
      insert(self, 1, elements[i])
   end

   return self
end

function table:pop()
-- remove and return the last element into the table
   return remove(self, #self)
end

function table:head()
-- remove and return the first element into the table
   return remove(self, 1)
end

function table:last()
-- return the last element into the table
   return self[#self]
end

function table:first()
-- return the first value into the table
   return self[1]
end

function table:clear(remove_pairs)
-- empties the given table, if remove_pairs is true: all key-val pairs will be removed
   if remove_pairs == true then
      -- 
      for k, v in pairs(self) do
         self[k] = nil
      end
   else
      --
      for i = 1, #self do
         self[i] = nil
      end
   end

   return self
end

function table:has(value)
-- return true if it finds the given value, otherwise returns false
   return table.find(self, value) ~= nil
end

function table:haskey(key)
-- returns true if self[key] is not nil
   return self[key] ~= nil
end

function table:empty()
-- check if the table has 0 elements, it not consider key pairs.
   return #self == 0
end

function table:lshift(pos)
-- left shift the content of the table of 'pos' positions. It returns the 
-- shifted elements that are below the first index of the table.
   pos = pos or 0
   assert_true("lshift", type(pos) == "number" and pos >= 0, "<pos> must be a number >= 0!")

   local s, k = {}, 1

   for i = 1, pos do
      s[k] = remove(self, 1)
      k = k + 1
   end

   return unpack(s) 
end

function table:rshift(pos)
-- remove and returns all the elements of the table that are above #self - pos. 
   pos = pos or 0
   assert_true("rshift", type(pos) == "number" and pos >= 0, "<pos> must be a number >= 0!")

   local s, k = {}, 0
   local size = #self

   if size < pos then
      pos = size
   end

   for i = 1, pos do
      s[pos - k] = remove(self, size - i + 1)
      k = k + 1
   end

   return unpack(s)
end

function table:shift(pos)
-- calls table.lshift if pos is negative or table.rshift is pos is positive
   pos = pos or 0
   assert_number("shift", pos)

   if pos >= 0 then
      return table.rshift(self, pos)
   end

   return table.lshift(self, pos * -1)
end
-----------------------------------------------------------------------------------------
-- constructors:
-----------------------------------------------------------------------------------------
function table.new(...)
-- creates an enhanched table
   local t = { ... }

   if #t == 1 and type(t[1]) == "table" then
      -- the table is created from an old one
      t = t[1]
   end

   return setmetatable(t, mt)
end

function table.init(size, def, ...)
-- fill the enhanched table with a custom init value or function
   assert_number("init", size)

   local t = table()

   if type(def) == "function" then
      --
      for i = 1, size do
         t[i] = def(i, ...)
      end
   else        
      --
      for i = 1, size do
         t[i] = def
      end
   end 

   return t
end

function table.zeros(size)
-- fill the enhanched table with zeros
   assert_number("zeros", size)

   local t = table()

   for i = 1, size do
      t[i] = 0
   end

   return t
end

function table.ones(size)
-- fill the enhanched table with ones
   assert_number("ones", size)

   local t = table()

   for i = 1, size do
      t[i] = 1
   end

   return t
end

function table.ofChars(string)
-- create a enhanched table from the given string, which will contains 
-- every single character of the input string
   assert_true("ofChars", "require a valid string!", type(string) == "string")

   local t = table()
   local n = string:len()

   for i = 1, n do
      t[i] = string:sub(i, i)
   end

   return t
end
-----------------------------------------------------------------------------------------
-- operator overload
-----------------------------------------------------------------------------------------
mt.__eq  = table.equal
mt.__add = table.union
mt.__sub = table.negation
mt.__mul = table.intersect
mt.__concat = table.merge
-----------------------------------------------------------------------------------------
return setmetatable(table, { __call = function(t, ...) return table.new(...) end })
-----------------------------------------------------------------------------------------