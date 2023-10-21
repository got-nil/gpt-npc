local MODULE = MODULE

print("dfgjjfgdjklf gdkjdg kjsdfghkjhsgdf kjh gfkjhdfsg kjhdskfgjnsrirubnsikdjfbnikldjsnfbikldsjnfg, All my fellas")
function draw.DrawTexturedRectRotatedOutlined(x, y, width, height, color, rotation, outlinewidth, outlinecolour)
	local steps = ( outlinewidth * 2 ) / 3
	if steps < 1 then steps = 1 end

	surface.SetDrawColor(outlinecolour)
	for _x = -outlinewidth, outlinewidth, steps do
		for _y = -outlinewidth, outlinewidth, steps do
			surface.DrawTexturedRectRotated( x + _x, y + _y, width, height, rotation )
		end
	end

	surface.SetDrawColor(color)
	surface.DrawTexturedRectRotated(x,y, width,height,rotation)
end

local function EyeTrace()
	local lp = LocalPlayer()
	local tr = {
		start = lp:EyePos(),
		filter = LocalPlayer(),
		ignoreworld = true,
	}
	tr.endpos = tr.start + lp:EyeAngles():Forward() * 100
	tr = util.TraceLine(tr)

	if IsValid(tr.Entity) and tr.Entity.isgptnpc then
		return tr.Entity
	end
	return false
end

local mat_error = Material("gpt_npc/images/maintenance.png", "smooth mips")
local mat_chat = Material("gpt_npc/images/chat.png", "smooth mips")
local mat_tos = Material("gpt_npc/images/history.png", "smooth mips")
local mat_muted = Material("gpt_npc/images/mic_off.png", "smooth mips")
local mat_recording = Material("gpt_npc/images/mic_on.png", "smooth mips")
local mat_timeout = Material("gpt_npc/images/clock.png", "smooth mips")
local c = {
	["white"] = color_white,
	["black"] = Color(38, 38, 38),
	["error_message"] = Color(247, 79, 79),
	["tos"] = Color(255, 227, 114),
	["recording"] = Color(114, 255, 128),
}

local centerWidth, centerHeight = ScrW() * .5, ScrH() * .5
MODULE:AddHook("OnScreenSizeChanged", "gpt_tos", function()	centerWidth, centerHeight = ScrW() * .5, ScrH() * .5 end)

local function DrawAPIDown()
	local size = 50
	local x,y = centerWidth, centerHeight + size

	surface.SetMaterial(mat_error)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["error_message"], 0, 1, c["black"])
	y = y + size
	local _, th = draw.SimpleTextOutlined("Currently Unavailable", "TargetID", x,y, c["error_message"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
	y = y + th
	draw.SimpleTextOutlined("Undergoing Maintenance", "TargetID", x,y, c["error_message"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

local tos_text = table.concat({"Press ", (input.LookupBinding("+use") or " use"):upper(), " to read the TOS"})

local function DrawTOS()
	local size = 50
	local x, y = centerWidth, centerHeight + size

	surface.SetMaterial(mat_tos)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["tos"], 0, 1, c["black"])
	y = y + size
	local th = 0
	if not GNIL.GPT.TOS.HasSeenTOS() then
		_, th = draw.SimpleTextOutlined("You need to read the TOS before using this NPC", "TargetID", x,y, c["tos"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
	end
	y = y + th
	draw.SimpleTextOutlined(tos_text, "TargetID", x,y, c["tos"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

local function DrawMuted()
	local size = 50
	local x,y = centerWidth, centerHeight + size

	surface.SetMaterial(mat_muted)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["error_message"], 0, 1, c["black"])
	y = y + size
	local _, th = draw.SimpleTextOutlined("You have mic recording", "TargetID", x,y, c["error_message"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
	y = y + th
	draw.SimpleTextOutlined("Disabled", "TargetID", x,y, c["error_message"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

local function DrawRecordTimeout()
	local size = 50
	local x,y = centerWidth, centerHeight + size
	local _, tmr, len = GNIL.GPT.Recording.IsRecording()

	tmr = timer.TimeLeft(tmr)

	surface.SetMaterial(mat_timeout)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["recording"], 0, 1, c["black"])

	local w,h = size * 2.5, size * .15
	surface.SetDrawColor(c["white"])
	surface.DrawOutlinedRect(x - w * .5, y + size * .5 + h * .5,w,h,1)
	surface.SetDrawColor(c["recording"])
	surface.DrawRect(x - w * .5, y + size * .5 + h * .5,w * tmr / len,h)

	y = y + size
	local _, th = draw.SimpleTextOutlined("Timeleft", "TargetID", x,y, c["recording"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
	y = y + th
	draw.SimpleTextOutlined( (tmr > len * .25 and math.floor(math.max(0,tmr)) or math.Round(tmr,1)) .. " second" .. (tmr == 1 and "" or "s"), "TargetID", x,y, c["recording"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

local record_start = "Press " .. (input.LookupBinding("+use") or " use"):upper() .. " to record a prompt"
local function DrawStartRecording()
	local size, x, y = 50, centerWidth, centerHeight + 50

	surface.SetFont("TargetID")
	surface.SetMaterial(mat_recording)
	local total_height = size * 2 + select(2, surface.GetTextSize(record_start))

	local my = GNIL.GPT.Interaction.GetCurrent():GetY()
	y = math.min(y, my - total_height)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["white"], 0, 1, c["black"])
	y = y + size
	draw.SimpleTextOutlined(record_start, "TargetID", x,y, c["white"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

local function DrawStartChat(ent)
	local size = 50
	local x,y = centerWidth, centerHeight + size
	local text, entname = "", ent.GetDisplayName and ent:GetDisplayName() or ""

	if entname == "" then
		text = table.concat({"Press ", (input.LookupBinding("+use") or " use"):upper(), " to begin interaction"})
	else
		text = table.concat({"Press ", (input.LookupBinding("+use") or " use"):upper(), " to begin talking to ", entname})
	end

	surface.SetMaterial(mat_chat)
	draw.DrawTexturedRectRotatedOutlined(x, y, size, size, c["white"], 0, 1, c["black"])
	y = y + size
	draw.SimpleTextOutlined(text, "TargetID", x,y, c["white"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, c["black"])
end

hook.Add("HUDPaint", "cl_hud.lua",function()
	if GNIL.GPT.Recording.IsRecording() then
		DrawRecordTimeout()
		return
	end

	local ent = EyeTrace()
	if not ent then return end

	if isapidown then
		DrawAPIDown(ent)
		return
	end

	if not GNIL.GPT.TOS.HasAccepted() then
		DrawTOS()
		return
	end

	if GNIL.GPT.Recording.IsRecording() then
		DrawRecordTimeout()
		return
	end

	if IsValid(GNIL.GPT.Interaction.GetCurrent()) then
		if GNIL.GPT.Mute.IsGPTMuted() then
			DrawMuted()
		else
			DrawStartRecording()
		end

		return
	end

	DrawStartChat(ent)
end)