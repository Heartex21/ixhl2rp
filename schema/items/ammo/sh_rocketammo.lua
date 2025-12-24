ITEM.name = "RPG Missile"
ITEM.model = "models/weapons/w_missile_closed.mdl"
ITEM.ammo = "rpg_round" -- type of the ammo
ITEM.ammoAmount = 1 -- amount of the ammo
ITEM.width = 2
ITEM.description = "A Package of %s Rockets"
ITEM.iconCam = {
	ang	= Angle(-0.70499622821808, 268.25439453125, 0),
	fov	= 12.085652091515,
	pos	= Vector(7, 200, -2)
}

ITEM.functions.Use = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local startPos = client:GetPos()
		local timerID = "AmmoDelay_" .. client:EntIndex()
		local bContinue = true

		client:SetAction("Using Ammunition", 3)
		client:EmitSound("items/ammocrate_open.wav")

		-- Hook to detect movement
		hook.Add("Tick", timerID, function()
			if (IsValid(client) and startPos:Distance(client:GetPos()) > 10) then
				bContinue = false
				-- Player moved, cancel the action
				timer.Remove(timerID)
				timer.Remove(timerID .. "_pickup")
				hook.Remove("Tick", timerID)
				client:SetAction()
				client:NotifyLocalized("You must stand still to utilize ammunition.")
				return
			end
		end)

		-- Play pickup sound at 1.5 seconds
		timer.Create(timerID .. "_pickup", 1.5, 1, function()
			if (bContinue and IsValid(client)) then
				client:EmitSound("items/ammo_pickup.wav")
			end
		end)

		timer.Create(timerID, 3, 1, function()
			hook.Remove("Tick", timerID)
			timer.Remove(timerID .. "_pickup")
			if (bContinue and IsValid(client)) then
				client:GiveAmmo(itemTable.ammoAmount, itemTable.ammo)
				client:SetAction()
				client:EmitSound("items/ammocrate_close.wav")
				itemTable:Remove()
			end
		end)

		return false
	end
}
