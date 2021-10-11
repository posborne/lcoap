-- Lua CLI application which roughtly matches "coap-client" from libcoap:
-- https://libcoap.net/doc/reference/4.2.1/man_coap-client.html
local argparse = require "argparse"
local consts = require 'lcoap.protocol.consts'
local client = require 'lcoap.client'
local option = require 'lcoap.protocol.option'

local CONTENT_FORMAT_LOOKUP = {
    -- text/plain (plain)
    ["text/plain"] = consts.CONTENT_FORMATS.TEXT,
    ["text"] = consts.CONTENT_FORMATS.TEXT,
    -- application/link-format (link, link-format)
    ["application/link-format"] = consts.CONTENT_FORMATS.LINK_FORMAT,
    ["link"] = consts.CONTENT_FORMATS.LINK_FORMAT,
    ["link-format"] = consts.CONTENT_FORMATS.LINK_FORMAT,
    -- application/xml (xml)
    ["application/xml"] = consts.CONTENT_FORMATS.XML,
    ["xml"] = consts.CONTENT_FORMATS.XML,
    -- application/octet-stream (binary, octet-stream)
    ["application/octet-stream"] = consts.CONTENT_FORMATS.OCTET_STREAM,
    ["binary"] = consts.CONTENT_FORMATS.OCTET_STREAM,
    ["octet-stream"] = consts.CONTENT_FORMATS.OCTET_STREAM,
    -- application/exi (exi)
    ["application/exi"] = consts.CONTENT_FORMATS.EXI,
    ["exi"] = consts.CONTENT_FORMATS.EXI,
    -- application/json (json)
    ["application/json"] = consts.CONTENT_FORMATS.JSON,
    ["json"] = consts.CONTENT_FORMATS.JSON,
    -- application/cbor (cbor)]])
    ["application/cbor"] = consts.CONTENT_FORMATS.CBOR,
    ["cbor"] = consts.CONTENT_FORMATS.CBOR
}

local parser = argparse("client",
                        "Execute Client Command (similar to coap-client)")
parser:argument("url")
parser:option("-m --method",
              [[The request method for action (get|put|post|delete), default
is get. (Note that the string passed to -m is compared case-insensitive.)]])
parser:option("-e --text",
              "Include text as payload (use percent-encoding for non-ASCII characters).")
parser:option("-f --file", "File to send with PUT/POST (use - for STDIN).")
parser:option("-t --type", [[Content format for given resource for PUT/POST.
type must be either a numeric value reflecting a valid CoAP content format or a
string describing a registered format. The following registered content format
descriptors are supported, with alternative shortcuts given in parentheses:
    text/plain (plain)
    application/link-format (link, link-format)
    application/xml (xml)
    application/octet-stream (binary, octet-stream)
    application/exi (exi)
    application/json (json)
    application/cbor (cbor)]])
parser:option("-A --accept", [[Accepted media type.
type must be either a numeric value reflecting a valid CoAP content format or
a string that specifies a registered format as described for option -t.]])

local function main(args)
    local client_methods = {
        get = {fn = client.get, payload = false},
        put = {fn = client.put, payload = true},
        post = {fn = client.post, payload = true},
        delete = {fn = client.delete, payload = true}
    }

    -- --method/-m
    local verb_options = client_methods[string.lower(args.method)]

    local options = {}

    -- --accept/-A
    if args.accept then
        local content_format = CONTENT_FORMAT_LOOKUP[string.lower(args.accept)]
        if content_format then
            table:insert(options, option.new_content_format())
        else
            print("Unknown Accept Content-Format: " .. args.accept)
            os.exit(1)
        end
    end

    -- --type/-t
    if args.type then
        local content_format = CONTENT_FORMAT_LOOKUP[string.lower(args.type)]
        if content_format then
            table:insert(options, option.new_content_format())
        else
            print("Unknown Type Content-Format: " .. args.type)
            os.exit(1)
        end
    end

    -- --file/-f
    local payload = nil
    if args.file then
        local f = io.open(args.file, "rb")
        payload = f:read("*a")
        -- --text/-e
    elseif args.text then
        -- TODO: unescape?
        payload = args.text
    end

    local response, err
    if payload then
        response, err = verb_options.fn(args.url, payload, options)
    else
        response, err = verb_options.fn(args.url, options)
    end

    if not response then
        print("Request failed: " .. err)
        os.exit(1)
    end

    if response.code ~= consts.CODES.RESPONSE.CONTENT then
        print("Received non-CONTENT response: " .. tostring(response.code))
    end

    print(response.payload)
end

local args = parser:parse()
main(args)
