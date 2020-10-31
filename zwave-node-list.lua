local command_id = 0x02
local name = "NodeList"

-- Request

local req = Proto("zwave_req_nodelist", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())

   pinfo.cols.info:set("Request node list")

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_nodelist", name.." response")

local field_ver = ProtoField.uint8("zwave.resp_nodelist.version", "Serial API version", base.DEC)

local field_capabilities_controller = ProtoField.bool(
   "zwave.resp_nodelist.capabilities_controller", "Is this a slave API",
   8, nil, 0x01)

local field_capabilities_timer = ProtoField.bool(
   "zwave.resp_nodelist.capabilities_timer", "Are timer functions supported",
   8, nil, 0x02)

local field_capabilities_primary = ProtoField.bool(
   "zwave.resp_nodelist.capabilities_primary", "Is this a secondary controller",
   8, nil, 0x04)

local field_capabilities_sis = ProtoField.bool(
   "zwave.resp_nodelist.capabilities_sis", "Is this a SIS controller",
   8, nil, 0x08)

local field_nodes_bitmask_len = ProtoField.uint8(
   "zwave.resp_nodelist.nodes_bitmask_len", "Length of nodes bitmask (in bytes)", base.DEC)

local field_nodes = ProtoField.none("zwave.resp_nodelist.nodes", "Present nodes")

local field_chip_type_ver = ProtoField.uint16(
   "zwave.resp_nodelist.chip_type", "Chip type", base.HEX, {
      [0x0102] = "ZW0102",
      [0x0201] = "ZW0201",
      [0x0301] = "ZW0301",
      [0x0401] = "ZW0401/ZM4102/SD3402",
      [0x0500] = "ZW050x",
})

resp.fields = {
   field_ver,
   field_capabilities_controller,
   field_capabilities_timer,
   field_capabilities_primary,
   field_capabilities_sis,
   field_nodes_bitmask_len,
   field_nodes,
   field_chip_type_ver,
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

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_ver, tvbuf:range(0, 1))
   tree:add(field_capabilities_controller, tvbuf:range(1, 1))
   tree:add(field_capabilities_timer, tvbuf:range(1, 1))
   tree:add(field_capabilities_primary, tvbuf:range(1, 1))
   tree:add(field_capabilities_sis, tvbuf:range(1, 1))

   local len = tvbuf:range(2, 1)
   tree:add(field_nodes_bitmask_len, len)

   local nodes = tvbuf:range(3, len:uint())
   local tn = tree:add(field_nodes, nodes)
   local node_list = "["..table.concat(nodes_bitmask(nodes:bytes()), " ").."]"
   tn:append_text(": "..node_list)

   tree:add(field_chip_type_ver, tvbuf:range(3+len:uint(), 2))

   -- FIXME expose more info
   pinfo.cols.info:set("Node list "..node_list)

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
