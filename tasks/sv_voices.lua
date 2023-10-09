
-- Get all custom voice ids for googlecloud and elevenlabs.
-- The websocket server manages custom voices.
-- There is no request data needed, and therefore no need
-- for the validate, request functions. Its essentially a GET.

return {
    name = "tts_voices",
    response = function(_, data)

        if data.size == nil or data.voices == nil then
            return false, "Missing required attribute(s)."
        end

        return true, {
            data
        }
    end
}