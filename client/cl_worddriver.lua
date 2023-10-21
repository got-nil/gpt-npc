local alignments = {
	["left"] = TEXT_ALIGN_LEFT,
	["center"] = TEXT_ALIGN_CENTER,
	["right"] = TEXT_ALIGN_RIGHT,
	[TEXT_ALIGN_LEFT] = TEXT_ALIGN_LEFT,
	[TEXT_ALIGN_CENTER] = TEXT_ALIGN_CENTER,
	[TEXT_ALIGN_RIGHT] = TEXT_ALIGN_RIGHT,
	["LEFT"] = TEXT_ALIGN_LEFT,
	["CENTER"] = TEXT_ALIGN_CENTER,
	["RIGHT"] = TEXT_ALIGN_RIGHT,
	["<"] = TEXT_ALIGN_LEFT,
	["|"] = TEXT_ALIGN_CENTER,
	[">"] = TEXT_ALIGN_RIGHT,
}

local c = {
	["black"] = color_black,
	["white"] = color_white
}

local WordDriver = GNIL.Thirdparty.middleclass("WordDriver"):IncludeMixin(GNIL.ClassMixins.Events)
ClassAccessorFunc(WordDriver, {
	Active  = {"active", FORCE_BOOL},
	Text  = {"text", FORCE_STRING},
	Alignment = {var = "alignment", force = FORCE_NUMBER, set = function(self, align)
		if alignments[align] then
			self.alignment = alignments[align]
		end
	end},
	FullTextWide = FuncAccessors.ReadOnly("fulltextwide"),
	FullTextTall = FuncAccessors.ReadOnly("fulltexttall"),
	Color = {"color", FORCE_COLOR},
	Font = {var = "font", force = FORCE_STRING, set = function(self, font)
		self.font = font or "ChatMessage.Small"
		local _, th, tw = string.TextWrap(self.font, self.text, self.maxwidth)
		self.fulltextwide, self.fulltexttall = tw, th
	end},
	MaxWidth = {var = "maxwidth", force = FORCE_NUMBER, set = function(self, n)
		self.maxwidth = n
		local _, tw, th = string.TextWrap(self.font, self.text, self.maxwidth)
		self.fulltextwide, self.fulltexttall = tw, th
	end}
})

function WordDriver:Initialize(maxwidth, font, color, alignment)
	self.maxwidth = maxwidth or 100
	self.alignment = alignments[alignment] or TEXT_ALIGN_LEFT
	self.font = font or "ChatMessage.Small"
	self.color = color or c["white"]

	self.active = false
	self.worddriver = true
	self.text = ""
	self.drawtext = ""
	self.wordindex = 1
	self.nexttime = 0
end

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

function WordDriver:InjestData( data )
	local driver = data.driver

	self.font = data.font or self.font
	self.color = data.color or self.color
	self.alignment = data.alignment or self.alignment
	self.starttime = SysTime()

	surface.SetFont(self.font)

	if driver == "gcloud" then
		local word_data = data.timepoints.data
		local wordtbl, timetbl = {}, {}

		for i, dat in ipairs(word_data) do
			wordtbl[i] = dat[1]
			timetbl[i] = dat[2]
		end

		self.text 		= data.message.text
		self.wordtbl 	= wordtbl
		self.timetbl 	= timetbl
		self.nexttime = self.starttime + timetbl[1]
		local _, th, tw = string.TextWrap(self.font, self.text, self.maxwidth)
		self.fulltextwide, self.fulltexttall = tw, th

		return self
	end

	local duration = data.length * .95
	local text = driver == "elevenlabs" and data.message.text or data.text
	local wordtbl, timetbl = string.Explode("[ ]+", text, true), {}
	local avgdelay = duration / #wordtbl

	for i, word in ipairs(wordtbl) do
		timetbl[i] = avgdelay * i
	end

	self.text = text
	self.wordtbl = wordtbl
	self.timetbl = timetbl
	self.nexttime = self.starttime + timetbl[1]
	self.fulltextwide, self.fulltexttall = surface.GetTextSize(self.text)

	return self
end

function WordDriver:Think()
	if not self.active then return end

	if self.nexttime <= SysTime() then
		local newtext = table.concat(self.wordtbl, " ", 1, self.wordindex)
		local txt, tall, wide = string.TextWrap(self.font, newtext, self.maxwidth)

		self.drawtext = txt
		self.textwide, self.texttall = tall, wide
		self.nexttime = self.starttime + self.timetbl[self.wordindex]
		self.wordindex = self.wordindex + 1

		self:EmitSignal("updatelayout")

		if self.wordindex > #self.wordtbl then
			self.active = false
			self:OnFinished()
			return
		end
	end
end

function WordDriver:Start()
	self.active = true
end

function WordDriver:Stop(force)
	if force then
		self.wordindex = #self.wordtbl
	end
	self.active = false
end

function WordDriver:Reset(start)
	self.active = tobool(start)
	self.starttime = SysTime()
	self.nexttime = self.starttime + self.timetbl[1]
	self.wordindex = 1
	self.drawtext = ""
end

function WordDriver:GetTextSize()
	return self.fulltextwide or 0, self.fulltexttall or 0
end

function WordDriver:DrawText(x, y)
	if not self.active and self.wordindex < #self.wordtbl then return end
	draw.DrawTextShadow(self.drawtext,self.font,x,y,self.color,self.alignment)
end

function WordDriver:OnFinished() end

function WordDriver:__tostring()
	return "[WordDriver]" .. self.parent and tostring(self.parent) or "Standalone"
end

function IsWordDriver(obj)
	return IsInstanceOf(obj, WordDriver)
end

GNIL.GPT.WordDriver = WordDriver