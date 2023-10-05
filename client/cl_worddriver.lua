
local c = {
    ["black"] = color_black,
    ["white"] = color_white
}

local wordDriver = {}

--[[[
    example input

        gcloud:
        {
          ["driver"] = "gcloud",
          ["message"] = {
            ["text"] = "INPUT TTS MESSAGE",
            ["words"] = {"INPUT", "TTS", "MESSAGE"}
          },
          ["timepoints"] = {
                "len": 28,
                "data": {
                    "1": [
                        "Hello",
                        0.014999999664723873
                    ],
                    "2": [
                        "World!",
                        0.39129164814949036
                    ]
                }
            }
        }

        elevenlabs:
        {
          ["length"] = 1
          ["driver"] = "elevenlabs",
          ["message"] = {
            ["text"] = "INPUT TTS MESSAGE"
            }
        }

        manual:
        {
            ["length"] = 5,
            ["text"] = "Hello World!"
        }
--]]

function wordDriver:InjestData(data)
    local driver = data.driver

    self.font = data.font or self.font
    self.color = data.color or self.color
    self.alignment = data.alignment or self.alignment
    self.starttime = SysTime()

    if driver == "gcloud" then
        local word_data = data.timepoints.data
        local wordtbl, timetbl = {}, {}

        for i, dat in ipairs(word_data) do
            wordtbl[i] = dat[1]
            timetbl[i] = dat[2]
        end

        self.text 		= data.message.text
        self.parent.message.message = self.text
        self.wordtbl 	= wordtbl
        self.timetbl 	= timetbl
        self.nexttime = self.starttime + timetbl[1]
        self.active = true
        return
    end

    local duration = data.length * .95
    local text = driver == "elevenlabs" and data.message.text or data.text
    local wordtbl, timetbl = string.Explode("[ ]+", text, true), {}
    local avgdelay = duration / #wordtbl

    for i, word in ipairs(wordtbl) do
        timetbl[i] = avgdelay * i
    end

    self.text = text
    self.parent.message.message = self.text
    self.wordtbl = wordtbl
    self.timetbl = timetbl
    self.nexttime = self.starttime + timetbl[1]
    self.active = true
end

function wordDriver:Think()
    if not self.active then return end

    if self.nexttime <= SysTime() then
        local newtext = table.concat(self.wordtbl, " ", 1, self.wordindex)
        local txt, tall, wide = string.TextWrap(self.font, newtext, self.maxwidth)

        self.drawtext = txt
        self.nexttime = self.starttime + self.timetbl[self.wordindex]
        self.wordindex = self.wordindex + 1

        self.parent.message.size = {tall = tall, wide = wide}
        self.parent:InvalidateLayout()

        if self.wordindex > #self.wordtbl then
            self.active = false
            return
        end
    end
end

function wordDriver:DrawText(x, y)
    draw.DrawText(self.drawtext,self.font,x + 1,y + 1,c["black"],self.alignment) -- lol
    draw.DrawText(self.drawtext,self.font,x,y,self.color,self.alignment)
end

function wordDriver:__tostring()
    return "[wordDriver] " .. tostring(self.parent)
end

wordDriver.__index = wordDriver

local function installWordDriver(pnl)
    pnl.worddriver = setmetatable({
        parent = pnl,

        active = false,
        maxwidth = pnl.maxwidth or 100,
        text = "",
        drawtext = "",
        wordindex = 1,
        nexttime = 0,

        alignment = TEXT_ALIGN_LEFT,
        font = "ChatMessage.Small",
        color = c["white"]
    }, wordDriver)
end

GNIL.GPT.WordDriver = installWordDriver