GNIL.GPT.Subtitles.NPCs = GNIL.GPT.Subtitles.NPCs or {}
local etbl = GNIL.GPT.Subtitles.NPCs

local convar = CreateClientConVar( "gpt_showsubtitles", "1", true, false, "Toggles showing subtitles for nearby GPT based NPCs.")
local grad = Material("gui/gradient", "mips smooth")

local meta = {
	tbl = {},
	origin = ScrH() * .95
}

function meta:AddSubtitle(speaker, worddriver, duration)
	assert(IsSpeaker(speaker))

	table.insert(self.tbl, {
		ytar = 0,
		y = 0,
		speaker = speaker,
		driver = worddriver,
		duration = SysTime() + (duration or 1)
	})
end

local max_dist = 500 * 500
local falloff = max_dist * .10
local cply = LocalPlayer()
local disttosqr = FindMetaTable("Entity").DistToSqr

function meta:ShouldDraw()
	if not convar:GetBool() then return false end

	local pos = cply:GetPos()
	for _, npc in ipairs(etbl) do
		local dist = disttosqr(pos, npc:GetPos())
		if dist < max_dist then
			return true, dist
		end
	end

	return false
end

local wce = ScrW() * .5
local mw,mt = ScrW() * .55, 450
function meta:Draw()
	local x, y = wce, self.origin
	local topx, topy = wce - mw * .5, self.origin - mt

	render.SetScissorRect(topx-5, topy, topy + mw + 10, topy + mt + 5, true)
		for i, t in ipairs(self.tbl) do
			t.y = Lerp(0.05, t.y, t.ytar)
			local word = t.driver
			surface.SetFont(t.namefont)
			local namewide, nametall = surface.GetTextSize(t.speaker:GetName())
			local wide, _ = word:GetFullTextSize()
			local _, tall = word:GetTextSize()
			local textx, texty = x - wide * .5, y - t.y

			surface.SetDrawColor(ColorAlpha(t.namecolor,15))
			surface.SetMaterial(grad)
			surface.DrawTexturedRect(textx - 5,texty - 5, math.max(namewide, wide) + 10, tall + nametall + 10)

			surface.SetDrawColor(t.namecolor)
			surface.DrawRect(textx-5, texty-5, 3, tall + nametall + 10)

			draw.SimpleTextOutlined(t.speaker:GetName(), t.speaker:GetFont(), textx, texty, t.speaker:GetColor(),nil,nil, 1, color_black)
			word:DrawText(textx, texty + nametall)
		end
	render.SetScissorRect(0, 0, 0, 0, false)
end

function meta:Think()
	local off = 0

	for i = #self.tbl, 1, -1 do
		local v = self.tbl[i]
		if SysTime() >= v.duration then
			table.remove(self.tbl, i)
			continue
		end

		local word = v.driver
		word:Think()

		local _, wtall = word:GetTextSize()
		surface.SetFont(v.namefont)
		local _, ntall = surface.GetTextSize(v.name)

		v.ytar = off + wtall + ntall
		off = v.ytar + 15
	end
end

function meta.__call(self)
	self:Think()
	local should, dist = self:ShouldDraw()
	if not should then return end
	local alpha = surface.GetAlphaMultiplier()
	-- I don't think an alpha greater than 1 will break anything???
	surface.SetAlphaMultiplier(1 - (dist - (maxdist - falloff)) / falloff)
		self:Draw()
	surface.SetAlphaMultiplier(alpha)
end

meta.__index = meta

GNIL.GPT.Subtitles.Container = function()
	return setmetatable({}, meta)
end

function GNIL.GPT.Subtitles.Add(speaker, worddriver, duration)
	worddriver = IsWordDriver(worddriver) and worddriver
	if not worddriver then
		worddriver = GNIL.GPT.WordDriver(ScrW() * .55, "ChatMessage.Medium")
		worddriver:InjestData(wd)
	end

	GNIL.GPT.Subtitles.Container:AddSubtitle(speaker, worddriver, duration)
end

MODULE:AddHook("HUDPaint", "GPT.Subtitles.HUDPaint", function() GNIL.GPT.Subtitles.Container() end)
MODULE:AddHook("OnEntityCreated", "GPT.Subtitles.Entity.Created", function(ent)
	if not IsValid(ent) or not ent.isgptnpc then
		return
	end
	table.insert(etbl, ent)
end)
MODULE:AddHook("EntityRemoved", "GPT.Subtitles.Entity.Removed", function(ent, _)
	for i = 1, #etbl do
		if etbl[i] == ent then
			table.remove(etbl, i)
			break
		end
	end
end)
MODULE:AddHook("OnScreenSizeChanged", "GPT.Subtitles.ScrenSizeChanged", function()
	GNIL.GPT.Subtitles.Container.origin = ScrH() * .95
end)

local namecolor = Color(36,181,233)
local function EstimateReadingTime(text, wpm)
	local wordCount = istable(text) and text or string.Explode(" ", text)
	return (#wordCount / wpm) * 60
end

Net:Receive("gpt_input_subtitle", function()
	local wdriver = {
		text = net.ReadString(),
		color = namecolor
	}
	wdriver["length"] = EstimateReadingTime(wdriver.text, 200)

	GNIL.GPT.Subtitles.Add(GNIL.GPT.Classes.Speaker(net.ReadString()), wdriver, d.length)
end)