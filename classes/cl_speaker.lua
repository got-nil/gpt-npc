local Speaker = GNIL.Thirdparty.middleclass("Speaker")
ClassAccessorFunc(Speaker, {
	Name  = FuncAccessors.ReadOnly("name"),
	Color = FuncAccessors.ReadOnly("color"),
	Font = FuncAccessors.ReadOnly("font"),
	Size = FuncAccessors.ReadOnly("size"),
})

function Speaker:Initialize(name, color, font)
	self.name = name
	self.color = color
	self.font = font

	surface.SetFont(font)
	local w, h = surface.GetTextSize(name)
	self.size = {
		wide = w,
		tall = h
	}
end

function IsSpeaker(obj)
	return IsInstanceOf(obj, Speaker)
end

return {
	Speaker = Speaker
}