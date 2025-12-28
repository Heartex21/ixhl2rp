
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

-- Stamina HUD system
if (CLIENT) then
	local staminaBarAlpha = 0
	local breathSound = nil
	local wasExhausted = false
	local shakeOffset = 0
	local blurIntensity = 0
	local displayedStamina = 100
	local exhaustedSprintTime = 0
	
	function Schema:HUDPaint()
		local client = LocalPlayer()
		if (!IsValid(client) or !client:Alive()) then 
			if (breathSound) then
				breathSound:Stop()
				breathSound = nil
			end
			blurIntensity = 0
			return 
		end
		
		local stamina = client:GetLocalVar("stm", 100)
		local breathless = client:GetNetVar("brth", false)
		local faction = client:Team()
		
		-- Only apply stamina effects to citizens and metropolice
		local isAffectedFaction = (faction == FACTION_CITIZEN or faction == FACTION_MPF)
		if (!isAffectedFaction) then return end
		
		-- Track exhaustion state
		local isExhausted = (breathless or stamina <= 0)
		if (isExhausted and !wasExhausted) then
			wasExhausted = true
		end
		
		-- Calculate blur intensity based on stamina
		local targetBlurIntensity = 0
		if (wasExhausted and stamina < 50) then
			-- Recovering from exhaustion: blur fades out from 0% to 50%
			targetBlurIntensity = 1 - (stamina / 50)
		elseif (stamina < 25) then
			-- Going low: blur intensifies from 25% to 0%
			targetBlurIntensity = 1 - (stamina / 25)
		end
		
		-- Very smooth transition with small increments
		local transitionSpeed = 0.15 -- Units per second (takes ~6.6 seconds to go from 0 to 1)
		local increment = transitionSpeed * FrameTime()
		
		if (math.abs(targetBlurIntensity - blurIntensity) < increment) then
			blurIntensity = targetBlurIntensity
		elseif (targetBlurIntensity > blurIntensity) then
			blurIntensity = blurIntensity + increment
		else
			blurIntensity = blurIntensity - increment
		end
		
		-- Handle stamina bar (shows below 50%)
		if (stamina < 50) then
			staminaBarAlpha = math.min(staminaBarAlpha + FrameTime() * 400, 255)
		else
			staminaBarAlpha = math.max(staminaBarAlpha - FrameTime() * 600, 0)
		end
		
		-- Smooth stamina display with very slow lerp to compensate for server tick updates
		displayedStamina = Lerp(FrameTime() * 1, displayedStamina, stamina)
		
		if (staminaBarAlpha > 0) then
			local barWidth = 300
			local barHeight = 20
			local barX = ScrW() / 2 - barWidth / 2
			local barY = ScrH() - 100
			
			-- Determine faction color
			local barColor
			if (faction == FACTION_MPF) then
				barColor = Color(50, 120, 200, staminaBarAlpha)
			else
				barColor = Color(220, 130, 50, staminaBarAlpha)
			end
			
			-- Draw bar background
			draw.RoundedBox(4, barX, barY, barWidth, barHeight, Color(0, 0, 0, staminaBarAlpha * 0.7))
			
			-- Draw stamina fill using lerped value for smooth animation
			local fillWidth = (displayedStamina / 100) * (barWidth - 4)
			if (fillWidth > 0.1) then
				-- Use surface library for sub-pixel accuracy
				surface.SetDrawColor(barColor.r, barColor.g, barColor.b, staminaBarAlpha)
				surface.DrawRect(barX + 2, barY + 2, fillWidth, barHeight - 4)
			end
			
			-- Draw outline
			surface.SetDrawColor(barColor.r, barColor.g, barColor.b, staminaBarAlpha)
			surface.DrawOutlinedRect(barX, barY, barWidth, barHeight, 2)
		end
		
		-- Handle breathing sounds
		local shouldBreathe = false
		
		if (wasExhausted) then
			-- If we were exhausted, keep breathing until 50%
			if (stamina < 50) then
				shouldBreathe = true
			else
				wasExhausted = false
			end
		elseif (stamina < 25 and stamina > 0) then
			-- Normal low stamina breathing (below 25%)
			shouldBreathe = true
		end
		
		if (shouldBreathe) then
			if (!breathSound or !breathSound:IsPlaying()) then
				breathSound = CreateSound(client, "player/breathe1.wav")
				breathSound:SetSoundLevel(50)
				breathSound:PlayEx(0.2, 100)
			end
		else
			if (breathSound) then
				breathSound:Stop()
				breathSound = nil
			end
		end
		
		-- Handle exhaustion collapse (fall over after 4 seconds of sprinting at 0%)
		if (stamina <= 0 and client:KeyDown(IN_SPEED)) then
			if (exhaustedSprintTime == 0) then
				exhaustedSprintTime = CurTime()
			elseif (CurTime() - exhaustedSprintTime >= 4) then
				-- Request server to ragdoll the player
				netstream.Start("StaminaCollapse")
				exhaustedSprintTime = 0
			end
		else
			exhaustedSprintTime = 0
		end
		
		-- Handle exhaustion effects
		if (blurIntensity > 0.01) then
			-- Use exponential curve for more gradual effect at low values
			local exponentialIntensity = blurIntensity * blurIntensity
			
			-- Wave-like screen shake (proportional to blur intensity)
			shakeOffset = shakeOffset + FrameTime() * 5 * exponentialIntensity
			local shakeX = math.sin(shakeOffset) * 2 * exponentialIntensity
			local shakeY = math.cos(shakeOffset * 1.3) * 1.5 * exponentialIntensity
			
			-- Apply screen blur with exponentially scaled intensity
			local blurAmount = 0.02 * exponentialIntensity
			local blurQuality = 0.5
			local blurPasses = 0.002 + (0.008 * exponentialIntensity)
			DrawMotionBlur(blurAmount, blurQuality, blurPasses)
			
			-- Apply view offset (shake)
			local view = client:GetViewEntity()
			if (IsValid(view)) then
				local angles = view:EyeAngles()
				angles.pitch = angles.pitch + shakeY * 0.3
				angles.yaw = angles.yaw + shakeX * 0.3
			end
		else
			shakeOffset = 0
		end
	end
