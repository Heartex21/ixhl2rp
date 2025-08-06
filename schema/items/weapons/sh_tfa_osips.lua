ITEM.name = "OTI Pulse SMG"
ITEM.description = "A submachine gun that is powered by dark energy bullets,it is biolinked to the user of the weapon.It is versatile and a good defensive weapon in close ranges."
ITEM.model = Model("models/weapons/psmg/c_psmg.mdl")
ITEM.class = "tfa_osips"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_TGU, CLASS_EOW}
ITEM.width = 3
ITEM.height = 2
ITEM.iconCam = {
	ang	= Angle(-0.020070368424058, 270.40155029297, 0),
	fov	= 7.2253324508038,
	pos	= Vector(-17.5, 200, -5)
}

function ITEM:CanDrop()
    return false
end