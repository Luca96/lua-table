rockspec_format = "3.0"
package = "luatable"
version = "0.8.0-1"

source = {
   url = "git+https://github.com/Luca96/lua-table.git",
   tag = "v0.8.0",
}

description = {
   summary = "A library that gives superpowers to Lua tables",
   detailed = [[
      Extends Lua's table library with iterators (range, group, slide, keys, values,
      inverse), functional helpers (map, reduce, accept, reject, flat, deepflat, flatmap,
      all, any), set operations (union, negation, intersect, unique, keySet, valueSet),
      utilities (max, min, avg, sample, shuffle, reverse, slice, find, clone, merge,
      purify, equal) and enhanced tables with methods and operator overloads
      (+ - * .. ==). Works on Lua 5.1 - 5.4 and LuaJIT 2.1.
   ]],
   homepage = "https://github.com/Luca96/lua-table",
   license = "MIT",
   labels = { "datastructure", "utility", "functional" },
}

dependencies = {
   "lua >= 5.1",
}

test_dependencies = {
   "busted",
}

test = {
   type = "busted",
}

build = {
   type = "builtin",
   modules = {
      luatable = "src/luatable.lua",
   },
}
