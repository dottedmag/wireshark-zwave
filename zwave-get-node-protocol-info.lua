local command_id = 0x41
local name = "ZW_GetNodeProtocolInfo"

-- Request

local req = Proto("zwave_req_zw_getnodeprotocolinfo", name.." request")

local field_node_id = ProtoField.uint8("zwave.req_zw_getnodeprotocolinfo.node_id", "Node ID", base.DEC)

req.fields = {
   field_node_id,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local node_id = tvbuf(0, 1)

   pinfo.cols.info:set("Request for node "..node_id:uint())

   local tree = root:add(req, tvbuf:range())
   tree:add(field_node_id, node_id)

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_zw_getnodeprotocolinfo", name.." response")

local field_listening = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.listening", "Is node listening",
   base.HEX, {[0x00]= "No", [0x01] = "Yes"}, 0x80)

local field_capability_proprietary = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.capability_proprietary", "Protocol-specific (proprietary) info",
   base.HEX, nil, 0x7f)

local field_optional_functionality = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.optional_functionality", "Device supports functionality beyond the mandatory one",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x80)

local field_sensor_1000ms = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.listening_1000ms", "Device is a 1000ms FLiRS node",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x40)

local field_sensor_250ms = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.listening_250ms", "Device is a 250ms FLiRS node",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x20)

local field_security_proprietary = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.security_proprietary", "Protocol-specific (proprietary) info",
   base.HEX, nil, 0x1f)

local field_reserved = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.reserved", "Protocol-specific (proprietary) info", base.HEX)

local field_basic = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.basic_class", "Basic device class", base.HEX)

local field_generic = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.generic_class", "Generic device class", base.HEX)

local field_specific = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.specific_class", "Specific device class", base.HEX)

resp.fields = {
   field_listening,
   field_capability_proprietary,
   field_optional_functionality,
   field_sensor_1000ms,
   field_sensor_250ms,
   field_security_proprietary,
   field_reserved,
   field_basic,
   field_generic,
   field_specific,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_listening, tvbuf(0, 1))
   tree:add(field_capability_proprietary, tvbuf(0, 1))
   tree:add(field_optional_functionality, tvbuf(1, 1))
   tree:add(field_sensor_1000ms, tvbuf(1, 1))
   tree:add(field_sensor_250ms, tvbuf(1, 1))
   tree:add(field_security_proprietary, tvbuf(1, 1))
   tree:add(field_reserved, tvbuf(2, 1))
   tree:add(field_basic, tvbuf(3, 1))
   tree:add(field_generic, tvbuf(4, 1))
   tree:add(field_specific, tvbuf(5, 1))

--   pinfo.cols.info:set(info)

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
