local T = require "luatable"
local h = require "helpers"
local plain, is_enhanced, sorted = h.plain, h.is_enhanced, h.sorted

describe("utility", function()

   describe("table.info", function()
      -- info() prints through a cached `print`, so check its text in the source instead
      local function read(path)
         local f = assert(io.open(path, "rb"))
         local text = f:read("*a")
         f:close()
         return text
      end

      it("reports a version that has a release rockspec", function()
         local version = read("src/luatable.lua"):match("function table%.info%(%).-version: ([%d.]+)")
         assert.are.equal("0.8.0", version)
         local rockspec = read("rockspecs/luatable-" .. version .. "-1.rockspec")
         assert.are.equal(version .. "-1", rockspec:match('version = "([^"]+)"'))
         assert.are.equal("v" .. version, rockspec:match('tag = "([^"]+)"'))
      end)
   end)

   describe("table.purify", function()
      it("keeps array values and hash pairs", function()
         assert.are.same({ 1, 2, x = 3 }, plain(T.purify({ 1, 2, x = 3 })))
      end)

      it("purifies nested tables", function()
         assert.are.same({ { 1, 2 } }, plain(T.purify({ { 1, 2 } })))
      end)

      it("compacts sparse numeric keys keeping their order", function()
         assert.are.same({ "a", "b", "c" }, plain(T.purify({ [10] = "a", [20] = "b", [30] = "c" })))
      end)

      it("preserves a cycle under a hash key", function()
         local t = { 1, x = 2 }
         t.me = t
         local r = T.purify(t)
         assert.is_true(rawequal(r.me, r))
         assert.is_false(rawequal(r, t))
         assert.are.equal(1, r[1])
         assert.are.equal(2, r.x)
      end)

      it("preserves a cycle under a numeric key", function()
         local t = { 1 }
         t[2] = t
         local r = T.purify(t)
         assert.is_true(rawequal(r[2], r))
         assert.are.equal(1, r[1])
      end)
   end)

   describe("table.max / table.min", function()
      it("max with an explicit comparator", function()
         assert.are.equal(3, T.max({ 1, 3, 2 }, T.gt))
      end)

      it("min with an explicit comparator", function()
         assert.are.equal(1, T.min({ 3, 1, 2 }, T.lt))
      end)

      it("return nil for an empty table", function()
         assert.is_nil(T.max({}, T.gt))
         assert.is_nil(T.min({}, T.lt))
      end)

      it("max works without a comparator", function()
         assert.are.equal(3, T.max({ 1, 3, 2 }))
      end)

      it("min without a comparator returns the smallest value", function()
         assert.are.equal(1, T.min({ 3, 1, 2 }))
      end)
   end)

   describe("table.avg", function()
      it("returns the mean of the array values", function()
         assert.are.equal(2, T.avg({ 1, 2, 3 }))
         assert.are.equal(2.5, T.avg({ 2, 3 }))
      end)

      it("returns 0 for an empty table", function()
         assert.are.equal(0, T.avg({}))
      end)
   end)

   describe("table.maximize / table.minimize", function()
      local t = { -3, 1, 2 }

      it("maximize returns the value with the highest f(value)", function()
         assert.are.equal(-3, T.maximize(t, T.sqr))
      end)

      it("minimize returns the value with the lowest f(value)", function()
         assert.are.equal(1, T.minimize(t, T.sqr))
      end)

      it("forward extra args to the function", function()
         assert.are.equal(-3, T.maximize(t, T.pow, 2))
         assert.are.equal(-3, T.minimize(t, T.mul, 1))
      end)
   end)

   describe("table.sample", function()
      before_each(function() math.randomseed(42) end)

      it("returns an element of the table", function()
         local t = { "a", "b", "c" }
         for _ = 1, 20 do
            assert.is_not_nil(T.find(t, T.sample(t)))
         end
      end)

      it("returns nil for an empty table", function()
         assert.is_nil(T.sample({}))
      end)
   end)

   describe("table.shuffle", function()
      before_each(function() math.randomseed(42) end)

      it("keeps the same elements", function()
         local t = { 1, 2, 3, 4, 5, 6 }
         T.shuffle(t)
         assert.are.same({ 1, 2, 3, 4, 5, 6 }, sorted(t))
      end)

      it("shuffles in place and returns the same table", function()
         local t = { 1, 2, 3 }
         assert.is_true(rawequal(t, T.shuffle(t)))
      end)

      it("leaves empty and one-element tables unchanged", function()
         assert.are.same({}, T.shuffle({}))
         assert.are.same({ 7 }, T.shuffle({ 7 }))
      end)

      it("makes every ordering equally likely", function()
         -- regression: the old algorithm gave some orderings 4/27 and others 5/27
         local runs, counts = 60000, {}

         for _ = 1, runs do
            local key = table.concat(T.shuffle({ 1, 2, 3 }))
            counts[key] = (counts[key] or 0) + 1
         end

         local expected = runs / 6
         local orderings = 0

         for key, n in pairs(counts) do
            orderings = orderings + 1
            assert.is_true(math.abs(n - expected) <= expected * 0.05,
               ("ordering %s came up %d times, expected about %d"):format(key, n, expected))
         end

         assert.are.equal(6, orderings)
      end)
   end)

   describe("table.reverse", function()
      it("reverses an even-length table in place", function()
         local t = { 1, 2, 3, 4 }
         assert.is_true(rawequal(t, T.reverse(t)))
         assert.are.same({ 4, 3, 2, 1 }, t)
      end)

      it("reverses an odd-length table", function()
         assert.are.same({ 3, 2, 1 }, T.reverse({ 1, 2, 3 }))
      end)

      it("handles empty and single-element tables", function()
         assert.are.same({}, T.reverse({}))
         assert.are.same({ 1 }, T.reverse({ 1 }))
      end)
   end)

   describe("table.slice", function()
      local t = { 1, 2, 3, 4, 5 }

      it("returns a copy of the whole table by default", function()
         local r = T.slice(t)
         assert.is_false(rawequal(t, r))
         assert.is_true(is_enhanced(r))
         assert.are.same({ 1, 2, 3, 4, 5 }, plain(r))
      end)

      it("returns the i..j range inclusive", function()
         assert.are.same({ 2, 3 }, plain(T.slice(t, 2, 3)))
      end)

      it("counts negative indices from the end", function()
         assert.are.same({ 3, 4 }, plain(T.slice(t, -3, -2)))
         assert.are.same({ 4, 5 }, plain(T.slice(t, -2)))
      end)

      it("clamps negative indices below the start", function()
         assert.are.same({ 1, 2 }, plain(T.slice(t, -100, 2)))
      end)

      it("skips nils past the end", function()
         assert.are.same({ 4, 5 }, plain(T.slice(t, 4, 10)))
      end)
   end)

   describe("table.find", function()
      it("returns the index of the first occurrence", function()
         assert.are.equal(2, T.find({ "a", "b", "b" }, "b"))
      end)

      it("returns nil when the value is missing", function()
         assert.is_nil(T.find({ 1, 2 }, 3))
      end)
   end)

   describe("table.clone", function()
      it("deep-copies every key/value pair", function()
         local src = { 1, x = { 2, { 3 } } }
         local copy = T.clone(src)
         assert.are.same(src, plain(copy))
         assert.is_false(rawequal(src, copy))
         assert.is_false(rawequal(src.x, copy.x))
         assert.is_false(rawequal(src.x[2], copy.x[2]))
      end)

      it("makes the copy and its nested tables enhanced", function()
         local copy = T.clone({ x = {} })
         assert.is_true(is_enhanced(copy))
         assert.is_true(is_enhanced(copy.x))
      end)

      it("reproduces a cycle in the copy", function()
         local t = { 1 }
         t.self = t
         local c = T.clone(t)
         assert.is_false(rawequal(c, t))
         assert.is_true(rawequal(c.self, c))
         assert.are.equal(1, c[1])
      end)

      it("keeps shared references shared in the copy", function()
         local s = {}
         local c = T.clone({ a = s, b = s })
         assert.is_true(rawequal(c.a, c.b))
         assert.is_false(rawequal(c.a, s))
      end)
   end)

   describe("table.merge", function()
      it("concatenates array values, keeping duplicates", function()
         assert.are.same({ 1, 2, 2, 3 }, plain(T.merge({ 1, 2 }, { 2, 3 })))
      end)

      it("ignores hash keys", function()
         assert.are.same({ 1, 2 }, plain(T.merge({ 1, x = 9 }, { 2, y = 9 })))
      end)
   end)

   describe("table.unique", function()
      it("removes duplicates keeping first-seen order", function()
         assert.are.same({ 3, 1, 2 }, plain(T.unique({ 3, 1, 3, 2, 1 })))
      end)

      it("returns an enhanced table", function()
         assert.is_true(is_enhanced(T.unique({})))
      end)
   end)

   describe("table.keyList / table.valueList / table.valueSequence", function()
      local t = { 10, 20, x = 30 }

      it("keyList lists every key", function()
         assert.are.same(sorted({ 1, 2, "x" }), sorted(T.keyList(t)))
      end)

      it("valueList lists every value", function()
         assert.are.same({ 10, 20, 30 }, sorted(T.valueList(t)))
      end)

      it("valueSequence lists only the array part, in order", function()
         assert.are.same({ 10, 20 }, plain(T.valueSequence(t)))
      end)
   end)

   describe("table.equal", function()
      it("compares array values in order", function()
         assert.is_true(T.equal({ 1, 2, 3 }, { 1, 2, 3 }))
         assert.is_false(T.equal({ 1, 2, 3 }, { 1, 3, 2 }))
         assert.is_false(T.equal({ 1, 2 }, { 1, 2, 3 }))
      end)

      it("matches the README example (shallow vs deep)", function()
         local t1 = { 1, 2, 3, x = { 4, 5 } }
         local t2 = { 1, 2, 3, 4, 5 }
         assert.is_false(T.equal(t1, t2))
         assert.is_true(T.equal(t1, t2, true))
      end)

      it("treats two empty tables as equal", function()
         assert.is_true(T.equal({}, {}))
      end)

      it("compares nested values in their original order", function()
         assert.is_true(T.equal({ { 1 }, 2 }, { 1, 2 }))
         assert.is_false(T.equal({ { 1 }, 2 }, { 2, 1 }))
      end)

      it("deep equality does not depend on pairs order", function()
         local t = { 1, 2, alpha = 1, bravo = { 2, 3 }, charlie = "x", delta = 4,
                     echo = { y = 5 }, foxtrot = 6, golf = true, hotel = 8, india = 9,
                     juliet = { 10, { 11 } } }
         assert.is_true(T.equal(t, h.reordered(t), true))

         local words = { alpha = 1, bravo = 2, charlie = 3, delta = 4, echo = 5,
                         foxtrot = 6, golf = 7, hotel = 8, india = 9, juliet = 10 }
         assert.is_true(T.equal(words, h.reordered(words), true))
         assert.is_true(T.equal(h.reordered(words), words, true))
      end)

      it("deep equality treats equal-content table keys alike", function()
         local a = { [{ 1 }] = "one", [{ 2 }] = "two", [{ 3, 4 }] = "pair" }
         local b = { [{ 3, 4 }] = "pair", [{ 2 }] = "two", [{ 1 }] = "one" }
         assert.is_true(T.equal(a, b, true))
         assert.is_false(T.equal(a, { [{ 1 }] = "two", [{ 2 }] = "one", [{ 3, 4 }] = "pair" }, true))
      end)

      it("terminates on cyclic tables", function()
         local t = { 1, 2 }
         t[3] = t
         t.x = t
         assert.is_true(T.equal(t, t))
         assert.is_true(T.equal(t, t, true))
         assert.is_true(T.equal(t, { 1, 2 }))
      end)
   end)
end)
