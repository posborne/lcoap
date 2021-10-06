local consts = require 'lcoap.protocol.consts'
local Option = require 'lcoap.protocol.option'

local Message = {}
Message.__index = Message

local function randuint(bytes) return math.random(bytes << 8 + 1) - 1 end

function Message.new(args)
    return setmetatable({
        message_id = assert(args.message_id),
        type = assert(args.type),
        token = args.token,
        code = assert(args.code),
        options = assert(args.options),
        payload = args.payload or ""
    }, Message)
end

Message.__tostring = function(self)
    local buf = string.format("CoAP Message: id=%d, type=%d, code=%d...",
                              self.message_id, self.type, self.code)
    for i, option in ipairs(self.options) do
        buf = buf .. "\n\tOption " .. i .. ": " .. option
    end
    buf = buf .. "\n\tPayload: '" .. self.payload .. "'"
    return buf
end

local function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do table.insert(result, each) end
    return result
end

local function extract_uri_paths(options, path)
    for _, pathseg in ipairs(split(path, "/")) do
        if #pathseg > 0 then
            table.insert(options, Option.new_uri_path(pathseg))
        end
    end
end

function Message.new_get(path, ext)
    ext = ext or {}
    local options = {} or ext.options
    local type = consts.TYPES.CONFIRMABLE
    local message_id = ext.message_id or randuint(2)
    extract_uri_paths(options, path)
    return Message.new({
        type = type,
        message_id = message_id,
        code = consts.CODES.REQUEST.GET,
        options = options
    })
end

function Message.new_put(path, payload, ext)
    ext = ext or {}
    local options = {} or ext.options
    local type = consts.TYPES.CONFIRMABLE
    local message_id = ext.message_id or randuint(2)
    extract_uri_paths(options, path)
    return Message.new({
        type = type,
        message_id = message_id,
        code = consts.CODES.REQUEST.PUT,
        options = options,
        payload = payload,
    })
end

-- 0   1   2   3   4   5   6   7
-- +---------------+---------------+
-- |               |               |
-- |  Option Delta | Option Length |   1 byte
-- |               |               |
-- +---------------+---------------+
-- \                               \
-- /         Option Delta          /   0-2 bytes
-- \          (extended)           \
-- +-------------------------------+
-- \                               \
-- /         Option Length         /   0-2 bytes
-- \          (extended)           \
-- +-------------------------------+
-- \                               \
-- /                               /
-- \                               \
-- /         Option Value          /   0 or more bytes
-- \                               \
-- /                               /
-- \                               \
-- +-------------------------------+
--
--                        Figure 8: Option Format
local function option_ext_encode(value)
    local base_4bit_value
    local ext_value
    if value < 13 then
        -- we can store the delta directly in the 4-bit space
        base_4bit_value = value
        ext_value = ""
    elseif value < 269 then
        -- we can't fit the payload in 4-bits but we can fit it
        -- 8-bits (with 13 bits added inferred range)
        base_4bit_value = 13
        ext_value = string.char(value - 13)
    else
        -- We need 16-bits
        base_4bit_value = 14
        ext_value = string.pack(">H", value - 269)
    end

    return base_4bit_value, ext_value
end

