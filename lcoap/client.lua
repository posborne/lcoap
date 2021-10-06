local socket = require 'socket'
local socketurl = require 'socket.url'
local Message = require 'lcoap.protocol.message'

local client = {}

-- Perform a CoAP GET request against the provided RFC 2396 URL.
function client.get(url, options)
    options = options or {}
    local timeout = options.timeout or 5.0

    local parsed, err = socketurl.parse(url)
    if not parsed then
        return nil, "invalid url " .. err
    end

    -- TODO: support "coaps" for secure
    if parsed.scheme ~= "coap" then
        return nil, "Unsupport scheme " .. parsed.scheme .. ", expected 'coap'"
    end

    local port = parsed.port or 5683
    local udp = socket.udp()
    udp:settimeout(timeout)
    local ok, err = udp:setpeername(parsed.host, port)
    if not ok then
        return nil, "Failed to set udp peer name: " .. err
    end

    local tx = Message.new_get(parsed.path)
    udp:send(tx:pack())
    local rx_dgram, err = udp:receive()
    if not rx_dgram then
        return nil, "No response received: " .. timeout
    end

    local rx, err = Message.parse(rx_dgram)
    if not rx then
        return nil, "Failed to parse dgram: " .. err
    end

    return rx
end

return client
