local app_request_table = DissectorTable.new("zwave.app_request", "Z-Wave Application requests", ftypes.UINT8)
local app_response_table = DissectorTable.new("zwave.app_response", "Z-Wave Application responses", ftypes.UINT8)

-- ZW_SendData

local command_id = 0x13
local name = "ZW_SendData"

-- Request

local req = Proto("zwave_req_senddata", name.." request")

local field_node_id = ProtoField.uint8("zwave.req_send_data.node_id", "Target node ID", base.DEC)
local field_data_length = ProtoField.uint8("zwave.req_send_data.length", "Data length", base.DEC)

local field_app_cmd = ProtoField.uint8("zwave.req_send_data.app_cmd", "Application Command", base.HEX)

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
   field_app_cmd,
   field_tx_option_ack,
   field_tx_option_low_power,
   field_tx_option_auto_route,
   field_tx_option_no_route,
   field_tx_option_explore,
   field_func_id,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(req, tvbuf:range(0, 3))
   tree:add(field_node_id, tvbuf:range(0, 1))

   local len = tvbuf:range(1, 1)
   tree:add(field_data_length, len)

   local app_cmd_tree_item = tree:add(field_app_cmd, tvbuf:range(2, 1))

   local tx_options = tvbuf:range(2+len:uint(), 1)
   tree:add(field_tx_option_ack, tx_options)
   tree:add(field_tx_option_low_power, tx_options)
   tree:add(field_tx_option_auto_route, tx_options)
   tree:add(field_tx_option_no_route, tx_options)
   tree:add(field_tx_option_explore, tx_options)

   tree:add(field_func_id, tvbuf:range(3+len:uint(), 1))

   app_request_table:try(tvbuf:range(2, 1):uint(), tvbuf:range(3, len:uint()-1):tvb(), pinfo, root)

   if pinfo.private.app_command_id ~= nil then
      app_cmd_tree_item:append_text(" ("..pinfo.private.app_command_id..")")
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

   local tree = root:add(resp, tvbuf:range())

   return tvbuf:len()
end

function resp.init()
   DissectorTable.get("zwave.chip_response"):set(command_id, resp)
end

-- Callback

local callback = Proto("zwave_callback_senddata", name.." callback")

function callback.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name

   local tree = root:add(callback, tvbuf:range())

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

function ach_req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = ach_name

   local tree = root:add(ach_req, tvbuf:range())

   return tvbuf:len()
end

function ach_req.init()
   DissectorTable.get("zwave.chip_request"):set(ach_command_id, ach_req)
end
