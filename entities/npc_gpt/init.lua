
util.AddNetworkString("gpt_npc_done")

function ENT:SetupNPCData(gender, country_code, display_name, model, age, mood, textcolor)
	self:SetGender(gender or self:GetRandomData("gender"))
	self:SetCountryCode(country_code or self:GetRandomData("countrycode"))
	self:SetDisplayName(display_name or self:GetRandomData("fullname"))
	self:SetAge(age or self:GetRandomData("age", 1, 100))
	self:SetMood(mood or self:GetRandomData("mood"))
	self:SetModel(model or self:GetGenderModel(self:GetGender()))
	self:SetTextColor(textcolor or ColorRand())
end

function ENT:Initialize()
	self:SetupNPCData()
	self:SetCurrentState(self.STATE["Idle"])
	self.nextusecooldown = {}

	self.recorder = false
	self.brain = GNIL.GPT.Classes.Brain:New()
	self.brain:GetTTSParameters():SetProvider(
		GNIL_GPT_SPEECH_PROVIDER_ELEVENLABS
	)

	GNIL.GPT.Websocket:IsConnected()

	self.states = {
		["Idle"] = {
			OnUse = function(slf, ply)
				if not ply:GPTHasAcceptedTOS() then
					slf.nextusecooldown[ply] = CurTime() + 1.3268

					if not ply._gpt_tos_seen then
						ply:GPTShowTOS()
						return
					end

					ply:ChatMessage(Color(244,244,244),"[",Color(255,139,62),"TOS",Color(244,244,244),"] You have not accepted the ",Color(255,178,178),"TOS",Color(244,244,244)," to use this feature, type \"", Color(94,250,164),"/acceptTOS",Color(244,244,244),"\" to accept the TOS.")
					return
				end

				if not self:StartInteraction() then return end

				if ply:IsGPTMuted() then
					ply:ChatMessage(Color(244,244,244),"[",Color(255,139,62),"TOS",Color(244,244,244),"] You have not accepted the ",Color(255,178,178),"TOS",Color(244,244,244)," to use this feature, type \"", Color(94,250,164),"/acceptTOS",Color(244,244,244),"\" to accept the TOS.")
					return
				end

				self.recorder = GNIL.GPT.Classes.Recorder:New(ply:UserID())
					:OnSuccess(function(text)
						self:BrainThink(text, ply)
					end)
					:OnError(function(errorType, errorMessage)
						self:EndListening(true)
						if errorType == GNIL_GPT_ERRORS_CANCELLED then return end
					end)
				self:StartListening()
			end,
		},
		["Listening"] = {
			OnUse = function(slf, ply)
				self:EndListening()
			end,
		},
		["Thinking"] = {
			OnUse = function(slf, ply)
				-- !!! do something here?
			end,
		},
		["Talking"] = {
			OnUse = function(slf, ply) end,
		},
		["Generic"] = {
			OnDamage = function(slf, dmginfo, atker) end,
			OnUse = function(slf, ply)
				ply:ChatMessage(self:GetTextColor(), self:GetDisplayName(), Color(246, 246, 246), ": I'm a little busy right now.")
			end,
		}
	}
end

function ENT:OnRemove()
	if self.brain then
		self.brain:Delete()
	end
end

local usedelay = .75

function ENT:Use(ply)
	-- need to add tos stuff still
	if type(ply) ~= "Player" then return end

	if not self.nextusecooldown[ply] or self.nextusecooldown[ply] <= CurTime() then
		self.nextusecooldown[ply] = CurTime() + usedelay
		local state_onuse = self.states[self.m_moving and "Generic" or self.STATE[self:GetCurrentState()]].OnUse

		if isfunction(state_onuse) then
			state_onuse(self, ply)
		end
	end
end

function ENT:Think()
end

function ENT:Timer(str, del, rep, func)
	if isfunction(rep) and func == nil then func = rep rep = 1 end

	local tname = "gpt.npc.talking." .. str .. "." .. tostring(self)
	timer.Create(tname, del, rep, function()
		if not IsValid(self) then return end
		func(self)
	end)
end

function ENT:StartInteraction(ply)
	local cply = self:GetListeningTarget()
	if IsValid(cply) and cply ~= ply then
		ply:ChatMessage(self:GetTextColor(), self:GetDisplayName(), Color(246, 246, 246), ": I'm a little busy right now.")
		self.nextusecooldown[ply] = CurTime() + 1.5
		return false
	end
	self:SetListeningTarget(ply)

	-- If there is no menu we open up a new one
	if not IsValid(GNIL.GPT.Interaction.GetCurrent(ply)) then
		GNIL.GPT.Interaction.Start(ply, self)
		self.nextusecooldown[ply] = CurTime() + 1
		--[[
			the reason we stop here to start the interaction,
			so the next time they use the npc it will
			start/stop the recording
		]]
		return false
	end

	return true
end

function ENT:EndInteraction()
	local ply = self:GetListeningTarget()
	if IsValid(ply) then
		GNIL.GPT.Interaction.End(ply)
	end
	self:SetListeningTarget(nil)
	self:SetCurrentState(self.STATE["Idle"])
	if self.recording then
		self.recording:StopRecording(true)
		self.recording = nil
	end
end

function ENT:StartListening()
	local ply = self:GetListeningTarget()
	if not IsValid(ply) then self:EndInteraction() return end
	self.recorder:StartRecording()
	GNIL.GPT.Recording.Start(ply, 30,function()
		GNIL.GPT.Recording.End(ply)
		if IsValid(self) then
			self:EndListening()
		end
	end)
	self:SetCurrentState(self.STATE["Listening"])
end

function ENT:EndListening(cancel)
	local ply = self:GetListeningTarget()

	if not IsValid(ply) then
		self:EndInteraction()
		return
	end

	GNIL.GPT.Recording.End(ply)
	if self.recorder:IsRecording() then
		self.recorder:StopRecording()
	end

	if cancel then
		self:SetCurrentState(self.STATE["Idle"])
		return
	end

	self:SetCurrentState(self.STATE["Thinking"])
end

function ENT:BrainThink(newmsg, ply, history)
	-- !!! history handling
	local gpt_params = GNIL.GPT.Classes.GPTParameters:New()
	:AddMessage(newmsg, "user", ply:SteamID64())
	:SetHistory(steamid, 3)

	self.brain:Think(gpt_params)
	:OnError(function(errorType, errorMessage)
		self:SetCurrentState(self.STATE["Idle"])
	end)
	:OnSuccess(function(out)

		self:StartTalking(out)
	end)
end

function ENT:StartTalking(data)
		-- data.gpt = {GPT Response message}
		-- data.tts = {URL, data}
		local driver = data.tts.driver
		local length = 2

		if driver == "gcloud" then
			length = out.tts.timepoints.len
		elseif driver == "elevenlabs" then
			length = out.tts.length
		else
			return
		end

		self:Timer("Talking", length, function()
			self:SetCurrentState(self.STATE["Idle"])
		end)

		local rf = RecipientFilter()
		rf:AddPlayer(self:GetListeningTarget())
		rf:AddPAS(self:GetPos())
		GNIL.GPT.Output.Send(rf, self, data.tts)
end

function ENT:RunBehaviour()
	while true do
		self:StartActivity(ACT_IDLE)
		self:SetSequence("lineidle0" .. math.random(3))
		coroutine.wait(60 * 10)
	end
end

function ENT:OnTakeDamage() return 0 end