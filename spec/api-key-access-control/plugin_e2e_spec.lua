local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("ApiKeyAccessControl", function()
  local kong_sdk, send_request, send_admin_request

  setup(function()
    helpers.start_kong({ plugins = "api-key-access-control" })

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
            consumer = {
              id = consumer.id
            },
            name = "api-key-access-control",
            config = {}
          })
        end)

        assert.is_false(success)
        assert.are.equal("required field missing", response.body.fields.config.api_keys)
      end)
    end)

    context("when all required parameters are set", function()
      it("should fail to add plugin", function()
        local success, response = pcall(function()
          kong_sdk.plugins:create({
            consumer = {
              id = consumer.id
            },
            name = "api-key-access-control",
            config = {
              api_keys = {}
            }
          })
        end)

        assert.is_false(success)
        assert.are.equal("length must be at least 1", response.body.fields.config.api_keys)
      end)
    end)

    context("when all parameters are set", function()
      it("should set config default values", function()
        local response = kong_sdk.plugins:create({
          consumer = {
            id = consumer.id
          },
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" }
          }
        })

        assert.are.same({
          api_keys = { "some-key" },
          whitelist = {},
          whitelist_lua_pattern = {}
        }, response.config)
      end)
    end)

  end)

  context("Plugin logic", function()
    local service

    before_each(function()
      service = kong_sdk.services:create({
        name = "test-service",
        id = "0a7f3795-bc92-43b5-aada-258113b7c4ed",
        url = "http://mockbin:8080/request"
      })

      kong_sdk.routes:create_for_service(service.id, "/test")
    end)

    context("when whitelist is not set", function()
      it("should deny access for the api key", function()
        kong_sdk.plugins:create({
          service = {
            id = service.id
          },
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" }
          }
        })

        local response = send_request({
          method = "GET",
          path = "/test",
          headers = {
            ["x-credential-username"] = "some-key"
          }
        })

        assert.are.equal(403, response.status)
      end)

      it("should allow access for the api key", function()
        kong_sdk.plugins:create({
          service = {
            id = service.id
          },
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" }
          }
        })

        local response = send_request({
          method = "GET",
          path = "/test",
          headers = {
            ["x-credential-username"] = "some-other-key"
          }
        })

        assert.are.equal(200, response.status)
      end)
    end)

    context("when whitelist is set", function()
      it("should allow access for the api key", function()
        kong_sdk.plugins:create({
          service = {
            id = service.id
          },
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" },
            whitelist = { "some-key GET /test" }
          }
        })

        local response = send_request({
          method = "GET",
          path = "/test",
          headers = {
            ["x-credential-username"] = "some-key"
          }
        })

        assert.are.equal(200, response.status)
      end)

      it("should a handle query parameters", function()
        kong_sdk.plugins:create({
          service = {
            id = service.id
          },          
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" },
            whitelist = { "some-key GET /test?first=1" }
          }
        })

        local response = send_request({
          method = "GET",
          path = "/test?first=1",
          headers = {
            ["x-credential-username"] = "some-key"
          }
        })

        assert.are.equal(200, response.status)
      end)
    end)

    context("when whitelist with pattern matching is set", function()
      it("should allow request", function()
        kong_sdk.plugins:create({
          service = {
            id = service.id
          },
          name = "api-key-access-control",
          config = {
            api_keys = { "some-key" },
            whitelist_lua_pattern = { "some%-key GET /test/%d+/asd" }
          }
        })

        local response = send_request({
          method = "GET",
          path = "/test/123/asd",
          headers = {
            ["x-credential-username"] = "some-key"
          }
        })

        assert.are.equal(200, response.status)
      end)
    end)

  end)

end)
