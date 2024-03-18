
---@class GPT.WordDriver: middleclass
---@field _id string
---@field protected _active boolean
---@field protected _index number
---@field protected _max_width number
---@field protected _font_name string
---@field protected _font_height number
---@field protected _words string[]
local WordDriver = GNIL.Thirdparty.middleclass("WordDriver")
ClassAccessorFunc(WordDriver, {
    ID = FuncAccessors.ReadOnly("_id"), ---@accessor string readonly
    FontHeight = FuncAccessors.ReadOnly("_font_height"), ---@accessor number readonly
    MaxWidth = {"_max_width", FORCE_NUMBER}, ---@accessor number
    FontName = { ---@accessor string
        var = "_font_name",
        force = FORCE_STRING,
        set = function(self, value)

            if not isstring(value) then
                return false
            end

            -- Cache the font height as we set it.
            surface.SetFont(value)
            local _, height = surface.GetTextSize("A")
            self._font_height = height
            self._font_name = value

            return true
        end
    },
})

function WordDriver:Initialize(font_name, max_width)
    self._id = GNIL.Utils.Random(6)
    self._active = false
    self._index = 1

    self._max_width = max_width or ScrW() / 1.5
    self:SetFontName(font_name or "ChatMessage.Small")
    self._font_height = 0

    self._words = {}
    self._times = {}
    self._word_count = 0
    self._max_lines = 4

    self._real_times = {}
    self._next_time = 0
    self._driver_added = false
    self._draw_lines = false
end

function WordDriver:Ingest(text, timepoints, length)

    -- Use timepoints if provided, otherwise use average word length.
    local words, times = string.Explode("[ ]+", text, true), {}
    if timepoints then
        times = timepoints
    else
        local duration = length * 0.95
        local avgdelay = duration / #words

        -- Elevenlabs does not tell us when the words are said, so use average.
        for i = 1, #words do
            times[i] = avgdelay * i
        end
    end

    self._words = words
    self._times = times
    self._word_count = #words
    return self
end

-- Called in HUDPaint before Draw.
local sysTime, textWrap, tableConcat, stringExplode = SysTime, string.TextWrap, table.concat, string.Explode
function WordDriver:Think()
    local next_time = self._next_time or 0
    if not self._active then return end

    local systime = sysTime()
    if next_time < systime then

        -- Get the current wrapped text (in entirety).
        local index, word_count = self._index, self._word_count
        local wrappedText = textWrap(
            self._font_name,
            tableConcat(self._words, " ", 1, index),
            self._max_width
        )

        -- Seperate the text into a table of new lines.
        local all_lines = stringExplode("\n", wrappedText)
        local line_count, max_lines = #all_lines, self._max_lines

        -- Clamp the amount of lines to max_lines.
        local lines, start = {}, line_count - max_lines > 0 && line_count - max_lines || 1
        for i = start, line_count, 1 do
            lines[i - start + 1] = all_lines[i]
        end
        self._draw_lines = lines

        -- Prevent overflows.
        if index >= word_count then
            self:Stop()
            return
        end

        -- Update the index and next runtime.
        self._index = index + 1
        self._next_time = self._real_times[index + 1] or 0
    end
end

function WordDriver:Start(globally_add)

    -- Since we're starting, add the SysTime to the start of all word
    -- times which will actually be used when scrolling the text.
    local out, systime = {}, SysTime()
    for i = 1, #self._times do
        out[i] = systime + self._times[i]
    end

    self._real_times = out
    self._active = true
    self._index = 0

    -- Add the driver to the UI if the argument is set.
    if globally_add and not self._driver_added then
        GNIL.GPT.Subtitles.AddWordDriver(self)
        self._driver_added = true
    end
end

function WordDriver:Stop(force, driver_remove_delay)
    self._index = self._word_count

    -- If the word driver has been added globally, remove it.
    if self._driver_added then
        self._driver_added = false

        -- Don't actually remove the driver immidiately since that looks ugly.
        -- Do a short delay first, and then remove it afterwards.
        local self = self
        timer.Simple(force and 0 or (driver_remove_delay or 3), function()
            if self then
                GNIL.GPT.Subtitles.RemoveWordDriver(self)
                self._active = false
            end
        end)

    else
        self._active = false
    end
end

-- Return draw status and total height.
local white, black, background = color_white, color_black, Color(20, 20, 20, 180)
local line_padding = 25
function WordDriver:Draw(x, y)
    if not self._active and self._index < self._word_count then
        return false, nil
    end

    local font_height, total_height, lines = self._font_height, 0, self._draw_lines
    local lines_len = #lines

    -- Start the first line at the heighest position and work down to minimum.
    y = y - ((font_height + line_padding) * lines_len)
    local start_y = y

    local padding = (ScrH() / 10) / 4
    local total_height = (font_height + line_padding) * lines_len

    -- Draw the subtitles background.
    local scrw = ScrW()
    local w = scrw / 8
    draw.RoundedBox(0, w, start_y - padding, scrw - (w * 2), total_height + (padding * 2), background)

    -- Draw lines.
    for i = 1, lines_len do
        draw.SimpleTextOutlined(lines[i], self._font_name, x, y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT, 3, black)
        y = y + font_height + line_padding
    end

    return true, total_height
end

return {
    WordDriver = WordDriver
}