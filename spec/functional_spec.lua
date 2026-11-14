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

      it("keeps the original element order with nesting in the middle", function()
         assert.are.same({ 1, 2, 3, 4 }, plain(T.flat({ 1, { 2, { 3 } }, 4 })))
      end)

      it("skips a reference back to the table itself", function()
         local t = { 1, 2 }
         t[3] = t
         assert.are.same({ 1, 2 }, plain(T.flat(t)))
      end)

      it("skips a reference back to an ancestor deeper down", function()
         local t = { 1 }
         t[2] = { 2, t }
         assert.are.same({ 1, 2 }, plain(T.flat(t)))
      end)

      it("still flattens a shared (non-cyclic) table every time it appears", function()
         local s = { 1 }
         assert.are.same({ 1, 1 }, plain(T.flat({ s, s })))
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

      it("skips a reference back to the table under a hash key", function()
         local t = { 1 }
         t.x = t
         assert.are.same({ 1 }, plain(T.deepflat(t)))
      end)

      it("visits hash keys in sorted order, after the array part", function()
         assert.are.same({ 3, 1, 2 }, plain(T.deepflat({ 3, b = 2, a = 1 })))
         -- regression: with 10 keys, pairs order is practically never sorted
         local t = { c = 3, h = 8, a = 1, j = 10, e = 5, b = 2, g = 7, d = 4, i = 9, f = 6 }
         assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, plain(T.deepflat(t)))
      end)

      it("ranks key types: numbers, strings, booleans, tables, then the rest", function()
         local f = function() end
         local t = { [f] = "func", [{}] = "table", [true] = "true", [false] = "false",
                     s = "string", [2.5] = "number", [-1] = "negative" }
         assert.are.same({ "negative", "number", "string", "false", "true", "table", "func" },
            plain(T.deepflat(t)))
      end)

      it("orders table keys by their content", function()
         assert.are.same({ "a", "b" }, plain(T.deepflat({ [{ 2 }] = "b", [{ 1 }] = "a" })))
         -- the first difference decides; a shorter prefix comes first
         local t = { [{ 1, 2, 9 }] = "c", [{ 1, 2 }] = "a", [{ 1, 2, 3 }] = "b", [{ 0, 99 }] = "z" }
         assert.are.same({ "z", "a", "b", "c" }, plain(T.deepflat(t)))
         -- key content is flattened with the same rules (nested, hash keys sorted)
         t = { [{ y = 2, x = 1 }] = "b", [{ { 1 }, 1 }] = "a" }
         assert.are.same({ "a", "b" }, plain(T.deepflat(t)))
      end)

      it("orders keys with the same content by their value", function()
         local t = { [{ 1 }] = "b", [{ 1 }] = "a", [{ 1 }] = "c" }
         assert.are.same({ "a", "b", "c" }, plain(T.deepflat(t)))
      end)

      it("terminates when a key table refers back to the table", function()
         local t = { 1 }
         local k = { 2 }
         k[2] = t
         k[3] = k
         t[k] = 3
         t[{ 0 }] = 4
         assert.are.same({ 1, 4, 3 }, plain(T.deepflat(t)))
      end)

      it("terminates when the table is a key of itself (empty content, sorts first)", function()
         local t = { 1 }
         t[t] = 2
         t[{ 0 }] = 3
         assert.are.same({ 1, 2, 3 }, plain(T.deepflat(t)))
      end)

      it("handles NaN values under equal-content keys", function()
         local nan = 0 / 0
         local r = T.deepflat({ [{ 1 }] = nan, [{ 1 }] = 2, [{ 1 }] = nan })
         assert.are.equal(3, #r)
         assert.are.equal(2, r[1])
         assert.is_true(r[2] ~= r[2] and r[3] ~= r[3])
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
