local T = require "luatable"
local h = require "helpers"
local plain = h.plain

describe("small operator functions", function()
   -- { function name, arguments, expected result }
   local cases = {
      { "odd",       { 3 },     true  },
      { "odd",       { 4 },     false },
      { "even",      { 4 },     true  },
      { "even",      { 3 },     false },
      { "half",      { 3 },     1.5   },
      { "double",    { 3 },     6     },
      { "sqr",       { -4 },    16    },
      { "pow",       { 2, 10 }, 1024  },
      { "increase",  { 1 },     2     },
      { "decrease",  { 1 },     0     },
      { "positive",  { 0 },     true  },
      { "positive",  { -1 },    false },
      { "negative",  { -1 },    true  },
      { "negative",  { 0 },     false },
      { "itself",    { "v" },   "v"   },
      { "identity",  { 5 },     true  },
      { "isnil",     { nil },   true  },
      { "isnil",     { false }, false },
      { "eq",        { 1, 1 },  true  },
      { "eq",        { 1, 2 },  false },
      { "neq",       { 1, 2 },  true  },
      { "gt",        { 2, 1 },  true  },
      { "gt",        { 1, 1 },  false },
      { "lt",        { 1, 2 },  true  },
      { "ge",        { 1, 1 },  true  },
      { "le",        { 2, 1 },  false },
      { "sum",       { 2, 3 },  5     },
      { "sub",       { 2, 3 },  -1    },
      { "mul",       { 2, 3 },  6     },
      { "div",       { 7, 2 },  3.5   },
   }

   local unpack = table.unpack or unpack

   for _, case in ipairs(cases) do
      local name, args, expected = case[1], case[2], case[3]
      local shown = {}
      for i = 1, 2 do
         if args[i] ~= nil or i == 1 then shown[#shown + 1] = tostring(args[i]) end
      end
      local label = ("%s(%s) == %s"):format(name, table.concat(shown, ", "), tostring(expected))

      it(label, function()
         assert.are.equal(expected, T[name](unpack(args, 1, 2)))
      end)
   end

   it("void() returns nothing", function()
      assert.are.equal(0, select("#", T.void()))
   end)
end)

describe("operator overloads", function()
   it("+ is union (concatenation without duplicates)", function()
      assert.are.same({ 1, 2, 3 }, plain(T { 1, 2 } + T { 2, 3 }))
   end)

   it("- is negation (values of the left side missing from the right)", function()
      assert.are.same({ 1, 3 }, plain(T { 1, 2, 3 } - T { 2 }))
   end)

   it("* is intersection", function()
      assert.are.same({ 2, 3 }, plain(T { 1, 2, 3 } * T { 2, 3, 4 }))
   end)

   it(".. is merge (keeps duplicates)", function()
      assert.are.same({ 1, 2, 2, 3 }, plain(T { 1, 2 } .. T { 2, 3 }))
   end)

   it("== is table.equal", function()
      assert.is_true(T { 1, 2 } == T { 1, 2 })
      assert.is_false(T { 1, 2 } == T { 2, 1 })
      assert.is_true(T { 1, 2 } ~= T { 1, 2, 3 })
   end)

   it("operators return enhanced tables", function()
      assert.is_true(h.is_enhanced(T { 1 } + T { 2 }))
      assert.is_true(h.is_enhanced(T { 1 } .. T { 2 }))
   end)
end)

describe("table.tostring", function()
   it("is used by tostring() on enhanced tables", function()
      local s = tostring(T { 1 })
      assert.matches("^table %[", s)
      assert.matches("k: 1, v: 1", s, 1, true)
   end)

   it("renders nested tables", function()
      local s = T.tostring({ x = { 7 } })
      assert.matches("k: x, v: table [", s, 1, true)
      assert.matches("k: 1, v: 7", s, 1, true)
   end)

   it("renders an empty table", function()
      assert.matches("^table %[", T.tostring({}))
   end)

   it("skips userdata values but keeps the other entries", function()
      local s
      assert.has_no.errors(function() s = T.tostring({ 1, io.stdout, 3 }) end)
      assert.matches("v: 1", s, 1, true)
      assert.matches("v: 3", s, 1, true)
   end)
end)
