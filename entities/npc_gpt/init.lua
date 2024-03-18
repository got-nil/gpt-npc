local MODULE = MODULE

MODULE:Include("entities/npc_gpt/sv_random.lua")
GNIL.Net.AddNetworkString("gpt_npc_speak")

function ENT:Initialize()

    -- Randomise the NPC Model and Gender.
    local randomData = self:GetRandomData()
    self.Gender = randomData.Gender

    -- TODO: Stop using elevenlabs as the default and actually
    -- fix whatever weird billing issue is stopping me from using
    -- GoogleCloud properly. Pretty sure I have my old card on it.
    self.Brain = GNIL.GPT.Classes.Brain:New(randomData.Gender)
    self.Brain:GetTTSParameters():SetProvider(
        GNIL_GPT_SPEECH_PROVIDER_GOOGLECLOUD
    )

    self:SetUseType(SIMPLE_USE)
    self:SetState(GNIL_GPT_NPC_STATE_IDLE)
    self:SetModel(randomData.Model)
end

function ENT:Use(ply)
    if not IsPlayer(ply) then return end
    self:RunStateHandler("Use", ply)
end

-- When the NPC is being removed, set its state to Busy.
-- This is important as it calls ExitState on the current state
-- to allow for any cleanup to take place.
function ENT:OnRemove()
    self:SetState(GNIL_GPT_NPC_STATE_BUSY)
end

function ENT:Speak(url, data)

    local has_timepoints = data.timepoints != nil
    local nm = GNIL.Net.Create("gpt_npc_speak")
        :WriteEntity(self)
        :WriteString(url)
        :WriteFloat(data.length)
        :WriteString(data.driver)
        :WriteString(data.message.text)
        :WriteBool(has_timepoints)

    -- If there are timepoints, also write them to the message.
    if has_timepoints then

        local len = data.timepoints.len
        local times = data.timepoints.data
        assert(isnumber(len), "Provided timepoints length must be a number.")

        nm:WriteUInt(len, 12) -- 4095 words max
        for i = 1, len do
            nm:WriteDouble(times[i][2])
        end
    end

    -- Send the TTS speak data to all nearby players.
    for _, v in ipairs(self:FindNearbyPlayers()) do
        nm:Send(v)
    end
end

function ENT:FindNearbyPlayers()

    -- TODO: Maybe use a box instead to ignore players under the NPC
    -- such as in the downtown maps that have sewers under the street.
    -- OR, as @Blueasharky suggests just do a height check first.
    local out = {}
    for _, v in ipairs(ents.FindInSphere(self:GetPos(), self.Config.NearbySearchRadius)) do
        if IsPlayer(v) then
            table.insert(out, v)
        end
    end
    return out
end

-- TODO: Maybe look into possible optimisations such as caching the listening target.
-- Also look into how the network var getters actually cache the value (if they do).
function ENT:Think()

    local target = self:GetListeningTarget()
    if target != nil and IsValid(target) then

        -- If the listening target goes too far, return to idle state.
        local dist = self:GetPos():DistToSqr(target:GetPos())
        if dist > self.Config.CancelRadiusSqr then
            self:SetState(GNIL_GPT_NPC_STATE_IDLE)
            self:ChatMessage("How rude! Walking away from someone in the middle of a conversation!")
        end
    end
end

-- Nextbot behaviour coroutine.
-- TODO: Make it actually do stuff.
function ENT:RunBehaviour()
    while true do
        self:StartActivity(ACT_IDLE)
        self:SetSequence("lineidle0" .. math.random(3))
        coroutine.wait(60 * 10)
    end
end

-- Don't take any damage.
function ENT:OnTakeDamage()
    return 0
end