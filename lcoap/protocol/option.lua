local Option = {}
Option.__index = function(table, key)
    return table.prototype[key] or Option[key]
end

local StringTransformer = {}
StringTransformer.__index = StringTransformer
function StringTransformer.pack(value) return value end
function StringTransformer.parse(data) return data end
local OpaqueTransformer = StringTransformer

local UIntTransformer = {}
UIntTransformer.__index = UIntTransformer
function UIntTransformer.pack(value)
    -- big endian pack using just enough bytes
    local test = value
    local bytes_required = 0
    while test > 0 do
        test = test >> 8
        bytes_required = bytes_required + 1
    end
    return string.pack(">L", value):sub(-bytes_required)
end
function UIntTransformer.parse(data)
    -- big endian parse of as many bytes as we have
    local val = 0
    for i = 1, #data do val = string.byte(data, -i) << (8 * (i - 1)) end
    return val
end

local EmptyTransformer = {}
EmptyTransformer.__index = EmptyTransformer
function EmptyTransformer.pack(value) return "" end
function EmptyTransformer.parse(value) return "" end

local KNOWN_OPTIONS = {
    ["IF_MATCH"] = {
        id = 1,
        name = "If-Match",
        repeatable = true,
        transformer = StringTransformer
    },
    ["URI_HOST"] = {
        id = 3,
        name = "Uri-Host",
        repeatable = false,
        transformer = StringTransformer
    },
    ["ETAG"] = {
        id = 4,
        name = "ETag",
        repeatable = true,
        transformer = OpaqueTransformer
    },
    ["IF_NONE_MATCH"] = {
        id = 5,
        name = "If-None-Match",
        repeatable = false,
        transformer = EmptyTransformer
    },
    ["URI_PORT"] = {
        id = 7,
        name = "Uri-Port",
        repeatable = false,
        transformer = UIntTransformer
    },
    ["LOCATION_PATH"] = {
        id = 8,
        name = "Location-Path",
        repeatable = true,
        transformer = StringTransformer
    },
    ["URI_PATH"] = {
        id = 11,
        name = "Uri-Path",
        repeatable = true,
        transformer = StringTransformer
    },
    ["CONTENT_FORMAT"] = {
        id = 12,
        name = "Content-Format",
        repeatable = false,
        transformer = UIntTransformer
    },
    ["MAX_AGE"] = {
        id = 14,
        name = "Max-Age",
        repeatable = false,
        transformer = UIntTransformer
    },
    ["URI_QUERY"] = {
        id = 15,
        name = "Uri-Query",
        repeatable = true,
        transformer = StringTransformer
    },
    ["ACCEPT"] = {
        id = 17,
        name = "Accept",
        repeatable = true,
        transformer = UIntTransformer
    },
    ["LOCATION_QUERY"] = {
        id = 20,
        name = "Location-Query",
        repeatable = true,
        transformer = StringTransformer
    },
    ["PROXY_URI"] = {
        id = 35,
        name = "Proxy-Uri",
        repeatable = false,
        transformer = StringTransformer
    },
    ["PROXY_SCHEME"] = {
        id = 39,
        name = "Proxy-Scheme",
        repeatable = false,
        transformer = StringTransformer
    },
    ["SIZE1"] = {
        id = 60,
        name = "Size1",
        repeatable = false,
        transformer = UIntTransformer
    }
}

function Option.new(prototype, value)
    local self = {}
    self.prototype = prototype
    setmetatable(self, Option)

    self.value = value
    assert(self.value)
    assert(self.transformer)
    return self
end

function Option.new_from_parts(option_id, packed_value)
    for _k, candidate in pairs(KNOWN_OPTIONS) do
        if candidate.id == option_id then
            local value = candidate.transformer.parse(packed_value)
            return Option.new(candidate, value)
        end
    end
    return nil, string.format("Option %d not known", option_id)
end

function Option.new_uri_host(host)
    return Option.new(KNOWN_OPTIONS.URI_HOST, host)
end

function Option.new_uri_port(port)
    return Option.new(KNOWN_OPTIONS.URI_PORT, port)
end

function Option.new_uri_path(pathsegment)
    return Option.new(KNOWN_OPTIONS.URI_PATH, pathsegment)
end

function Option.new_uri_query(key, value)
    return Option.new(KNOWN_OPTIONS.URI_QUERY, string.format("%s=%s", key, value))
end

function Option.new_content_format(value)
    return Option.new(KNOWN_OPTIONS.CONTENT_FORMAT, value)
end

function Option.new_accept(value) return Option.new(KNOWN_OPTIONS.ACCEPT, value) end

function Option.new_max_age(max_age_seconds)
    return Option.new(KNOWN_OPTIONS.MAX_AGE, max_age_seconds)
end

function Option.new_proxy_uri(proxy_uri)
    return Option.new(KNOWN_OPTIONS.PROXY_URI, proxy_uri)
end

function Option.new_proxy_scheme(proxy_scheme)
    return Option.new(KNOWN_OPTIONS.PROXY_SCHEME, proxy_scheme)
end

function Option.new_etag(etag) return Option.new(KNOWN_OPTIONS.ETAG, etag) end

function Option.new_location_path(location_path)
    return Option.new(KNOWN_OPTIONS.LOCATION_PATH, location_path)
end

function Option.new_location_query(location_query)
    return Option.new(KNOWN_OPTIONS.LOCATION_QUERY, location_query)
end

function Option.new_if_match(if_match)
    return Option.new(KNOWN_OPTIONS.IF_MATCH, if_match)
end

function Option.new_if_none_match()
    return Option.new(KNOWN_OPTIONS.IF_NONE_MATCH, "")
end

function Option.new_option_size1(os1) return
    Option.new(KNOWN_OPTIONS.SIZE1, os1) end

function Option:pack() return self.transformer.pack(self.value) end

return Option
