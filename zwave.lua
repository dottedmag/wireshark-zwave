-- Serial Z-Wave protocol
--
-- This protocol is used to communicate between Z-Wave chip and user programs,
-- either running in Z-Wave device, or on a host Z-Wave controller is plugged
-- into.
--
-- Serial Z-Wave protocol consists of data frame SOF (Start of Frame) and
-- auxiliary frames:
-- ACK (Acknowledged)
-- NAK (Not acknowledged, malformed frame)
-- CAN (Can resend, well-formed frame arrived at unfortunate time)
--
-- These frames are sent in both directions between the host and Z-Wave chip.
--
-- Data frames carry a request/response flag and a "Command ID" for further
-- dispatch.
--
-- Each Command ID might have 4 meanings, based on whether it is a request or a
-- response, and whether it is coming from a Z-Wave chip or from a host.
--
-- Every data frame also contains a checksum.
--

local host_req_table = DissectorTable.new("zwave.host_request", "Z-Wave Serial API host->chip requests", ftypes.UINT8)
local host_resp_table = DissectorTable.new("zwave.host_response", "Z-Wave Serial API host->chip responses", ftypes.UINT8)
local chip_req_table = DissectorTable.new("zwave.chip_request", "Z-Wave Serial API chip->host requests", ftypes.UINT8)
local chip_resp_table = DissectorTable.new("zwave.chip_response", "Z-Wave Serial API chip->host responses", ftypes.UINT8)

local serial = Proto("zwave_serial", "Z-Wave serial protocol")

-- Frame types

local SOF = 0x01
local ACK = 0x06
local NAK = 0x15
local CAN = 0x18

local frame_type_values = {
   [SOF] = "Start of frame",
   [ACK] = "ACK",
   [NAK] = "NAK",
   [CAN] = "Can resend",
}

local field_frame_type = ProtoField.uint8("zwave_serial.frame_type", "Frame type", base.HEX, frame_type_values)

-- Frame length

local field_frame_length = ProtoField.uint8("zwave_serial.frame_length", "Frame length", base.DEC)

-- Data frame types

local REQ = 0x00
local RESP = 0x01

local data_frame_type_values = {
   [REQ] = "Request",
   [RESP] = "Response",
}

local field_data_frame_type = ProtoField.uint8("zwave_serial.data_frame_type", "Data frame type", base.DEC,
                                               data_frame_type_values)

-- Command IDs

local field_command_id = ProtoField.uint8("zwave_serial.command_id", "Command ID", base.HEX)

-- Checksum

local field_checksum = ProtoField.uint8("zwave_serial.checksum", "Frame checksum", base.HEX)

serial.fields = {
   field_frame_type,
   field_frame_length,
   field_data_frame_type,
   field_command_id,
   field_checksum,
}

function serial.dissector(tvbuf, pinfo, root)
   -- FIXME: check tvbuf length
   local type = tvbuf(0, 1)

   local tree
   if type:uint() == SOF then
      -- FIXME check tvbuf length
      tree = root:add(serial, tvbuf:range(0, 4))
   else
      tree = root:add(serial, tvbuf:range(0, 1))
   end

   tree:add(field_frame_type, type)

   if type:uint() ~= SOF then
      return
   end

   local length = tvbuf(1, 1)
   -- FIXME: check length / frame length
   tree:add(field_frame_length, length)

   -- FIXME check tvbuf length
   local data_frame_type = tvbuf(2, 1)
   tree:add(field_data_frame_type, data_frame_type)

   -- FIXME check tvbuf length
   local command_id = tvbuf(3, 1)
   local command_id_tree_item = tree:add(field_command_id, command_id)

   local host_to_chip = pinfo.p2p_dir == 0

   local proto_table
   if host_to_chip and data_frame_type:uint() == REQ then
      proto_table = host_req_table
   elseif host_to_chip and data_frame_type:uint() == RESP then
      proto_table = host_resp_table
   elseif not host_to_chip and data_frame_type:uint() == REQ then
      proto_table = chip_req_table
   elseif not host_to_chip and data_frame_type:uint() == RESP then
      proto_table = chip_resp_table
   end

   -- FIXME check wrong data_frame_type
   if proto_table ~= nil then
      local cmd = tvbuf:range(4, tvbuf:len()-5)
      proto_table:try(command_id:uint(), cmd:tvb(), pinfo, root)

      if pinfo.private.command_id ~= nil then
         command_id_tree_item:append_text(" ("..pinfo.private.command_id..")")
      end
   end

   -- FIXME: check tvbuf length
   local checksum = tvbuf(tvbuf:len()-1)
   tree:add(field_checksum, checksum)
   -- FIXME: check checksum
end

DissectorTable.get("wtap_encap"):add(211, serial)
