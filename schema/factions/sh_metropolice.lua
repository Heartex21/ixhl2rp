
FACTION.name = "Metropolice Force"
FACTION.description = "A metropolice unit working as Civil Protection."
FACTION.color = Color(50, 100, 150)
FACTION.pay = 10
FACTION.models = {"models/ma/hla/terranovapolice.mdl"}

FACTION.weapons = {"ix_stunstick"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("handheld_radio", 1)
	inventory:Add("zip_tie", 3)

	-- Set initial RP to 0 (RPU rank)
	character:SetData("mpfRP", 0)
	character:SetName(Schema:GetMPFName(character))
	character:SetModel(self.models[1])
end
	

function FACTION:GetDefaultName(client, character)
	-- Use RP-based name generation
	if (character) then
		return Schema:GetMPFName(character), true
	end
	return "CP:RPU." .. Schema:ZeroNumber(math.random(1, 999), 3), true
end

function FACTION:OnTransferred(character)
	-- Set to RPU when transferred
	character:SetData("mpfRP", 0)
	character:SetName(Schema:GetMPFName(character))
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
	-- Update name based on current RP
	character:SetName(Schema:GetMPFName(character))
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
