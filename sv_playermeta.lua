
local PlayerMeta = FindMetaTable("Player")

-------------------------------------------------------
-- TOS

function PlayerMeta:GPTHasAcceptedTOS()
	return GNIL.GPT.TOS.HasAccepted(self)
end

function PlayerMeta:GPTHasSeenTOS()
	return GNIL.GPT.TOS.HasSeenTOS(self)
end

function PlayerMeta:GPTShowTOS()
	GNIL.GPT.TOS.ShowTOS(self)
end

-------------------------------------------------------
-- Interaction

function PlayerMeta:GPTInteractionStart(ent)
	return GNIL.GPT.Interaction.Start(self, ent)
end

function PlayerMeta:GPTInteractionClear()
	return GNIL.GPT.Interaction.Clear(self)
end

function PlayerMeta:GPTCurrentInteraction()
	return GNIL.GPT.Interaction.GetCurrent(self)
end

-------------------------------------------------------
-- Recording

function PlayerMeta:GPTRecordingStart(timeout)
	GNIL.GPT.Recording.Start(self, timeout)
end

function PlayerMeta:GPTRecordingEnd()
	GNIL.GPT.Recording.End(self)
end

-------------------------------------------------------
-- Mute

function PlayerMeta:IsGPTMuted()
	return self._gpt_muted
end
