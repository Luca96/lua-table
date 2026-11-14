local T = require "luatable"
local h = require "helpers"
local plain, is_enhanced = h.plain, h.is_enhanced

describe("constructors", function()

   describe("table.new", function()
      it("creates an empty enhanced table with no arguments", function()
         local t = T.new()
         assert.is_true(is_enhanced(t))
         assert.are.same({}, plain(t))
      end)

      it("packs varargs into an enhanced table", function()
         local t = T.new(1, 2, 3)
         assert.is_true(is_enhanced(t))
         assert.are.same({ 1, 2, 3 }, plain(t))
      end)

      it("wraps a single table argument in place (no copy)", function()
         local src = { 1, 2, x = 3 }
         local t = T.new(src)
         assert.is_true(rawequal(src, t))
         assert.is_true(is_enhanced(src))
         assert.are.same({ 1, 2, x = 3 }, plain(t))
      end)

      it("treats several table arguments as elements", function()
         local a, b = { 1 }, { 2 }
         local t = T.new(a, b)
         assert.are.equal(2, #t)
         assert.is_true(rawequal(a, t[1]))
         assert.is_true(rawequal(b, t[2]))
      end)
   end)

   describe("table.of", function()
      it("creates an empty enhanced table with no arguments", function()
         local t = T.of()
         assert.is_true(is_enhanced(t))
         assert.are.same({}, plain(t))
      end)

      it("packs its arguments", function()
         assert.are.same({ 1, 2, 3 }, plain(T.of(1, 2, 3)))
      end)

      it("keeps a single table argument as the only element", function()
         local x = { 1, 2 }
         local t = T.of(x)
         assert.are.equal(1, #t)
         assert.is_true(rawequal(x, t[1]))
         assert.is_true(is_enhanced(t))
      end)

      it("leaves the argument's metatable alone", function()
         local x = { 1 }
         T.of(x)
         assert.is_nil(getmetatable(x))
      end)
   end)

   describe("calling the library", function()
      it("table{...} is the same as table.new{...}", function()
         local t = T { 4, 5 }
         assert.is_true(is_enhanced(t))
         assert.are.same({ 4, 5 }, plain(t))
      end)

      it("table(a, b, c) packs its arguments", function()
         assert.are.same({ "a", "b", "c" }, plain(T("a", "b", "c")))
      end)

      it("enables method chaining on the result", function()
         assert.are.equal(12, T { 3, 1, 2 }:map(T.double):reduce(0, T.sum))
      end)
   end)

   describe("table.init", function()
      it("fills with a constant value", function()
         assert.are.same({ "x", "x", "x" }, plain(T.init(3, "x")))
      end)

      it("fills with the result of a function of the index and extra args", function()
         local t = T.init(3, function(i, m) return i * m end, 10)
         assert.are.same({ 10, 20, 30 }, plain(t))
      end)

      it("gives every slot its own deep copy of a table init value", function()
         local def = { 0, inner = { 1 } }
         local t = T.init(2, def)
         assert.is_false(rawequal(t[1], t[2]))
         assert.is_false(rawequal(t[1], def))
         assert.is_false(rawequal(t[1].inner, t[2].inner))
         assert.is_false(rawequal(t[1].inner, def.inner))
         assert.are.same({ { 0, inner = { 1 } }, { 0, inner = { 1 } } }, plain(t))
      end)

      it("slots stay independent when one is changed", function()
         local t = T.init(2, { 0 })
         t[1][1] = 9
         assert.are.same({ { 9 }, { 0 } }, plain(t))
      end)

      it("copies of a table init value are enhanced tables", function()
         local t = T.init(1, {})
         assert.is_true(is_enhanced(t[1]))
      end)

      it("returns an empty enhanced table for size 0", function()
         local t = T.init(0, 1)
         assert.is_true(is_enhanced(t))
         assert.are.same({}, plain(t))
      end)
   end)

   describe("table.zeros / table.ones", function()
      it("zeros(n) creates n zeros", function()
         assert.are.same({ 0, 0, 0 }, plain(T.zeros(3)))
      end)

      it("ones(n) creates n ones", function()
         assert.are.same({ 1, 1 }, plain(T.ones(2)))
      end)

      it("returns enhanced tables", function()
         assert.is_true(is_enhanced(T.zeros(1)))
         assert.is_true(is_enhanced(T.ones(1)))
      end)
   end)

   describe("table.ofChars", function()
      it("splits a string into characters", function()
         assert.are.same({ "a", "b", "c" }, plain(T.ofChars("abc")))
      end)

      it("returns an empty table for the empty string", function()
         assert.are.same({}, plain(T.ofChars("")))
      end)
   end)
end)
