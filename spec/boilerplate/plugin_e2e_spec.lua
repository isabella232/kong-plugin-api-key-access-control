local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("Boilerplate", function()
  local kong_sdk, send_request, send_admin_request

  setup(function()
    helpers.start_kong({ custom_plugins = "boilerplate" })

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

  context("when the say_hello flag is true", function()

    local service

    before_each(function()
      service = kong_sdk.services:create({
        name = "test-service",
        url = "http://mockbin:8080/request"
      })

      kong_sdk.routes:create_for_service(service.id, "/test")
    end)

    it("should add headers to the proxied request", function()
      kong_sdk.plugins:create({
        service_id = service.id,
        name = "boilerplate",
        config = {
          say_hello = true
        }
      })

      local response = send_request({
        method = "GET",
        path = "/test"
      })

      assert.are.equal(200, response.status)
      assert.is_equal("Hey Upstream!", response.body.headers["x-upstream-header"])
      assert.is_equal("Hey Downstream!", response.headers["X-Downstream-Header"])
    end)
  end)

  context("when the say_hello flag is false", function()

    local service

    before_each(function()
      service = kong_sdk.services:create({
        name = "test-service",
        url = "http://mockbin:8080/request"
      })

      kong_sdk.routes:create_for_service(service.id, "/test")
    end)

    it("should add headers to the proxied request", function()
      kong_sdk.plugins:create({
        service_id = service.id,
        name = "boilerplate",
        config = {
          say_hello = false
        }
      })

      local response = send_request({
        method = "GET",
        path = "/test"
      })

      assert.are.equal(200, response.status)
      assert.is_equal("Bye Upstream!", response.body.headers["x-upstream-header"])
      assert.is_equal("Bye Downstream!", response.headers["X-Downstream-Header"])
    end)
  end)
end)
