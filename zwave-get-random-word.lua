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
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())

   local n
   if tvbuf:len() > 0 then
      tree:add(field_n, tvbuf(0, 1))
      n = tvbuf(0, 1):uint()
   else
      n = 2
   end

   pinfo.cols.info:set("Request "..n.." bytes of random data")

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

resp.fields = {
   field_success,
   field_n,
   field_random
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   local success = tvbuf(0, 1)
   tree:add(field_success, success)
   local n = tvbuf(1, 1)
   tree:add(field_n, n)
   local random_data = tvbuf(2)
   tree:add(field_random, random_data)

   if success:uint() == 1 then
      pinfo.cols.info:set("Retrieved "..n:uint().." bytes of random data")
   else
      pinfo.cols.info:set("Failed to obtain random data")
   end

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