local function pack_option(option, prev_code)
    local delta = option.id - prev_code
    local option_delta, option_delta_ext = option_ext_encode(delta)
    local option_value = option:pack()
    local option_length, option_length_ext = option_ext_encode(#option_value)
    return (string.char(option_delta << 4 | option_length) ..
            option_delta_ext .. option_length_ext .. option_value)
end

local function pack_options(options)
    -- Note that options use a somewhat crazy delta
    -- encoding and we need to pack the options in ascending
    -- order in order for the delta to work properly.
    table.sort(options, function(a, b) return a.id < b.id end)

    local prev_id = 0
    local buf = ""
    for _, option in ipairs(options) do
        local packed_option, err = pack_option(option, prev_id)
        prev_id = option.id
        if not packed_option then return nil, err end
        buf = buf .. packed_option
    end

    return buf
end

-- Lua TLV Message Format
-- ----------------------
--
-- 0                   1                   2                   3
-- 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |Ver| T |  TKL  |      Code     |          Message ID           |
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |   Token (if any, TKL bytes) ...
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |   Options (if any) ...
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
-- |1 1 1 1 1 1 1 1|    Payload (if any) ...
-- +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
function Message:pack()
    -- Header (bytes 1 and 2)
    local ver = 1 -- Implementation MUST set to 0b01
    local type = self.type -- Confirmable, Non-Confirmable, etc.
    local tkl = self.token and #self.token or 0
    local b0 = (ver << 6 | type << 4 | tkl)
    local code = self.code
    local buf = string.pack(">BBH", b0, code, self.message_id)

    -- Token (i.e. requestID)
    if self.token then buf = buf .. self.token end

    -- Options
    buf = buf .. pack_options(self.options)

    if self.payload and #self.payload > 0 then
        -- Marker byte
        buf = buf .. "\xff" .. self.payload
    end

    return buf
end

local function parse_option(data, prev_option_id)
    if #data == 0 then
        -- no more options to parse
        return {}, nil
    end

    local b0 = string.byte(data)
    if b0 == 0xFF then
        -- we found the payload marker
        return {}, data:sub(2)
    end

    local delta_4b = (b0 & 0xF0) >> 4
    local option_length_4b = b0 & 0xF

    local idx = 2

    -- parse extended option delta
    local option_id
    if delta_4b < 13 then
        option_id = prev_option_id + delta_4b
    elseif delta_4b == 13 then
        option_id = prev_option_id + 13 + data:byte(idx)
        idx = idx + 1
    elseif delta_4b == 14 then
        option_id = 269 + string.unpack(">H", data, idx)
        idx = idx + 2
    else -- delta_4b == 15
        return nil, nil, "Reserved delta value 15"
    end

    -- parse extended option length
    local option_length
    if option_length_4b < 13 then
        option_length = option_length_4b
    elseif option_length_4b == 13 then
        option_length = 13 + data:byte(idx)
        idx = idx + 1
    elseif option_length_4b == 14 then
        option_length = 269 + string.unpack(">H", data)
        idx = idx + 2
    else
        return nil, nil, "Reserved option length 15"
    end

    -- parse option value
    local option_value = data:sub(idx, idx + option_length - 1)
    idx = idx + option_length

    local option, err = Option.new_from_parts(option_id, option_value)
    if not option then
        return nil, nil, err
    end

    -- build the full set of options and find payload
    -- through the power of recursion
    local options = {option}
    local tail_options, payload, err = parse_option(data:sub(idx), option_id)
    if not tail_options then
        return nil, nil, err
    end
    for i=1,#tail_options do
        table.insert(options, tail_options[i])
    end

    return options, payload
end

function Message.parse(datagram)
    if #datagram < 4 then
        return nil, "Insufficient Length for Header"
    end
    
    -- parse header
    local b0, code, message_id = string.unpack(">BBH", datagram:sub(1, 4))
    local ver = b0 >> 6 -- bits 6,7
    local type = (b0 >> 4) & 3 -- bits 4,5
    local tkl =  b0 & 0xf -- bits 0-3
    if ver ~= 1 then
        return nil, string.format("Invalid version: %d", ver)
    end
    if tkl > 8 then
        return nil, string.format("TKL values 9-15 are reserved: %d", tkl)
    end

    -- parse token if present
    local token = nil
    if tkl > 0 then
        token = datagram:sub(5, 5 + tkl - 1) 
    end

    local options, payload, err = parse_option(datagram:sub(5 + tkl), 0)
    if not options then
        return nil, err
    end

    return Message.new({
        type = type,
        message_id = message_id,
        code = code,
        token = token,
        options = options,
        payload = payload,
    })
end

return Message
