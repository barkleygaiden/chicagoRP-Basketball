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
SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

-- traces in think function to drop ball once dunked
-- primary/secondary code
-- throw anim/timer handler (PREDICTED PLEASE)

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsThrowing")
    self:NetworkVar("Bool", 1, "IsDunking")
    self:NetworkVar("Float", 0, "ThrowPower")
end

function SWEP:Initialize()
    self.m_bInitialized = true
    self.IsBasketball = true

    if CLIENT and !self.m_bDeployed then
        self:CallOnClient("Deploy")
    end

    self:SetIsThrowing(false)
    self:SetIsDunking(false)
    self:SetThrowPower(0)
end

local ballAddPos = Vector(0, 5, 0)

function SWEP:Deploy()
    self.m_bDeployed = true

    self:SetHoldType("slam")
    self:SendWeaponAnim(ACT_VM_DRAW)

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
    if self:GetIsThrowing() or self:GetIsDunking() then return false end -- Fix this, we should be able to holster whenever we want to

    self:SendWeaponAnim(ACT_VM_HOLSTER)

    self:SetThrowPower(0)

    self:RemoveBasketball()

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

local animationTime = 1

function SWEP:Think()
    if !self.m_bInitialized then
        self:Initialize()
    end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    self:BallHitWall() -- Does this really have to be serverside too?

    if SERVER then
        self:UpdateBasketballPos()
    end

    local curTime = CurTime()

    if IsValid(self.BasketballProp) and self.ThrowTime and (self.ThrowTime) > curTime then
        if SERVER then
            self.BasketballProp:SetPreventTransmit(owner, false)
        end

        self:ThrowBasketball()
    end

    if self.FinishAction and (self.FinishAction) > curTime then
        self:SendWeaponAnim(ACT_VM_HOLSTER)

        self:Remove()
    end

    if self:GetIsThrowing() or self:GetIsDunking() then return end

    if IsFirstTimePredicted() and !owner:KeyDownLast(IN_ATTACK) and !owner:KeyDown(IN_ATTACK) then
        self:SetThrowPower(math.max(0, self:GetThrowPower() - 0.1)) -- Make this not tick-rate dependent
    end

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

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local firstTimePredicted = IsFirstTimePredicted()
    local attackDownLast = owner:KeyDownLast(IN_ATTACK)

    if firstTimePredicted and self:GetNearWall() and IsValid(self.PassablePlayer) and !attackDownLast then
        self:RemoveBasketball()

        if SERVER then -- Pass anim too?
            self.PassablePlayer:Give("chicagorp_basketball")
        end

        self:Remove()

        return
    end

    if firstTimePredicted and attackDownLast then
        self:SetThrowPower(math.min(1, self:GetThrowPower() + 0.1)) -- Make this not tick-rate dependent
    end

    if firstTimePredicted and !attackDownLast and self:GetThrowPower() > 0 then
        if SERVER then -- Make this shared?
            self:SetIsThrowing(true)
        end

        local sequence = self:LookupSequence("throw")

        self:SendViewModelMatchingSequence(sequence)

        self.ThrowTime = CurTime() + 0.3
        self.FinishAction = CurTime() + 0.5
    end
end

function SWEP:SecondaryAttack()
    if self:GetIsThrowing() or self:GetIsDunking() then return end
    if self:GetNearWall() then return end

    -- start dunk anim

    -- starttouch with touch entities? 

    if SERVER then -- Make this shared?
        self:SetIsDunking(true)
    end
end

function SWEP:RemoveBasketball()
	if !SERVER then return end 
	if !IsValid(self.BasketballProp) then return end

	self.BasketballProp:Remove()
end

function SWEP:ThrowBasketball(mult)
    if !IsValid(self.BasketballProp) then return end

    mult = mult or self.ThrowPower

    local owner = self:GetOwner()
    local physObj = self.BasketballProp:GetPhysicsObject()

    if !IsValid(owner) or !IsValid(physObj) then return end

    local aimVec = owner:GetAimVector()
    aimVec:Mul(100 * mult) -- :D
    aimVec:Add(VectorRand(-10, 10)) -- Add a random vector with elements (-10, 10)
    physObj:ApplyForceCenter(aimVec)
end

function SWEP:UpdateBasketballPos()
    if !IsValid(self.BasketballProp) then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local vm = owner:GetViewModel()
    local ballPos = vm:GetBonePosition(0)

    if !ballPos then return end
    if ballPos == self.LastBallPos then return end

    self.BasketballProp:SetPos(ballPos)

    self.LastBallPos = ballPos
end

function SWEP:GetAnimTime(key)
    local owner = self:GetOwner()
    local anim = self.Animations[key]

    if !IsValid(owner) or !anim then return 1 end

    local vm = owner:GetViewModel()

    if !IsValid(vm) then return 1 end

    local t = anim.Time

    if !t then
        local tseq = anim.Source

        if istable(tseq) then
            tseq["BaseClass"] = nil -- god I hate Lua inheritance
            tseq = tseq[1]
        end

        if !tseq then return 1 end
        tseq = vm:LookupSequence(tseq)

        -- to hell with it, just spits wrong on draw sometimes
        t = vm:SequenceDuration(tseq) or 1
    end

    return t
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

function SWEP:BallHitWall() -- Pasted from ArcCW, checks if the viewmodel hits a wall or an entity
    local length = 4
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
        local right, forward, up = dir:Right(), dir:Forward(), dir:Up()

        for i = 1, 3 do
            src[i] = src[i] + right[i] * ballAddPos[1] + forward[i] * ballAddPos[2] + up[i] * ballAddPos[3]
        end

        local filter = {owner, self.BasketballProp}

        forward:Mul(length)
        forward:Add(src) -- equals src + (forward * length)

        traceLineTab.start = src
        traceLineTab.endpos = forward
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

    local offsetVec = Vector(5, -2.7, -3.4) -- Specify a good position
    local offsetAng = Angle(180, 90, 0)

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()

        if IsValid(owner) then
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

        worldModel:DrawModel()
    end
end

SWEP.Animations = {
    ["idle"] = {
        Source = "idle"
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {s = ratel, t = 0},
            {s = common .. "raise.ogg", t = 0.2},
            {s = common .. "shoulder.ogg",    t = 0.2},
        },
    }
}