local MODULE = MODULE
local LocalPlayer = LocalPlayer()
local Net = MODULE:GetExtension("net")

--[[
	Starting the interaction with creating the menu and
	letting the server known we started an interaction
--]]
local maxdist = 300 ^ 2
function GNIL.GPT.Interaction.Start(ent)
	local intmenu = GNIL.GPT.Interaction.GetCurrent()
	if IsValid(intmenu) then return intmenu	end

	local chat_container = vgui.Create("DPanel")
	chat_container.Entity = ent
	chat_container._thinkdelay = CurTime()
	LocalPlayer._gpt_currentinteraction = chat_container
	chat_container:SetSize(ScrW() * .45, ScrH() * .25)
	chat_container:Center()
	chat_container:SetY(ScrH() - chat_container:GetTall() * 1.3)
	chat_container.Paint = function() end

	ent.AltRemove = function()
		chat_container:Remove()
	end

	local chat_log = chat_container:Add("gpt_msglog")
	chat_container.chat_log = chat_log
	chat_log.parent = chat_container
	chat_log:Dock(TOP)

	function chat_container:AddMessage(speakertbl, data)
		local cht, inpt, npc = self.chat_log, self.chat_log.input, self.Entity

		local msg = cht:AddMessage(speakertbl, data[2])

		-- if the url works play the sound and start typewriter
		-- if it dosent it will start typewriter anyways
		npc:PlayVoice(data[1], function()
			if not IsValid(msg) then return end
			msg:StartTypeWriter()
		end)

		inpt:SetEnterAllowed(false)
		msg:TypeWriteFinishCallback(function()
			inpt:SetEnterAllowed(true)
		end)

		return msg
	end

	local hist = ent:History():GetHistory("local", 10)
	if #hist > 0 then
		for _, d in ipairs(hist) do
			d[2].length = 1
			chat_container:AddMessage(d[1], d[2])
		end
	end

	function chat_container:Think()
		if self._thinkdelay > CurTime() then return end
		self._thinkdelay = CurTime() + 1

		if not IsValid(self.Entity) or self.Entity:GetPos():DistToSqr(LocalPlayer:GetPos()) > maxdist then
			GNIL.GPT.Interaction.Close()
		end
	end

	function chat_container:OnRemove()
		self.removing = true
		if self.removing then return end
		GNIL.GPT.Interaction.Close()
	end

	return chat_container
end

function GNIL.GPT.Interaction.Error(etype)
	local pnl = GNIL.GPT.Interaction.GetCurrent()
	if not pnl then return end
	local msg = {text = "", length = 2.5}
	if etype == GNIL_GPT_ERRORS_CANCELLED then
		msg.text = "Transcribing has ben cancelled"
	elseif etpye == GNIL_GPT_ERRORS_RESPONSE then
		msg.text = "An error occured on the server, please try again in a few seconds."
	end

	pnl:AddMessage({"Error", c["red"]}, msg)
end

function GNIL.GPT.Interaction.Close()
	local intmenu = GNIL.GPT.Interaction.GetCurrent()
	if IsValid(intmenu) then
		intmenu:Clear()
		intmenu:Remove()
	end
	LocalPlayer._gpt_currentinteraction = nil
	GNIL.Net.Create("gpt_interaction"):WriteBool(false):SendToServer()
end

function GNIL.GPT.Interaction.GetCurrent()
	local p = LocalPlayer._gpt_currentinteraction
	return IsValid(p) and p
end

Net:Receive("gpt_interaction", function()
	if not net.ReadBool() then
		GNIL.GPT.Interaction.Close()
		return
	end

	GNIL.GPT.Interaction.Start(net.ReadEntity())
end)

Net:Receive("gpt_interaction_error", function()
	GNIL.GPT.Interaction.Error(net.ReadUInt(3))
end)

--[[
	Recording updates for the client
--]]

function GNIL.GPT.Recording.Start(timeout)
	local mnu = GNIL.GPT.Interaction.GetCurrent()
	if not IsValid(mnu) then return end
	local str = "gpt.recording." .. tostring(mnu)
	mnu.input.record_button.recording = true
	mnu.input:SetEnterAllowed(false)
	GNIL.GPT.Recording.Length = timeout
	timer.Create(str, timeout, 1, GNIL.GPT.Recording.End)
end

function GNIL.GPT.Recording.End(fromserver)
	local mnu = GNIL.GPT.Interaction.GetCurrent()
	local tname = "gpt.recording." .. tostring(mnu)
	if timer.Exists(tname) then GNIL.GPT.Recording.Length = nil timer.Remove(tname) end
	if not fromserver then
		-- reason nothing is writen is because only time the client is sending
		-- anything to the server over this net is to manually stop recording
		-- this is for the mute button in the menu, only time it should be used clientside
		GNIL.Net.Create("gpt_recording"):SendToserver()
	end
	if not IsValid(mnu) then return end
	mnu.input.record_button.recording = false
	mnu.input:SetEnterAllowed(true)
end

function GNIL.GPT.Recording.IsRecording()
	local mnu = GNIL.GPT.Interaction.GetCurrent()
	local tname = "gpt.recording." .. tostring(mnu)
	return timer.Exists(tname), tname, GNIL.GPT.Recording.Length
end

Net:Receive("gpt_recording", function()
	if not net.ReadBool() then
		GNIL.GPT.Recording.End(true)
		return
	end

	GNIL.GPT.Interaction.Start(net.ReadEntity())
end)

--[[
	Output receiving stuff
--]]

function GNIL.GPT.Input.SendPrompt(prompt)
	local pnl = GNIL.GPT.Interaction.GetCurrent()
	if not IsValid(pnl) then return end
	if IsValid(pnl.Entity) then
		pnl.Entity:History():AddMessage("local", {LocalPlayer():GetName(), Color(36,181,233)},{text = prompt, length = 1})
	end
	GNIL.Net.Create("gpt_input_prompt")
		:WriteString(prompt)
	:SendToserver()
end

--[[
	Output receiving stuff
--]]
Net:Receive("gpt_output_data", function()
	local ent = net.ReadEntity()
	local data = net.ReadUInt(32)
	data = util.JSONToTable(util.Decompress(net.ReadData(data)))

	-- error occured or npc is gone
	if not data or not IsValid(ent) then
		return
	end

	local panl = GNIL.GPT.Interaction.GetCurrent()
	if not panl then
		local len = data.driver == "gcloud" and data.timepoints.len or data.length
		GNIL.GPT.Subtitles.Add(ent:GetDisplayName(), data, len, nil, ent:GetNameColor())
		return
	end

	if panl.Entity ~= ent then return end
	local msg = {{ent:GetDisplayName(), ent:GetNameColor(), ent.GetTextFont and npc:GetTextFont()},data}
	ent:History():AddMessage("local", msg)
	panl:AddMessage(msg[1], msg[2])
end)