
FACTION.name = "Metropolice Force"
FACTION.description = "A metropolice unit working as Civil Protection."
FACTION.color = Color(50, 100, 150)
FACTION.pay = 10
FACTION.models = {"models/wn7new/metropolice/male_07.mdl"}

FACTION.bodyGroups = {
	["Skin"] = 0,
	["Base"] = 0,
	["cp_Body"] = 6,
	["cp_Head"] = 1,
	["cp_Armor"] = 0,
	["cp_Belt"] = 0,
	["cp_Pants"] = 0,
	["cp_Bag"] = 0,
	["Satchel"] = 0
}

FACTION.weapons = {"ix_stunstick"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("cp_uniform", 1)
	inventory:Add("handheld_radio", 1)
	inventory:Add("zip_tie", 3)

	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])
end
	

function FACTION:GetDefaultName(client)
	return "CP:RPU." .. Schema:ZeroNumber(math.random(1, 999), 3), true
end

function FACTION:OnTransferred(character)
	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])

	-- Apply the default bodygroups
	local client = character:GetPlayer()
	if IsValid(client) then
		for k, v in pairs(self.bodyGroups) do
			local index = client:FindBodygroupByName(k)
			if index >= 0 then
				client:SetBodygroup(index, v)
			end
		end
	end
end

function FACTION:OnCharacterLoaded(character)
	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])

	-- Apply the default bodygroups
	local client = character:GetPlayer()
	if IsValid(client) then
		for k, v in pairs(self.bodyGroups) do
			local index = client:FindBodygroupByName(k)
			if index >= 0 then
				client:SetBodygroup(index, v)
			end
		end
	end
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()

	if (!Schema:IsCombineRank(oldValue, "RPU") and Schema:IsCombineRank(value, "RCT")) then
		character:JoinClass(CLASS_MPR)
	elseif (!Schema:IsCombineRank(oldValue, "OfC") and Schema:IsCombineRank(value, "OfC")) then
		character:SetModel("models/policetrench.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "EpU") and Schema:IsCombineRank(value, "EpU")) then
		character:JoinClass(CLASS_EMP)

		character:SetModel("models/leet_police2.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "DvL") and Schema:IsCombineRank(value, "DvL")) then
		character:SetModel("models/eliteshockcp.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "SeC") and Schema:IsCombineRank(value, "SeC")) then
		character:SetModel("models/sect_police2.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "SCN") and Schema:IsCombineRank(value, "SCN")
	or !Schema:IsCombineRank(oldValue, "SHIELD") and Schema:IsCombineRank(value, "SHIELD")) then
		character:JoinClass(CLASS_MPS)
	end

	if (!Schema:IsCombineRank(oldValue, "GHOST") and Schema:IsCombineRank(value, "GHOST")) then
		character:SetModel("models/eliteghostcp.mdl")
	end
end

FACTION_MPF = FACTION.index
