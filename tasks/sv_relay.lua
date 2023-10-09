local tts_url = MODULE:Config():Get("tts_url")

return {
    name = "voice_relay",
    validate = function(recorder)
        if not recorder.IsInstanceOf then return false end
        return recorder:IsInstanceOf(GNIL.GPT.Classes.Recorder)
    end,
    request = function(_, recorder)

        -- Always return a set structure just incase.
        local tbl = recorder:ToTable()
        return true, {
            ["voice_id"] = tbl.voice_id,
            ["raw"] = tbl.raw
        }
    end,
    response = function(_, data)

        -- Handle different types of response types.
        local types = {
            ["transcription"] = {"text"},
            ["raw"] = {"filename", function(v) return tts_url .. "/" .. v end}
        }
        local argument = types[data.type][1]
        if not argument then
            return false, "Invalid relay response type '" .. tostring(data.type) .. "'"
        end
        if not isstring(data[argument]) then
            return false, "Required type argument '" .. argument .. "' is invalid"
        end

        -- Specifically to allow the raw type to have a formatted
        -- URL, but could maybe be used more in future?
        local value = data[argument]
        if #types[data.type] > 1 then
            value = types[data.type][2](value)
        end

        return true, {
            value,
            data.type
        }
    end
}
