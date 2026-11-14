-----------------------------------------------------------------------------------------
-- Shared helpers for the lua-table spec files
-----------------------------------------------------------------------------------------
local T = require "luatable"

local unpack = table.unpack or unpack
local helpers = {}

local function pack(...)
   return { n = select("#", ...), ... }
end

-- Recursive copy with every metatable dropped.
-- Enhanced tables carry __eq = table.equal (a flattening compare), and luassert's
-- `same`/`equal` honour __eq, so structural assertions must compare plain copies.
function helpers.plain(v, seen)
   if type(v) ~= "table" then
      return v
   end

   seen = seen or {}
   if seen[v] then
      return seen[v]
   end

   local copy = {}
   seen[v] = copy

   for k, x in next, v do
      copy[helpers.plain(k, seen)] = helpers.plain(x, seen)
   end

   return copy
end

-- Drain an iterator into a list of tuples: { {a, b}, {c, d}, ... }.
-- A safety limit stops runaway iterators from hanging the suite.
function helpers.collect(iter, limit)
   limit = limit or 1000
   local out = {}

   while true do
      local values = pack(iter())

      if values[1] == nil then
         return out
      end

      out[#out + 1] = { unpack(values, 1, values.n) }
      assert(#out <= limit, "iterator did not terminate after " .. limit .. " steps")
   end
end

-- Drain an iterator, keeping only the first value of each step.
function helpers.collect1(iter, limit)
   local out = {}

   for i, tuple in ipairs(helpers.collect(iter, limit)) do
      out[i] = tuple[1]
   end

   return out
end

-- True when t has the library's enhanced-table metatable (so it supports t:method()).
function helpers.is_enhanced(t)
   return type(t) == "table" and rawequal(getmetatable(t), getmetatable(T.new()))
end

-- Wrap a luassert spy in a real function: spies are callable tables, and the
-- library rejects callbacks whose type() is not "function".
function helpers.fn(s)
   return function(...) return s(...) end
end

-- Keys of t in `pairs` order, as one string (to compare iteration orders).
local function key_order(t)
   local keys = {}

   for k in next, t do
      keys[#keys + 1] = tostring(k)
   end

   return table.concat(keys, ",")
end

-- A table constructor with n nil fields presizes the hash part without storing anything.
local function presized(n)
   local fields = {}

   for i = 1, n do
      fields[i] = "_" .. i .. " = nil"
   end

   return assert((loadstring or load)("return {" .. table.concat(fields, ", ") .. "}"))()
end

-- Shallow copy of t with the same content but a different `pairs` order. A key's slot
-- depends on the hash-part size (and on insertion order when keys collide), so this
-- tries growing presized tables, inserting forwards and backwards, until the order
-- differs. Fails if none does (use several varied keys so that is practically impossible).
function helpers.reordered(t)
   local keys = {}

   for k in next, t do
      keys[#keys + 1] = k
   end

   local want = key_order(t)

   for size = 1, 10 do
      for _, backwards in ipairs({ true, false }) do
         local copy = presized(2 ^ size)

         for i = 1, #keys do
            local k = keys[backwards and #keys - i + 1 or i]
            copy[k] = t[k]
         end

         if key_order(copy) ~= want then
            return copy
         end
      end
   end

   error("reordered(): could not change the pairs order", 2)
end

-- Plain, sorted copy of a list; for results that follow the unspecified `pairs` order.
function helpers.sorted(list)
   local copy = {}

   for i, v in ipairs(helpers.plain(list)) do
      copy[i] = v
   end

   table.sort(copy, function(a, b)
      if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then
         return a < b
      end
      return tostring(a) < tostring(b)
   end)

   return copy
end

return helpers
