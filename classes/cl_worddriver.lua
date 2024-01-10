local WordDriver = GNIL.Thirdparty.middleclass("WordDriver")

function WordDriver:Initialize()
    self._active = false
    self._index = 0
    self._max_width = 100

    self._words = {}
    self._times = {}
    self._word_count = 0

    self._start_time = 0
    self._real_times = {}
    self._next_time = 0
    self._draw_text = false
end

function WordDriver:Ingest(text, timepoints)

    -- Use timepoints if provided, otherwise use average word length.
    local words, times = string.Explode("[ ]+", text, true), {}
    if timepoints then
        times = timepoints
    else
        local duration = data.length * 0.95
        local avgdelay = duration / #words

        -- Elevenlabs does not tell us when the words are said, so use average.
        for i = 1, #words do
            times[i] = avgdelay * i
        end
    end

    self._font_name = "ChatMessage.Small"
    self._words = words
    self._times = times
    self._word_count = #words
    return self
end

function WordDriver:Think()
    if not self._active then return end

    local systime = SysTime()
    if self._next_time <= systime then

        local index = self._index

        self._draw_text = string.TextWrap(
            self._font_name,
            table.concat(self._words, " ", 1, index),
            self._max_width
        )
        self._next_time = self._start_time + self._times[index]

        index = index + 1
        if index > self._word_count then
            self._active = false
            print("FINISHED")
            return
        end
        self._index = index

    end
end

function WordDriver:Start()

    -- Since we're starting, add the SysTime to the start of all word
    -- times which will actually be used when scrolling the text.
    local out, systime = {}, SysTime()
    for i, v in ipairs(self._times) do
        out[i] = systime + self._times[i]
    end

    self._start_time = RealTime()
    self._real_times = out
    self._active = false
    self._index = 1
end

function WordDriver:Stop(force)
    if force then
        self._index = self._word_count
    end
    self._real_times = false
    self._active = false
end

function WordDriver:Draw(x, y)
    if not self._active and self._index < self._word_count then return end
    draw.SimpleTextOutlined(self._draw_text, self._font_name, x, y, color_white, TEXT_ALIGN_CENTER)
end

return {
    WordDriver = WordDriver
}