end

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

-- Metropolice voiceline categories
local metropoliceVoicelines = {
	-- 1 - Status & Communication
	{
		{"copy", "Copy."},
		{"affirmative", "Affirmative."},
		{"10-4", "10-4."},
		{"10-2", "10-2."},
		{"responding", "Responding."},
		{"10-8", "Unit is on-duty, 10-8."},
		{"location", "Location?"},
		{"patrol", "Patrol!"},
		{"checkpoints", "Proceed to designated checkpoints."},
		{"atcheckpoint", "At checkpoint."}
	},
	-- 2 - Contact & Engagement
	{
		{"contact", "Contact!"},
		{"engaging", "Engaging!"},
		{"acquiring", "Acquiring on visual!"},
		{"closing", "Closing!"},
		{"converging", "Converging."},
		{"sweeping", "Sweeping for suspect!"},
		{"moving", "Moving to cover!"},
		{"movein", "All units, move in!"},
		{"breakcover", "Break his cover!"},
		{"expose", "Firing to expose target!"}
	},
	-- 3 - Alerts & Codes
	{
		{"code2", "All units, code two!"},
		{"code3", "Officer down, request all units, code three to my 10-20!"},
		{"code7", "Code seven."},
		{"backup", "Backup!"},
		{"help", "Help!"},
		{"overrun", "CP is overrun, we have no containment!"},
		{"compromised", "CP is compromised, re-establish!"},
		{"officerdown", "10-78"},
		{"anticitizen", "Anti-citizen."},
		{"priority", "I have contact with a priority two!"}
	},
	-- 4 - Orders & Commands
	{
		{"moveout", "All units, move to arrest positions!"},
		{"getdown", "Get down!"},
		{"dontmove", "Don't move!"},
		{"apply", "Apply."},
		{"administer", "Administer."},
		{"amputate", "Amputate."},
		{"prosecute", "Ready to prosecute!"},
		{"judge", "Ready to judge."},
		{"inalwarning", "Final warning!"},
		{"firstwarning", "First warning, move away!"}
	},
	-- 5 - Suspects & Targets
	{
		{"suspectone", "Suspect is bleeding from multiple wounds!"},
		{"suspect243", "Contact with 243 suspect, my 10-20 is..."},
		{"designate", "Designate suspect as..."},
		{"allclose", "All units, close on suspect!"},
		{"reportloc", "All units, report location suspect!"},
		{"goa", "10-97, that suspect is GOA."},
		{"anticitizen", "Anti-citizen."},
		{"malcompliant", "Malcompliant citizen."},
		{"restrictedblock", "Restricted block."},
		{"fleeing", "Fleeing suspect!"}
	},
	-- 6 - Confirmations & Reports
	{
		{"reportclear", "Reporting clear."},
		{"contained", "Contained."},
		{"cleaned", "Cleaned."},
		{"controlled", "Control is one-hundred percent this location."},
		{"blockcohesive", "Block is holding, cohesive."},
		{"cleared", "Clear and code one-hundred."},
		{"verdict", "Final verdict administered."},
		{"document", "Document."},
		{"defender", "Defender!"},
		{"readyweapons", "Ready weapons!"}
	}
}

