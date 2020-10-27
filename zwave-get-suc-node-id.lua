local command_id = 0x56
local name = "ZW_GetSUCNodeID"

-- Request

local req = Proto("zwave_req_getsucnodeid", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf:range())

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_getsucnodeid", name.." response")

local field_node_id = ProtoField.uint8(
   "zwave.resp_getsucnodeid.node_id", "SUC node ID", base.DEC)

resp.fields = {
   field_node_id
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_node_id, tvbuf(0, 1))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
