local Speaker = GNIL.Thirdparty.middleclass("Speaker")
ClassAccessorFunc(Speaker, {
	Name  = FuncAccessors.ReadOnly("name"),
	Color = FuncAccessors.ReadOnly("color"),
	Font = FuncAccessors.ReadOnly("font"),
	Size = FuncAccessors.ReadOnly("size"),
})

local c = Color(47,188,244)
function Speaker:Initialize(name, color, font)
	self.name = name
	self.color = color or c
	self.font = font or "ChatMessage.Small"

	surface.SetFont(self.font)
	local w, h = surface.GetTextSize(name)
	self.size = {
		wide = w,
		tall = h
	}
end

function Speaker.IsSpeaker(obj)
	return IsInstanceOf(obj, Speaker)
end

return {
	Speaker = Speaker
}