local command_id = 0x80
local name = "ZW_GetRoutingInfo"

-- Request

local req = Proto("zwave_req_getroutinginfo", name.." request")

local field_node_id = ProtoField.uint8(
   "zwave.req_getroutinginfo.node_id", "Node ID", base.DEC)

local field_remove_bad = ProtoField.uint8(
   "zwave.req_getroutinginfo.remove_bad", "Remove bad (currently unavailable) nodes", base.DEC, {[0] = "No", [1] = "Yes"})

local field_remove_non_reps = ProtoField.uint8(
   "zwave.req_getroutinginfo.remove_non_repeaters", "Remove non-repeaters", base.DEC, {[0] = "No", [1] = "Yes"})

-- FIXME: check that it is set to 0
local field_func_id = ProtoField.uint8(
   "zwave.req_getroutinginfo.func_id", "Function (callback) ID", base.HEX)

req.fields = {
   field_node_id,
   field_remove_bad,
   field_remove_non_reps,
   field_func_id,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())
   local node_id = tvbuf:range(0, 1)
   tree:add(field_node_id, node_id)
   local remove_bad = tvbuf:range(1, 1)
   tree:add(field_remove_bad, remove_bad)
   local remove_non_reps = tvbuf:range(2, 1)
   tree:add(field_remove_non_reps, remove_non_reps)
   tree:add(field_func_id, tvbuf:range(3, 1))

   local info = "Get routing info for node "..node_id:uint()
   if remove_bad:uint() ~= 0 then
      info = info..", without bad nodes"
   end
   if remove_non_reps:uint() ~= 0 then
      info = info..", only repeaters"
   end

   pinfo.cols.info:set(info)
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_getroutinginfo", name.." response")

local field_nodes = ProtoField.bytes(
   "zwave.resp_getroutinginfo.nodes", "Neighbour nodes")

resp.fields = {
   field_nodes,
}

function nodes_bitmask(nodes)
   out = {}
   for i = 0, nodes:len()-1 do
      local byte = nodes:get_index(i)
      for j = 0, 8 do
         local b = bit.band(bit.rshift(byte, j), 0x1)
         if b ~= 0 then
            table.insert(out, i*8+j+1)
         end
      end
   end
   return out
end

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())
   tree:add(field_nodes, tvbuf:range())

   pinfo.cols.info:set("Neighbour nodes: ["..table.concat(nodes_bitmask(tvbuf:bytes()), ", ").."]")

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
