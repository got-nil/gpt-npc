local MODULE = MODULE

function ENT:Initialize()
    -- local nameplate = GPT.UI.CreateNameplate(self:GetDisplayName(), self:GetIsFemale(), self.flag)
    -- nameplate.entity = self

    -- self.nameplate = nameplate

    self:AddCallback( "BuildBonePositions", function( ent, _ )
        ent:HeadLook()
    end)
end

local maxdist = 200 * 200
local mindist = 100 * 100
local off = Vector(0,0,64)

function ENT:DrawTranslucent()
    self:DrawModel()
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

        -- self:DrawNameplate()
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

    -- todo: angle clamping or what ever the fuck it needs

    bone_matrix:SetAngles(self.look_angle)
    self:SetBoneMatrix(bone_index, bone_matrix)
end

function ENT:Think()
    if IsValid(self.voice) then
        self.voice:SetPos(self:GetPos())
    end

    if self:GetCurrentState() == 3 then return end
    local ply = IsValid(self:GetListeningTarget()) and self:GetListeningTarget() or self:FindClosestInSphere(nil, 150, function(_, e) return type(e) == "Player" end)

    if ply then
        self.look_target = ply
        self:SetupBones()
    elseif self.look_target then
        self.look_target = nil
        self:SetupBones()
    end
end

function ENT:OnRemove()
    if IsValid(self.voice) then
        self.voice:Stop()
    end
    -- if IsValid(self.nameplate) then
    -- 	self.nameplate:Remove()
    -- end
end

net.Receive("gpt_npc_done", function()
    local data = {
        ent = net.ReadEntity(),
        url = net.ReadString(),
        vlen = net.ReadUInt(32)
    }
    data.vdata = util.JSONToTable(util.Decompress(net.ReadData(data.vlen)))
    MODULE:log(data, "debug")

    if not data.vdata then
        MODULE:log("Could not read GPT Voice Data from nm!", "error")
        return
    end
end)

-- example

-- this:PlayAudio("https://cdn.morgverd.com/shx/files/UXLqaHnzdhqCvzO9vqnNwChKa.mp3", {
-- 	driver = "gcloud",
-- 	length = 9.29183292388916,
-- 	message = {
-- 		text = "Hello there how are you today This is another test sentence for raptor to use when making the NPC audio sync I wish you good luck love you!",
-- 		words = {"Hello", "there,", "how", "are", "you", "today?", "This", "is", "another", "test", "sentence", "for", "raptor", "to", "use", "when", "making", "the", "NPC", "audio", "sync.", "I", "wish", "you", "good", "luck,", "love", "you!"}
-- 	},
-- 	timepoints = util.JSONToTable([[{"len": 28, "data": {"1": ["Hello", 0.014999999664723873], "2": ["there,", 0.39129164814949036], "3": ["how", 0.9586249589920044], "4": ["are", 1.1796666383743286], "5": ["you", 1.2346665859222412], "6": ["today?", 1.3801665306091309], "7": ["This", 2.190500020980835], "8": ["is", 2.463916540145874], "9": ["another", 2.598583221435547], "10": ["test", 2.9031248092651367], "11": ["sentence", 3.25529146194458], "12": ["for", 3.772958278656006], "13": ["raptor", 3.875499963760376], "14": ["to", 4.349791526794434], "15": ["use", 4.4897918701171875], "16": ["when", 4.845791339874268], "17": ["making", 4.995957851409912], "18": ["the", 5.35641622543335], "19": ["NPC", 5.4796247482299805], "20": ["audio", 6.1775407791137695], "21": ["sync.", 6.5948333740234375], "22": ["I", 7.725165843963623], "23": ["wish", 7.845166206359863], "24": ["you", 8.104124069213867], "25": ["good", 8.229124069213867], "26": ["luck,", 8.451623916625977], "27": ["love", 9.025249481201172], "28": ["you!", 9.29183292388916]}}]])
-- })