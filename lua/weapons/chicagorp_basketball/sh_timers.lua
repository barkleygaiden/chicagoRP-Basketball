local tick = 0

function SWEP:InitTimers()
    self.ActiveTimers = {} -- {{time, id, func}}
end

function SWEP:AddTimer(time, callback, id)
    if !IsFirstTimePredicted() then return end

    table.insert(self.ActiveTimers, {time + CurTime(), id or "", callback})
end

function SWEP:TimerExists(id)
    for i = 1, #self.ActiveTimers do
        local timer_ = self.ActiveTimers[i]

        if timer_[2] == id then return true end
    end

    return false
end

function SWEP:RemoveTimer(id)
    local keeptimers = {}

    for i = 1, #self.ActiveTimers do
        local timer_ = self.ActiveTimers[i]

        if timer_[2] != id then table.insert(keeptimers, timer_) end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:RemoveTimers()
    self.ActiveTimers = {}
end

function SWEP:ProcessTimers()
    local keeptimers, curTime = {}, CurTime()

    if CLIENT and curTime == tick then return end

    if !self.ActiveTimers then self:InitTimers() end

    for i = 1, #self.ActiveTimers do
        local timer_ = self.ActiveTimers[i]

        if timer_[1] <= curTime then timer_[3]() end
    end

    for i = 1, #self.ActiveTimers do
        local timer_ = self.ActiveTimers[i]

        if timer_[1] > curTime then table.insert(keeptimers, timer_) end
    end

    self.ActiveTimers = keeptimers
end

function SWEP:PlaySoundTable(tbl, key)
    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local start = 0

    for k = 1, #tbl do
        local v = tbl[k]

        if !next(v) then continue end
        if !v.t then continue end

        local ttime = v.t - start

        if ttime < 0 then continue end

        local time = CurTime() + ttime

        -- i may go fucking insane
        if !self.EventTable[1] then self.EventTable[1] = {} end

        local eventTable = self.EventTable

        for i = 1, #eventTable do
            local Event = eventTable[i]

            if Event[time] then
                if !self.EventTable[i + 1] then
                    self.EventTable[i + 1] = {}

                    continue
                end
            else
                self.EventTable[i][time] = table.Copy(v)
                self.EventTable[i][time].StartTime = CurTime()
                self.EventTable[i][time].AnimKey = key

                -- print(CurTime(), "Clean at " .. i)
            end
        end
    end
end