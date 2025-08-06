
ITEM.name = "CP Uniform"
ITEM.description = "A Civil Protection uniform, crafted with light plated armor with a combine symbol on the sleeve.It can last against basic firearms and melees long enough."
ITEM.category = "Clothing"
ITEM.armor = 50
ITEM.maxArmor = 50

ITEM.replacements = {
	{"group01", "group03"},
	{"group02", "group03"},
	{"group03m", "group03"},
}

ITEM.bodyGroups = {
	["cp_Head"] = 1,
    ["cp_Body"] = 4
}

function ITEM:OnEquipped()
    -- Ensure the armor value is not reset unnecessarily
    if not self.armor then
        self.armor = self.maxArmor
    end
end