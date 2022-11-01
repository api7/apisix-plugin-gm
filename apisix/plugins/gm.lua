-- local common libs
local require = require
local core    = require("apisix.core")

-- local function

-- module define
local plugin_name = "gm"

-- plugin schema
local plugin_schema = {
    type = "object",
    properties = {
    },
}

local _M = {
    version  = 0.1,            -- plugin version
    priority = 43,
    name     = plugin_name,    -- plugin name
    schema   = plugin_schema,  -- plugin schema
}


function _M.init()

end


function _M.destroy()

end

-- module interface for schema check
-- @param `conf` user defined conf data
-- @param `schema_type` defined in `apisix/core/schema.lua`
-- @return <boolean>
function _M.check_schema(conf, schema_type)
    return core.schema.check(plugin_schema, conf)
end


return _M
