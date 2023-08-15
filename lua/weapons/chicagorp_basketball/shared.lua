AddCSLuaFile()

SWEP.Author = "SpiffyJUNIOR"
SWEP.PrintName = "chicagoRP - Basketball"
SWEP.Instructions = "Fire to throw. Alt fire to dunk."
SWEP.Spawnable = true
SWEP.UseHands = true
SWEP.ViewModel = "models/chicagorp/chicagorp_basketball/c_basketball.mdl"
SWEP.WorldModel = "models/chicagorp/chicagorp_basketball/w_basketball.mdl"
SWEP.ViewModelFOV = 90
SWEP.Slot = 0
SWEP.SlotPos = 5

-- traces in think function to drop ball once dunked
-- MRW setupmove detour
-- primary/secondary code

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsThrowing")
    self:NetworkVar("Bool", 1, "IsDunking")
end

function SWEP:Initialize()
    self.m_bInitialized = true
    self.IsBasketball = true

    if CLIENT and !self.m_bDeployed then
        self:CallOnClient("Deploy")
    end

    self:SetIsThrowing(false)
    self:SetIsDunking(false)
end

local ballAddPos = Vector(0, 5, 0)

function SWEP:Deploy()
    self.m_bDeployed = true

    self:SetHoldType("slam")

    local owner = self:GetOwner()

    if SERVER then
        local ballPos = owner:GetPos() + ballAddPos

        local basketball = ents.Create("chicagorp_basketball")
        basketball:SetPos(ballPos)
        basketball:Spawn()
        basketball:Activate()

        basketball:SetPreventTransmit(owner, true)

        self.BasketballProp = basketball
    end
end

function SWEP:Holster()
    if self:GetIsThrowing() or self:GetIsDunking() then return false end

    self:SendWeaponAnim(ACT_VM_HOLSTER)

    SWEP:RemoveBasketball()

    return true
end

function SWEP:Ammo1() -- For third-party HUD's
    return 1
end

function SWEP:Ammo2() -- For third-party HUD's
    return 1
end

function SWEP:OnDrop()
    self:Remove() -- We shouldn't drop this since the basketball prop is the weapon.
end

function SWEP:Think()
    if !self.m_bInitialized then
        self:Initialize()
    end

    self:BallHitWall() -- Does this really have to be serverside too?

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    if SERVER then
        self:UpdateBallPos()
    end

    if self:GetIsThrowing() or self:GetIsDunking() then return end

    local isMoving = ply:GetVelocity():LengthSqr() > 0
    local onGround = owner:OnGround()

    if isMoving and onGround then
        local sequence = self:LookupSequence("idle")

        self:SendViewModelMatchingSequence(sequence)
    elseif isMoving and !onGround
        local sequence = self:LookupSequence("idleair")

        self:SendViewModelMatchingSequence(sequence)
    end

    if !isMoving then
        local sequence = self:LookupSequence("holdprimary")

        self:SendViewModelMatchingSequence(sequence)
    end
end

function SWEP:PrimaryAttack()
    if self:GetIsThrowing() or self:GetIsDunking() then return end

    if SERVER and self:GetNearWall() and IsValid(self.PassablePlayer) then
        SWEP:RemoveBasketball()
        self:Remove()

        self.PassablePlayer:Give("chicagorp_basketball")

        return
    end

    if IsFirstTimePredicted() then
        -- codehere
    end

    if SERVER then
        self:SetIsThrowing(true)
    end
end

function SWEP:SecondaryAttack()
    if self:GetIsThrowing() or self:GetIsDunking() then return end

    if SERVER and self:GetNearWall() and IsValid(self.PassablePlayer) then
        SWEP:RemoveBasketball()
        self:Remove()

        self.PassablePlayer:Give("chicagorp_basketball")

        return
    end

    if IsFirstTimePredicted() then
        -- codehere
    end

    if SERVER then
        self:SetIsDunking(true)
    end
end

function SWEP:RemoveBasketball()
	if !SERVER then return end 
	if !IsValid(self.BasketballProp) then return end

	self.BasketballProp:Remove()
end

function SWEP:UpdateBallPos()
    if !IsValid(self.BasketballProp) then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local vm = owner:GetViewModel()
    local ballPos = vm:GetBonePosition(0)

    if ballPos == self.LastBallPos then return end

    self.BasketballProp:SetPos(ballPos)

    self.LastBallPos = ballPos
end

local hitwallcache = {0, 0}
local traceLineResultTab = {}

local traceLineTab = {
    mask = MASK_SOLID,
    output = traceLineResultTab,
}

local function IsEntityPassable(ent)
    if !IsValid(ent) then return end
    if !ent:IsPlayer() then return end

    return ent
end

function SWEP:BallHitWall() -- pasted from arccw lmao
    local len = 4
    local owner = self:GetOwner()
    local curTime = CurTime()

    if !IsValid(owner) then return end

    if owner:IsPlayer() and owner:InVehicle() then
        hitwallcache[1] = 0
        hitwallcache[2] = curTime
    end

    if !hitwallcache or hitwallcache[2] != curTime then
        local dir = owner:EyeAngles()
        local src = owner:EyePos()
        local r, f, u = dir:Right(), dir:Forward(), dir:Up()

        for i = 1, 3 do
            src[i] = src[i] + r[i] * ballAddPos[1] + f[i] * ballAddPos[2] + u[i] * ballAddPos[3]
        end

        local filter = {owner, self.BasketballProp}

        f:Mul(len)
        f:Add(src) -- equals src + (f * len)

        traceLineTab.start = src
        traceLineTab.endpos = f
        traceLineTab.filter = filter

        util.TraceLine(traceLineTab)

        local tr = traceLineResultTab

        if tr.Hit then
            hitwallcache[1] = 1 - tr.Fraction

            if SERVER then
                self.PassablePlayer = IsEntityPassable(tr.Entity)
            end
        else
            hitwallcache[1] = 0
            hitwallcache[2] = curTime
        end
    end

    return hitwallcache[1] or 0
end

function SWEP:GetNearWall()
    return hitwallcache and hitwallcache[1] or 0
end

if CLIENT then
    local worldModel = ClientsideModel(SWEP.WorldModel)
    worldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
            local offsetVec = Vector(5, -2.7, -3.4) -- Specify a good position
            local offsetAng = Angle(180, 90, 0)
            
            local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
            if !boneid then return end

            local matrix = owner:GetBoneMatrix(boneid)
            if !matrix then return end

            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

            worldModel:SetPos(newPos)
            worldModel:SetAngles(newAng)

            worldModel:SetupBones()
        else
            worldModel:SetPos(self:GetPos())
            worldModel:SetAngles(self:GetAngles())
        end

        WorldModel:DrawModel()
    end
end