
ITEM.name = "Health Vial"
ITEM.model = Model("models/healthvial.mdl")
ITEM.description = "A small vial with green liquid."
ITEM.category = "Medical"
ITEM.price = 40

ITEM.functions.Apply = {
	sound = "items/medshot4.wav",
	OnRun = function(itemTable)
		local client = itemTable.player

		client:SetAction("Using a Health Vial", 5)

		timer.Create("HealthVialDelay_" .. client:EntIndex(), 5, 1, function()
			if (IsValid(client)) then
				client:SetHealth(math.min(client:Health() + 20, client:GetMaxHealth()))

				if (client:IsCombine()) then
					client:AddCombineDisplayMessage("@cMedicalVial", Color(0, 255, 0, 255))
				end

				client:SetAction()
				itemTable:Remove()
			end
		end)

		return true
	end
}
