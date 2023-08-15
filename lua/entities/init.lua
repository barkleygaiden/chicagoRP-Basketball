AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/chicagorp/chicagorp_basketball/phys_basketball.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local physObj = self:GetPhysicsObject()

    if IsValid(physObj) then physObj:Wake() end
end

function ENT:Use(activator)
    if activator:IsPlayer() then 
        activator:Kill()
    end
end