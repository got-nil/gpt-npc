local MODULE = MODULE

if CLIENT then
	local LocalPlayer = LocalPlayer
	local c = {
		["white"] = Color(244,244,244),
		["blue"] = Color(76,250,230),
		["muted"] = Color(244,67,64),
		["unmuted"] = Color(64,244,82),
	}

	function GNIL.GPT.Mute.SetGPTMuted(state)
		GNIL.Net.Create("gpt_mute")
			:WriteBool(state)
			:OnReply(function(succ)
				if not succ then return end
				local newstate = net.ReadBool()
				LocalPlayer()._gpt_muted = newstate
				local text = newstate and "muted" or "unmuted"
				chat.AddText(c["white"],"[",c["blue"],"NPC Mute",c["white"],"] The NPC's are now ",c[text],text,c["white"]," from hearing you.")
			end)
		:SendToServer()
	end

	function GNIL.GPT.Mute.IsGPTMuted()
		return Either(isbool(LocalPlayer()._gpt_muted), LocalPlayer()._gpt_muted, false)
	end

	function GNIL.GPT.Mute.ToggleGPTMuted()
		GNIL.GPT.Mute.SetGPTMuted(not GNIL.GPT.Mute.IsGPTMuted())
	end

	local states = {
		["mute"] = true,
		["unmute"] = false,
		["true"] = true,
		["false"] = false,
		["1"] = true,
		["0"] = false,
	}

	MODULE:AddHook("OnPlayerChat", "GPT.Mute.Chat", function(ply, txt)
		if ply ~= LocalPlayer() or txt:sub(1,8) ~= "/gptmute" then return end
		local bool = txt:Trim():sub(10,#txt)
		if states[bool] ~= nil then
			if bool == "" then
				GNIL.GPT.Mute.ToggleGPTMuted()
			else
				GNIL.GPT.Mute.SetGPTMuted(states[bool])
			end
		end
	end)
else

	GNIL.Net.AddNetworkString("gpt_mute")

	MODULE:GetExtension("net"):Receive("gpt_mute", function(_, ply, reply)
		local newstate = net.ReadBool()
		ply._gpt_muted = newstate
		if IsValid(ply._gpt_currentinteraction) then
			ply._gpt_currentinteraction:EndListening(true, true)
		end
		return reply:WriteBool(newstate)
	end)

	function GNIL.GPT.Mute.IsGPTMuted(ply)
		return ply._gpt_muted
	end
end