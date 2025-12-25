
ITEM.name = "Milk Carton"
ITEM.model = Model("models/props_junk/garbage_milkcarton001a.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A carton filled with milk."
ITEM.category = "Consumables"
ITEM.permit = "consumables"

ITEM.functions.Drink = {
	OnRun = function(itemTable)
		local client = itemTable.player
		
		client:SetAction("Drinking a Carton of Milk.", 3)
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
				client:SetLocalVar("thirst", math.Clamp(currentThirst + 25, 0, 100))
				
				itemTable:Remove()
			end
		end)
		
		return false
	end,
}
