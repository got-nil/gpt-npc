local c = {
    ["white"] = color_white,
    ["mic_recording"] = Color(237, 44, 44),
    ["mic_hover"] = Color(177, 177, 177),
    ["text_placeholder"] = Color(238, 238, 238, 238),
}

local mat_arrow = Material("gpt_npc/icons/expand_less.png", "smooth mips")
local mat_mic_on = Material("gpt_npc/images/mic_on.png", "smooth mips")
local mat_mic_off = Material("gpt_npc/images/mic_off.png", "smooth mips")

--[[
    things that need intergration
        when the recording starts set .recording to true
        when textentry enter do stuff
]]

local PANEL = {}

function PANEL:Init()
    self:DockPadding(2,2,2,2)
    local record_button = self:Add("DPanel")
    self.record_button = record_button
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

    record_button.Paint = function(s,w,h)
        local color = s.recording and c["mic_recording"] or c["white"]
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

        surface.SetMaterial(s.recording and mat_mic_on or mat_mic_off)
        local size = h
        surface.DrawTexturedRectRotated(w - size * .5, h * .5, size,size,0)
        draw.SimpleText(s.recording and "Voice Recording" or "Voice Idle", "ChatMessage.Medium",4, h * .5, color, nil, TEXT_ALIGN_CENTER)
    end

    local entry = self:Add("DButton")
    self.entry = entry
    entry:Dock(LEFT)
    entry:SetText("")
    entry.DoClick = function()
        if entry.isTextInput then return end
        entry.isTextInput = true
        self:TextInput()
    end

    local last = false
    entry.Think = function(s)
        -- don't pull focus when not needed
        if not s:IsVisible() or s.isTextInput or gui.IsConsoleVisible() then return end

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
        local color = s:IsHovered() and c["mic_hover"] or c["white"]
        local size = h
        surface.SetDrawColor(color)
        surface.SetMaterial(mat_arrow)
        DisableClipping(true)
        surface.DrawTexturedRectRotated(size * -.25, h * .5,size,size,-90)
        DisableClipping(false)

        surface.DrawRect(0, h - 2,w,2)
        draw.SimpleText("Press Enter to start typing", "ChatMessage.Small", 3, h * .5, color,nil,TEXT_ALIGN_CENTER)
    end

end

function PANEL:TextInput()
    local inpt = vgui.Create("DTextEntry")
    self.inpt = inpt
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
    local op = inpt.Paint
    inpt.Paint = function(s,w,h)
        op(s,w,h)
        local color = c["white"]
        local size = h
        local text = s:GetText()
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
    inpt.OnEnter = function(s,val)
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
        local tw,_ = surface.GetTextSize(text)
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
    local tw,_ = surface.GetTextSize(self.record_button.recording and "Voice Recording" or "Voice Idle")
    self.record_button:SetWide(tw + h)

    surface.SetFont("ChatMessage.Small")
    tw,_ = surface.GetTextSize("Press Enter to start typing")
    self.entry:SetWide(tw + 5)
end

vgui.Register("gpt_input", PANEL, "EditablePanel")