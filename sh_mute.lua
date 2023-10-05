local MODULE = MODULE
local LocalPlayer = LocalPlayer

if CLIENT then

	function GNIL.GPT.Mute.SetGPTMuted(state)
		GNIL.Net.Create("gpt_mute")
			:WriteBool(state)
			:OnReply(function(succ)
				if not succ then return end
				LocalPlayer()._gpt_muted = net.ReadBool()
			end)
		:SendToServer()
	end

	function GNIL.GPT.Mute.IsGPTMuted()
		return LocalPlayer()._gpt_muted
	end

	function GNIL.GPT.Mute.ToggleGPTMuted()
		GNIL.GPT.Mute.SetGPTMuted(not GNIL.GPT.Mute.IsGPTMuted())
	end

else

	GNIL.Net.AddNetworkString("gpt_mute")

	MODULE:GetExtension("net"):Receive("gpt_mute", function(_, ply)
		local mute = net.ReadBool()
		ply._gpt_muted = mute
		ply._gpt_currentinteraction:EndListening(true)
		return GNIL.Net.CreateReply():WriteBool(mute)
	end)

	function GNIL.GPT.Mute.IsGPTMuted(ply)
		return ply._gpt_muted
	end
end