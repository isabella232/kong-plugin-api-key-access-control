local BasePlugin = require "kong.plugins.base_plugin"

local ApiKeyAccessControlHandler = BasePlugin:extend()

ApiKeyAccessControlHandler.PRIORITY = 950

function ApiKeyAccessControlHandler:new()
  ApiKeyAccessControlHandler.super.new(self, "api-key-access-control")
end

function ApiKeyAccessControlHandler:access(conf)
  ApiKeyAccessControlHandler.super.access(self)

  local api_key = kong.request.get_header("x_credential_username")
  local whitelist_rule = table.concat({api_key, kong.request.get_method(), kong.request.get_path()}, " ")

  for i = 1, #conf.api_keys do
    if conf.api_keys[i] == api_key then
      for j = 1, #conf.whitelist do
        if whitelist_rule == conf.whitelist[j] then
          return
        end
      end
      return kong.response.exit(403)
    end
  end

  return
end

return ApiKeyAccessControlHandler
