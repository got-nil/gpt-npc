local MODULE = MODULE
local Net = MODULE:GetExtension("net")

GNIL.Net.AddNetworkStrings("gpt_interaction", "gpt_interaction_error", "gpt_recording", "gpt_input_prompt", "gpt_input_subtitle", "gpt_output_data")

--[[
	Interaction tracking for the server, getting updates from the client
--]]
local maxdist = 150 ^ 2
Net:Receive("gpt_interaction", function(_, ply)
	local bool = net.ReadBool()

	if not bool then
		-- the client has closed their interaction, clear what we have on serverside
		GNIL.GPT.Interaction.Clear(ply, true)
		return
	end

	local ent = net.ReadEntity()
	local response = false

	if ply:GetPos():DistToSqr(ent:GetPos()) <= maxdist then
		response = GNIL.GPT.Interaction.Start(ply, ent)
	end

	return GNIL.Net.CreateReply():WriteBool(response)
end)

function GNIL.GPT.Interaction.Start(ply, ent)
	ply._gpt_currentinteraction = ent

	GNIL.Net.Create("gpt_interaction")
		:WriteBool(true)
		:WriteEntity(ent)
	:Send(ply)
end

function GNIL.GPT.Interaction.Error(ply, etype)
	GNIL.Net.Create("gpt_interaction_error")
		:WriteUInt(etype,3)
	:Send(ply)
end

function GNIL.GPT.Interaction.Clear(ply, clientrequest)
	ply._gpt_currentinteraction:EndInteraction()
	ply._gpt_currentinteraction = nil

	-- this is to prevent the server from sending a useless message back to the client
	-- the client has already closed the interaction, it's good enough
	if clientrequest then return end
	GNIL.Net.Create("gpt_interaction"):WriteBool(false):Send(ply)
end
GNIL.GPT.Interaction.End = GNIL.GPT.Interaction.Clear

function GNIL.GPT.Interaction.GetCurrent(ply)
	return ply._gpt_currentinteraction
end

--[[
	Recording updates for the server
--]]

function GNIL.GPT.Recording.Start(ply, timeout, timeoutfunc)
	timer.Create("gpt.recording." .. tostring(ply), timeout,1, timeoutfunc)
	GNIL.Net.Create("gpt_recording")
		:WriteBool(true)
		:WriteFloat(timeout)
	:Send(ply)
end

function GNIL.GPT.Recording.End(ply, clientrequest)
	local tname = "gpt.recording." .. tostring(ply)
	if timer.Exists(tname) then	timer.Remove(tname)	end
	-- prevent useless message from being sent
	if clientrequest then return end
	GNIL.Net.Create("gpt_recording")
		:WriteBool(false)
	:Send(ply)
end

Net:Receive("gpt_recording", function(_, ply)
	GNIL.GPT.Recording.End(ply, true)
end)

--[[
	TTS output data stuff
--]]

function GNIL.GPT.Output.Send(ply, ent, data)
	data = util.Compress(util.TableToJSON(data))
	GNIL.Net.Create("gpt_output_data")
		:WriteEntity(ent)
		:WriteUInt(#data, 32)
		:WriteData(data, #data)
	:Send(ply)
end

--[[
	Input Prompt
--]]

Net:Receive("gpt_input_prompt", function(_, ply)
	local ent = GNIL.GPT.Interaction.GetCurrent(ply)
	if not IsValid(ent) then return end
	local msg = net.ReadString()

	-- When the player sends a manual text input, show the messages to anyone nearby
	-- !!! might need to be moved to the brain think
	-- local rf = RecipientFilter()
	-- rf:AddPAS(ent:GetPos())
	-- rf:RemovePlayer(ply)

	-- GNIL.Net.Create("gpt_input_subtitle")
	-- 	:WriteString(msg)
	-- 	:WriteString(ply:GetName())
	-- :Send(rf)

	ent:BrainThink(msg, ply)
end)