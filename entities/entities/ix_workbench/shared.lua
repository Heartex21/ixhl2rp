ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Workbench"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

if (SERVER) then
    function ENT:Initialize()
        self:SetModel("models/props_c17/FurnitureTable002a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if (IsValid(phys)) then
            phys:Wake()
        end
    end
end
