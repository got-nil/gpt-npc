local MODULE = MODULE

local IconOffset, AlphaOffset = Vector(0, 0, 18), Vector(0, 0, 64)
local IconWidth, IconHeight, IconSize = 512, 512, 912

-- Get the materials from shared paths.
local IconMaterials = {}
for k, v in pairs(ENT.IconMaterialPaths) do
    local mat = Material(v)
    if mat:IsError() then
        MODULE:log("Failed to load Icon material '" .. k .. "'.", "error")
    end
    IconMaterials[k] = mat
end

-- Animate the speaker icon by lerping between 3 different images.
local speakerAnimStart = SysTime()
local function animateSpeakerIcon()

    local sysTime = SysTime()
    local v = sysTime - speakerAnimStart
    if v > 3 then
        speakerAnimStart = sysTime
    end
    return "speaker-" .. (math.floor(v) + 1)
end

local CenterWidth, CenterHeight = ScrW() * .5, ScrH() * .5
local Config = ENT.Config
local MinDist, MaxDist = 100 * 100, 300 * 300

-- This is called for every frame, so keep it optimised.
function ENT:DrawTranslucent()

    self:DrawModel()

    -- Make sure player isn't too far away.
    local ply, entPos = LocalPlayer(), self:GetPos()
    local distance = entPos:DistToSqr(ply:GetPos())
    if distance > MaxDist then
        return
    end

    -- Only actually draw stuff if we have a state handler.
    local stateHandler = self:GetStateHandler()
    if not stateHandler then
        return
    end

    -- Copied from Virtualraptor, fade the surface away as distance increases.
    local eyesPos = ply:EyePos()
    local entVector = (entPos + AlphaOffset) - eyesPos
    local angCos = ply:GetAimVector():Dot(entVector) / entVector:Length()
    local dotAlpha = math.Clamp(math.ease.InQuad(angCos + .2), 0, 1)
    distance = distance - MinDist
    local alpha = 1 - math.max(.04, distance / MaxDist)
    if dotAlpha < alpha then alpha = dotAlpha end
    if alpha < 0.2 then return end

    -- Get the icon name, and also support icon animations.
    local iconName = stateHandler.Icon
    if iconName == "speaker" then iconName = animateSpeakerIcon() end
    local iconMaterial = iconName and IconMaterials[iconName]
    local showNameplate = stateHandler.showNameplate or true
    local paintFn = stateHandler.Paint

    if iconMaterial or showNameplate or paintFn then

        -- TODO: Look into optimising the attachment, cache after first time.
        local eyesAngle = ply:EyeAngles()
        local head = self:GetAttachment(
            self:LookupAttachment("anim_attachment_head") or 0
        )

        -- If there is a valid head, use that as the base position
        -- otherwise get it offset from the bounding box center.
        -- I was told this was the best way to handle wacky models.
        local base
        if head != nil and head.Pos then
            base = head
        else
            base = self:LocalToWorld(self:OBBCenter()) + self:GetUp() * 30
        end
        local pos = base + eyesAngle:Up()

        -- Turn to face player.
        eyesAngle:RotateAroundAxis(eyesAngle:Forward(), 90)
        eyesAngle:RotateAroundAxis(eyesAngle:Right(), 90)

        surface.SetAlphaMultiplier(alpha)
        cam.Start3D2D(pos, Angle(0, eyesAngle.y, 90), 0.01)

            if iconMaterial then
                surface.SetMaterial(iconMaterial)
                surface.SetDrawColor(unpack(stateHandler.IconDrawColor or {0, 0, 0, 255}))
                surface.DrawTexturedRect(-IconSize / 2, -IconSize * 1.8, IconSize, IconSize)
            end

            if showNameplate then

                --[[

                    TODO: for prof.

                --]]

            end

            -- Reset the surface alpha before any custom paint func.
            surface.SetAlphaMultiplier(1)
            if paintFn then
                paintFn(self)
            end

        cam.End3D2D()

    end
end
