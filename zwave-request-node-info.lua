local command_id = 0x60
local name = "ZW_RequestNodeInfo"

-- Request

local req = Proto("zwave_req_requestnodeinfo", name.." request")

local field_node_id = ProtoField.uint8(
   "zwave.resp_getsucnodeid.node_id", "Requested node ID", base.DEC)

req.fields = {
   field_node_id,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())
   local node_id = tvbuf(0, 1)
   tree:add(field_node_id, node_id)

   pinfo.cols.info:set("Request NIF from node "..node_id:uint())

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_requestnodeinfo", name.." response")

local field_success = ProtoField.bool("zwave.resp_requestnodeinfo.success", base.NONE)

resp.fields = {
   field_success,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   local success = tvbuf(0, 1)
   tree:add(field_success, success)

   if success:uint() == 1 then
      pinfo.cols.info:set("Request queued successfully")
   else
      pinfo.cols.info:set("Request queueing failed")
   end

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
