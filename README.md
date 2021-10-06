# `lcoap` Pure Lua CoAP Library

[![Actions Status](https://github.com/posborne/lcoap/workflows/lua%20unit%20tests/badge.svg)](https://github.com/posborne/lcoap/actions)

## About The Project

`lcoap` is a pure Lua (no direct C dependnecies) implementation of
the CoAP protocol as described in [RFC7252](https://datatracker.ietf.org/doc/html/rfc7252).

Currently it provides:
* Implementation of core protocol message packing/parsing along with
  required constants suitable for building a CoAP client or server.
* A basic client implementation built on luasocket.

### Example

The following is a basic example showing usage of the client APIs
to perform a basic GET request and print the payload 10 times:

```lua
local coap_client = require('lcoap.client')

for _=1,10 do
    local rx, err = coap_client.get("coap://192.168.1.175/pot")
    if not rx then
        print("CoAP Get Failed: " .. err)
    else
        print("Potentiometer Value: " .. rx.payload)
    end
    os.execute("sleep 2")
end
```

### Installation

Once release, the library will be available via luarocks.

## Contributing

Contributions to the project and bug reports are very welcome.
Bug reports may be filed by creating an issue on Github and PRs
are welcome as well!

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for
more information.
