ITEM.name = "L2 Helmet"
ITEM.description = "A resistance helmet,crafted from scrap metal and other materials. It provides decent protection against small arms fire."
ITEM.model = Model("models/willardnetworks/clothingitems/head_helmet.mdl")
ITEM.outfitCategory = "head"
ITEM.category = "Armored Clothing"
ITEM.maxArmor = 20
ITEM.width = 2
ITEM.height = 2
ITEM.bodyGroupName = "head"
ITEM.bodyGroupValue = 4
ITEM.functions.Equip = nil -- Remove inherited Equip function

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
	
	function ITEM:PopulateTooltip(tooltip)
		local panel = tooltip:AddRowAfter("name", "armor")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		-- Show only THIS item's armor, not total player armor
		panel:SetText("Armor: " .. self:GetData("currentArmor", self.maxArmor))
		panel:SizeToContents()
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
	-- Get current armor this item has (accounting for damage)
	local itemArmor = self:GetData("currentArmor", self.maxArmor)
	
	-- Add this item's armor to the player's current armor
	local currentArmor = self.player:Armor()
	self.player:SetArmor(currentArmor + itemArmor)

	-- Store the armor value this item contributed for later removal
	self:SetData("givenArmor", itemArmor)
	
	-- Apply this item's bodygroup
	local index = self.player:FindBodygroupByName(self.bodyGroupName)
	if (index >= 0) then
		self.player:SetBodygroup(index, self.bodyGroupValue)
	end
end

function ITEM:OnUnequipped()
	-- Save current armor value to item before removing
	local givenArmor = self:GetData("givenArmor", self.maxArmor)
	local currentPlayerArmor = self.player:Armor()
	
	-- Calculate how much of this item's armor remains
	local remainingArmor = math.max(math.min(currentPlayerArmor, givenArmor), 0)
	self:SetData("currentArmor", remainingArmor)
	
	-- Remove only the armor this item gave
	local newArmor = math.max(currentPlayerArmor - givenArmor, 0)
	self.player:SetArmor(newArmor)
	
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
		local itemArmor = self:GetData("currentArmor", self.maxArmor)
		local currentArmor = self.player:Armor()
		self.player:SetArmor(currentArmor + itemArmor)
		self:SetData("givenArmor", itemArmor)
		
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

if (SERVER) then
	hook.Add("EntityTakeDamage", "ixArmorDamageTracking", function(target, dmginfo)
		if (!target:IsPlayer()) then return end
		
		local character = target:GetCharacter()
		if (!character) then return end
		
		local inventory = character:GetInventory()
		if (!inventory) then return end
		
		-- Get armor before damage
		local armorBefore = target:Armor()
		if (armorBefore <= 0) then return end
		
		-- Check after damage is applied
		timer.Simple(0, function()
			if (!IsValid(target)) then return end
			
			local armorAfter = target:Armor()
			local armorLost = armorBefore - armorAfter
			
			if (armorLost <= 0) then return end
			
			-- Find all equipped armor items and reduce their stored armor proportionally
			local equippedArmor = {}
			local totalGivenArmor = 0
			
			for _, item in pairs(inventory:GetItems()) do
				if (item:GetData("equip") and item.bodyGroupName and item:GetData("givenArmor")) then
					table.insert(equippedArmor, item)
					totalGivenArmor = totalGivenArmor + item:GetData("givenArmor", 0)
				end
			end
			
			if (totalGivenArmor <= 0) then return end
			
			-- Reduce each item's armor proportionally
			for _, item in ipairs(equippedArmor) do
				local itemGivenArmor = item:GetData("givenArmor", 0)
				local itemProportion = itemGivenArmor / totalGivenArmor
				local itemArmorLost = armorLost * itemProportion
				
				local currentItemArmor = item:GetData("currentArmor", item.maxArmor)
				local newItemArmor = math.max(currentItemArmor - itemArmorLost, 0)
				
				item:SetData("currentArmor", newItemArmor)
				item:SetData("givenArmor", newItemArmor)
				
				-- If armor is depleted, auto-unequip
				if (newItemArmor <= 0) then
					item.player = target
					item:OnUnequipped()
					item:SetData("equip", false)
					item.player = nil
						
						-- Play break sound and destroy item
						if (item.name == "L2 Helmet") then
							target:EmitSound("physics/plastic/plastic_box_impact_bullet3.wav", 75, 100)
						elseif (item.name == "Resistance Uniform") then
							target:EmitSound("physics/cardboard/cardboard_box_break3.wav", 75, 100)
						end
						
						-- Remove item from inventory after a short delay
						timer.Simple(0.5, function()
							if (item) then
								item:Remove()
							end
						end)
				end
			end
			end)
		end)
end
