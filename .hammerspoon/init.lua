-- Create a logger for debugging  
local logger = hs.logger.new('RightCmdToEnter', 'info')

-- Try using CGEvent monitoring for low-level key detection
local rightCmdTap = nil
local eventTapRunning = false
local rightCmdPressedAlone = false
local otherKeysPressed = false

-- Create event tap for all events to catch modifier keys and regular keys
rightCmdTap = hs.eventtap.new({
  hs.eventtap.event.types.flagsChanged,
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp
}, function(event)
  if not eventTapRunning then return end

  local eventType = event:getType()
  local keyCode = event:getKeyCode()
  
  -- Track regular key presses (non-modifier keys)
  if eventType == hs.eventtap.event.types.keyDown then
    -- If any regular key is pressed while right CMD is down, invalidate
    if rightCmdPressedAlone then
      otherKeysPressed = true
      logger.d("Other key pressed while right CMD down - invalidating")
    end
  end
  
  -- For flagsChanged events, check the raw event data
  if eventType == hs.eventtap.event.types.flagsChanged then
    local flags = event:getFlags()
    local rawFlags = event:rawFlags()
    
    logger.d("Flags changed - rawFlags: " .. rawFlags)
   
    -- Check for specific right command flag (0x10 shifted to right position)
    -- Right command typically has a different raw flag value than left command
    local rightCmdMask = 0x000010  -- Right command mask
    local leftCmdMask = 0x000008   -- Left command mask
    
    local rightCmdPressed = (rawFlags & rightCmdMask) ~= 0
    local leftCmdPressed = (rawFlags & leftCmdMask) ~= 0
    
    logger.d("Left CMD: " .. tostring(leftCmdPressed) .. ", Right CMD: " .. tostring(rightCmdPressed))
    
    -- Right CMD pressed down
    if rightCmdPressed and not leftCmdPressed and not rightCmdPressedAlone then
      -- Check if NO other modifiers are pressed at press time
      local hasOtherModifiers = flags.shift or flags.ctrl or flags.alt or flags.fn
      if not hasOtherModifiers then
        logger.d("Right CMD pressed alone - waiting for release")
        rightCmdPressedAlone = true
        otherKeysPressed = false
      end
    end
    
    -- Right CMD released
    if not rightCmdPressed and rightCmdPressedAlone then
      logger.d("Right CMD released")
      if not otherKeysPressed then
        logger.d("Right CMD was pressed alone and released cleanly - sending Enter")
        hs.eventtap.keyStroke({}, "return")
      else
        logger.d("Other keys were pressed during right CMD hold - not sending Enter")
      end
      rightCmdPressedAlone = false
      otherKeysPressed = false
      return true
    end
    
    -- If other modifiers are added while right CMD is held, invalidate
    if rightCmdPressedAlone and rightCmdPressed then
      local hasOtherModifiers = flags.shift or flags.ctrl or flags.alt or flags.fn
      if hasOtherModifiers then
        logger.d("Other modifiers added while right CMD held - invalidating")
        rightCmdPressedAlone = false
        otherKeysPressed = true
      end
    end
  end
  
  return false
end)

function startRightCmdTap()
    if rightCmdTap then
        rightCmdTap:start()
        eventTapRunning = true
        logger.i("RightCmdToEnter event tap started.")
        hs.alert.show('Right CMD to Enter mapping loaded (Debug v3)')
    else
        logger.e("rightCmdTap object is nil. Cannot start.")
        hs.alert.show('ERROR: Right CMD tap nil!')
    end
end

-- Graceful cleanup when Hammerspoon reloads/quits
function stopRightCmdTap()
    if rightCmdTap then
        rightCmdTap:stop()
        eventTapRunning = false
        -- It's generally not recommended to set the tap object to nil here
        -- if you intend to restart it, unless you recreate it with hs.eventtap.new()
        logger.i("RightCmdToEnter event tap stopped.")
    end
end

-- Initial start
startRightCmdTap()

-- If you have a reload function in your init.lua, you might want to include these:
-- local oldReload = hs.reload
-- hs.reload = function()
--   stopRightCmdTap()
--   oldReload() -- This calls the original hs.reload, which will re-run this script.
-- end
