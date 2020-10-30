local command_id = 0x06
local name = "SetTimeouts"

-- Request

local req = Proto("zwave_req_settimeouts", name.." request")

local field_rx_ack_timeout = ProtoField.uint8(
   "zwave.req_settimeouts.rx_ack", "Receive ACK timeout (in 10th milliseconds)", base.DEC)
local field_rx_byte_timeout = ProtoField.uint8(
   "zwave.req_settimeouts.rx_bytes", "Receive data timeout (in 10th milliseconds)", base.DEC)

req.fields = {
   field_rx_ack_timeout,
   field_rx_byte_timeout,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())
   tree:add(field_rx_ack_timeout, tvbuf(0, 1))
   tree:add(field_rx_byte_timeout, tvbuf(1, 1))

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_settimeouts", name.." response")

local field_old_rx_ack_timeout = ProtoField.uint8(
   "zwave.resp_settimeouts.old_rx_ack", "Previous receive ACK timeout (in 10th milliseconds)", base.DEC)
local field_old_rx_byte_timeout = ProtoField.uint8(
   "zwave.req_settimeouts.old_rx_bytes", "Previous receive data timeout (in 10th milliseconds)", base.DEC)

req.fields = {
   field_old_rx_ack_timeout,
   field_old_rx_byte_timeout,
}

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())
   tree:add(field_old_rx_ack_timeout, tvbuf(0, 1))
   tree:add(field_old_rx_byte_timeout, tvbuf(1, 1))

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end
