local consts = {}

-- Header "code" field c.dd calculator
local function code(c, d) return c << 5 | d end

consts.TYPES = {
    ["CONFIRMABLE"] = 0,
    ["NON_CONFIRMABLE"] = 1,
    ["ACKNOWLEDGEMENT"] = 2,
    ["RESET"] = 3
}

consts.CODES = {
    -- 0.0
    ["EMPTY"] = code(0, 0),
    -- 0.01-0.31 (Section 12.1.1)
    ["REQUEST"] = {
        ["GET"] = code(0, 01),
        ["POST"] = code(0, 02),
        ["PUT"] = code(0, 03),
        ["DELETE"] = code(0, 04)
    },
    -- 2.00-5.31 (Section 12.1.2)
    ["RESPONSE"] = {
        ["CREATED"] = code(2, 01),
        ["DELETED"] = code(2, 02),
        ["VALID"] = code(2, 03),
        ["CHANGED"] = code(2, 04),
        ["CONTENT"] = code(2, 05),
        ["BAD_REQUEST"] = code(4, 00),
        ["UNAUTHORIZED"] = code(4, 01),
        ["BAD_OPTION"] = code(4, 02),
        ["FORBIDDEN"] = code(4, 03),
        ["NOT_FOUND"] = code(4, 04),
        ["METHOD_NOT_ALLOWED"] = code(4, 05),
        ["NOT_ACCEPTABLE"] = code(4, 06),
        ["PRECONDITION_FAILED"] = code(4, 12),
        ["REQUEST_ENTITY_TOO_LARGE"] = code(4, 13),
        ["UNSUPPORTED_CONTENT_TYPE"] = code(4, 15),
        ["INTERNAL_SERVER_ERROR"] = code(5, 00),
        ["NOT_IMPLEMENTED"] = code(5, 01),
        ["BAD_GATEWAY"] = code(5, 02),
        ["SERVICE_UNAVAILABLE"] = code(5, 03),
        ["GATEWAY_TIMEOUT"] = code(5, 04),
        ["PROXYING_NOT_SUPPORTED"] = code(5, 05)
    }
}

consts.CONTENT_FORMATS = {
    ["TEXT"] = 0, -- text/plain;
    ["LINK_FORMAT"] = 40, -- application/link-format
    ["XML"] = 41, -- application/xml
    ["OCTET_STREAM"] = 42, -- application/octet-stream
    ["EXI"] = 47, -- application/exi
    ["JSON"] = 50 -- application/json
}

return consts
