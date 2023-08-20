ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "chicagoRP - Basketball"
ENT.Category = "chicagoRP"
ENT.Author = "SpiffyJUNIOR"
ENT.Spawnable = true
ENT.IsBasketball = true

function ENT:GetController()
    return self.Controller
end

function ENT:SetController(swep)
    self.Controller = swep
end