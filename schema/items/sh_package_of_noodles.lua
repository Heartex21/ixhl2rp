
ITEM.name = "Package of Noodles"
ITEM.model = Model("models/props_junk/garbage_takeoutcarton001a.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A takeout carton, it's filled with cold noodles."
ITEM.category = "Consumables"
ITEM.permit = "consumables"

ITEM.functions.Eat = {
	OnRun = function(itemTable)
		local client = itemTable.player
		
		client:SetAction("Eating Package of Noodles.", 5)
		client:EmitSound("npc/barnacle/barnacle_crunch2.wav", 75, 100, 0.5)
		
		timer.Simple(2.5, function()
			if (IsValid(client)) then
				client:EmitSound("npc/barnacle/barnacle_crunch3.wav", 75, 100, 0.5)
			end
		end)
		
		timer.Simple(5, function()
			if (IsValid(client) and itemTable) then
				-- Restore hunger
				local currentHunger = client:GetLocalVar("hunger", 100)
				client:SetLocalVar("hunger", math.Clamp(currentHunger + 25, 0, 100))
				
				itemTable:Remove()
			end
		end)
		
		return false
	end,
}
