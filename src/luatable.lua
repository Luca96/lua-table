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
local concat = table.concat 
local maxlen = table.maxn 
local format = string.format 
local random = math.random 
local floor  = math.floor 
local abs    = math.abs 
-------------------------------------------------------------------------------
math.randomseed(os.time())
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

function Table.abs(a)
   return abs(a)
end

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
	local i = 1

	return function()
		local v = table[i]
		i = i + 1

		return v
	end
end

local function range(table, start, count, step)
	-- build a range iterator over a table
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
	step  = step  or 1
	start = start or 1

	local i = start

	return function()
		local v = table[i]
		i = i + step

		return v
	end
end

local function each(table, func)
	-- apply the given function to all elements of the table
	local len = #table

	for i = 1, len do
		func(table[i])
	end

	return Table(table)
end

local function eachKeys(table, func)
	-- apply the given function on all (key, value) pairs of table

	for k, v in pairs(table) do
		func(k, v)
	end

	return Table(table)
end

--[[
local function times(count, func)
	-- execute <func> code multiple times
	for i = 1, count do
		func()
	end
end
--]]
-------------------------------------------------------------------------------
-- Functional utils
-------------------------------------------------------------------------------
local function map(table, transform)
	-- returns a new table which elements are the result of applying the transformation function
	local map = {}
	local len = #table

	for i = 1, len do
		map[i] = transform(table[i])
	end

	return Table(map)
end

local function filter(table, criteria)
	-- remove elements that not matches the criteria
	local set = {}
	local len, k = #table, 1

	for i = 1, len do
		local item = table[i]

		if criteria(item) then
			set[k] = item
			k = k + 1
		end
	end

	return Table(set)
end

local function reject(table, criteria)
	-- remove elements that matches the criteria
	local set = {}
	local len, k = #table, 1

	for i = 1, len do
		local item = table[i]

		if not criteria(item) then
			set[k] = item
			k = k + 1
		end
	end

	return Table(set)
end

local function reduce(table, base, reduction)
	-- reduce a table into a single value, base is the initial value
	local value = base
	local len = #table

	for i = 1, len do
		value = reduction(value, table[i])
	end

	return value --TODO: wrap into a table and apply mt??
end
-------------------------------------------------------------------------------
-- Table utils
-------------------------------------------------------------------------------
local function max(table, comparator)
	-- return the biggest value of the input based on a comparator
	comparator = comparator or Table.asc_compare

	local max = table[1]
	local len = #table

	for i = 2, len do
		local item = table[i]

		if comparator(item, max) then
			max = item
		end
	end

	return max
end

local function min(table, comparator)
	-- return the smallest value of the input based on a comparator
	comparator = comparator or Table.dsc_compare

	local min = table[1]
	local len = #table

	for i = 2, len do
		local item = table[i]

		if comparator(item, min) then
			min = item
		end
	end

	return min
end

local function sum(table)
	-- returns the sum of all elements of the table
	local len = #table
	local sum = 0

	for i = 1, len do
		sum = sum + table[i]
	end

	return sum
end

-- mul, sub, div

local function sample(table)
	-- returns a random element of the table
	return table[random(#table)]
end

local function shuffle(table)
	-- mix the values inside the given table
	local len = #table

	for i = 1, len do
		local index = random(len)

		table[i], table[index] = table[index], table[i]		
	end

	return Table(table)
end

local function keys(table)
	-- return a table of keys
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
	local values = {}

	for i, v in ipairs(table) do
		values[i] = v
	end

	return Table(values)
end

local function reverse(table)
	-- return a table which values are in opposite order
	local n = floor(#table * .5)

	for i = 1, n do
      local k = n - i + 1
		local x = table[i]
		local y = table[k]

		table[i], table[k] = y, x
	end

	return Table(table)
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

local function tostring(table)
	local len = #table
	local buf = { "Table [" }

	for i = 1, len do
		buf[i + 1] = format("  i: %d, value: %s", i, table[i])
	end

	buf[len + 2] = "]"

	return concat(buf, "\n")
end

local function init(self, table)

	if table then
		self = table
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
		filter = filter,
		reject = reject,
		reduce = reduce,

		-- iterators
		iter = iter,
		each = each,
		step = step,
		range = range,
		eachKeys = eachKeys,

		-- table utils
		max = max,
		min = min,
		sum = sum,
		keys = keys,
		pack = pack,
		pack2 = pack2,
		values = values,
		sample = sample,
		shuffle = shuffle,
		reverse = reverse,
	},

	__tostring = tostring,
	__call = init,
}
-------------------------------------------------------------------------------
return setmetatable(Table, mt)
-------------------------------------------------------------------------------