local T = require "luatable"
local h = require "helpers"
local collect, collect1, sorted = h.collect, h.collect1, h.sorted

describe("iterators", function()

   describe("table.iter", function()
      it("yields the values in order", function()
         assert.are.same({ "a", "b", "c" }, collect1(T.iter({ "a", "b", "c" })))
      end)

      it("stops at the first hole", function()
         assert.are.same({ 1, 2 }, collect1(T.iter({ 1, 2, nil, 4 })))
      end)

      it("yields nothing for an empty table", function()
         assert.are.same({}, collect1(T.iter({})))
      end)

      it("works in a generic for loop", function()
         local sum = 0
         for v in T.iter({ 1, 2, 3 }) do sum = sum + v end
         assert.are.equal(6, sum)
      end)
   end)

   describe("table.inverse", function()
      it("yields the values in reverse order", function()
         assert.are.same({ 3, 2, 1 }, collect1(T.inverse({ 1, 2, 3 })))
      end)

      it("yields nothing for an empty table", function()
         assert.are.same({}, collect1(T.inverse({})))
      end)
   end)

   describe("table.range", function()
      local t = { "a", "b", "c", "d" }

      it("yields (index, value) over the whole table by default", function()
         assert.are.same({ { 1, "a" }, { 2, "b" }, { 3, "c" }, { 4, "d" } }, collect(T.range(t)))
      end)

      it("honours start, count and step", function()
         assert.are.same({ { 1, "a" }, { 3, "c" } }, collect(T.range(t, 1, 2, 2)))
      end)

      it("yields nothing when count is 0", function()
         assert.are.same({}, collect(T.range(t, 1, 0)))
      end)

      it("does not run past the end when only start is given", function()
         assert.are.same({ { 2, "b" }, { 3, "c" } }, collect(T.range({ "a", "b", "c" }, 2)))
      end)
   end)

   describe("table.group", function()
      it("yields consecutive k-tuples", function()
         assert.are.same({ { 1, 2 }, { 3, 4 } }, collect(T.group({ 1, 2, 3, 4 }, 2)))
      end)

      it("yields a shorter last group", function()
         assert.are.same({ { 1, 2 }, { 3, 4 }, { 5 } }, collect(T.group({ 1, 2, 3, 4, 5 }, 2)))
      end)
   end)

   describe("table.slide", function()
      it("yields only full sliding windows of size k", function()
         assert.are.same({ { 1, 2 }, { 2, 3 }, { 3, 4 } }, collect(T.slide({ 1, 2, 3, 4 }, 2)))
      end)
   end)

   describe("table.keys / table.values", function()
      local t = { 10, 20, x = 30 }

      it("keys() yields every key", function()
         assert.are.same(sorted({ 1, 2, "x" }), sorted(collect1(T.keys(t))))
      end)

      it("values() yields every value", function()
         assert.are.same({ 10, 20, 30 }, sorted(collect1(T.values(t))))
      end)

      it("yield nothing for an empty table", function()
         assert.are.same({}, collect1(T.keys({})))
         assert.are.same({}, collect1(T.values({})))
      end)
   end)

   describe("table.eachi", function()
      it("calls the function with each array value and the extra args", function()
         local s = spy.new(function() end)
         T.eachi({ "a", "b" }, h.fn(s), "extra")
         assert.spy(s).was.called(2)
         assert.spy(s).was.called_with("a", "extra")
         assert.spy(s).was.called_with("b", "extra")
      end)

      it("ignores hash keys", function()
         local s = spy.new(function() end)
         T.eachi({ 1, x = 2 }, h.fn(s))
         assert.spy(s).was.called(1)
      end)

      it("returns the same table", function()
         local t = { 1 }
         assert.is_true(rawequal(t, T.eachi(t, function() end)))
      end)
   end)

   describe("table.each", function()
      it("calls the function with every (key, value) pair and the extra args", function()
         local s = spy.new(function() end)
         T.each({ 10, x = 20 }, h.fn(s), "extra")
         assert.spy(s).was.called(2)
         assert.spy(s).was.called_with(1, 10, "extra")
         assert.spy(s).was.called_with("x", 20, "extra")
      end)

      it("returns the same table", function()
         local t = { 1 }
         assert.is_true(rawequal(t, T.each(t, function() end)))
      end)
   end)
end)
