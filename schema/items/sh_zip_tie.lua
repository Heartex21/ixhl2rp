
ITEM.name = "Zip Tie"
ITEM.description = "An orange zip-tie used to restrict people."
ITEM.price = 8
ITEM.model = "models/items/crossbowrounds.mdl"
ITEM.factions = {FACTION_MPF, FACTION_OTA}
ITEM.functions.Use = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:GetCharacter()
		and !target:GetNetVar("tying") and !target:IsRestricted()) then
			itemTable.bBeingUsed = true

			client:SetAction("@tying", 2)

			client:DoStaredAction(target, function()
				target:SetRestricted(true)
				target:SetNetVar("tying")
				target:NotifyLocalized("fTiedUp")

				if (target:IsCombine()) then
					Schema:AddCombineDisplayMessage("@cLosingContact", Color(255, 255, 255, 255))
					Schema:AddCombineDisplayMessage("@cLostContact", Color(255, 0, 0, 255))
				end

				itemTable:Remove()
			end, 5, function()
				client:SetAction()

				target:SetAction()
				target:SetNetVar("tying")

				itemTable.bBeingUsed = false
			end)

			target:SetNetVar("tying", true)
			target:SetAction("@fBeingTied", 2)
		else
			itemTable.player:NotifyLocalized("plyNotValid")
		end

		return false
	end,
	OnCanRun = function(itemTable)
		return !IsValid(itemTable.entity) or itemTable.bBeingUsed
	end
}

function ITEM:CanTransfer(inventory, newInventory)
	return !self.bBeingUsed
end

if SERVER then
    util.AddNetworkString("ixZipTieInspectInventory")

    hook.Add("KeyPress", "ixZiptieInspect", function(client, key)
        if key ~= IN_RELOAD then return end
        if not IsValid(client) or not client:Alive() then return end

        local char = client:GetCharacter()
        if not char then return end
        local inv = char:GetInventory()
        if not inv:HasItem("zip_tie") then return end

        local trace = client:GetEyeTrace()
        local target = trace.Entity
        if not (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then return end
        if not target:IsRestricted() then
            client:Notify("You can only inspect someone who is tied up!")
            return
        end

        if client._ixInspecting then return end
        client._ixInspecting = true

        client:SetAction("@searching", 2)
        client:DoStaredAction(target, function()
            client._ixInspecting = nil
            if not (IsValid(client) and IsValid(target)) then return end
            if client:GetPos():DistToSqr(target:GetPos()) > 10000 then
                client:Notify("You moved too far away.")
                return
            end

            -- Gather target inventory items
            local targetInv = target:GetCharacter():GetInventory()
            local itemsData = {}
            if targetInv then
                for k, v in pairs(targetInv:GetItems()) do
                    table.insert(itemsData, {name = v.name, id = v.uniqueID, amount = v:GetData("quantity", 1)})
                end
            end

            -- Send to client
            net.Start("ixZipTieInspectInventory")
                net.WriteTable(itemsData)
                net.WriteString(target:Name())
            net.Send(client)

            client:Notify("You are now inspecting " .. target:Name())
        end, 2, function()
            client._ixInspecting = nil
            client:SetAction()
            client:Notify("Inspection cancelled.")
        end)
    end)
end

if CLIENT then
    net.Receive("ixZipTieInspectInventory", function()
        local itemsData = net.ReadTable()
        local targetName = net.ReadString()

        local frame = vgui.Create("DFrame")
        frame:SetTitle("Inspecting " .. targetName)
        frame:SetSize(200, 500)
        frame:Center()
        frame:MakePopup()

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)

        for _, item in ipairs(itemsData) do
            local line = vgui.Create("DLabel", scroll)
            line:Dock(TOP)
            line:DockMargin(5, 5, 5, 0)
            line:SetText(item.name .. " x" .. item.amount)
            line:SetFont("DermaDefaultBold")
            line:SizeToContents()
        end
    end)
end


