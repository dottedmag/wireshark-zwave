local cmd_request_table = DissectorTable.new("zwave.command_request", "Z-Wave Application requests", ftypes.UINT8)
local cmd_response_table = DissectorTable.new("zwave.command_response", "Z-Wave Application responses", ftypes.UINT8)

-- ZW_SendData

local command_id = 0x13
local name = "ZW_SendData"

-- Request

local req = Proto("zwave_req_senddata", name.." request")

local field_node_id = ProtoField.uint8("zwave.req_send_data.node_id", "Target node ID", base.DEC)
local field_data_length = ProtoField.uint8("zwave.req_send_data.length", "Data length", base.DEC)

local field_cmd_class = ProtoField.uint8("zwave.req_send_data.cmd_class", "Command Class", base.HEX)

local field_tx_option_ack = ProtoField.bool("zwave.req_send_data.tx_option.ack",
                                            "Request acknowledgement", 8, nil, 0x01)
local field_tx_option_low_power = ProtoField.bool("zwave.req_send_data.tx_option.low_power",
                                                  "Transmit at low power level", 8, nil, 0x02)
local field_tx_option_auto_route = ProtoField.bool("zwave.req_send_data.tx_option.auto_route",
                                                   "Allow routing the frame", 8, nil, 0x04)
local field_tx_option_no_route = ProtoField.bool("zwave.req_send_data.tx_option.no_route",
                                                 "Send the frame directly (do not route)", 8, nil, 0x10)
local field_tx_option_explore = ProtoField.bool("zwave.req_send_data.tx_option.explore",
                                                "Send the frame as explore as a fallback", 8, nil, 0x20)

local field_func_id = ProtoField.uint8("zwave.req_send_data.func_id", "Function ID (Callback ID)", base.HEX)

req.fields = {
   field_node_id,
   field_data_length,
   field_cmd_class,
   field_tx_option_ack,
   field_tx_option_low_power,
   field_tx_option_auto_route,
   field_tx_option_no_route,
   field_tx_option_explore,
   field_func_id,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range(0, 3))
   tree:add(field_node_id, tvbuf:range(0, 1))

   local len = tvbuf:range(1, 1)
   tree:add(field_data_length, len)

   local cmd_class_tree_item = tree:add(field_cmd_class, tvbuf:range(2, 1))

   local tx_options = tvbuf:range(2+len:uint(), 1)
   tree:add(field_tx_option_ack, tx_options)
   tree:add(field_tx_option_low_power, tx_options)
   tree:add(field_tx_option_auto_route, tx_options)
   tree:add(field_tx_option_no_route, tx_options)
   tree:add(field_tx_option_explore, tx_options)

   tree:add(field_func_id, tvbuf:range(3+len:uint(), 1))

   cmd_request_table:try(tvbuf:range(2, 1):uint(), tvbuf:range(3, len:uint()-1):tvb(), pinfo, root)

   if pinfo.private.command_class_id ~= nil then
      cmd_class_tree_item:append_text(" ("..pinfo.private.command_class_id..")")
   end

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end

-- Response

local resp = Proto("zwave_resp_senddata", name.." response")

function resp.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(resp, tvbuf:range())

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end

-- Callback

local callback = Proto("zwave_callback_senddata", name.." callback")

local OK = 0x00
local NO_ACK = 0x01
local FAIL = 0x02

local field_func_id = ProtoField.uint8("zwave.callback_senddata.func_id", "Func ID (callback ID)", base.HEX)
local field_tx_status = ProtoField.uint8(
   "zwave.callback_senddata.tx_status", "Transmit status",
   base.HEX, {[OK] = "OK", [NO_ACK] = "Not acknowledged before timeout", [FAIL] = "Failed (network busy)"})
local field_tx_ticks = ProtoField.uint16(
   "zwave.callback_senddata.tx_ticks", "Transmit time in ticks (10ms)", base.DEC)

callback.fields = {
   field_func_id,
   field_tx_status,
   field_tx_ticks,
}

function callback.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(callback, tvbuf:range())

   local func_id = tvbuf(0, 1)
   tree:add(field_func_id, func_id)
   local tx_status = tvbuf(1, 1)
   tree:add(field_tx_status, tx_status)

   local info
   if tx_status:uint() == OK then
      info = "Sent a frame"
   elseif tx_status:uint() == NO_ACK then
      info = "Sent a frame with no ack before timeout"
   elseif tx_status:uint() == FAIL then
      info = "Failed to send a frame due to busy network"
   else
      info = "???"
   end

   info = info..string.format(", callback ID 0x%x", func_id:uint())

   if tvbuf:len() > 2 then
      local tx_ticks = tvbuf(2, 2)
      tree:add(field_tx_ticks, tx_ticks)

      info = info..string.format(", tx time=%dms", 10*tx_ticks():uint())
   end

   pinfo.cols.info:set(info)

   return tvbuf:len()
