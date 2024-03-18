
-- Random data that is used for NPC set generation.
local data = {

    Models = {
        ["male"] = {
            "models/Humans/Group01/Male_01.mdl",
            "models/Humans/Group01/Male_02.mdl",
            "models/Humans/Group01/Male_03.mdl",
            "models/Humans/Group01/Male_04.mdl",
            "models/Humans/Group01/Male_05.mdl",
            "models/Humans/Group01/Male_06.mdl",
            "models/Humans/Group01/Male_07.mdl",
            "models/Humans/Group01/Male_08.mdl",
            "models/Humans/Group01/Male_09.mdl"
        },

        ["female"] = {
            "models/Humans/Group01/Female_01.mdl",
            "models/Humans/Group01/Female_02.mdl",
            "models/Humans/Group01/Female_03.mdl",
            "models/Humans/Group01/Female_04.mdl",
            "models/Humans/Group01/Female_06.mdl"
        }
    }

}

-- Sequential random.
local function randomValue(tbl)
    return tbl[math.random(1, #tbl)]
end

function ENT.GetRandomData()

    local gender = math.random(0, 1) == 0 && "male" || "female"
    return {
        ["Gender"] = gender,
        ["Model"] = randomValue(data.Models[gender])
    }
end