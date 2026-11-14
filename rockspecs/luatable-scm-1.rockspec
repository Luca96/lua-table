rockspec_format = "3.0"
package = "LuaTable"
version = "scm-1"

source = {
	url = "git+https://github.com/Luca96/lua-table.git",
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

test_dependencies = {
    "busted",
}

test = {
    type = "busted",
}

build = {
    type = "builtin",
    modules = {
        luatable = "src/luatable.lua",
    },
}