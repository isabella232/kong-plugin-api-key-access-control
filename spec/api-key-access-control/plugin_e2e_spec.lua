local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"
local dump = require("pl.pretty").dump

describe("ApiKeyAccessControl", function()
  local kong_sdk, send_request, send_admin_request

  setup(function()
    helpers.start_kong({ custom_plugins = "api-key-access-control" })

    kong_sdk = kong_client.create_kong_client()
    send_request = kong_client.create_request_sender(helpers.proxy_client())
    send_admin_request = kong_client.create_request_sender(helpers.admin_client())
  end)

  teardown(function()
    helpers.stop_kong(nil)
  end)

  before_each(function()
    helpers.db:truncate()
  end)

  context("Plugin configuration", function()

    local consumer

    before_each(function()
      consumer = kong_sdk.consumers:create({
        username = "test-consumer"
      })
    end)

    context("when required parameters are missing", function()
      it("should fail to add plugin", function()
        local success, response = pcall(function()
          kong_sdk.plugins:create({
            consumer_id = consumer.id,
            name = "api-key-access-control",
            config = {}
          })
        end)

        assert.is_false(success)
        assert.are.equal("api_keys is required", response.body["config.api_keys"])
      end)
    end)

    context("when all required parameters are set", function()
      it("should fail to add plugin", function()
        local success, response = pcall(function()
          kong_sdk.plugins:create({
            consumer_id = consumer.id,
            name = "api-key-access-control",
            config = {
              api_keys = {}
            }
          })
        end)

        assert.is_false(success)
        assert.are.equal("you must set at least one api key", response.body["config"])
      end)
    end)

    context("when all parameters are set", function()
      it("should set whitelist parameter's default value", function()
        local response = kong_sdk.plugins:create({
          consumer_id = consumer.id,
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" }
          }
        })

        assert.are.same({}, response.config["whitelist"])
      end)
    end)

  end)

end)
