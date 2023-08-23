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
SWEP.IsBasketball = true

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsThrowing")
    self:NetworkVar("Bool", 1, "IsDunking")
    self:NetworkVar("Float", 0, "ThrowPower")
    self:NetworkVar("Float", 1, "NWPriorityAnim")
end

function SWEP:Initialize()
    self.m_bInitialized = true

    if CLIENT and !self.m_bDeployed then
        self:CallOnClient("Deploy")
    end

    self.LastAnimStartTime = 0
    self.LastAnimFinishTime = 0
    self.UpdatePos = true

    self:SetIsThrowing(false)
    self:SetIsDunking(false)
    self:SetThrowPower(0)
    self:InitTimers()
end

function SWEP:Deploy()
    self.m_bDeployed = true

    self:SetHoldType("slam")
    self:SendWeaponAnim(ACT_VM_DRAW)

    self:CreateBasketball()
end

function SWEP:Holster()
    if self:GetIsThrowing() or self:GetIsDunking() then return false end -- Fix this, we should be able to holster whenever we want to

    self:SendWeaponAnim(ACT_VM_HOLSTER)

    self:SetThrowPower(0)

    self:RemoveBasketball()
    self:KillTimers()

    return true
end

function SWEP:PrimaryAttack()
    if self:GetIsThrowing() or self:GetIsDunking() then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local firstTimePredicted = IsFirstTimePredicted()
    local attackDownLast = owner:KeyDownLast(IN_ATTACK)

    if firstTimePredicted and IsValid(self.PassablePlayer) and self:GetNearWall() and !attackDownLast then
        self:DoPass()

        return
    end

    if firstTimePredicted and attackDownLast then
        self:SetThrowPower(math.min(1, self:GetThrowPower() + 0.1)) -- Make this not tick-rate dependent
    end

    if firstTimePredicted and !attackDownLast and self:GetThrowPower() > 0 then
        if SERVER then -- Make this shared?
            self:SetIsThrowing(true)
        end

        self:PlayAnimation("throw")
        self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime("throw"))

        self:AddTimer(CurTime() + 0.3, function() self:DoThrow() end, id)
    end
end

function SWEP:SecondaryAttack()
    if self:GetIsThrowing() or self:GetIsDunking() then return end
    if self:GetNearWall() then return end

    self:PlayAnimation("dunk_start")
    self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime("dunk_start"))

    if SERVER then -- Make this shared?
        self:SetIsDunking(true)
    end
end

local animationTime = 1

function SWEP:Think()
    if !self.m_bInitialized then
        self:Initialize()
    end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    self:BasketballHitWall() -- Does this really have to be serverside too?

    if SERVER and self.UpdatePos then
        self:UpdateBasketballPos()
    end

    local curTime = CurTime()

    for i = 1, #self.EventTable do
        local event = self.EventTable[i]

        if i != 1 and !next(event) then
            self.EventTable[i] = nil

            continue
        end

        for ed, bz in pairs(event) do
            if ed <= now then
                if bz.AnimKey and (bz.AnimKey != self.LastAnimKey or bz.StartTime != self.LastAnimStartTime) then continue end

                self:PlayEvent(bz)
                self.EventTable[i][ed] = nil
            end
        end
    end

    self:ProcessTimers()

    if self:GetIsThrowing() or self:GetIsDunking() then return end

    if IsFirstTimePredicted() and !owner:KeyDownLast(IN_ATTACK) and !owner:KeyDown(IN_ATTACK) and curTime > (self.NextPowerSubtract or 0) then
        self:SetThrowPower(math.max(0, self:GetThrowPower() - 0.1)) -- Make this not tick-rate dependent
    end

    self:PlayIdleAnimation()

    self.NextPowerSubtract = CurTime() + 0.1
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
    ["idle_air"] = {
        Source = "idle_air"
    },
    ["idle_throw"] = {
        Source = "idle_throw"
    },
    ["idle_dunk"] = {
        Source = "idle_dunk"
    },
    ["throw"] = {
        Source = "idle_dunk",
        TPAnim = ACT_MP_GRENADE1_DRAW,
        SoundTable = {
            {s = ratel, t = 0},
            {s = common .. "raise.ogg", t = 0.2},
            {s = common .. "shoulder.ogg",    t = 0.2},
        }
    },
    ["dunk_start"] = {
        Source = "idle_dunk",
        TPAnim = ACT_MP_GRENADE1_DRAW,
        SoundTable = {
            {s = ratel, t = 0},
            {s = common .. "raise.ogg", t = 0.2},
            {s = common .. "shoulder.ogg",    t = 0.2},
        }
    },
    ["dunk_end"] = {
        Source = "idle_dunk",
        TPAnim = ACT_MP_GRENADE1_DRAW,
        SoundTable = {
            {s = ratel, t = 0},
            {s = common .. "raise.ogg", t = 0.2},
            {s = common .. "shoulder.ogg",    t = 0.2},
        }
    }
}