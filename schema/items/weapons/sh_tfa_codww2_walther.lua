ITEM.name = "Walther Toggle Action Shotgun"
ITEM.description = "An anticitizen toggle-action shotgun. It utilizes 12-gauge shells chambered with the help of a Detachable Box Magazine. It is preferred in close-range combat against armed infantry."
ITEM.model = "models/weapons/tfa_codww2/walther/w_walther_barrel.mdl"
ITEM.class = "tfa_codww2_walther"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EOW}
ITEM.width = 3
ITEM.attachments = {""}
ITEM.height = 1
-- Disable attachments by overriding the TFA base functionality
ITEM.iconCam = {
    pos = Vector(0, 200, 1),
    ang = Angle(0, 270, 0),
    fov = 10
}
-- Override the weapon's damage to set a specific value
function ITEM:OnEquipWeapon(client, weapon)
    if IsValid(weapon) then
        local totalDamage = 1 -- Desired total damage for all pellets
        local pelletCount = 8 -- Number of pellets fired by the shotgun
        weapon.Primary.Damage = totalDamage / pelletCount -- Set damage per pellet
    end
end

function ITEM:OnEquipWeapon(client, weapon)
    if IsValid(weapon) then
        local weaponTable = weapon:GetTable()
        if weaponTable.Primary and weaponTable.Primary.Spread then
            weaponTable.Primary.Spread = weaponTable.Primary.Spread * 0.5 -- Reduce spread by 50%
        end
    end
end


