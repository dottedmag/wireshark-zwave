local command_id = 0x15
local name = "ZW_GetVersion"

-- Request

local req = Proto("zwave_req_zw_version", name.." request")

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf)

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_zw_version", name.." response")

local field_resp_text = ProtoField.string("zwave.resp_zw_version.text", "Version Text", base.ASCII)

local library_types = {
   [0x01] = "Static controller",
   [0x02] = "Portable controller",
   [0x03] = "Enhanced slave",
   [0x04] = "Slave",
   [0x05] = "Installer",
   [0x06] = "Routing slave",
   [0x07] = "Bridge controller",
}
local field_resp_library_type = ProtoField.uint8(
   "zwave.resp_zw_version.library_type", "Library Type", base.HEX, library_types)

resp.fields = {
   field_resp_text,
   field_resp_library_type,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(resp, tvbuf:range())

   tree:add(field_resp_text, tvbuf(0, 12))
   tree:add(field_resp_library_type, tvbuf(12, 1))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
