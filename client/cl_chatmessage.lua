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
    self.alignment = TEXT_ALIGN_LEFT

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

    GNIL.GPT.WordDriver(self)
end

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

function PANEL:SetAlignment(align)
    if alignments[align] then
        self.alignment = alignments[align]
    end
end

function PANEL:SetSpeaker(speaker, color, font)
    if istable(speaker) then
        speaker, color, font = speaker[1], speaker[2], speaker[3]
    end

    if IsEntity(speaker) then
        if IsPlayer(speaker) then
            speaker = speaker:Name()
        else
            speaker = speaker:GetName() or speaker:GetClass()
        end
    end

    speaker = speaker or self.speaker.name
    font = font or self.speaker.font
    surface.SetFont(font)
    local wide, tall = surface.GetTextSize(speaker)
    self.speaker.name = speaker
    self.speaker.color = color or self.speaker.color
    self.speaker.font = font

    self.speaker.size = {
        wide = wide,
        tall = tall
    }
end

function PANEL:SetMessage(data)
    self.worddriver:InjestData(data)
end

function PANEL:Chat(speaktbl, msgdata, alignment)
    msgdata.alignment = alignment -- >:c
    self:SetSpeaker(speaktbl)
    self:SetMessage(msgdata)
    self:SetAlignment(alignment)
    self:PerformLayout()

    return self
end

function PANEL:CalcSize()
    local sw, sh = self.speaker.size.wide, self.speaker.size.tall
    local mw, mh = self.message.size.wide, self.message.size.tall

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

    if self.alignment == TEXT_ALIGN_CENTER then
        w1 = self.speaker.size.wide
        x1 = w * .5 - w1 * .5
        y1 = self.speaker.size.tall - 1
        h1 = width
    elseif self.alignment == TEXT_ALIGN_RIGHT then
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

    if self.alignment == TEXT_ALIGN_CENTER then
        x = w * .5
    elseif self.alignment == TEXT_ALIGN_RIGHT then
        x = w - r or 0
    end

    draw.DrawText(self.speaker.name, self.speaker.font, x + 1, 1, c["black"], self.alignment) -- lol
    draw.DrawText(self.speaker.name, self.speaker.font, x, 0, self.speaker.color, self.alignment)

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