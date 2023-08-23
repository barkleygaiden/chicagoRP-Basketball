AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()    
    self:SetModel("models/chicagorp/chicagorp_basketball/phys_basketball.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetUseType(SIMPLE_USE)

    local physObj = self:GetPhysicsObject()

    if IsValid(physObj) then physObj:Wake() end
end

function ENT:Use(activator)
    if !IsValid(activator) then return end
    if !activator:IsPlayer() then return end

    local wep = self:GetController()

    if IsValid(wep) then
        wep:Remove()
    end

    activator:Give("chicagorp_basketball")

    self:Remove()
end

function ENT:PhysicsCollide(coldata, collider)
    if !IsValid(collider) then return end
    if collider:IsPlayer() or collider:IsNPC() then return end

    local wep = self:GetController()

    if IsValid(wep) and wep:GetIsDunking() then return end

    if IsValid(wep) then
        self:EmitSound("chicagorp/chicagorp_basketball/ball_dribble.ogg", 75, 100, 1, CHAN_AUTO)
    else
        self:EmitSound("chicagorp/chicagorp_basketball/ball_bounce.ogg", 75, 100, 1, CHAN_AUTO)
    end
end