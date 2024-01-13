local MODULE = MODULE

MODULE:GetExtension("net"):Receive("gpt_npc_speak", function()

    local data = {
        npc = net.ReadEntity(),
        url = net.ReadString(),
        length = net.ReadFloat(),
        driver = net.ReadString(),
        text = net.ReadString(),
        has_timepoints = net.ReadBool()
    }

    -- Make sure we're getting a valid GPT NPC NPC reference.
    if not IsValid(data.npc) or not data.npc.GPTNPC then
        return
    end

    -- If there are timepoints, also get those.
    if data.has_timepoints then
        local timepoints = {}
        for i = 1, net.ReadUInt(12) do
            timepoints[i] = net.ReadDouble()
        end
        data.timepoints = timepoints
    end

    -- Setup the subtitles.
    local wordDriver = GNIL.GPT.Classes.WordDriver:New():Ingest(
        data.text,
        data.timepoints,
        data.length
    )

    local wordDriverId = wordDriver:GetID()
    data.npc._word_drivers[wordDriverId] = wordDriver

    sound.PlayURL(data.url, "3d", function(soundChannel, _, errName)

        -- Make sure the NPC is still valid.
        if not IsValid(data.npc) then
            return
        end

        -- Handle various possible errors.
        if errName then
            data.npc:HandleError("Failed to play TTS file with errorName: " .. errName)
            return
        end
        if not IsValid(soundChannel) then
            data.npc:HandleError("Failed to get a valid soundChannel for TTS file.")
            return
        end

        -- Store the voice channel so its position can be tracked/updated
        -- and then start playing.
        data.npc.Voice = soundChannel
        soundChannel:SetPos(data.npc:GetPos())

        soundChannel:Play()
        wordDriver:Start(true)

        -- Remove the voice channel once finished.
        timer.Simple(data.length, function()
            if not IsValid(data.npc) or not IsValid(data.npc.Voice) then
                return
            end

            data.npc.Voice:Stop()
            data.npc.Voice = nil

            data.npc._word_drivers[wordDriverId] = nil
        end)
    end)
end)

-- Idea stolen directly from the original NPC made by Virtualraptor.
local VoiceOffset = Vector(0, 0, 64)
function ENT:Think()

    local voice = self.Voice
    if voice != nil and IsValid(voice) then

        local v = self:GetPos()
        v:Add(VoiceOffset)
        voice:SetPos(v)

    end
end
