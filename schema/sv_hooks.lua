
function Schema:LoadData()
	self:LoadRationDispensers()
	self:LoadVendingMachines()
	self:LoadCombineLocks()
	self:LoadForceFields()

	Schema.CombineObjectives = ix.data.Get("combineObjectives", {}, false, true)
end

function Schema:SaveData()
	self:SaveRationDispensers()
	self:SaveVendingMachines()
	self:SaveCombineLocks()
	self:SaveForceFields()
end

function Schema:PlayerSwitchFlashlight(client, enabled)
	if (client:IsCombine()) then
		return true
	end
end

function Schema:PlayerUse(client, entity)
	if (IsValid(client.ixScanner)) then
		return false
	end

	if ((client:IsCombine() or client:Team() == FACTION_ADMIN) and entity:IsDoor() and IsValid(entity.ixLock) and client:KeyDown(IN_SPEED)) then
		entity.ixLock:Toggle(client)
		return false
	end

	if (!client:IsRestricted() and entity:IsPlayer() and entity:IsRestricted() and !entity:GetNetVar("untying")) then
		entity:SetAction("@beingUntied", 5)
		entity:SetNetVar("untying", true)

		client:SetAction("@unTying", 5)

		client:DoStaredAction(entity, function()
			entity:SetRestricted(false)
			entity:SetNetVar("untying")
		end, 5, function()
			if (IsValid(entity)) then
				entity:SetNetVar("untying")
				entity:SetAction()
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)
	end
end

function Schema:PlayerUseDoor(client, door)
	if (client:IsCombine()) then
		if (!door:HasSpawnFlags(256) and !door:HasSpawnFlags(1024)) then
			door:Fire("open")
		end
	end
end

function Schema:PlayerLoadout(client)
	client:SetNetVar("restricted")
end

function Schema:PostPlayerLoadout(client)
	if (client:IsCombine()) then
		if (client:Team() == FACTION_OTA) then
			client:SetMaxHealth(150)
			client:SetHealth(150)
			client:SetArmor(80)
		elseif (client:IsScanner()) then
			if (client.ixScanner:GetClass() == "npc_clawscanner") then
				client:SetHealth(200)
				client:SetMaxHealth(200)
			end

			client.ixScanner:SetHealth(client:Health())
			client.ixScanner:SetMaxHealth(client:GetMaxHealth())
			client:StripWeapons()
		else
			client:SetArmor(self:IsCombineRank(client:Name(), "RCT") and 30 or 50)
		end

		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, "", client:GetCharacter():GetName())
		end
	end

	-- Start hunger/thirst decay timer (each lasts 60 minutes = 3600 seconds)
	local uniqueID = "ixNutrition" .. client:SteamID()
	client.ixLastStarvationDamage = 0
	
	timer.Create(uniqueID, 0.25, 0, function()
		if (!IsValid(client)) then
			timer.Remove(uniqueID)
			return
		end

		local character = client:GetCharacter()
		if (!character) then
			return
		end

		-- Decay rates: 100 / 3600 seconds = 0.027778 per second, 0.0069445 per 0.25s tick
		local hungerDecay = 0.0069445
		local thirstDecay = 0.0069445

		local currentHunger = client:GetLocalVar("hunger", 100)
		local currentThirst = client:GetLocalVar("thirst", 100)

		local newHunger = math.Clamp(currentHunger - hungerDecay, 0, 100)
		local newThirst = math.Clamp(currentThirst - thirstDecay, 0, 100)

		client:SetLocalVar("hunger", newHunger)
		client:SetLocalVar("thirst", newThirst)
		
		-- Apply starvation/dehydration damage if hunger or thirst reaches 0
		if ((newHunger <= 0 or newThirst <= 0) and client:Alive()) then
			local currentTime = CurTime()
			
			-- Apply 15 damage every 25 seconds
			if (currentTime - client.ixLastStarvationDamage >= 25) then
				client:TakeDamage(15)
				client.ixLastStarvationDamage = currentTime
			end
		else
			-- Reset damage timer when hunger/thirst is restored above 0
			client.ixLastStarvationDamage = 0
		end
	end)
