
ITEM.name = "Special Breen's Water"
ITEM.model = Model("models/props_junk/popcan01a.mdl")
ITEM.skin = 2
ITEM.description = "A yellow aluminium can of water that seems a bit more viscous than usual."
ITEM.category = "Consumables"

ITEM.functions.Drink = {
	OnRun = function(itemTable)
		local client = itemTable.player
		
		client:SetAction("Drinking a can of Special Breen's Water.", 3)
		client:EmitSound("npc/barnacle/barnacle_gulp2.wav", 75, 90, 0.35)
		
		timer.Simple(1.5, function()
			if (IsValid(client)) then
				client:EmitSound("npc/barnacle/barnacle_gulp1.wav", 75, 90, 0.35)
			end
		end)
		
		timer.Simple(3, function()
			if (IsValid(client) and itemTable) then
				-- Restore thirst
				local currentThirst = client:GetLocalVar("thirst", 100)
				client:SetLocalVar("thirst", math.Clamp(currentThirst + 40, 0, 100))
				
				itemTable:Remove()
			end
		end)
		
		return false
	end,
	OnCanRun = function(itemTable)
		return itemTable.player:Team() != FACTION_OTA
	end
}
