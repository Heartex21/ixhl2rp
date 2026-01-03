-- Combine Terminal Interface

surface.CreateFont("CombineTerminalText", {
    font = "Consolas",
    size = 16,
    weight = 500,
    antialias = true,
})

surface.CreateFont("CombineTerminalTitle", {
    font = "Candara",
    size = 20,
    weight = 700,
    antialias = true,
})

local PANEL = {}

function PANEL:Init()
	self:SetSize(ScrW() * 0.35, ScrH() * 0.45)
	self:Center()
	self:MakePopup()
	self:SetAlpha(0)
	self:AlphaTo(255, 0.2)
	self:SetKeyboardInputEnabled(true)
	
	-- Loading state variables
	self.loadProgress = 0
	self.loadStartTime = CurTime()
	self.loadDuration = 2
	self.isLoading = true
	self.loadingTexts = {
		"INITIALIZING TERMINAL INTERFACE...",
		"CONNECTING TO NEXUS MAINFRAME...",
		"AUTHENTICATING BIOMETRIC DATA...",
		"VERIFYING CLEARANCE PROTOCOLS...",
		"LOADING CIVIL PROTECTION INDEX...",
		"SYNCING SECTOR DATABASES...",
		"RETRIEVING CITIZEN RECORDS...",
		"ESTABLISHING SECURE CONNECTION...",
		"LOADING TACTICAL INTERFACE...",
		"SYNCHRONIZING OVERWATCH DATA...",
		"ACCESSING DISPATCH NETWORK...",
		"CALIBRATING BIOMETRIC SCANNERS...",
		"LOADING SECURITY PROTOCOLS...",
		"ESTABLISHING UPLINK...",
		"FINALIZING TERMINAL ACCESS..."
	}
	
	-- Text scrolling system
	self.displayedTexts = {}
	self.nextTextIndex = 1
	self.nextTextTime = CurTime()
	self.maxVisibleLines = 6
	
	-- Closing animation
	self.isClosing = false
	self.closeStartTime = 0
	
	-- Button bounds (calculated in Paint, used in mouse detection)
	self.buttons = {
		{id = "lookout", text = "Active Lookout Index", x = 0, y = 0, w = 0, h = 0, hover = false},
		{id = "unitid", text = "Unit ID Index", x = 0, y = 0, w = 0, h = 0, hover = false},
		{id = "sociostatus", text = "Sociostatus Index", x = 0, y = 0, w = 0, h = 0, hover = false},
		{id = "surveillance", text = "Surveillance System", x = 0, y = 0, w = 0, h = 0, hover = false},
	}
	
	-- Button fade-in animation
	self.buttonsFadingIn = false
	self.buttonsFadeStartTime = 0
	self.buttonsFadeAlpha = 0
	
	-- Exit button bounds
	self.buttonX = 0
	self.buttonY = 0
	self.buttonWidth = 0
	self.buttonHeight = 0
	
	-- Hover sound tracking
	self.wasOverButton = false
end

function PANEL:Think()
	-- Handle closing fade out
	if self.isClosing then
		local elapsed = CurTime() - self.closeStartTime
		local alpha = math.max(0, 255 - (elapsed * 500))
		self:SetAlpha(alpha)
		
		if alpha <= 0 then
			self:Remove()
			return
		end
	end
	
	-- Update loading progress
	if self.isLoading then
		local elapsed = CurTime() - self.loadStartTime
		self.loadProgress = math.min(elapsed / self.loadDuration, 1)
		
		-- Add new text line
		if CurTime() >= self.nextTextTime and self.nextTextIndex <= #self.loadingTexts then
			table.insert(self.displayedTexts, {
				text = self.loadingTexts[self.nextTextIndex],
				spawnTime = CurTime()
			})
			self.nextTextIndex = self.nextTextIndex + 1
			self.nextTextTime = CurTime() + 0.2
		end
		
		-- Remove old texts if too many
		while #self.displayedTexts > self.maxVisibleLines do
			table.remove(self.displayedTexts, 1)
		end
		
		-- Loading complete, start fade out
		if self.loadProgress >= 1 and not self.fadingOut then
			self.fadingOut = true
			self.fadeStartTime = CurTime()
		end
	end
	
	-- Handle fade out of loading elements
	if self.fadingOut then
		local fadeElapsed = CurTime() - self.fadeStartTime
		local fadeProgress = math.min(fadeElapsed / 0.5, 1)
		self.loadFadeAlpha = 255 * (1 - fadeProgress)
		
		if fadeProgress >= 1 then
			self.isLoading = false
			self.fadingOut = false
			-- Start button fade in
			self.buttonsFadingIn = true
			self.buttonsFadeStartTime = CurTime()
		end
	end
	
	-- Handle button fade in
	if self.buttonsFadingIn then
		local fadeElapsed = CurTime() - self.buttonsFadeStartTime
		local fadeProgress = math.min(fadeElapsed / 0.3, 1)
		self.buttonsFadeAlpha = 255 * fadeProgress
		
		if fadeProgress >= 1 then
			self.buttonsFadingIn = false
		end
	end
