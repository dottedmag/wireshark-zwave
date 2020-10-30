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

local field_optional_functionality = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.optional_functionality", "Device supports functionality beyond the mandatory one",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x80)

local field_sensor_1000ms = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.listening_1000ms", "Device is a 1000ms FLiRS node",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x40)

local field_sensor_250ms = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.listening_250ms", "Device is a 250ms FLiRS node",
   base.HEX, {[0x00] = "No", [0x01] = "Yes"}, 0x20)

local field_basic = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.basic_class", "Basic device class", base.HEX)

local field_generic = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.generic_class", "Generic device class", base.HEX)

local field_specific = ProtoField.uint8(
   "zwave.resp_zw_getnodeprotocolinfo.specific_class", "Specific device class", base.HEX)

resp.fields = {
   field_listening,
   field_optional_functionality,
   field_sensor_1000ms,
   field_sensor_250ms,
   field_basic,
   field_generic,
   field_specific,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   local listening = tvbuf(0, 1)
   tree:add(field_listening, listening)
   local caps = tvbuf(1, 1)
   tree:add(field_optional_functionality, caps)
   tree:add(field_sensor_1000ms, caps)
   tree:add(field_sensor_250ms, caps)
   local basic = tvbuf(3, 1)
   tree:add(field_basic, basic)
   local generic = tvbuf(4, 1)
   tree:add(field_generic, generic)
   local specific = tvbuf(5, 1)
   tree:add(field_specific, specific)

   local info = {}
   if bit.band(listening:uint(), 0x80) == 0x80 then
      table.insert(info, "Listening")
   end
   if bit.band(caps:uint(), 0x80) == 0x80 then
      table.insert(info, "Func+")
   end
   if bit.band(caps:uint(), 0x40) == 0x40 then
      table.insert(info, "FLiRS 1000ms")
   end
   if bit.band(caps:uint(), 0x20) == 0x20 then
      table.insert(info, "FLiRS 250ms")
   end

   pinfo.cols.info:set(string.format(
                          "Node options: [%s], basic: 0x%x, generic: 0x%x, specific: 0x%x",
                          table.concat(info, ", "), basic:uint(), generic:uint(), specific:uint()))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
