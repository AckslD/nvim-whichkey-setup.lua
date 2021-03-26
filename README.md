# nvim-whichkey-setup.lua

This nvim-plugin is just a wrapper for [`vim-which-key`](https://github.com/liuchengxu/vim-which-key) to simplify setup in lua.

# Features
* Simple setup in lua.
* Can handle complex commands without having the need to make a dedicated command for them as is the case with bare `whichkey`.
* Can handle leader and localleader in normal and visual mode through global or buffer keymaps.

# Installation

Use your favourite plugin manager, for example using [`packer.nvim`](https://github.com/wbthomason/packer.nvim)
```lua
use {
    'AckslD/nvim-whichkey-setup.lua',
    requires = {'liuchengxu/vim-which-key'},
}
```
or [`vim-plug`](https://github.com/junegunn/vim-plug):
```vim
Plug 'liuchengxu/vim-which-key'
Plug 'AckslD/nvim-whichkey-setup.lua'
```

# Usage
The plugin allows you to define commands and helper texts to be used with whichkey using a [which_key_map](https://github.com/liuchengxu/vim-which-key#example).
Other settings such as `vim.g.which_key_timeout` needs to be set separately.

For how to setup the keymaps see examples below.
Additionally, feel free to checkout my own [config](https://gitlab.com/AckslD/config/-/tree/master/nvim) for how I use it.
Four different types of keymaps can be set
* `leader`: `<Leader>` in normal mode.
* `localleader`: `<LocalLeader>` in normal mode.
* `visual`: `<Leader>` in visual mode.
* `localvisual`: `<LocalLeader>` in visual mode.

Note that you won't need to map the leader-keys to the `WhichKey`-command since this will be handled automatically by `whichkey-setup`.

All commands specified are directly mapped rather relying on whichkey to execute them which allows you to set arbitrary complex commands.

## Examples
### General
```lua
local wk = require('whichkey_setup')

local keymap = {
    
    w = {':w!<CR>', 'save file'} -- set a single command and text
    j = 'split args' -- only set a text for an already configured keymap
    ['<CR>'] = {'@q', 'macro q'}, -- setting a special key
    f = { -- set a nested structure
        name = '+find',
        b = {'<Cmd>Telescope buffers<CR>', 'buffers'},
        h = {'<Cmd>Telescope help_tags<CR>', 'help tags'},
        c = {
            name = '+commands',
            c = {'<Cmd>Telescope commands<CR>', 'commands'},
            h = {'<Cmd>Telescope command_history<CR>', 'history'},
        },
        q = {'<Cmd>Telescope quickfix<CR>', 'quickfix'},
        g = {
            name = '+git',
            g = {'<Cmd>Telescope git_commits<CR>', 'commits'},
            c = {'<Cmd>Telescope git_bcommits<CR>', 'bcommits'},
            b = {'<Cmd>Telescope git_branches<CR>', 'branches'},
            s = {'<Cmd>Telescope git_status<CR>', 'status'},
        },
    }
}

wk.register_keymap('leader', keymap)
```

### Local leader and visual
You can set maps for each type.
Note that you can do this as many times as you want for each.
This won't overwrite what was already set but rather extend it so that you can keep specific keymaps for various plugins in different places.
```lua
local wk = require('whichkey_setup')

local visual_keymap = {
    K = {':move \'<-2<CR>gv-gv', 'move line up'},
    J = {':move \'>+1<CR>gv-gv', 'move line down'},
}
local local_keymap = {
    r = {':!python %', 'run python'},
}

wk.register_keymap('visual', visual_keymap)
wk.register_keymap('localleader', local_keymap)
```

### Map options and buffer local keymaps
You can pass options to the `register_keymap`-function which are all passed when setting the actual keymap.
If no options are passed `{silent = true, noremap = true}` is used.
Additionally you to the map-options you can also pass a `bufnr` to define buffer-local keymap. If `bufnr` is not set a global keymap is defined.
```lua
local wk = require('whichkey_setup')

local keymap = {l = {name = '+lsp'}}
if client.resolved_capabilities.document_formatting then
    keymap.l.f = {"<Cmd>lua vim.lsp.buf.formatting()<CR>", 'format'}
elseif client.resolved_capabilities.document_range_formatting then
    keymap.l.f = {"<Cmd>lua vim.lsp.buf.range_formatting()<CR>", 'format'}
end
wk.register_keymap('leader', keymap, {noremap=true, silent=true, bufnr=bufnr})

wk.register_keymap('leader', keymap)
```
