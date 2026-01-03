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

surface.CreateFont("CombineTerminalSmall", {
    font = "Consolas",
    size = 7.8,
    weight = 400,
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
	
	-- Active panel tracking
	self.activePanel = nil
	self.panelFadeAlpha = 0
	self.panelFading = false	self.panelFadingOut = false	self.panelFadeStart = 0
	self.nextPanel = nil
	
	-- Scrollbar tracking
	self.scrollPosition = 0
	self.isDraggingScrollbar = false
	
	-- Unit entries for Unit ID Index panel
	self.unitEntries = {}
	
	-- BOL entries for lookout panel
	self.bolEntries = {
		{id = "#19342", reason = "Anti-Citizen Activity", time = "14:32"},
		{id = "#19341", reason = "Contraband Possession", time = "14:28"},
		{id = "#19340", reason = "Unauthorized Zone Entry", time = "14:15"},
		{id = "#19339", reason = "Resisting Compliance", time = "14:02"},
		{id = "#19338", reason = "Assault on CP Unit", time = "13:47"},
		{id = "#19337", reason = "Curfew Violation", time = "13:23"},
		{id = "#19336", reason = "Unregistered Biometrics", time = "13:10"},
		{id = "#19335", reason = "Black Market Activity", time = "12:55"},
		{id = "#19334", reason = "Civil Discord", time = "12:38"},
		{id = "#19333", reason = "Unauthorized Communication", time = "12:19"},
		{id = "#19332", reason = "Restricted Area Breach", time = "11:54"},
		{id = "#19331", reason = "Malcompliance", time = "11:32"},
	}
	
	-- Info box scrolling text
	self.infoBoxTexts = {
		"[NEXUS] MAINFRAME STATUS: OPERATIONAL",
		"[OVERWATCH] TACTICAL SWEEP GRID: SECTOR-17",
		"[BIOMETRICS] SCANNING FREQUENCY: 2.4 GHz",
		"[DISPATCH] UNIT DEPLOYMENT: CODE-TANGO-4",
		"[SURVEILLANCE] CAMERA ARRAY: 847 FEEDS ACTIVE",
		"[SECURITY] PERIMETER BREACH: NIL",
		"[CITIZEN] COMPLIANCE INDEX: 94.7%",
		"[RATION] DISTRIBUTION CYCLE: 18:00 HRS",
		"[CONTRABAND] SCAN RESULTS: 3 VIOLATIONS LOGGED",
		"[NETWORK] UPLINK LATENCY: 12ms",
		"[SYSTEM] CPU UTILIZATION: 67%",
		"[MEMORY] CACHE STATUS: 2.4/8.0 GB",
		"[PATROL] ROUTE-DELTA: WAYPOINT 7/12",
		"[BIOSIGNAL] TRACKING 1,847 ENTITIES",
		"[ALERT] PRIORITY-3: MISCOUNT DETECTED",
		"[DATABASE] CITIZEN RECORDS: SYNCING...",
		"[CIVIL PROTECTION] ACTIVE UNITS: 42",
		"[OVERWATCH] TRANSHUMAN ARM: STANDBY",
		"[SECTOR] LOCKDOWN STATUS: GREEN",
		"[RESTRICTION] ZONE-9: AUTHORIZED ONLY",
		"[STABILIZATION] FIELD INTEGRITY: 99.2%",
		"[SOCIO-CREDIT] PROCESSED: 3,421 TRANSACTIONS",
		"[TRIBUNAL] PENDING CASES: 17",
		"[LOYALIST] REGISTRY UPDATE: 6 NEW ENTRIES",
		"[VORTIGAUNT] LABOR ASSIGNMENTS: 89 ACTIVE",
		"[TRAIN] DEPARTURE SCHEDULE: ON TIME",
		"[COMMUNICATION] CHANNELS: ENCRYPTED",
		"[HEALTH] MEDICAL STATION: 4 PATIENTS",
		"[CHECKPOINT] SCANS COMPLETED: 1,204",
		"[ANTI-CITIZEN] WATCHLIST: 34 FLAGGED",
		"[HOUSING] BLOCK ASSIGNMENTS: UPDATED",
		"[WORK] SHIFT SCHEDULE: ACTIVE",
		"[TRANSIT] SYSTEM DELAYS: NONE",
		"[CURFEW] ENFORCEMENT: 22:00 HRS",
		"[SCANNER] PATROL UNITS: 12 DEPLOYED",
		"[MANHACK] RESERVE: 847 UNITS READY",
		"[APC] TRANSPORT: ROUTE BRAVO-3",
		"[TURRET] DEFENSE GRID: ARMED",
		"[FORCEFIELD] BARRIERS: ENERGIZED",
		"[PROPAGANDA] BROADCAST: LOOP 4/12",
	}
	self.infoBoxDisplayed = {}
	self.infoBoxNextIndex = 1
	self.infoBoxNextTime = 0
	self.infoBoxMaxLines = 14
end

function PANEL:UpdateUnitEntries()
	self.unitEntries = {}
	
	-- Find all online Metrocops
	for _, ply in ipairs(player.GetAll()) do
		local char = ply:GetCharacter()
		if char then
			local factionID = char:GetFaction()
			if factionID == FACTION_MPF then
				-- Get unit data
				local name = char:GetName()
				local status = ply:Alive() and "10-8" or "10-7"
				
				-- Extract unit ID - look for the last part with format like "RL.938" or "MPF.01.234"
				local unitID = name
				-- Try to find pattern: letters followed by dot and numbers (e.g., RL.938, MPF.01.234)
				local pattern = string.match(name, "([%u]+%.[%d]+)%s*$") or string.match(name, ":([%u]+%.[%d]+)")
				if pattern then
					unitID = pattern
				else
					-- Fallback: take last part after colon or space
					local colonPos = string.find(name, ":", 1, true)
					if colonPos then
						unitID = string.sub(name, colonPos + 1)
					else
						local spacePos = string.find(name, " ")
						if spacePos then
							unitID = string.sub(name, spacePos + 1)
						end
					end
				end
				
				table.insert(self.unitEntries, {
					id = unitID,
					status = status,
					location = "N/A"
				})
			end
		end
	end
	
	-- Sort by unit ID
	table.sort(self.unitEntries, function(a, b)
		return a.id < b.id
	end)
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
			self.infoBoxNextTime = CurTime() + 0.5
		end
	end
	
	-- Update info box scrolling text
	if self.buttonsFadeAlpha >= 255 and CurTime() >= self.infoBoxNextTime then
		local displayText = self.infoBoxTexts[self.infoBoxNextIndex]
		
		-- Add random numbers to certain messages
		if string.find(displayText, "SCANNING FREQUENCY") then
			displayText = "[BIOMETRICS] SCANNING FREQUENCY: " .. string.format("%.1f", math.random(20, 50) / 10) .. " GHz"
		elseif string.find(displayText, "CAMERA ARRAY") then
			displayText = "[SURVEILLANCE] CAMERA ARRAY: " .. math.random(800, 900) .. " FEEDS ACTIVE"
		elseif string.find(displayText, "COMPLIANCE INDEX") then
			displayText = "[CITIZEN] COMPLIANCE INDEX: " .. string.format("%.1f", math.random(920, 980) / 10) .. "%"
		elseif string.find(displayText, "UPLINK LATENCY") then
			displayText = "[NETWORK] UPLINK LATENCY: " .. math.random(8, 25) .. "ms"
		elseif string.find(displayText, "CPU UTILIZATION") then
			displayText = "[SYSTEM] CPU UTILIZATION: " .. math.random(45, 85) .. "%"
		elseif string.find(displayText, "CACHE STATUS") then
			displayText = "[MEMORY] CACHE STATUS: " .. string.format("%.1f", math.random(15, 65) / 10) .. "/8.0 GB"
		elseif string.find(displayText, "TRACKING") then
			displayText = "[BIOSIGNAL] TRACKING " .. math.random(1500, 2200) .. " ENTITIES"
		elseif string.find(displayText, "ACTIVE UNITS") then
			displayText = "[CIVIL PROTECTION] ACTIVE UNITS: " .. math.random(35, 50)
		elseif string.find(displayText, "SCANS COMPLETED") then
			displayText = "[CHECKPOINT] SCANS COMPLETED: " .. math.random(1000, 1500)
		end
		
		table.insert(self.infoBoxDisplayed, {
			text = displayText,
			spawnTime = CurTime()
		})
		
		self.infoBoxNextIndex = self.infoBoxNextIndex + 1
		if self.infoBoxNextIndex > #self.infoBoxTexts then
			self.infoBoxNextIndex = 1
		end
		
		self.infoBoxNextTime = CurTime() + 0.1
		
		-- Remove old texts if too many
		while #self.infoBoxDisplayed > self.infoBoxMaxLines do
			table.remove(self.infoBoxDisplayed, 1)
		end
	end
	
	-- Handle panel fade transitions
	if self.panelFading then
		local fadeElapsed = CurTime() - self.panelFadeStart
		local fadeProgress = math.min(fadeElapsed / 0.2, 1)
		
		if self.panelFadingOut then
			-- Fading out
			self.panelFadeAlpha = 255 * (1 - fadeProgress)
			if fadeProgress >= 1 then
				if self.nextPanel then
					-- Transition to new panel
					self.activePanel = self.nextPanel
					-- Update unit entries if switching to Unit ID panel
					if self.activePanel == "unitid" then
						self:UpdateUnitEntries()
					end
					self.nextPanel = nil
					self.panelFadingOut = false
					self.panelFadeAlpha = 0
					self.panelFadeStart = CurTime()
				else
					-- Close panel
					self.activePanel = nil
					self.panelFading = false
					self.panelFadingOut = false
					self.scrollPosition = 0
				end
			end
		else
			-- Fading in
			self.panelFadeAlpha = 255 * fadeProgress
			if fadeProgress >= 1 then
				self.panelFading = false
			end
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
		
		-- Info box below buttons
		if #self.buttons > 0 then
			local lastButton = self.buttons[#self.buttons]
			local boxX = leftMargin
			local boxY = lastButton.y + lastButton.h + buttonSpacing
			local boxWidth = uniformWidth
			local boxHeight = 180
			
			-- Box background
			surface.SetDrawColor(10, 20, 30, 200 * (self.buttonsFadeAlpha / 255))
			surface.DrawRect(boxX, boxY, boxWidth, boxHeight)
			
			-- Box outline
			surface.SetDrawColor(100, 150, 200, self.buttonsFadeAlpha)
			surface.DrawOutlinedRect(boxX, boxY, boxWidth, boxHeight, 1)
			
			-- Draw scrolling text inside box
			surface.SetFont("CombineTerminalSmall")
			local textStartY = boxY + 6
			local lineHeight = 12
			
			for i, textData in ipairs(self.infoBoxDisplayed) do
				local textAge = CurTime() - textData.spawnTime
				local textY = textStartY + ((i - 1) * lineHeight)
				
				-- Calculate fade effect
				local textAlpha = self.buttonsFadeAlpha
				if textAge < 0.15 then
					-- Fade in
					textAlpha = (textAge / 0.15) * self.buttonsFadeAlpha
				elseif i == 1 and #self.infoBoxDisplayed > self.infoBoxMaxLines - 1 then
					-- Fade out top line when about to be removed
					textAlpha = self.buttonsFadeAlpha * 0.5
				end
				
				surface.SetTextColor(120, 220, 255, textAlpha)
				surface.SetTextPos(boxX + 8, textY)
				surface.DrawText(textData.text)
			end
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
	
	-- Draw active panel on the right side
	if (self.activePanel == "lookout" or self.nextPanel == "lookout") and self.buttonsFadeAlpha >= 255 then
		local firstButton = self.buttons[1]
		local panelWidth = 350
		local panelHeight = 300
		local panelX = width - panelWidth - 50
		local panelY = firstButton.y
		
		-- Panel background
		surface.SetDrawColor(20, 40, 80, 220 * (self.panelFadeAlpha / 255))
		surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
		
		-- Panel outline
		surface.SetDrawColor(100, 150, 200, self.panelFadeAlpha)
		surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight, 2)
		
		-- Inner content area (lighter blue)
		local contentPadding = 10
		local scrollbarWidth = 20
		local contentX = panelX + contentPadding
		local contentY = panelY + contentPadding
		local contentWidth = panelWidth - (contentPadding * 2) - scrollbarWidth - 5
		local contentHeight = panelHeight - (contentPadding * 2)
		
		-- Inner background (lighter blue)
		surface.SetDrawColor(30, 60, 100, 180 * (self.panelFadeAlpha / 255))
		surface.DrawRect(contentX, contentY, contentWidth, contentHeight)
		
		-- Static horizontal scan lines from top to bottom
		surface.SetDrawColor(255, 255, 255, 15 * (self.panelFadeAlpha / 255))
		for y = contentY, contentY + contentHeight, 4 do
			surface.DrawLine(contentX, y, contentX + contentWidth, y)
		end
		
		-- Animated slow moving horizontal scanning line
		local scanPos = ((CurTime() * 0.1) % 1) * contentHeight + contentY
		surface.SetDrawColor(255, 255, 255, 120 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX, scanPos, contentX + contentWidth, scanPos)
		
		-- Column headers at the top
		surface.SetFont("CombineTerminalText")
		local headerY = contentY + 8
		local col1X = contentX + 10
		local col2X = contentX + contentWidth * 0.35
		local col3X = contentX + contentWidth * 0.70
		
		surface.SetTextColor(200, 230, 255, self.panelFadeAlpha)
		surface.SetTextPos(col1X, headerY)
		surface.DrawText("BOL ID")
		
		surface.SetTextPos(col2X, headerY)
		surface.DrawText("Reason")
		
		surface.SetTextPos(col3X, headerY)
		surface.DrawText("Time")
		
		-- Horizontal line below headers
		local headerLineY = headerY + 20
		surface.SetDrawColor(100, 150, 200, 150 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX + 5, headerLineY, contentX + contentWidth - 5, headerLineY)
		
		-- Scrollable BOL entries
		local entryStartY = headerLineY + 10
		local entryHeight = 25
		local totalContentHeight = #self.bolEntries * entryHeight
		local maxScroll = math.max(0, totalContentHeight - (contentHeight - 40))
		local scrollOffset = self.scrollPosition * maxScroll
		
		-- Enable scissor rect to clip content
		render.SetScissorRect(contentX, entryStartY, contentX + contentWidth, contentY + contentHeight, true)
		
		surface.SetFont("CombineTerminalSmall")
		for i, entry in ipairs(self.bolEntries) do
			local entryY = entryStartY + ((i - 1) * entryHeight) - scrollOffset
			
			-- Only draw if visible
			if entryY + entryHeight >= entryStartY and entryY <= contentY + contentHeight then
				-- Alternating row background
				if i % 2 == 0 then
					surface.SetDrawColor(20, 40, 70, 100 * (self.panelFadeAlpha / 255))
					surface.DrawRect(contentX + 5, entryY, contentWidth - 10, entryHeight)
				end
				
				surface.SetTextColor(180, 210, 240, self.panelFadeAlpha)
				surface.SetTextPos(col1X, entryY + 8)
				surface.DrawText(entry.id)
				
				surface.SetTextPos(col2X, entryY + 8)
				surface.DrawText(entry.reason)
				
				surface.SetTextPos(col3X, entryY + 8)
				surface.DrawText(entry.time)
			end
		end
		
		-- Disable scissor rect
		render.SetScissorRect(0, 0, 0, 0, false)
		
		-- Scrollbar on the right
		local scrollbarX = panelX + panelWidth - scrollbarWidth - contentPadding
		local scrollbarY = contentY
		local scrollbarHeight = contentHeight
		
		-- Store scrollbar bounds for mouse detection
		self.scrollbarX = scrollbarX
		self.scrollbarY = scrollbarY
		self.scrollbarWidth = scrollbarWidth
		self.scrollbarHeight = scrollbarHeight
		
		-- Scrollbar background
		surface.SetDrawColor(15, 30, 60, 200 * (self.panelFadeAlpha / 255))
		surface.DrawRect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight)
		
		-- Scrollbar outline
		surface.SetDrawColor(80, 120, 160, self.panelFadeAlpha)
		surface.DrawOutlinedRect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 1)
		
		-- Scrollbar thumb (position based on scroll)
		local thumbHeight = 60
		local availableHeight = scrollbarHeight - thumbHeight
		local thumbY = scrollbarY + (availableHeight * self.scrollPosition)
		surface.SetDrawColor(60, 100, 140, self.panelFadeAlpha)
		surface.DrawRect(scrollbarX + 2, thumbY, scrollbarWidth - 4, thumbHeight)
	end
	
	-- Draw Unit ID Index panel
	if (self.activePanel == "unitid" or self.nextPanel == "unitid") and self.buttonsFadeAlpha >= 255 then
		local firstButton = self.buttons[1]
		local panelWidth = 350
		local panelHeight = 300
		local panelX = width - panelWidth - 50
		local panelY = firstButton.y
		
		-- Panel background
		surface.SetDrawColor(20, 40, 80, 220 * (self.panelFadeAlpha / 255))
		surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
		
		-- Panel outline
		surface.SetDrawColor(100, 150, 200, self.panelFadeAlpha)
		surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight, 2)
		
		-- Inner content area (lighter blue)
		local contentPadding = 10
		local scrollbarWidth = 20
		local contentX = panelX + contentPadding
		local contentY = panelY + contentPadding
		local contentWidth = panelWidth - (contentPadding * 2) - scrollbarWidth - 5
		local contentHeight = panelHeight - (contentPadding * 2)
		
		-- Inner background (lighter blue)
		surface.SetDrawColor(30, 60, 100, 180 * (self.panelFadeAlpha / 255))
		surface.DrawRect(contentX, contentY, contentWidth, contentHeight)
		
		-- Static horizontal scan lines from top to bottom
		surface.SetDrawColor(255, 255, 255, 15 * (self.panelFadeAlpha / 255))
		for y = contentY, contentY + contentHeight, 4 do
			surface.DrawLine(contentX, y, contentX + contentWidth, y)
		end
		
		-- Animated slow moving horizontal scanning line
		local scanPos = ((CurTime() * 0.1) % 1) * contentHeight + contentY
		surface.SetDrawColor(255, 255, 255, 120 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX, scanPos, contentX + contentWidth, scanPos)
		
		-- Column headers at the top
		surface.SetFont("CombineTerminalText")
		local headerY = contentY + 8
		local col1X = contentX + 10
		local col2X = contentX + contentWidth * 0.35
		local col3X = contentX + contentWidth * 0.70
		
		surface.SetTextColor(200, 230, 255, self.panelFadeAlpha)
		surface.SetTextPos(col1X, headerY)
		surface.DrawText("Unit ID")
		
		surface.SetTextPos(col2X, headerY)
		surface.DrawText("Status")
		
		surface.SetTextPos(col3X, headerY)
		surface.DrawText("Location")
		
		-- Horizontal line below headers
		local headerLineY = headerY + 20
		surface.SetDrawColor(100, 150, 200, 150 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX + 5, headerLineY, contentX + contentWidth - 5, headerLineY)
		
		-- Scrollable unit entries
		local entryStartY = headerLineY + 10
		local entryHeight = 25
		local totalContentHeight = #self.unitEntries * entryHeight
		local availableHeight = contentHeight - (entryStartY - contentY)
		local maxScroll = math.max(0, totalContentHeight - availableHeight)
		local scrollOffset = self.scrollPosition * maxScroll
		
		surface.SetFont("CombineTerminalText")
		for i, entry in ipairs(self.unitEntries) do
			local entryY = entryStartY + ((i - 1) * entryHeight) - scrollOffset
			
			-- Draw all entries
			-- Alternating row background
			if i % 2 == 0 then
				surface.SetDrawColor(20, 40, 70, 100)
				surface.DrawRect(contentX + 5, entryY, contentWidth - 10, entryHeight)
			end
			
			-- Draw text with full opacity
			surface.SetTextColor(180, 210, 240, 255)
			surface.SetTextPos(col1X, entryY + 8)
			surface.DrawText(entry.id)
			
			surface.SetTextPos(col2X, entryY + 8)
			surface.DrawText(entry.status)
			
			surface.SetTextPos(col3X, entryY + 8)
			surface.DrawText(entry.location)
		end
		
		-- Disable scissor rect
		render.SetScissorRect(0, 0, 0, 0, false)
		
		-- Scrollbar on the right
		local scrollbarX = panelX + panelWidth - scrollbarWidth - contentPadding
		local scrollbarY = contentY
		local scrollbarHeight = contentHeight
		
		-- Store scrollbar bounds for mouse detection
		self.scrollbarX = scrollbarX
		self.scrollbarY = scrollbarY
		self.scrollbarWidth = scrollbarWidth
		self.scrollbarHeight = scrollbarHeight
		
		-- Scrollbar background
		surface.SetDrawColor(15, 30, 60, 200 * (self.panelFadeAlpha / 255))
		surface.DrawRect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight)
		
		-- Scrollbar outline
		surface.SetDrawColor(80, 120, 160, self.panelFadeAlpha)
		surface.DrawOutlinedRect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 1)
		
		-- Scrollbar thumb (position based on scroll)
		local thumbHeight = 60
		local availableHeight = scrollbarHeight - thumbHeight
		local thumbY = scrollbarY + (availableHeight * self.scrollPosition)
		surface.SetDrawColor(60, 100, 140, self.panelFadeAlpha)
		surface.DrawRect(scrollbarX + 2, thumbY, scrollbarWidth - 4, thumbHeight)
	end
	
	-- Draw Sociostatus Index panel
	if (self.activePanel == "sociostatus" or self.nextPanel == "sociostatus") and self.buttonsFadeAlpha >= 255 then
		local firstButton = self.buttons[1]
		local panelWidth = 350
		local panelHeight = 300
		local panelX = width - panelWidth - 50
		local panelY = firstButton.y
		
		-- Panel background
		surface.SetDrawColor(20, 40, 80, 220 * (self.panelFadeAlpha / 255))
		surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
		
		-- Panel outline
		surface.SetDrawColor(100, 150, 200, self.panelFadeAlpha)
		surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight, 2)
		
		-- Inner content area
		local contentPadding = 10
		local contentX = panelX + contentPadding
		local contentY = panelY + contentPadding
		local contentWidth = panelWidth - (contentPadding * 2)
		local contentHeight = panelHeight - (contentPadding * 2)
		
		-- Inner background
		surface.SetDrawColor(30, 60, 100, 180 * (self.panelFadeAlpha / 255))
		surface.DrawRect(contentX, contentY, contentWidth, contentHeight)
		
		-- Static horizontal scan lines
		surface.SetDrawColor(255, 255, 255, 15 * (self.panelFadeAlpha / 255))
		for y = contentY, contentY + contentHeight, 4 do
			surface.DrawLine(contentX, y, contentX + contentWidth, y)
		end
		
		-- Animated scanning line
		local scanPos = ((CurTime() * 0.1) % 1) * contentHeight + contentY
		surface.SetDrawColor(255, 255, 255, 120 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX, scanPos, contentX + contentWidth, scanPos)
		
		-- Status information texts
		surface.SetFont("CombineTerminalText")
		
		-- Check ration cycle (looking for ix_rationdispenser entities that are active)
		local rationCycleActive = false
		for _, ent in ipairs(ents.FindByClass("ix_rationdispenser")) do
			if IsValid(ent) and ent:GetEnabled() then
				rationCycleActive = true
				break
			end
		end
		
		-- Check curfew (you can add your own curfew system check here)
		local currentHour = tonumber(os.date("%H"))
		local curfewActive = (currentHour >= 22 or currentHour < 6)
		
		-- Count citizens with CID
		local citizenCount = 0
		for _, ply in ipairs(player.GetAll()) do
			local char = ply:GetCharacter()
			if char then
				local inv = char:GetInventory()
				if inv then
					for _, item in pairs(inv:GetItems()) do
						if item.uniqueID == "cid" then
							citizenCount = citizenCount + 1
							break
						end
					end
				end
			end
		end
		
		-- Calculate Sociostability Index (CP alive vs total CP)
		local totalCP = 0
		local aliveCP = 0
		for _, ply in ipairs(player.GetAll()) do
			local char = ply:GetCharacter()
			if char then
				local factionID = char:GetFaction()
				if factionID == FACTION_MPF then
					totalCP = totalCP + 1
					if ply:Alive() then
						aliveCP = aliveCP + 1
					end
				end
			end
		end
		local sociostabilityIndex = totalCP > 0 and math.floor((aliveCP / totalCP) * 100) or 100
		
		-- Calculate Compliance Rating based on city code
		local complianceRating = 100
		local cityCode = ix.option.Get("cityCode", "SS") -- Default to Socio-Stable
		if cityCode == "SS" then
			complianceRating = 100
		elseif cityCode == "M" then
			complianceRating = 60
		elseif cityCode == "JW" then
			complianceRating = 25
		elseif cityCode == "AJ" then
			complianceRating = 0
		end
		
		-- Blinking text for scanning
		local blinkAlpha = math.abs(math.sin(CurTime() * 3)) * self.panelFadeAlpha
		
		-- Bottom left status texts
		local bottomY = contentY + contentHeight - 60
		
		surface.SetTextColor(200, 230, 255, self.panelFadeAlpha)
		surface.SetTextPos(contentX + 10, bottomY)
		surface.DrawText("RATION CYCLE: " .. (rationCycleActive and "ACTIVE" or "INACTIVE"))
		
		surface.SetTextPos(contentX + 10, bottomY + 20)
		surface.DrawText("CURFEW STATUS: " .. (curfewActive and "ACTIVE" or "INACTIVE"))
		
		surface.SetTextPos(contentX + 10, bottomY + 40)
		surface.DrawText("CURRENT CITIZEN INDEX: " .. citizenCount)
		
		-- Additional status texts scattered around
		surface.SetTextPos(contentX + 10, contentY + 20)
		surface.DrawText("CIVIL PROTECTION AUTHORITY")
		
		surface.SetTextPos(contentX + 10, contentY + 50)
		surface.DrawText("SOCIOSTABILITY INDEX: " .. sociostabilityIndex .. "%")
		
		surface.SetTextPos(contentX + 10, contentY + 80)
		surface.DrawText("COMPLIANCE RATING: " .. complianceRating .. "%")
		
		surface.SetTextPos(contentX + 10, contentY + 110)
		surface.DrawText("LOYALIST QUOTA: 0")
		
		surface.SetTextColor(255, 200, 100, blinkAlpha)
		surface.SetTextPos(contentX + 10, contentY + 140)
		surface.DrawText("ANTI-CITIZEN COUNT: SCANNING")
	end
	
	-- Draw Surveillance System panel
	if (self.activePanel == "surveillance" or self.nextPanel == "surveillance") and self.buttonsFadeAlpha >= 255 then
		local firstButton = self.buttons[1]
		local panelWidth = 350
		local panelHeight = 300
		local panelX = width - panelWidth - 50
		local panelY = firstButton.y
		
		-- Panel background
		surface.SetDrawColor(20, 40, 80, 220 * (self.panelFadeAlpha / 255))
		surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
		
		-- Panel outline
		surface.SetDrawColor(100, 150, 200, self.panelFadeAlpha)
		surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight, 2)
		
		-- Inner content area
		local contentPadding = 10
		local contentX = panelX + contentPadding
		local contentY = panelY + contentPadding
		local contentWidth = panelWidth - (contentPadding * 2)
		local contentHeight = panelHeight - (contentPadding * 2)
		
		-- Inner background
		surface.SetDrawColor(30, 60, 100, 180 * (self.panelFadeAlpha / 255))
		surface.DrawRect(contentX, contentY, contentWidth, contentHeight)
		
		-- Static horizontal scan lines
		surface.SetDrawColor(255, 255, 255, 15 * (self.panelFadeAlpha / 255))
		for y = contentY, contentY + contentHeight, 4 do
			surface.DrawLine(contentX, y, contentX + contentWidth, y)
		end
		
		-- Animated scanning line
		local scanPos = ((CurTime() * 0.1) % 1) * contentHeight + contentY
		surface.SetDrawColor(255, 255, 255, 120 * (self.panelFadeAlpha / 255))
		surface.DrawLine(contentX, scanPos, contentX + contentWidth, scanPos)
		
		-- Coming Soon text centered
		surface.SetFont("CombineTerminalTitle")
		local text = "Coming Soon :)"
		local textW, textH = surface.GetTextSize(text)
		local textX = contentX + (contentWidth - textW) / 2
		local textY = contentY + (contentHeight - textH) / 2
		
		surface.SetTextColor(200, 230, 255, self.panelFadeAlpha)
		surface.SetTextPos(textX, textY)
		surface.DrawText(text)
	end
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
		
		-- Check if clicking on scrollbar (if any panel with scrollbar is active)
		if (self.activePanel == "lookout" or self.activePanel == "unitid") and self.scrollbarX then
			if x >= self.scrollbarX and x <= self.scrollbarX + self.scrollbarWidth and
			   y >= self.scrollbarY and y <= self.scrollbarY + self.scrollbarHeight then
				self.isDraggingScrollbar = true
				return
			end
		end
		
		-- Check main buttons
		for i, button in ipairs(self.buttons) do
			if x >= button.x and x <= button.x + button.w and
			   y >= button.y and y <= button.y + button.h then
				surface.PlaySound("hl2rp/terminal-click.wav")
				
				-- Handle button specific actions
				if self.activePanel == button.id then
					-- Same button clicked, close panel
					self.nextPanel = nil
					self.panelFading = true
					self.panelFadingOut = true
					self.panelFadeStart = CurTime()
				elseif self.activePanel then
					-- Different panel active, transition to new one
					self.nextPanel = button.id
					self.scrollPosition = 0  -- Reset scroll for new panel
					self.panelFading = true
					self.panelFadingOut = true
					self.panelFadeStart = CurTime()
				else
					-- No panel active, open new one
					self.activePanel = button.id
					-- Update unit entries if opening Unit ID panel
					if button.id == "unitid" then
						self:UpdateUnitEntries()
					end
					self.nextPanel = nil
					self.scrollPosition = 0  -- Reset scroll for new panel
					self.panelFadeAlpha = 0
					self.panelFading = true
					self.panelFadingOut = false
					self.panelFadeStart = CurTime()
				end
				
				return
			end
		end
		
		-- Check exit button
		if x >= self.buttonX and x <= self.buttonX + self.buttonWidth and
		   y >= self.buttonY and y <= self.buttonY + self.buttonHeight then
			self.isClosing = true
			self.closeStartTime = CurTime()
			surface.PlaySound("hl2rp/terminal-click.wav")
		end
	end
end

function PANEL:OnMouseReleased(mouseCode)
	if mouseCode == MOUSE_LEFT then
		self.isDraggingScrollbar = false
	end
end

function PANEL:OnCursorMoved(x, y)
	-- Handle scrollbar dragging
	if self.isDraggingScrollbar and self.scrollbarY and self.scrollbarHeight then
		local thumbHeight = 60
		local availableHeight = self.scrollbarHeight - thumbHeight
		local relativeY = y - self.scrollbarY
		
		-- Clamp position
		relativeY = math.Clamp(relativeY - thumbHeight / 2, 0, availableHeight)
		self.scrollPosition = relativeY / availableHeight
		return
	end
	
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
