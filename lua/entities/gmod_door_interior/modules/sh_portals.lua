-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

if SERVER then
    ENT:AddHook("PlayerInitialize", "portals", function(self)
        if self.portals then
            net.WriteEntity(self.portals.exterior)
            net.WriteEntity(self.portals.interior)
            if self.customportals then
                net.WriteBool(true)
                net.WriteInt(table.Count(self.customportals),8)
                for k,v in pairs(self.customportals) do
                    net.WriteString(k)
                
                    net.WriteEntity(v.entry)
                    net.WriteBool(v.entry.black)
                
                    net.WriteEntity(v.exit)
                    net.WriteBool(v.exit.black)
                end
            else
                net.WriteBool(false)
            end
        end
    end)

    local function SetupWorldPortals(self, entryEnt, entry, exitEnt, exit)
        local entryPortal=ents.Create("linked_portal_door")
        local exitPortal=ents.Create("linked_portal_door")
        
        entryPortal:SetWidth(entry.width)
        entryPortal:SetHeight(entry.height)
        entryPortal:SetPos(entryEnt:LocalToWorld(entry.pos))
        entryPortal:SetAngles(entryEnt:LocalToWorldAngles(entry.ang))
        entryPortal:SetExit(exitPortal)
        entryPortal:SetParent(entryEnt)
        if entry.link then
            entryPortal:SetCustomLink(entry.link)
        end
        entryPortal.exterior = entryEnt
        entryPortal.interior = exitEnt
        entryPortal.black = entry.black
        entryPortal.fallback = entry.fallback
        entryPortal:Spawn()
        entryPortal:Activate()
        
        exitPortal:SetWidth(exit.width)
        exitPortal:SetHeight(exit.height)
        exitPortal:SetPos(exitEnt:LocalToWorld(exit.pos))
        exitPortal:SetAngles(exitEnt:LocalToWorldAngles(exit.ang))
        exitPortal:SetExit(entryPortal)
        exitPortal:SetParent(exitEnt)
        if exit.link then
            exitPortal:SetCustomLink(exit.link)
        end
        exitPortal.interior = exitEnt
        exitPortal.exterior = entryEnt
        exitPortal.black = exit.black
        exitPortal.fallback = exit.fallback
        exitPortal:Spawn()
        exitPortal:Activate()

        return entryPortal, exitPortal
    end


    local function SetupSeamlessPortals(self, entryEnt, entry, exitEnt, exit)
        local entryPortal=ents.Create("seamless_portal")
        local exitPortal=ents.Create("seamless_portal")
        
        -- entryPortal:SetWidth(entry.width)
        -- entryPortal:SetHeight(entry.height)
        entryPortal:SetPos(entryEnt:LocalToWorld(entry.pos))
        entryPortal:SetAngles(entryEnt:LocalToWorldAngles(entry.ang))
        entryPortal:SetParent(entryEnt)
        -- if entry.link then
        --     entryPortal:SetCustomLink(entry.link)
        -- end
        entryPortal.exterior = entryEnt
        entryPortal.interior = exitEnt
        -- entryPortal.black = entry.black
        -- entryPortal.fallback = entry.fallback
        entryPortal:Spawn()
        entryPortal:Activate()
        
        -- exitPortal:SetWidth(exit.width)
        -- exitPortal:SetHeight(exit.height)
        exitPortal:SetPos(exitEnt:LocalToWorld(exit.pos))
        exitPortal:SetAngles(exitEnt:LocalToWorldAngles(exit.ang))
        exitPortal:SetParent(exitEnt)
        -- if exit.link then
            -- exitPortal:SetCustomLink(exit.link)
        -- end
        exitPortal.interior = exitEnt
        exitPortal.exterior = entryEnt
        -- exitPortal.black = exit.black
        -- exitPortal.fallback = exit.fallback
        exitPortal:Spawn()
        exitPortal:Activate()

        entryPortal:LinkPortal(exitPortal)

        return entryPortal, exitPortal
    end

    function ENT:SetupPortals(entryEnt, entry, exitEnt, exit)
        -- todo: detect seamless portal addon + warn user / fallback to world portals if not there(?)
        if entry.seamless and entry.seamless then
            return SetupSeamlessPortals(self, entryEnt, entry, exitEnt, exit)
        elseif entry.seamless or exit.seamless then
            error("SeamlessPortals must be set to true on both entry and exit portals")
        else
            return SetupWorldPortals(self, entryEnt, entry, exitEnt, exit)
        end
    end
    
    ENT:AddHook("PreInitialize", "portals", function(self)
        local int=self.Portal
        local ext=self.exterior.Portal
        if not (int and ext) then return end
        self.portals={}
        
        self.portals.exterior, self.portals.interior = self:SetupPortals(self.exterior, ext, self, int)
        
        if self.CustomPortals then
            self.customportals={}
            for k,v in pairs(self.CustomPortals) do
                self.customportals[k] = {}
                local portals = self.customportals[k]
                portals.entry, portals.exit = self:SetupPortals(self, v.entry, self, v.exit)
            end
        end
    end)

    ENT:AddHook("PostTeleportPortal", "portals", function(self,portal,ent)
        if portal~=self.portals.interior and portal.fallback and ent:IsPlayer() and self:IsStuck(ent) then
            ent:SetPos(self:LocalToWorld(portal.fallback))
        end
    end)

    hook.Add("wp-shouldtp","doors-portals",function(portal,ent)
        local p = portal:GetParent()
        if IsValid(p) and (p.DoorInterior or p.DoorExterior) and p._init then
            return p:CallHook("ShouldTeleportPortal",portal,ent)
        end
    end)
    
    hook.Add("wp-teleport","doors-portals",function(portal,ent)
        local p=portal:GetParent()
        if IsValid(p) and (p.DoorInterior or p.DoorExterior) and p._init then
            return p:CallHook("PostTeleportPortal",portal,ent)
        end
    end)
