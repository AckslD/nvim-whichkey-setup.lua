M = {}

-- Default settings
local settings = {
    hide_statusline = false,
    default_keymap_settings = {
        silent=true,
        noremap=true,
    },
}

local textmaps = {
    leader = {},
    localleader = {},
    visual = {},
    localvisual = {},
}

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
    }
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(default_opts) do
        if opts[key] == nil then
            opts[key] = value
        end
    end
    return opts
end

M.register_keymap = function(leader_type, keymap, opts)
    opts = handle_user_opts(opts)
    local bufnr = opts.bufnr
    opts.bufnr = nil
    local mapkey = leader_type
    local mode, key, mapped_key
    if (leader_type == 'leader') then
        mode = 'n'
        key = '<Leader>'
        mapped_key = vim.g.mapleader
    elseif (leader_type == 'localleader') then
        mode = 'n'
        key = '<Localleader>'
        mapped_key = vim.g.maplocalleader
    elseif (leader_type == 'visual') then
        mode = 'v'
        key = '<Leader>'
        mapped_key = '<VisualBindings>'
    elseif (leader_type == 'localvisual') then
        mode = 'v'
        key = '<Localleader>'
        mapped_key = '<LocalVisualBindings>'
    else
        mode = opts.mode
        if mode == nil then mode = 'n' end
        key = leader_type
        mapped_key = leader_type
        mapkey = leader_type .. mode
    end
    if textmaps[mapkey] == nil then textmaps[mapkey] = {} end
    local textmap = textmaps[mapkey]
    setup_keymap(mode, {key}, keymap, textmap, opts, bufnr)

    -- TODO at the moment we register with whichkey plugin everytime
    -- would be better to only do this once but not sure when to do this
    vim.fn['which_key#register'](mapped_key, textmap)
    mapped_key = vim.fn.escape(mapped_key, '\\')
    vim.api.nvim_set_keymap(mode, key, ':<c-u> :WhichKey "'..mapped_key..'"<CR>', {silent=true, noremap=true})
end

local function setup_hide_statusline()
    vim.cmd('autocmd! FileType which_key')
    vim.cmd('autocmd Filetype which_key set laststatus=0 noshowmode noruler | autocmd BufLeave <buffer> set laststatus=2 showmode ruler')
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
