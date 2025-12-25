
ITEM.name = "Melon"
ITEM.model = Model("models/props_junk/watermelon01.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A green fruit, it has a hard outer shell."
ITEM.category = "Consumables"
ITEM.permit = "consumables"

ITEM.functions.Eat = {
	OnRun = function(itemTable)
		local client = itemTable.player
		
		client:SetAction("Eating a Melon.", 5)
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
				client:SetLocalVar("hunger", math.Clamp(currentHunger + 20, 0, 100))
				
				itemTable:Remove()
			end
		end)
		
		return false
	end,
}
