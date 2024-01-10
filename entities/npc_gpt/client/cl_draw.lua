local MODULE = MODULE

local IconOffset, IconWidth, IconHeight = Vector(0, 0, 18), 512, 512
local IconSize = 312

-- Get the materials from shared paths.
local IconMaterials = {}
for k, v in pairs(ENT.IconMaterialPaths) do
    local mat = Material(v)
    if mat:IsError() then
        MODULE:log("Failed to load Icon material '" .. k .. "'.", "error")
    end
    IconMaterials[k] = mat
end

-- This is called for every frame, so keep it optimised.
local CenterWidth, CenterHeight = ScrW() * .5, ScrH() * .5
function ENT:Draw()

    self:DrawModel()

    -- Only actually draw stuff if we have a state handler.
    local stateHandler = self:GetStateHandler()
    if not stateHandler then
        return
    end

    -- If the state has its own Draw function, call it.
    local drawFn = stateHandler.Draw
    if drawFn then drawFn(self) end

    -- If there is actually a state icon, show it.
    local iconName = stateHandler.Icon
    local iconMaterial = iconName and IconMaterials[iconName]
    if iconMaterial then

        local eyes = LocalPlayer():EyeAngles()
        local head = self:GetAttachment(
            self:LookupAttachment("anim_attachment_head") or 0
        )

        -- If there is a valid head, use that as the base position
        -- otherwise get it offset from the bounding box center.
        -- I was told this was the best way to handle wacky models.
        local base = Either(head and head.Pos, head.Pos, (
            self:LocalToWorld(self:OBBCenter()) + self:GetUp() * 24
        ))
        local pos = base + IconOffset + eyes:Up()

        -- Turn to face player.
        eyes:RotateAroundAxis(eyes:Forward(), 90)
        eyes:RotateAroundAxis(eyes:Right(), 90)

        cam.Start3D2D(pos, Angle(0, eyes.y, 90), 0.05)
            surface.SetMaterial(iconMaterial)
            surface.SetDrawColor( 0, 0, 0, 255 )
            surface.DrawTexturedRect(-IconSize / 2, -IconSize / 2, IconSize, IconSize)
        cam.End3D2D()

    end
end