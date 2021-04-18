-- i tried to include illustrative example mappings below. in init.lua, you would `require('leadermaps')`.
local binds = require('lib.bind')
local map_cr = binds.map_cr
local map_cu = binds.map_cu
local map_cmd = binds.map_cmd

-- prob don't need this
local maps = setmetatable({}, {__index = {whichKey = {}}})

function maps:load_whichKey_define()
  self.whichKey = {
    ["n|<Leader>"] = map_cu("silent WhichKey '<Space>'"):with_noremap():with_silent(),
    ["v|<Leader>"] = map_cu("silent WhichKeyVisual '<Space>'"):with_noremap():with_silent(),
    ["n|<LocalLeader>"] = map_cu("silent WhichKey '\\'"):with_noremap():with_silent(),
    ["v|<LocalLeader>"] = map_cu("silent WhichKeyVisual '\\'"):with_noremap():with_silent(),
    ["n|<LocalLeader>x"] = map_cr("ToggleCheckbox"):with_noremap(),
    ["n|<Leader>,"] = map_cr("Commentary"):with_noremap():with_silent(),
    ["n|<Leader><Left>"] = map_cr("BufferMoveNext"):with_noremap():with_silent(),
    ["n|<Leader>bv"] = map_cmd("<C-W>t<C-W>H"):with_noremap():with_silent(),
    ["n|<Leader>dl"] = map_cmd("<Plug>(Luadev-RunLine)"),
    ["n|<Leader>ep"] = map_cr([[vsplit $FOONV/lua/domain/plugins.lua]]):with_noremap(),
    ["n|<Leader>ff"] = map_cr("lua require('telescope').extensions.fzf_writer.staged_grep()"):with_noremap()
  }
end

local function load_maps()
  require('wkDescriptions') -- this is a placeholder for the tricky part; see below
  maps:load_whichKey_define()
  binds.nvim_load_mapping(maps.whichKey)
end

load_maps()

-- basically, there just needs to be a wrapper function that will preprocess the which-key setup
-- configuration to parse out the text descriptions, pass them to which-key, and then pass the rest on to this library of
-- functions. but handling keymaps this way, albeit after some more user-friendly tweaking, is more
-- robust in all ways than using whichkey.
----------------------------------