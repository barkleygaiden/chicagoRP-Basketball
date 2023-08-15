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

function SWEP:Ammo1() -- For third-party HUD's
    return 1
end

function SWEP:Ammo2() -- For third-party HUD's
    return 1
end

function SWEP:Initialize()
    self.m_bInitialized = true

    if CLIENT and !self.m_bDeployed then
        self:CallOnClient("Deploy")
    end

    -- code here
end

local ballAddPos = Vector(0, 5, 0)

function SWEP:Deploy()
    self.m_bDeployed = true

    self:SetHoldType("slam")

    local owner = self:GetOwner()

    if SERVER then
    	local ballPos = owner:GetPos() + ballAddPos

    	local basketball = ents.Create("chicagoRP_basketball")
    	basketball:SetPos(ballPos)
    	basketball:Spawn()
    	basketball:Activate()

    	self.BasketballProp = basketball
    end

    -- aa
end

function SWEP:Holster()
    -- aa
end

function SWEP:Think()
    if !self.m_bInitialized then
        self:Initialize()
    end

    local owner = self:GetOwner()

    if !IsValid(owner) or self.IsThrowing then return end

    local onGround = owner:OnGround()

    if onGround then

    else

    -- code here
end

function SWEP:PrimaryAttack()
	self.IsThrowing = true
    -- aa
end

function SWEP:SecondaryAttack()
	self.IsThrowing = true
    -- aa
end

local hitwallcache = {0, 0}
local traceLineResultTab = {}

local traceLineTab = {
    mask = MASK_SOLID,
    output = traceLineResultTab,
}

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
elseif SERVER then
    function SWEP:ShouldDropOnDie()
        -- aa
    end

    function SWEP:OnDrop()
        -- aa
    end
end