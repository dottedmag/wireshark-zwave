local command_id = 0x1c
local name = "ZW_GetRandomWord"

-- Request

local req = Proto("zwave_req_getrandomword", name.." request")

local field_n = ProtoField.uint8("zwave.req_getrandomword.n", "Number of random bytes", base.DEC)

req.fields = {
   field_n,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf:range())

   if tvbuf:len() > 0 then
      tree:add(field_n, tvbuf(0, 1))
   end

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_getrandomword", name.." response")

local field_success = ProtoField.bool("zwave.resp_getrandomword.succeeded", "Generation succeeded", base.NONE)
local field_n = ProtoField.uint8("zwave.resp_getrandomword.n", "Number of random bytes", base.DEC)
local field_random = ProtoField.bytes("zwave.resp_getrandomword.data", "Random bytes", base.NONE)

req.fields = {
   field_success,
   field_n,
   field_random
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_success, tvbuf(0, 1))
   tree:add(field_n, tvbuf(1, 1))
   tree:add(field_random, tvbuf(2))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
