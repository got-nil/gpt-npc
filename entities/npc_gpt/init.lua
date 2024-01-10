local MODULE = MODULE

GNIL.Net.AddNetworkString("gpt_npc_speak")

function ENT:Initialize()
    self:SetState(GNIL_GPT_NPC_STATE_IDLE)

    self:SetModel("models/Humans/Group01/Male_01.mdl")
    self:SetUseType(SIMPLE_USE)

    -- The actual GPT "brain" that is used by the NPC.
    -- TODO: Initialize with a random Gender.
    self.Brain = GNIL.GPT.Classes.Brain:New("male")

    -- TODO: Stop using elevenlabs as the default and actually
    -- fix whatever weird billing issue is stopping me from using
    -- GoogleCloud properly. Pretty sure I have my old card on it.
    self.Brain:GetTTSParameters():SetProvider(
        GNIL_GPT_SPEECH_PROVIDER_ELEVENLABS
    )
end

function ENT:Use(ply)
    if not IsPlayer(ply) then return end
    self:RunStateHandler("Use", ply)
end

function ENT:OnTakeDamage()
    return false
end

-- When the NPC is being removed, set its state to Busy.
-- This is important as it calls ExitState on the current state
-- to allow for any cleanup to take place.
function ENT:OnRemove()
    self:SetState(GNIL_GPT_NPC_STATE_BUSY)
end

function ENT:Speak(url, data)

    -- Send the TTS speak data to all nearby players.
    -- TODO: GoogleCloud timemarkers.
    for _, v in ipairs(self:FindNearbyPlayers()) do
        GNIL.Net.Create("gpt_npc_speak")
            :WriteEntity(self)
            :WriteString(url)
            :WriteFloat(data.length)
            :WriteString(data.driver)
            :WriteString(data.message.text)
        :Send(v)
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