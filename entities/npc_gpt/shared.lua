ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PrintName = "GPT NEW"
ENT.Author = math.random(0, 1) == 0 && "morgverd & Virtualraptor" || "Virtualraptor & morgverd"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

MODULE:IncludeDirectory("entities/npc_gpt/extended")

-- c:
ENT.STATE = {
    [1] = "Idle",
    [2] = "Listening",
    [3] = "Thinking",
    [4] = "Talking",
    [5] = "Generic",
    ["Idle"] = 1,
    ["Listening"] = 2,
    ["Thinking"] = 3,
    ["Talking"] = 4,
    ["Generic"] = 5,
}

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "AIState")
    self:NetworkVar("Int", 1, "Age")
    self:NetworkVar("Int", 2, "CurrentState")
    self:NetworkVar("String", 0, "DisplayName")
    self:NetworkVar("String", 1, "Mood")
    self:NetworkVar("String", 2, "CountryCode")
    self:NetworkVar("String", 3, "Gender")
    self:NetworkVar("Entity", 0, "ListeningTarget")
    self:NetworkVar("Vector", 0, "NameColor")
    self:NetworkVar("Vector", 1, "TextColor")
    self:NetworkVar("Bool", 0, "IsFeminine")
end