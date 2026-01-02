surface.CreateFont("CombineDisplayLarge", {
    font = "Combine", -- or any font you want
    size = 24,            -- change this to your desired size
    weight = 500,
    antialias = true,
})

surface.CreateFont("CityCodeDisplay", {
    font = "Candara",
    size = 28,
    weight = 700,
    antialias = true,
})

surface.CreateFont("CombineSubtext", {
    font = "Candara",
    size = 16,
    weight = 500,
    antialias = true,
})

surface.CreateFont("CombineScanText", {
    font = "Consolas",
    size = 14,
    weight = 400,
    antialias = true,
})


local PANEL = {}

AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "maxLines", "MaxLines", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end

	self.lines = {}

	self:SetMaxLines(24)
	self:SetFont("CombineDisplayLarge")

	self:SetPos(6, 6) -- You can change these values to set the initial position
	self:SetSize(ScrW(), ScrH() / 2)
	self:ParentToHUD()

	ix.gui.combine = self
end

function PANEL:AddLine(text, color, expireTime, ...)
	if (#self.lines >= self.maxLines) then
		for k, info in ipairs(self.lines) do
			if (info.expireTime != 0) then
				table.remove(self.lines, k)
			end
		end
	end

	-- check for any phrases and replace the text
	if (text:sub(1, 1) == "@") then
		text = L(text:sub(2), ...)
	end

	local index = #self.lines + 1

	self.lines[index] = {
		text = "<:: Situation Index: " .. text .. " ::>",
		color = color or color_white,
		expireTime = CurTime() + 15,
		character = 1,
	}

	return index

end

function PANEL:RemoveLine(id)
	if (self.lines[id]) then
		table.remove(self.lines, id)
	end
end

function PANEL:Think()
	local x, _ = self:GetPos()
	local y = 4

	self:SetPos(x, y)
end

function PANEL:Paint(width, height)
	local textHeight = draw.GetFontHeight(self.font)
	local y = 10
	local padding = 20
	local maxWidth = ScrW() * 0.3 -- Max 30% of screen width

	surface.SetFont(self.font)

	for k, info in ipairs(self.lines) do
		if (info.expireTime != 0 and CurTime() >= info.expireTime) then
			table.remove(self.lines, k)
			continue
		end

		if (info.character < info.text:len()) then
			info.character = info.character + 1
		end
        local displayText = info.text:sub(1, info.character)
        local textWidth = surface.GetTextSize(displayText)
        
        -- Right-align with padding
        local x = ScrW() - textWidth - padding

        -- Draw outline (black, 1px offset in 8 directions)
        for ox = -1, 1 do
            for oy = -1, 1 do
                if ox ~= 0 or oy ~= 0 then
                    surface.SetTextColor(0, 0, 0, 255)
                    surface.SetTextPos(x + ox, y + oy)
                    surface.DrawText(displayText)
                end
            end
        end

        -- Draw main text
        surface.SetTextColor(info.color)
        surface.SetTextPos(x, y)
        surface.DrawText(displayText)

		y = y + textHeight
	end
end

vgui.Register("ixCombineDisplay", PANEL, "Panel")

if (IsValid(ix.gui.combine)) then
	vgui.Create("ixCombineDisplay")
end

-- City Code Display Panel
local CITYCODE_PANEL = {}

function CITYCODE_PANEL:Init()
	if (IsValid(ix.gui.citycode)) then
		ix.gui.citycode:Remove()
	end

	self:SetSize(400, 150)
	self:SetPos(20, 20)
	self:ParentToHUD()

	self.scanlinePos = 0
	self.scanlineStart = CurTime()
	
	-- Status messages that rotate
	self.statusMessages = {
		"BIOTICS NOMINAL",
		"STABILIZATION ACTIVE",
		"SECTOR COMPLIANCE: OPTIMAL",
		"SYNTH OVERSIGHT: ENABLED",
		"CITIZEN PROCESSING: NORMAL",
		"CONTAINMENT PROTOCOLS: GREEN",
		"CIVIL AUTHORITY: MAINTAINED"
	}
	self.currentStatus = 1
	self.nextStatusChange = CurTime() + 4
	
	-- Pulse animation variables
	self.pulseAlpha = 0
	self.pulseTime = 0
	self.lastCityCode = Schema:GetCityCode()

	ix.gui.citycode = self
end

function CITYCODE_PANEL:Paint(width, height)
	-- Only show for Metropolice and OTA
	local char = LocalPlayer():GetCharacter()
	if not char then return end
	
	local faction = char:GetFaction()
	if faction != FACTION_MPF and faction != FACTION_OTA then return end

	-- Get current city code
	local currentCode = Schema:GetCityCode()
	local codeData = Schema:GetCityCodeInfo(currentCode)
	if not codeData then return end
	
	-- Check for city code change and trigger pulse
	if currentCode != self.lastCityCode then
		self.pulseAlpha = 255
		self.pulseTime = CurTime()
		self.lastCityCode = currentCode
		surface.PlaySound("buttons/button17.wav")
	end
	
	-- Update pulse animation (fade out over 1 second)
	if self.pulseAlpha > 0 then
		local pulseProgress = CurTime() - self.pulseTime
		self.pulseAlpha = math.max(0, 255 - (pulseProgress * 255))
	end
	
	-- Update status message rotation
	if CurTime() >= self.nextStatusChange then
		self.currentStatus = (self.currentStatus % #self.statusMessages) + 1
		self.nextStatusChange = CurTime() + 4
	end

	-- Background: transparent black
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(0, 0, width, height)
	
	-- Pulse overlay effect when code changes
	if self.pulseAlpha > 0 then
		surface.SetDrawColor(codeData.color.r, codeData.color.g, codeData.color.b, self.pulseAlpha * 0.3)
		surface.DrawRect(0, 0, width, height)
	end

	-- Draw multiple white outline layers with fade effect
	local fadeTime = CurTime() % 2 -- 2 second loop for fade
	local fadeAlpha = math.abs(math.sin(fadeTime * math.pi))

	-- Outer outlines (fade in/out)
	for i = 1, 4 do
		local alpha = 30 + (fadeAlpha * 20)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawOutlinedRect(i, i, width - i * 2, height - i * 2, 1)
	end

	-- Inner solid outline
	surface.SetDrawColor(255, 255, 255, 100)
	surface.DrawOutlinedRect(5, 5, width - 10, height - 10, 2)

	-- Top left scanning text (changes every 0.1 seconds)
	local scanChange = math.floor(CurTime() * 10) -- Updates 10 times per second
	local hexVal1 = string.format("%04X", (scanChange * 1337) % 65536)
	local hexVal2 = string.format("%04X", (scanChange * 2741) % 65536)
	local hexVal3 = string.format("%02X", (scanChange * 17) % 256)
	
	local scanText = string.format("SCAN: 0x%s-%s-%s", hexVal1, hexVal2, hexVal3)
	
	surface.SetFont("CombineScanText")
	
	-- Draw scan text outline
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox != 0 or oy != 0 then
				surface.SetTextColor(0, 0, 0, 200)
				surface.SetTextPos(15 + ox, 15 + oy)
				surface.DrawText(scanText)
			end
		end
	end
	
	-- Draw main scan text (cyan-ish with flicker)
	local flickerAlpha = 200 + math.sin(CurTime() * 15) * 55
	surface.SetTextColor(100, 200, 255, flickerAlpha)
	surface.SetTextPos(15, 15)
	surface.DrawText(scanText)
	
	-- Top right time/date display
	local dateObj = os.date("*t")
	local dayOfYear = dateObj.yday
	local combineTime = string.format("D.%03d.%02d:%02d:%02d", dayOfYear, dateObj.hour, dateObj.min, dateObj.sec)
	
	surface.SetFont("CombineScanText")
	local timeWidth = surface.GetTextSize(combineTime)
	
	-- Draw time outline
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox != 0 or oy != 0 then
				surface.SetTextColor(0, 0, 0, 200)
				surface.SetTextPos(width - timeWidth - 15 + ox, 15 + oy)
				surface.DrawText(combineTime)
			end
		end
	end
	
	-- Draw main time text (amber)
	surface.SetTextColor(255, 180, 50, 220)
	surface.SetTextPos(width - timeWidth - 15, 15)
	surface.DrawText(combineTime)

	-- Draw horizontal scanning lines
	surface.SetDrawColor(255, 255, 255, 15)
	for y = 10, height - 10, 8 do
		surface.DrawLine(8, y, width - 8, y)
	end

	-- Animated scanning line (8 second loop)
	local scanDuration = 8
	local timeSinceScan = (CurTime() - self.scanlineStart) % scanDuration
	self.scanlinePos = (timeSinceScan / scanDuration) * (width - 16) + 8

	-- Draw scanning line with glow
	for i = 1, 3 do
		local alpha = 100 - (i * 25)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawLine(self.scanlinePos - i, 10, self.scanlinePos - i, height - 10)
		surface.DrawLine(self.scanlinePos + i, 10, self.scanlinePos + i, height - 10)
	end
	surface.SetDrawColor(255, 255, 255, 150)
	surface.DrawLine(self.scanlinePos, 10, self.scanlinePos, height - 10)

	-- Draw city code text with brackets
	local displayText = "<<:: " .. codeData.name .. " ::>>"
	surface.SetFont("CityCodeDisplay")
	local textWidth, textHeight = surface.GetTextSize(displayText)
	
	local textX = (width - textWidth) / 2
	local textY = (height - textHeight) / 2

	-- Text outline with fade effect (black)
	local textFadeAlpha = math.abs(math.sin((CurTime() % 1.5) * math.pi))
	for ox = -3, 3 do
		for oy = -3, 3 do
			if ox != 0 or oy != 0 then
				local dist = math.sqrt(ox * ox + oy * oy)
				local alpha = (100 + textFadeAlpha * 50) * (1 - dist / 4)
				surface.SetTextColor(0, 0, 0, alpha)
				surface.SetTextPos(textX + ox, textY + oy)
				surface.DrawText(displayText)
			end
		end
	end

	-- Main text (green)
	surface.SetTextColor(codeData.color.r, codeData.color.g, codeData.color.b, 255)
	surface.SetTextPos(textX, textY)
	surface.DrawText(displayText)
	
	-- Status message below city code
	local statusText = self.statusMessages[self.currentStatus]
	surface.SetFont("CombineScanText")
	local statusWidth, statusHeight = surface.GetTextSize(statusText)
	
	local statusX = (width - statusWidth) / 2
	local statusY = textY + textHeight + 10
	
	-- Status text outline
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox != 0 or oy != 0 then
				surface.SetTextColor(0, 0, 0, 180)
				surface.SetTextPos(statusX + ox, statusY + oy)
				surface.DrawText(statusText)
			end
		end
	end
	
	-- Main status text (dim white)
	surface.SetTextColor(180, 180, 180, 200)
	surface.SetTextPos(statusX, statusY)
	surface.DrawText(statusText)

	-- Bottom left combine text
	local combineText = "SECTOR.OVERWATCH.17 // SYNTH.CTRL.ACTIVE"
	surface.SetFont("CombineSubtext")
	local subtextWidth, subtextHeight = surface.GetTextSize(combineText)
	
	-- Position at bottom left with padding
	local subtextX = 15
	local subtextY = height - subtextHeight - 15

	-- Draw subtext outline
	for ox = -1, 1 do
		for oy = -1, 1 do
			if ox != 0 or oy != 0 then
				surface.SetTextColor(0, 0, 0, 200)
				surface.SetTextPos(subtextX + ox, subtextY + oy)
				surface.DrawText(combineText)
			end
		end
	end

	-- Draw main subtext (dim white)
	surface.SetTextColor(150, 150, 150, 180)
	surface.SetTextPos(subtextX, subtextY)
	surface.DrawText(combineText)
end

vgui.Register("ixCityCodeDisplay", CITYCODE_PANEL, "Panel")

-- Create city code display
hook.Add("InitPostEntity", "ixCreateCityCodeDisplay", function()
	timer.Simple(1, function()
		if IsValid(ix.gui.citycode) then
			ix.gui.citycode:Remove()
		end
		vgui.Create("ixCityCodeDisplay")
	end)
end)
