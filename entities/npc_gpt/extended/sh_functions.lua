
local FindInSphere = ents.FindInSphere

function ENT:FindClosestInSphere(pos, radius, filter)
    pos = (isvector(pos) and pos) or self:GetPos()
    local closest, dist = nil, math.max

    for _, ent in ipairs(FindInSphere(pos, radius)) do
        if not IsValid(ent) or ent == self or not (filter == nil or filter(self, ent)) then continue end
        local edist = pos:DistToSqr(ent:GetPos())
        if not closest or edist < dist then
            closest = ent
            dist = edist * edist
        end
    end

    return closest
end

function ENT:FindInSphere(pos, radius, filter)
    pos = (isvector(pos) and pos) or self:GetPos()
    local tbl = {}

    for _, ent in ipairs(FindInSphere(pos, radius)) do
        if IsValid(ent) and ent != self and (filter == nil or filter(self, ent)) then
            tbl[#tbl + 1] = ent
        end
    end

    return tbl
end