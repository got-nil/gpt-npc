local MODULE, config = MODULE, MODULE:Config()
GNIL.GPT.Voice = GNIL.GPT.Voice or {
    ["_listening"] = {}
}

eightbit.SetBroadcastIP(config:Get("relay_ip"))
eightbit.SetBroadcastPort(config:Get("relay_port"))
eightbit.EnableBroadcast(true)

function GNIL.GPT.Voice.Start(userid, voice_id)
    assert(isnumber(userid), "The provided userid MUST be a number")
    assert(isnumber(voice_id), "The provided voice_id MUST be a number")

    if eightbit.IsRecording(userid) then return false end
    if eightbit.StartRecording(userid, voice_id) then
        GNIL.GPT.Voice["_listening"][tostring(userid)] = true
        return true
    end 
    return false
end

function GNIL.GPT.Voice.Stop(userid, cancelled)
    assert(isnumber(userid), "The provided userid MUST be a number")
    assert(cancelled == nil or isbool(cancelled), "Cancelled MUST either be nil or boolean")
    
    if cancelled == nil then cancelled = false end    
    if eightbit.StopRecording(userid, cancelled) then
        GNIL.GPT.Voice["_listening"][tostring(userid)] = nil
        return true
    end
    return false
end

function GNIL.GPT.Voice.IsRecording(userid)
    assert(isnumber(userid), "The provided userid MUST be a number")
    return eightbit.IsRecording(userid)
end

function GNIL.GPT.Voice.AllRecording(as_players)
    local userids = {}
    for k, v in pairs(GNIL.GPT.Voice["_listening"]) do
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
        if ply:IsValid() then
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
    if GNIL.GPT.Voice["_listening"][tostring(data.userid)] then
        GNIL.GPT.Voice.Stop(data.userid, true)
    end
end)