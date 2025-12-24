ITEM.name = "Pulse-Rifle Energy"
ITEM.model = "models/items/combine_rifle_cartridge01.mdl"
ITEM.ammo = "ar2" -- type of the ammo
ITEM.ammoAmount = 30 -- amount of the ammo
ITEM.description = "A Cartridge that contains %s of AR2 Ammo"
ITEM.classes = {CLASS_EOW}

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
