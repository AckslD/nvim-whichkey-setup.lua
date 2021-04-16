M = {}

-- Default settings
local settings = {
    hide_statusline = false,
    default_keymap_settings = {
        silent=true,
        noremap=true,
    },
    default_mode = 'n',
}

local textmaps = {}

-- for debugging
M.debug = {}
M.debug.print_current_textmaps = function()
    local function print_key_map(key, value, indent)
        if indent == nil then indent = 0 end
        local indent_str = string.rep(' ', indent)
        if type(value) == "string" then
            print(indent_str.."'"..key.."' -> "..value)
        else
            print(indent_str.."'"..key.."':")
            local new_indent = indent+1
            for k, v in pairs(value) do
                print_key_map(k, v, new_indent)
            end
        end
    end
    for key, value in pairs(textmaps) do
        print_key_map(key, value)
    end
end

local function get_new_leaders(leaders, key)
    local new_leader = {}
    for _, l in ipairs(leaders) do
        table.insert(new_leader, l)
    end
    table.insert(new_leader, key)
    return new_leader
end

local function is_keymap_leaf(value)
    -- a bit sketchy but we check if value is a string or "array"
    -- with "array" meaning it has number indices as keys
    return (type(value) == 'string') or (value[1] ~= nil)
end


local function setup_keymap(mode, leaders, keymap, textmap, opts, bufnr)
    for key, value in pairs(keymap) do
        if (textmap[key] == nil) then
            textmap[key] = {}
        end
        if (key == 'name') then
            textmap[key] = value
        end
        -- update current if leaf, otherwise recurse
        if is_keymap_leaf(value) then
            if type(value) == 'table' then -- contains a cmd + text
                local keys = table.concat(leaders, "")..key
                if bufnr == nil then
                    vim.api.nvim_set_keymap(mode, keys, value[1], opts)
                else
                    vim.api.nvim_buf_set_keymap(bufnr, mode, keys, value[1], opts)
                end
                textmap[key] = value[2]
            else
                textmap[key] = value
            end
        else
            local new_leader = get_new_leaders(leaders, key)
            setup_keymap(mode, new_leader, value, textmap[key], opts, bufnr)
        end
    end
end

local function handle_user_opts(opts)
    local default_opts = {
        silent = settings.default_keymap_settings.silent,
        noremap = settings.default_keymap_settings.noremap,
        mode = settings.default_mode,
    }
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(default_opts) do
        if opts[key] == nil then
            opts[key] = value
        end
    end
    -- split general options and keymap options
    local split_opts = {keymap_opts = {}}
    for key, value in pairs(opts) do
        if key == "silent" or key == "noremap" then
            split_opts.keymap_opts[key] = value
        else
            split_opts[key] = value
        end
    end
    return split_opts
end

local function get_key_spec(initial_key, mode)
    local key, raw_key
    if (initial_key == 'leader') then -- handle special initial keys
        key = '<Leader>'
        if mode == 'n' then
            raw_key = vim.g.mapleader
        else
            raw_key = '<VisualBindings>'
        end
    elseif (initial_key == 'localleader') then
        key = '<Localleader>'
        if mode == 'n' then
            raw_key = vim.g.maplocalleader
        else
            raw_key = '<LocalVisualBindings>'
        end
    else
        if string.len(initial_key) > 1 then
            vim.cmd('echoerr "Can only specify a single initial key, not '..initial_key..'"')
        end
        key = initial_key
        raw_key = initial_key
    end
    return {
        key = key,
        raw_key = raw_key,
    }
end

local function to_textmap_key(initial_key, mode, bufnr)
    if bufnr == nil then
        bufnr = "x"
    end
    return initial_key..' '..mode..' '..bufnr
end

local function from_textmap_key(textmap_key)
    local entries = {}
    for match in  string.gmatch(textmap_key, '%S+') do
        table.insert(entries, match)
    end
    return {
        initial_key = entries[1],
        mode = entries[2],
        bufnr = entries[3],
    }
end

local function setup_hide_statusline()
    vim.cmd('autocmd! FileType which_key')
    vim.cmd('autocmd Filetype which_key set laststatus=0 noshowmode noruler | autocmd BufLeave <buffer> set laststatus=2 showmode ruler')
end

local vim_enter_autocmd_added = false
local function add_vim_enter_autocmd()
    vim.cmd('autocmd VimEnter * lua require("whichkey_setup").setup_which_key()')
    vim_enter_autocmd_added = true
end

M.setup_which_key = function()
    for textmap_key, textmap in pairs(textmaps) do
        local entries = from_textmap_key(textmap_key)
        local mode = entries.mode
        local key_spec = get_key_spec(entries.initial_key)
        local key = key_spec.key
        local raw_key = key_spec.raw_key
        -- local bufnr = entries.bufnr -- TODO start using this when supported by which_key
        vim.fn['which_key#register'](raw_key, textmap)
        raw_key = vim.fn.escape(raw_key, '\\')
        vim.api.nvim_set_keymap(mode, key, ':<c-u> :WhichKey "'..raw_key..'"<CR>', {silent=true, noremap=true})
    end
end


M.register_keymap = function(initial_key, keymap, opts)
    opts = handle_user_opts(opts)
    -- check if initial_key specifies mode for backwards compatibility
    local mode = opts.mode
    if initial_key == 'visual' then
        mode = 'v'
        initial_key = 'leader'
    end
    if initial_key == 'localvisual' then
        mode = 'v'
        initial_key = 'localleader'
    end

    local key = get_key_spec(initial_key, mode).key
    local textmap_key = to_textmap_key(initial_key, mode, opts.bufnr)
    if textmaps[textmap_key] == nil then textmaps[textmap_key] = {} end
    local textmap = textmaps[textmap_key]
    setup_keymap(mode, {key}, keymap, textmap, opts.keymap_opts, opts.bufnr)

    if vim.v.vim_did_enter == 1 then
        M.setup_which_key()
    else
        if not vim_enter_autocmd_added then
            add_vim_enter_autocmd()
        end
    end
end

M.config = function(user_settings)
    user_settings = user_settings or {}
    for key, value in pairs(user_settings) do
        if settings[key] == nil then
            vim.cmd('echoerr "Unknown setting '..key..'"')
        end
        settings[key] = value
    end
    if settings.hide_statusline then
        setup_hide_statusline()
    end
end

return M