end

function PANEL:Paint(width, height)
	-- Main background - blue tinted transparent
	surface.SetDrawColor(20, 40, 80, 230)
	surface.DrawRect(0, 0, width, height)
	
	-- Draw multiple white outline layers with fade effect
	local fadeTime = CurTime() % 2
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
	
	-- Horizontal scanning lines
	surface.SetDrawColor(255, 255, 255, 10)
	for y = 10, height - 10, 8 do
		surface.DrawLine(8, y, width - 8, y)
	end
	
	-- Animated scanning line (top to bottom, slow and thin)
	local scanPos = ((CurTime() * 0.05) % 1) * (height - 16) + 8
	surface.SetDrawColor(255, 255, 255, 100)
	surface.DrawLine(8, scanPos, width - 8, scanPos)
	
	-- Only draw loading elements if still loading or fading out
	if self.isLoading or self.fadingOut then
		local alpha = self.loadFadeAlpha or 255
		
		-- Draw loading texts from top to bottom
		local startY = 60
		local lineHeight = 22
		surface.SetFont("CombineTerminalText")
		
		for i, textData in ipairs(self.displayedTexts) do
			local textAge = CurTime() - textData.spawnTime
			local textY = startY + ((i - 1) * lineHeight)
			local textW = surface.GetTextSize(textData.text)
			local textX = (width - textW) / 2
			
			-- Calculate fade effect
			local textAlpha = alpha
			if textAge < 0.15 then
				-- Fade in
				textAlpha = (textAge / 0.15) * alpha
			elseif i == 1 and #self.displayedTexts > self.maxVisibleLines - 1 then
				-- Fade out top line when about to be removed
				textAlpha = alpha * 0.5
			end
			
			-- Text outline
			for ox = -1, 1 do
				for oy = -1, 1 do
					if ox != 0 or oy != 0 then
						surface.SetTextColor(0, 0, 0, textAlpha)
						surface.SetTextPos(textX + ox, textY + oy)
						surface.DrawText(textData.text)
					end
				end
			end
			
			-- Main text
			surface.SetTextColor(100, 200, 255, textAlpha)
			surface.SetTextPos(textX, textY)
			surface.DrawText(textData.text)
		end
		
		-- Loading bar (horizontal - left to right)
		local barWidth = width - 100
		local barHeight = 30
		local barX = (width - barWidth) / 2
		local barY = height / 2 + 20
		
		-- Bar background
		surface.SetDrawColor(20, 20, 40, alpha * 0.8)
		surface.DrawRect(barX, barY, barWidth, barHeight)
		
		-- Bar outline
		surface.SetDrawColor(255, 255, 255, alpha * 0.6)
		surface.DrawOutlinedRect(barX, barY, barWidth, barHeight, 2)
		
		-- Progress fill (white, left to right)
		local fillWidth = barWidth * self.loadProgress
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(barX, barY, fillWidth, barHeight)
		
		-- Progress glow
		if fillWidth > 0 then
			surface.SetDrawColor(150, 200, 255, alpha * 0.3)
			surface.DrawRect(barX, barY, fillWidth, barHeight)
		end
		
		-- Percentage text below bar
		local percentText = string.format("%d%%", math.floor(self.loadProgress * 100))
		surface.SetFont("CombineTerminalTitle")
		local percentW = surface.GetTextSize(percentText)
		local percentX = (width - percentW) / 2
		local percentY = barY + barHeight + 15
		
		-- Percentage outline
		for ox = -1, 1 do
			for oy = -1, 1 do
				if ox != 0 or oy != 0 then
					surface.SetTextColor(0, 0, 0, alpha)
					surface.SetTextPos(percentX + ox, percentY + oy)
					surface.DrawText(percentText)
				end
			end
		end
		
		surface.SetTextColor(255, 255, 255, alpha)
		surface.SetTextPos(percentX, percentY)
		surface.DrawText(percentText)
	end
	
	-- Draw main buttons (4 buttons vertically stacked on left side)
	if self.buttonsFadeAlpha > 0 then
		surface.SetFont("CombineTerminalText")
		local buttonPadding = 10
		local buttonSpacing = 10
		local startY = 80
		local leftMargin = 40
		
		-- Calculate uniform button size (based on widest text)
		local maxWidth = 0
		local buttonHeight = 0
		for i, button in ipairs(self.buttons) do
			local textW, textH = surface.GetTextSize(button.text)
			if textW > maxWidth then maxWidth = textW end
			if buttonHeight == 0 then buttonHeight = textH + (buttonPadding * 2) end
		end
		local uniformWidth = maxWidth + (buttonPadding * 2)
		
		for i, button in ipairs(self.buttons) do
			local btnX = leftMargin
			local btnY = startY + ((i - 1) * (buttonHeight + buttonSpacing))
			
			-- Store button bounds
			button.x = btnX
			button.y = btnY
			button.w = uniformWidth
			button.h = buttonHeight
			
			-- Button background (blue)
			surface.SetDrawColor(30, 60, 120, 200 * (self.buttonsFadeAlpha / 255))
			surface.DrawRect(btnX, btnY, uniformWidth, buttonHeight)
			
			-- Simple button outline
			surface.SetDrawColor(100, 150, 200, self.buttonsFadeAlpha)
			surface.DrawOutlinedRect(btnX, btnY, uniformWidth, buttonHeight, 1)
			
			-- Button text
			surface.SetTextColor(255, 255, 255, self.buttonsFadeAlpha)
			surface.SetTextPos(btnX + buttonPadding, btnY + buttonPadding)
			surface.DrawText(button.text)
		end
	end
	
	-- Exit button at bottom (always visible)
	local exitText = "SPACE - EXIT"
	surface.SetFont("CombineTerminalText")
	local exitW, exitH = surface.GetTextSize(exitText)
	
	-- Button dimensions
	local exitButtonPadding = 10
	local buttonWidth = exitW + (exitButtonPadding * 2)
	local buttonHeight = exitH + (exitButtonPadding * 2)
	local buttonX = (width - buttonWidth) / 2
	local buttonY = height - buttonHeight - 20
	
	-- Store button bounds for mouse detection
	self.buttonX = buttonX
	self.buttonY = buttonY
	self.buttonWidth = buttonWidth
	self.buttonHeight = buttonHeight
	
	-- Button background (blue)
	surface.SetDrawColor(30, 60, 120, 200)
	surface.DrawRect(buttonX, buttonY, buttonWidth, buttonHeight)
	
	-- Simple button outline
	surface.SetDrawColor(100, 150, 200, 255)
	surface.DrawOutlinedRect(buttonX, buttonY, buttonWidth, buttonHeight, 1)
	
	-- Text position (centered in button)
	local exitX = buttonX + exitButtonPadding
	local exitY = buttonY + exitButtonPadding
	
	-- Pulsing exit text
	local pulseAlpha = 200 + math.sin(CurTime() * 3) * 55
	surface.SetTextColor(255, 255, 255, pulseAlpha)
	surface.SetTextPos(exitX, exitY)
	surface.DrawText(exitText)
