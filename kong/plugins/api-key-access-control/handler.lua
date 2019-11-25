local BasePlugin = require "kong.plugins.base_plugin"

local ApiKeyAccessControlHandler = BasePlugin:extend()

ApiKeyAccessControlHandler.PRIORITY = 950

function ApiKeyAccessControlHandler:new()
  ApiKeyAccessControlHandler.super.new(self, "api-key-access-control")
end

function ApiKeyAccessControlHandler:access(conf)
  ApiKeyAccessControlHandler.super.access(self)
end

return ApiKeyAccessControlHandler
