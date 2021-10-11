local socket = require 'socket'
local socketurl = require 'socket.url'
local Message = require 'lcoap.protocol.message'

local client = {}

local function parse_coap_url(url)
    local parsed, err = socketurl.parse(url)
    if not parsed then
        return nil, "invalid url " .. err
    end

    -- TODO: support "coaps" for secure
    if parsed.scheme ~= "coap" then
        return nil, "Unsupport scheme " .. parsed.scheme .. ", expected 'coap'"
    end

    parsed.port = parsed.port or 5683
    return parsed
end

local function make_connected_udp_socket(parsed_url, timeout)
    local udp = socket.udp()
    udp:settimeout(timeout)

    local ok, err = udp:setpeername(parsed_url.host, parsed_url.port)
    if not ok then
        return nil, "Failed to set udp peer name: " .. err
    end

    return udp
end

local function make_connected_socket_from_options(url, options)
    options = options or {}
    local timeout = options.timeout or 5.0

    local parsed_url, purl_err = parse_coap_url(url)
    if not parsed_url then
        return nil, nil, purl_err
    end

    local udp, udperr = make_connected_udp_socket(parsed_url, timeout)
    if not udp then
        return nil, nil, udperr
    end

    return udp, parsed_url
end

-- Perform a CoAP GET request against the provided RFC 2396 URL.
function client.get(url, options)
    local udp, parsed_url, err = make_connected_socket_from_options(url, options)
    if not udp then
        return nil, err
    end

    local tx = Message.new_get(parsed_url.path)
    udp:send(tx:pack())
    local rx_dgram
    rx_dgram, err = udp:receive()
    if not rx_dgram then
        return nil, "No response received: " .. err
    end

    local rx
    rx, err = Message.parse(rx_dgram)
    if not rx then
        return nil, "Failed to parse dgram: " .. err
    end

    return rx
end

-- Perform a CoAP PUT request against the provided RFC 2396 URL.
function client.put(url, payload, options)
    local udp, parsed_url, err = make_connected_socket_from_options(url, options)
    if not udp then
        return nil, err
    end

    local tx = Message.new_put(parsed_url.path, payload)
    udp:send(tx:pack())
    local rx_dgram
    rx_dgram, err = udp:receive()
    if not rx_dgram then
        return nil, "No response received: " .. err
    end

    local rx
    rx, err = Message.parse(rx_dgram)
    if not rx then
        return nil, "Failed to parse dgram: " .. err
    end

    return rx
end

-- Perform a CoAP POST request against the provided RFC 2396 URL.
function client.post(url, payload, options)
    local udp, parsed_url, err = make_connected_socket_from_options(url, options)
    if not udp then
        return nil, err
    end

    local tx = Message.new_post(parsed_url.path, payload)
    udp:send(tx:pack())
    local rx_dgram
    rx_dgram, err = udp:receive()
    if not rx_dgram then
        return nil, "No response received: " .. err
    end

    local rx
    rx, err = Message.parse(rx_dgram)
    if not rx then
        return nil, "Failed to parse dgram: " .. err
    end

    return rx
end

-- Perform a CoAP DELETE request against the provided RFC 2396 URL.
function client.delete(url, options)
    local udp, parsed_url, err = make_connected_socket_from_options(url, options)
    if not udp then
        return nil, err
    end

    local tx = Message.new_delete(parsed_url.path)
    udp:send(tx:pack())
    local rx_dgram
    rx_dgram, err = udp:receive()
    if not rx_dgram then
        return nil, "No response received: " .. err
    end

    local rx
    rx, err = Message.parse(rx_dgram)
    if not rx then
        return nil, "Failed to parse dgram: " .. err
    end

    return rx
end

return client
