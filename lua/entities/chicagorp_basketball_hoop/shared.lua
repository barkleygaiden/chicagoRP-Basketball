ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsBasketballHoop = true

local scoreMin = Vector(-1, -1, -1)
local scoreMax = Vector(1, 1, 1)

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/chicagorp/chicagorp_basketball/basketball_hoop.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

        local physObj = self:GetPhysicsObject()

        if IsValid(physObj) then physObj:Wake() end
    end

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

    local scoreZone = ents.Create("chicagorp_basketball_scorezone")
    scoreZone:SetPos(self:GetBonePosition(0)) -- Parenting will make this unnecessary!
    scoreZone:SetCollisionBoundsWS(scoreMin, scoreMax)
    scoreZone:SetMoveParent(self)
    scoreZone:Spawn()
    scoreZone:Activate()
end

function ENT:GetGameZone()
    return self.GameZone
end

function ENT:SetGameZone(zone)
    self.GameZone = zone
end

function ENT:OnRemove()
    -- We assume that we are only ever removed when the map has been reset/cleared
    -- So we respawn ourself after a short delay

    -- fella stoo
end