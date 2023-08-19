function SWEP:PlayAnimation(key)
    if !key then return end

    local startfrom = 0

    local anim = self.Animations[key]

    if !anim then return end

    local isFirstTimePredicted = IsFirstTimePredicted()

    if CLIENT and anim.ViewPunchTable then
        for k = 1, #anim.ViewPunchTable do
            local event = anim.ViewPunchTable[k]

            if !event.t then continue end

            local st = event.t - startfrom

            if st >= 0 and isnumber(event.t) and isFirstTimePredicted then
                self:AddTimer(st, function() self:OurViewPunch(event.vel, event.ang) end, id)
            end
        end
    end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local curTime = CurTime()
    local seq = anim.Source

    if istable(seq) then
        seq = seq[math.Round(util.SharedRandom("randomseq" .. curTime, 1, #seq))]
    else
        seq = self:LookupSequence(seq)
    end

    local time = self:GetAnimKeyTime(key)
    local timeMult = time
    local ttime = timeMult - startfrom

    if ttime < 0 then return end

    if anim.TPAnim then
        local aseq = owner:SelectWeightedSequence(anim.TPAnim)

        if aseq then
            owner:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, anim.TPAnimStartTime or 0, true)

            if SERVER then
                net.Start("arccw_networktpanim")
                net.WriteEntity(owner)
                net.WriteUInt(aseq, 16)
                net.WriteFloat(anim.TPAnimStartTime or 0)
                net.SendPVS(owner:GetPos())
            end
        end
    end

    if isFirstTimePredicted then
        self:PlaySoundTable(anim.SoundTable or {}, key)
    end

    if seq then
        self:SendViewModelMatchingSequence(seq)
        local dur = self:SequenceDuration()
        self:SetPlaybackRate(math.Clamp(dur / (ttime + startfrom), -4, 12))
        self.LastAnimStartTime = ct
        self.LastAnimFinishTime = ct + dur
        self.LastAnimKey = key
    end

    return true
end

function SWEP:PlayIdleAnimation()
    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local ianim = "idle"
    local isMoving = owner:GetVelocity():LengthSqr() > 0
    local onGround = owner:OnGround()

    if isMoving and !onGround then
        ianim = "idleair"
    elseif !isMoving then
        ianim = "holdprimary"
    end

    self:PlayAnimation(ianim)
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

function SWEP:PlayEvent(event)
    if !event or !istable(event) then error("SWEP:PlayEvent: No event to play!") end

    if event.s then
        self:MyEmitSound(event.s, event.l, event.p, event.v, event.c or CHAN_AUTO)
    end
end

if CLIENT then
    net.Receive("arccw_networktpanim", function()
        local ent = net.ReadEntity()
        local aseq = net.ReadUInt(16)
        local starttime = net.ReadFloat()

        if IsValid(ent) and ent != LocalPlayer() then
            ent:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, starttime, true)
        end
    end)
elseif SERVER then
    util.AddNetworkString("arccw_networktpanim")
end