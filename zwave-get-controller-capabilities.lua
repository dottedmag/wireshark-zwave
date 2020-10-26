local command_id = 0x05
local name = "ZW_GetControllerCapabilities"

-- Request

local req = Proto("zwave_req_zw_getcontrollercapabilities", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf:range())

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_zw_getcontrollercapabilities", name.." response")

local field_capabilities_secondary = ProtoField.bool(
   "zwave.resp_zw_getcontrollercapabilities.secondary", "Secondary controller", 8, nil, 0x01)

local field_capabilities_on_other_network = ProtoField.bool(
   "zwave.resp_zw_getcontrollercapabilities.on_other_network", "Controller is on other network", 8, nil, 0x02)

local field_capabilities_sis_present = ProtoField.bool(
   "zwave.resp_zw_getcontrollercapabilities.sis_present", "SIS is present in the network", 8, nil, 0x04)

local field_capabilities_real_primary = ProtoField.bool(
   "zwave.resp_zw_getcontrollercapabilities.real_primary", "Real primary controller", 8, nil, 0x08)

local field_capabilities_suc = ProtoField.bool(
   "zwave.resp_zw_getcontrollercapabilities.suc", "SUC (static update controller)", 8, nil, 0x10)

local field_unused = ProtoField.uint8(
   "zwave.resp_zw_getcontrollercapabilities.unused", "Unused", base.HEX, nil, 0xe0)

resp.fields = {
   field_capabilities_secondary,
   field_capabilities_on_other_network,
   field_capabilities_sis_present,
   field_capabilities_real_primary,
   field_capabilities_suc,
   field_unused,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_capabilities_secondary, tvbuf(0, 1))
   tree:add(field_capabilities_on_other_network, tvbuf(0, 1))
   tree:add(field_capabilities_sis_present, tvbuf(0, 1))
   tree:add(field_capabilities_real_primary, tvbuf(0, 1))
   tree:add(field_capabilities_suc, tvbuf(0, 1))
   tree:add(field_unused, tvbuf(0, 1))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
