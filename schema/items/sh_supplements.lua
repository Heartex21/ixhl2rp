
ITEM.name = "Supplements"
ITEM.model = Model("models/props_lab/jar01a.mdl")
ITEM.description = "A white plastic jar containing a good portion of your daily nutrients."

ITEM.functions.Eat = {
	OnRun = function(itemTable)
		local client = itemTable.player
		
		client:SetAction("@eating", 5)
		client:EmitSound("npc/barnacle/barnacle_crunch2.wav", 75, 100, 0.5)
		
		timer.Simple(2.5, function()
			if (IsValid(client)) then
				client:EmitSound("npc/barnacle/barnacle_crunch3.wav", 75, 100, 0.5)
			end
		end)
		
		timer.Simple(5, function()
			if (IsValid(client) and itemTable) then
				client:EmitSound("npc/antlion_grub/squashed.wav", 75, 150, 0.25)
				
				-- Restore hunger
				local currentHunger = client:GetLocalVar("hunger", 100)
				client:SetLocalVar("hunger", math.Clamp(currentHunger + 40, 0, 100))
				
				itemTable:Remove()
			end
		end)
		
		return false
	end,
	OnCanRun = function(itemTable)
		return itemTable.player:Team() != FACTION_OTA
	end
}
