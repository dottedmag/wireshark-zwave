local command_id = 0x03
local name = "ApplicationNodeInformation"

-- Request

local req = Proto("zwave_req_applicationnodeinformation", name.." request")

local field_options_listening = ProtoField.bool("zwave.req_applicationnodeinformation.listening",
                                                "Node is always listening and stationary", 8, nil, 0x01)
local field_options_optional = ProtoField.bool("zwave.req_applicationnodeinformation.optional",
                                               "Node supports optional functionality", 8, nil, 0x02)
local field_type_generic = ProtoField.uint8("zwave.req_applicationnodeinformation.type_generic",
                                            "Generic device class", base.HEX)
local field_type_specific = ProtoField.uint8("zwave.req_applicationnodeinformation.type_specific",
                                             "Specific device class", base.HEX)
local field_type_classes_length = ProtoField.uint8("zwave.req_applicationnodeinformation.classes_length",
                                                   "Length of list of classes in bytes")
local field_type_classes = ProtoField.bytes("zwave.req_applicationnodeinformation.classes",
                                            "List of supported command classes", base.NONE)

req.fields = {
   field_options_listening,
   field_options_optional,
   field_type_generic,
   field_type_specific,
   field_type_classes_length,
   field_type_classes,
}

function req.dissector(tvbuf, pinfo, root)
   pinfo.private.command_id = name
   pinfo.cols.protocol:set(name)

   local tree = root:add(req, tvbuf:range())
   tree:add(field_options_listening, tvbuf:range(0, 1))
   tree:add(field_options_optional, tvbuf:range(0, 1))
   tree:add(field_type_generic, tvbuf:range(1, 1))
   tree:add(field_type_specific, tvbuf:range(2, 1))
   local len = tvbuf:range(3, 1)
   tree:add(field_type_classes_length, len)
   tree:add(field_type_classes, tvbuf:range(4, len:uint()))

   -- FIXME: decode classes, set info

   return tvbuf:len()
end

function req.init()
   DissectorTable.get("zwave.host_request"):set(command_id, req)
end
