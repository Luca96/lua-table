local T = require "luatable"
local h = require "helpers"
local plain = h.plain

describe("table methods", function()

   describe(":at", function()
      local t = T { "a", "b", "c" }

      it("returns the element at a positive index", function()
         assert.are.equal("b", t:at(2))
      end)

      it("counts negative indices from the end", function()
         assert.are.equal("c", t:at(-1))
         assert.are.equal("a", t:at(-3))
      end)

      it("returns the default when the element is missing", function()
         assert.are.equal("d", t:at(10, "d"))
         assert.is_nil(t:at(10))
      end)

      it("returns a stored false instead of the default", function()
         assert.are.equal(false, T { false }:at(1, "d"))
      end)
   end)

   describe(":get", function()
      local t = T { 1, x = "v" }

      it("returns the value at any key", function()
         assert.are.equal("v", t:get("x"))
         assert.are.equal(1, t:get(1))
      end)

      it("returns the default when the key is missing", function()
         assert.are.equal("d", t:get("missing", "d"))
      end)

      it("returns a stored false instead of the default", function()
         assert.are.equal(false, T { false }:get(1, "d"))
      end)

      it("does not see library functions as stored values", function()
         assert.are.equal(0, T {}:get("sum", 0))
      end)
   end)

   describe(":append / :push", function()
      it("append adds values at the end and returns self", function()
         local t = T { 1 }
         assert.is_true(rawequal(t, t:append(2, 3)))
         assert.are.same({ 1, 2, 3 }, plain(t))
      end)

      it("push adds values at the front, keeping their order", function()
         local t = T { 4 }
         assert.is_true(rawequal(t, t:push(1, 2, 3)))
         assert.are.same({ 1, 2, 3, 4 }, plain(t))
      end)

      it("work on an empty table", function()
         assert.are.same({ 1 }, plain(T {}:append(1)))
         assert.are.same({ 1 }, plain(T {}:push(1)))
      end)
   end)

   describe(":pop / :head", function()
      it("pop removes and returns the last value", function()
         local t = T { 1, 2, 3 }
         assert.are.equal(3, t:pop())
         assert.are.same({ 1, 2 }, plain(t))
      end)

      it("head removes and returns the first value", function()
         local t = T { 1, 2, 3 }
         assert.are.equal(1, t:head())
         assert.are.same({ 2, 3 }, plain(t))
      end)

      it("return nil on an empty table", function()
         assert.is_nil(T {}:pop())
         assert.is_nil(T {}:head())
      end)
   end)

   describe(":first / :last", function()
      it("return the first and last values without removing them", function()
         local t = T { 1, 2, 3 }
         assert.are.equal(1, t:first())
         assert.are.equal(3, t:last())
         assert.are.same({ 1, 2, 3 }, plain(t))
      end)

      it("return nil on an empty table", function()
         assert.is_nil(T {}:first())
         assert.is_nil(T {}:last())
      end)
   end)

   describe(":clear", function()
      it("removes array values but keeps hash pairs by default", function()
         local t = T { 1, 2, x = 3 }
         assert.is_true(rawequal(t, t:clear()))
         assert.are.same({ x = 3 }, plain(t))
      end)

      it("removes everything when remove_pairs is true", function()
         assert.are.same({}, plain(T { 1, 2, x = 3 }:clear(true)))
      end)
   end)

   describe(":has / :haskey / :empty", function()
      local t = T { "a", x = "b" }

      it("has finds array values", function()
         assert.is_true(t:has("a"))
         assert.is_false(t:has("z"))
      end)

      it("haskey checks for a non-nil value at the key", function()
         assert.is_true(t:haskey("x"))
         assert.is_true(t:haskey(1))
         assert.is_false(t:haskey("missing"))
      end)

      it("haskey does not report library function names", function()
         assert.is_false(T {}:haskey("map"))
      end)

      it("empty looks only at the array part", function()
         assert.is_true(T {}:empty())
         assert.is_true(T { x = 1 }:empty())
         assert.is_false(T { 1 }:empty())
      end)
   end)

   describe(":lshift / :rshift / :shift", function()
      it("lshift removes and returns the first pos values", function()
         local t = T { 1, 2, 3, 4 }
         assert.are.same({ 1, 2 }, { t:lshift(2) })
         assert.are.same({ 3, 4 }, plain(t))
      end)

      it("rshift removes and returns the last pos values in order", function()
         local t = T { 1, 2, 3, 4 }
         assert.are.same({ 3, 4 }, { t:rshift(2) })
         assert.are.same({ 1, 2 }, plain(t))
      end)

      it("rshift clamps pos to the table size", function()
         local t = T { 1, 2 }
         assert.are.same({ 1, 2 }, { t:rshift(10) })
         assert.are.same({}, plain(t))
      end)

      it("shift with no argument removes nothing", function()
         local t = T { 1, 2 }
         assert.are.equal(0, select("#", t:shift()))
         assert.are.same({ 1, 2 }, plain(t))
      end)

      it("shift(n) right-shifts and shift(-n) left-shifts", function()
         local t = T { 1, 2, 3, 4 }
         assert.are.same({ 4 }, { t:shift(1) })
         assert.are.same({ 1 }, { t:shift(-1) })
         assert.are.same({ 2, 3 }, plain(t))
      end)
   end)
end)
