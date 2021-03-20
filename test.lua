local u  = require 'luaunit'
local mp = require "mp"

local eq   = u.assertEquals
local fail = u.assertErrorMsgContains

local function check_eq(t, t2)
   local bytes = mp.encode(t)
   local ok, r = pcall(mp.decode, bytes)
   if not ok then
      print(mp.tohex(bytes))
      error(r)
   end
   eq(mp.decode(bytes), t2 or t)
end

function _G.test_basic()
   local a = "\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16"
   eq(mp.fromhex(mp.tohex(a)), a)
   eq({mp.decode "\1\2"}, {1,2})
   check_eq {
      foo = 1,
      bar = 2,
      array = {1,2,3,4}
   }
   check_eq {
      foo = 1,
      bar = 2,
      array = mp.array {1,2,3,4}
   }
   check_eq {
      foo = 1,
      bar = 2,
      array = mp.array {1,2,3,4}
   }
   check_eq {
      foo = 1,
      bar = 2,
      array = mp.map {1,2,3,4}
   }
   check_eq {
      f1 = 1,
      f2 = 2,
      fs1 = "foo",
      fs2 = "bar",
      fm = {
         ft1 = 1,
         ft2 = "foo",
         ft3 = {1,2,3},
         ft4 = { ft5 = { ft6 = { ft7 = { ft8 = { ft9 = mp.array { } } } } } }
      },
      fa_long = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17},
      fm_long = {
         f1 = 1, f2 = 2, f3 = 3, f4 = 4, f5 = 5, f6 = 6, f7 = 7, f8 = 8,
         f9 = 9, f10 = 10, f11 = 11, f12 = 12, f13 = 13, f14 = 14, f15 = 15, f16 = 16,
         f17 = 17, f18 = 18, f19 = 19, f20 = 20,
      }
   }
end

function _G.test_boolean()
   check_eq(true)
   check_eq(false)
end

function _G.test_number()
   check_eq(0)
   check_eq(127)
   check_eq(128)
   check_eq(0x100 + 100)
   check_eq(0x10000 + 100)
   check_eq(0x100000000 + 100)
   check_eq(-1)
   check_eq(-32)
   check_eq(-33)
   check_eq(-100)
   check_eq(-0x100 - 100)
   check_eq(-0x10000 - 100)
   check_eq(-0x100000000 - 100)
   check_eq("a")
   check_eq("aaa")
   check_eq(("a"):rep(31))
   check_eq(("a"):rep(32))
   check_eq(("a"):rep(0x100+100))
   check_eq(("a"):rep(0x10000+100))
   check_eq(1.123)
   check_eq(function() return "u",100 end, 100)
   check_eq(function() return "u",200 end, 200)
   check_eq(function() return "u",0x100 + 100 end, 0x100 + 100)
   check_eq(function() return "u",0x10000 + 100 end, 0x10000 + 100)
   check_eq(function() return "u",0x100000000 + 100 end, 0x100000000 + 100)
   check_eq(function() return "i",100 end, 100)
   check_eq(function() return "i",0x100 + 100 end, 0x100 + 100)
   check_eq(function() return "i",0x10000 + 100 end, 0x10000 + 100)
   check_eq(function() return "i",0x100000000 + 100 end, 0x100000000 + 100)
   check_eq(function() return "f",1.5 end, 1.5)
   check_eq(function() return "d",1.5 end, 1.5)
   check_eq(mp.meta("int", { value = 1 }), 1)
   check_eq(mp.meta("value", { value = 1 }), 1)
end

