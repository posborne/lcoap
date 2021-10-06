local util = {}

function util.lpad(s, width, char)
    char = char or " "
    if #s < width then
        return string.rep(char, width - #s) .. s
    else
        return s
    end
end

function util.hexstr(bstr)
    local hexbytes = {}
    string.gsub(bstr, ".",
                function(c) table.insert(hexbytes, string.byte(c)) end)

    local buf = ""
    for i = 1, #hexbytes do
        if (i - 1) % 4 == 0 then
            buf = buf .. "\n" .. util.lpad(string.format("%d", i - 1), 4) .. " |"
        end
        buf = buf .. string.format(" %02X", hexbytes[i])
    end

    return buf
end

return util
