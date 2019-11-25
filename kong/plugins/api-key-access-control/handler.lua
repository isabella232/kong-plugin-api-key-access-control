local BasePlugin = require "kong.plugins.base_plugin"

local ApiKeyAccessControlHandler = BasePlugin:extend()

ApiKeyAccessControlHandler.PRIORITY = 950

function ApiKeyAccessControlHandler:new()
  ApiKeyAccessControlHandler.super.new(self, "api-key-access-control")
end

function ApiKeyAccessControlHandler:access(conf)
  ApiKeyAccessControlHandler.super.access(self)

  if conf.say_hello then
    kong.log.debug("Hey!")

    kong.service.request.set_header("X-Upstream-Header", "Hey Upstream!")
    kong.response.set_header("X-Downstream-Header", "Hey Downstream!")
  else
    kong.log.debug("Bye!")

    kong.service.request.set_header("X-Upstream-Header", "Bye Upstream!")
    kong.response.set_header("X-Downstream-Header", "Bye Downstream!")
  end

end

return ApiKeyAccessControlHandler