else
    ENT:AddHook("Initialize","interior",function(self)
        self.contains = {}
    end)
    
    ENT:AddHook("PlayerInitialize", "portals", function(self)
        self.portals={}
        local exterior=net.ReadEntity()
        local interior=net.ReadEntity()
        if IsValid(exterior) and IsValid(interior) then
            self.portals.exterior=exterior
            self.portals.exterior.exterior=self.exterior
            self.portals.exterior.interior=self
            
            self.portals.interior=interior
            self.portals.interior.exterior=self.exterior
            self.portals.interior.interior=self
        end
        
        if net.ReadBool() then
            self.customportals={}
            local count=net.ReadInt(8)
            for i=1,count do
                local k=net.ReadString()
                self.customportals[k]={}
                local portals = self.customportals[k]
            
                portals.entry=net.ReadEntity()
                portals.entry.exterior = self.exterior
                portals.entry.interior = self
                portals.entry.black = net.ReadBool()
            
                portals.exit=net.ReadEntity()
                portals.exit.exterior = self.exterior
                portals.exit.interior = self
                portals.exit.black = net.ReadBool()
            end
        end
    end)
    
    ENT:AddHook("ShouldDraw", "portals", function(self)
        local insideof = IsValid(wp.drawingent) and wp.drawingent.exterior and wp.drawingent.exterior.insideof==self and wp.drawingent.interior.portals.interior==wp.drawingent
        if wp.drawing and wp.drawingent==self.portals.interior and not (wp.drawingent==self.portals.interior and self.props[self.exterior]) and (not insideof) then
            return false
        end
        if wp.drawing and wp.drawingent.interior and wp.drawingent.interior ~= self and wp.drawingent.exterior and wp.drawingent.exterior.insideof~=self then
            return false
        end
    end)

    ENT:AddHook("ShouldRenderPortal", "portals", function(self)
        if LocalPlayer().doori~=self then
            return false
        end
    end)
    
    hook.Add("wp-shouldrender", "doors-portals", function(portal,exit,origin)
        local p=portal:GetParent()
        if IsValid(p) then
            if p.DoorExterior or p.DoorInterior then
                if not p._init then return false end
                return p:CallHook("ShouldRenderPortal",portal,exit,origin)
            end
        end
    end)
    
    hook.Add("wp-predraw","doors-portals",function(portal)
        local p=portal:GetParent()
        if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
            p:CallHook("PreDrawPortal",portal)
        end
    end)
    
    hook.Add("wp-postdraw","doors-portals",function(portal)
        local p=portal:GetParent()
        if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
            p:CallHook("PostDrawPortal",portal)
        end
    end)

    hook.Add("wp-prerender","doors-portals",function(portal)
        local p=portal:GetParent()
        if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
            p:CallHook("PreRenderPortal",portal)
        end
    end)
    
    hook.Add("wp-postrender","doors-portals",function(portal)
        local p=portal:GetParent()
        if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
            p:CallHook("PostRenderPortal",portal)
        end
    end)
end

hook.Add("wp-trace", "doors-portals", function(portal)
    local p=portal:GetParent()
    if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
        return p:CallHook("ShouldTracePortal",portal)
    end
end)

hook.Add("wp-tracefilter", "doors-portals", function(portal)
    local p=portal:GetParent()
    if IsValid(p) and (p.DoorExterior or p.DoorInterior) and p._init then
        return p:CallHook("TraceFilterPortal",portal)
    end
end)