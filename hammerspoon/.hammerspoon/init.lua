local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "0", function()
    hs.reload()
end)

local function mouse_to_next_screen()
    local screen = hs.mouse.getCurrentScreen()
    local nextScreen = screen:next()
    local rect = nextScreen:fullFrame()
    local center = hs.geometry.rectMidPoint(rect)
    hs.mouse.setAbsolutePosition(center)
end
  
local function get_window_under_mouse()
    local my_pos = hs.geometry.new(hs.mouse.getAbsolutePosition())
    local my_screen = hs.mouse.getCurrentScreen()
    return hs.fnutils.find(hs.window.orderedWindows(), function(w)
    return my_screen == w:screen() and my_pos:inside(w:frame())
    end)
end
  
local function focus_next_screen()
    mouse_to_next_screen()
    local win = get_window_under_mouse()
    win:focus()
end
  
hs.hotkey.bind(hyper, "w", function() -- does the keybinding
       focus_next_screen()
end)
  
  -- previous screen
local function mouse_to_prev_screen()
    local screen = hs.mouse.getCurrentScreen()
    local prevScreen = screen:previous()
    local rect = prevScreen:fullFrame()
    local center = hs.geometry.rectMidPoint(rect)
    hs.mouse.setAbsolutePosition(center)
end
  
local function focus_prev_screen()
    mouse_to_prev_screen()
    local win = get_window_under_mouse()
    win:focus()
end
  
hs.hotkey.bind(hyper, "q", function() -- does the keybinding
    focus_prev_screen()
end)
  
-- Application hotkeys
local applicationHotkeys = {
    f = 'iTerm',
    n = 'Obsidian',
    m = 'Spotify',
    c = 'Google Chrome',
    s = "Slack"
}

-- Set up the regular application hotkeys
for key, app in pairs(applicationHotkeys) do
    hs.hotkey.bind(hyper, key, function()
        hs.application.launchOrFocus(app)
    end)
end

local editorConfigPath = "~/.editor-profile"

local function readEditorConfig()
    return hs.json.read(editorConfigPath)
end

local conf = readEditorConfig()

local function updateEditor(editor)
    conf["editor"] = editor

    hs.json.write(conf, editorConfigPath, true, true)
end

local editorProps = {
    { name = "Cursor", icon = "🚀" },
    { name = "Zed Preview", icon = "🔥" }
}

local menubarIcon = hs.menubar.new()

local function toggleEditor()
    local nextEditor
    
    for _, editor in pairs(editorProps) do
        if editor.name ~= conf["editor"] then
            nextEditor = editor
            break -- Stop after finding the first match
        end
    end
    
    updateEditor(nextEditor.name)
    menubarIcon:setTitle(nextEditor.icon)
end

if menubarIcon then
    for _, editor in pairs(editorProps) do
        if editor.name == conf["editor"] then
            menubarIcon:setTitle(editor.icon)
        end
    end

    menubarIcon:setClickCallback(function()
        toggleEditor()
    end)
end


hs.hotkey.bind(hyper, "v", function()
    hs.application.launchOrFocus(conf["editor"])
end)

-- Double press detection for the 'x' key
local lastPressTime = 0
local doublePressTimeThreshold = 0.5 -- seconds


-- Set up the 'x' hotkey with double-press detection
hs.hotkey.bind(hyper, "x", function()
    local currentTime = hs.timer.secondsSinceEpoch()
    local timeSinceLastPress = currentTime - lastPressTime

    if timeSinceLastPress < doublePressTimeThreshold then
        -- Double press detected - toggle the app
        toggleEditor()
        lastPressTime = 0 -- Reset the timer
    else
        lastPressTime = currentTime
    end
end)



hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
