-- April fools :)

ENT:AddHook("SetupPosition", "aprilfools", function(self,pos)
    if not Doors:IsAprilFools() then return end
    local mins = Vector(self.mins or self:OBBMins())
    local maxs = Vector(self.maxs or self:OBBMaxs())
    self:SetAngles(Angle(0,0,180))
    return pos + Vector(0,0,maxs.z+mins.z)
end)

ENT:AddHook("PlayerEnter", "aprilfools", function(self,ply)
    if (not Doors:IsAprilFools()) or ply.doors_aprilfools then return end
    ply.doors_aprilfools = true
    timer.Simple(10, function()
        if IsValid(ply) then
            ply:ChatPrint("April fools! :) (doors_aprilfools_2021 0 in console to disable)")
        end
    end)
end)