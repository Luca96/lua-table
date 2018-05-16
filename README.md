# Lua-Table 0.4
Lua tables with superpowers :muscle:

## Changes
View the ```changelog``` for more info about changes

## Installation
To install the library just ```clone``` the repo or install via [LuaRocks](https://luarocks.org/modules/Luca96/luatable).

## Examples
```lua
local Table = require "luatable"

-- create a Table from an old one
local t = Table { 1, -2, 3, 4, -5 }

-- print all values
print(t)
-- OR
t:each(print)

-- iterators
-------------------------
-- iterate over int indices (1, 2, ..., #t)
for i in t:iter() do
  stuff(i)
end

-- apply a function over all values (from 1 to #t)
t:eachi(function(a)
  -- do stuff
end)

-- over all (key, value) pairs
t:each(function(key, val)
  -- other stuff
end)

-- iterate in reverse order
for i in t:inverse() do
   print(i)  --prints: -5, 4, 3, -2, 1
end

-- iterate over triples (k-tuple in general)
for a, b, c in t:group(3) do
   print(a, b, c)  --prints: (1, -2, 3), (4, -5, nil)
end

-- functional operators
-------------------------
-- avoid negative values
local subset = t:reject(Table.negative)

--find the max value from a subtable of doubled odd values
local max = t:accept(Table.odd):map(Table.double):max() 

-- table utils
-------------------------
-- pick a random value from the table
local random_value = t:sample()

-- randomly mixing the table
local shuffled = t:shuffle()

-- remove nil values from a table
local table_with_nils = Table { 1, nil, 2, { nil, 3 }, nil, 4 }
local table_without_nils = table_with_nils:removeNils()  -- { 1, 2, { 3 }, 4 }

-- clone a table
local cloned = t:clone()

-- slice a table
local slice = t:slice(2, 4)  -- { -2, 3, 4 }
local slice = t:slice(1, -2) -- { 1, -2, 3, 4 }

-- table operators
-------------------------
-- simulate a stack
local stack = Table():append(1, 2, 3)
print(stack)          -- { 1, 2, 3 }
print(stack:pop())    --return: 3
stack:append(4)       --contains: 1, 2, 4

```
