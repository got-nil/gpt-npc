local MODULE = MODULE

-- Add entity icon materials (after shared).
for _, v in pairs(ENT.IconMaterialPaths) do
    resource.AddFile("materials/" .. v)
end

ENT.StateHandlers = {

    [GNIL_GPT_NPC_STATE_IDLE] = {

        -- Reset listening target when we become idle.
        EnterState = function(self)

            self:SetListeningTarget(nil)

        end,

        -- Pressing E when we're idle means someone wants to start
        -- a new interaction with the NPC. Check that they've accepted
        -- the TOS and then start the interaction cycle.
        Use = function(self, ply)

            -- TODO: check TOS.
            self:SetListeningTarget(ply)
            self:SetState(GNIL_GPT_NPC_STATE_LISTENING)

        end

    },

    [GNIL_GPT_NPC_STATE_LISTENING] = {

        -- When we enter the listening state, start recording.
        EnterState = function(self)

            local target = self:GetListeningTarget()
            if not IsValid(target) then
                return false
            end

            -- Tell the user when the recording has finished.
            local finishedRecording = function()
                if IsValid(target) then
                    target:ChatMessage("Finished/Stopped recording!")
                end
            end

            -- Make sure its the same state.
            local isSameState = function()
                return self:GetState() == GNIL_GPT_NPC_STATE_LISTENING
            end

            self.Recorder = GNIL.GPT.Classes.Recorder:New(target:UserID())
                :SetTimeout(self.Config.RecorderTimeout)
                :OnSuccess(function(out)

                    if not IsValid(self) or not isSameState() then
                        return
                    end
                    finishedRecording()

                    -- If we get a successful transcription, start thinking.
                    self:SetState(GNIL_GPT_NPC_STATE_THINKING, out)

                end)
                :OnError(function(errorType, errorMessage)

                    -- Ignore when we're already invalid, or if its a cancellation
                    -- error as we also accept text input.
                    if not IsValid(self) or not isSameState() then
                        return
                    end
                    finishedRecording()

                    if errorType == GNIL_GPT_ERRORS_CANCELLED then
                        return
                    end
                    self:HandleError("Failed to record transcription: " .. errorMessage)

                end)

            -- Attempt to start the recording.
            local started = self.Recorder:StartRecording()
            if not started then
                self:HandleError("Could not start recording!")
                return
            end
            target:ChatMessage("Started recording!")

        end,

        -- Make sure we cancel any recordings when we exit this state.
        -- Just incase something else somewhere else randomly changes the state.
        ExitState = function(self)

            if not self.Recorder then
                return
            end
            if self.Recorder:IsRecording() then
                self.Recorder:StopRecording(true)
            end

        end,

        -- Pressing E while we're listening should mean they've
        -- finished talking and want to end the recording.
        Use = function(self, ply)

            -- Ignore interactions from random people.
            if ply != self:GetListeningTarget() then
                ply:ChatMessage("Go away, I'm listening to someone else right now!")
                return
            end

            -- If we're not recording, ignore since we're probably just
            -- waiting for the recorder to finish before it resolves.
            if not self.Recorder:IsRecording() then
                return
            end

            -- Cancel the recording if its under 1 second,
            -- since the user is probably just spamming E.
            local cancelled = 1 > self.Recorder:GetRuntime()

            -- TODO: Maybe check if the recording failed to stop?
            -- It could maybe happen somehow but it really shouldn't.
            self.Recorder:StopRecording(cancelled)
        end

    },

    [GNIL_GPT_NPC_STATE_THINKING] = {

        EnterState = function(self, userInputText)

            -- Ensure we're actually getting some user input.
            if not userInputText then
                self:HandleError("Expected valid userInputText to Thinking state.")
                return
            end

            -- Make sure its the same state.
            local isSameState = function()

                -- This function is only called inside of the Promise resolvers,
                -- so we can remove the promise from the ent here.
                self.ThinkPromise = nil

                return self:GetState() == GNIL_GPT_NPC_STATE_THINKING
            end

            -- If there is somehow already a ThinkPromise, then cancel it
            -- before we overwrite it. I have no idea how this could happen,
            -- but I suppose its good just to play it safe.
            if self.ThinkPromise then
                self.ThinkPromise:Cancel()
            end

            -- Create a GPT Parameter set with the users input message.
            local gpt_params = GNIL.GPT.Classes.GPTParameters:New()
                :AddMessage(
                    userInputText,
                    "user",
                    self:GetListeningTarget():SteamID64()
                )

            -- Create the thinking promise and then wait for it to resolve.
            self.ThinkPromise = self.Brain:Think(gpt_params)
                :OnSuccess(function(data)

                    if not IsValid(self) or not isSameState() then
                        return
                    end

                    -- Here, we should have finished thinking so we start the
                    -- speaking state with the output tts data.
                    self:SetState(GNIL_GPT_NPC_STATE_SPEAKING, data.tts)

                end)
                :OnError(function(_, errorMessage)

                    if not IsValid(self) or not isSameState() then
                        return
                    end
                    self:HandleError("Failed to think: " .. errorMessage)

                end)

        end,

        ExitState = function(self)

            -- If there is a pending ThinkPromise then cancel it.
            -- This could maybe save us from an unneeded TTS request.
            if self.ThinkPromise then
                self.ThinkPromise:Cancel()
            end

        end,

        Use = function(self, ply)

            ply:ChatMessage("Go away! I'm thinking real hard.")

        end

    },

    [GNIL_GPT_NPC_STATE_SPEAKING] = {

        EnterState = function(self, ttsData)

            -- Ensure we're actually receiving valid TTS data.
            if not istable(ttsData) or #ttsData != 2 then
                self:HandleError("Expected valid ttsData to Speaking state.")
                return
            end

            -- Send the TTS data to nearby players.
            self:Speak(
                ttsData[1], -- URL
                ttsData[2]  -- Data
            )

            -- One second after we should have finished speaking, go back
            -- to the idle state and let the cycle continue once more.
            timer.Simple(ttsData[2].length + 1, function()
                if not IsValid(self) then
                    return
                end

                self:SetState(GNIL_GPT_NPC_STATE_IDLE)
            end)

        end,

        Use = function(self, ply)

            ply:ChatMessage("Hey! Don't interrupt me while I'm talking!")

        end

    }
}