end

function callback.init()
   DissectorTable.get("zwave.chip_request"):set(command_id, callback)
end

-- ApplicationCommandHandler

local ach_command_id = 0x04
local ach_name = "Application Command Handler"
local promisc_ach_command_id = 0xd1 -- FIXME: implement

-- Request

local ach_req = Proto("zwave_req_ach", ach_name)

local field_status_busy = ProtoField.bool("zwave.req_ach.status.busy",
                                          "A response route is locked by the application", 8, nil, 0x01)
local field_status_low_power = ProtoField.bool("zwave.req_ach.status.low_power",
                                               "Received at low output power level", 8, nil, 0x02)
local field_status_type = ProtoField.uint8(
   "zwave.req_ach.status.type", "Frame type", base.HEX,
   {[0x00] = "Unicast", [0x01] = "Broadcast", [0x02] = "Multicast"}, 0x0c)

local field_explore = ProtoField.uint8("zwave.req_ach.status.explore", "Explorer frame", base.HEX,
                                       {[0x10] = "Yes", [0x00] = "No"}, 0x30)

local field_foreign = ProtoField.bool("zwave.req_ach.status.foreign", "Foreign frame", 8, nil, 0x40)

local field_foreign_homeid = ProtoField.bool("zwave.req_ach.status.foreign_homeid", "Foreign HomeID", 8, nil, 0x80)

local field_src_node = ProtoField.uint8("zwave.req_ach.src_node", "Source node", base.DEC)

local field_command_length = ProtoField.uint8("zwave.req_ach.command_length", "Command length", base.DEC)

local field_command_class = ProtoField.uint8("zwave.req_ach.command_class", "Command class", base.HEX)

local field_rxssi = ProtoField.uint8("zwave.req_ach.rx_rssi", "Received frame power (dBms)", base.DEC)

local field_security_key = ProtoField.uint8("zwave.req_ach.security_key", "Security key", base.HEX)

ach_req.fields = {
   field_status_busy,
   field_status_low_power,
   field_status_type,
   field_explore,
   field_foreign,
   field_foreign_homeid,
   field_src_node,
   field_command_length,
   field_command_class,
   field_rxssi,
   field_security_key,
}

function ach_req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = ach_name
   pinfo.cols.protocol:set(ach_name)

   local tree = root:add(ach_req, tvbuf:range())
   tree:add(field_status_busy, tvbuf:range(0, 1))
   tree:add(field_status_low_power, tvbuf:range(0, 1))
   tree:add(field_status_type, tvbuf:range(0, 1))
   tree:add(field_explore, tvbuf:range(0, 1))
   tree:add(field_foreign, tvbuf:range(0, 1))
   tree:add(field_foreign_homeid, tvbuf:range(0, 1))
   tree:add(field_src_node, tvbuf:range(1, 1))

   local len = tvbuf:range(2, 1)
   tree:add(field_command_length, len)

   local class = tvbuf:range(3, 1)
   tree:add(field_command_class, class)

   local cmd = tvbuf:range(4, len:uint()-1)

   if tvbuf:len() > 3+len:uint() then
      local rxssi = tvbuf:range(3+len:uint(), 1)
      local tf = tree:add(field_rxssi, rxssi)
      if rxssi:uint() == 125 then
         tf:set("Below sensitivity - no signal detected")
      elseif rxssi:uint() == 127 then
         tf:set("Measurement is not available")
      elseif rxssi:uint() == 126 then
         tf:set("Receiver saturated, power is too high to measure precisely")
      elseif rxssi:uint() >= 11 then
         tf:set("Reserved value")
      end
      tree:add(field_security_key, tvbuf:range(4+len:uint(), 1))
   end

   cmd_response_table:try(class:uint(), cmd:tvb(), pinfo, root)

   if pinfo.private.command_class_id ~= nil then
      cmd_class_tree_item:append_text(" ("..pinfo.private.command_class_id..")")
   end

   return tvbuf:len()
end

function ach_req.init()
   DissectorTable.get("zwave.chip_request"):set(ach_command_id, ach_req)
end
