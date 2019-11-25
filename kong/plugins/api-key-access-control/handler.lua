local BasePlugin = require "kong.plugins.base_plugin"

local ApiKeyAccessControlHandler = BasePlugin:extend()

ApiKeyAccessControlHandler.PRIORITY = 950

function ApiKeyAccessControlHandler:new()
  ApiKeyAccessControlHandler.super.new(self, "api-key-access-control")
end

function ApiKeyAccessControlHandler:access(conf)
  ApiKeyAccessControlHandler.super.access(self)

  local api_key = kong.request.get_header("x_credential_username")
  for i = 1, #conf.api_keys do
    if conf.api_keys[i] == api_key then
      return kong.response.exit(403)
    end
  end

  return
end

return ApiKeyAccessControlHandler
