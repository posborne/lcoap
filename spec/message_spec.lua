require 'busted.runner'()
local Message = require 'lcoap.protocol.message'
local consts  = require 'lcoap.protocol.consts'

describe("CoAP Message Packing", function()
    -- Wireshark Capture of "coap-client -m get coap://192.168.1.175/sensors/potentiometer"
    -- ============================
    -- Constrained Application Protocol, Confirmable, GET, MID:9626
    -- 01.. .... = Version: 1
    -- ..00 .... = Type: Confirmable (0)
    -- .... 0000 = Token Length: 0
    -- Code: GET (1)
    -- Message ID: 9626
    -- Opt Name: #1: Uri-Path: sensors
    -- Opt Name: #2: Uri-Path: potentiometer
    -- [Uri-Path: /sensors/potentiometer]
    it("Should pack a basic GET request correctly", function()
        local expected = ("\x40\x01\x25\x9a\xb7\x73\x65\x6e" ..
                             "\x73\x6f\x72\x73\x0d\x00\x70\x6f" ..
                             "\x74\x65\x6e\x74\x69\x6f\x6d\x65" ..
                             "\x74\x65\x72")
        local m = Message.new_get("/sensors/potentiometer",
                                  {message_id = 9626})
        local packed = m:pack()
        assert.equal(expected, packed)
    end)

    -- Constrained Application Protocol, Confirmable, PUT, MID:42799
    -- 01.. .... = Version: 1
    -- ..00 .... = Type: Confirmable (0)
    -- .... 0000 = Token Length: 0
    -- Code: PUT (3)
    -- Message ID: 42799
    -- Opt Name: #1: Uri-Path: actuators
    --     Opt Desc: Type 11, Critical, Unsafe
    --     1011 .... = Opt Delta: 11
    --     .... 1001 = Opt Length: 9
    --     Uri-Path: actuators
    -- Opt Name: #2: Uri-Path: leds
    --     Opt Desc: Type 11, Critical, Unsafe
    --     0000 .... = Opt Delta: 0
    --     .... 0100 = Opt Length: 4
    --     Uri-Path: leds
    -- Opt Name: #3: Uri-Path: red
    --     Opt Desc: Type 11, Critical, Unsafe
    --     0000 .... = Opt Delta: 0
    --     .... 0011 = Opt Length: 3
    --     Uri-Path: red
    -- End of options marker: 255
    -- [Uri-Path: /actuators/leds/red]
    -- Payload: Payload Content-Format: application/octet-stream (no Content-Format), Length: 2
    it("Should pack a basic PUT request correctly", function()
        local expected = ("\x40\x03\xa7\x2f\xb9\x61\x63\x74\x75\x61\x74" ..
                             "\x6f\x72\x73\x04\x6c\x65\x64\x73\x03\x72\x65\x64\xff\x4f\x6e")
        local m = Message.new_put("/actuators/leds/red", "On",
                                           {message_id = 42799})
        local packed = m:pack()
        assert.equal(packed, expected)
    end)
end)

describe("CoAP Message Parsing", function()
    -- Constrained Application Protocol, Acknowledgement, 2.05 Content, MID:50243
    -- 01.. .... = Version: 1
    -- ..10 .... = Type: Acknowledgement (2)
    -- .... 0000 = Token Length: 0
    -- Code: 2.05 Content (69)
    -- Message ID: 50243
    -- Opt Name: #1: Content-Format: text/plain; charset=utf-8
    --     Opt Desc: Type 12, Elective, Safe
    --     1100 .... = Opt Delta: 12
    --     .... 0010 = Opt Length: 2
    --     Content-type: text/plain; charset=utf-8
    -- End of options marker: 255
    -- Payload: Payload Content-Format: text/plain; charset=utf-8, Length: 5
    it("Should be able to decode a response message", function()
        local datagram = "\x60\x45\xc4\x43\xc2\x00\x00\xff\x30\x2e\x30\x35\x0a"
        local m, _err = Message.parse(datagram)
        assert.equal(m.type, consts.TYPES.ACKNOWLEDGEMENT)
        assert.equal(m.code, consts.CODES.RESPONSE.CONTENT)
        assert.equal(m.message_id, 50243)
        assert.equal(#m.options, 1)
        local o = m.options[1]
        assert.equal(o.id, 12)
        assert.equal(o.value, consts.CONTENT_FORMATS.TEXT)
        assert.equal(o.name, "Content-Format")
        assert.equal(m.payload, "0.05\n")
    end)
end)
