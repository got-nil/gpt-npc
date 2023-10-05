
local mat_arrow = Material("gpt_npc/icons/expand_less.png", "smooth mips")

local SS = ScaleScreen
local ef = function() end
local c = {
    ["arrow"] = Color(238, 238, 238, 131),
}

local PANEL = {}

function PANEL:Init()
    self:SetSize(SS:Scale(1728, 400))
    self.VBar:SetHideButtons(true)

    self.lasthover = CurTime()
    self.ishovered = false

    local input_container = vgui.Create("gpt_input")
    self.input = input_container
    input_container.chat = self
    input_container:SetSize(self:GetSize())

    local sbar = self:GetVBar()
    sbar.Paint = ef
    sbar.btnUp.Paint = ef
    sbar.btnDown.Paint = ef
    sbar.btnGrip.Paint = function(s,w,h)
        surface.SetDrawColor(c["arrow"])
        local wd = math.max(2,w * .25) + (s:IsHovered() and 2 or 0)
        surface.DrawRect(w * .5 - wd * .5, 0,wd,h)
    end
end

function PANEL:AddMsg(...)
    local msg = self:Add("gpt_chatmessage")
    msg:Chat(...)
    self:InvalidateLayout()
    msg:Dock( TOP )
    msg:DockPadding( 25, 0, 25, 0 )
    msg:DockMargin( 0, 0, 0, 4 )
    return msg
end

function PANEL:Delay(dur, f)
    timer.Simple(dur, function()
        if not IsValid(self) then return end
        f(self)
    end)

    return self
end

function PANEL:Think()
    local hovered = self:IsHovered() or self:IsChildHovered()

    if self.ishovered and not hovered then
        self.ishovered = false
        self.lasthover = CurTime() + 1
    elseif not self.ishovered and hovered then
        self.ishovered = true
    end

    if not self.ishovered and self.lasthover <= CurTime() then
        self.VBar:SetScroll(Lerp(.02,self.VBar.Scroll, self:GetCanvas():GetTall()))
    end
end

function PANEL:Paint(w,h)
end

function PANEL:PaintOver(w,h)
    if not self.VBar.Enabled then return end
    surface.SetDrawColor(c["arrow"])
    surface.SetMaterial(mat_arrow)
    local aw,ah = h * .2, h * .2
    local x,y = w * .5, ah * -.25
    DisableClipping(true)

    if self.VBar:GetScroll() > 0 then
        surface.DrawTexturedRectRotated(x, y, aw,ah,0)
    end

    if self.VBar.CanvasSize > 1 and self.VBar:GetScroll() < self.VBar.CanvasSize then
        y = ah * .25 + h
        surface.DrawTexturedRectRotated(x, y, aw,ah,180)
    end

    DisableClipping(false)
end


function PANEL:OnRemove()
    if IsValid(self.input) then self.input:Remove()	end
end

function PANEL:PerformLayout()
    if not IsValid(self.input) then self.input = vgui.Create("gpt_input") end

    self.input:SetZPos(self:GetZPos() + 1)
    local x,y = self:LocalToScreen(0, 0)
    self.input:SetPos(x,y + self:GetTall())
    self.input:SetSize(self:GetWide(), SS:Tall(50))

    self:PerformLayoutInternal()
end

vgui.Register("gpt_msglog", PANEL, "DScrollPanel")