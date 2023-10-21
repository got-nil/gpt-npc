local MODULE = MODULE

function ENT:Initialize()
	self.isgptnpc = true
	self._history = {}

	self:AddCallback( "BuildBonePositions", function( ent, _ )
		ent:HeadLook()
	end)

	return self
end

function ENT:AddHistory(speaker, msg, col, font, alignment)
	table.insert(self._history, {speaker = speaker, msg = msg, length = 1, color = col or Color(36,181,233), font = font or "ChatMessage.Small", alignment = alignment})
end

function ENT:GetHistory()
	return self._history
end

function ENT:StartInteraction()
	GNIL.GPT.Interaction.Start(self)
end

function ENT:EndInteraction()
	GNIL.GPT.Interaction.Close()
end

function ENT:PlayVoice(url, callback)
	if not url then callback() return end
	sound.PlayURL(url, "3d", function(snd, err, errstr)
		if not IsValid(snd) or not IsValid(self) then callback() return end
		snd:SetPos(self:GetPos())
		self.voice = snd
		snd:Play()
		callback()
	end)
end

local maxdist = 200 * 200
local mindist = 100 * 100
local off = Vector(0,0,64)
function ENT:DrawTranslucent()
	self:DrawModel()
	if true then return end -- !!! repalce all this later
	if self:GetCurrentState() == self.STATE["Listening"] and self:GetListeningTarget() == LocalPlayer() then
		self:DrawState()
	end

	local dist = self:GetPos():DistToSqr(LocalPlayer():GetPos())
	if dist > maxdist then return end

	local aimVector = LocalPlayer():GetAimVector()
	local entVector = (self:GetPos() + off) - EyePos()
	local angCos = aimVector:Dot(entVector) / entVector:Length()

	local dotalpha = math.Clamp(math.ease.InQuad(angCos + .2), 0, 1)

	dist = dist - mindist
	local alpha = 1 - math.max(.04, dist / maxdist)

	if dotalpha < alpha then
		alpha = dotalpha
	end
	if alpha < 0.2 then return end

	surface.SetAlphaMultiplier(alpha)
		if self:GetCurrentState() == self.STATE["Thinking"] or (self:GetCurrentState() == self.STATE["Listening"] and self:GetListeningTarget() ~= LocalPlayer()) then
			self:DrawState()
		end
	surface.SetAlphaMultiplier(1)
end

function ENT:HeadLook()
	local bone_index = self:LookupBone("ValveBiped.Bip01_Head1")

	if not bone_index then return end
	local bone_matrix = self:GetBoneMatrix(bone_index)
	if not bone_matrix then return end

	if IsValid(self.look_target) then
		local ply_eyes = self.look_target:EyePos()
		self:SetEyeTarget(ply_eyes)

		-- this is absolute position
		local bone_pos = bone_matrix:GetTranslation()
		local dir = (ply_eyes - bone_pos):GetNormalized()
		local new_angle = dir:Angle()

		-- this is absolute angle
		local old_angle = bone_matrix:GetAngles()
		self.look_angle = self.look_angle or old_angle

		new_angle:RotateAroundAxis(new_angle:Up(),90)
		new_angle:RotateAroundAxis(new_angle:Right(),90)
		new_angle:RotateAroundAxis(new_angle:Up(),-15)

		self.look_angle_target = new_angle
	else
		local new_angle = self:GetAngles()
		new_angle:RotateAroundAxis(new_angle:Right(),90)
		new_angle:RotateAroundAxis(new_angle:Forward(),90)
		new_angle:RotateAroundAxis(new_angle:Up(),-15)

		self.look_angle_target = new_angle
	end

	self.look_angle = LerpAngle(.02, self.look_angle or Angle(0,0,0),self.look_angle_target or Angle(0,0,0))

	-- todo: !!! angle clamping or what ever the fuck it needs

	bone_matrix:SetAngles(self.look_angle)
	self:SetBoneMatrix(bone_index, bone_matrix)
end

local voice_offset = Vector(0,0,64)
function ENT:Think()
	if IsValid(self.voice) then
		local v = self:GetPos()
		v:Add(voice_offset)
		self.voice:SetPos(v)
	end

	if self:GetCurrentState() == 3 then return end
	local ply = IsValid(self:GetListeningTarget()) and self:GetListeningTarget() or self:FindClosestInSphere(nil, 150, function(_, e) return type(e) == "Player" end)

	if ply then
		self.look_target = ply
	elseif self.look_target then
		self.look_target = nil
	end

	self:SetupBones()
end

function ENT:AltRemove() end

function ENT:OnRemove()
	if IsValid(self.voice) then
		self.voice:Stop()
		self.voice = nil
	end
	self:AltRemove()
end

