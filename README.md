# lua-mp - Yet another msgpack implement for Lua

[![Build Status](https://travis-ci.org/starwing/lua-mp.svg?branch=master)](https://travis-ci.org/starwing/lua-mp)[![Coverage Status](https://coveralls.io/repos/github/starwing/lua-mp/badge.svg?branch=master)](https://coveralls.io/github/starwing/lua-mp?branch=master)



Lua-mp is a simple C module for Lua to manipulate msgpack encoding/decoding.

## Install

The simplest way to install it is using Luarocks:

```shell
luarocks install --server=https://luarocks.org/dev lua-mp
```

Or, just compile the single C file:

```shell
# Linux
gcc -o mp.so -O3 -fPIC -shared mp.c
# macOS
gcc -o mp.so -O3 -fPIC -shared -undefined dynamic_lookup mp.c
# Windows
cl /Fe mp.dll /LD /MT /O2 /DLUA_BUILD_AS_DLL /Ipath/to/lua/include mp.c path/to/lua/lib
```

# Example

```lua
local mp = require "mp"
local serpent = require "serpent" -- just for print table

local bytes = mp.encode {
  name = "alice",
  phone_list = { "1311234", "1310024" }
}
print(mp.tohex(bytes))

local t = mp.decode(bytes)
print(serpent.block(t))
```

 ## Document

| Routine                                   | Returns          | Description                                                  |
| ----------------------------------------- | ---------------- | ------------------------------------------------------------ |
| `decode(string[, i[, j[, ext_handler]]])` | `object`,  `pos` | decode a msgpack string into object, returns the decoded object and unread position |
| `encode(...)`                             | `string`         | Accept any values and create a msgpack encoding string       |
| `null`                                    | `-`              | the `null` object can be used in array/map                   |
| `array(...)`                              | ...              | mark all it's arguments to array                             |
| `map(...)`                                | ...              | mark all it's arguments to map                               |
| `meta(type, ...)`                         | ...              | mark all it's arguments to `type`                            |
| `tohex(string)`                           | `string`         | convert a binary string into hexadigit mode for human reading |
| `fromhex(string)`                         | `string`         | convert hexadigit back into binary string                    |

### Decoding mapping

| Msgpack Type                        | Lua Type                            |
| ----------------------------------- | ----------------------------------- |
| `null`                              | `nil`                               |
| `true`, `false`                     | `boolean`                           |
| `int`, `uint`, `float32`, `float64` | `number`                            |
| `bin`, `string`                     | `string`                            |
| `ext`                               | `{ type = number, value = string }` |

`decode()` accepts a string, and optional two pos `i` and `j` (based on 1), and a optionl `env_handler` function  for arguments. if there is `ext` type in `msgpack` string, the ext_handler will be called with `type` and `value` and returns a object for use. if the handler returns nothing, the default type/value table will be used.

It returns the decoded object, and if there is any remain bytes in string, returns the current reading position for next reading. So you can iterate all object in a string using a loop:

```lua
local pos = 1
local values = {}
while pos do
  values[#values+1], pos = mp.decode(data, pos)
end
```

### Encoding Mapping

| Lua Type   | Msgpack Type                                                 |
| ---------- | ------------------------------------------------------------ |
| `nil`      | `null`                                                       |
| `boolean`  | `true`, `false`                                              |
| `number`   | `int`, `float32`, `float64`                                  |
| `string`   | `string`                                                     |
| `function` | A [handler function](#handler-function) returns the actually values to encode |
| `table`    | `array` or `map` or any other (using `meta` types)           |

### Meta types

meta type is a table, that has a metatable, which has a field `"msgpack.type"` with below values:

| `"msgpack.type"` | `"Description"` |
| ---------------- | --------------- |
| `"null"` | encode a `null` |
| `"True"`, `"False"` | encode a `true` or `false` |
| `"int"`, `"uint"`, `"float"`, `"double"` | reads the `value` field of table, and encode a number value |
| `"string"`, `"binary"` | same as above, but encoding a `string` or `binary` value |
| `"value"` | same as above, but encode using the Lua type of value field |
| `"handler"` | reads the `pack` field as a function, call with table itself, and returns the actually values to encode |
| `"array"` | treat table as a array |
| `"map"` | treat table as a map |
| `"extension"` | reads the `type` and `value` fields in table and encode a `ext` value |

meta value can get by `mp.meta()` or `mp.array()`, `mp.map()` routines:

```lua
-- get a meta value of uint:
local uint = mp.meta("uint", 123)
-- get a array:
local array = mp.array { 1,2,3,4 }
-- set all tables to map:
mp.map(map1, map2, map3)
```

### Handler function

A `handler` should first returns a `"msgpack.type"` string, and if needed, return the actual value to be encoded. for `"entension"` type, `handler` should returns both `type` and `value`:

```lua
local function handler_to_get_a_uint() return "uint", 123 end
local function handler_to_get_a_ext() return "extension", 1, "foo" end
local function handler_to_get_a_true() return "True" end
local function handler_to_another_handler() return "handler", { pack = handler } end
```

