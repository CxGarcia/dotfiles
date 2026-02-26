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
    f = 'Ghostty',
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

local sessionPickerTap = (function()
    local waitingForSecond = false
    local timer = nil
    local tap

    local function reset()
        waitingForSecond = false
        if timer then timer:stop(); timer = nil end
    end

    local function replayCtrlA()
        tap:stop()
        hs.eventtap.keyStroke({'ctrl'}, 'a', 0)
        tap:start()
    end

    tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        local isCtrlA = flags.ctrl and not flags.cmd and not flags.alt and not flags.shift and keyCode == 0

        local ghostty = hs.application.find('Ghostty')
        if ghostty and ghostty:isFrontmost() then
            reset()
            return false
        end

        if isCtrlA then
            if waitingForSecond then
                reset()
                if ghostty then
                    ghostty:activate()
                else
                    hs.application.launchOrFocus('Ghostty')
                end
                hs.timer.doAfter(0.15, function()
                    hs.task.new("/opt/homebrew/bin/tmux", nil, {
                        "display-popup", "-E", "-w", "80%", "-h", "70%",
                        "-S", "fg=#3a4450",
                        "bash ~/.config/tmux/scripts/ts.sh"
                    }):start()
                end)
                return true
            else
                waitingForSecond = true
                timer = hs.timer.doAfter(0.3, function()
                    reset()
                    replayCtrlA()
                end)
                return true
            end
        end

        if waitingForSecond then
            reset()
            replayCtrlA()
        end
        return false
    end)

    return tap
end)()
sessionPickerTap:start()

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



-- Load and configure Cherry pomodoro timer
hs.loadSpoon("Cherry")
spoon.Cherry.work_period_sec = 25 * 60  -- 25 minutes
spoon.Cherry.rest_period_sec = 5 * 60   -- 5 minute break

-- Track timer state and disabled hotkeys
local timerActive = false
local disabledHotkeys = {}
local pomodoroMonitor = nil

-- Keys to disable during pomodoro for focus (derived from applicationHotkeys)
local focusModeDisabledKeys = {
    "s",  -- Slack - social/chat apps
    "m",  -- Spotify - entertainment apps
    -- "c", -- Uncomment to disable Chrome during focus
    -- Add more distracting app keys here as needed
}

-- Derive the disabled apps from the main applicationHotkeys definition
local focusModeDisabledApps = {}
for _, key in ipairs(focusModeDisabledKeys) do
    if applicationHotkeys[key] then
        focusModeDisabledApps[key] = applicationHotkeys[key]
    end
end

-- Function to disable specific hotkeys during pomodoro
local function disableHotkeys()
    timerActive = true

    -- Disable specified hotkeys during focus mode
    for key, appName in pairs(focusModeDisabledApps) do
        local blockedHotkey = hs.hotkey.bind(hyper, key, function()
            hs.alert.show("🍅 Focus time! " .. appName .. " disabled during pomodoro")
        end)
        disabledHotkeys[key] = blockedHotkey
    end

    local disabledApps = {}
    for _, appName in pairs(focusModeDisabledApps) do
        table.insert(disabledApps, appName)
    end

    hs.alert.show("🍅 Pomodoro started! " .. table.concat(disabledApps, ", ") .. " disabled for focus")
end

-- Function to re-enable hotkeys after pomodoro
local function onFocusEnd()
    timerActive = false
    -- Stop monitoring timer
    if pomodoroMonitor then
        pomodoroMonitor:stop()
        pomodoroMonitor = nil
    end

    -- Clean up disabled hotkey bindings
    for key, hotkey in pairs(disabledHotkeys) do
        if hotkey then
            hotkey:delete()
        end
    end
    disabledHotkeys = {}

    -- Restore original hotkeys for the disabled apps
    for key, appName in pairs(focusModeDisabledApps) do
        hs.hotkey.bind(hyper, key, function()
            hs.application.launchOrFocus(appName)
        end)
    end

    hs.alert.show("✅ Pomodoro complete! Hotkeys re-enabled")
end

-- Function to check if Cherry timer is still running
local function isPomodoroRunning()
    -- Check if Cherry spoon has an active menubar item (typical indicator it's running)
    if spoon.Cherry.menubar then
        return true
    end

    -- Also check if there's a timer object that's still running
    if spoon.Cherry.timer and spoon.Cherry.timer:running() then
        return true
    end

    return false
end

-- Monitor pomodoro status and re-enable hotkeys if stopped early
local function startPomodoroMonitoring()
    if pomodoroMonitor then
        pomodoroMonitor:stop()
    end

    pomodoroMonitor = hs.timer.doEvery(2, function()
        if timerActive and not isPomodoroRunning() then
            onFocusEnd()
        end
    end)
end

-- Override Cherry's popup method to handle hotkey re-enabling
local originalPopup = spoon.Cherry.popup
spoon.Cherry.popup = function(self)
    originalPopup(self)
    if timerActive then
        onFocusEnd()
    end
end

-- Double press detection for the 'p' key (pomodoro)
local lastPomodoroPress = 0
local pomodoroDoublePressThreshold = 0.5 -- seconds

hs.hotkey.bind(hyper, "p", function()
    local currentTime = hs.timer.secondsSinceEpoch()
    local timeSinceLastPress = currentTime - lastPomodoroPress

    if timeSinceLastPress < pomodoroDoublePressThreshold then
        -- Double press detected - start pomodoro
        if not timerActive then
            disableHotkeys()
            spoon.Cherry:start()
            startPomodoroMonitoring()  -- Start monitoring for early stops
        else
            hs.alert.show("🍅 Pomodoro already running!")
        end
        lastPomodoroPress = 0 -- Reset the timer
    else
        lastPomodoroPress = currentTime
    end
end)

-- Screenshot paste: copy most recent screenshot to clipboard on demand (Hyper+I)
local screenshotDir = (function()
    local output, status = hs.execute("defaults read com.apple.screencapture location 2>/dev/null")
    if status and output then
        local path = output:gsub("%s+$", "")
        if path ~= "" then
            return path:gsub("^~", os.getenv("HOME"))
        end
    end
    return os.getenv("HOME") .. "/Desktop"
end)()

hs.hotkey.bind(hyper, "i", function()
    local latest = nil
    local latestMod = 0

    for file in hs.fs.dir(screenshotDir) do
        if file:match("^Screenshot") and file:match("%.png$") then
            local fullPath = screenshotDir .. "/" .. file
            local attrs = hs.fs.attributes(fullPath)
            if attrs and attrs.modification > latestMod then
                latestMod = attrs.modification
                latest = fullPath
            end
        end
    end

    if latest then
        hs.osascript.applescript(string.format(
            'set the clipboard to (read (POSIX file "%s") as TIFF picture)',
            latest
        ))
        hs.alert.show("Screenshot copied — ready to paste", 2)
    else
        hs.alert.show("No screenshots found", 2)
    end
end)

-- Cleanup function for reloads/shutdowns
local function cleanup()
    if pomodoroMonitor then
        pomodoroMonitor:stop()
        pomodoroMonitor = nil
    end
    -- Re-enable any disabled hotkeys during shutdown/reload
    if timerActive then
        -- Clean up disabled hotkey bindings
        for key, hotkey in pairs(disabledHotkeys) do
            if hotkey then
                hotkey:delete()
            end
        end
        disabledHotkeys = {}
        timerActive = false

        hs.alert.show("🔄 Config reloaded - Pomodoro hotkeys restored")
    end
end

-- Register cleanup on reload/shutdown
hs.shutdownCallback = cleanup

hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
