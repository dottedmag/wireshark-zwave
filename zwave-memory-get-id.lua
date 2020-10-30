local command_id = 0x20
local name = "MemoryGetID"

-- Request

local req = Proto("zwave_req_memorygetid", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())

   pinfo.cols.info:set("Request Home ID, Node ID from the chip")

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_memorygetid", name.." response")

local field_home_id = ProtoField.uint32("zwave.resp_memorygetid.home_id", "Home ID (network ID)", base.HEX)
local field_node_id = ProtoField.uint32("zwave.resp_memorygetid.node_id", "Node ID", base.DEC)

resp.fields = {
   field_home_id,
   field_node_id,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   local home_id = tvbuf(0, 4)
   tree:add(field_home_id, home_id)
   local node_id = tvbuf(4, 1)
   tree:add(field_node_id, node_id)

   pinfo.cols.info:set(string.format("Home ID=0x%x, Node ID=%d", home_id:uint(), node_id:uint()))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
