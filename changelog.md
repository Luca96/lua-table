# Lua-Table Changelog

## (0.2) 01/05/2018:
- added removeNils function, that return a new table without nil values
- tostring now prints even nested tables
- added table init helpers (like in python)
- copy functions is renamed to clone, and now performs a true clone of the table

## (0.1) 23/04/2018:
- tostring now prints key-value pairs
- functions does not create anytime a new table, like Table(table). they just return itself.
- table.abs points to math.abs
- eachKeys renamed to each, and each renamed to eachi