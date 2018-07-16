package = "LuaTable"
version = "scm-1"

source = {
	url = "git://github.com/Luca96/lua-table",
}

description = {
	summary = "A library that give superpowers to lua tables",
	detailed = [[
		This library extends the common Lua table by adding iterators, operators and utility functions.
    Visit https://github.com/Luca96/lua-table for more info.
	]],
	homepage = "https://github.com/Luca96/lua-table",
	license = "MIT",
}

dependencies = {
    "lua"
}

build = {
    type = "builtin",
    modules = {
        luatable = "src/luatable.lua",
    },
}