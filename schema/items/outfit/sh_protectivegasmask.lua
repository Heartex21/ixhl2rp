ITEM.name = "P-35 Gas Mask"
ITEM.description = "A resistance gas mask,crafted from scrap metal and other plastic materials. It provides decent protection against harmful smokes."
ITEM.category = "Outfit"
ITEM.model = Model("models/willardnetworks/update_items/m40_item.mdl")
ITEM.outfitCategory = "mask"
ITEM.bodyGroupName = "face"
ITEM.bodyGroupValue = 3
ITEM.functions.Equip = nil -- Remove inherited Equip function

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

-- Helper function to reapply all equipped armor bodygroups
local function ReapplyArmorBodygroups(client)
	local character = client:GetCharacter()
	if (!character) then return end
	
	local inventory = character:GetInventory()
	if (!inventory) then return end
	
	-- Loop through all items and reapply bodygroups for equipped armor
	for _, item in pairs(inventory:GetItems()) do
		if (item:GetData("equip") and item.bodyGroupName and item.bodyGroupValue) then
			local index = client:FindBodygroupByName(item.bodyGroupName)
			if (index >= 0) then
				client:SetBodygroup(index, item.bodyGroupValue)
			end
		end
	end
end

function ITEM:OnEquipped()
	-- Apply this item's bodygroup
	local index = self.player:FindBodygroupByName(self.bodyGroupName)
	if (index >= 0) then
		self.player:SetBodygroup(index, self.bodyGroupValue)
	end
end

function ITEM:OnUnequipped()
	-- Reset only this item's bodygroup
	local index = self.player:FindBodygroupByName(self.bodyGroupName)
	if (index >= 0) then
		self.player:SetBodygroup(index, 0)
	end
	
	-- Reapply all other equipped armor bodygroups
	timer.Simple(0, function()
		if (IsValid(self.player)) then
			ReapplyArmorBodygroups(self.player)
		end
	end)
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		-- Apply bodygroup on loadout
		local index = self.player:FindBodygroupByName(self.bodyGroupName)
		if (index >= 0) then
			self.player:SetBodygroup(index, self.bodyGroupValue)
		end
	end
end

-- Prevent transfer while equipped
function ITEM:CanTransfer(oldInventory, newInventory)
	if (newInventory and self:GetData("equip")) then
		return false
	end
	return true
end

-- Override OnRemoved to prevent outfit system from interfering
function ITEM:OnRemoved()
	if (self.invID != 0 and self:GetData("equip")) then
		self.player = self:GetOwner()
		if (IsValid(self.player)) then
			self:OnUnequipped()
		end
		self.player = nil
	end
end

-- Item functions for equipping/unequipping
ITEM.functions.Equip = { -- Override inherited function
	OnRun = function(item)
		if (item:GetData("equip")) then
			item:OnUnequipped()
			item:SetData("equip", false)
		else
			item:SetData("equip", true)
			item:OnEquipped()
		end
		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity) and IsValid(item.player)
	end
}

function ITEM.functions.Equip:GetName()
	return self.item:GetData("equip") and "Unequip" or "Equip"
end

function ITEM.functions.Equip:GetIcon()
	return self.item:GetData("equip") and "icon16/cross.png" or "icon16/tick.png"
end

ITEM.functions.Unequip = nil -- Remove inherited Unequip function
ITEM.functions.EquipUn = nil -- Remove any other equip functions