function _G.test_list()
   do
      local a = {}
      for i = 1, 1000 do
         a[#a+1] = i
      end
      check_eq(a)
      for i = 1, 65535 do
         a[#a+1] = i
      end
      check_eq(a)
   end
   do
      local a = {}
      for i = 1, 1000 do
         a["foo"..i] = i
      end
      check_eq(a)
      for i = 1, 65536 do
         a["foo"..(i+1000)] = i
      end
      check_eq(a)
   end
end

function _G.test_nil()
   check_eq(nil)
   eq(mp.decode(mp.encode(mp.null)), nil)
   eq(mp.decode(mp.newencoder()(mp.null)), nil)
   eq(tostring(mp.null), "null")
end

function _G.test_ext()
   local e = { type = 1, value = "foo" }
   local function check_ext(t, v)
      check_eq(function() return "e", t, v end, { type = t, value = v })
   end
   check_ext(1, "a")
   check_ext(1, ("a"):rep(2))
   check_ext(1, ("a"):rep(4))
   check_ext(1, ("a"):rep(8))
   check_ext(1, ("a"):rep(16))
   check_ext(1, ("a"):rep(50))
   check_ext(1, ("a"):rep(30000))
   check_ext(1, ("a"):rep(65537))
   check_ext(1, ("a"):rep(3))
   eq(mp.decode(mp.encode(function() return "e", 1, "foo" end),
         nil, nil, function(t, v)
            eq(t, 1)
            eq(v, "foo")
            return v
         end), "foo")
   eq(mp.decode(mp.encode(function() return "e", 1, "foo" end),
         nil, nil, function() end), e)
   check_eq(mp.meta("extension", e), e)
   --check_eq(mp.meta("t", mp.meta("ext", { value = e })), e)
   local e1 = mp.meta("extension", "foo")
   e1.type = 1
   check_eq(e1, e)
   local e2 = mp.meta("extension", setmetatable({type = 1, value = "foo"}, {}))
   check_eq(e2, e)
end

function _G.test_handler()
   check_eq(function() return "T" end, true)
   eq(mp.decode(mp.encode(function() return "F" end)), false)
   check_eq(function() return "s", "foo" end, "foo")
   check_eq(function() return "b", "foo" end, "foo")

   local co = coroutine.create(function()end)
   local c = 0
   local v = mp.newencoder(function(v, k, t)
      assert(k == nil)
      assert(t == nil)
      if v == co then
         c = c + 1
         return "int", 1
      end
      return "nil"
   end)(co, co, co)
   eq(c, 3); eq(v, "\1\1\1")
   c = 0; v = mp.newencoder(function(v, k, t)
      assert(k >= 1 and k <= 3)
      assert(type(t) == "table")
      if v == co then
         c = c + 1
         return "int", 1
      end
      return "nil"
   end)({co, co, co})
   eq(c, 3); eq(v, "\x93\1\1\1")
   c = 0; v = mp.newencoder(function(v, k, t)
      assert(k == "foo")
      assert(type(t) == "table")
      if v == co then
         c = c + 1
         return "int", 1
      end
      return "nil"
   end)({foo = co})
   eq(c, 1); eq(v, "\x81\xA3foo\1")
   c = 0; v = mp.newencoder(function(v, k, t)
      assert(k == nil)
      assert(type(t) == "table")
      if v == co then
         c = c + 1
         return "int", 1
      end
      return "nil"
   end)({[co] = "bar"})
   eq(c, 1); eq(v, "\x81\1\xA3bar")
end

function _G.test_error()
   fail("number expected, got nil",
      function() mp.encode(function() return "u", nil end) end)
   fail("integer expected, got number",
      function() mp.encode(function() return "u", 1.2 end) end)
   fail("attempt to index a msgpack.null value",
      function() return mp.null.abc end)
   fail("attempt to index a msgpack.null value",
      function() mp.null.abc = 10 end)
   local a = {} a[1] = a
   fail("array level too deep", function() mp.encode(a) end)
   a = {} a.foo = a
   fail("map level too deep", function() mp.encode(a) end)
   fail("invalid key in map", function()
      mp.encode { [function() end] = 1 }
   end)
   fail("integer expected for extension type, got boolean", function()
      mp.encode(function() return "e", true end)
   end)
   fail("invalid extension type: 10000", function()
      mp.encode(function() return "e", 10000 end)
   end)
   fail("string expected for extension value, got boolean", function()
      mp.encode(function() return "e", 1, true end)
   end)
   fail("'pack' field expected in handler object", function()
      mp.encode(mp.meta("handler", {}))
   end)
   fail("'value' field expected in wrapper object", function()
      mp.encode(mp.meta("int", {}))
   end)
   fail("invalid type 'thread'", function()
      mp.encode(coroutine.create(function() end))
   end)
   fail("invalid string at offset 2: 1 bytes expected, got 0 bytes",
      function() mp.decode("\161") end)
   fail("invalid string at offset 2: 1 bytes expected, got 0 bytes",
      function() mp.decode("\161") end)
   fail("unexpected end of message at offset 2: map key expected",
      function() mp.decode("\129") end)
   fail("unexpected end of message at offset 3: map value expected",
      function() mp.decode("\129\1") end)
   fail("unexpected end of message at offset 2: array element expected",
      function() mp.decode("\145") end)
   fail("invalid char '193' at offset 2",
      function() mp.decode("\193") end)
end

if _VERSION == "Lua 5.1" and not _G.jit then
   u.LuaUnit.run()
else
   os.exit(u.LuaUnit.run(), true)
end

-- unixcc: run='rm -f *.gcda; time lua test.lua; gcov mp.c'
-- win32cc: run='del /s/q *.gcda & lua test.lua & gcov mp.c'