end

function PANEL:OnKeyCodePressed(key)
	if key == KEY_SPACE and not self.isClosing then
		self.isClosing = true
		self.closeStartTime = CurTime()
		surface.PlaySound("hl2rp/terminal-click.wav")
	end
end

function PANEL:OnMousePressed(mouseCode)
	if mouseCode == MOUSE_LEFT and not self.isClosing then
		local x, y = self:CursorPos()
		
		-- Check if click is within button bounds
		if x >= self.buttonX and x <= self.buttonX + self.buttonWidth and
		   y >= self.buttonY and y <= self.buttonY + self.buttonHeight then
			self.isClosing = true
			self.closeStartTime = CurTime()
			surface.PlaySound("hl2rp/terminal-click.wav")
		end
	end
end

function PANEL:OnCursorMoved(x, y)
	local isOverAnyButton = false
	
	-- Check main buttons
	for i, button in ipairs(self.buttons) do
		local isOver = x >= button.x and x <= button.x + button.w and
		               y >= button.y and y <= button.y + button.h
		
		if isOver then
			isOverAnyButton = true
			
			-- Play hover sound when entering button area
			if not button.hover then
				surface.PlaySound("hl2rp/passing.wav")
				button.hover = true
			end
		else
			button.hover = false
		end
	end
	
	-- Check exit button
	local isOverExitButton = x >= self.buttonX and x <= self.buttonX + self.buttonWidth and
	                         y >= self.buttonY and y <= self.buttonY + self.buttonHeight
	
	if isOverExitButton then
		isOverAnyButton = true
		
		-- Play hover sound when entering button area
		if not self.wasOverButton then
			surface.PlaySound("hl2rp/passing.wav")
			self.wasOverButton = true
		end
	else
		self.wasOverButton = false
	end
	
	-- Set cursor based on whether over any button
	if isOverAnyButton then
		self:SetCursor("hand")
	else
		self:SetCursor("arrow")
	end
end

function PANEL:OnRemove()
end

vgui.Register("ixCombineTerminal", PANEL, "DPanel")

-- Network receiver to open terminal
net.Receive("ixOpenCombineTerminal", function()
	if IsValid(ix.gui.combineTerminal) then
		ix.gui.combineTerminal:Remove()
	end
	
	ix.gui.combineTerminal = vgui.Create("ixCombineTerminal")
	
	-- Play terminal open sound
	surface.PlaySound("hl2rp/terminal-open.wav")
end)
