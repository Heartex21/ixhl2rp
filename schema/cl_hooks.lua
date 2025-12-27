
function Schema:PopulateCharacterInfo(client, character, tooltip)
	if (client:IsRestricted()) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("tiedUp"))
		panel:SizeToContents()
	elseif (client:GetNetVar("tying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingTied"))
		panel:SizeToContents()
	elseif (client:GetNetVar("untying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingUntied"))
		panel:SizeToContents()
	end
end

local COMMAND_PREFIX = "/"

function Schema:ChatTextChanged(text)
	if (LocalPlayer():IsCombine()) then
		local key = nil

		if (text == COMMAND_PREFIX .. "radio ") then
			key = "r"
		elseif (text == COMMAND_PREFIX .. "w ") then
			key = "w"
		elseif (text == COMMAND_PREFIX .. "y ") then
			key = "y"
		elseif (text:sub(1, 1):match("%w")) then
			key = "t"
		end

		if (key) then
			netstream.Start("PlayerChatTextChanged", key)
		end
	end
end

function Schema:FinishChat()
	netstream.Start("PlayerFinishChat")
end

function Schema:CanPlayerJoinClass(client, class, info)
	return false
end

function Schema:CharacterLoaded(character)
	if (character:IsCombine()) then
		vgui.Create("ixCombineDisplay")
	elseif (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	return true
end

local COLOR_BLACK_WHITE = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1.5,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local combineOverlay = ix.util.GetMaterial("effects/combine_binocoverlay")
local scannerFirstPerson = false

function Schema:RenderScreenspaceEffects()
	local colorModify = {}
	colorModify["$pp_colour_colour"] = 0.77

	if (system.IsWindows()) then
		colorModify["$pp_colour_brightness"] = -0.02
		colorModify["$pp_colour_contrast"] = 1.2
	else
		colorModify["$pp_colour_brightness"] = 0
		colorModify["$pp_colour_contrast"] = 1
	end

	if (scannerFirstPerson) then
		COLOR_BLACK_WHITE["$pp_colour_brightness"] = 0.05 + math.sin(RealTime() * 10) * 0.01
		colorModify = COLOR_BLACK_WHITE
	end

	DrawColorModify(colorModify)

	if (LocalPlayer():IsCombine()) then
		render.UpdateScreenEffectTexture()

		combineOverlay:SetFloat("$alpha", 0.5)
		combineOverlay:SetInt("$ignorez", 1)

		render.SetMaterial(combineOverlay)
		render.DrawScreenQuad()
	end
end

function Schema:PreDrawOpaqueRenderables()
	local viewEntity = LocalPlayer():GetViewEntity()

	if (IsValid(viewEntity) and viewEntity:GetClass():find("scanner")) then
		self.LastViewEntity = viewEntity
		self.LastViewEntity:SetNoDraw(true)

		scannerFirstPerson = true
		return
	end

	if (self.LastViewEntity != viewEntity) then
		if (IsValid(self.LastViewEntity)) then
			self.LastViewEntity:SetNoDraw(false)
		end

		self.LastViewEntity = nil
		scannerFirstPerson = false
	end
end

function Schema:ShouldDrawCrosshair()
	if (scannerFirstPerson) then
		return false
	end
end

function Schema:AdjustMouseSensitivity()
	if (scannerFirstPerson) then
		return 0.3
	end
end

-- creates labels in the status screen
function Schema:CreateCharacterInfo(panel)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid = panel:Add("ixListRow")
		panel.cid:SetList(panel.list)
		panel.cid:Dock(TOP)
		panel.cid:DockMargin(0, 0, 0, 8)
	end
end

-- populates labels in the status screen
function Schema:UpdateCharacterInfo(panel)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid:SetLabelText(L("citizenid"))
		panel.cid:SetText(string.format("##%s", LocalPlayer():GetCharacter():GetData("cid") or "UNKNOWN"))
		panel.cid:SizeToContents()
	end
end

function Schema:BuildBusinessMenu(panel)
	local bHasItems = false

	for k, _ in pairs(ix.item.list) do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), k) != false) then
			bHasItems = true

			break
		end
	end

	return bHasItems
end

