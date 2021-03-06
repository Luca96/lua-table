# Lua-Table Changelog

## (0.7) 16/07/2018:
- code rewriting: now the library extends the global table object
- removed step iterator (use range instead)
- flatten is renamed to flat (and re-implemented)
- flatten2 is removed
- added table.flatmap()
- removeNils renamed to purify
- removed some table operators: s_empy, s_nempty, s_len, t_len, t_maxlen
- some utils like: sum, mul are moved to operators
- difference renamed into negation
- added table.union, table.deepflat, table.equal
- some operator overloads
- added: lshift, rshift and shift
- added: all, any, allPairs and anyPairs

## (0.6) 01/06/2018:
- new table operator: add
- new table utils: valueList, keyList, valueSequence, difference, interection, 
- unique and occurrences.
- edited valueSet and keySet: now both return a set (not a list of elements)
- fixed Table.new (now init-value can be a string, number, table, ecc..)

## (0.5) 24/05/2018:
- new comparison operators: eq, neq, gt, lt, ge, le 
- new operators: increase, decrease, itself and identity
- removed operators: asc_compare and desc_compare (replaced by Table.ge and Table.le)
- added optional varargs in: each, eachi, map, accept, reject, reduce, maximize and minimize
- edited Table.new: now tables can be created with a value provided by an init-function 
- iterators edited: now range and group returns (index, value) at each iteration
- performance improvement for append and push
- removed Table.pack and replaced by Table.pack2
- fixed a bug in Table.reverse

## (0.4) 12/05/2018:
- change into table utils: key and values are now iterators
- renamed: Table.create to Table.new
- table utils: added find, keySet, valueSet, avg, minimize and maximize
- table operators: added has, hasKey and head
- table init helpers: added Table.ofChars

## (0.3) 05/05/2018:
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