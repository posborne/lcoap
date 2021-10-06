package = "lcoap"
version = "0.1-1"
source = {
    url = "-- TODO Tarball Source Link --",
}
description = {
    summary = "A Pure Lua CoAP Protocol and Client Implementation",
    detailed = [[
        lcoap provides an implementation of the CoAP protocol described
        in RFC7525 suitable for a wide range of operating environments.
        The protocol layer on its own has no external dependencies outside
        of a few items from the std lib.

        In addition to the protocol implementation, an easy to use
        client implementation is provided based on luasocket.
    ]],
    homepage = "http://github.com/posborne/lcoap",
    license = "MIT",
}

-- https://www.mail-archive.com/luarocks-developers@lists.luaforge.net/msg00248.html
dependencies = {
    "lua >= 5.3", -- 5.3 required for bitwise operations
    "luasocket >= 2.0", -- luasocket dependency is optional
}

build = {
    type = "builtin",
    modules = {
        ["lcoap"] = "lcoap/init.lua",
        ["lcoap.protocol.message"] = "lcoap/protocol/message.lua",
        ["lcoap.protocol.consts"] = "lcoap/protocol/consts.lua",
        ["lcoap.protocol.option"] = "lcoap/protocol/option.lua",
        ["lcoap.client"] = "lcoap/client.lua",
    }
}
