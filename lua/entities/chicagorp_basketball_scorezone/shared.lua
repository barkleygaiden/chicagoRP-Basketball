ENT.Base = "base_brush"
ENT.Type = "brush"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsScoreZone = true

local dummyMin = Vector(1, 1, 1)
local dummyMax = Vector(-1, -1, -1)

function ENT:Initialize()
    if SERVER then
        self:SetSolid(SOLID_BBOX)
        self:SetTrigger(true)
        self:SetPos((zone and zone.min) or vector_origin)
        self:SetCollisionBoundsWS((zone and zone.min) or dummyMin, (zone and zone.max) or dummyMax)
    end

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
end

function ENT:GetGameZone()
    return self.GameZone
end

function ENT:SetGameZone(zone)
    self.GameZone = zone
end

function ENT:GetConfig()
    return self.Config
end

function ENT:SetConfig(index)
    self.Config = index
end

-- This should be faster than using a Think with AABB stuff as 
-- this is actually called by the engine once when it actually
-- happens. It requires another entity though, but that's fine
-- as our basketball system doesn't use too many.

function ENT:StartTouch(ent)
    if !IsValid(ent) then return end
    if !ent.IsBasketball then return end

    self:EmitSound("chicagorp/chicagorp_basketball/score.ogg", 75, 100, 1, CHAN_AUTO)

    local wep = ent:GetController()

    if !IsValid(wep) then return end

    wep:DoDunk(self:OBBCenter())
end

function ENT:Touch(ent)
end

function ENT:EndTouch(ent)
end

function ENT:OnRemove()
    -- We assume that we are only ever removed when the map has been reset/cleared
    -- So we respawn ourself after a short delay

    -- fella stoo
end

function ENT:RemoveZone()
    self.OnRemove = nil
    self:Remove()
end