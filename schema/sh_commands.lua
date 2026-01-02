-- Register network message for MPF reward notice
if (SERVER) then
	util.AddNetworkString("ixMPFRewardNotice")
	util.AddNetworkString("ixMPFPunishmentNotice")
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "dispatch", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Dispatch", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local item

		for k, v in ipairs(radios) do
			if (v:GetData("enabled", false)) then
				item = v
				break
			end
		end

		if (item) then
			if (!client:IsRestricted()) then
				ix.chat.Send(client, "radio", message)
				ix.chat.Send(client, "radio_eavesdrop", message)
			else
				return "@notNow"
			end
		elseif (#radios > 0) then
			return "@radioNotOn"
		else
			return "@radioRequired"
		end
	end

	ix.command.Add("Radio", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.number

	function COMMAND:OnRun(client, frequency)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local itemTable = inventory:HasItem("handheld_radio")

		if (itemTable) then
			if (string.find(frequency, "^%d%d%d%.%d$")) then
				character:SetData("frequency", frequency)
				itemTable:SetData("frequency", frequency)

				client:Notify(string.format("You have set your radio frequency to %s.", frequency))
			end
		end
	end

	ix.command.Add("SetFreq", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		if (inventory:HasItem("request_device") or client:IsCombine() or client:Team() == FACTION_ADMIN) then
			if (!client:IsRestricted()) then
				Schema:AddCombineDisplayMessage("@cRequest")

				ix.chat.Send(client, "request", message)
				ix.chat.Send(client, "request_eavesdrop", message)
			else
				return "@notNow"
			end
		else
			return "@needRequestDevice"
		end
	end

	ix.command.Add("Request", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "broadcast", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Broadcast", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}

	function COMMAND:OnRun(client, target, permit)
		local itemTable = ix.item.Get("permit_" .. permit:lower())

		if (itemTable) then
			target:GetInventory():Add(itemTable.uniqueID)
		end
	end

	ix.command.Add("PermitGive", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}
	COMMAND.syntax = "<string name> <string permit>"

	function COMMAND:OnRun(client, target, permit)
		local inventory = target:GetInventory()
		local itemTable = inventory:HasItem("permit_" .. permit:lower())

		if (itemTable) then
			inventory:Remove(itemTable.id)
		end
	end

	ix.command.Add("PermitTake", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.character

	function COMMAND:OnRun(client, target)
		local targetClient = target:GetPlayer()

		if (!hook.Run("CanPlayerViewData", client, targetClient)) then
			return "@cantViewData"
		end

		netstream.Start(client, "ViewData", targetClient, target:GetData("cid") or false, target:GetData("combineData"))
	end

	ix.command.Add("ViewData", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		if (!hook.Run("CanPlayerViewObjectives", client)) then
			return "@noPerm"
		end

		netstream.Start(client, "ViewObjectives", Schema.CombineObjectives)
	end

	ix.command.Add("ViewObjectives", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:IsRestricted()) then
			if (!client:IsRestricted()) then
				Schema:SearchPlayer(client, target)
			else
				return "@notNow"
			end
		end
	end

	ix.command.Add("CharSearch", COMMAND)
end

-- Metropolice Rank Commands

do
	local COMMAND = {}
	COMMAND.description = "Give Rank Points to a Metropolice officer. Only usable by Rank Leaders."
	COMMAND.arguments = {ix.type.character, ix.type.number}

	function COMMAND:OnRun(client, target, amount)
		local character = client:GetCharacter()
		local targetChar = target
		
		-- Allow admins to bypass all checks
		if (!client:IsAdmin()) then
			-- Check if user is MPF
			if (character:GetFaction() != FACTION_MPF) then
				return "@notCombine"
			end
			
			-- Check if user is Rank Leader
			if (!Schema:IsRankLeader(character)) then
				return "Only Rank Leaders can give Rank Points."
			end
		end
		
		-- Check if target is MPF
		if (targetChar:GetFaction() != FACTION_MPF) then
			return "Target is not in the Metropolice Force."
		end
		
		-- Validate amount
		if (amount < 1 or amount > 100) then
			return "Amount must be between 1 and 100."
		end
		
		-- Get current RP
		local currentRP = targetChar:GetData("mpfRP", 0)
		local newRP = math.Clamp(currentRP + amount, 0, 100)
		
		-- Set new RP
		targetChar:SetData("mpfRP", newRP)
		
		-- Get rank info
		local oldRank = Schema:GetMPFRankByRP(currentRP)
		local newRank = Schema:GetMPFRankByRP(newRP)
		local rankInfo = Schema:GetMPFRankInfo(newRank)
		
		local targetPlayer = targetChar:GetPlayer()
		if (IsValid(targetPlayer)) then
			-- Play reward sound
			targetPlayer:EmitSound("npc/overwatch/radiovoice/rewardnotice.wav", 75, 100, 1, CHAN_AUTO)
			
			-- Send reward notice to HUD with RP amount
			net.Start("ixMPFRewardNotice")
				net.WriteUInt(amount, 8)
			net.Send(targetPlayer)
		end
		
		-- Update name
		targetChar:SetName(Schema:GetMPFName(targetChar))
	end

	ix.command.Add("MPFGiveRP", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Remove Rank Points from a Metropolice officer. Only usable by Rank Leaders."
	COMMAND.arguments = {ix.type.character, ix.type.number}

	function COMMAND:OnRun(client, target, amount)
		local character = client:GetCharacter()
		local targetChar = target
		
		-- Allow admins to bypass all checks
		if (!client:IsAdmin()) then
			-- Check if user is MPF
			if (character:GetFaction() != FACTION_MPF) then
				return "@notCombine"
			end
			
			-- Check if user is Rank Leader
			if (!Schema:IsRankLeader(character)) then
				return "Only Rank Leaders can remove Rank Points."
			end
		end
		
		-- Check if target is MPF
		if (targetChar:GetFaction() != FACTION_MPF) then
			return "Target is not in the Metropolice Force."
		end
		
		-- Validate amount
		if (amount < 1 or amount > 100) then
			return "Amount must be between 1 and 100."
		end
		
		-- Get current RP
		local currentRP = targetChar:GetData("mpfRP", 0)
		local newRP = math.Clamp(currentRP - amount, 0, 100)
		
		-- Set new RP
		targetChar:SetData("mpfRP", newRP)
		
		-- Get rank info
		local oldRank = Schema:GetMPFRankByRP(currentRP)
		local newRank = Schema:GetMPFRankByRP(newRP)
		local rankInfo = Schema:GetMPFRankInfo(newRank)
		
		local targetPlayer = targetChar:GetPlayer()
		if (IsValid(targetPlayer)) then
			-- Send punishment sequence to client with RP amount
			net.Start("ixMPFPunishmentNotice")
				net.WriteUInt(amount, 8)
			net.Send(targetPlayer)
		end
		
		-- Update name
		targetChar:SetName(Schema:GetMPFName(targetChar))
	end

	ix.command.Add("MPFRemoveRP", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Check the Rank Points of a Metropolice officer."
	COMMAND.arguments = {ix.type.character}

	function COMMAND:OnRun(client, target)
		local character = client:GetCharacter()
		local targetChar = target
		
		-- Check if user is MPF
		if (character:GetFaction() != FACTION_MPF) then
			return "@notCombine"
		end
		
		-- Check if target is MPF
		if (targetChar:GetFaction() != FACTION_MPF) then
			return "Target is not in the Metropolice Force."
		end
		
		local rp = targetChar:GetData("mpfRP", 0)
		local rank = Schema:GetMPFRankByRP(rp)
		local rankInfo = Schema:GetMPFRankInfo(rank)
		
		return string.format("%s has %d RP [%s].", targetChar:GetName(), rp, rankInfo.display)
	end

	ix.command.Add("MPFCheckRP", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Set exact Rank Points for a Metropolice officer. Admin only."
	COMMAND.adminOnly = true
	COMMAND.arguments = {ix.type.character, ix.type.number}

	function COMMAND:OnRun(client, target, amount)
		local targetChar = target
		
		-- Check if target is MPF
		if (targetChar:GetFaction() != FACTION_MPF) then
			return "Target is not in the Metropolice Force."
		end
		
		-- Validate amount
		amount = math.Clamp(amount, 0, 100)
		
		-- Set new RP
		targetChar:SetData("mpfRP", amount)
		
		-- Get rank info
		local rank = Schema:GetMPFRankByRP(amount)
		local rankInfo = Schema:GetMPFRankInfo(rank)
		
		-- Notify
		client:Notify(string.format("Set %s's RP to %d [%s].", targetChar:GetName(), amount, rankInfo.display))
		
		local targetPlayer = targetChar:GetPlayer()
		if (IsValid(targetPlayer)) then
			targetPlayer:Notify(string.format("Your RP was set to %d [%s].", amount, rankInfo.display))
		end
		
		-- Update name
		targetChar:SetName(Schema:GetMPFName(targetChar))
	end

	ix.command.Add("MPFSetRP", COMMAND)
end
