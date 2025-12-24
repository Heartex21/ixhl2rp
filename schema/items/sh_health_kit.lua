
ITEM.name = "Health Kit"
ITEM.model = Model("models/items/healthkit.mdl")
ITEM.description = "A white packet filled with medication."
ITEM.category = "Medical"
ITEM.price = 65

ITEM.functions.Apply = {
	sound = "items/medshot4.wav",
	OnRun = function(itemTable)
		local client = itemTable.player
		local startPos = client:GetPos()
		local timerID = "HealthKitDelay_" .. client:EntIndex()

		client:SetAction("Using a Health Kit", 6)

		-- Hook to detect movement
		hook.Add("Tick", timerID, function()
			if (IsValid(client) and startPos:Distance(client:GetPos()) > 10) then
				-- Player moved, cancel the action
				timer.Remove(timerID)
				hook.Remove("Tick", timerID)
				client:SetAction()
				client:NotifyLocalized("You must stand still to utilize the Health Kit.")
				return
			end
		end)

		timer.Create(timerID, 6, 1, function()
			hook.Remove("Tick", timerID)
			if (IsValid(client)) then
				client:SetHealth(math.min(client:Health() + 50, client:GetMaxHealth()))

				if (client:IsCombine()) then
					client:AddCombineDisplayMessage("@cMedicalKit", Color(0, 255, 0, 255))
				end

				client:SetAction()
				client:EmitSound("items/suitchargeno1.wav")
				itemTable:Remove()
			end
		end)

		return false
	end
}
