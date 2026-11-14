-----------------------------------------------------------------------------------------
-- lua-table feature tour
--
-- Exercises every public function of the library, prints what each call returns and
-- checks it against the expected value. Run it from anywhere:
--
--    lua examples/demo.lua
--
-- Each line shows "ok" or "FAIL"; the script exits with status 1 if anything failed.
-----------------------------------------------------------------------------------------

-- load the library from ../src relative to this file, so the script runs from any folder
local here = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or "./"
package.path = here .. "../src/?.lua;" .. package.path

local table = require "luatable"   -- the extended table library (README style)

-----------------------------------------------------------------------------------------
-- tiny helpers: render values, compare them, report results
-----------------------------------------------------------------------------------------
local passed, failed = 0, 0

-- compact, deterministic rendering: array part first, then other keys sorted by name.
-- uses rawget/next so enhanced-table metamethods never interfere; cycles show as <cycle>
local function show(v, seen)
   if type(v) == "string" then return ("%q"):format(v) end
   if type(v) ~= "table" then return tostring(v) end

   seen = seen or {}
   if seen[v] then return "<cycle>" end
   seen[v] = true

   local parts, n = {}, #v

   for i = 1, n do
      parts[#parts + 1] = show(rawget(v, i), seen)
   end

   local keys = {}
   for k in next, v do
      local in_array = type(k) == "number" and k >= 1 and k <= n and k % 1 == 0
      if not in_array then keys[#keys + 1] = k end
   end
   table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

   for _, k in ipairs(keys) do
      local name = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or "[" .. show(k, seen) .. "]"
      parts[#parts + 1] = name .. " = " .. show(rawget(v, k), seen)
   end

   seen[v] = nil
   return "{" .. table.concat(parts, ", ") .. "}"
end

-- structural equality that ignores metatables (enhanced tables overload ==)
local function same(a, b, seen)
   if rawequal(a, b) then return true end
   if type(a) ~= "table" or type(b) ~= "table" then return a == b end

   seen = seen or {}
   if seen[a] == b then return true end
   seen[a] = b

   for k, v in next, a do
      if not same(v, rawget(b, k), seen) then return false end
   end
   for k in next, b do
      if rawget(a, k) == nil then return false end
   end
   return true
end

local function check(label, got, expected)
   if same(got, expected) then
      passed = passed + 1
      print(("  ok    %-44s %s"):format(label, show(got)))
   else
      failed = failed + 1
      print(("  FAIL  %-44s got %s, expected %s"):format(label, show(got), show(expected)))
   end
end

local function section(title)
   print("\n== " .. title .. " " .. ("="):rep(math.max(0, 70 - #title)))
end

-- drain an iterator: one value per step, or a list when it yields `arity` values
local function collect(iter, arity)
   local out = {}
   while true do
      local step = { iter() }
      if step[1] == nil then return out end
      out[#out + 1] = (arity or 1) == 1 and step[1] or step
   end
end

-- sorted copy, for results that follow the (unspecified) pairs order
local function sorted(list)
   local copy = {}
   for i = 1, #list do copy[i] = list[i] end
   table.sort(copy, function(a, b) return tostring(a) < tostring(b) end)
   return copy
end

-- same content as t, but a different pairs order: a key's slot depends on the size of
-- the hash part, so copy t into presized tables (a constructor with n nil fields
-- reserves n slots without storing anything) until the iteration order changes
local function reordered(t)
   local function order(x)
      local keys = {}
      for k in next, x do keys[#keys + 1] = tostring(k) end
      return table.concat(keys, ",")
   end

   for size = 1, 10 do
      local fields = {}
      for i = 1, 2 ^ size do fields[i] = "_" .. i .. " = nil" end
      local copy = assert((loadstring or load)("return {" .. table.concat(fields, ", ") .. "}"))()

      for k, v in next, t do copy[k] = v end
      if order(copy) ~= order(t) then return copy end
   end

   error("reordered(): could not change the pairs order")
end

local function strip_ansi(s)
   return (tostring(s):gsub("\27%[[%d;]*m", ""))
end

-----------------------------------------------------------------------------------------
section("library info")
-----------------------------------------------------------------------------------------
table.info()

-----------------------------------------------------------------------------------------
section("constructors")
-----------------------------------------------------------------------------------------
check("table.new(1, 2, 3)",                table.new(1, 2, 3), { 1, 2, 3 })
check("table { 4, 5 }   (call syntax)",     table { 4, 5 }, { 4, 5 })
check("table(\"a\", \"b\")",                table("a", "b"), { "a", "b" })

local plain = { 7, 8 }
local wrapped = table.new(plain)
check("table.new(t) wraps t in place",      rawequal(wrapped, plain), true)
check("...and t gains methods",             plain:last(), 8)

local box = { 7 }
check("table.of(t) holds t as an element",  { #table.of(box), rawequal(table.of(box)[1], box) }, { 1, true })
check("...leaving t without methods",       getmetatable(box), nil)
check("table.of(1, 2, 3)",                  table.of(1, 2, 3), { 1, 2, 3 })

check("table.init(3, \"x\")",               table.init(3, "x"), { "x", "x", "x" })
check("table.init(4, i -> i*i)",            table.init(4, function(i) return i * i end), { 1, 4, 9, 16 })
check("table.init(3, f, 10)  (extra args)", table.init(3, function(i, base) return base + i end, 10), { 11, 12, 13 })

local grid = table.init(2, { 0 })
grid[1][1] = 9
check("table.init(2, {0})  (a copy per slot)", grid, { { 9 }, { 0 } })
check("table.zeros(3)",                     table.zeros(3), { 0, 0, 0 })
check("table.ones(2)",                      table.ones(2), { 1, 1 })
check("table.ofChars(\"lua\")",             table.ofChars("lua"), { "l", "u", "a" })

-----------------------------------------------------------------------------------------
section("small operator functions (for map / reduce / accept ...)")
-----------------------------------------------------------------------------------------
check("odd(3), even(3)",                    { table.odd(3), table.even(3) }, { true, false })
check("half(5), double(4)",                 { table.half(5), table.double(4) }, { 2.5, 8 })
check("sqr(3), pow(2, 8)",                  { table.sqr(3), table.pow(2, 8) }, { 9, 256 })
check("increase(1), decrease(1)",           { table.increase(1), table.decrease(1) }, { 2, 0 })
check("positive(-1), negative(-1)",         { table.positive(-1), table.negative(-1) }, { false, true })
check("itself(\"x\"), identity(1)",         { table.itself("x"), table.identity(1) }, { "x", true })
check("isnil(nil), isnil(false)",           { table.isnil(nil), table.isnil(false) }, { true, false })
check("eq, neq, gt, lt, ge, le",
      { table.eq(1, 1), table.neq(1, 1), table.gt(2, 1), table.lt(2, 1), table.ge(1, 1), table.le(2, 1) },
      { true, false, true, false, true, false })
check("sum, sub, mul, div",
      { table.sum(2, 3), table.sub(5, 3), table.mul(2, 3), table.div(7, 2) },
      { 5, 2, 6, 3.5 })
check("void() returns nothing",             select("#", table.void()), 0)

-----------------------------------------------------------------------------------------
section("functional utils")
-----------------------------------------------------------------------------------------
check("map({1,2,3}, double)",               table.map({ 1, 2, 3 }, table.double), { 2, 4, 6 })
check("map({1,2,3}, pow, 2)  (extra args)", table.map({ 1, 2, 3 }, table.pow, 2), { 1, 4, 9 })
check("reduce({1,2,3,4}, 0, sum)",          table.reduce({ 1, 2, 3, 4 }, 0, table.sum), 10)
check("reduce({1,2,3,4}, 1, mul)",          table.reduce({ 1, 2, 3, 4 }, 1, table.mul), 24)
check("accept({1,-2,3,-4}, positive)",      table.accept({ 1, -2, 3, -4 }, table.positive), { 1, 3 })
check("reject({1,-2,3,-4}, positive)",      table.reject({ 1, -2, 3, -4 }, table.positive), { -2, -4 })
check("accept({1,2,3}, gt, 1)",             table.accept({ 1, 2, 3 }, table.gt, 1), { 2, 3 })
check("flat({1, {2, {3, 4}}, 5})",          table.flat({ 1, { 2, { 3, 4 } }, 5 }), { 1, 2, 3, 4, 5 })
check("flat ignores hash keys",             table.flat({ 1, x = { 2 } }), { 1 })
check("deepflat({1, {2}, x = {3}})",        table.deepflat({ 1, { 2 }, x = { 3 } }), { 1, 2, 3 })
check("deepflat({3, b = 2, a = 1})  (sorted)", table.deepflat({ 3, b = 2, a = 1 }), { 3, 1, 2 })
check("deepflat(10 keys)  (sorted, not pairs)",
      table.deepflat({ c = 3, h = 8, a = 1, j = 10, e = 5, b = 2, g = 7, d = 4, i = 9, f = 6 }),
      { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
check("deepflat({[{2}]=\"b\", [{1}]=\"a\"})  (by key content)",
      table.deepflat({ [{ 2 }] = "b", [{ 1 }] = "a" }), { "a", "b" })
check("flatmap({1,2}, v -> {v, v*10})",
      table.flatmap({ 1, 2 }, function(v) return { v, v * 10 } end), { 1, 10, 2, 20 })
check("all({2,4}, even), all({2,3}, even)", { table.all({ 2, 4 }, table.even), table.all({ 2, 3 }, table.even) }, { true, false })
check("any({1,2}, even), any({1,3}, even)", { table.any({ 1, 2 }, table.even), table.any({ 1, 3 }, table.even) }, { true, false })
check("allPairs / anyPairs see hash values",
      { table.allPairs({ 2, x = 3 }, table.even), table.anyPairs({ 1, x = 2 }, table.even) }, { false, true })

-- method chaining on an enhanced table
check("table{1,2,3,4}:accept(even):map(sqr):reduce(0, sum)",
      table { 1, 2, 3, 4 }:accept(table.even):map(table.sqr):reduce(0, table.sum), 20)

-----------------------------------------------------------------------------------------
section("iterators")
-----------------------------------------------------------------------------------------
local letters = { "a", "b", "c", "d" }

local seen_in_loop = {}
for v in table.iter(letters) do seen_in_loop[#seen_in_loop + 1] = v end   -- plain for-in loop
check("for v in iter(t)",                   seen_in_loop, { "a", "b", "c", "d" })
check("inverse(t)",                         collect(table.inverse(letters)), { "d", "c", "b", "a" })
check("range(t)",                           collect(table.range(letters), 2),
      { { 1, "a" }, { 2, "b" }, { 3, "c" }, { 4, "d" } })
check("range(t, 3)  (from index 3)",        collect(table.range(letters, 3), 2), { { 3, "c" }, { 4, "d" } })
check("range(t, 1, 2, 2)  (count 2, step 2)", collect(table.range(letters, 1, 2, 2), 2), { { 1, "a" }, { 3, "c" } })
check("range(t, 4, nil, -1)  (backwards)",  collect(table.range(letters, 4, nil, -1), 2),
      { { 4, "d" }, { 3, "c" }, { 2, "b" }, { 1, "a" } })
check("group({1..5}, 2)",                   collect(table.group({ 1, 2, 3, 4, 5 }, 2), 2), { { 1, 2 }, { 3, 4 }, { 5 } })
check("slide({1..4}, 3)  (full windows)",   collect(table.slide({ 1, 2, 3, 4 }, 3), 3), { { 1, 2, 3 }, { 2, 3, 4 } })
check("keys({10, 20, x = 30})",             sorted(collect(table.keys({ 10, 20, x = 30 }))), { 1, 2, "x" })
check("values({10, 20, x = 30})",           sorted(collect(table.values({ 10, 20, x = 30 }))), { 10, 20, 30 })

local visited = {}
table.eachi({ "a", "b" }, function(v, suffix) visited[#visited + 1] = v .. suffix end, "!")
check("eachi(t, f, \"!\")",                 visited, { "a!", "b!" })

visited = {}
table.each({ 1, x = 2 }, function(k, v) visited[#visited + 1] = tostring(k) .. "=" .. v end)
check("each(t, f)  (all key/value pairs)",  sorted(visited), { "1=1", "x=2" })

-----------------------------------------------------------------------------------------
section("utility")
-----------------------------------------------------------------------------------------
check("purify({[1]=\"a\", [5]=\"b\", [9]=\"c\", x=1})",
      table.purify({ [1] = "a", [5] = "b", [9] = "c", x = 1 }), { "a", "b", "c", x = 1 })
check("max({3, 7, 2}), min({3, 7, 2})",     { table.max({ 3, 7, 2 }), table.min({ 3, 7, 2 }) }, { 7, 2 })
check("max(words, longer-than)",
      table.max({ "aa", "b", "cccc" }, function(a, b) return #a > #b end), "cccc")
check("avg({2, 4, 6})",                     table.avg({ 2, 4, 6 }), 4)
check("maximize({-5, 1, 3}, sqr)",          table.maximize({ -5, 1, 3 }, table.sqr), -5)
check("minimize({-5, 1, 3}, sqr)",          table.minimize({ -5, 1, 3 }, table.sqr), 1)

math.randomseed(42)
local pool = { "x", "y", "z" }
check("sample(t) is an element of t",       table.find(pool, table.sample(pool)) ~= nil, true)
local deck = { 1, 2, 3, 4, 5, 6 }
table.shuffle(deck)
print("        shuffle({1..6}) -> " .. show(deck))
check("shuffle keeps the same elements",    sorted(deck), { 1, 2, 3, 4, 5, 6 })

-- every ordering of {1, 2, 3} should come up about 1/6 of the time
-- (the old algorithm gave some orderings 4/27 and others 5/27)
local runs, tally, uniform = 60000, {}, true
for _ = 1, runs do
   local key = table.concat(table.shuffle({ 1, 2, 3 }))
   tally[key] = (tally[key] or 0) + 1
end
local orderings = 0
for _, n in pairs(tally) do
   orderings = orderings + 1
   if math.abs(n - runs / 6) > runs / 6 * 0.05 then uniform = false end
end
check("shuffle is uniform  (6 orderings, +-5%)", { orderings, uniform }, { 6, true })

check("reverse({1, 2, 3})  (in place)",     table.reverse({ 1, 2, 3 }), { 3, 2, 1 })
check("slice({1..5}, 2, 4)",                table.slice({ 1, 2, 3, 4, 5 }, 2, 4), { 2, 3, 4 })
check("slice({1..5}, -2)  (from the end)",  table.slice({ 1, 2, 3, 4, 5 }, -2), { 4, 5 })
check("find({\"a\",\"b\",\"c\"}, \"b\")",   table.find({ "a", "b", "c" }, "b"), 2)
check("find(t, missing) -> nil",            table.find({ "a" }, "z"), nil)

local original = { 1, inner = { 2, 3 } }
local copy = table.clone(original)
check("clone(t) has the same content",      copy, original)
check("...but is a deep copy",              { rawequal(copy, original), rawequal(copy.inner, original.inner) }, { false, false })

check("merge({1,2}, {2,3})  (keeps dups)",  table.merge({ 1, 2 }, { 2, 3 }), { 1, 2, 2, 3 })
check("unique({1,2,2,3,1})",                table.unique({ 1, 2, 2, 3, 1 }), { 1, 2, 3 })
check("keyList({10, x = 20})",              sorted(table.keyList({ 10, x = 20 })), { 1, "x" })
check("valueList({10, x = 20})",            sorted(table.valueList({ 10, x = 20 })), { 10, 20 })
check("valueSequence({1, 2, x = 3})",       table.valueSequence({ 1, 2, x = 3 }), { 1, 2 })

local t1 = { 1, 2, 3, x = { 4, 5 } }
local t2 = { 1, 2, 3, 4, 5 }
check("equal(t1, t2)  (array part only)",   table.equal(t1, t2), false)
check("equal(t1, t2, true)  (deep)",        table.equal(t1, t2, true), true)

local person = { name = "Ada", born = 1815, field = "maths", city = "London",
                 langs = { "en", "fr" }, notes = { first = "program" } }
check("deep equal ignores pairs order",     table.equal(person, reordered(person), true), true)
check("deep equal: table keys by content",
      table.equal({ [{ 1 }] = "a", [{ 2 }] = "b" }, { [{ 2 }] = "b", [{ 1 }] = "a" }, true), true)

-----------------------------------------------------------------------------------------
section("set utils")
-----------------------------------------------------------------------------------------
check("union({1,2}, {2,3})",                table.union({ 1, 2 }, { 2, 3 }), { 1, 2, 3 })
check("negation({1,2,3}, {2})",             table.negation({ 1, 2, 3 }, { 2 }), { 1, 3 })
check("intersect({1,2,3}, {2,3,4})",        table.intersect({ 1, 2, 3 }, { 2, 3, 4 }), { 2, 3 })
check("keySet({\"a\", x = \"b\"})",         table.keySet({ "a", x = "b" }), { true, x = true })
check("valueSet({\"a\", \"a\", \"b\"})",    table.valueSet({ "a", "a", "b" }), { a = true, b = true })

-----------------------------------------------------------------------------------------
section("methods on enhanced tables")
-----------------------------------------------------------------------------------------
local tb = table { "a", "b", "c", x = "hash" }

check("tb:at(1), tb:at(-1)",                { tb:at(1), tb:at(-1) }, { "a", "c" })
check("tb:at(10, \"default\")",             tb:at(10, "default"), "default")
check("tb:get(\"x\"), tb:get(\"nope\", 0)", { tb:get("x"), tb:get("nope", 0) }, { "hash", 0 })
check("tb:get(\"sum\", \"none\")  (no leak)", tb:get("sum", "none"), "none")
check("table{false}:at(1, \"d\")",          table { false }:at(1, "d"), false)
check("tb:first(), tb:last()",              { tb:first(), tb:last() }, { "a", "c" })
check("tb:has(\"b\"), tb:has(\"z\")",       { tb:has("b"), tb:has("z") }, { true, false })
check("tb:haskey(\"x\"), tb:haskey(\"map\")", { tb:haskey("x"), tb:haskey("map") }, { true, false })
check("tb:empty(), table{x=1}:empty()",     { tb:empty(), table { x = 1 }:empty() }, { false, true })

local list = table { 2, 3 }
list:append(4, 5)
check("append(4, 5)",                       list, { 2, 3, 4, 5 })
list:push(0, 1)
check("push(0, 1)  (to the front)",         list, { 0, 1, 2, 3, 4, 5 })
check("pop() returns the last value",       list:pop(), 5)
check("head() returns the first value",     list:head(), 0)
check("...leaving",                         list, { 1, 2, 3, 4 })

local shifty = table { 1, 2, 3, 4, 5, 6 }
check("lshift(2) returns the first two",    { shifty:lshift(2) }, { 1, 2 })
check("rshift(2) returns the last two",     { shifty:rshift(2) }, { 5, 6 })
check("shift(-1) == lshift(1)",             { shifty:shift(-1) }, { 3 })
check("shift(1) == rshift(1)",              { shifty:shift(1) }, { 4 })
check("...leaving an empty table",          shifty, {})

local clearable = table { 1, 2, x = 3 }
check("clear() keeps hash keys",            clearable:clear(), { x = 3 })
check("clear(true) removes everything",     clearable:clear(true), {})

-----------------------------------------------------------------------------------------
section("operator overloads and printing")
-----------------------------------------------------------------------------------------
local a, b = table { 1, 2, 3 }, table { 2, 4, 5 }
check("a + b  (union)",                     a + b, { 1, 2, 3, 4, 5 })
check("a - b  (negation)",                  a - b, { 1, 3 })
check("a * b  (intersect)",                 a * b, { 2 })
check("a .. b  (merge)",                    a .. b, { 1, 2, 3, 2, 4, 5 })
check("a == b, a == table{1,2,3}",          { a == b, a == table { 1, 2, 3 } }, { false, true })

print("        print(table { 1, x = { 2 } }) ->")
print(table { 1, x = { 2 } })
check("tostring renders key/value lines",   tostring(table { 1 }):find("k: 1, v: 1", 1, true) ~= nil, true)

-----------------------------------------------------------------------------------------
section("cyclic tables")
-----------------------------------------------------------------------------------------
local cyc = table { 1, 2 }
cyc[3] = cyc
cyc.me = cyc

check("flat skips the back-reference",      table.flat(cyc), { 1, 2 })
check("deepflat too",                       table.deepflat(cyc), { 1, 2 })
local cyc_copy = table.clone(cyc)
check("clone reproduces the cycle",         { rawequal(cyc_copy.me, cyc_copy), rawequal(cyc_copy, cyc) }, { true, false })
local cyc_pure = table.purify(cyc)
check("purify reproduces the cycle",        rawequal(cyc_pure.me, cyc_pure), true)
check("equal(cyc, cyc, true) terminates",   table.equal(cyc, cyc, true), true)
check("tostring marks it as <cycle>",       tostring(cyc):find("<cycle>", 1, true) ~= nil, true)

-----------------------------------------------------------------------------------------
section("argument checks and warnings")
-----------------------------------------------------------------------------------------
-- note: no `return` before table.map. A tail call (`return f()`) discards the caller's
-- stack frame, so Lua could no longer say which line the call came from.
local call_line = debug.getinfo(1, "l").currentline + 1   -- the line of the next statement
local ok, msg = pcall(function() table.map(nil, print) end)
print("        map(nil, print) raised: " .. strip_ansi(msg))
check("map(nil, f) raises an error",        { ok, msg:find("table.map()", 1, true) ~= nil }, { false, true })
check("...reported at the caller's line",   { msg:find("demo%.lua:" .. call_line .. ":") ~= nil,
                                              msg:find("luatable.lua", 1, true) ~= nil }, { true, false })

ok, msg = pcall(table.zeros, "three")
check("zeros(\"three\") raises an error",   { ok, msg:find("table.zeros()", 1, true) ~= nil }, { false, true })

ok, msg = pcall(function() return table { 1 }:lshift(-1) end)
check("lshift(-1) raises an error",         { ok, msg:find("table.lshift()", 1, true) ~= nil }, { false, true })

print("        slice(t, 3, 1) prints a warning and returns {}:")
check("slice({1,2,3}, 3, 1)",               table.slice({ 1, 2, 3 }, 3, 1), {})

-----------------------------------------------------------------------------------------
print(("\n%d checks: %d passed, %d failed"):format(passed + failed, passed, failed))
os.exit(failed == 0 and 0 or 1)
