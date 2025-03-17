local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "0", function()
  hs.reload()
end)

-- next screen
local function mouse_to_next_screen()
  local screen = hs.mouse.getCurrentScreen()
  local nextScreen = screen:next()
  local rect = nextScreen:fullFrame()
  local center = hs.geometry.rectMidPoint(rect)
  hs.mouse.setAbsolutePosition(center)
end

--get the window under cursor
function get_window_under_mouse()
  local my_pos = hs.geometry.new(hs.mouse.getAbsolutePosition())
  local my_screen = hs.mouse.getCurrentScreen()
  return hs.fnutils.find(hs.window.orderedWindows(), function(w)
  return my_screen == w:screen() and my_pos:inside(w:frame())
  end)
end

function focus_next_screen()
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

function focus_prev_screen()
  mouse_to_prev_screen()
  local win = get_window_under_mouse()
  win:focus()
end

hs.hotkey.bind(hyper, "q", function() -- does the keybinding
  focus_prev_screen()
end)

hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

local applicationHotkeys = {
  f = 'iTerm',
  z = 'Zed Preview',
  -- v = 'Zed',
  v = 'Cursor',
  n = 'Obsidian',
  s = 'Slack',
  m = 'Spotify',
  c = 'Google Chrome'
}

for key, app in pairs(applicationHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end
