local T = require "luatable"
local h = require "helpers"
local plain, is_enhanced = h.plain, h.is_enhanced

describe("set utils", function()

   describe("table.union", function()
      it("concatenates both tables without duplicates", function()
         assert.are.same({ 1, 2, 3 }, plain(T.union({ 1, 2 }, { 2, 3 })))
      end)

      it("also removes duplicates within one side", function()
         assert.are.same({ 1, 2 }, plain(T.union({ 1, 1 }, { 2, 2 })))
      end)

      it("returns an enhanced table", function()
         assert.is_true(is_enhanced(T.union({}, {})))
      end)
   end)

   describe("table.negation", function()
      it("keeps values of t1 that are not in t2", function()
         assert.are.same({ 1, 3 }, plain(T.negation({ 1, 2, 3 }, { 2, 4 })))
      end)

      it("keeps duplicates from t1", function()
         assert.are.same({ 1, 1 }, plain(T.negation({ 1, 2, 1 }, { 2 })))
      end)

      it("returns a copy of t1 when t2 is empty", function()
         assert.are.same({ 1, 2 }, plain(T.negation({ 1, 2 }, {})))
      end)
   end)

   describe("table.intersect", function()
      it("keeps values of t1 that are also in t2, in t1 order", function()
         assert.are.same({ 3, 2 }, plain(T.intersect({ 3, 1, 2 }, { 2, 3, 4 })))
      end)

      it("keeps duplicates from t1", function()
         assert.are.same({ 1, 1 }, plain(T.intersect({ 1, 2, 1 }, { 1 })))
      end)

      it("returns an empty table when nothing is shared", function()
         assert.are.same({}, plain(T.intersect({ 1 }, { 2 })))
      end)
   end)

   describe("table.keySet / table.valueSet", function()
      it("keySet maps every key to true", function()
         assert.are.same({ [1] = true, x = true }, plain(T.keySet({ "a", x = "b" })))
      end)

      it("valueSet maps every value to true", function()
         assert.are.same({ a = true, b = true }, plain(T.valueSet({ "a", "a", x = "b" })))
      end)

      it("return enhanced tables", function()
         assert.is_true(is_enhanced(T.keySet({})))
         assert.is_true(is_enhanced(T.valueSet({})))
      end)
   end)
end)
