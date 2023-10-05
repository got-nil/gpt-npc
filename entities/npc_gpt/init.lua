
util.AddNetworkString("gpt_npc_done")

local function randomname()
    return table.concat({first[math.random(#first)], " " ,last[math.random(#last)]})
end

function ENT:SetupNPCData(gender, country_code, display_name, model, age, mood)
    self:SetGender(gender or self:GetRandomData("gender"))
    self:SetCountryCode(country_code or self:GetRandomData("countrycode"))
    self:SetDisplayName(display_name or self:GetRandomData("fullname"))
    self:SetAge(age or self:GetRandomData("age", 1, 100))
    self:SetMood(mood or self:GetRandomData("mood"))
    self:SetModel(model or self:GetGenderModel(self:GetGender()))
end

function ENT:Initialize()
    self:SetupNPCData()
    self:SetCurrentState(self.STATE["Idle"])
    self.nextusecooldown = {}
    
    self.brain = GNIL.GPT.Classes.Brain:New()
    self.recorder = false


    -- !!! EXAMPLE SETTING THE NPC TO USE ELEVENLABS
    -- (BY DEFAULT, IT WILL USE GOOGLETTS)
    self.brain:GetTTSParameters():SetProvider(
        GNIL_GPT_SPEECH_PROVIDER_ELEVENLABS
    )

    -- !!! IF YOU WANT TO CHECK IF THE WEBSOCKET IS CONNECTED
    -- OR NOT. WHEN THE WEBSOCKET IS NOT CONNECTED, LITERALLY
    -- NOTHING WILL WORK.
    GNIL.GPT.Websocket:IsConnected()

    self.states = {
        ["Idle"] = {
            OnUse = function(slf, ply)

                self.recorder = GNIL.GPT.Classes.Recorder:New(ply:UserID())
                    :OnError(function(errorType, errorMessage)

                        -- !!! FAILED TO TRANSCRIBE THE USERS RECORDING.
                        -- THE ERRORMESSAGE WILL PROBABLY BE TECHNICAL.

                        -- ALL "PROMISES" MUST BE RESOLVED, SO CANCELLING
                        -- COUNTS AS AN ERROR. YOU CAN IGNORE THESE (SO
                        -- THE NPC DOESNT GO INTO AN ERROR STATE, LIKE THIS)
                        if errorType == GNIL_GPT_ERRORS_CANCELLED then
                            return
                        end

                        -- .....
                    
                    end)

                -- !!! Actually start recording the player, change state
                -- to Listening here.
                self.recorder:StartRecording()

                -- !!! IF YOU WANNA CHECK IF ITS RECORDING
                self.recorder:IsRecording()
            end,
        },
        ["Listening"] = {
            OnUse = function(slf, ply)
                
                self.recorder:OnSuccess(function(text)
                    
                    -- !!! The 'text' here is the transcription output.
                    -- GET THE TEXT TO 'THINKING'

                end)


                -- !!! IF YOU NEED TO STOP THE RECORDING AT ANY POINT:
                -- CANCELLED = boolean, if true the API wont actually
                -- recieve any recording data at all, and the OnError
                -- will be called immidiately.
                self.recorder:StopRecording(CANCELLED)

            end,
        },
        ["Thinking"] = {
            OnUse = function(slf, ply)

                -- !!! THIS IS HOW YOU WOULD SEND THE GPT MESSAGES BACK.
                -- YOU CAN AddMessage AS MANY TIMES AS YOU WANT IF THERE
                -- WERE MULTIPLE SPEAKERS, HOWEVER FOR THIS EXAMPLE WE ONLY
                -- ADD THE LAST 'text' (transcription).
                local text = "TEXT FROM RECORDER"
                local steamid = ply:SteamID64()

                -- !!! THE STEAMID IS OPTIONAL FOR Think, BUT IT IS REQUIRED
                -- IF YOU ALSO USE SetHistory, SO THE BRAIN KNOWS THE STEAMID
                -- OF THE MESSAGE AUTHOR.
                local gpt_params = GNIL.GPT.Classes.GPTParameters:New()
                    :AddMessage(text, "user", steamid) -- message text, GPT role, steamid
                    :SetHistory(steamid, 3) -- steamid, amount of history

                -- !!! THE SECOND ARGUMENT HERE CAN BE tts_params IF YOU 
                -- WANT TO OVERRIDE THE VOICE, GENDER OR TTS PROVIDER. IF
                -- ONE ISNT PROVIDED, THE DEFAULT BRAIN ONE IS USED.
                self.brain:Think(gpt_params)
                    :OnSuccess(function(out)
                        
                        -- out.gpt = {GPT Response message}
                        -- out.tts = {URL, data}

                    end)
                    :OnError(function(errorType, errorMessage)
                    
                        -- !!! FAILED WITH GPT OR TTS
                        -- ERROR MESSAGE WILL BE TECHNICAL.

                    end)

            end,
        },
        ["Talking"] = {
            OnUse = function(slf, ply) end,
        },
        ["Generic"] = {
            OnDamage = function(slf, dmginfo, atker) end,
            OnUse = function(slf, ply)
                ply:ChatPrint("I'm waulkin heaaa.")
            end,
        }
    }

    -- old stuff

    -- self.brain = GPT.GmodServer.CreateNPC({
    -- 	gender = self.gendername,
    -- 	driver = "elevenlabs"
    -- })

    -- self.brain:On("start", function()
    -- 	--[[
    -- 		the API has just been reset.
    -- 		NPC state etc should also be reset.
    -- 	]]
    -- 	self:SetCurrentState(self.STATE["Idle"])
    -- 	self:SetListeningTarget(nil)
    -- end)

    -- self.brain:On("cancelled", function(interaction)
    -- 	--[[
    -- 		the passed interaction has been cancelled.
    -- 		it will be deleted after the callback exec.
    -- 	]]
    -- 	self:SetCurrentState(self.STATE["Idle"])
    -- 	self:SetListeningTarget(nil)
    -- end)

    -- self.brain:On("error", function(interaction, error_message)
    -- 	--[[
    -- 		an error was encountered while trying to process an
    -- 		interaction. the interaction will be deleted after callback.
    -- 	]]
    -- 	local ply = self:GetListeningTarget()

    -- 	if IsValid(ply) then
    -- 		ply:ChatPrint("There has been an error, please try again.")
    -- 	end

    -- 	self:SetCurrentState(self.STATE["Idle"])
    -- 	self:SetListeningTarget(nil)
    -- end)

    -- self.brain:On("update", function(interaction, state, event) end)

    -- --[[
    -- 		called when an interaction state changes. The
    -- 		provided state is a string (whisper, gpt, tts)
    -- 		and event is the associated event data (different
    -- 		for each state, see below).

    -- 		structs:
    -- 			whisper - No data
    -- 			gpt - input(str) = The GPT input string (whisper output)
    -- 			tts - input(str) = The TTS input string (gpt output)
    -- 	]]
    -- self.brain:On("done", function(interaction, out)
    -- 	--[[
    -- 		called once the interaction has successfully finished.
    -- 		out structure:
    -- 			{
    -- 				file (str) - The TTS playback filename.
    -- 				data (table) - {
    -- 					driver (str) - Either 'gcloud' or 'elevenlabs', what was used for TTS generation.
    -- 					length (float) - The total playback length of the TTS file.
    -- 					message (table) - {
    -- 						text (str) - The TTS input message in full.
    -- 						words (table) [GCLOUD ONLY] - Sequential table of each word used for timepoint marks.
    -- 					},
    -- 					timepoints (table) [GCLOUD ONLY] - Timepoints structure sent last time
    -- 				}
    -- 			}
    -- 	]]
    -- 	self:SetCurrentState(4)
    -- 	local duration = out.data.length

    -- 	timer.Simple(duration + 2, function()
    -- 		if not IsValid(self) then return end
    -- 		self:SetCurrentState(1)
    -- 		self:SetListeningTarget(nil)
    -- 	end)

    -- 	local data = util.Compress(util.TableToJSON(out.data))
    -- 	net.Start("gpt_npc_done")
    -- 	net.WriteEntity(self)
    -- 	net.WriteString(GPT.Config.services.cdn.base .. "/" .. out.file .. ".mp3")
    -- 	net.WriteUInt(#data, 32)
    -- 	net.WriteData(data, #data)
    -- 	net.SendPVS(self:GetPos())
    -- end)
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

function ENT:StartListeningTarget(ply)
    self:SetListeningTarget(ply)
    -- self.interaction = self.brain:CreateInteraction(self:GetListeningTarget())

    -- self.interaction:StartRecording(function(success)
    -- 	if not success then
    -- 		self:GetListeningTarget():ChatPrint("Voice recording error.")
    -- 	end
    -- end)
end

function ENT:FinishListening()
    self:SetCurrentState(self.STATE["Thinking"])

    -- if self.interaction then
    -- 	self.interaction:StopRecording()
    -- end
end

function ENT:RunBehaviour()
    while true do
        self:StartActivity(ACT_IDLE)
        self:SetSequence("lineidle0" .. math.random(3))
        coroutine.wait(60 * 10)
    end
end

function ENT:OnTakeDamage() return 0 end