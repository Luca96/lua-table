# Lua-Table
Lua tables with superpowers :muscle:

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
t:each(function(a)
  -- do stuff
end)

-- over all (key, value) pairs
t:eachKeys(function(key, val)
  -- other stuff
end)

-- functional operators
-------------------------
-- avoid negative values
local subset = t:reject(Table.negative)

--find the max value from a list of doubled odd values
local max = t:filter(Table.odd):map(Table.double):max() 

-- table utils
-------------------------
-- pick a random value from the table
local random_value = t:sample()

-- randomly mixing the table
local shuffled = t:shuffle()
```
