<p align="center"><img src="logo/vertical.png" alt="lua-table" height="100px"></p>

# Lua-Table 0.7
Lua tables with superpowers :muscle:

## Changes
View the ```changelog``` for more info about changes.

## Installation
To install the library just ```clone``` the repo or install via [LuaRocks](https://luarocks.org/modules/Luca96/luatable).

## Running tests
The test suite lives in `spec/` and uses [busted](https://lunarmodules.github.io/busted/):
```
luarocks install busted
busted
```
or, through LuaRocks (installs busted first if it is missing):
```
luarocks test
```

## Examples
```lua
-- load library
local table = require "luatable"

-- create a normal table
local t = { 1, 2, 2, 3, -4, 5 }

-- remove negative values
t = table.accept(t, table.positive)

-- create an enhanched table from an old one (t itself gains the methods, no copy)
local tb = table(t)

-- table.of always packs its arguments: a single table becomes the only element
local nested = table.of(t)   --> { t }

-- a table init value is deep-copied into each slot
local grid = table.init(3, { 0, 0 })

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

-- table equality
local t1 = { 1, 2, 3, x = { 4, 5 } }
local t2 = { 1, 2, 3, 4, 5 }

print(table.equal(t1, t2))       --> false
print(table.equal(t1, t2, true)) --> true

-- deep equality (and deepflat) visit hash keys in a fixed order, not pairs order:
-- numbers, strings, booleans, then tables (compared by content), then functions,
-- userdata and threads (by identity, so these keys only line up when both tables
-- use the same key objects)

-- operator overloads
local t1 = table { 1, 2, 3 }
local t2 = table { 2, 4, 5 }

print(t1 + t2)  -- table.union
print(t1 - t2)  -- table.negation
print(t1 * t2)  -- table.intersect
print(t1 == t2) -- table.equal
print(t1 .. t2) -- table.merge

```

## Known issues & roadmap
This section tracks what is still open. Update it when an item is fixed or a new one is found.

### Known issues
- **Dot-access returns library functions.** Enhanced tables use `__index = table`, so `tb.sum` or
  `tb.map` on a table without those keys returns the library function instead of `nil`.
  `get` and `haskey` are not affected; plain indexing is.

### Roadmap
- **Module instead of global extension.** Today the library adds its functions to Lua's global
  `table` (by design). Alternative: `require "luatable"` returns its own table with
  `__index = table` as a fallback, so `local table = require "luatable"` works as now while the
  global `table` stays untouched, plus an optional `luatable.install()` for the current global
  behaviour. This avoids name clashes with future Lua versions or other libraries.
- CI running busted on Lua 5.1, 5.4 and LuaJIT.
- Version bump and release once the fixes in the changelog's *Unreleased* section ship.