end

function Schema:PrePlayerLoadedCharacter(client, character, oldCharacter)
	if (IsValid(client.ixScanner)) then
		client.ixScanner:Remove()
	end
end

function Schema:PlayerLoadedCharacter(client, character, oldCharacter)
	local faction = character:GetFaction()

	if (faction == FACTION_CITIZEN) then
		self:AddCombineDisplayMessage("@cCitizenLoaded", Color(255, 100, 255, 255))
	elseif (client:IsCombine()) then
		client:AddCombineDisplayMessage("@cCombineLoaded")
	end

	-- Initialize hunger/thirst from saved data
	timer.Simple(0.25, function()
		if (IsValid(client)) then
			client:SetLocalVar("hunger", character:GetData("hunger", 100))
			client:SetLocalVar("thirst", character:GetData("thirst", 100))
		end
	end)
end

function Schema:CharacterVarChanged(character, key, oldValue, value)
	local client = character:GetPlayer()
	if (key == "name") then
		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, oldValue, value)
		end
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	local factionTable = ix.faction.Get(client:Team())

	if (factionTable.runSounds and client:IsRunning()) then
		client:EmitSound(factionTable.runSounds[foot])
		return true
	end

	client:EmitSound(soundName)
	return true
end

function Schema:PlayerSpawn(client)
	client:SetCanZoom(client:IsCombine())
end

