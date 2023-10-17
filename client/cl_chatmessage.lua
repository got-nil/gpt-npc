local mat_history = Material("gpt_npc/images/history.png", "smooth mips")

local c = {
	["black"] = color_black,
	["history_included"] = Color(112, 255, 131),
}

local PANEL = {}

function PANEL:Init()
	self:SetText("")
	self:SetCursor("arrow")
	self.maxwidth = (ScrW() * .45) * .50
	self.speaker = {
		name = "Unknown",
		color = Color(64, 198, 255),
		font = "ChatMessage.Medium",
		size = {
			wide = 0,
			tall = 0
		}
	}
	self.message = {
		message = "Hello World!",
		color = Color(253, 245, 233),
		font = "ChatMessage.Small",
		size = {
			wide = 0,
			tall = 0
		}
	}
end

function PANEL:SetMessage(speakerobj, msgdata)
	self.speaker = speakerobj
	self.worddriver = msgdata
	self.worddriver:AddSignalListener("updatelayout", function()
		self:InvalidateLayout()
	end)
	self:PerformLayout()

	return self
end

function PANEL:StartTypeWriter()
	if not self.worddriver then return end
	self.worddriver:StartTypeWriter()
end

function PANEL:TypeWriteFinishCallback(func)
	if not self.worddriver then return end
	self.worddriver.OnFinished = func
end

function PANEL:CalcSize()
	if not self.worddriver then return 0, 0 end
	local size =  self.speaker:GetSize()
	local sw, sh = size.wide, size.tall
	local mw, mh = self.worddriver:GetTextSize()
	-- local mw, mh = self.message.size.wide, self.message.size.tall

	return math.max(sw, mw), sh + mh + 5
end

function PANEL:DoRightClick()
	local rmenu = DermaMenu()
	rmenu.parent = self

	rmenu.Think = function(slf)
		if not IsValid(slf.parent) then
			slf:Remove()
		end
	end

	rmenu:AddOption("Copy Name", function()
		SetClipboardText(self.speaker.name)
	end):SetIcon("icon16/group.png")

	rmenu:AddOption("Copy Message", function()
		SetClipboardText(self.message.message)
	end):SetIcon("icon16/comment.png")

	rmenu:Open()
end

function PANEL:PaintBackground(w, h)
	local width = self:IsHovered() and 4 or 2
	local l = 5
	local w1, h1 = width, h
	local x1, y1 = l, 0

	local align = self.worddriver and self.worddriver:GetAlignment()

	if align == TEXT_ALIGN_CENTER then
		w1 = self.speaker.size.wide
		x1 = w * .5 - w1 * .5
		y1 = self.speaker.size.tall - 1
		h1 = width
	elseif align == TEXT_ALIGN_RIGHT then
		x1 = w - w1
		h1 = h
	end

	surface.SetDrawColor(self.speaker.color)
	surface.DrawRect(x1, y1, w1, h1)
end

function PANEL:Think()
	self.worddriver:Think()
end

function PANEL:Paint(w, h)
	if self:GetPaintBackground() then
		self:PaintBackground(w, h)
	end

	local l, r = 10, 10
	local x = l or 0

	local align = self.worddriver and self.worddriver:GetAlignment()

	if align == TEXT_ALIGN_CENTER then
		x = w * .5
	elseif align == TEXT_ALIGN_RIGHT then
		x = w - r or 0
	end

	draw.DrawText(self.speaker.name, self.speaker.font, x + 1, 1, c["black"], align) -- lol
	draw.DrawText(self.speaker.name, self.speaker.font, x, 0, self.speaker.color, align)

	if self.history_included then
		local speakerw, speakerh = surface.GetTextSize(self.speaker.name)
		surface.SetMaterial(mat_history)
		local size = 25
		surface.SetDrawColor(c["history_included"])
		surface.DrawTexturedRectRotated(x + speakerw + size * .6, speakerh * .5, size, size, 0)
	end

	if self.worddriver then
		self.worddriver:DrawText(x, self.speaker.size.tall)
	end
end

function PANEL:PerformLayout(w, h)
	local _, t = self:CalcSize()
	self:SetTall(t)
end

vgui.Register("gpt_chatmessage", PANEL, "DButton")