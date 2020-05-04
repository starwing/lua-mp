package = "lua-mp"
version = "scm-1"

source = {
  url = "git://github.com/starwing/lua-mp.git",
}

description = {
  summary = "yet another msgpack implement for Lua",
  detailed = [[
This project implements a tiny msgpack C module for Lua
  ]],
  homepage = "https://github.com/starwing/lua-mp",
  license = "MIT",
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    mp = "mp.c";
  }
}