function Schema:PlayerDeath(client, inflicter, attacker)
	if (client:IsCombine()) then
		local location = client:GetArea() or "unknown location"

		self:AddCombineDisplayMessage("@cLostBiosignal")
		self:AddCombineDisplayMessage("@cLostBiosignalLocation", Color(255, 0, 0, 255), location)

		if (IsValid(client.ixScanner) and client.ixScanner:Health() > 0) then
			client.ixScanner:TakeDamage(999)
		end

		local sounds = {"npc/overwatch/radiovoice/on1.wav", "npc/overwatch/radiovoice/lostbiosignalforunit.wav"}
		local chance = math.random(1, 7)

		if (chance == 2) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/remainingunitscontain.wav"
		elseif (chance == 3) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/reinforcementteamscode3.wav"
		end

		sounds[#sounds + 1] = "npc/overwatch/radiovoice/off4.wav"

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				ix.util.EmitQueuedSounds(v, sounds, 2, nil, v == client and 100 or 80)
			end
		end
	end
end

function Schema:PlayerNoClip(client)
	if (IsValid(client.ixScanner)) then
		return false
	end
end

function Schema:EntityTakeDamage(entity, dmgInfo)
	if (IsValid(entity.ixPlayer) and entity.ixPlayer:IsScanner()) then
		entity.ixPlayer:SetHealth( math.max(entity:Health(), 0) )

		hook.Run("PlayerHurt", entity.ixPlayer, dmgInfo:GetAttacker(), entity.ixPlayer:Health(), dmgInfo:GetDamage())
	end
end

function Schema:PlayerHurt(client, attacker, health, damage)
	if (health <= 0) then
		return
	end

	if (client:IsCombine() and (client.ixTraumaCooldown or 0) < CurTime()) then
		local text = "External"

		if (damage > 50) then
			text = "Severe"
		end

		client:AddCombineDisplayMessage("@cTrauma", Color(255, 0, 0, 255), text)

		if (health < 25) then
			client:AddCombineDisplayMessage("@cDroppingVitals", Color(255, 0, 0, 255))
		end

		client.ixTraumaCooldown = CurTime() + 15
	end
end

function Schema:PlayerStaminaLost(client)
	client:AddCombineDisplayMessage("@cStaminaLost", Color(255, 255, 0, 255))
end

function Schema:PlayerStaminaGained(client)
	client:AddCombineDisplayMessage("@cStaminaGained", Color(0, 255, 0, 255))
end

function Schema:GetPlayerPainSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Pain"

		if (Schema:IsCombineRank(client:Name(), "SCN")) then
			sound = "NPC_CScanner.Pain"
		elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
			sound = "NPC_SScanner.Pain"
		end

		return sound
	end
end

function Schema:GetPlayerDeathSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Die"

		if (Schema:IsCombineRank(client:Name(), "SCN")) then
			sound = "NPC_CScanner.Die"
		elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
			sound = "NPC_SScanner.Die"
		end

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				v:EmitSound(sound)
			end
		end

		return sound
	end
end

function Schema:OnNPCKilled(npc, attacker, inflictor)
	if (IsValid(npc.ixPlayer)) then
		hook.Run("PlayerDeath", npc.ixPlayer, inflictor, attacker)
	end
end

function Schema:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
	if (chatType == "ic" or chatType == "w" or chatType == "y" or chatType == "dispatch") then
		local class = self.voices.GetClass(speaker)

		-- Split the raw text into tokens (allowing commas, semicolons, pipes or whitespace)
		local tokens = {}
		for token in string.gmatch(rawText or "", "[^,;|%s]+") do
			tokens[#tokens + 1] = token
		end

		local foundInfos = {}

		-- Match each token separately so multiple voicelines can be triggered
		for _, v in ipairs(class) do
			for _, token in ipairs(tokens) do
				local info = self.voices.Get(v, token)

				if (info) then
					foundInfos[#foundInfos + 1] = info
				end
			end
		end

		if (#foundInfos > 0) then
			local volume = 80

			if (chatType == "w") then
				volume = 60
			elseif (chatType == "y") then
				volume = 150
			end

			local texts = {}
			local sounds = {}

			for _, info in ipairs(foundInfos) do
				if (info.sound) then
					if (info.global) then
						netstream.Start(nil, "PlaySound", info.sound)
					else
						sounds[#sounds + 1] = info.sound
					end
				end

				texts[#texts + 1] = info.text or ""
			end

			local retText = table.concat(texts, " ")

			if (#sounds > 0) then
				if (speaker:IsCombine()) then
					sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
				end

				ix.util.EmitQueuedSounds(speaker, sounds, nil, 0.1, volume)
			end

			if (speaker:IsCombine()) then
				return string.format("<:: %s ::>", retText)
			else
				return retText
			end
		end

		if (speaker:IsCombine()) then
			return string.format("<:: %s ::>", text)
		end
	end
end

function Schema:CanPlayerJoinClass(client, class, info)
	if (client:IsRestricted()) then
		client:Notify("You cannot change classes when you are restrained!")

		return false
	end
end

local SCANNER_SOUNDS = {
	"npc/scanner/scanner_blip1.wav",
	"npc/scanner/scanner_scan1.wav",
	"npc/scanner/scanner_scan2.wav",
	"npc/scanner/scanner_scan4.wav",
	"npc/scanner/scanner_scan5.wav",
	"npc/scanner/combat_scan1.wav",
	"npc/scanner/combat_scan2.wav",
	"npc/scanner/combat_scan3.wav",
	"npc/scanner/combat_scan4.wav",
	"npc/scanner/combat_scan5.wav",
	"npc/scanner/cbot_servoscared.wav",
	"npc/scanner/cbot_servochatter.wav"
}

function Schema:KeyPress(client, key)
	if (IsValid(client.ixScanner) and (client.ixScannerDelay or 0) < CurTime()) then
		local source

		if (key == IN_USE) then
			source = SCANNER_SOUNDS[math.random(1, #SCANNER_SOUNDS)]
			client.ixScannerDelay = CurTime() + 1.75
		elseif (key == IN_RELOAD) then
			source = "npc/scanner/scanner_talk"..math.random(1, 2)..".wav"
			client.ixScannerDelay = CurTime() + 10
		elseif (key == IN_WALK) then
			if (client:GetViewEntity() == client.ixScanner) then
				client:SetViewEntity(NULL)
			else
				client:SetViewEntity(client.ixScanner)
			end
		end

		if (source) then
			client.ixScanner:EmitSound(source)
		end
	end
end

function Schema:PlayerSpawnObject(client)
	if (client:IsRestricted() or IsValid(client.ixScanner)) then
		return false
	end
end

function Schema:PlayerSpray(client)
	return true
end

netstream.Hook("PlayerChatTextChanged", function(client, key)
	if (client:IsCombine() and !client.bTypingBeep
	and (key == "y" or key == "w" or key == "r" or key == "t")) then
		client:EmitSound("NPC_MetroPolice.Radio.On")
		client.bTypingBeep = true
	end
end)

netstream.Hook("PlayerFinishChat", function(client)
	if (client:IsCombine() and client.bTypingBeep) then
		client:EmitSound("NPC_MetroPolice.Radio.Off")
		client.bTypingBeep = nil
	end
end)

netstream.Hook("ViewDataUpdate", function(client, target, text)
	if (IsValid(target) and hook.Run("CanPlayerEditData", client, target) and client:GetCharacter() and target:GetCharacter()) then
		local data = {
			text = string.Trim(text:sub(1, 1000)),
			editor = client:GetCharacter():GetName()
		}

		target:GetCharacter():SetData("combineData", data)
		Schema:AddCombineDisplayMessage("@cViewDataFiller", nil, client)
	end
end)

netstream.Hook("ViewObjectivesUpdate", function(client, text)
	if (client:GetCharacter() and hook.Run("CanPlayerEditObjectives", client)) then
		local date = ix.date.Get()
		local data = {
			text = text:sub(1, 1000),
			lastEditPlayer = client:GetCharacter():GetName(),
			lastEditDate = ix.date.GetSerialized(date)
		}

		ix.data.Set("combineObjectives", data, false, true)
		Schema.CombineObjectives = data
		Schema:AddCombineDisplayMessage("@cViewObjectivesFiller", nil, client, date:spanseconds())
	end
end)

-- Save hunger/thirst on character save
function Schema:CharacterPreSave(character)
	local client = character:GetPlayer()

	if (IsValid(client)) then
		character:SetData("hunger", client:GetLocalVar("hunger", 100))
		character:SetData("thirst", client:GetLocalVar("thirst", 100))
	end
end

hook.Add("PostEntityFireBullets", "MetropoliceOutOfAmmo", function(ent, data)
	if (IsValid(ent) and ent:IsPlayer() and ent:Team() == FACTION_MPF) then
		local weapon = ent:GetActiveWeapon()
		if (IsValid(weapon)) then
			-- Check ammo after firing
			timer.Simple(0.05, function()
				if (IsValid(ent) and IsValid(weapon)) then
					-- Check current clip ammo and reserve ammo
					local clipAmmo = weapon:Clip1()
					local reserveAmmo = 0
					
					-- Try to get reserve ammo (GetPrimaryAmmoType returns index, need string name)
					-- Safe approach: check if they just fired their last bullet
					if (clipAmmo == 0 and weapon:GetMaxClip1() > 0) then
						-- Fired last bullet in clip, check reserve
						reserveAmmo = ent:GetAmmoCount(weapon:GetClass()) or 0
						
						-- If no reserve either, they're out
						if (reserveAmmo <= 0) then
							if (!ent.outOfAmmoTriggered) then
								-- Send chat message as if the player said it
								ix.chat.Send(ent, "IC", "Back me up im out!")
								ent:EmitSound("npc/metropolice/vo/backmeupimout.wav")
								ent.outOfAmmoTriggered = true
								
								-- Reset flag when they pick up ammo
								timer.Simple(1, function()
									if (IsValid(ent)) then
										ent.outOfAmmoTriggered = false
									end
								end)
							end
						end
					end
				end
			end)
		end
	end
end)

-- Handle stamina collapse
netstream.Hook("StaminaCollapse", function(client)
	if (!IsValid(client) or !client:Alive()) then return end
	
	local stamina = client:GetLocalVar("stm", 100)
	
	-- Verify they're actually at 0 stamina
	if (stamina <= 0) then
		client:SetRagdolled(true, 10) -- Ragdoll for 10 seconds
	end
end)
