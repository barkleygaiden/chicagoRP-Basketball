function SWEP:MyEmitSound(snd, level, pitch, vol, chan, useWorld)
    if !snd or !string.IsValid(snd) then return end

    if istable(snd) then snd = chicagoRP.RandomKey(snd) end

    self:EmitSound(snd, level, pitch, vol, chan or CHAN_AUTO)
end

function SWEP:OurViewPunch(vel, ang) -- VERY crappy viewpunch solution, but it (should) work.
    if !isangle(vel) then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    if ang then
        owner:SetViewPunchAngles(ang)
    end

    owner:ViewPunch(vel)

    owner:SetViewPunchAngles(angle_zero)
end