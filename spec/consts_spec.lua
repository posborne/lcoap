require 'busted.runner'()
local consts = require 'lcoap.protocol.consts'

describe("CoAP Protocol Codes", function()
    it("Should define request codes",
       function() assert.equal(consts.CODES.REQUEST.GET, 1); end)

    it("Should define correct response codes", function()
        -- HTTP 401 => CoAP 4.01 => 4 << 5 | 1
        assert.equal(consts.CODES.RESPONSE.UNAUTHORIZED, 4 << 5 | 1)
        -- HTTP 200 => COAP 2.03 => 2 << 5 | 3
        --             CoAP 2.05 => 2 << 5 | 5
        assert.equal(consts.CODES.RESPONSE.VALID, 2 << 5 | 3)
        assert.equal(consts.CODES.RESPONSE.CONTENT, 2 << 5 | 5)
    end)
end)

