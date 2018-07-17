<p align="left"><img src="logo/horizontal.png" alt="lua-table" height="100px"></p>

# Lua-Table 0.7
Lua tables with superpowers :muscle:

## Changes
View the ```changelog``` for more info about changes.

## Installation
To install the library just ```clone``` the repo or install via [LuaRocks](https://luarocks.org/modules/Luca96/luatable).

## Examples
```lua
-- load library
local table = require "luatable"

-- create a normal table
local t = { 1, 2, 2, 3, -4, 5 }

-- remove negative values
t = table.accept(t, table.positive)

-- create an enhanched table from an old one
local tb = table(t)

-- print every element
tb:eachi(print)

-- or print the entire table (with key-value pairs)
print(tb)

-- double and sum values
local sum = tb:map(table.double):reduce(0, table.sum)

-- remove duplicates
tb = table.unique(tb)

-- clear and add values to table
tb:clear()
tb:append(4, 5, 6)
tb:push(1, 2, 3)

```
