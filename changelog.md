# Lua-Table Changelog

## (0.3) ---- :
- fixed a bug into init function 
- introduced table operators, like: at, get, push, append, pop, empty, ...
- new table utils: merge, sort and slice
- new iterators: inverse, group and slide

## (0.2) 01/05/2018:
- added removeNils function, that return a new table without nil values
- tostring now prints even nested tables
- added table init helpers: zeros, ones and create (inspired by python)
- copy function is renamed to clone, and now performs a true clone (deep-copy) of the table

## (0.1) 23/04/2018:
- tostring now prints key-value pairs
- functions does not create anytime a new table, like Table(table). they just return itself.
- table.abs points to math.abs
- eachKeys renamed to each, and each renamed to eachi