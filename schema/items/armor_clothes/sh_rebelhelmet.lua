ITEM.name = "L2 Helmet"
ITEM.description = "A resistance helmet,crafted from scrap metal and other materials. It provides decent protection against small arms fire."
ITEM.model = Model("models/willardnetworks/clothingitems/head_helmet.mdl")
ITEM.outfitCategory = "head"
ITEM.category = "Armored Clothing"
ITEM.maxArmor = 20
ITEM.armor = 20
ITEM.width = 2
ITEM.height = 2
ITEM.bodyGroups = {
	["head"] = 4
}

function ITEM:OnEquipped()
	-- Add this item's armor to the player's current armor
	local currentArmor = self.player:Armor()
	self.player:SetArmor(currentArmor + self.armor)

	-- Store the armor value this item contributed for later removal
	self:SetData("givenArmor", self.armor)

	self.bodyGroups = {
        ["head"] = 4
    }
end

function ITEM:OnUnequipped()
	-- Remove only the armor this item gave
	local givenArmor = self:GetData("givenArmor", self.armor)
	local newArmor = math.max(self.player:Armor() - givenArmor, 0)
	self.player:SetArmor(newArmor)

	self.bodyGroups = {
        ["head"] = 0
    }
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self.player:SetArmor(self:GetData("armor", self.maxArmor))
	end
end

function ITEM:OnSave()
	if (self:GetData("equip")) then
		self:SetData("armor", math.Clamp(self.player:Armor(), 0, self.maxArmor))
	end
end
