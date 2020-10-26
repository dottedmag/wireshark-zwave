local command_id = 0x07
local name = "SerialGetCapabilities"

-- Request

local req = Proto("zwave_req_serialgetcapabilities", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf:range())

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_serialgetcapabilities", name.." response")

local field_version = ProtoField.uint8("zwave.resp_serialgetcapabilities.version", "Serial API Version", base.DEC)
local field_revision = ProtoField.uint8("zwave.resp_serialgetcapabilities.revision", "Serial API Revision", base.DEC)

local field_manufacturer_id = ProtoField.uint16("zwave.resp_serialgetcapabilities.manufacturer_id",
                                                "Manufacturer ID", base.HEX)

local field_manufacturer_product_type = ProtoField.uint16("zwave.resp_serialgetcapabilities.manufacturer_product_type",
                                                          "Manufacturer product type", base.HEX)

local field_manufacturer_product_id = ProtoField.uint16("zwave.resp_serialgetcapabilities.manufacturer_product_id",
                                                        "Manufacturer product ID", base.HEX)

local field_supported_functions_bitmask = ProtoField.none("zwave.resp_serialgetcapabilities.supported_functions_bitmask",
                                                          "Bitmask of supported Serial API functions")

resp.fields = {
   field_version,
   field_revision,
   field_manufacturer_id,
   field_manufacturer_product_type,
   field_manufacturer_product_id,
   field_supported_functions_bitmask,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_version, tvbuf:range(0, 1))
   tree:add(field_revision, tvbuf:range(1, 1))
   tree:add(field_manufacturer_id, tvbuf:range(2, 2))
   tree:add(field_manufacturer_product_type, tvbuf:range(4, 2))
   tree:add(field_manufacturer_product_id, tvbuf:range(6, 2))
   tree:add(field_supported_functions_bitmask, tvbuf:range(8, 32))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
