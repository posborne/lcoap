local coap_client = require 'lcoap.client'

for _=1,10 do
    local rx, err = coap_client.get("coap://192.168.1.175/pot")
    if not rx then
        print("CoAP Get Failed: " .. err)
    else
        print("Potentiometer Value: " .. rx.payload)
    end
    os.execute("sleep 2")
end