if (CLIENT) then
	-- Prevent weapon switching when voiceline panel is open
	hook.Add("PlayerBindPress", "ixVoicelinePanelBlockWeaponSwitch", function(client, bind, pressed)
		if (IsValid(ix.gui.leftPanel) and pressed) then
			-- Block slot selection (slot1, slot2, slot3, etc.)
			if (bind:find("slot")) then
				return true
			end
			
			-- Block invnext/invprev (scroll wheel weapon switching)
			if (bind:find("invnext") or bind:find("invprev")) then
				return true
			end
		end
	end)
	
	local status, err = pcall(function()
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
			panel:SetKeyboardInputEnabled(true)
			panel:SetMouseInputEnabled(false)
			
			-- Override to consume number key presses
			function panel:OnKeyCodePressed(key)
				-- Consume all number keys and backspace/escape to prevent weapon/inventory switching
				if (key >= KEY_1 and key <= KEY_0) or key == KEY_BACKSPACE or key == KEY_ESCAPE then
					return true
				end
			end
			
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
			panel.scanLineY = 0
			panel.scanLineSpeed = 100
			
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
			
			-- Scanning line effect
			local scanAlpha = math.min(self.alpha * 0.6, 153)
			surface.SetDrawColor(255, 255, 255, scanAlpha)
			surface.DrawLine(7, self.scanLineY, w - 7, self.scanLineY)
			
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
			
			-- Update scan line position
			self.scanLineY = self.scanLineY + self.scanLineSpeed * FrameTime()
			if (self.scanLineY > self:GetTall() - 7) then
				self.scanLineY = 7
			end
			
			-- Handle panel size based on selected category
			local targetWidth = self.selectedCategory and self.voicelineWidth or self.categoryWidth
			local targetHeight = self.selectedCategory and self.voicelineHeight or self.categoryHeight
			
			-- Smooth size transition with lerp
			if (!self.currentWidth) then self.currentWidth = self:GetWide() end
			if (!self.currentHeight) then self.currentHeight = self:GetTall() end
			
			self.currentWidth = Lerp(FrameTime() * 12, self.currentWidth, targetWidth)
			self.currentHeight = Lerp(FrameTime() * 12, self.currentHeight, targetHeight)
			
			self:SetSize(self.currentWidth, self.currentHeight)
		self:SetPos(20, (ScrH() - self.currentHeight) / 2)
		
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
			panel:SetKeyboardInputEnabled(true)
			panel:SetMouseInputEnabled(false)
			
			-- Override to consume number key presses
			function panel:OnKeyCodePressed(key)
				-- Consume all number keys and backspace/escape to prevent weapon/inventory switching
				if (key >= KEY_1 and key <= KEY_0) or key == KEY_BACKSPACE or key == KEY_ESCAPE then
					return true
				end
			end
			
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
			panel.scanLineY = 0
			panel.scanLineSpeed = 100
			
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
				
				-- Scanning line effect
				local scanAlpha = math.min(self.alpha * 0.6, 153)
				surface.SetDrawColor(255, 255, 255, scanAlpha)
			surface.DrawLine(7, self.scanLineY, w - 7, self.scanLineY)
			
			local textAlpha = math.min(self.alpha, 255)
			local textColor = Color(255, 255, 255, textAlpha)		
		if (self.selectedCategory) then					-- Show voicelines for selected category
					local voicelines = metropoliceVoicelines[self.selectedCategory]
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
					
					draw.SimpleText("1 - Status & Communication", "ixMediumFont", 15, yStart, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText("2 - Contact & Engagement", "ixMediumFont", 15, yStart + ySpacing, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText("3 - Alerts & Codes", "ixMediumFont", 15, yStart + ySpacing * 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText("4 - Orders & Commands", "ixMediumFont", 15, yStart + ySpacing * 3, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText("5 - Suspects & Targets", "ixMediumFont", 15, yStart + ySpacing * 4, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText("6 - Confirmations & Reports", "ixMediumFont", 15, yStart + ySpacing * 5, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
				
				-- Update scan line position
				self.scanLineY = self.scanLineY + self.scanLineSpeed * FrameTime()
				if (self.scanLineY > self:GetTall()) then
					self.scanLineY = 0
				end
				
				-- Update scan line position
				self.scanLineY = self.scanLineY + self.scanLineSpeed * FrameTime()
				if (self.scanLineY > self:GetTall() - 7) then
					self.scanLineY = 7
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
							local voicelines = metropoliceVoicelines[self.selectedCategory]
							
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
		end
	end
	end)
	end)
	
	if not status then
		ErrorNoHalt("Error loading voiceline panel: " .. tostring(err) .. "\n")
	end
end
