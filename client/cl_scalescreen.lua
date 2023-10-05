
local ss_meta = {
    UpdateResolution = function(self) self._wide = ScrW() self._tall = ScrH() end,
    SetBase = function(self, bw, bh) self._basewide = bw self._basetall = bh end,
    Width = function(self, w) return w * (self._wide / self._basewide) end,
    Height = function(self, h) return h * (self._tall / self._basetall) end,
    Scale = function(self, w, h) return self:Width(w), self:Height(h) end,
    Font = function(self, fontname, fdata)
        local name = table.concat({fontname,".",fdata.size,"-",self._wide,"x",self._tall})
        if self._fonts[name] then
            return name
        end

        surface.CreateFont(name, {
            font = fdata.font or "Trebuchet MS",
            extended = fdata.extended or false,
            size = math.max(15, self:Height(fdata.size)),
            weight = fdata.weight or 700,
        })
        self._fonts[name] = true
        return name
    end
}
ss_meta.Wide = ss_meta.Width
ss_meta.Tall = ss_meta.Height
ss_meta.X = ss_meta.Width
ss_meta.Y = ss_meta.Height
ss_meta.__index = ss_meta

ScaleScreen = setmetatable({_wide = ScrW(),	_tall = ScrH(),	_basewide = 3840, _basetall = 1600, _fonts = {}}, ss_meta)
MODULE:AddHook("OnScreenSizeChanged", "ScaleScreen.Update", function() ScaleScreen:UpdateResolution() end)