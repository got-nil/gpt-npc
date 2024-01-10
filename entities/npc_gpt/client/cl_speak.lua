local MODULE = MODULE

MODULE:GetExtension("net"):Receive("gpt_npc_speak", function()

    local data = {
        npc = net.ReadEntity(),
        url = net.ReadString(),
        length = net.ReadFloat(),
        driver = net.ReadString(),
        text = net.ReadString()
    }

    -- Make sure we're getting a valid GPT NPC NPC reference.
    if not IsValid(data.npc) or not data.npc.GPTNPC then
        return
    end

    sound.PlayURL(data.url, "3d", function(soundChannel, _, errName)

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

        -- Remove the voice channel once finished.
        timer.Simple(data.length, function()
            if not IsValid(data.npc) or not IsValid(data.npc.Voice) then
                return
            end
            data.npc.Voice:Stop()
            data.npc.Voice = nil
        end)

        -- TODO: Replace with some nice UI obviously.
        LocalPlayer():PrintMessage(HUD_PRINTTALK, data.text)
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
