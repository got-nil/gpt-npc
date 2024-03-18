local MODULE, config = MODULE, MODULE:Config()
GNIL.GPT.Recording = GNIL.GPT.Recording or {
    ["_listening"] = {}
}

-- Only broadcast when we're not in debug mode.
local isDebug = config:Get("debug", false)
if not isDebug then
    eightbit.SetBroadcastIP(config:Get("relay_ip"))
    eightbit.SetBroadcastPort(config:Get("relay_port"))
end
eightbit.EnableBroadcast(not isDebug)

---Generate a 15 digit integer to be used as the voice_id. The total
---identifier is 17, with the last two being used for terminator control.
---Use the current time as start to reduce chances of collision.
function GNIL.GPT.Recording.GenerateID()
    local out = string.Explode("", tostring(os.time()))
    for i = 1, 15 - #out do
        table.insert(out, math.random(1, 9))
    end
    return table.concat(out)
end

---Start recording a userid.
---@param userid number
---@param voice_id string 15 digit string.
---@return boolean SuccessState
function GNIL.GPT.Recording.Start(userid, voice_id)
    assert(isnumber(userid), "The provided userid MUST be a number")
    assert(isstring(voice_id) and #voice_id == 15, "The provided voice_id MUST be a 15 digit string")

    if eightbit.IsRecording(userid) then return false end
    if eightbit.StartRecording(userid, voice_id) then
        GNIL.GPT.Recording["_listening"][tostring(userid)] = true
        return true
    end
    return false
end

---Stop recording a userid.
---@param userid number
---@param cancelled? boolean
---@return boolean SuccessState
function GNIL.GPT.Recording.Stop(userid, cancelled)
    assert(isnumber(userid), "The provided userid MUST be a number")
    assert(cancelled == nil or isbool(cancelled), "Cancelled MUST either be nil or boolean")

    if cancelled == nil then cancelled = false end
    if eightbit.StopRecording(userid, cancelled) then
        GNIL.GPT.Recording["_listening"][tostring(userid)] = nil
        return true
    end
    return false
end

---Check if we're recording a given userid.
---@param userid number
---@return boolean
function GNIL.GPT.Recording.IsRecording(userid)
    assert(isnumber(userid), "The provided userid MUST be a number")
    return eightbit.IsRecording(userid)
end

---Get all players that are being recorded.
---@param as_players? boolean Should the output be a table of Player objects?
---@return number[]|Player[] Output Table of userids, or Players if `as_players` is true.
function GNIL.GPT.Recording.AllRecording(as_players)
    local userids = {}
    for _, v in pairs(GNIL.GPT.Recording["_listening"]) do
        if v then
            table.insert(userids, v)
        end
    end
    if not as_players then
        return userids
    end

    -- Convert the userids to Players.
    local players = {}
    for _, v in ipairs(userids) do
        local ply = Player(v)
        if IsValid(ply) then
            table.insert(players, ply)
        end
    end
    return players
end

-- When a player disconnects from the server, we should
-- "stop" the voice stream. This sends ensures the terminator
-- is still sent + it deletes the userid from the C++
-- unordered_map entirely, so its basically garbage collection.
gameevent.Listen("player_disconnect")
MODULE:AddHook("player_disconnect", "GPT.Voice.GC", function(data)
    if GNIL.GPT.Recording["_listening"][tostring(data.userid)] then
        GNIL.GPT.Recording.Stop(data.userid, true)
    end
end)