local T = require "luatable"
local h = require "helpers"
local plain, is_enhanced = h.plain, h.is_enhanced

describe("functional utils", function()

   describe("table.map", function()
      it("applies the function to every array value", function()
         assert.are.same({ 2, 4, 6 }, plain(T.map({ 1, 2, 3 }, T.double)))
      end)

      it("forwards extra args to the function", function()
         assert.are.same({ 1, 8, 27 }, plain(T.map({ 1, 2, 3 }, T.pow, 3)))
      end)

      it("returns a new enhanced table and leaves the input alone", function()
         local t = { 1, 2 }
         local r = T.map(t, T.double)
         assert.is_false(rawequal(t, r))
         assert.is_true(is_enhanced(r))
         assert.are.same({ 1, 2 }, t)
      end)

      it("ignores hash keys", function()
         assert.are.same({ 2 }, plain(T.map({ 1, x = 5 }, T.double)))
      end)

      it("returns an empty table for an empty input", function()
         assert.are.same({}, plain(T.map({}, T.double)))
      end)
   end)

   describe("table.reduce", function()
      it("folds the values starting from base", function()
         assert.are.equal(10, T.reduce({ 1, 2, 3, 4 }, 0, T.sum))
         assert.are.equal(24, T.reduce({ 1, 2, 3, 4 }, 1, T.mul))
      end)

      it("returns base for an empty table", function()
         assert.are.equal(42, T.reduce({}, 42, T.sum))
      end)

      it("calls the reducer as f(accumulator, value, ...extra)", function()
         local s = spy.new(function(acc) return acc end)
         T.reduce({ "v" }, "base", h.fn(s), "extra")
         assert.spy(s).was.called_with("base", "v", "extra")
      end)
   end)

   describe("table.accept / table.reject", function()
      local t = { 1, -2, 3, -4, 5 }

      it("accept keeps the values matching the criteria, in order", function()
         assert.are.same({ 1, 3, 5 }, plain(T.accept(t, T.positive)))
      end)

      it("reject drops the values matching the criteria, in order", function()
         assert.are.same({ -2, -4 }, plain(T.reject(t, T.positive)))
      end)

      it("forward extra args to the criteria", function()
         assert.are.same({ 3, 5 }, plain(T.accept(t, T.gt, 2)))
         assert.are.same({ 1, -2, -4 }, plain(T.reject(t, T.gt, 2)))
      end)

      it("return enhanced tables", function()
         assert.is_true(is_enhanced(T.accept(t, T.positive)))
         assert.is_true(is_enhanced(T.reject(t, T.positive)))
      end)
   end)

   describe("table.flat", function()
      it("flattens a trailing nested table", function()
         assert.are.same({ 1, 2, 3, 4 }, plain(T.flat({ 1, 2, { 3, 4 } })))
      end)

      it("ignores hash keys", function()
         assert.are.same({ 1 }, plain(T.flat({ 1, x = { 2 } })))
      end)

      it("returns a flat table unchanged (as a copy)", function()
         local t = { 1, 2, 3 }
         local r = T.flat(t)
         assert.is_false(rawequal(t, r))
         assert.are.same({ 1, 2, 3 }, plain(r))
      end)

      it("keeps the original element order with nesting in the middle #knownbug", function()
         assert.are.same({ 1, 2, 3, 4 }, plain(T.flat({ 1, { 2, { 3 } }, 4 })))
      end)
   end)

   describe("table.deepflat", function()
      it("collects every non-table value, including under hash keys", function()
         local r = T.deepflat({ 1, { 2, { 3 } }, x = { 4 } })
         assert.are.same({ 1, 2, 3, 4 }, h.sorted(r))
      end)

      it("returns an enhanced table", function()
         assert.is_true(is_enhanced(T.deepflat({ 1 })))
      end)
   end)

   describe("table.flatmap", function()
      it("maps then flattens each result", function()
         local r = T.flatmap({ 1, 2 }, function(v) return { v, { v * 10 } } end)
         assert.are.same({ 1, 10, 2, 20 }, plain(r))
      end)

      it("forwards extra args to the function", function()
         local r = T.flatmap({ 1, 2 }, function(v, n) return T.init(n, v) end, 2)
         assert.are.same({ 1, 1, 2, 2 }, plain(r))
      end)
   end)

   describe("table.all / table.any", function()
      it("all is true only when every array value matches", function()
         assert.is_true(T.all({ 2, 4 }, T.even))
         assert.is_false(T.all({ 2, 3 }, T.even))
      end)

      it("any is true when at least one array value matches", function()
         assert.is_true(T.any({ 1, 2 }, T.even))
         assert.is_false(T.any({ 1, 3 }, T.even))
      end)

      it("all is true and any is false on an empty table", function()
         assert.is_true(T.all({}, T.even))
         assert.is_false(T.any({}, T.even))
      end)

      it("ignore hash keys", function()
         assert.is_true(T.all({ 2, x = 3 }, T.even))
         assert.is_false(T.any({ 1, x = 2 }, T.even))
      end)
   end)

   describe("table.allPairs / table.anyPairs", function()
      it("check hash values too", function()
         assert.is_false(T.allPairs({ 2, x = 3 }, T.even))
         assert.is_true(T.anyPairs({ 1, x = 2 }, T.even))
      end)

      it("allPairs is true and anyPairs is false on an empty table", function()
         assert.is_true(T.allPairs({}, T.even))
         assert.is_false(T.anyPairs({}, T.even))
      end)
   end)
end)
