local c = {
	["white"] = color_white,
	["mic_recording"] = Color(83, 237, 44),
	["mic_muted"] = Color(237, 44, 44),
	["mic_tos"] = Color(114, 0, 0),
	["mic_hover"] = Color(177, 177, 177),
	["text_placeholder"] = Color(238, 238, 238, 238),
}

local mat_arrow = Material("gpt_npc/icons/expand_less.png", "smooth mips")
local mat_mic_on = Material("gpt_npc/images/mic_on.png", "smooth mips")
local mat_mic_off = Material("gpt_npc/images/mic_off.png", "smooth mips")

local PANEL = {}

function PANEL:Init()
	self.enter_allowed = true
	self.input_history = {}
	self:DockPadding(2,2,2,2)
	local record_button = self:Add("DButton")
	self.record_button = record_button
	record_button.recording = false
	record_button:SetText("")
	record_button:Dock(RIGHT)

	local vl = {}
	-- fucked shit, but needed otherwise the line starts off fucky
	for i = 1, 50 do
		vl[i] = 0
	end

	local nT = SysTime()
	record_button.Think = function(s)
		if nT < SysTime() then
			nT = SysTime() + .05
			table.insert(vl, LocalPlayer():IsSpeaking() and LocalPlayer():VoiceVolume() * 1.5 or 0)
			if #vl > 50 then
				table.remove(vl, 1)
			end
		end
	end

	record_button.clickcooldown = CurTime()
	record_button.DoClick = function()
		if record_button.clickcooldown > CurTime() then	return end record_button.clickcooldown = CurTime() + 1

		if not GNIL.GPT.TOS.HasAccepted() then
			GNIL.GPT.TOS.OpenTOS()
			self:Remove()
			return
		end

		GNIL.GPT.MUTE.ToggleGPTMuted()
	end

	record_button.Paint = function(s,w,h)
		local color, mictext, material = c["white"], "Voice Idle", mat_mic_on

		if s:IsHovered() then
			color = c["mic_hover"]
		end

		if s.recording then
			mictext = "Voice Recording"
			color = c["mic_recording"]
		end

		if GNIL.GPT.MUTE.IsGPTMuted() then
			mictext = "Voice Muted"
			color = c["mic_muted"]
			material = mat_mic_off
		end

		if not GNIL.GPT.TOS.HasAccepted() then
			mictext = "Mic Muted (TOS)"
			color = c["mic_tos"]
			material = mat_mic_off
		end

		s.mictext = mictext
		surface.SetDrawColor(color)

		if s.recording then
			-- some more fucked shit
			local lastx,lasty = 0,0
			local ws = w / 50
			for i = 1, 50 do
				local vs = vl[i] or 0
				local x, y = ws * i, math.min(h-1,h - (h * vs))
				if not lastx or i == 1 then
					lastx, lasty = x,y
					continue
				end
				surface.DrawLine(
					lastx, lasty,
					x, y
				)
				lastx, lasty = x,y
			end
		else
			surface.DrawLine(0,h-1,w,h-1)
		end

		surface.SetMaterial(material)
		local size = h
		surface.DrawTexturedRectRotated(w - size * .5, h * .5, size,size,0)
		draw.SimpleText(s.mictext, "ChatMessage.Medium",4, h * .5, color, nil, TEXT_ALIGN_CENTER)
	end

	local entry = self:Add("DButton")
	self.entry = entry
	entry:Dock(LEFT)
	entry:SetText("")
	entry.DoClick = function()
		if entry.isTextInput or self.record_button.recording then return end
		entry.isTextInput = true
		self:TextInput()
	end

	local last = false
	entry.Think = function(s)
		-- don't pull focus when not needed
		if not s:IsVisible() or s.isTextInput or gui.IsConsoleVisible() then return end

		if input.IsKeyDown(KEY_ESCAPE) then
			GNIL.GPT.Interaction.Close()
		end

		if not last and input.IsKeyDown(KEY_ENTER) then
			last = true
			-- prevents pulling focus from other text entries
			if vgui.GetKeyboardFocus() == nil then
				s:DoClick()
			end
		elseif last and not input.IsKeyDown(KEY_ENTER) then
			last = false
		end
	end

	entry.Paint = function(s,w,h)
		if s.isTextInput then return end
		local text, color = "Press Enter to start typing", c["white"]

		if s:IsHovered() then
			color = c["mic_hover"]
		end

		if self.record_button.recording then
			text = "Voice Recording"
			color = c["mic_recording"]
		end

		local size = h
		surface.SetDrawColor(color)
		surface.SetMaterial(mat_arrow)

		DisableClipping(true)
			surface.DrawTexturedRectRotated(size * -.25, h * .5,size,size,-90)
		DisableClipping(false)

		surface.DrawRect(0, h - 2,w,2)
		draw.SimpleText( text, "ChatMessage.Small", 3, h * .5, color,nil,TEXT_ALIGN_CENTER)
	end
