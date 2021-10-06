require 'busted.runner'()
local Option = require 'lcoap.protocol.option'

describe("CoAP Options Classes", function()
    it("packs strings properly", function()
        local o = Option.new_uri_host("google.com")
        assert.same(o:pack(), "google.com")
    end)

    it("packs single byte uints properly", function()
        local o = Option.new_uri_port(0x50)
        assert.equal(o:pack(), "\x50")
    end)

    it("packs 3-byte uints properly", function()
        local o = Option.new_uri_port(0x123456)
        assert.equal(o:pack(), "\x12\x34\x56")
    end)

    it("packs 4-byte uints properly", function()
        local o = Option.new_uri_port(0x12345678)
        assert.equal(o:pack(), "\x12\x34\x56\x78")
    end)
end)
