package = "LuaTable"
version = "0.1"

source  = {
	url = "git://github.com/Luca96/lua-table",
	tag = "v0.1",
}

description = {
	summary = "A library that give superpowers to lua tables",
	detailed = [[
		This library extends the common lua table by adding 
		new functions from:
			- functional world: map, reduce, filter, reject, ...
			- handy utilities: tostring, shuffle, reverse, ...
			- iterators: range, step, iter, each, ...
	]],
	homepage = "https://github.com/Luca96/lua-table",
	license = "MIT/X11",
}

dependencies = {
    "lua"
}

build = {
    type = "builtin",
    modules = {
        luatable = "src/luatable.lua",
    },
    --copy_directories = { "doc", "test" }
}