function Schema:PopulateHelpMenu(tabs)
	tabs["voices"] = function(container)
		local classes = {}

		for k, v in pairs(Schema.voices.classes) do
			if (v.condition(LocalPlayer())) then
				classes[#classes + 1] = k
			end
		end

		if (#classes < 1) then
			local info = container:Add("DLabel")
			info:SetFont("ixSmallFont")
			info:SetText("You do not have access to any voice lines!")
			info:SetContentAlignment(5)
			info:SetTextColor(color_white)
			info:SetExpensiveShadow(1, color_black)
			info:Dock(TOP)
			info:DockMargin(0, 0, 0, 8)
			info:SizeToContents()
			info:SetTall(info:GetTall() + 16)

			info.Paint = function(_, width, height)
				surface.SetDrawColor(ColorAlpha(derma.GetColor("Error", info), 160))
				surface.DrawRect(0, 0, width, height)
			end

			return
		end

		table.sort(classes, function(a, b)
			return a < b
		end)

		for _, class in ipairs(classes) do
			local category = container:Add("Panel")
			category:Dock(TOP)
			category:DockMargin(0, 0, 0, 8)
			category:DockPadding(8, 8, 8, 8)
			category.Paint = function(_, width, height)
				surface.SetDrawColor(Color(0, 0, 0, 66))
				surface.DrawRect(0, 0, width, height)
			end

			local categoryLabel = category:Add("DLabel")
			categoryLabel:SetFont("ixMediumLightFont")
			categoryLabel:SetText(class:upper())
			categoryLabel:Dock(FILL)
			categoryLabel:SetTextColor(color_white)
			categoryLabel:SetExpensiveShadow(1, color_black)
			categoryLabel:SizeToContents()
			category:SizeToChildren(true, true)

			for command, info in SortedPairs(self.voices.stored[class]) do
				local title = container:Add("DLabel")
				title:SetFont("ixMediumLightFont")
				title:SetText(command:upper())
				title:Dock(TOP)
				title:SetTextColor(ix.config.Get("color"))
				title:SetExpensiveShadow(1, color_black)
				title:SizeToContents()

				local description = container:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(info.text)
				description:Dock(TOP)
				description:SetTextColor(color_white)
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			end
		end
	end
end

netstream.Hook("CombineDisplayMessage", function(text, color, arguments)
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:AddLine(text, color, nil, unpack(arguments))
	end
end)

netstream.Hook("PlaySound", function(sound)
	surface.PlaySound(sound)
end)

netstream.Hook("Frequency", function(oldFrequency)
	Derma_StringRequest("Frequency", "What would you like to set the frequency to?", oldFrequency, function(text)
		ix.command.Send("SetFreq", text)
	end)
end)

netstream.Hook("ViewData", function(target, cid, data)
	Schema:AddCombineDisplayMessage("@cViewData")
	vgui.Create("ixViewData"):Populate(target, cid, data)
end)

netstream.Hook("ViewObjectives", function(data)
	Schema:AddCombineDisplayMessage("@cViewObjectives")
	vgui.Create("ixViewObjectives"):Populate(data)
end)

-- Custom left-side panel toggle
-- Citizen voiceline categories
local citizenVoicelines = {
	-- 1 - Idle Chatter
	{
		{"Idle", "I don't think war is ever gonna end"},
		{"Idle2", "I don't dream anymore"},
		{"Idle3", "When this is all over, ahm-... Who am i kidding..."},
		{"Idle4", "Woah deja vu"},
		{"cheese", "Sometimes,i dream about cheese"},
		{"freedom", "You smell that? It's freedom"},
		{"horse", "I could eat a horse, hooves and all"},
		{"believe", "I can't believe this day has finally come"},
		{"plan", "Im pretty sure this isn't part of the plan"},
		{"Shower", "I can't remember the last time i had a shower"}
	},
	-- 2 - Active Chatter
	{
		{"same", "Same here"},
		{"mean", "Know what you mean"},
		{"withyou", "Im with you"},
		{"both", "Hah, you and me both"},
		{"howabout", "How about that?"},
		{"righton", "Right on"},
		{"noargument", "No argument there"},
		{"sure", "You sure about that?"},
		{"telling", "Why are you telling me?"},
		{"talkingto", "You talking to me?"}
	},
	-- 3 - Action
	{
		{"letsgo", "Let's go!"},
		{"follow", "Follow me!"},
		{"lead", "You lead the way!"},
		{"cover", "Take cover!"},
		{"down", "Get down!"},
		{"watch", "Watch out!"},
		{"behind", "Behind you!"},
		{"heads", "Heads up!"},
		{"reload", "Cover me while i reload"},
		{"ready", "Ready when you are!"}
	},
	-- 4 - Panic
	{
		{"runlife", "RUN FOR YOUR LIFEE!"},
		{"gethell", "GET THE HELL OUT OF HERE!"},
		{"Strider", "STRIIIIIDEEEER!"},
		{"RUUN", "RUUUUN!"},
		{"Headcrabs", "HEADCRAAABS!"},
		{"Combine", "COMBINE!"},
		{"CP", "Civil Protection!"},
		{"Zombies", "ZOMBIES!"},
		{"Help", "Help!"},
		{"god", "Good god!"}
	},
	-- 5 - Guilt
	{
		{"trusted", "We trusted you!"},
		{"notman", "You're not the man i thought you were"},
		{"deserve", "What did i do to deserve this?"},
		{"nowwhat", "Now what?"},
		{"theuse", "Whats the use?!"},
		{"thepoint", "Whats the point?"},
		{"sick", "I'm gonna be sick"},
		{"cantbe", "This can't be!"},
		{"notend", "It's not supposed to end like this"},
		{"dead", "He's dead"}
	},
	-- 6 - Cheer
	{
		{"Fantastic", "Faantastic."},
		{"Fantastic2", "FANTASTIC!"},
		{"Finally", "Finally!"},
		{"Nice", "Nice"},
		{"gotone", "Haha, got one!"},
		{"likethat", "Haha, like that?!"},
		{"gotit", "You got it"},
		{"nicely", "This will do nicely"},
		{"freedom", "You smell that? It's freedom"},
		{"believe", "I can't believe this day has finally come"}
	}
}

concommand.Add("ix_toggleleftpanel", function()
	if (IsValid(ix.gui.leftPanel)) then
		ix.gui.leftPanel:Remove()
		ix.gui.leftPanel = nil
	else
		local playerFaction = LocalPlayer():Team()
		
		-- Check if player is a citizen
		if (playerFaction == FACTION_CITIZEN) then
			-- Create Citizen Panel
			local panel = vgui.Create("DPanel")
			
			-- Calculate panel size based on content
			local categoryWidth = 350
			local categoryHeight = 220 -- Enough for 6 categories with 25px spacing + padding
			local voicelineWidth = 500
			local voicelineHeight = 400 -- Enough for 10 voicelines with 35px spacing + padding
			
			panel:SetSize(categoryWidth, categoryHeight)
			panel:SetPos(20, (ScrH() - categoryHeight) / 2)
			panel:MakePopup()
			panel:SetKeyboardInputEnabled(false)
			panel:SetMouseInputEnabled(false)
			
			panel.alpha = 0
			panel.targetAlpha = 180
			panel.fadeSpeed = 1200 -- alpha per second
			panel.selectedCategory = nil
			panel.categoryWidth = categoryWidth
			panel.categoryHeight = categoryHeight
			panel.voicelineWidth = voicelineWidth
			panel.voicelineHeight = voicelineHeight
			panel.lastKeyPressTime = {}
			panel.fadingOut = false
			panel.fadeOutTime = 0.15
			
			function panel:Paint(w, h)
				-- Draw outer outline (orange for citizens)
				draw.RoundedBox(8, 0, 0, w, h, Color(220, 130, 50, self.alpha))
			-- Draw black background
			draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(0, 0, 0, self.alpha))
			-- Draw inner white outline
			draw.RoundedBox(6, 6, 6, w - 12, h - 12, Color(255, 255, 255, math.min(self.alpha * 0.3, 76)))
			draw.RoundedBox(6, 7, 7, w - 14, h - 14, Color(0, 0, 0, self.alpha))
			
			-- Helmet vision scan lines effect
			local scanLineSpacing = 3
			local scanLineAlpha = math.min(self.alpha * 0.15, 27)
			for y = 10, h - 10, scanLineSpacing do
				surface.SetDrawColor(220, 130, 50, scanLineAlpha)
				surface.DrawLine(10, y, w - 10, y)
			end
			
			-- Add vertical accent lines on sides
			local accentAlpha = math.min(self.alpha * 0.2, 36)
			surface.SetDrawColor(220, 130, 50, accentAlpha)
			surface.DrawLine(15, 10, 15, h - 10)
			surface.DrawLine(w - 15, 10, w - 15, h - 10)
			
			local textAlpha = math.min(self.alpha, 255)
			local textColor = Color(255, 255, 255, textAlpha)
			
			if (self.selectedCategory) then
				-- Show voicelines for selected category
				local voicelines = citizenVoicelines[self.selectedCategory]
				local paddingTop = 20
				local ySpacing = 35 -- Fixed spacing between voiceline items
				local yStart = paddingTop
				
				for i = 1, math.min(10, #voicelines) do
					local displayNum = i == 10 and 0 or i
					local voiceline = voicelines[i]
					local text = displayNum .. " - " .. voiceline[2]
					draw.SimpleText(text, "ixMediumFont", 15, yStart + ySpacing * (i - 1), textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			else
				-- Show category list
				local paddingTop = 30
				local ySpacing = 25 -- Fixed spacing between items
				local yStart = paddingTop
				
				draw.SimpleText("1 - Idle Chatter", "ixMediumFont", 15, yStart, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("2 - Active Chatter", "ixMediumFont", 15, yStart + ySpacing, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("3 - Action", "ixMediumFont", 15, yStart + ySpacing * 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("4 - Panic", "ixMediumFont", 15, yStart + ySpacing * 3, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("5 - Guilt", "ixMediumFont", 15, yStart + ySpacing * 4, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("6 - Cheer", "ixMediumFont", 15, yStart + ySpacing * 5, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		end
		
		function panel:Think()
			-- Handle fade out
			if (self.fadingOut) then
				self.alpha = math.max(0, self.alpha - (255 / self.fadeOutTime) * FrameTime())
				if (self.alpha <= 0) then
					self:Remove()
					return
				end
			elseif (self.alpha < self.targetAlpha) then
				self.alpha = math.min(self.alpha + self.fadeSpeed * FrameTime(), self.targetAlpha)
			end
			
			-- Handle panel size based on selected category
			local targetWidth = self.selectedCategory and self.voicelineWidth or self.categoryWidth
			local targetHeight = self.selectedCategory and self.voicelineHeight or self.categoryHeight
			if (self:GetWide() != targetWidth or self:GetTall() != targetHeight) then
				self:SetSize(targetWidth, targetHeight)
				self:SetPos(20, (ScrH() - targetHeight) / 2)
			end
			
			local currentTime = CurTime()
			local debounceDelay = 0.3
			
			-- Check if we can process key presses (debounce)
			local function CanPressKey(key)
				if not self.lastKeyPressTime[key] then
					return true
				end
				return (currentTime - self.lastKeyPressTime[key]) >= debounceDelay
			end
			
			local function MarkKeyPressed(key)
				self.lastKeyPressTime[key] = currentTime
			end
			
			-- Detect number key presses
			if (self.selectedCategory) then
				-- We're viewing voicelines, check for voiceline selection (1-0)
				local voicelineKeys = {KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0}
				for i, key in ipairs(voicelineKeys) do
					if (input.IsKeyDown(key) and CanPressKey(key)) then
						MarkKeyPressed(key)
						
						local voicelineIndex = (i == 10) and 10 or i
						local voicelines = citizenVoicelines[self.selectedCategory]
						
						if (voicelines[voicelineIndex]) then
							local voiceCommand = voicelines[voicelineIndex][1]
							RunConsoleCommand("say", voiceCommand)
							
							-- Start fade out
							self.fadingOut = true
						end
						break
					end
				end
			else
				-- We're viewing categories, check for category selection (1-6)
				if (input.IsKeyDown(KEY_1) and CanPressKey(KEY_1)) then
					MarkKeyPressed(KEY_1)
					self.selectedCategory = 1
				elseif (input.IsKeyDown(KEY_2) and CanPressKey(KEY_2)) then
					MarkKeyPressed(KEY_2)
					self.selectedCategory = 2
				elseif (input.IsKeyDown(KEY_3) and CanPressKey(KEY_3)) then
					MarkKeyPressed(KEY_3)
					self.selectedCategory = 3
				elseif (input.IsKeyDown(KEY_4) and CanPressKey(KEY_4)) then
					MarkKeyPressed(KEY_4)
					self.selectedCategory = 4
				elseif (input.IsKeyDown(KEY_5) and CanPressKey(KEY_5)) then
					MarkKeyPressed(KEY_5)
					self.selectedCategory = 5
				elseif (input.IsKeyDown(KEY_6) and CanPressKey(KEY_6)) then
					MarkKeyPressed(KEY_6)
					self.selectedCategory = 6
				end
			end
			
			-- Handle back navigation
			if (input.IsKeyDown(KEY_BACKSPACE) or input.IsKeyDown(KEY_ESCAPE)) then
				if (CanPressKey(KEY_BACKSPACE)) then
					MarkKeyPressed(KEY_BACKSPACE)
					MarkKeyPressed(KEY_ESCAPE)
					self.selectedCategory = nil
				end
			end
		end
		
		ix.gui.leftPanel = panel
		
	-- Check if player is metropolice
	elseif (playerFaction == FACTION_MPF) then
			-- Create Metropolice Panel
			local panel = vgui.Create("DPanel")
			
			-- Calculate panel size based on content
			local categoryWidth = 350
			local categoryHeight = 220
			local voicelineWidth = 500
			local voicelineHeight = 400
			
			panel:SetSize(categoryWidth, categoryHeight)
			panel:SetPos(20, (ScrH() - categoryHeight) / 2)
			panel:MakePopup()
			panel:SetKeyboardInputEnabled(false)
			panel:SetMouseInputEnabled(false)
			
			panel.alpha = 0
			panel.targetAlpha = 180
			panel.fadeSpeed = 1200
			panel.selectedCategory = nil
			panel.categoryWidth = categoryWidth
			panel.categoryHeight = categoryHeight
			panel.voicelineWidth = voicelineWidth
			panel.voicelineHeight = voicelineHeight
			panel.lastKeyPressTime = {}
			panel.fadingOut = false
			panel.fadeOutTime = 0.15
			
			function panel:Paint(w, h)
				-- Draw outer outline (blue for metropolice)
				draw.RoundedBox(8, 0, 0, w, h, Color(50, 120, 200, self.alpha))
				-- Draw black background
				draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(0, 0, 0, self.alpha))
				-- Draw inner white outline
				draw.RoundedBox(6, 6, 6, w - 12, h - 12, Color(255, 255, 255, math.min(self.alpha * 0.3, 76)))
				draw.RoundedBox(6, 7, 7, w - 14, h - 14, Color(0, 0, 0, self.alpha))
				
				-- Helmet vision scan lines effect
				local scanLineSpacing = 3
				local scanLineAlpha = math.min(self.alpha * 0.15, 27)
				for y = 10, h - 10, scanLineSpacing do
					surface.SetDrawColor(50, 120, 200, scanLineAlpha)
					surface.DrawLine(10, y, w - 10, y)
				end
				
				-- Add vertical accent lines on sides
				local accentAlpha = math.min(self.alpha * 0.2, 36)
				surface.SetDrawColor(50, 120, 200, accentAlpha)
				surface.DrawLine(15, 10, 15, h - 10)
				surface.DrawLine(w - 15, 10, w - 15, h - 10)
				
				local textAlpha = math.min(self.alpha, 255)
				local textColor = Color(255, 255, 255, textAlpha)
				
				-- Placeholder text
				draw.SimpleText("METROPOLICE PANEL", "ixMediumFont", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			function panel:Think()
				-- Handle fade in
				if (self.alpha < self.targetAlpha) then
					self.alpha = math.min(self.alpha + self.fadeSpeed * FrameTime(), self.targetAlpha)
				end
			end
			
			ix.gui.leftPanel = panel
		end
	end
end)
