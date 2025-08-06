CLASS.name = "Elite Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/nemez/combine_soldiers/combine_soldier_elite_h.mdl")
	end
end

CLASS_EOW = CLASS.index
