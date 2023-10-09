local tts_url = MODULE:Config():Get("tts_url")

return {
    name = "tts",
    validate = function(text, tts_params)
        if not isstring(text) then return false end
        if not tts_params.IsInstanceOf then return false end
        return tts_params:IsInstanceOf(GNIL.GPT.Classes.TTSParameters)
    end,
    request = function(_, text, tts_params)

        -- Default to Google Cloud (cheaper) if there
        -- is no set speech provider (required argument).
        local tbl, provider = tts_params:ToTable(), GNIL_GPT_SPEECH_PROVIDER_GOOGLECLOUD
        if tbl.provider != nil then provider = tbl.provider end

        return true, {
            ["provider"] = tostring(provider),
            ["voice_id"] = tbl.voice_id,
            ["language"] = tbl.language,
            ["gender"] = tbl.gender,
            ["text"] = text
        }
    end,
    response = function(_, data)

        -- Get filename to add to TTS URL path.
        if not data.filename then
            return false, "Failed to get output TTS filename"
        end
        return true, {
            tts_url .. "/" .. data.filename,
            data.out
        }
    end
}