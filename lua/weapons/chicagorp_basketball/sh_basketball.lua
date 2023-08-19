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

    basketball:SetPreventTransmit(owner, true)

    self.BasketballProp = basketball

    return basketball
end

function SWEP:RemoveBasketball()
    if !SERVER then return end 
    if !IsValid(self.BasketballProp) then return end

    self.BasketballProp:Remove()
end

function SWEP:PassBasketball()
    self:RemoveBasketball()

    if SERVER then -- Pass anim too?
        self.PassablePlayer:Give("chicagorp_basketball")
    end

    self:Remove()
end

function SWEP:ThrowBasketball(mult)
    if !IsValid(self.BasketballProp) then return end

    if SERVER then
        self.BasketballProp:SetPreventTransmit(owner, false)
    end

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