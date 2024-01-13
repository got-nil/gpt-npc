
--[[

    I hate this shit so bad.
    We have a basic WordDriver implementation based on raptors original one.

    TODO:
     - Actually show the word driver in HUDPaint.
     - Support multiple word drivers going at once (move existing up a bit for it).
     - Add start/finish events to the driver.

--]]

local MODULE = MODULE
GNIL.GPT.Subtitles = GNIL.GPT.Subtitles or {}

local wordDrivers, wordDriversLen, padding = {}, 0, 50

// Cache base values.
local scrh, base_x, y = 0, 0, 0
local function setBasePositions()

    scrh = ScrH()
    x, base_y = ScrW() / 2, scrh - (scrh / 10)

end
setBasePositions()

-- Update the bases when the screen size is updated.
MODULE:AddHook("OnScreenSizeChanged", "screenheight_update", function()
    setBasePositions()
end)

MODULE:AddHook("HUDPaint", "paint_subtitles", function()

    // Attempt to draw each word driver and use their returned height.
    local y = base_y
    for i = 1, wordDriversLen do

        local wordDriver = wordDrivers[i]
        if wordDriver == nil then
            continue
        end

        -- TODO: Maybe ease the y when the wordDriversLen has changed.

        wordDriver:Think()
        local success, height = wordDriver:Draw(x, y)
        if not success then
            continue
        end

        -- Just incase.
        if not height then
            MODULE:log("WordDriver returning success without any valid height!", "warning")
            height = wordDriver:GetFontHeight()
        end

        y = y - height - padding

    end

end)

function GNIL.GPT.Subtitles.AddWordDriver(wordDriver, position)
    assert(IsClass(wordDriver, "WordDriver"), "Argument must be a valid WordDriver.")

    table.insert(wordDrivers, position or #wordDrivers + 1, wordDriver)
    wordDriversLen = wordDriversLen + 1
end

function GNIL.GPT.Subtitles.RemoveWordDriver(wordDriver)
    assert(IsClass(wordDriver, "WordDriver"), "Argument must be a valid WordDriver.")

    -- Find the word driver position to remove.
    local position = nil
    for i = 1, wordDriversLen do
        local v = wordDrivers[i]

        if v == wordDriver then
            position = i
            break
        end
    end
    if position == nil then
        return false
    end

    table.remove(wordDrivers, position)
    return true
end