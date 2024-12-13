local M = {}

local function all_trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- local config
local C = {
    -- AIMSwitcher binary's name, or the binary's full path
    command = "AIMSwitcher",
    -- default input method in normal mode.
    default_ime = { method = "1033", mode = nil },
    -- default_ime = { method = "2052", mode = 0 },

    -- Restore the default input method state when the following events are triggered
    set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
    -- Restore the previous used input method state when the following events are triggered
    set_previous_events = { "InsertEnter" },

    keep_quiet_on_no_binary = false,
}

local function set_opts(opts)
    if opts == nil or type(opts) ~= "table" then
        return
    end

    if opts.default_ime ~= nil then
        C.default_ime = opts.default_ime
    end

    if opts.command ~= nil then
        C.command = opts.command
    end

    if opts.set_default_events ~= nil and type(opts.set_default_events) == "table" then
        C.set_default_events = opts.set_default_events
    end

    if opts.set_previous_events ~= nil and type(opts.set_previous_events) == "table" then
        C.set_previous_events = opts.set_previous_events
    end

    if opts.keep_quiet_on_no_binary then
        C.keep_quiet_on_no_binary = true
    end
end

local function get_ime(cmd)
    local method = all_trim(vim.fn.system({ cmd, '--im' }))
    local mode = nil
    if method == '2052' then
        mode = all_trim(vim.fn.system({ cmd, '--imm' }))
    end
    return { method = method, mode = mode }
end

local function set_ime(cmd, ime)
    vim.fn.system({ cmd, '--im', ime.method })
    if ime.mode ~= nil then
        vim.fn.system({ cmd, '--imm', ime.mode })
    end
end

local function restore_default_ime()
    local current = get_ime(C.command)
    vim.api.nvim_set_var("im_select_saved_state", current)

    if current ~= C.method then
        set_ime(C.command, C.default_ime)
    end
end

local function restore_previous_ime()
    local current = get_ime(C.command)
    local saved = vim.g["im_select_saved_state"]

    if current.method ~= saved.method or current.mode ~= saved.mode then
        set_ime(C.command, saved)
    end
end

M.setup = function(opts)
    set_opts(opts)

    if vim.fn.executable(C.command) ~= 1 then
        if not C.keep_quiet_on_no_binary then
            vim.api.nvim_err_writeln([[please install `AIMSwitcher` binary first]])
        end
        return
    end

    -- set autocmd
    local group_id = vim.api.nvim_create_augroup("aimswitcher", { clear = true })

    if #C.set_previous_events > 0 then
        vim.api.nvim_create_autocmd(C.set_previous_events, {
            callback = restore_previous_ime,
            group = group_id,
        })
    end

    if #C.set_default_events > 0 then
        vim.api.nvim_create_autocmd(C.set_default_events, {
            callback = restore_default_ime,
            group = group_id,
        })
    end
end

return M
