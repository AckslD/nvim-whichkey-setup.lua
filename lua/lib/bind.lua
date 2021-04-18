local wkbind = {}

-- most credit goes to github.com/glepnir

--[[ Overview
There are three types of mappings, each of which can be used in whatever mode:
  wkbind.map_cr ->  self.cmd = (":%s<CR>"):format(cmd_string)
  wkbind.map_cu -> self.cmd = (":<C-u>%s<CR>"):format(cmd_string)
  wkbind.map_cmd -> self.cmd = cmd_string

There are 4 boolean mapping option parameters:
  noremap
  silent
  expr
  nowait

Then the optional text description, which is not fully implemented.
]]

-- mapping options like noremap, silent, etc.
local rhs_options = {}

function wkbind.bind_option(options)
    for k, v in pairs(options) do
        if v == true or v == false then
            vim.cmd('set ' .. k)
        else
            vim.cmd('set ' .. k .. '=' .. v)
        end
    end
end

function rhs_options:new()
    local instance = {
        cmd = '',
        options = {
            noremap = false,
            silent = false,
            expr = false,
            nowait = false
        },
        description = ''
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

-- different ways of mapping
function rhs_options:map_cmd(cmd_string)
    self.cmd = cmd_string
    return self
end

function rhs_options:map_cr(cmd_string)
    self.cmd = (":%s<CR>"):format(cmd_string)
    return self
end

function rhs_options:map_cu(cmd_string)
    self.cmd = (":<C-u>%s<CR>"):format(cmd_string)
    return self
end

function rhs_options:with_desc(desc)
  self.description = desc or ''
  return self
end

-- this one is not implemented but could be
function rhs_options:map_args(cmd_string)
    self.cmd = (":%s<Space>"):format(cmd_string)
    return self
end

function rhs_options:with_silent()
    self.options.silent = true
    return self
end

function rhs_options:with_noremap()
    self.options.noremap = true
    return self
end

function rhs_options:with_expr()
    self.options.expr = true
    return self
end

function rhs_options:with_nowait()
    self.options.nowait = true
    return self
end

function wkbind.map_cr(cmd_string)
    local opts = rhs_options:new()
    return opts:map_cr(cmd_string)
end

function wkbind.map_cmd(cmd_string)
    local opts = rhs_options:new()
    return opts:map_cmd(cmd_string)
end

function wkbind.map_cu(cmd_string)
    local opts = rhs_options:new()
    return opts:map_cu(cmd_string)
end

function wkbind.map_args(cmd_string)
    local opts = rhs_options:new()
    return opts:map_args(cmd_string)
end



function wkbind.nvim_load_mapping(mapping)
    for key, value in pairs(mapping) do
        local mode, keymap = key:match("([^|]*)|?(.*)")
        if type(value) == 'table' then
            local rhs = value.cmd
            local options = value.options
            local textmap = value.description -- this is the string value of the description
            vim.api.nvim_set_keymap(mode, keymap, rhs, options)
        end
        -- right here append these values for mode, keymap, textmap to the appropriate table for which-key popup; see below
        -- table.insert(whichtable)
    end
    -- return(whichtable)
end

return wkbind

--[[ 
basically, the there just needs to be a wrapper function that will connect the dots from here to the plugin setup
configuration. in other words, 'return(whichtable)' in the last function call needs to be fitted. handling keymaps 
this way is more robust than how which-key does it (from what i remember). 

but nothing is easy, time is limited, and this particular rabbit hole will quickly spiral into a full rebuild of which-key in lua.  
--]] 
