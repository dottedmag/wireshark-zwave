local class_id = 0x26
local name = "Multilevel Switch"

local handler = Proto("zwave_req_app_switch_multilevel", name)

local SET = 0x01
local GET = 0x02
local REPORT = 0x03
local START_LEVEL_CHANGE = 0x04
local STOP_LEVEL_CHANGE = 0x05
local SUPPORTED_GET = 0x06
local SUPPORTED_REPORT = 0x07

local START_LEVEL_INCREASE = 0
local START_LEVEL_IGNORE_LEVEL = 0x20
local START_LEVEL_DECREASE = 0x40

function handler.dissector(tvbuf, proto, root)
   local cmd = tvbuf(0, 1):uint()

   if cmd == SET then
      -- check length: 2 bytes for ver 1, 3 bytes for ver 2+
   elseif cmd == GET then
      -- no args
   elseif cmd == REPORT then
      -- check length: 2 bytes for ver 1, 4 bytes for ver 4+
   elseif cmd == START_LEVEL_CHANGE then
      -- check length: 3 bytes for ver 1, 4 bytes for ver 2, 5 bytes for ver 3+
   elseif cmd == STOP_LEVEL_CHANGE then
      -- check length: 1 byte for ver 1+
   elseif cmd == SUPPORTED_GET then
      -- always 1 byte
   elseif cmd == SUPPORTED_REPORT then
      -- always 3 bytes
   end
end