end

function PANEL:SetEnterAllowed(bool)
	self.enter_allowed = bool
	if IsValid(self.inpt) then
		self.inpt:SetEnterAllowed(bool)
	end
end

function PANEL:GetEnterAllowed()
	return self.enter_allowed
end

local maxdist = 200 * 200
function PANEL:TextInput()
	local inpt = vgui.Create("DTextEntry")
	self.inpt = inpt
	inpt:SetEnterAllowed(self.enter_allowed)
	inpt:DockPadding(0,0,0,0)
	inpt:SetFont("ChatMessage.Small")
	inpt:SetPlaceholderText("Type a prompt")
	inpt:SetTextColor(c["white"])
	inpt:SetPlaceholderColor(c["text_placeholder"])
	inpt:SetPaintBackground(false)
	inpt:MakePopup()
	inpt:SetUpdateOnType(true)
	inpt.OnValueChange = function(s,v)
		s:InvalidateLayout()
	end
	for _, txt in ipairs(self.input_history) do
		inpt:AddHistory(txt)
	end

	local op = inpt.Paint
	inpt.Paint = function(s,w,h)
		op(s,w,h)
		local color, size, text = c["white"], h, s:GetText()
		text = text ~= "" and text or "Type a prompt"

		surface.SetDrawColor(color)
		surface.SetMaterial(mat_arrow)

		DisableClipping(true)
			surface.DrawTexturedRectRotated(h * -.25, h * .5,size,size,-90)
		DisableClipping(false)

		surface.SetFont("ChatMessage.Small")
		local tw,_ = surface.GetTextSize(text)
		surface.DrawRect(0, h - 2,tw + 5,2)
	end

	inpt.OnEnter = function(s)
		local val, ent = s:GetValue(), self.parent.parent.Entity

		table.insert(self.input_history, val)

		if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) <= maxdist and ent:GetCurrentState() == ent.STATE["Idle"] then
			GNIL.GPT.Input.SendPrompt(val)
		end

		s:DoClose()
	end

	inpt.OnKeyCode = function(s,key)
		if key == KEY_ESCAPE then
			s:DoClose()
		end
	end

	inpt.DoClose = function(s)
		self.entry.isTextInput = false
		s:Remove()
	end

	inpt.PerformLayout = function(s,w,h)
		local text = s:GetText()
		text = text ~= "" and text or "Type a prompt"
		surface.SetFont("ChatMessage.Small")
		local tw, _ = surface.GetTextSize(text)
		local wide = math.Clamp(tw + 5, 10, self:GetWide() - self.record_button:GetWide() - 5)
		s:SetWide(wide)
	end
end

function PANEL:OnRemove()
	if IsValid(self.inpt) then
		self.inpt:Remove()
	end
end

function PANEL:Think()
	local inpt = self.inpt
	if IsValid(inpt) then
		inpt:SetPos(self.entry:LocalToScreen(0,0))
		inpt:SetTall(self.entry:GetTall())
	end
end

function PANEL:Paint(w,h) end


function PANEL:PerformLayout(w,h)
	surface.SetFont("ChatMessage.Medium")
	local tw,_ = surface.GetTextSize(s.mictext)
	self.record_button:SetWide(tw + h)

	surface.SetFont("ChatMessage.Small")
	tw,_ = surface.GetTextSize("Press Enter to start typing")
	self.entry:SetWide(tw + 5)
end

vgui.Register("gpt_input", PANEL, "EditablePanel")