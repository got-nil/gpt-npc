local MODULE = MODULE
local ScrW, ScrH = ScrW, ScrH
local ss = GNIL.UI.ScreenScale

local terms_of_service_text = [[Non at nisi nemo illo ad. Exercitationem repudiandae asperiores est et temporibus est est veniam. Modi ab et similique dicta quos odit dicta delectus debitis. Est voluptatem dolorum dolorem sunt ipsam qui vitae. Ut soluta voluptates reiciendis.
Sed ullam dolore qui quia corrupti sed. Accusantium laborum labore ea unde. Omnis saepe dolor et sunt. Id impedit rem sit perferendis quod. Qui est mollitia dignissimos nostrum facilis. Natus fuga et aut eaque consequuntur laborum repudiandae itaque occaecati.
Consectetur aut aliquam dolorem quo. Fugiat dolores rerum possimus. Repellat ut cum. Reiciendis cum reprehenderit ut. Quia ea dignissimos et. Eum eveniet voluptatem. Consequuntur quae cumque. Fuga rem asperiores ipsam quis. In doloremque quo repudiandae ipsa recusandae eius voluptatem similique et.

Reprehenderit doloribus et laboriosam autem. Eum ratione reprehenderit est. Nobis dolorem voluptatem voluptatem suscipit accusantium. Qui temporibus animi vel sit quo autem dolores.
Enim officia a mollitia dignissimos itaque ut et. Est ipsum sit qui a et ex. Adipisci sit et vero minus consequuntur expedita. Inventore esse cum eius assumenda.Adipisci aut sed ipsa perferendis velit enim a quia sunt. Porro molestiae perferendis voluptates autem. Laudantium sed similique quia. Delectus voluptatem quas eum voluptatem. Sint in libero.

Reiciendis eveniet doloremque laudantium. Voluptatem explicabo aut consectetur eaque dolorem. Magni ipsam doloribus tenetur atque velit sit aliquam. Magnam rerum quia incidunt qui.
Eos doloribus omnis delectus molestias sit veritatis odio. Tempora voluptatem aspernatur eveniet molestiae nemo delectus ex. Et ex placeat. Magni ut et nesciunt aut nostrum vel.Id eos quam nostrum quis quia iste in. Qui dicta ut delectus facere porro libero et ex. Dolor beatae tempora itaque rerum autem molestiae repudiandae. Quidem sed dolor officiis dolor necessitatibus. Et sunt molestiae doloribus.
Et incidunt iste corporis est et qui qui et. Repudiandae temporibus sequi ab aut sed. Rem explicabo sequi aut amet quidem expedita deserunt ullam pariatur. Dicta adipisci eum voluptatibus minima optio sit. Sapiente reprehenderit esse molestiae. Sed repudiandae voluptatum minima corporis hic quod eum.
Dignissimos voluptatem qui recusandae libero sunt repudiandae fuga dicta. Sint asperiores tempora quisquam. Autem minus quibusdam.Autem eligendi tempora vero. Beatae nesciunt occaecati. Similique facere et qui iste magnam quia quis. Velit beatae maiores adipisci.

Ad voluptatem aperiam corrupti magnam voluptatem ullam. Voluptatem ea dolorem sed asperiores et rerum a dolores. Reiciendis id qui cum. Corrupti optio reprehenderit iure necessitatibus ut quaerat est placeat totam. Esse exercitationem et minima ipsa recusandae aut. Qui et maiores velit consequatur dolore.

Quia voluptatem consequatur voluptas. Ratione necessitatibus repudiandae voluptates cupiditate saepe. Facilis ut rerum ducimus sit temporibus nemo natus sint.]]

local tos_accept_text = "I, {NAME}, hereby acknowledge that by clicking \"I Agree\" or accessing and using the services, I have read and fully understand the terms of service, including all terms and conditions, policies, guidelines, and any other relevant information provided by the company. I consent to be bound by these terms and agree to comply with all applicable laws and regulations. If I do not agree with any of these terms, I will not use the services. My continued use of the services after the effective date of any modifications to the terms constitutes my acceptance of such modifications."

