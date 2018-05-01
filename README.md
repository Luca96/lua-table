# Lua-Table
Lua tables with superpowers :muscle:

## Changes
View the ```changelog``` for more info about changes

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
-- iterate over int indexes (1, 2, ..., #t)
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
local table_without_nils = table_with_nils:removeNils()

-- clone a table
local cloned = t:clone()
```
