local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "0", function()
    hs.reload()
end)

-- [Your existing screen navigation code here]

-- Application hotkeys
local applicationHotkeys = {
    f = 'iTerm',
    n = 'Obsidian',
    m = 'Spotify',
    c = 'Google Chrome'
}

-- Set up the regular application hotkeys
for key, app in pairs(applicationHotkeys) do
    hs.hotkey.bind(hyper, key, function()
        hs.application.launchOrFocus(app)
    end)
end

-- V-app toggle configuration
local vAppToggle = {
    currentApp = 'Zed Preview',
    apps = { 'Zed Preview', 'Cursor' }
}

menubarIcon = hs.menubar.new()

-- Check if menubar was created successfully

-- Function to toggle the app for the 'v' key
local function toggleVApp()
    if vAppToggle.currentApp == vAppToggle.apps[1] then
        menubarIcon:setTitle("🚀")
        vAppToggle.currentApp = vAppToggle.apps[2]
    else
        menubarIcon:setTitle("🔥")
        vAppToggle.currentApp = vAppToggle.apps[1]
    end

    print("Application toggled to " .. vAppToggle.currentApp)
    hs.notify.new({
        title = "Application Toggled",
        informativeText = "The 'v' key now launches: " .. vAppToggle.currentApp
    }):send()
end

if menubarIcon then
    if vAppToggle.currentApp == vAppToggle.apps[1] then
        menubarIcon:setTitle("🔥")
    end

    menubarIcon:setClickCallback(function()
        toggleVApp()
    end)
end


hs.hotkey.bind(hyper, "v", function()
    hs.application.launchOrFocus(vAppToggle.currentApp)
end)

-- Double press detection for the 'v' key
local lastVPressTime = 0
local doublePressTimeThreshold = 0.5 -- seconds


-- Set up the 'v' hotkey with double-press detection
hs.hotkey.bind(hyper, "x", function()
    local currentTime = hs.timer.secondsSinceEpoch()
    local timeSinceLastPress = currentTime - lastVPressTime

    if timeSinceLastPress < doublePressTimeThreshold then
        -- Double press detected - toggle the app
        toggleVApp()
        lastVPressTime = 0 -- Reset the timer
    else
        lastVPressTime = currentTime
    end
end)



hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
