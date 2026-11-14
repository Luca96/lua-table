local T = require "luatable"

local function noop() end

describe("argument validation", function()

   describe("rejects a missing table", function()
      local fns = {
         "iter", "inverse", "range", "keys", "values", "flat", "deepflat", "purify",
         "avg", "sample", "shuffle", "reverse", "slice", "find", "clone", "unique",
         "keyList", "valueList", "valueSequence", "keySet", "valueSet",
      }

      for _, name in ipairs(fns) do
         it("table." .. name .. "(nil)", function()
            assert.error_matches(function() T[name](nil) end, "table%." .. name .. "%(%)")
         end)
      end

      for _, name in ipairs({ "merge", "union", "negation", "intersect", "equal" }) do
         it("table." .. name .. " with a nil second table", function()
            assert.error_matches(function() T[name]({}, nil) end, "table%." .. name .. "%(%)")
         end)
      end
   end)

   describe("rejects a missing table or function", function()
      local fns = {
         "eachi", "each", "map", "accept", "reject", "flatmap",
         "all", "any", "allPairs", "anyPairs", "maximize", "minimize",
      }

      for _, name in ipairs(fns) do
         it("table." .. name .. "(nil, f)", function()
            assert.error_matches(function() T[name](nil, noop) end, "table%." .. name .. "%(%)")
         end)

         it("table." .. name .. "(t, nil)", function()
            assert.error_matches(function() T[name]({}, nil) end, "table%." .. name .. "%(%)")
         end)
      end

      it("table.reduce(t, base, nil)", function()
         assert.error_matches(function() T.reduce({}, 0, nil) end, "table%.reduce%(%)")
      end)

      it("table.max / table.min with a non-function comparator", function()
         assert.error_matches(function() T.max({}, 1) end, "table%.max%(%)")
         assert.error_matches(function() T.min({}, 1) end, "table%.min%(%)")
      end)
   end)

   describe("rejects non-number arguments", function()
      it("table.init / zeros / ones", function()
         assert.error_matches(function() T.init("3", 0) end, "table%.init%(%)")
         assert.error_matches(function() T.zeros("3") end, "table%.zeros%(%)")
         assert.error_matches(function() T.ones("3") end, "table%.ones%(%)")
      end)

      it("table.range start / count / step", function()
         assert.error_matches(function() T.range({}, "1") end, "table%.range%(%)")
         assert.error_matches(function() T.range({}, 1, "2") end, "table%.range%(%)")
         assert.error_matches(function() T.range({}, 1, 2, "1") end, "table%.range%(%)")
      end)

      it("table.slice i / j", function()
         assert.error_matches(function() T.slice({}, "1") end, "table%.slice%(%)")
         assert.error_matches(function() T.slice({}, 1, "2") end, "table%.slice%(%)")
      end)

      it(":at and :shift", function()
         assert.error_matches(function() T {}:at("1") end, "table%.at%(%)")
         assert.error_matches(function() T {}:shift("1") end, "table%.shift%(%)")
      end)
   end)

   describe("rejects invalid values", function()
      it("group / slide with k <= 0 or a non-number k", function()
         assert.error_matches(function() T.group({}, 0) end, "table%.group%(%)")
         assert.error_matches(function() T.slide({}, -1) end, "table%.slide%(%)")
         assert.error_matches(function() T.group({}, "2") end, "table%.group%(%)")
      end)

      it("ofChars with a non-string", function()
         assert.error_matches(function() T.ofChars(123) end, "table%.ofChars%(%)")
      end)

      it("lshift / rshift with a negative pos", function()
         assert.error_matches(function() T { 1 }:lshift(-1) end, "table%.lshift%(%)")
         assert.error_matches(function() T { 1 }:rshift(-1) end, "table%.rshift%(%)")
      end)
   end)

   describe("error position", function()
      -- Runs fn (which records the line it calls the library from) and returns that
      -- line and the error message. The message must point at that line in this file,
      -- not at a line inside luatable.lua.
      local function caught(fn)
         local line
         local ok, err = pcall(fn, function() line = debug.getinfo(2, "l").currentline end)
         assert.is_false(ok)
         return line, err
      end

      local function assert_points_at_caller(line, err)
         assert.matches("validation_spec%.lua:" .. line .. ":", err)
         assert.is_nil(err:find("luatable.lua", 1, true))
      end

      it("points at the caller for a missing table", function()
         assert_points_at_caller(caught(function(here) here(); T.map(nil, print) end))
      end)

      it("points at the caller for a missing function", function()
         assert_points_at_caller(caught(function(here) here(); T.map({}, nil) end))
      end)

      it("points at the caller for a non-number", function()
         assert_points_at_caller(caught(function(here) here(); T.zeros("3") end))
      end)

      it("points at the caller for an invalid value", function()
         assert_points_at_caller(caught(function(here) here(); T.group({}, 0) end))
      end)

      it("points at the caller for a method call", function()
         assert_points_at_caller(caught(function(here) here(); T { 1 }:lshift(-1) end))
      end)
   end)

   describe("warnings", function()
      -- The library captures `print` when it is loaded, so the stub has to be in
      -- place before the module is (re)loaded.
      local print_stub, lib

      before_each(function()
         print_stub = stub(_G, "print")
         package.loaded.luatable = nil
         lib = require "luatable"
      end)

      after_each(function()
         print_stub:revert()
         package.loaded.luatable = nil
         require "luatable"
      end)

      it("slice warns when i > j and returns an empty table", function()
         local r = lib.slice({ 1, 2, 3 }, 3, 1)
         assert.stub(print_stub).was.called(1)
         assert.stub(print_stub).was.called_with(match.matches("table%.slice%(%)"))
         assert.are.equal(0, #r)
      end)

      it("slice does not warn for a valid range", function()
         lib.slice({ 1, 2, 3 }, 1, 2)
         assert.stub(print_stub).was_not.called()
      end)
   end)
end)
