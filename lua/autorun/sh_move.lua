hook.Add("SetupMove", "chicagoRP_basketball_move", function(ply, mv, cmd)
    local wep = ply:GetActiveWeapon()

    if !IsValid(wep) then return end
    if !wep.IsBasketball then return end

    local isThrowing = wep:GetIsThrowing()
    local isDunking = wep:GetIsDunking()

    if !isThrowing and !isDunking then return end

    local jumpPower = ply:GetJumpPower()

    if isDunking then
        ply:SetJumpPower(jumpPower + 200)
    elseif isThrowing then
        ply:SetJumpPower(jumpPower + 50)
    end
end)