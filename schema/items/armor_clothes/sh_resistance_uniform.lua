ITEM.name = "Resistance Uniform"
ITEM.description = "A resistance uniform, crafted with light plated armor with a symbol on the sleeve.It can last against basic firearms and melees long enough."
ITEM.model = Model("models/willardnetworks/clothingitems/torso_rebel_torso_1.mdl")
ITEM.outfitCategory = "torso"
ITEM.category = "Armored Clothing"
ITEM.maxArmor = 50
ITEM.armor = 50
ITEM.width = 2
ITEM.height = 2

function ITEM:OnEquipped()
	-- Add this item's armor to the player's current armor
	local currentArmor = self.player:Armor()
	self.player:SetArmor(currentArmor + self.armor)

	-- Store the armor value this item contributed for later removal
	self:SetData("givenArmor", self.armor)

	local torsoIndex = self.player:FindBodygroupByName("torso")
	if torsoIndex >= 0 then
		self.player:SetBodygroup(torsoIndex, 8)
	end
end

function ITEM:OnUnequipped()
	-- Remove only the armor this item gave
	local givenArmor = self:GetData("givenArmor", self.armor)
	local newArmor = math.max(self.player:Armor() - givenArmor, 0)
	self.player:SetArmor(newArmor)

	local torsoIndex = self.player:FindBodygroupByName("torso")
	if torsoIndex >= 0 then
		self.player:SetBodygroup(torsoIndex, 0)
	end
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

ITEM.replacements = {
	{"group01", "group03"},
	{"group02", "group03"},
	{"group03m", "group03"},
}
