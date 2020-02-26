local Schema = require "kong.db.schema"
local Errors = require "kong.db.errors"

return {
  name = "api-key-access-control",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            api_keys = { 
              type = "array", 
              elements = { 
                type = "string" 
              }, 
              required = true,
              len_min = 1
            }
          },
          {
            whitelist = { 
              type = "array", 
              elements = { 
                type = "string" 
              }, 
              default = {
              } 
            }
          },
          {
            whitelist_lua_pattern = { 
              type = "array", 
              elements = { 
                type = "string" 
              }, 
              default = {                
              } 
            }
          }
        }
      }
    }
  }
}