local alert = Material("virtualraptor/images/alert.png", "smooth mips")
local gtl = Material("virtualraptor/gradients/topleft.png", "smooth mips")
local gbr = Material("virtualraptor/gradients/bottomright.png", "smooth mips")
local backarrow = Material("virtualraptor/icons/expand_less.png", "smooth mips")
local background_material = Material("virtualraptor/gradients/flame.png", "smooth noclamp")
local gradient_bottom = Material("virtualraptor/gradients/bottom.png", "smooth noclamp")
local c = {
	white = color_white,
	info_back = Color(207,207,207,14),
	hover_blue = Color(124,192,255),
	back_grey = Color(160,160,160),
	whiteish = Color(235,235,235),
	tint_grey = Color(105,105,105),
	accept_green = Color(40,184,27),
	accept_tint_hover = Color(119,236,109),
	accept_tint_idle = Color(21,116,12),
	white_tint = Color(199,199,199),
	back_black = Color(44,44,44),
	back_gradient_bottom = Color(139,139,139, 26),
	back_icon_black = Color(34,34,34, 100),
	alert_red = Color(184,27,27),
}

--[[
	TOS UI
--]]

local PANEL = {}

function PANEL:Init()
	self:ShowCloseButton(false)
	self:SetTitle("")
	self:DockPadding(ss(50),ss(50),ss(50),ss(50))
	self:MakePopup()
	self.positionY = ScrH()

	local container = self:Add("DPanel")
	self.container = container
	container:Dock(FILL)
	container.Paint  = function() end
	--[[
		Terms of Serice page
		Start
	--]]
	local tos = container:Add("DPanel")
	self.tos = tos
	tos:SetVisible(false)
	tos.animationDelta = 1
	tos:DockPadding(ss(15),ss(45),ss(15),ss(15))
	tos.Paint = function(slf,w,h)
		draw.RoundedBox(0,0,0,w,h,c["info_back"])
	end
	function tos:PerformLayout(w,h)
		if IsValid(container) then
			self:SetSize(container:GetSize())
		end
	end

	local back = tos:Add("DButton")
	back:SetSize(ss(65),ss(35))
	back:SetPos(ss(10),ss(10))
	back:SetText("")
	function back:Paint(w,h)
		surface.SetDrawColor(c["white"])
		surface.SetMaterial(backarrow)
		local size = h
		for i = 1, 5 do
			surface.DrawTexturedRectRotated(-size + size + i * ss(11), h * .5 + (self:IsHovered() and math.sin(CurTime() * 4 + (i * 5)) * 3 or 0),size,size,90)
		end
	end

	back.DoClick = function()
		local info = self.info
		tos.fading = true
		info.fading = true
		info:SetVisible(true)
		tos:CreateAnimation(.75, {
			index = 1,
			target = {animationDelta = 1},
			easing = "inOutQuad",
			Think = function(slf,pnl)
				pnl:SetY(-pnl:GetParent():GetTall() * pnl.animationDelta)
			end,
			OnComplete = function(slf, pnl)
				pnl:SetVisible(false)
				pnl.fading = true
			end
		})
		info:CreateAnimation(.75, {
			index = 1,
			target = {animationDelta = 0},
			easing = "inOutQuad",
			Think = function(slf,pnl)
				pnl:SetY(pnl:GetParent():GetTall() * pnl.animationDelta)
			end,
			OnComplete = function(slf, pnl)
				pnl:SetVisible(true)
				pnl.fading = true
			end
		})
	end

	local tos_scroll = tos:Add("DScrollPanel")
	tos_scroll:Dock(FILL)

	local tos_text = tos_scroll:Add("DTextEntry")
	tos_text:SetText(terms_of_service_text)
	tos_text:SetFont("gpt.tos.TextSmaller")
	tos_text:Dock(FILL)
	tos_text:SetPaintBackground( false )
	tos_text:SetTextColor(c["white"])
	tos_text:SetMultiline(true)
	tos_text:SetDisabled(true)
	function tos_text:PerformLayout(w,h)
		self:SetTall(1e4)
	end

	--[[
		Terms of Serice page
		End
	--]]


	--[[
		Main page
		Start
	--]]
	local info = container:Add("DPanel")
	self.info = info
	info:SetVisible(true)
	info.animationDelta = 0
	info:DockPadding(ss(15),ss(15),ss(15),ss(15))
	info.Paint = function(slf,w,h)
		draw.RoundedBox(0,0,0,w,h,c["info_back"])

	end
	function info:PerformLayout(w,h)
		if IsValid(container) then
			self:SetSize(container:GetSize())
			if self.fading then
				self:SetY(container:GetTall() * self.animationDelta)
			end
		end
	end

	local title = info:Add("DLabel")
	self.title = title
	title:Dock(TOP)
	title:DockMargin(0,0,0,ss(30))
	title:SetTextColor(c["white"])
	title:SetContentAlignment(5)
	title:SetFont("gpt.tos.Title")
	title:SetText("TERMS OF SERVICE")
	title:SizeToContents()
	title.Paint = function(slf,w,h)
		surface.SetDrawColor(c["white"])
		surface.DrawRect(0,h - ss(5),w,ss(5))
	end

	local desc = info:Add("DLabel")
	self.desc = desc
	desc:Dock(TOP)
	desc:SetTextColor(c["white"])
	desc:DockMargin(0,ss(10),0,0)
	desc:SetFont("gpt.tos.Text")
	desc:SetContentAlignment(5)
	desc:SetWrap(true)
	desc:SetAutoStretchVertical(true)
	desc:SetText(string.Interpolate(tos_accept_text, {NAME = LocalPlayer():Name()}))
	desc:DockMargin(0,0,0,ss(20))

	local expand = info:Add("DLabel")
	expand:Dock(TOP)
	expand:DockMargin(0,0,0,ss(5))
	expand:SetTextColor(c["white"])
	expand:SetFont("gpt.tos.Text")
	expand:SetWrap(true)
	expand:SetAutoStretchVertical(true)
	expand:SetKeyboardInputEnabled( true )
	expand:SetMouseInputEnabled( true )
	expand:SetText("I reaffirm my obligation to abide by GotNil's")

	local tos_button = expand:Add("DButton")
	tos_button:SetTextColor(c["white"])
	tos_button:SetFont("gpt.tos.TextHeavy")
	tos_button:SetText("Terms of Service")
	tos_button:SizeToContents() -- lol
	tos_button:SetText("")
	tos_button:MoveToAfter(expand)
	function tos_button:PerformLayout(w,h)
		surface.SetFont("gpt.tos.Text")
		local tw,_ = surface.GetTextSize(expand:GetText())
		self:SetX(tw)
		self:SetY(-4)
	end
	function tos_button:Paint(w,h)
		local col = self:IsHovered() and c["hover_blue"] or c["white"]
		local _,th = draw.SimpleText("Terms of Service", "gpt.tos.TextHeavy", w * .5, h * .5, col,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		surface.SetDrawColor(col)
		surface.DrawLine(ss(3),th - ss(2),w-ss(3),th-ss(2) )
	end

	function tos_button:DoClick()
		tos.fading = true
		info.fading = true
		tos:SetVisible(true)
		tos:CreateAnimation(.75, {
			index = 1,
			target = {animationDelta = 0},
			easing = "inOutQuad",
			Think = function(slf,pnl)
				pnl:SetY(-pnl:GetParent():GetTall() * pnl.animationDelta)
			end,
			OnComplete = function(slf,pnl)
				pnl:SetVisible(true)
				pnl.fading = true
			end
		})
		info:CreateAnimation(.75, {
			index = 1,
			target = {animationDelta = 1},
			easing = "inOutQuad",
			Think = function(slf, pnl)
				pnl:SetY(pnl:GetParent():GetTall() * pnl.animationDelta)
			end,
			OnComplete = function(slf,pnl)
				pnl:SetVisible(false)
				pnl.fading = true
			end
		})
	end

	local decline = info:Add("DButton")
	decline:Dock(BOTTOM)
	decline:DockMargin(0,ss(10),0,0)
	decline:MoveBelow( desc, ss(0) )
	decline:SetFont("gpt.tos.Button")
	decline:SizeToContents()
	decline:SetText("I Disagree")
	decline:SetTextColor(c["white"])
	decline.Paint = function(slf,w,h)
		GNIL.UI.DrawRoundedMask(ss(5),0,0,w,h, function()
			surface.SetDrawColor(c["back_grey"])
			surface.DrawRect(0,0,w,h)
			local tint = slf:IsHovered() and c["whiteish"] or c["tint_grey"]
			surface.SetDrawColor(tint)
			surface.SetMaterial(gtl)
			surface.DrawTexturedRect(0,0,w * .5,h)
			surface.SetMaterial(gbr)
			surface.DrawTexturedRect(w - w * .5,0,w * .5,h)
		end)
	end
	decline.DoClick = function()
		if isfunction(self.TOSDeny) then
			self:TOSDeny()
		end
		self:CreateAnimation(.75, {
			index = 1,
			target = {positionY = ScrH() + self:GetTall() * 1.1},
			easing = "inOutQuad",
			Think = function(slf,pnl)
				pnl:SetY(pnl.positionY)
			end,
			OnComplete = function(anim, pnl)
				self:Close()
			end
		})
	end

	local accept = info:Add("DButton")
	accept:Dock(BOTTOM)
	accept:MoveBelow( desc, ss(0) )
	accept:SetFont("gpt.tos.Button")
	accept:SizeToContents()
	accept:SetText("I Agree")
	accept:SetTextColor(c["white"])
	accept.Paint = function(slf,w,h)
		GNIL.UI.DrawRoundedMask(ss(5),0,0,w,h, function()
			surface.SetDrawColor(c["accept_green"])
			surface.DrawRect(0,0,w,h)
			local tint = slf:IsHovered() and c["accept_tint_hover"] or c["accept_tint_idle"]
			surface.SetDrawColor(tint)
			surface.SetMaterial(gtl)
			surface.DrawTexturedRect(0,0,w * .5,h)
			surface.SetMaterial(gbr)
			surface.DrawTexturedRect(w - w * .5,0,w * .5,h)
		end)
	end
	accept.DoClick = function()
		if isfunction(self.TOSAccept) then
			self:TOSAccept()
		end
		self:CreateAnimation(.75, {
			index = 1,
			target = {positionY = ScrH() + self:GetTall() * 1.1},
			easing = "inOutQuad",
			Think = function(slf,pnl)
				pnl:SetY(pnl.positionY)
			end,
			OnComplete = function(anim, pnl)
				self:Close()
			end
		})
	end
	--[[
		Main page
		End
	--]]
end

local move_scale = .05
local scale = 6

function PANEL:Paint(w,h)
	local oc = DisableClipping(true)

	GNIL.UI.DrawRoundedExMask(h * .05,0,0,w,h, function()
		surface.SetDrawColor(c["white_tint"])
		surface.DrawRect(0,0,w,h)
	end,false,true,true,false)

	GNIL.UI.DrawRoundedExMask(h * .05,1,1,w - 2,h - 2, function()
		surface.SetDrawColor(c["back_black"])
		surface.DrawRect(1,1,w - 2,h - 2)

		surface.SetMaterial(gradient_bottom)
		surface.SetDrawColor(c["back_gradient_bottom"])
		surface.DrawTexturedRect(2,2, w - 4, h - 4)

		surface.SetMaterial(background_material)
		surface.SetDrawColor(c["back_icon_black"])
		local off = (CurTime() * move_scale) % 90
		local wscale = w / h
		surface.DrawTexturedRectUV( 1,1,w - 2,h - 2, off, off, (scale * wscale) + off, scale + off )
	end,false,true,true,false)

	surface.SetDrawColor(c["alert_red"])
	surface.SetMaterial(alert)

	local s = ss(120)
	surface.DrawTexturedRectRotated( ss(15),0, s, s,14 + math.cos(CurTime() * 3) * 5)

	DisableClipping(oc)
end

function PANEL:TOSAccept() end
function PANEL:TOSDeny() end

vgui.Register("gpt_tos_form",PANEL,"DFrame")