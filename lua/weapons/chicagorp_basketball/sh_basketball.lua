local ballAddPos = Vector(0, 5, 0)

function SWEP:CreateBasketball()
    if CLIENT then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local ballPos = owner:GetPos() + ballAddPos

    local basketball = ents.Create("chicagorp_basketball")
    basketball:SetPos(ballPos)
    basketball:Spawn()
    basketball:Activate()

    basketball:SetController(self)
    basketball:SetPreventTransmit(owner, true)

    self:SetBasketball(basketball)

    return basketball
end

function SWEP:RemoveBasketball()
    if !SERVER then return end

    local basketBall = self:GetBasketball()

    if !IsValid(basketBall) then return end

    basketBall:Remove()
end

function SWEP:DoPass()
    self:RemoveBasketball()

    if SERVER then -- Pass anim too?
        self.PassablePlayer:Give("chicagorp_basketball")
    end

    self:Remove()
end

function SWEP:DoThrow(mult)
    if !IsFirstTimePredicted() then return end

    local basketBall = self:GetBasketball()

    if !IsValid(basketBall) then return end

    if SERVER then
        basketBall:SetPreventTransmit(owner, false)
    end

    mult = mult or self.ThrowPower

    local owner = self:GetOwner()
    local physObj = basketBall:GetPhysicsObject()

    if !IsValid(owner) or !IsValid(physObj) then return end

    local aimVec = owner:GetAimVector()
    aimVec:Mul(100 * mult) -- Scales velocity with our ThrowPower mult.
    aimVec:Add(VectorRand(-10, 10)) -- Add a random vector with elements (-10, 10)

    physObj:ApplyForceCenter(aimVec) -- Applies our final velocity vector to the physobj's center.
end

function SWEP:DoDunk(pos)
    local basketBall = self:GetBasketball()

    if !IsValid(basketBall) then return end

    self:PlayAnimation("dunk_end")
    self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime("dunk_end"))

    self.UpdatePos = false

    if SERVER then
        pos = pos or self:LocalToWorld(ballAddPos)

        basketBall:SetPos(pos)
        basketBall:SetPreventTransmit(owner, false)
    end

    self:EmitSound("chicagorp/chicagorp_basketball/score.ogg", 75, 100, 1, CHAN_AUTO)

    self:AddTimer(CurTime() + 0.3, function() self:FinishAction() end, id)
end

function SWEP:FinishAction()
    if !IsFirstTimePredicted() then return end

    self:SendWeaponAnim(ACT_VM_HOLSTER)

    self:Remove()
end

function SWEP:UpdateBasketballPos()
    local basketBall = self:GetBasketball()

    if !IsValid(basketBall) then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local vm = owner:GetViewModel()
    local ballPos = vm:GetBonePosition(0)

    if !ballPos then return end
    if ballPos == self.LastBallPos then return end

    basketBall:SetPos(ballPos)

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

function SWEP:BasketballHitWall() -- Pasted from ArcCW, checks if the viewmodel hits a wall or an entity
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