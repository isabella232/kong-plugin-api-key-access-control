local BasePlugin = require "kong.plugins.base_plugin"

local MypluginHandler = BasePlugin:extend()

MypluginHandler.PRIORITY = 2000

function MypluginHandler:new()
  MypluginHandler.super.new(self, "myplugin")
end

function MypluginHandler:access(conf)
  MypluginHandler.super.access(self)

  if conf.say_hello then
    kong.log.debug('Hey!')

    kong.service.request.set_header('X-Upstream-Header', 'Hey Upstream!')
    kong.response.set_header('X-Downstream-Header', 'Hey Downstream!')
  else
    kong.log.debug('Bye!')

    kong.service.request.set_header('X-Upstream-Header', 'Bye Upstream!')
    kong.response.set_header('X-Downstream-Header', 'Bye Downstream!')
  end

end

return MypluginHandler
