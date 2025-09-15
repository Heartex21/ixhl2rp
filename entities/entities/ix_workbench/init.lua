AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/FurnitureTable001a.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:Wake()
    end

    self.nextUse = 0 -- cooldown timer
end

function ENT:Use(activator)
    if (IsValid(activator) and activator:IsPlayer()) then
        if (self.nextUse > CurTime()) then return end -- still on cooldown
        self.nextUse = CurTime() + 1 -- 1 second cooldown

        netstream.Start(activator, "ixWorkbench_Open")
    end
end
