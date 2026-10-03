--// astro.MAIN




























game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Notification",
    Text = "ty for buying",
    Duration = 5
})

--// Compatibility bootstrap: Da Hood-style forks may not expose the same module tree.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function findChildPath(root, ...)
    local current = root
    for _, name in ipairs({...}) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local handler = nil
local oldFunc = nil
do
    local gunHandlerModule = findChildPath(ReplicatedStorage, "Modules", "GunHandler")
    if gunHandlerModule and gunHandlerModule:IsA("ModuleScript") then
        local ok, result = pcall(require, gunHandlerModule)
        if ok and type(result) == "table" and type(result.getAim) == "function" then
            handler = result
            oldFunc = result.getAim
        end
    end
end

plrs = game:GetService("Players")
me = plrs.LocalPlayer
RunService = game:GetService("RunService")
cam = workspace.CurrentCamera
mouse = me:GetMouse()
aimPart = "Head"

_G.AyeshaCompatibility = {
    GunHandler = handler ~= nil,
    SkinModules = ReplicatedStorage:FindFirstChild("SkinModules") ~= nil,
    SkinAssets = ReplicatedStorage:FindFirstChild("SkinAssets") ~= nil,
}

_G.FOV_RADIUS = 1000
_G.RevolverBypass = false
_G.WallCheck = false

_G.ESP_Boxes = false
_G.ESP_Names = false
_G.ESP_Distance = false
_G.ESP_Snaplines = false
_G.ESP_Skeleton = false
_G.ESP_Color = Color3.fromRGB(105, 175, 255)

_G.Speed_Enabled = false
_G.Speed_Value = 50
_G.Speed_Key = Enum.KeyCode.X
_G.Speed_ToggleEnabled = false
_G.HitboxEnabled = false
_G.HitboxSize = 100
_G.HitboxTransparency = 0
_G.HitboxColor = Color3.fromRGB(145, 210, 240)

--// Flamelock
_G.FlamelockEnabled = false
_G.FlameMode = "Hold"
_G.FlameKey = Enum.KeyCode.Z
_G.FlameRightClick = false
_G.FlameSmoothness = 0.35
_G.FlamePrediction = 0
_G.FlameLeftOffset = 0
_G.FlameUpOffset = 0
_G.FlameHitPart = "Body"
_G.FlameActive = false
flameTargetPart = nil

--// TriggerBot
TriggerBot = {
    Enabled = false,
    Mode = "Hold",
    Key = Enum.KeyCode.T,
    Active = false,
    ClickDelay = 0.02,
    Blacklist = {"Knife", "Wallet", "Phone", "Chicken", "Pizza", "Flashlight", "Medkit"},
    LastClick = 0
}


HitboxOriginals = setmetatable({}, {__mode = "k"})

function saveHitboxOriginal(hrp)
    if not hrp or HitboxOriginals[hrp] then return end
    HitboxOriginals[hrp] = {
        Size = hrp.Size,
        Transparency = hrp.Transparency,
        Color = hrp.Color,
        Material = hrp.Material,
        CanCollide = hrp.CanCollide,
        CanTouch = hrp.CanTouch,
        CanQuery = hrp.CanQuery,
    }
end

function restoreHitbox(hrp)
    local original = HitboxOriginals[hrp]
    if not hrp or not original then return end
    pcall(function()
        hrp.Size = original.Size
        hrp.Transparency = original.Transparency
        hrp.Color = original.Color
        hrp.Material = original.Material
        hrp.CanCollide = original.CanCollide
        hrp.CanTouch = original.CanTouch
        hrp.CanQuery = original.CanQuery
    end)
    HitboxOriginals[hrp] = nil
end

function updateAyeshaHitboxes()
    for _, plr in ipairs(plrs:GetPlayers()) do
        if plr ~= me and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if _G.HitboxEnabled and not (_G.Whitelist and _G.Whitelist[plr.UserId]) then
                    saveHitboxOriginal(hrp)
                    pcall(function()
                        hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                        hrp.Transparency = 1 - math.clamp(_G.HitboxTransparency, 0, 1)
                        hrp.Color = _G.HitboxColor
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                        hrp.CanTouch = true
                        hrp.CanQuery = true
                    end)
                else
                    restoreHitbox(hrp)
                end
            end
        end
    end
end

function setupAyeshaHitboxPlayer(plr)
    if plr == me then return end
    plr.CharacterAdded:Connect(function()
        task.wait(0.35)
        updateAyeshaHitboxes()
    end)
end

for _, plr in ipairs(plrs:GetPlayers()) do
    setupAyeshaHitboxPlayer(plr)
end
plrs.PlayerAdded:Connect(setupAyeshaHitboxPlayer)
plrs.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then restoreHitbox(hrp) end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        updateAyeshaHitboxes()
    end
end)


-- High Jump settings
_G.HighJump_Enabled = false
_G.HighJump_Value = 50

-- Fly settings
_G.Fly_Enabled = false
_G.Fly_Speed = 50
_G.Fly_Keybind = Enum.KeyCode.F
local Fly_KeybindListening = false
FlyKeyState = {W=false,A=false,S=false,D=false,Space=false,LeftControl=false}

-- Whitelist settings
whitelist = {}

--// Integrated Astro.MAIN backend
replicatedstorage = game:GetService("ReplicatedStorage")
players = game:GetService("Players")
localplayer = me
StarterGui = game:GetService("StarterGui")
skinStatus = nil
MUTED = Color3.fromRGB(92, 103, 76)
GREEN = Color3.fromRGB(113, 177, 139)

function clearAyeshaFlame(tool)
    if not tool then return end
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj.Name:sub(1, 15) == "AyeshaSkinFX__" then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- skin config
shared.Glory = {
    ['skins'] = {
        ['enabled'] = false, -- skins apply when the user selects them
        ['weapons'] = {
            ['[Double-Barrel SG]'] = "",
            ['[Revolver]'] = "",
            ['[TacticalShotgun]'] = "",
            ['[Knife]'] = "",
            ['[Shotgun]'] = "",
        },
    },
}

cfg = shared.Glory
knifedata = {}
toolregistry = {}

-- Extra weapon slots start empty; skins apply when the user selects them.


-- knife skins data table
knifeskins = {
    ["Golden Age Tanto"] = {
        soundid = "rbxassetid://5917819099",
        animationid = "rbxassetid://13473404819",
        positionoffset = Vector3.new(0, -0.20, -1.2),
        rotationoffset = Vector3.new(90, 263.7, 180)
    },
    
    ["GPO-Knife"] = {
        soundid = "rbxassetid://4604390759", 
        animationid = "rbxassetid://14014278925", 
        positionoffset = Vector3.new(0.00, -0.32, -1.07), 
        rotationoffset = Vector3.new(90, -97.4, 90)
    },
    
    ["GPO-Knife Prestige"] = {
        soundid = "rbxassetid://4604390759", 
        animationid = "rbxassetid://14014278925", 
        positionoffset = Vector3.new(0.00, -0.32, -1.07), 
        rotationoffset = Vector3.new(90, -97.4, 90)
    },
    ["Love Kukri"] = {
        soundid = "",
        animationid = "",
        positionoffset = Vector3.new(0, 0, 0),
        rotationoffset = Vector3.new(90, 0, 0)
    },
    
    ["Heaven"] = {
        soundid = "rbxassetid://14489860007", 
        animationid = "rbxassetid://14500266726", 
        positionoffset = Vector3.new(-0.02, -0.82, 0.20), 
        rotationoffset = Vector3.new(64.42, 3.79, 0.00)
    },
    
    ["Love Kukri"] = {
        soundid = "", 
        animationid = "", 
        positionoffset = Vector3.new(-0.14, 0.14, -1.62), 
        rotationoffset = Vector3.new(-90.00, 180.00, -4.97), 
        particle = true, 
        textureid = "rbxassetid://12124159284"
    },
    
    ["Purple Dagger"] = {
        soundid = "rbxassetid://17822743153", 
        animationid = "rbxassetid://17824999722", 
        positionoffset = Vector3.new(-0.13, -0.24, -1.80), 
        rotationoffset = Vector3.new(89.05, 96.63, 180.00)
    },
    
    ["Blue Dagger"] = {
        soundid = "rbxassetid://17822737046", 
        animationid = "rbxassetid://17824995184", 
        positionoffset = Vector3.new(-0.13, -0.24, -1.80), 
        rotationoffset = Vector3.new(89.05, 96.63, 180.00)
    },
    
    ["Green Dagger"] = {
        soundid = "rbxassetid://17822741762", 
        animationid = "rbxassetid://17825004320", 
        positionoffset = Vector3.new(-0.13, -0.24, -1.07), 
        rotationoffset = Vector3.new(89.05, 96.63, 180.00)
    },
    
    ["Red Dagger"] = {
        soundid = "rbxassetid://17822952417", 
        animationid = "rbxassetid://17825008844", 
        positionoffset = Vector3.new(-0.13, -0.24, -1.07), 
        rotationoffset = Vector3.new(89.05, 96.63, 180.00)
    },
    
    ["Portal"] = {
        soundid = "rbxassetid://16058846352", 
        animationid = "rbxassetid://16058633881", 
        positionoffset = Vector3.new(-0.13, -0.35, -0.57), 
        rotationoffset = Vector3.new(89.05, 96.63, 180.00)
    },
    
    ["Emerald Butterfly"] = {
        soundid = "rbxassetid://14931902491", 
        animationid = "rbxassetid://14918231706", 
        positionoffset = Vector3.new(-0.02, -0.30, -0.65), 
        rotationoffset = Vector3.new(180.00, 90.95, 180.00)
    },
    
    ["Boy"] = {
        soundid = "rbxassetid://18765078331", 
        animationid = "rbxassetid://18789158908", 
        positionoffset = Vector3.new(-0.02, -0.09, -0.73), 
        rotationoffset = Vector3.new(89.05, -88.11, 180.00)
    },
    
    ["Girl"] = {
        soundid = "rbxassetid://18765078331", 
        animationid = "rbxassetid://18789162944", 
        positionoffset = Vector3.new(-0.02, -0.16, -0.73), 
        rotationoffset = Vector3.new(89.05, -88.11, 180.00)
    },
    
    ["Dragon"] = {
        soundid = "rbxassetid://14217789230", 
        animationid = "rbxassetid://14217804400", 
        positionoffset = Vector3.new(-0.02, -0.32, -0.98), 
        rotationoffset = Vector3.new(89.05, 90.95, 180.00)
    },
    
    ["Void"] = {
        soundid = "rbxassetid://14756591763", 
        animationid = "rbxassetid://14774699952", 
        positionoffset = Vector3.new(-0.02, -0.22, -0.85), 
        rotationoffset = Vector3.new(180.00, 90.95, 180.00)
    },
    
    ["Wild West"] = {
        soundid = "rbxassetid://16058689026", 
        animationid = "rbxassetid://16058148839", 
        positionoffset = Vector3.new(-0.02, -0.24, -1.15), 
        rotationoffset = Vector3.new(-91.89, 90.95, 180.00)
    },
    
    ["Iced Out"] = {
        soundid = "rbxassetid://14924261405", 
        animationid = "rbxassetid://18465353361", 
        positionoffset = Vector3.new(0.02, -0.08, 0.99), 
        rotationoffset = Vector3.new(180.00, -90.95, -180.00)
    },
    
    ["Reptile"] = {
        soundid = "rbxassetid://18765103349", 
        animationid = "rbxassetid://18788955930", 
        positionoffset = Vector3.new(-0.03, -0.06, -0.92), 
        rotationoffset = Vector3.new(168.63, 90.00, -180.00)
    },
    
    ["Emerald"] = {
        soundid = "", 
        animationid = "", 
        positionoffset = Vector3.new(-0.03, -0.06, -0.92), 
        rotationoffset = Vector3.new(168.63, 90.00, 108.00)
    },
    
    ["Ribbon"] = {
        soundid = "rbxassetid://130974579277249", 
        animationid = "rbxassetid://124102609796063", 
        positionoffset = Vector3.new(0.02, -0.25, -0.05), 
        rotationoffset = Vector3.new(90.00, 0.00, 180.00)
    },
}

-- helper function to clear mesh
function clearmesh(tool, exclude)
    local children = tool:GetChildren()
    for i = 1, #children do
        local v = children[i]
        if v:IsA("MeshPart") and v ~= exclude then
            v:Destroy()
        end
    end
end

copyGunSkinVisuals = nil
originalGunState = setmetatable({}, {__mode = "k"})

-- Save the untouched gun state once so  can truly restore it.
function saveOriginalGunState(tool)
    if originalGunState[tool] then return end
    local handle = tool:FindFirstChild("Handle")
    local orig = tool:FindFirstChildOfClass("MeshPart")
    if not orig then return end
    local state = {
        texture = orig.TextureID,
        transparency = orig.Transparency,
        soundId = nil,
        particles = {},
    }
    if handle then
        local shoot = handle:FindFirstChild("ShootSound")
        if shoot then state.soundId = shoot.SoundId end
        for _, obj in ipairs(handle:GetChildren()) do
            if obj:IsA("ParticleEmitter") and obj.Name:sub(1,15) ~= "AyeshaSkinFX__" then
                table.insert(state.particles, obj:Clone())
            end
        end
    end
    originalGunState[tool] = state
end

function resetGun(tool)
    clearAyeshaFlame(tool)
    local orig = tool:FindFirstChildOfClass("MeshPart")
    if not orig then return end
    local state = originalGunState[tool]
    -- Remove any generated skin parts.
    for _, obj in ipairs(tool:GetChildren()) do
        if obj.Name == "CurrentSkin" or (obj:IsA("MeshPart") and obj ~= orig) then
            pcall(function() obj:Destroy() end)
        end
    end
    local handle = tool:FindFirstChild("Handle")
    if handle then
        for _, obj in ipairs(handle:GetChildren()) do
            if obj.Name:sub(1,15) == "AyeshaSkinFX__" then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
        if state then
            local shoot = handle:FindFirstChild("ShootSound")
            if shoot and state.soundId ~= nil then shoot.SoundId = state.soundId end
            for _, particle in ipairs(state.particles) do particle:Clone().Parent = handle end
        end
    end
    if state then
        orig.TextureID = state.texture
        orig.Transparency = state.transparency
    end
    handle = tool:FindFirstChild("Handle")
    if handle then handle:SetAttribute("SkinName", nil) end
end

-- apply gun skin
function applygun(tool, name)
    saveOriginalGunState(tool)
    local orig = tool:FindFirstChildOfClass("MeshPart")
    if not orig then return end

    local skinmodules = replicatedstorage:FindFirstChild("SkinModules")
    if not skinmodules then 
        warn("SkinModules not found in ReplicatedStorage")
        return 
    end

    local ok, skinmodulesreq = pcall(function()
        return require(skinmodules)
    end)
    if not ok or not skinmodulesreq then 
        warn("Failed to require SkinModules")
        return 
    end

    -- Skin entries can be nested differently between weapon categories.
    -- Resolve the selected name anywhere inside that weapon's own SkinModules bucket.
    local function findSkinEntry(t, wanted, depth, seen)
        if type(t) ~= "table" or depth > 10 then return nil end
        seen = seen or {}
        if seen[t] then return nil end
        seen[t] = true

        -- Prefer an exact key whose value looks like a skin definition.
        local exact = t[wanted]
        if type(exact) == "table" then
            return exact
        end

        for k, v in pairs(t) do
            if type(k) == "string" and k == wanted and type(v) == "table" then
                return v
            end
        end
        for _, v in pairs(t) do
            if type(v) == "table" then
                local found = findSkinEntry(v, wanted, depth + 1, seen)
                if found then return found end
            end
        end
        return nil
    end

    local bucket = skinmodulesreq[tool.Name]
    local info = findSkinEntry(bucket, name, 0)
    if not info then
        warn("Skin info not found for:", tool.Name, name)
        return
    end

    clearmesh(tool, orig)

    local skinpart = info.TextureID
    if typeof(skinpart) == "Instance" then
        local clone = skinpart:Clone()
        clone.Parent = tool
        clone.CFrame = orig.CFrame
        clone.Name = "CurrentSkin"

        local w = Instance.new("Weld")
        w.Part0 = clone
        w.Part1 = orig
        w.C0 = info.CFrame:Inverse()
        w.Parent = clone

        orig.Transparency = 1
    else
        orig.TextureID = skinpart
        orig.Transparency = 0
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- handle sound
    local shoot = handle:FindFirstChild("ShootSound")
    if shoot then
        local skinassets = replicatedstorage:FindFirstChild("SkinAssets")
        if skinassets then
            local gunsounds = skinassets:FindFirstChild("GunShootSounds")
            if gunsounds then
                local sounds = gunsounds:FindFirstChild(tool.Name)
                local obj = sounds and sounds:FindFirstChild(name)
                if obj then
                    shoot.SoundId = obj.Value
                end
            end
        end
    end

    -- handle particles
    local skinassets = replicatedstorage:FindFirstChild("SkinAssets")
    if skinassets then
        local particlefolder = skinassets:FindFirstChild("GunHandleParticle")
        if particlefolder then
            local particlesource = particlefolder:FindFirstChild(name)
            if particlesource then
                local pe = particlesource:FindFirstChild("ParticleEmitter")
                if pe then
                    for _, existing in ipairs(handle:GetChildren()) do
                        if existing:IsA("ParticleEmitter") then
                            existing:Destroy()
                        end
                    end
                    pe:Clone().Parent = handle
                end
            end
        end
    end

    copyGunSkinVisuals(tool, name)
    handle:SetAttribute("SkinName", name)
end

-- clean knife data
function cleanknife(tool)
    local data = knifedata[tool]
    if data then
        if data.track then
            data.track:Stop()
            data.track:Destroy()
            data.track = nil
        end
        if data.welds then
            for _, w in ipairs(data.welds) do
                if w then w:Destroy() end
            end
        end
        if data.sounds then
            for _, s in ipairs(data.sounds) do
                if s and s.Parent then s:Destroy() end
            end
        end
    end

    local mesh = tool:FindFirstChild("Default") or tool:FindFirstChild("Handle")
    if not mesh then
        mesh = tool:FindFirstChildWhichIsA("BasePart", true)
    end
    if mesh then
        local children = mesh:GetChildren()
        for i = 1, #children do
            local v = children[i]
            if v.Name == "Handle.R" or v:IsA("Model") or (v:IsA("BasePart") and v.Name ~= "Default") then
                v:Destroy()
            end
        end
        mesh.Transparency = 0
    end

    knifedata[tool] = nil
end

-- Resolve each knife skin's own animation and sound.
-- Prefer the animation explicitly defined for the skin, then fall back to
-- animation data stored on the current game's skin model. No generic animation
-- is forced, so Bubu and every other skin can keep its own movement.
function resolveKnifeAssets(skinmodel, skincfg)
    local soundid = skincfg and skincfg.soundid or ""
    local animationid = skincfg and skincfg.animationid or ""

    if (not animationid or animationid == "") and skinmodel then
        -- Support an Animation instance inside the skin model.
        for _, obj in ipairs(skinmodel:GetDescendants()) do
            if obj:IsA("Animation") and obj.AnimationId and obj.AnimationId ~= "" then
                animationid = obj.AnimationId
                break
            end
        end

        -- Support common attribute/value names used by skin modules.
        if not animationid or animationid == "" then
            local candidates = {"AnimationId", "animationid", "Animation", "animation"}
            for _, name in ipairs(candidates) do
                local value = skinmodel:GetAttribute(name)
                if type(value) == "string" and value ~= "" then
                    animationid = value
                    break
                end
            end
        end
    end

    if (not soundid or soundid == "") and skinmodel then
        for _, obj in ipairs(skinmodel:GetDescendants()) do
            if obj:IsA("Sound") and obj.SoundId and obj.SoundId ~= "" then
                soundid = obj.SoundId
                break
            end
        end
    end

    return animationid or "", soundid or ""
end

-- Copy only visual bullet/muzzle/trail effects that the current game's SkinAssets exposes.
-- This preserves things such as green/black/etc. bullet visuals without hardcoding them.
copyGunSkinVisuals = function(tool, skin)
    local handle = tool:FindFirstChild("Handle")
    local skinassets = replicatedstorage:FindFirstChild("SkinAssets")
    if not handle or not skinassets then return end

    for _, old in ipairs(handle:GetChildren()) do
        if old.Name:sub(1, 15) == "AyeshaSkinFX__" then
            old:Destroy()
        end
    end

    local folderNames = {
        "GunHandleParticle", "BulletTrail", "GunBulletTrail", "BulletEffect",
        "GunBulletEffect", "GunMuzzleFlash", "MuzzleFlash", "MuzzleEffect", "GunTrail"
    }

    for _, folderName in ipairs(folderNames) do
        local folder = skinassets:FindFirstChild(folderName)
        local source = folder and folder:FindFirstChild(skin)
        if source then
            for _, obj in ipairs(source:GetChildren()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Attachment") then
                    local clone = obj:Clone()
                    clone.Name = "AyeshaSkinFX__" .. obj.Name
                    clone.Parent = handle
                end
            end
        end
    end
end

-- Robust knife model lookup. Golden Age Tanto is used as the requested classic golden knife skin.
function findKnifeModel(knives, wanted)
    if not knives then return nil end
    local direct = knives:FindFirstChild(wanted)
    if direct then return direct end
    local wantedLower = string.lower(tostring(wanted))
    for _, obj in ipairs(knives:GetDescendants()) do
        if string.lower(obj.Name) == wantedLower then
            return obj
        end
    end
    return nil
end

-- apply knife skin
function applyknife(char, tool, skin)
    -- Config is optional. Unknown knife skins still work with their model's own appearance.
    local skincfg = knifeskins[skin] or {
        soundid = "", animationid = "",
        positionoffset = Vector3.new(0, 0, 0),
        rotationoffset = Vector3.new(90, 0, 0)
    }

    local hum = char:FindFirstChild("Humanoid")
    local rhand = char:FindFirstChild("RightHand")
    if not hum or not rhand then return end

    cleanknife(tool)
    knifedata[tool] = {track = nil, welds = {}, sounds = {}}
    local data = knifedata[tool]

    -- Do not require a specific "Default" part; different game versions use
    -- different knife tool layouts.  Prefer Default, then Handle, then any
    -- BasePart so the visual can still be attached.
    local mesh = tool:FindFirstChild("Default") or tool:FindFirstChild("Handle")
    if not mesh then
        mesh = tool:FindFirstChildWhichIsA("BasePart", true)
    end
    if not mesh then
        warn("Knife tool has no BasePart to attach the skin to")
        return
    end
    mesh.Transparency = 1

    local skinmodules = replicatedstorage:FindFirstChild("SkinModules")
    if not skinmodules then 
        warn("SkinModules not found")
        return 
    end
    
    local knives = skinmodules:FindFirstChild("Knives")
    if not knives then 
        warn("Knives folder not found in SkinModules")
        return 
    end

    local modelName = skin
    local skinmodel = findKnifeModel(knives, modelName)

    if not skinmodel and skin == "Golden Age Tanto" then
        skinmodel = findKnifeModel(knives, "Golden Age Tanto")
    end

    if not skinmodel then 
        warn("Skin model not found:", skin)
        return 
    end
    
    local clone = skinmodel:Clone()
    clone.Name = skin

    local handr = Instance.new("Part")
    handr.Name = "Handle.R"
    handr.Transparency = 1
    handr.CanCollide = false
    handr.Anchored = false
    handr.Size = Vector3.new(0.001, 0.001, 0.001)
    handr.Massless = true
    handr.Parent = mesh

    local m6d = Instance.new("Motor6D")
    m6d.Name = "Handle.R"
    m6d.Part0 = rhand
    m6d.Part1 = handr
    m6d.Parent = handr

    local offset = CFrame.new(skincfg.positionoffset) * CFrame.Angles(
        math.rad(skincfg.rotationoffset.X), 
        math.rad(skincfg.rotationoffset.Y), 
        math.rad(skincfg.rotationoffset.Z)
    )

    if clone:IsA("Model") then
        if not clone.PrimaryPart then
            for _, c in ipairs(clone:GetDescendants()) do
                if c:IsA("BasePart") then
                    clone.PrimaryPart = c
                    break
                end
            end
        end

        if clone.PrimaryPart then
            -- Position the complete model first, then weld every part to the hand.
            -- This avoids the old per-part CFrame math that could rotate/offset skins incorrectly.
            clone.Parent = mesh
            for _, p in ipairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                    p.Massless = true
                    p.Anchored = false
                end
            end

            clone:PivotTo(handr.CFrame * offset)

            for _, p in ipairs(clone:GetDescendants()) do
                if p:IsA("BasePart") then
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = handr
                    w.Part1 = p
                    w.Parent = p
                    table.insert(data.welds, w)
                end
            end
        else
            clone:Destroy()
        end
    elseif clone:IsA("BasePart") then
        clone.CanCollide = false
        clone.Massless = true
        clone.Anchored = false

        if clone:IsA("MeshPart") and skincfg.textureid then
            clone.TextureID = skincfg.textureid
        end

        if skincfg.particle then
            local skinassets = replicatedstorage:FindFirstChild("SkinAssets")
            if skinassets then
                local particlefolder = skinassets:FindFirstChild("GunHandleParticle")
                if particlefolder then
                    local particlesource = particlefolder:FindFirstChild(skin)
                    if particlesource then
                        local pe = particlesource:FindFirstChild("ParticleEmitter")
                        if pe then
                            pe:Clone().Parent = clone
                        end
                    end
                end
            end
        end

        clone.Parent = mesh
        clone.CFrame = handr.CFrame * offset
        local w = Instance.new("WeldConstraint")
        w.Part0 = handr
        w.Part1 = clone
        w.Parent = clone
        table.insert(data.welds, w)
    end

    local animationid, soundid = resolveKnifeAssets(skinmodel, skincfg)

    if animationid ~= "" then
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = animationid
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        anim:Destroy()
        if ok and track then
            track.Looped = false
            track:Play()
            data.track = track
            track.Ended:Once(function()
                if data.track == track then data.track = nil end
                track:Destroy()
            end)
        end
    end

    -- If the skin has no sound, do not invent/copy one.
    if soundid ~= "" then
        local snd = Instance.new("Sound")
        snd.SoundId = soundid
        snd.Parent = workspace
        snd:Play()
        table.insert(data.sounds, snd)
        snd.Ended:Connect(function() snd:Destroy() end)
    end

    tool:SetAttribute("CurrentKnifeSkin", skin)
end

-- setup tool with skin
function setuptool(tool)
    if not tool:IsA("Tool") then return end
    if toolregistry[tool] then return end
    toolregistry[tool] = true

    tool.Equipped:Connect(function()
        if not cfg['skins']['enabled'] then return end

        local char = tool.Parent
        if char ~= localplayer.Character then return end

        local skin = cfg['skins']['weapons'][tool.Name]
        if not skin or skin == "" then return end

        if tool.Name == "[Knife]" then
            applyknife(char, tool, skin)
        else
            applygun(tool, skin)
        end
    end)

    tool.Unequipped:Connect(function()
        if tool.Name == "[Knife]" then
            cleanknife(tool)
        end
    end)

end

-- watch character for tools
function watchchar(char)
    if not char then return end
    local children = char:GetChildren()
    for i = 1, #children do
        local v = children[i]
        if v:IsA("Tool") then
            setuptool(v)
        end
    end
    char.ChildAdded:Connect(function(v)
        if v:IsA("Tool") then
            setuptool(v)
        end
    end)
end

-- initialize
if localplayer.Character then
    watchchar(localplayer.Character)
end

localplayer.CharacterAdded:Connect(function(char)
    watchchar(char)
end)

-- watch backpack for tools
backpacktools = localplayer.Backpack:GetChildren()
for i = 1, #backpacktools do
    local v = backpacktools[i]
    if v:IsA("Tool") then
        setuptool(v)
    end
end

localplayer.Backpack.ChildAdded:Connect(function(v)
    if v:IsA("Tool") then
        setuptool(v)
    end
end)

-- =========================

weapons={"[Double-Barrel SG]","[Revolver]","[TacticalShotgun]","[Shotgun]","[Knife]"}
names={["[Double-Barrel SG]"]="Double-Barrel",["[Revolver]"]="Revolver",["[TacticalShotgun]"]="Tactical Shotgun",["[Shotgun]"]="Shotgun",["[Knife]"]="Knife"}
icons={["[Double-Barrel SG]"]="DB",["[Revolver]"]="RV",["[TacticalShotgun]"]="TS",["[Shotgun]"]="SG",["[Knife]"]="KN"}
tabButtons={}

function clear()
    for _,v in ipairs(inner:GetChildren()) do if not v:IsA("UIListLayout") then v:Destroy() end end
end
function heading(title,sub)
    clear(); txt(inner,title,19,UDim2.fromOffset(2,0),Enum.Font.GothamBold,TEXT); txt(inner,sub,10,UDim2.fromOffset(2,27),Enum.Font.Gotham,MUTED)
end
function getNames(toolName)
    local out, seen = {}, {}
    local function add(name)
        name = tostring(name or "")
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(out, name)
        end
    end

    local sm = replicatedstorage:FindFirstChild("SkinModules")
    if toolName == "[Knife]" then
        -- Show the configured classic knife collection, but only when the
        -- skin actually exists in the current game's SkinModules.
        local knives = sm and sm:FindFirstChild("Knives")
        -- Keep the requested classic entries visible in Astro.MAIN. The apply
        -- function still verifies that the selected skin exists in the game.
        add("Golden Age Tanto")
        add("GPO-Knife Prestige")
        if knives and knives:FindFirstChild("Love Kukri") then
            add("Love Kukri")
        end
        if knives then
            for skinName in pairs(knifeskins) do
                if skinName ~= "Makeshift Knife" and skinName ~= "Golden Age Tanto" and skinName ~= "GPO-Knife Prestige" and knives:FindFirstChild(skinName) then
                    add(skinName)
                end
            end
        end
    elseif sm then
        local ok, data = pcall(require, sm)
        if ok and type(data) == "table" then
            local bucket = data[toolName]
            local seenTables = {}
            local function looksLikeSkin(t)
                return type(t) == "table" and (t.TextureID ~= nil or t.CFrame ~= nil or t.MeshID ~= nil or t.Texture ~= nil)
            end
            local function walk(t, depth)
                if type(t) ~= "table" or depth > 10 or seenTables[t] then return end
                seenTables[t] = true
                for k, v in pairs(t) do
                    if type(k) == "string" and type(v) == "table" and looksLikeSkin(v) then
                        add(k)
                    end
                    if type(v) == "table" then walk(v, depth + 1) end
                end
            end
            walk(bucket, 0)
        end
    end

    table.sort(out, function(a,b) return string.lower(a) < string.lower(b) end)
    return out
end

function hasGameSkin(toolName, wanted)
    local sm = replicatedstorage:FindFirstChild("SkinModules")
    if not sm then return false end

    if toolName == "[Knife]" then
        local knives = sm:FindFirstChild("Knives")
        return knives and knives:FindFirstChild(wanted) ~= nil
    end

    local ok, data = pcall(require, sm)
    if not ok or type(data) ~= "table" then return false end

    local bucket = data[toolName]
    local seen = {}
    local function walk(t, depth)
        if type(t) ~= "table" or depth > 10 or seen[t] then return false end
        seen[t] = true
        for k, v in pairs(t) do
            if k == wanted and type(v) == "table" then
                return true
            end
            if type(v) == "table" and walk(v, depth + 1) then
                return true
            end
        end
        return false
    end
    return walk(bucket, 0)
end

function applySkin(toolName,skin)
    if not skin or skin=="" then return end

    -- Do not apply a stale skin name that is absent from the current game data.
    if toolName == "[Knife]" then
        local sm = replicatedstorage:FindFirstChild("SkinModules")
        local knives = sm and sm:FindFirstChild("Knives")
        local exists = knives and findKnifeModel(knives, skin) ~= nil
        if not exists then
            skinStatus.Text = "● SKIN NOT FOUND"
            skinStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Astro.MAIN",
                    Text = "That knife skin does not exist in the current SkinModules.",
                    Duration = 2
                })
            end)
            return
        end
    end

    cfg.skins.enabled=true; cfg.skins.weapons[toolName]=skin
    local char=localplayer.Character; local tool=char and char:FindFirstChild(toolName)
    if tool and tool:IsA("Tool") then
        if toolName=="[Knife]" then applyknife(char,tool,skin) else applygun(tool,skin) end
        skinStatus.Text="● APPLIED"; skinStatus.TextColor3=Color3.fromRGB(255, 255, 255)
        pcall(function() StarterGui:SetCore("SendNotification",{Title="Astro.MAIN",Text=names[toolName].." • "..skin,Duration=2}) end)
    else
        skinStatus.Text="● SAVED • EQUIP TOOL"; skinStatus.TextColor3=Color3.fromRGB(255, 255, 255)
        pcall(function() StarterGui:SetCore("SendNotification",{Title="Skin Saved",Text="Equip "..names[toolName].." to use "..skin,Duration=2}) end)
    end
end


_0xn1 = 100
_0xn8 = 1
_0xn9 = 0
_0xn11 = 2
_0xn14 = 0.05
_0xn15 = -0.1
_0xn16 = -0.05

_0x52a0d5 = {
    BulletSpread = {
        Enabled = true,
        Amount = 100
    }
}

_0x9ba38e = nil
_0x9ba38e = hookfunction(math.random, function(...)
    local _0x5e1a0d = {...}

    if checkcaller() then
        return _0x9ba38e(...)
    end

    if (#_0x5e1a0d == _0xn9)
        or (_0x5e1a0d[_0xn8] == _0xn16 and _0x5e1a0d[_0xn11] == _0xn14)
        or (_0x5e1a0d[_0xn8] == _0xn15)
        or (_0x5e1a0d[_0xn8] == _0xn16) then

        if _0x52a0d5.BulletSpread.Enabled then
            return _0x9ba38e(...) * (_0x52a0d5.BulletSpread.Amount / _0xn1)
        end
    end

    return _0x9ba38e(...)
end)

function getClosestPart(char)
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(mouse.X, mouse.Y)

    local parts = {

        "Head",
        "HumanoidRootPart",
        "LeftUpperLeg",
        "LeftLowerLeg",
        "LeftFoot",
        "RightUpperLeg",
        "RightLowerLeg",
        "RightFoot",
        "LeftUpperArm",
        "LeftLowerArm",
        "LeftHand",
        "RightUpperArm",
        "RightLowerArm",
        "RightHand"
    }

    for _, partName in pairs(parts) do
        local p = char:FindFirstChild(partName)
        if p then
            local screenPos, onScreen = cam:WorldToScreenPoint(p.Position)
            if onScreen then
                local dist = (
                    Vector2.new(screenPos.X, screenPos.Y) - mousePos
                ).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = p
                end
            end
        end
    end

    return closest or char:FindFirstChild("Head")
end
function isValidSilentAimTarget(player)
    if not player or player == me or whitelist[player.UserId] then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    -- Da Hood-style knocked state.  Support both common K.O/KO value names.
    local bodyEffects = character:FindFirstChild("BodyEffects")
    if bodyEffects then
        local ko = bodyEffects:FindFirstChild("K.O") or bodyEffects:FindFirstChild("KO")
        if ko and ko:IsA("BoolValue") and ko.Value then
            return false
        end
        if ko and ko:IsA("NumberValue") and ko.Value ~= 0 then
            return false
        end
    end

    return true
end

function getClosest()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local best = nil
    local bestDist = _G.FOV_RADIUS
    for _, v in pairs(plrs:GetPlayers()) do
        if isValidSilentAimTarget(v) then
            local part = nil
            if aimPart == "Closest Part" then
                part = getClosestPart(v.Character)
            elseif aimPart == "Body" then
                part = v.Character:FindFirstChild("HumanoidRootPart")
            elseif aimPart == "Left Leg" then
                part = v.Character:FindFirstChild("LeftUpperLeg")
                    or v.Character:FindFirstChild("LeftLeg")
            elseif aimPart == "Right Leg" then
                part = v.Character:FindFirstChild("RightUpperLeg")
                    or v.Character:FindFirstChild("RightLeg")
            elseif aimPart == "Left Arm" then
                part = v.Character:FindFirstChild("LeftUpperArm")
                    or v.Character:FindFirstChild("LeftArm")
            elseif aimPart == "Right Arm" then
                part = v.Character:FindFirstChild("RightUpperArm")
                    or v.Character:FindFirstChild("RightArm")
            else
                part = v.Character:FindFirstChild("Head")
            end
            if part then
                local screenPos, onScreen =
                    cam:WorldToScreenPoint(part.Position)
                if onScreen then
                    local screenVec =
                        Vector2.new(screenPos.X, screenPos.Y)
                    local dist =
                        (screenVec - mousePos).Magnitude
                    if dist <= _G.FOV_RADIUS then
                        targetPriorityScore = dist
                        if targetPriorityScore < bestDist then
                            if _G.WallCheck then
                                local ray = Ray.new(
                                    cam.CFrame.Position,
                                    (part.Position - cam.CFrame.Position).Unit * 500
                                )
                                local hit, pos =
                                    workspace:FindPartOnRayWithIgnoreList(
                                        ray,
                                        {me.Character, cam}
                                    )
                                if hit and hit:IsDescendantOf(v.Character) then
                                    bestDist = targetPriorityScore
                                    best = part
                                end
                            else
                                bestDist = targetPriorityScore
                                best = part
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end
--// Only install the existing aim hook when this experience actually exposes the expected handler.
--// If a fork has a different structure, the rest of the script can continue loading.
if handler and oldFunc then
    handler.getAim = function(origin, maxDist)
        if _G.RevolverBypass then
            local currentTool =
                me.Character and me.Character:FindFirstChildOfClass("Tool")
            if currentTool
                and (currentTool.Name == "[Revolver]"
                or currentTool.Name == "Revolver") then
                return oldFunc(origin, maxDist)
            end
        end
        local target = getClosest()
        if target then
            local dir = (target.Position - origin).Unit
            local dist = (target.Position - origin).Magnitude
            return dir, math.min(dist, maxDist or 200)
        end
        return oldFunc(origin, maxDist)
    end
end
UIS = game:GetService("UserInputService")
CoreGui = game:GetService("CoreGui")
--// TriggerBot
function triggerBotHoldingBlacklisted()
    local character = me.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local toolName = tool.Name:lower()
    for _, word in ipairs(TriggerBot.Blacklist) do
        if string.find(toolName, tostring(word):lower(), 1, true) then return true end
    end
    return false
end

function triggerBotTargetUnderMouse()
    local character = me.Character
    local unitRay = cam:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = character and {character} or {}
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
    if not result or not result.Instance then return false end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model or model == character then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local targetPlayer = plrs:GetPlayerFromCharacter(model)
    if targetPlayer and _G.Whitelist and _G.Whitelist[targetPlayer.UserId] then return false end
    return true
end

function triggerBotClick()
    if not mouse1click then return end
    local now = tick()
    if now - TriggerBot.LastClick < TriggerBot.ClickDelay then return end
    TriggerBot.LastClick = now
    pcall(mouse1click)
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= TriggerBot.Key then return end
    if TriggerBot.Mode == "Toggle" then
        TriggerBot.Active = not TriggerBot.Active
    else
        TriggerBot.Active = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if TriggerBot.Mode == "Hold" and input.KeyCode == TriggerBot.Key then
        TriggerBot.Active = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not TriggerBot.Enabled or not TriggerBot.Active then return end
    if triggerBotHoldingBlacklisted() then return end
    if triggerBotTargetUnderMouse() then triggerBotClick() end
end)

--// Flamelock target selection
function getFlameTarget()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local closestPart, closestDist = nil, math.huge
    for _, player in ipairs(plrs:GetPlayers()) do
        if player ~= me and player.Character and not (_G.Whitelist and _G.Whitelist[player.UserId]) then
            local character = player.Character
            local part

            if _G.FlameHitPart == "Closest Part" then
                part = getClosestPart(character)
            elseif _G.FlameHitPart == "Body" then
                part = character:FindFirstChild("HumanoidRootPart")
            elseif _G.FlameHitPart == "Left Leg" then
                part = character:FindFirstChild("LeftUpperLeg")
                    or character:FindFirstChild("LeftLeg")
            elseif _G.FlameHitPart == "Right Leg" then
                part = character:FindFirstChild("RightUpperLeg")
                    or character:FindFirstChild("RightLeg")
            elseif _G.FlameHitPart == "Left Arm" then
                part = character:FindFirstChild("LeftUpperArm")
                    or character:FindFirstChild("LeftArm")
            elseif _G.FlameHitPart == "Right Arm" then
                part = character:FindFirstChild("RightUpperArm")
                    or character:FindFirstChild("RightArm")
            else
                part = character:FindFirstChild("Head")
            end

            if part then
                local screenPos, onScreen = cam:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPart = part
                    end
                end
            end
        end
    end
    return closestPart
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not _G.FlamelockEnabled then return end
    local triggered = (_G.FlameRightClick and input.UserInputType == Enum.UserInputType.MouseButton2)
        or (not _G.FlameRightClick and input.KeyCode == _G.FlameKey)
    if not triggered then return end
    if _G.FlameMode == "Hold" then
        _G.FlameActive = true
    else
        _G.FlameActive = not _G.FlameActive
    end
    if _G.FlameActive then
        flameTargetPart = getFlameTarget()
        if not flameTargetPart then _G.FlameActive = false end
    else
        flameTargetPart = nil
    end
end)

UIS.InputEnded:Connect(function(input)
    if _G.FlamelockEnabled and _G.FlameMode == "Hold" then
        local triggered = (_G.FlameRightClick and input.UserInputType == Enum.UserInputType.MouseButton2)
            or (not _G.FlameRightClick and input.KeyCode == _G.FlameKey)
        if triggered then
            _G.FlameActive = false
            flameTargetPart = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not _G.FlamelockEnabled or not _G.FlameActive then return end
    if not flameTargetPart or not flameTargetPart.Parent then
        flameTargetPart = getFlameTarget()
        if not flameTargetPart then _G.FlameActive = false return end
    end
    local character = flameTargetPart.Parent
    local targetPlayer = plrs:GetPlayerFromCharacter(character)
    if targetPlayer and _G.Whitelist and _G.Whitelist[targetPlayer.UserId] then
        _G.FlameActive = false
        flameTargetPart = nil
        return
    end
    local velocity = flameTargetPart.AssemblyLinearVelocity or flameTargetPart.Velocity
    local predicted = flameTargetPart.Position + (velocity * _G.FlamePrediction)
    local offset = cam.CFrame.RightVector * _G.FlameLeftOffset + Vector3.new(0, _G.FlameUpOffset, 0)
    local screenPos, onScreen = cam:WorldToViewportPoint(predicted + offset)
    if onScreen and type(mousemoverel) == "function" then
        local smooth = math.clamp(_G.FlameSmoothness, 0, 1)
        pcall(function()
            mousemoverel((screenPos.X - mouse.X) * smooth, (screenPos.Y - mouse.Y) * smooth)
        end)
    end
end)

--// Main GUI
gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Name = "Astro.MAIN"
gui.Parent = CoreGui
frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 660, 0, 440)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(248, 250, 244)
frame.BorderSizePixel = 0
frame.ClipsDescendants = false
frame.BackgroundColor3 = Color3.fromRGB(248, 250, 244)
frame.Parent = gui

frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 9)
frameCorner.Parent = frame

frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(166, 184, 124)
frameStroke.Transparency = 0.18
frameStroke.Thickness = 1.5
frameStroke.Parent = frame

frame.Visible = false


--// Astro.MAIN loading screen
loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "Astro.MAIN_Loading"
loadingGui.IgnoreGuiInset = true
loadingGui.ResetOnSpawn = false
loadingGui.DisplayOrder = 999999
loadingGui.Parent = CoreGui

loadingCard = Instance.new("Frame")
loadingCard.Size = UDim2.new(0, 220, 0, 105)
loadingCard.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingCard.AnchorPoint = Vector2.new(0.5, 0.5)
loadingCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loadingCard.BorderSizePixel = 0
loadingCard.Parent = loadingGui
Instance.new("UICorner", loadingCard).CornerRadius = UDim.new(0, 6)

loadingStroke = Instance.new("UIStroke")
loadingStroke.Color = Color3.fromRGB(166, 184, 124)
loadingStroke.Transparency = 0.05
loadingStroke.Thickness = 1
loadingStroke.Parent = loadingCard

loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, -20, 0, 28)
loadingTitle.Position = UDim2.new(0, 10, 0.5, -20)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "Astro.MAIN"
loadingTitle.TextColor3 = Color3.fromRGB(72, 85, 55)
loadingTitle.TextSize = 18
loadingTitle.Font = Enum.Font.GothamSemibold
loadingTitle.TextXAlignment = Enum.TextXAlignment.Center
loadingTitle.Parent = loadingCard

loadingTrack = Instance.new("Frame")
loadingTrack.Size = UDim2.new(1, -40, 0, 4)
loadingTrack.Position = UDim2.new(0, 20, 1, -22)
loadingTrack.BackgroundColor3 = Color3.fromRGB(225, 231, 216)
loadingTrack.BorderSizePixel = 0
loadingTrack.Parent = loadingCard
Instance.new("UICorner", loadingTrack).CornerRadius = UDim.new(0, 6)

loadingFill = Instance.new("Frame")
loadingFill.Size = UDim2.new(0, 0, 1, 0)
loadingFill.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
loadingFill.BorderSizePixel = 0
loadingFill.Parent = loadingTrack
Instance.new("UICorner", loadingFill).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    for i = 1, 100 do
        loadingFill.Size = UDim2.new(i / 100, 0, 1, 0)
        task.wait(0.022)
    end

    task.wait(0.12)
    loadingGui:Destroy()
    uiVisible = true
    frame.Visible = true
    _G.AstroMainLoaded = true

    -- Smooth opening animation for the main interface.
    frameScale.Scale = 0.74
    frame.Position = UDim2.new(0.5, 0, 0.5, 18)
    local openTween = TweenService:Create(
        frame,
        TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    local scaleTween = TweenService:Create(
        frameScale,
        TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Scale = userUIScale}
    )
    openTween:Play()
    scaleTween:Play()
end)

--// Responsive sizing: keeps the UI fitted on smaller screens
frameScale = Instance.new("UIScale")
frameScale.Parent = frame
userUIScale = 0.92

function updateFrameScale()
    -- The bottom-right handle controls the UI size directly.
    -- Do not force the user back down to a viewport-fit size.
    frameScale.Scale = userUIScale
end

updateFrameScale()

-- RightShift is locked while the loader is running.
-- The main UI can only be toggled after the loader has completely finished.
rightShiftToggleBound = true
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == (uiToggleKey or Enum.KeyCode.RightShift) then
        if _G.AstroMainLoaded ~= true then
            return
        end
        uiVisible = not uiVisible
        frame.Visible = uiVisible
        if not uiVisible and dropScroll then
            dropScroll.Visible = false
        end
    end
end)

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFrameScale)
end
--// Dragging
resizing = false
dragging, dragInput, dragStart, startPos = false, nil, nil, nil
frame.InputBegan:Connect(function(input)
    if resizing then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--// Bottom-right resize handle
local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.fromOffset(30, 30)
resizeHandle.Position = UDim2.new(1, -2, 1, -2)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.BackgroundTransparency = 1
resizeHandle.BorderSizePixel = 0
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 200
resizeHandle.Parent = frame

local resizeGrip = Instance.new("Frame")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.fromOffset(22, 22)
resizeGrip.Position = UDim2.new(1, -3, 1, -3)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.BackgroundTransparency = 1
resizeGrip.BorderSizePixel = 0
resizeGrip.ZIndex = 201
resizeGrip.Parent = frame

for i = 1, 3 do
    local line = Instance.new("Frame")
    line.Size = UDim2.fromOffset(2, 7 + i * 2)
    line.Position = UDim2.new(1, -(i * 5), 1, -2)
    line.AnchorPoint = Vector2.new(0.5, 1)
    line.Rotation = 45
    line.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
    line.BackgroundTransparency = 0.15
    line.BorderSizePixel = 0
    line.ZIndex = 202
    line.Parent = resizeGrip
end

local resizing = false
local resizeStart = nil
local resizeStartScale = userUIScale or 1

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        resizeStartScale = userUIScale or 1
    end
end)

UIS.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - resizeStart
    userUIScale = math.clamp(resizeStartScale + ((delta.X + delta.Y) / 2) / 420, 0.45, 2.25)
    if updateFrameScale then updateFrameScale() end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

--// Compact top bar
topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 34)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(190, 204, 160)
topBar.BorderSizePixel = 0
topBar.Parent = frame

--// Rounded top bar
topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 9)
topBarCorner.Parent = topBar
sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(0, 260, 0, 26)
sideTitle.Position = UDim2.new(0, 18, 0, 6)
sideTitle.Text = "Astro.MAIN"
sideTitle.TextColor3 = Color3.fromRGB(42, 48, 34)
sideTitle.TextSize = 16
sideTitle.Font = Enum.Font.GothamSemibold
sideTitle.BackgroundTransparency = 1
sideTitle.TextXAlignment = Enum.TextXAlignment.Left
sideTitle.Parent = topBar



--// Live date / time display
welcomeLabel = Instance.new("TextLabel")
welcomeLabel.Name = "DateTimeLabel"
welcomeLabel.Size = UDim2.new(0, 270, 0, 24)
welcomeLabel.Position = UDim2.new(1, -285, 0, 7)
welcomeLabel.TextColor3 = Color3.fromRGB(58, 68, 46)
welcomeLabel.TextSize = 10
welcomeLabel.Font = Enum.Font.Gotham
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.TextXAlignment = Enum.TextXAlignment.Right
welcomeLabel.TextWrapped = false
welcomeLabel.TextTruncate = Enum.TextTruncate.None
welcomeLabel.Parent = topBar

local function updateDateTimeLabel()
    -- Uses the local time of the device running the Roblox client.
    welcomeLabel.Text = os.date("%m/%d/%Y  %I:%M:%S %p")
end

updateDateTimeLabel()
task.spawn(function()
    while welcomeLabel and welcomeLabel.Parent do
        task.wait(1)
        updateDateTimeLabel()
    end
end)

--// Matcha accent line
cuteAccent = Instance.new("Frame")
cuteAccent.Size = UDim2.new(1, 0, 0, 2)
cuteAccent.Position = UDim2.new(0, 0, 1, 0)
cuteAccent.BackgroundColor3 = Color3.fromRGB(154, 171, 116)
cuteAccent.BorderSizePixel = 0
cuteAccent.Parent = topBar
Instance.new("UICorner", cuteAccent).CornerRadius = UDim.new(0, 2)

--// Sidebar + content layout
tabContainer = Instance.new("Frame")
tabContainer.Name = "ContentArea"
tabContainer.Size = UDim2.new(1, -128, 0, 406)
tabContainer.Position = UDim2.new(0, 128, 0, 34)
tabContainer.BackgroundTransparency = 1
tabContainer.BorderSizePixel = 0
tabContainer.ClipsDescendants = true
tabContainer.Parent = frame

tabContainerCorner = Instance.new("UICorner")
tabContainerCorner.CornerRadius = UDim.new(0, 6)
tabContainerCorner.Parent = tabContainer

ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Name = "Sidebar"
ScrollingFrame.Size = UDim2.new(0, 128, 0, 406)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 34)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(248, 250, 244)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.ScrollBarThickness = 3
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(166, 184, 124)
ScrollingFrame.ScrollBarImageTransparency = 0.1
ScrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
ScrollingFrame.ClipsDescendants = true
ScrollingFrame.Parent = frame

sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 6)
sidebarCorner.Parent = ScrollingFrame

sidebarStroke = Instance.new("UIStroke")
sidebarStroke.Color = Color3.fromRGB(166, 184, 124)
sidebarStroke.Transparency = 0.55
sidebarStroke.Thickness = 1
sidebarStroke.Parent = ScrollingFrame

tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Vertical
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
tabLayout.Padding = UDim.new(0, 2)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = ScrollingFrame

tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 7)
tabPadding.PaddingRight = UDim.new(0, 7)
tabPadding.PaddingTop = UDim.new(0, 5)
tabPadding.PaddingBottom = UDim.new(0, 0)
tabPadding.Parent = ScrollingFrame

-- Keep every sidebar entry reachable, including Visual and Force Reset.
tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 4)
end)

 tabs = {
    Home = Instance.new("ScrollingFrame"),
    SilentAim = Instance.new("ScrollingFrame"),
    Hitbox = Instance.new("ScrollingFrame"),
    Flamelock = Instance.new("ScrollingFrame"),
    TriggerBot = Instance.new("ScrollingFrame"),
    CamLock = Instance.new("ScrollingFrame"),
    ESP = Instance.new("ScrollingFrame"),
    Misc = Instance.new("ScrollingFrame"),
    Teleport = Instance.new("ScrollingFrame"),
    Visual = Instance.new("ScrollingFrame"),
    ForceReset = Instance.new("ScrollingFrame"),
    Avatar = Instance.new("ScrollingFrame"),
    Whitelist = Instance.new("ScrollingFrame"),
    SkinChanger = Instance.new("ScrollingFrame"),
    HC = Instance.new("ScrollingFrame"),
}
topBar.Size = UDim2.new(1, 0, 0, 34)
for name, page in pairs(tabs) do
    page.Size = UDim2.new(1, -2, 1, -2)
    page.BackgroundColor3 = Color3.fromRGB(250, 252, 246)
    page.BorderSizePixel = 0
    page.Visible = (name == "Home")
    page.Parent = tabContainer
    page.ZIndex = 1

    --// Cute vertical scrolling for pages that have more content than fits
    -- Every page is an independently scrollable vertical surface.
    -- Keep a real canvas height even when a page has only a few controls,
    -- so the mouse wheel/drag scrollbar is available consistently.
    page.CanvasSize = UDim2.new(0, 0, 0, 560)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(166, 184, 124)
    page.ScrollBarImageTransparency = 0.15
    page.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    page.ElasticBehavior = Enum.ElasticBehavior.Always
    page.ClipsDescendants = true
    page.ScrollingEnabled = true
    page.Active = true
    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingBottom = UDim.new(0, 3)
    pagePadding.PaddingTop = UDim.new(0, 0)
    pagePadding.Parent = page

    Instance.new("UICorner", page).CornerRadius = UDim.new(0, 6)
    local ps = Instance.new("UIStroke")
    ps.Color = Color3.fromRGB(166, 184, 124)
    ps.Transparency = 0.35
    ps.Thickness = 1.2
    ps.Parent = page
end
tabButtons = {}
tabNames = {
    "Home",
    "Silent Aim",
    "Hitbox",
    "Flamelock",
    "TriggerBot",
    "Cam Lock",
    "ESP",
    "Misc",
    "Teleport",
    "Visual",
    "Force Reset",
    "Avatar",
    "Whitelist",
    "Skin Changer",
    "HC",
}
tabKeys = {
    "Home",
    "SilentAim",
    "Hitbox",
    "Flamelock",
    "TriggerBot",
    "CamLock",
    "ESP",
    "Misc",
    "Teleport",
    "Visual",
    "ForceReset",
    "Avatar",
    "Whitelist",
    "SkinChanger",
    "HC",
}

-- Active UI theme colors are kept outside the theme section so tab switching
-- does not reset the selected page colors back to the original pink.
activeThemeAccent = Color3.fromRGB(158, 177, 112)
activeThemeSoft = Color3.fromRGB(226, 236, 207)
activeThemeButton = Color3.fromRGB(255, 255, 255)
activeThemeText = Color3.fromRGB(245, 243, 250)

--// Page polish helpers — all Astro.MAIN pages keep the same shared layout system.
function styleUpgradeCard(card)
    if not card or not card:IsA("GuiObject") then return end
    local corner = card:FindFirstChildOfClass("UICorner")
    if corner then corner.CornerRadius = UDim.new(0, 6) end
    local stroke = card:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = Color3.fromRGB(75, 68, 92)
        stroke.Transparency = 0.35
        stroke.Thickness = 1
    end
end

function styleUpgradeButton(button)
    if not button or not button:IsA("GuiButton") then return end
    local corner = button:FindFirstChildOfClass("UICorner")
    if corner then corner.CornerRadius = UDim.new(0, 6) end
    button.AutoButtonColor = false
end


TweenService = game:GetService("TweenService")
activeTabKey = "Home"

function switchTab(targetKey)
    if not tabs[targetKey] then
        return
    end

    local oldPage = tabs[activeTabKey]
    local newPage = tabs[targetKey]

    if oldPage and oldPage ~= newPage then
        oldPage.Visible = false
        oldPage.Position = UDim2.new(0, 0, 0, 0)
        oldPage.ZIndex = 1
    end

    newPage.Visible = true
    newPage.Position = UDim2.new(0, 0, 0, 0)
    newPage.ZIndex = 1

    for key, btn in pairs(tabButtons) do
        if key == targetKey then
            btn.BackgroundColor3 = activeThemeAccent
            btn.TextColor3 = Color3.fromRGB(45, 52, 35)
        else
            btn.BackgroundColor3 = activeThemeSoft
            btn.TextColor3 = Color3.fromRGB(45, 52, 35)
        end
    end

    activeTabKey = targetKey
    _G.ayeshaLastTab = targetKey
end

for idx, labelText in ipairs(tabNames) do
    local key = tabKeys[idx]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -2, 0, 25)
    btn.Text = labelText
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
    btn.TextColor3 = Color3.fromRGB(45, 52, 35)
    btn.AutoButtonColor = false
    btn.LayoutOrder = idx
    btn.Parent = ScrollingFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabButtons[key] = btn
    btn.MouseEnter:Connect(function()
        if tabs[key].Visible then
            return
        end
        btn.BackgroundColor3 = Color3.fromRGB(211, 224, 181)
    end)
    btn.MouseLeave:Connect(function()
        if tabs[key].Visible then
            return
        end
        btn.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
    end)
    btn.MouseButton1Click:Connect(function()
        switchTab(key)
    end)
end
switchTab(activeTabKey)
--// Page headers
function createPageHeader(pageFrame, titleText)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(58, 68, 46)
    title.TextSize = 14
    title.Font = Enum.Font.GothamSemibold
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = pageFrame
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -30, 0, 1)
    line.Position = UDim2.new(0, 15, 0, 25)
    line.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
    line.BorderSizePixel = 0
    line.Parent = pageFrame
end
--// Home page
--// Clear, visible dashboard: profile picture + welcome + live information.
local homeHeader = Instance.new("TextLabel")
homeHeader.Name = "HomeHeader"
homeHeader.Size = UDim2.new(1, -28, 0, 24)
homeHeader.Position = UDim2.fromOffset(14, 10)
homeHeader.BackgroundTransparency = 1
homeHeader.Text = "HOME"
homeHeader.TextColor3 = Color3.fromRGB(58, 68, 46)
homeHeader.TextSize = 15
homeHeader.Font = Enum.Font.GothamSemibold
homeHeader.TextXAlignment = Enum.TextXAlignment.Left
homeHeader.Parent = tabs.Home

local homeHeaderLine = Instance.new("Frame")
homeHeaderLine.Size = UDim2.new(1, -28, 0, 1)
homeHeaderLine.Position = UDim2.fromOffset(14, 35)
homeHeaderLine.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
homeHeaderLine.BorderSizePixel = 0
homeHeaderLine.Parent = tabs.Home

local homeHero = Instance.new("Frame")
homeHero.Name = "HomeProfile"
homeHero.Size = UDim2.new(1, -28, 0, 132)
homeHero.Position = UDim2.fromOffset(14, 47)
homeHero.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
homeHero.BorderSizePixel = 0
homeHero.Parent = tabs.Home
Instance.new("UICorner", homeHero).CornerRadius = UDim.new(0, 10)
local heroStroke = Instance.new("UIStroke")
heroStroke.Color = Color3.fromRGB(166, 184, 124)
heroStroke.Thickness = 1.2
heroStroke.Parent = homeHero

local homeAvatar = Instance.new("ImageLabel")
homeAvatar.Name = "ProfileAvatar"
homeAvatar.Size = UDim2.fromOffset(104, 104)
homeAvatar.Position = UDim2.fromOffset(16, 14)
homeAvatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
homeAvatar.BorderSizePixel = 0
homeAvatar.Parent = homeHero
Instance.new("UICorner", homeAvatar).CornerRadius = UDim.new(0, 10)
local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(166, 184, 124)
avatarStroke.Thickness = 1
avatarStroke.Parent = homeAvatar
pcall(function()
    homeAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(me.UserId) .. "&w=420&h=420"
end)

local homeWelcome = Instance.new("TextLabel")
homeWelcome.Size = UDim2.new(1, -136, 0, 32)
homeWelcome.Position = UDim2.fromOffset(134, 16)
homeWelcome.BackgroundTransparency = 1
homeWelcome.Text = "Welcome back, " .. tostring(me.DisplayName or me.Name)
homeWelcome.TextColor3 = Color3.fromRGB(45, 52, 35)
homeWelcome.TextSize = 18
homeWelcome.Font = Enum.Font.GothamSemibold
homeWelcome.TextXAlignment = Enum.TextXAlignment.Left
homeWelcome.TextTruncate = Enum.TextTruncate.AtEnd
homeWelcome.Parent = homeHero

local homeUsername = Instance.new("TextLabel")
homeUsername.Size = UDim2.new(1, -136, 0, 22)
homeUsername.Position = UDim2.fromOffset(134, 49)
homeUsername.BackgroundTransparency = 1
homeUsername.Text = "@" .. tostring(me.Name)
homeUsername.TextColor3 = Color3.fromRGB(92, 103, 76)
homeUsername.TextSize = 12
homeUsername.Font = Enum.Font.Gotham
homeUsername.TextXAlignment = Enum.TextXAlignment.Left
homeUsername.Parent = homeHero
homeUsername.Visible = false



-- Home dashboard FPS card
local homeFPSCard = Instance.new("Frame")
homeFPSCard.Name = "FPSCard"
homeFPSCard.Size = UDim2.new(1, -28, 0, 62)
homeFPSCard.Position = UDim2.fromOffset(14, 190)
homeFPSCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
homeFPSCard.BorderSizePixel = 0
homeFPSCard.Parent = tabs.Home
local homeFPSCorner = Instance.new("UICorner")
homeFPSCorner.CornerRadius = UDim.new(0, 6)
homeFPSCorner.Parent = homeFPSCard
local homeFPSStroke = Instance.new("UIStroke")
homeFPSStroke.Color = Color3.fromRGB(166, 184, 124)
homeFPSStroke.Transparency = 0.2
homeFPSStroke.Thickness = 1
homeFPSStroke.Parent = homeFPSCard

local homeFPSTitle = Instance.new("TextLabel")
homeFPSTitle.Name = "FPSTitle"
homeFPSTitle.Size = UDim2.new(0.5, -18, 1, 0)
homeFPSTitle.Position = UDim2.fromOffset(12, 0)
homeFPSTitle.BackgroundTransparency = 1
homeFPSTitle.Text = "FPS"
homeFPSTitle.TextColor3 = Color3.fromRGB(58, 68, 46)
homeFPSTitle.TextSize = 13
homeFPSTitle.Font = Enum.Font.GothamSemibold
homeFPSTitle.TextXAlignment = Enum.TextXAlignment.Left
homeFPSTitle.Parent = homeFPSCard

local homeFPSValue = Instance.new("TextLabel")
homeFPSValue.Name = "FPSValue"
homeFPSValue.Size = UDim2.new(0.5, -12, 1, 0)
homeFPSValue.Position = UDim2.new(0.5, 0, 0, 0)
homeFPSValue.BackgroundTransparency = 1
homeFPSValue.Text = "--"
homeFPSValue.TextColor3 = Color3.fromRGB(45, 52, 35)
homeFPSValue.TextSize = 15
homeFPSValue.Font = Enum.Font.GothamSemibold
homeFPSValue.TextXAlignment = Enum.TextXAlignment.Right
homeFPSValue.Parent = homeFPSCard

local homeStatusValue = Instance.new("TextLabel")
homeStatusValue.Visible = false
homeStatusValue.Parent = tabs.Home
local homeProfileName = Instance.new("TextLabel")
homeProfileName.Visible = false
homeProfileName.Parent = tabs.Home
local homeNickname = Instance.new("TextLabel")
homeNickname.Visible = false
homeNickname.Parent = tabs.Home
local homeUsernameValue = Instance.new("TextLabel")
homeUsernameValue.Visible = false
homeUsernameValue.Parent = tabs.Home
local homeUserId = Instance.new("TextLabel")
homeUserId.Visible = false
homeUserId.Parent = tabs.Home

tabs.Home.CanvasSize = UDim2.new(0, 0, 0, 270)

local fpsFrames, fpsLast = 0, os.clock()
RunService.RenderStepped:Connect(function()
    fpsFrames += 1
    local now = os.clock()
    if now - fpsLast >= 1 then
        homeFPSValue.Text = tostring(math.floor(fpsFrames / (now - fpsLast)))
        fpsFrames, fpsLast = 0, now
    end
end)

createPageHeader(tabs.SilentAim, "Silent Aim Settings")
createPageHeader(tabs.Hitbox, "Hitbox Expander")
createPageHeader(tabs.TriggerBot, "TriggerBot")
createPageHeader(tabs.CamLock, "Camlock Settings")
createPageHeader(tabs.ESP, "ESP Settings")
createPageHeader(tabs.Misc, "Misc Settings")
createPageHeader(tabs.Teleport, "Teleport System")
createPageHeader(tabs.Visual, "Visual Settings")
createPageHeader(tabs.ForceReset, "Force Reset Settings")
createPageHeader(tabs.Avatar, "Avatar Settings")
createPageHeader(tabs.Whitelist, "Player Whitelist")
createPageHeader(tabs.SkinChanger, "Skin Changer")
createPageHeader(tabs.HC, "HC Tools")

--// Soft dark cards for the picture-style layout
function addCard(page, y, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -30, 0, height)
    card.Position = UDim2.new(0, 15, 0, y)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    card.ZIndex = 0
    card.Parent = page
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = card
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(65, 60, 78)
    st.Transparency = 0.18
    st.Thickness = 1
    st.Parent = card
    return card
end

addCard(tabs.SilentAim, 31, 172)
addCard(tabs.Hitbox, 31, 285)
addCard(tabs.Flamelock, 31, 680)
addCard(tabs.TriggerBot, 31, 220)
addCard(tabs.SilentAim, 223, 180)
addCard(tabs.SilentAim, 413, 105)
addCard(tabs.CamLock, 31, 165)
addCard(tabs.ESP, 31, 330)
addCard(tabs.Misc, 31, 135)
addCard(tabs.Teleport, 31, 135)
addCard(tabs.Visual, 31, 730)
addCard(tabs.ForceReset, 31, 135)
addCard(tabs.Avatar, 31, 365)
addCard(tabs.Whitelist, 31, 300)
addCard(tabs.HC, 31, 180)

--// Skin Changer page — reference-style compact weapon / skin browser
--// Keeps the existing Astro.MAIN skin backend, but changes only this page's layout.
do
    local skinPage = tabs.SkinChanger

    -- Astro.MAIN palette: keep the reference layout, but use the same
    -- white / soft-matcha colors as the rest of Astro.MAIN.
    local REF_BG = Color3.fromRGB(255, 255, 255)
    local REF_PANEL = Color3.fromRGB(244, 247, 238)
    local REF_INPUT = Color3.fromRGB(250, 252, 246)
    local REF_SELECTED = Color3.fromRGB(181, 196, 150)
    local REF_LINE = Color3.fromRGB(166, 184, 124)
    local REF_TEXT = Color3.fromRGB(35, 38, 32)
    local REF_TEXT_DARK = Color3.fromRGB(35, 38, 32)
    local REF_MUTED = Color3.fromRGB(92, 103, 76)

    skinPage.BackgroundColor3 = REF_BG
    skinPage.BackgroundTransparency = 0
    skinPage.BorderSizePixel = 0
    skinPage.ScrollBarThickness = 3
    skinPage.ScrollBarImageColor3 = REF_LINE
    skinPage.ScrollBarImageTransparency = 0.15

    -- The normal Ayesha page header becomes the small reference-style title.
    local headerTitle
    local headerLine
    for _, child in ipairs(skinPage:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == "Skin Changer" then
            headerTitle = child
        elseif child:IsA("Frame") and child.Size == UDim2.new(1, -30, 0, 1) then
            headerLine = child
        end
    end

    if headerTitle then
        headerTitle.Text = "[Revolver]"
        headerTitle.Position = UDim2.fromOffset(10, 0)
        headerTitle.Size = UDim2.new(1, -20, 0, 25)
        headerTitle.TextColor3 = REF_TEXT
        headerTitle.TextSize = 15
        headerTitle.Font = Enum.Font.Gotham
    end
    if headerLine then
        headerLine.Position = UDim2.fromOffset(10, 28)
        headerLine.Size = UDim2.new(1, -20, 0, 1)
        headerLine.BackgroundColor3 = REF_LINE
    end

    local weaponRail = Instance.new("Frame")
    weaponRail.Name = "ReferenceWeaponRail"
    -- Weapon categories now sit across the TOP instead of in a left rail.
    weaponRail.Size = UDim2.new(1, 0, 0, 50)
    weaponRail.Position = UDim2.fromOffset(0, 30)
    weaponRail.BackgroundColor3 = REF_PANEL
    weaponRail.BorderSizePixel = 0
    weaponRail.Parent = skinPage

    local railLine = Instance.new("Frame")
    railLine.Size = UDim2.new(1, 0, 0, 1)
    railLine.Position = UDim2.new(0, 0, 1, -1)
    railLine.BackgroundColor3 = REF_LINE
    railLine.BorderSizePixel = 0
    railLine.Parent = weaponRail

    local weaponList = Instance.new("ScrollingFrame")
    weaponList.Name = "WeaponCategories"
    weaponList.Size = UDim2.new(1, -8, 1, -12)
    weaponList.Position = UDim2.fromOffset(4, 3)
    weaponList.BackgroundTransparency = 1
    weaponList.BorderSizePixel = 0
    weaponList.ScrollBarThickness = 5
    weaponList.ScrollBarImageColor3 = REF_LINE
    weaponList.ScrollBarImageTransparency = 0.05
    weaponList.AutomaticCanvasSize = Enum.AutomaticSize.None
    weaponList.CanvasSize = UDim2.new(0, 0, 0, 0)
    -- The Skin Changer weapon rail is independently scrollable left/right.
    weaponList.ScrollingDirection = Enum.ScrollingDirection.X
    weaponList.ScrollingEnabled = true
    weaponList.Active = true
    weaponList.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    weaponList.ElasticBehavior = Enum.ElasticBehavior.Never
    weaponList.ScrollingDirection = Enum.ScrollingDirection.X
    weaponList.CanvasPosition = Vector2.new(0, 0)
    weaponList.ClipsDescendants = true
    weaponList.Parent = weaponRail

    local weaponLayout = Instance.new("UIListLayout")
    weaponLayout.Padding = UDim.new(0, 3)
    weaponLayout.FillDirection = Enum.FillDirection.Horizontal
    weaponLayout.SortOrder = Enum.SortOrder.LayoutOrder
    weaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    weaponLayout.Parent = weaponList

    -- Force the TOP weapon selector to recalculate its horizontal canvas
    -- whenever buttons are added/removed.
    weaponLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        weaponList.CanvasSize = UDim2.new(0, weaponLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    local content = Instance.new("Frame")
    content.Name = "ReferenceSkinContent"
    content.Size = UDim2.new(1, 0, 0, 330)
    content.Position = UDim2.fromOffset(0, 82)
    content.BackgroundColor3 = REF_BG
    content.BorderSizePixel = 0
    content.Parent = skinPage

    local contentLine = Instance.new("Frame")
    contentLine.Size = UDim2.new(1, -20, 0, 1)
    contentLine.Position = UDim2.fromOffset(10, 28)
    contentLine.BackgroundColor3 = REF_LINE
    contentLine.BorderSizePixel = 0
    contentLine.Parent = content

    local currentWeaponTitle = Instance.new("TextLabel")
    currentWeaponTitle.Name = "CurrentWeapon"
    currentWeaponTitle.BackgroundTransparency = 1
    currentWeaponTitle.Position = UDim2.fromOffset(10, 0)
    currentWeaponTitle.Size = UDim2.new(1, -20, 0, 25)
    currentWeaponTitle.Text = "[Revolver]"
    currentWeaponTitle.TextColor3 = REF_TEXT
    currentWeaponTitle.TextSize = 15
    currentWeaponTitle.Font = Enum.Font.Gotham
    currentWeaponTitle.TextXAlignment = Enum.TextXAlignment.Left
    currentWeaponTitle.Parent = content

    -- Skin selector: compact "Skin ▼" control with a scrollable dropdown.
    local skinSearch = Instance.new("TextBox")
    skinSearch.Name = "SkinSearch"
    skinSearch.Size = UDim2.new(1, -86, 0, 30)
    skinSearch.Position = UDim2.fromOffset(43, 50)
    skinSearch.BackgroundColor3 = REF_INPUT
    skinSearch.BorderSizePixel = 0
    skinSearch.PlaceholderText = "Search skin..."
    skinSearch.PlaceholderColor3 = REF_MUTED
    skinSearch.Text = ""
    skinSearch.TextColor3 = REF_TEXT
    skinSearch.TextSize = 12
    skinSearch.Font = Enum.Font.Gotham
    skinSearch.TextXAlignment = Enum.TextXAlignment.Left
    skinSearch.ClearTextOnFocus = false
    skinSearch.Parent = content

    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 10)
    searchPadding.PaddingRight = UDim.new(0, 10)
    searchPadding.Parent = skinSearch

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = REF_LINE
    searchStroke.Thickness = 1
    searchStroke.Parent = skinSearch

    local skinSelector = Instance.new("TextButton")
    skinSelector.Name = "SkinSelector"
    skinSelector.Size = UDim2.new(1, -86, 0, 34)
    skinSelector.Position = UDim2.fromOffset(43, 84)
    skinSelector.BackgroundColor3 = REF_INPUT
    skinSelector.BorderSizePixel = 0
    skinSelector.Text = "Skin ▼"
    skinSelector.TextColor3 = REF_TEXT
    skinSelector.TextSize = 12
    skinSelector.Font = Enum.Font.Gotham
    skinSelector.TextXAlignment = Enum.TextXAlignment.Left
    skinSelector.AutoButtonColor = false
    skinSelector.Parent = content

    local selectorPadding = Instance.new("UIPadding")
    selectorPadding.PaddingLeft = UDim.new(0, 10)
    selectorPadding.PaddingRight = UDim.new(0, 10)
    selectorPadding.Parent = skinSelector

    local selectorStroke = Instance.new("UIStroke")
    selectorStroke.Color = REF_LINE
    selectorStroke.Thickness = 1
    selectorStroke.Parent = skinSelector

    local skinDropdown = Instance.new("ScrollingFrame")
    skinDropdown.Name = "SkinDropdown"
    skinDropdown.Size = UDim2.new(1, -86, 0, 176)
    skinDropdown.Position = UDim2.fromOffset(43, 122)
    skinDropdown.BackgroundColor3 = REF_PANEL
    skinDropdown.BorderSizePixel = 0
    skinDropdown.ScrollBarThickness = 3
    skinDropdown.ScrollBarImageColor3 = REF_LINE
    skinDropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
    skinDropdown.CanvasSize = UDim2.new()
    skinDropdown.Visible = false
    skinDropdown.ZIndex = 20
    skinDropdown.Parent = content

    local skinDropdownStroke = Instance.new("UIStroke")
    skinDropdownStroke.Color = REF_LINE
    skinDropdownStroke.Thickness = 1
    skinDropdownStroke.Parent = skinDropdown

    local skinLayout = Instance.new("UIListLayout")
    skinLayout.Padding = UDim.new(0, 3)
    skinLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    skinLayout.SortOrder = Enum.SortOrder.LayoutOrder
    skinLayout.Parent = skinDropdown

    local bottomLine = Instance.new("Frame")
    bottomLine.Size = UDim2.new(1, -20, 0, 1)
    bottomLine.Position = UDim2.new(0, 10, 1, -20)
    bottomLine.BackgroundColor3 = REF_LINE
    bottomLine.BorderSizePixel = 0
    bottomLine.Parent = content

    local selectedWeapon = "[Revolver]"
    local selectedSkin = ""
    local weaponButtons = {}
    local skinButtons = {}
    local skinDropdownOpen = false

    local weaponOrder = {
        "[Double-Barrel SG]",
        "[Revolver]",
        "[TacticalShotgun]",
        "[Shotgun]",
        
        
        "[Knife]",
    }

    local function clearButtons(list)
        for _, obj in ipairs(list) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        table.clear(list)
    end

    local function applyReferenceSkin(name)
        selectedSkin = name or ""
        cfg.skins.weapons[selectedWeapon] = selectedSkin
        applySkin(selectedWeapon, selectedSkin)
    end

    local function rebuildReferenceSkins()
        clearButtons(skinButtons)

        local list = getNames(selectedWeapon)
        local query = string.lower(skinSearch.Text or "")
        skinSelector.Text = (selectedSkin ~= "" and ("Skin: " .. selectedSkin .. " ▼") or "Skin ▼")

        local shown = 0
        for _, skinName in ipairs(list) do
            if query == "" or string.find(string.lower(tostring(skinName)), query, 1, true) then
                shown += 1
                local b = Instance.new("TextButton")
                b.Name = "Skin_" .. tostring(shown)
                b.Size = UDim2.new(1, -8, 0, 27)
                b.BackgroundColor3 = (skinName == selectedSkin) and REF_SELECTED or REF_INPUT
                b.BorderSizePixel = 0
                b.Text = skinName
                b.TextColor3 = REF_TEXT
                b.TextSize = 11
                b.Font = Enum.Font.Gotham
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.AutoButtonColor = false
                b.LayoutOrder = shown
                b.ZIndex = 21
                b.Parent = skinDropdown
                table.insert(skinButtons, b)

                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 9)
                pad.Parent = b

                b.MouseEnter:Connect(function()
                    if skinName ~= selectedSkin then
                        b.BackgroundColor3 = Color3.fromRGB(232, 237, 220)
                    end
                end)
                b.MouseLeave:Connect(function()
                    b.BackgroundColor3 = (skinName == selectedSkin) and REF_SELECTED or REF_INPUT
                end)
                b.MouseButton1Click:Connect(function()
                    applyReferenceSkin(skinName)
                    skinDropdownOpen = false
                    skinDropdown.Visible = false
                    skinSelector.Text = "Skin: " .. skinName .. " ▼"
                    rebuildReferenceSkins()
                end)
            end
        end

        if shown == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.new(1, -8, 0, 27)
            none.BackgroundTransparency = 1
            none.Text = query == "" and "No skins available" or "No matching skins"
            none.TextColor3 = REF_MUTED
            none.TextSize = 11
            none.Font = Enum.Font.Gotham
            none.ZIndex = 21
            none.Parent = skinDropdown
            table.insert(skinButtons, none)
        end

        skinDropdown.CanvasPosition = Vector2.new(0, 0)
    end

    skinSearch:GetPropertyChangedSignal("Text"):Connect(function()
        rebuildReferenceSkins()
        if not skinDropdownOpen then
            skinDropdownOpen = true
            skinDropdown.Visible = true
        end
    end)

    skinSelector.MouseButton1Click:Connect(function()
        skinDropdownOpen = not skinDropdownOpen
        skinDropdown.Visible = skinDropdownOpen
        skinSelector.Text = (selectedSkin ~= "" and ("Skin: " .. selectedSkin .. (skinDropdownOpen and " ▲" or " ▼"))
            or (skinDropdownOpen and "Skin ▲" or "Skin ▼"))
    end)

    task.defer(function()
        weaponList.CanvasSize = UDim2.new(0, weaponLayout.AbsoluteContentSize.X + 16, 0, 0)
    end)

    local function selectReferenceWeapon(toolName)
        selectedWeapon = toolName
        selectedSkin = cfg.skins.weapons[toolName] or ""

        local displayName = names[toolName] or toolName
        currentWeaponTitle.Text = "[" .. displayName .. "]"
        if headerTitle then
            headerTitle.Text = "[" .. displayName .. "]"
        end

        for key, b in pairs(weaponButtons) do
            if key == toolName then
                b.BackgroundColor3 = REF_SELECTED
                b.TextColor3 = REF_TEXT_DARK
            else
                b.BackgroundColor3 = REF_PANEL
                b.TextColor3 = REF_TEXT
            end
        end

        rebuildReferenceSkins()
    end

    for index, toolName in ipairs(weaponOrder) do
        local b = Instance.new("TextButton")
        b.Name = "Weapon_" .. tostring(index)
        b.Size = UDim2.fromOffset(78, 31)
        b.BackgroundColor3 = REF_PANEL
        b.BorderSizePixel = 0
        b.Text = names[toolName] or toolName
        b.TextColor3 = REF_TEXT
        b.TextSize = 10
        b.Font = Enum.Font.Gotham
        b.TextXAlignment = Enum.TextXAlignment.Center
        b.AutoButtonColor = false
        b.LayoutOrder = index
        b.Parent = weaponList
        weaponButtons[toolName] = b

        b.MouseEnter:Connect(function()
            if selectedWeapon ~= toolName then
                b.BackgroundColor3 = Color3.fromRGB(232, 237, 220)
            end
        end)
        b.MouseLeave:Connect(function()
            if selectedWeapon ~= toolName then
                b.BackgroundColor3 = REF_PANEL
            end
        end)
        b.MouseButton1Click:Connect(function()
            selectReferenceWeapon(toolName)
        end)
    end

    -- Reset remains available through a tiny context button under the skin list,
    -- without changing the reference layout into a large control panel.
    local reset = Instance.new("TextButton")
    reset.Name = "ResetSkin"
    reset.Size = UDim2.fromOffset(92, 28)
    reset.Position = UDim2.new(1, -102, 1, -36)
    reset.BackgroundColor3 = REF_SELECTED
    reset.BorderSizePixel = 0
    reset.Text = "Reset Skin"
    reset.TextColor3 = REF_TEXT
    reset.TextSize = 10
    reset.Font = Enum.Font.GothamSemibold
    reset.AutoButtonColor = false
    reset.ZIndex = 6
    reset.Parent = content

    reset.MouseEnter:Connect(function()
        reset.BackgroundColor3 = Color3.fromRGB(232, 237, 220)
    end)
    reset.MouseLeave:Connect(function()
        reset.BackgroundColor3 = REF_SELECTED
    end)
    reset.MouseButton1Click:Connect(function()
        local toolName = selectedWeapon
        cfg.skins.weapons[toolName] = ""
        selectedSkin = ""
        local char = localplayer.Character
        local tool = char and char:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            if toolName == "[Knife]" then
                cleanknife(tool)
            else
                resetGun(tool)
            end
        end
        rebuildReferenceSkins()
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Astro.MAIN",
                Text = (names[toolName] or toolName) .. " reset to original",
                Duration = 2
            })
        end)
    end)

    selectReferenceWeapon(selectedWeapon)
end

--// Generic toggle creator
--// Generic toggle creator
function createToggle(parent, labelText, y)
    local rowY = math.max(42, y - 30)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -95, 0, 24)
    label.Position = UDim2.new(0, 15, 0, rowY)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(58, 68, 46)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    label.ZIndex = 3

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -63, 0, rowY + 1)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(58, 68, 46)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 9
    btn.AutoButtonColor = false
    btn.Parent = parent
    btn.ZIndex = 3
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = btn
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(166, 184, 124)
    st.Transparency = 0.25
    st.Thickness = 1
    st.Parent = btn
    return label, btn
end

--// Hitbox controls
-- Compact, spaced controls with real sliders.
hitboxLabel, hitboxBtn = createToggle(tabs.Hitbox, "Hitbox Expander", 82)

function createHitboxSlider(parent, labelText, y, minValue, maxValue, initialValue, decimals, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 22)
    y = math.max(46, y - 30)
    label.Position = UDim2.new(0, 15, 0, y)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = parent

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 55, 0, 22)
    valueLabel.Position = UDim2.new(1, -70, 0, y)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -30, 0, 5)
    bar.Position = UDim2.new(0, 15, 0, y + 27)
    bar.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
    bar.BorderSizePixel = 0
    bar.Parent = parent
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setValue(value)
        value = math.clamp(value, minValue, maxValue)
        local alpha = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        if decimals == 0 then
            valueLabel.Text = tostring(math.floor(value + 0.5))
        else
            valueLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)
        end
        callback(value)
    end

    local function fromInput(input)
        local x = input.Position.X
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(minValue + (maxValue - minValue) * alpha)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    setValue(initialValue)
    return setValue, valueLabel
end

setHitboxSizeSlider, hitboxSizeValue =
    createHitboxSlider(tabs.Hitbox, "Hitbox Size", 128, 1, 100, _G.HitboxSize, 1, function(v)
        _G.HitboxSize = math.floor(v * 2 + 0.5) / 2
        updateAyeshaHitboxes()
    end)

setHitboxVisibilitySlider, hitboxVisibilityValue =
    createHitboxSlider(tabs.Hitbox, "Visibility", 190, 0, 1, _G.HitboxTransparency, 2, function(v)
        _G.HitboxTransparency = v
        updateAyeshaHitboxes()
    end)

-- Hitbox color palette
hitboxColorLabel = Instance.new("TextLabel")
hitboxColorLabel.Size = UDim2.new(1, -30, 0, 22)
hitboxColorLabel.Position = UDim2.new(0, 15, 0, 232)
hitboxColorLabel.BackgroundTransparency = 1
hitboxColorLabel.Text = "Hitbox Color"
hitboxColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxColorLabel.TextSize = 12
hitboxColorLabel.Font = Enum.Font.Gotham
hitboxColorLabel.TextXAlignment = Enum.TextXAlignment.Left
hitboxColorLabel.Parent = tabs.Hitbox

hitboxColors = {
    Color3.fromRGB(145, 210, 240),
    Color3.fromRGB(186, 150, 235),
    Color3.fromRGB(166, 184, 124),
    Color3.fromRGB(255, 105, 105),
    Color3.fromRGB(120, 220, 160),
    Color3.fromRGB(255, 215, 80),
    Color3.fromRGB(242, 240, 248),
    Color3.fromRGB(80, 80, 90)
}

hitboxColorButtons = {}
for i, color in ipairs(hitboxColors) do
    local colorButton = Instance.new("TextButton")
    colorButton.Size = UDim2.fromOffset(24, 24)
    colorButton.Position = UDim2.fromOffset(15 + ((i - 1) % 8) * 32, 280)
    colorButton.BackgroundColor3 = color
    colorButton.BorderSizePixel = 0
    colorButton.Text = ""
    colorButton.AutoButtonColor = false
    colorButton.Parent = tabs.Hitbox
    Instance.new("UICorner", colorButton).CornerRadius = UDim.new(0, 6)
    hitboxColorButtons[i] = colorButton
    colorButton.MouseButton1Click:Connect(function()
        _G.HitboxColor = color
        for index, button in ipairs(hitboxColorButtons) do
            button.BackgroundTransparency = (hitboxColors[index] == _G.HitboxColor) and 0 or 0.15
        end
        updateAyeshaHitboxes()
    end)
end

function refreshHitboxColorUI()
    for index, button in ipairs(hitboxColorButtons) do
        button.BackgroundTransparency = (hitboxColors[index] == _G.HitboxColor) and 0 or 0.15
    end
end

function refreshHitboxUI()
    hitboxBtn.Text = _G.HitboxEnabled and "ON" or "OFF"
    hitboxBtn.BackgroundColor3 = _G.HitboxEnabled
        and Color3.fromRGB(232, 240, 216)
        or Color3.fromRGB(245, 248, 239)
    hitboxBtn.TextColor3 = _G.HitboxEnabled
        and Color3.fromRGB(255, 255, 255)
        or Color3.fromRGB(255, 255, 255)
    setHitboxSizeSlider(_G.HitboxSize)
    setHitboxVisibilitySlider(_G.HitboxTransparency)
    refreshHitboxColorUI()
    updateAyeshaHitboxes()
end

hitboxBtn.MouseButton1Click:Connect(function()
    _G.HitboxEnabled = not _G.HitboxEnabled
    refreshHitboxUI()
end)

refreshHitboxUI()

--// Flamelock controls
-- Single-column layout matching the other pages, with a dedicated settings section.
do
    local flamePage = tabs.Flamelock

    local function flameSection(title, y)
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -30, 0, 22)
        titleLabel.Position = UDim2.fromOffset(15, y)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 12
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = flamePage
        titleLabel.ZIndex = 4

        local line = Instance.new("Frame")
        line.Name = title:gsub("%s+", "") .. "Line"
        line.Size = UDim2.new(1, -30, 0, 1)
        line.Position = UDim2.fromOffset(15, y + 25)
        line.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
        line.BorderSizePixel = 0
        line.Parent = flamePage
        line.ZIndex = 4
        return titleLabel, line
    end

    -- Main Flamelock section: use the same page-header rhythm as Silent Aim and the other tabs.
    local flameHeader = Instance.new("TextLabel")
    flameHeader.Size = UDim2.new(1, -30, 0, 24)
    flameHeader.Position = UDim2.fromOffset(15, 0)
    flameHeader.BackgroundTransparency = 1
    flameHeader.Text = "Flamelock"
    flameHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    flameHeader.TextSize = 14
    flameHeader.Font = Enum.Font.GothamSemibold
    flameHeader.TextXAlignment = Enum.TextXAlignment.Left
    flameHeader.Parent = flamePage

    local flameHeaderLine = Instance.new("Frame")
    flameHeaderLine.Name = "FlamelockHeaderLine"
    flameHeaderLine.Size = UDim2.new(1, -30, 0, 1)
    flameHeaderLine.Position = UDim2.fromOffset(15, 25)
    flameHeaderLine.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
    flameHeaderLine.BorderSizePixel = 0
    flameHeaderLine.Parent = flamePage

    flameLabel, flameBtn = createToggle(flamePage, "Flamelock", 76)
    flameRightLabel, flameRightBtn = createToggle(flamePage, "Right Click Lock", 112)

    function refreshFlameButton(label, btn, enabled)
        -- Match the same toggle styling used by the other pages.
        btn.Text = enabled and "ON" or "OFF"
        btn.BackgroundColor3 = enabled
            and Color3.fromRGB(232, 240, 216)
            or Color3.fromRGB(245, 248, 239)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
    end

    flameBtn.MouseButton1Click:Connect(function()
        _G.FlamelockEnabled = not _G.FlamelockEnabled
        if not _G.FlamelockEnabled then
            _G.FlameActive = false
            flameTargetPart = nil
        end
        refreshFlameButton(flameLabel, flameBtn, _G.FlamelockEnabled)
    end)

    flameRightBtn.MouseButton1Click:Connect(function()
        _G.FlameRightClick = not _G.FlameRightClick
        refreshFlameButton(flameRightLabel, flameRightBtn, _G.FlameRightClick)
    end)

    -- Flamelock dropdown styled like Silent Aim's Hit Part dropdown.
    local function createFlameDropdown(parent, labelText, y, options, current, callback)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 100, 0, 30)
        label.Position = UDim2.fromOffset(15, y)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = parent
        label.ZIndex = 5

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 130, 0, 26)
        button.Position = UDim2.new(1, -145, 0, y + 22)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.BorderSizePixel = 0
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.Gotham
        button.Text = (current or options[1]) .. " v"
        button.AutoButtonColor = false
        button.Parent = parent
        button.ZIndex = 6
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

        local menu = Instance.new("ScrollingFrame")
        menu.Size = UDim2.new(0, 130, 0, math.min(#options * 28 + 8, 132))
        menu.Position = UDim2.new(1, -145, 0, y + 52)
        menu.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
        menu.BorderSizePixel = 0
        menu.Visible = false
        menu.ZIndex = 8
        menu.CanvasSize = UDim2.new(0, 0, 0, #options * 28 + 8)
        menu.ScrollBarThickness = 3
        menu.ScrollBarImageColor3 = Color3.fromRGB(166, 184, 124)
        menu.Parent = parent
        Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)

        local currentText = current or options[1]
        if not table.find(options, currentText) then
            currentText = options[1]
        end
        callback(currentText)

        for idx, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, -8, 0, 26)
            optionButton.Position = UDim2.new(0, 4, 0, (idx - 1) * 28 + 4)
            optionButton.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
            optionButton.BorderSizePixel = 0
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.Font = Enum.Font.Gotham
            optionButton.TextSize = 11
            optionButton.ZIndex = 9
            optionButton.AutoButtonColor = false
            optionButton.Parent = menu
            Instance.new("UICorner", optionButton).CornerRadius = UDim.new(0, 6)

            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end)

            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
            end)

            optionButton.MouseButton1Click:Connect(function()
                currentText = option
                button.Text = option .. " v"
                menu.Visible = false
                callback(option)
            end)
        end

        button.MouseButton1Click:Connect(function()
            menu.Visible = not menu.Visible
        end)

        return button, menu
    end

    createFlameDropdown(flamePage, "Activation Mode", 148, {"Hold", "Toggle"}, _G.FlameMode, function(v)
        _G.FlameMode = v
    end)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, -30, 0, 22)
    keyLabel.Position = UDim2.fromOffset(15, 204)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Flamelock Key"
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.TextSize = 12
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.Parent = flamePage
    keyLabel.ZIndex = 4

    flameKeyBtn = Instance.new("TextButton")
    flameKeyBtn.Size = UDim2.new(1, -30, 0, 26)
    flameKeyBtn.Position = UDim2.fromOffset(15, 227)
    flameKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flameKeyBtn.BorderSizePixel = 0
    flameKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flameKeyBtn.TextSize = 11
    flameKeyBtn.Font = Enum.Font.Gotham
    flameKeyBtn.Text = _G.FlameKey.Name
    flameKeyBtn.AutoButtonColor = false
    flameKeyBtn.Parent = flamePage
    flameKeyBtn.ZIndex = 4

    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color = Color3.fromRGB(166, 184, 124)
    keyStroke.Thickness = 1
    keyStroke.Parent = flameKeyBtn

    flameKeyBtn.MouseButton1Click:Connect(function()
        flameKeyBtn.Text = "PRESS KEY"
        local connection
        connection = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                _G.FlameKey = input.KeyCode
                flameKeyBtn.Text = input.KeyCode.Name
                connection:Disconnect()
            end
        end)
    end)

    -- Same Hit Part choices as Silent Aim, with a real dropdown menu.
    createFlameDropdown(
        flamePage,
        "Hit Part",
        266,
        {"Head", "Body", "Left Leg", "Right Leg", "Left Arm", "Right Arm", "Closest Part"},
        _G.FlameHitPart,
        function(v)
            _G.FlameHitPart = v
        end
    )

    -- Keep Smoothness, but remove the extra "Flamelock Settings" heading
    -- that was sitting over the controls.
    createHitboxSlider(flamePage, "Smoothness", 336, 0, 1, _G.FlameSmoothness, 2, function(v)
        _G.FlameSmoothness = v
    end)

    createHitboxSlider(flamePage, "Prediction", 410, 0, 0.5, _G.FlamePrediction, 2, function(v)
        _G.FlamePrediction = v
    end)
    createHitboxSlider(flamePage, "Left Offset", 484, -5, 5, _G.FlameLeftOffset, 2, function(v)
        _G.FlameLeftOffset = v
    end)
    createHitboxSlider(flamePage, "Up Offset", 558, -20, 5, _G.FlameUpOffset, 2, function(v)
        _G.FlameUpOffset = v
    end)

    refreshFlameButton(flameLabel, flameBtn, _G.FlamelockEnabled)
    refreshFlameButton(flameRightLabel, flameRightBtn, _G.FlameRightClick)
end

--// Final layout normalization: keep every page aligned to the same header/content rhythm.
do
    local HEADER_BOTTOM = 26
    local FIRST_ROW = 46
    for pageName, page in pairs(tabs) do
        if page and page:IsA("ScrollingFrame") then
            -- Every main page behaves like Silent Aim: vertical scrolling with
            -- the canvas determined by whatever controls are actually inside it.
            page.ScrollBarThickness = 3
            page.ScrollingEnabled = true
            page.Active = true
            page.ScrollingDirection = Enum.ScrollingDirection.Y
            page.AutomaticCanvasSize = Enum.AutomaticSize.Y
            page.CanvasSize = UDim2.new(0, 0, 0, 0)
            page.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
            page.CanvasPosition = Vector2.new(0, 0)
            for _, obj in ipairs(page:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    obj.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end

--// Master enable toggles removed; the individual page controls remain.

--// TriggerBot controls
function setupTriggerBotUI()
    local triggerLabel, triggerBtn = createToggle(tabs.TriggerBot, "TriggerBot", 82)
    local function refreshTriggerButton()
        triggerBtn.Text = TriggerBot.Enabled and "ON" or "OFF"
        triggerBtn.BackgroundColor3 = TriggerBot.Enabled and Color3.fromRGB(232, 240, 216) or Color3.fromRGB(245, 248, 239)
        triggerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    triggerBtn.MouseButton1Click:Connect(function()
        TriggerBot.Enabled = not TriggerBot.Enabled
        if not TriggerBot.Enabled then TriggerBot.Active = false end
        refreshTriggerButton()
    end)
    refreshTriggerButton()

    local triggerModeLabel, triggerModeBtn = createToggle(tabs.TriggerBot, "Mode", 120)
    triggerModeBtn.Text = TriggerBot.Mode:upper()
    triggerModeBtn.MouseButton1Click:Connect(function()
        TriggerBot.Mode = (TriggerBot.Mode == "Hold") and "Toggle" or "Hold"
        if TriggerBot.Mode == "Hold" then TriggerBot.Active = false end
        triggerModeBtn.Text = TriggerBot.Mode:upper()
    end)

    local triggerBindLabel, triggerBindBtn = createToggle(tabs.TriggerBot, "Key", 158)
    triggerBindBtn.Text = tostring(TriggerBot.Key):gsub("Enum.KeyCode.", "")
    triggerBindBtn.MouseButton1Click:Connect(function()
        triggerBindBtn.Text = "PRESS KEY"
        local connection = nil
        connection = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                TriggerBot.Key = input.KeyCode
                triggerBindBtn.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                connection:Disconnect()
            end
        end)
    end)

    local triggerDelaySet, triggerDelayValue = createHitboxSlider(
        tabs.TriggerBot, "Click Delay", 196, 0.01, 0.20,
        TriggerBot.ClickDelay, 2, function(v)
            TriggerBot.ClickDelay = v
        end
    )

end
setupTriggerBotUI()

--// Silent Aim*
toggleLabel, toggleBtn =
    createToggle(tabs.SilentAim, "Revolver Bypass", 90)
toggleBtn.MouseButton1Click:Connect(function()
    _G.RevolverBypass = not _G.RevolverBypass
    if _G.RevolverBypass then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end)
wallLabel, wallBtn =
    createToggle(tabs.SilentAim, "Wall Check", 126)
wallBtn.MouseButton1Click:Connect(function()
    _G.WallCheck = not _G.WallCheck
    if _G.WallCheck then
        wallBtn.Text = "ON"
        wallBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    else
        wallBtn.Text = "OFF"
        wallBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end)
valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -30, 0, 20)
valueLabel.Position = UDim2.new(0, 15, 0, 221)
valueLabel.Text = "FOV Radius: 1000"
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
valueLabel.TextSize = 13
valueLabel.Font = Enum.Font.Gotham
valueLabel.BackgroundTransparency = 1
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = tabs.SilentAim
valueLabel.ZIndex = 2
slider = Instance.new("Frame")
slider.Size = UDim2.new(1, -30, 0, 6)
slider.Position = UDim2.new(0, 15, 0, 251)
slider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
slider.BorderSizePixel = 0
slider.Parent = tabs.SilentAim
slider.ZIndex = 2
Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 6)
button = Instance.new("TextButton")
button.Size = UDim2.new(0, 14, 0, 14)
button.Position = UDim2.new(1, -7, 0.5, -7)
button.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
button.BorderSizePixel = 0
button.Text = ""
button.AutoButtonColor = false
button.Parent = slider
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
spreadLabel = Instance.new("TextLabel")
spreadLabel.Size = UDim2.new(1, -30, 0, 20)
spreadLabel.Position = UDim2.new(0, 15, 0, 286)
spreadLabel.Text = "Bullet Spread: 100"
spreadLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
spreadLabel.TextSize = 13
spreadLabel.Font = Enum.Font.Gotham
spreadLabel.BackgroundTransparency = 1
spreadLabel.TextXAlignment = Enum.TextXAlignment.Left
spreadLabel.Parent = tabs.SilentAim
spreadLabel.ZIndex = 2
spreadSlider = Instance.new("Frame")
spreadSlider.Size = UDim2.new(1, -30, 0, 6)
spreadSlider.Position = UDim2.new(0, 15, 0, 316)
spreadSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
spreadSlider.BorderSizePixel = 0
spreadSlider.Parent = tabs.SilentAim
spreadSlider.ZIndex = 2
Instance.new("UICorner", spreadSlider).CornerRadius = UDim.new(0, 6)
spreadBtn = Instance.new("TextButton")
spreadBtn.Size = UDim2.new(0, 14, 0, 14)
spreadBtn.Position = UDim2.new(1, -7, 0.5, -7)
spreadBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
spreadBtn.BorderSizePixel = 0
spreadBtn.Text = ""
spreadBtn.AutoButtonColor = false
spreadBtn.Parent = spreadSlider
Instance.new("UICorner", spreadBtn).CornerRadius = UDim.new(0, 6)
hitLabel = Instance.new("TextLabel")
hitLabel.Size = UDim2.new(0, 100, 0, 30)
hitLabel.Position = UDim2.new(0, 15, 0, 351)
hitLabel.Text = "Aim Part"
hitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitLabel.TextSize = 13
hitLabel.Font = Enum.Font.Gotham
hitLabel.BackgroundTransparency = 1
hitLabel.TextXAlignment = Enum.TextXAlignment.Left
hitLabel.Parent = tabs.SilentAim
hitLabel.ZIndex = 2
dropMain = Instance.new("TextButton")
dropMain.Size = UDim2.new(0, 130, 0, 26)
dropMain.Position = UDim2.new(1, -145, 0, 373)
dropMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dropMain.Text = "Head v"
dropMain.TextColor3 = Color3.fromRGB(255, 255, 255)
dropMain.Font = Enum.Font.Gotham
dropMain.TextSize = 12
dropMain.ZIndex = 5
dropMain.AutoButtonColor = false
dropMain.Parent = tabs.SilentAim
Instance.new("UICorner", dropMain).CornerRadius = UDim.new(0, 6)
dropScroll = Instance.new("ScrollingFrame")
dropScroll.Size = UDim2.new(0, 130, 0, 100)
dropScroll.Position = UDim2.new(1, -145, 0, 403)
dropScroll.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
dropScroll.BorderSizePixel = 0
dropScroll.Visible = false
dropScroll.ZIndex = 6
dropScroll.CanvasSize = UDim2.new(0, 0, 0, 215)
dropScroll.ScrollBarThickness = 3
dropScroll.ScrollBarImageColor3 = Color3.fromRGB(166, 184, 124)
dropScroll.Parent = tabs.SilentAim
Instance.new("UICorner", dropScroll).CornerRadius = UDim.new(0, 6)
partsList = {
    "Head",
    "Body",
    "Left Leg",
    "Right Leg",
    "Left Arm",
    "Right Arm",
    "Closest Part"
}
for idx, partName in ipairs(partsList) do
    local partBtn = Instance.new("TextButton")
    partBtn.Size = UDim2.new(1, -8, 0, 26)
    partBtn.Position = UDim2.new(0, 4, 0, (idx - 1) * 28 + 4)
    partBtn.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
    partBtn.Text = partName
    partBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    partBtn.Font = Enum.Font.Gotham
    partBtn.TextSize = 11
    partBtn.ZIndex = 7
    partBtn.AutoButtonColor = false
    partBtn.Parent = dropScroll
    Instance.new("UICorner", partBtn).CornerRadius = UDim.new(0, 6)
    partBtn.MouseEnter:Connect(function()
        partBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
    partBtn.MouseLeave:Connect(function()
        partBtn.BackgroundColor3 = Color3.fromRGB(232, 240, 216)
    end)
    partBtn.MouseButton1Click:Connect(function()
        aimPart = partName
        dropMain.Text = partName .. " v"
        dropScroll.Visible = false
    end)
end
dropMain.MouseButton1Click:Connect(function()
    dropScroll.Visible = not dropScroll.Visible
end)
--// Silent Aim - Ignore Knocked
ignoreKnocked = true
ignoreKnockedLabel, ignoreKnockedBtn =
    createToggle(tabs.SilentAim, "Ignore Knocked", 162)
ignoreKnockedBtn.Text = "ON"
ignoreKnockedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

ignoreKnockedBtn.MouseButton1Click:Connect(function()
    ignoreKnocked = not ignoreKnocked
    if ignoreKnocked then
        ignoreKnockedBtn.Text = "ON"
        ignoreKnockedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    else
        ignoreKnockedBtn.Text = "OFF"
        ignoreKnockedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

--// Silent Aim - Show FOV*
silentShowFOV = false
silentFovLabel, silentFovBtn =
    createToggle(tabs.SilentAim, "Show FOV", 198)
silentFovCircle = Instance.new("Frame")
silentFovCircle.Name = "SilentAimFOVCircle"
silentFovCircle.Size = UDim2.fromOffset(
    _G.FOV_RADIUS * 2,
    _G.FOV_RADIUS * 2
)
silentFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
silentFovCircle.BackgroundTransparency = 1
silentFovCircle.BorderSizePixel = 0
silentFovCircle.Visible = false
silentFovCircle.ZIndex = 50
silentFovCircle.Parent = gui
silentFovCorner = Instance.new("UICorner")
silentFovCorner.CornerRadius = UDim.new(0, 6)
silentFovCorner.Parent = silentFovCircle
silentFovStroke = Instance.new("UIStroke")
silentFovStroke.Thickness = 2
silentFovStroke.Color = Color3.fromRGB(166, 184, 124)
silentFovStroke.Parent = silentFovCircle
silentFovBtn.MouseButton1Click:Connect(function()
    silentShowFOV = not silentShowFOV
    if silentShowFOV then
        silentFovBtn.Text = "ON"
        silentFovBtn.BackgroundColor3 =
            Color3.fromRGB(255, 255, 255)
    else
        silentFovBtn.Text = "OFF"
        silentFovBtn.BackgroundColor3 =
            Color3.fromRGB(255, 255, 255)
        silentFovCircle.Visible = false
    end
end)
silentFovRunService =
    game:GetService("RunService")
silentFovRunService.RenderStepped:Connect(function()
    if not gui.Parent then
        return
    end
    if silentShowFOV then
        local mousePosition = UIS:GetMouseLocation()
        silentFovCircle.Position =
            UDim2.fromOffset(
                mousePosition.X,
                mousePosition.Y
            )
        silentFovCircle.Size =
            UDim2.fromOffset(
                _G.FOV_RADIUS * 2,
                _G.FOV_RADIUS * 2
            )
        silentFovCircle.Visible = true
    else
        silentFovCircle.Visible = false
    end
end)
--// ESP*
espBoxLabel, espBoxBtn =
    createToggle(tabs.ESP, "ESP Boxes", 88)
espBoxBtn.MouseButton1Click:Connect(function()
    _G.ESP_Boxes = not _G.ESP_Boxes
    espBoxBtn.Text = _G.ESP_Boxes and "ON" or "OFF"
    espBoxBtn.BackgroundColor3 =
        _G.ESP_Boxes
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)
espNameLabel, espNameBtn =
    createToggle(tabs.ESP, "ESP Names", 124)
espNameBtn.MouseButton1Click:Connect(function()
    _G.ESP_Names = not _G.ESP_Names
    espNameBtn.Text = _G.ESP_Names and "ON" or "OFF"
    espNameBtn.BackgroundColor3 =
        _G.ESP_Names
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)
espDistanceLabel, espDistanceBtn = createToggle(tabs.ESP, "ESP Distance", 160)
espDistanceBtn.MouseButton1Click:Connect(function()
    _G.ESP_Distance = not _G.ESP_Distance
    espDistanceBtn.Text = _G.ESP_Distance and "ON" or "OFF"
    espDistanceBtn.BackgroundColor3 = _G.ESP_Distance
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)
espSnaplineLabel, espSnaplineBtn = createToggle(tabs.ESP, "ESP Snaplines", 196)
espSnaplineBtn.MouseButton1Click:Connect(function()
    _G.ESP_Snaplines = not _G.ESP_Snaplines
    espSnaplineBtn.Text = _G.ESP_Snaplines and "ON" or "OFF"
    espSnaplineBtn.BackgroundColor3 = _G.ESP_Snaplines
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)
espSkeletonLabel, espSkeletonBtn = createToggle(tabs.ESP, "ESP Skeleton", 232)
espSkeletonBtn.MouseButton1Click:Connect(function()
    _G.ESP_Skeleton = not _G.ESP_Skeleton
    espSkeletonBtn.Text = _G.ESP_Skeleton and "ON" or "OFF"
    espSkeletonBtn.BackgroundColor3 = _G.ESP_Skeleton
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)
paletteLabel = Instance.new("TextLabel")
paletteLabel.Size = UDim2.new(1, -30, 0, 20)
paletteLabel.Position = UDim2.new(0, 15, 0, 230)
paletteLabel.Text = "Select ESP Color"
paletteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
paletteLabel.TextSize = 13
paletteLabel.Font = Enum.Font.Gotham
paletteLabel.BackgroundTransparency = 1
paletteLabel.TextXAlignment = Enum.TextXAlignment.Left
paletteLabel.Parent = tabs.ESP
colorColors = {
    Color3.fromRGB(80, 170, 255),
    Color3.fromRGB(50, 120, 220),
    Color3.fromRGB(30, 70, 160),
    Color3.fromRGB(80, 220, 220),
    Color3.fromRGB(50, 220, 120),
    Color3.fromRGB(255, 220, 80),
    Color3.fromRGB(160, 100, 255),
    Color3.fromRGB(20, 20, 30),
    Color3.fromRGB(166, 184, 124)
}
for idx, colorHex in ipairs(colorColors) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 26, 0, 26)
    cBtn.Position = UDim2.new(
        0,
        15 + ((idx - 1) % 5) * 34,
        0,
        300 + math.floor((idx - 1) / 5) * 34
    )
    cBtn.BackgroundColor3 = colorHex
    cBtn.Text = ""
    cBtn.AutoButtonColor = false
    cBtn.Parent = tabs.ESP
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)
    local strk = Instance.new("UIStroke")
    strk.Color = Color3.fromRGB(166, 184, 124)
    strk.Transparency = 0.45
    strk.Parent = cBtn
    cBtn.MouseButton1Click:Connect(function()
        _G.ESP_Color = colorHex
    end)
end
--// Speed*
speedToggleLabel, speedToggleBtn =
    createToggle(tabs.Misc, "Speed Enabled", 55)
speedToggleBtn.MouseButton1Click:Connect(function()
    _G.Speed_ToggleEnabled = not _G.Speed_ToggleEnabled
    speedToggleBtn.Text =
        _G.Speed_ToggleEnabled and "ON" or "OFF"
    speedToggleBtn.BackgroundColor3 =
        _G.Speed_ToggleEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
    if not _G.Speed_ToggleEnabled then
        _G.Speed_Enabled = false
    end
end)
keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(0, 150, 0, 30)
keyLabel.Position = UDim2.new(0, 15, 0, 75)
keyLabel.Text = "Speed Bind"
keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
keyLabel.TextSize = 13
keyLabel.Font = Enum.Font.Gotham
keyLabel.BackgroundTransparency = 1
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Parent = tabs.Misc
bindBtn = Instance.new("TextButton")
bindBtn.Size = UDim2.new(0, 70, 0, 22)
bindBtn.Position = UDim2.new(1, -85, 0, 99)
bindBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
bindBtn.Text = "Key: X"
bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bindBtn.Font = Enum.Font.Gotham
bindBtn.TextSize = 11
bindBtn.AutoButtonColor = false
bindBtn.Parent = tabs.Misc
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)
isBinding = false
bindBtn.MouseButton1Click:Connect(function()
    isBinding = true
    bindBtn.Text = "Press key"
end)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if isBinding
        and input.UserInputType == Enum.UserInputType.Keyboard then
        _G.Speed_Key = input.KeyCode
        bindBtn.Text = "Key: " .. input.KeyCode.Name
        isBinding = false
    end
end)
speedValLabel = Instance.new("TextLabel")
speedValLabel.Size = UDim2.new(1, -30, 0, 20)
speedValLabel.Position = UDim2.new(0, 15, 0, 95)
speedValLabel.Text = "Speed Value: 50"
speedValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValLabel.TextSize = 13
speedValLabel.Font = Enum.Font.Gotham
speedValLabel.BackgroundTransparency = 1
speedValLabel.TextXAlignment = Enum.TextXAlignment.Left
speedValLabel.Parent = tabs.Misc
speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, -30, 0, 6)
speedSlider.Position = UDim2.new(0, 15, 0, 125)
speedSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = tabs.Misc
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(0, 6)
speedSliderBtn = Instance.new("TextButton")
speedSliderBtn.Size = UDim2.new(0, 14, 0, 14)
speedSliderBtn.Position = UDim2.new(0, 0, 0.5, -7)
speedSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
speedSliderBtn.BorderSizePixel = 0
speedSliderBtn.Text = ""
speedSliderBtn.AutoButtonColor = false
speedSliderBtn.Parent = speedSlider
Instance.new("UICorner", speedSliderBtn).CornerRadius = UDim.new(0, 6)

--// High Jump*
highJumpToggleLabel, highJumpToggleBtn =
    createToggle(tabs.Misc, "High Jump", 205)

highJumpToggleBtn.MouseButton1Click:Connect(function()
    _G.HighJump_Enabled = not _G.HighJump_Enabled
    highJumpToggleBtn.Text = _G.HighJump_Enabled and "ON" or "OFF"
    highJumpToggleBtn.BackgroundColor3 =
        _G.HighJump_Enabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)

highJumpValLabel = Instance.new("TextLabel")
highJumpValLabel.Size = UDim2.new(1, -30, 0, 20)
highJumpValLabel.Position = UDim2.new(0, 15, 0, 225)
highJumpValLabel.Text = "High Jump: 50"
highJumpValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
highJumpValLabel.TextSize = 13
highJumpValLabel.Font = Enum.Font.Gotham
highJumpValLabel.BackgroundTransparency = 1
highJumpValLabel.TextXAlignment = Enum.TextXAlignment.Left
highJumpValLabel.Parent = tabs.Misc

highJumpSlider = Instance.new("Frame")
highJumpSlider.Size = UDim2.new(1, -30, 0, 6)
highJumpSlider.Position = UDim2.new(0, 15, 0, 255)
highJumpSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
highJumpSlider.BorderSizePixel = 0
highJumpSlider.Parent = tabs.Misc
Instance.new("UICorner", highJumpSlider).CornerRadius = UDim.new(0, 6)

highJumpSliderBtn = Instance.new("TextButton")
highJumpSliderBtn.Size = UDim2.new(0, 14, 0, 14)
highJumpSliderBtn.Position = UDim2.new(0, 0, 0.5, -7)
highJumpSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
highJumpSliderBtn.BorderSizePixel = 0
highJumpSliderBtn.Text = ""
highJumpSliderBtn.AutoButtonColor = false
highJumpSliderBtn.Parent = highJumpSlider
Instance.new("UICorner", highJumpSliderBtn).CornerRadius = UDim.new(0, 6)

highJumpDragging = false
function updateHighJumpSlider(input)
    local width = highJumpSlider.AbsoluteSize.X
    if width <= 0 then
        return
    end

    local percentage = math.clamp(
        (input.Position.X - highJumpSlider.AbsolutePosition.X) / width,
        0,
        1
    )

    _G.HighJump_Value = math.round(25 + (percentage * 175))
    highJumpValLabel.Text = "High Jump: " .. tostring(_G.HighJump_Value)
    highJumpSliderBtn.Position =
        UDim2.new(percentage, -7, 0.5, -7)
end

highJumpSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        highJumpDragging = true
    end
end)

highJumpSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        highJumpDragging = true
        updateHighJumpSlider(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        if highJumpDragging then
            updateHighJumpSlider(input)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        highJumpDragging = false
    end
end)

--// Fly
flyToggleLabel, flyToggleBtn = createToggle(tabs.Misc, "Fly", 315)

local function updateFlyButton()
    flyToggleBtn.Text = _G.Fly_Enabled and "ON" or "OFF"
    flyToggleBtn.BackgroundColor3 = _G.Fly_Enabled and Color3.fromRGB(166, 184, 124) or Color3.fromRGB(245, 248, 239)
    flyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

flyToggleBtn.MouseButton1Click:Connect(function()
    _G.Fly_Enabled = not _G.Fly_Enabled
    updateFlyButton()

    if not _G.Fly_Enabled then
        for key in pairs(FlyKeyState) do
            FlyKeyState[key] = false
        end

        local character = me.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        if hrp then
            local v = hrp:FindFirstChild("AyeshaFlyVelocity")
            if v then v:Destroy() end
            local g = hrp:FindFirstChild("AyeshaFlyGyro")
            if g then g:Destroy() end
        end
    end
end)

flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(1, -30, 0, 20)
flySpeedLabel.Position = UDim2.new(0, 15, 0, 325)
flySpeedLabel.Text = "Fly Speed: " .. tostring(_G.Fly_Speed)
flySpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedLabel.TextSize = 13
flySpeedLabel.Font = Enum.Font.Gotham
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
flySpeedLabel.Parent = tabs.Misc

flySpeedSlider = Instance.new("Frame")
flySpeedSlider.Size = UDim2.new(1, -30, 0, 6)
flySpeedSlider.Position = UDim2.new(0, 15, 0, 355)
flySpeedSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
flySpeedSlider.BorderSizePixel = 0
flySpeedSlider.Parent = tabs.Misc
Instance.new("UICorner", flySpeedSlider).CornerRadius = UDim.new(0, 6)

flySpeedSliderBtn = Instance.new("TextButton")
flySpeedSliderBtn.Size = UDim2.new(0, 14, 0, 14)
flySpeedSliderBtn.Position = UDim2.new(math.clamp((_G.Fly_Speed - 10) / 490, 0, 1), -7, 0.5, -7)
flySpeedSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
flySpeedSliderBtn.BorderSizePixel = 0
flySpeedSliderBtn.Text = ""
flySpeedSliderBtn.AutoButtonColor = false
flySpeedSliderBtn.Parent = flySpeedSlider
Instance.new("UICorner", flySpeedSliderBtn).CornerRadius = UDim.new(0, 6)

flySpeedDragging = false
function updateFlySpeedSlider(input)
    local width = flySpeedSlider.AbsoluteSize.X
    if width <= 0 then return end
    local percentage = math.clamp((input.Position.X - flySpeedSlider.AbsolutePosition.X) / width, 0, 1)
    _G.Fly_Speed = math.round(10 + (percentage * 490))
    flySpeedLabel.Text = "Fly Speed: " .. tostring(_G.Fly_Speed)
    flySpeedSliderBtn.Position = UDim2.new(percentage, -7, 0.5, -7)
end

flySpeedSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        flySpeedDragging = true
    end
end)
flySpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        flySpeedDragging = true
        updateFlySpeedSlider(input)
    end
end)
UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and flySpeedDragging then
        updateFlySpeedSlider(input)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        flySpeedDragging = false
    end
end)

-- Fly click-to-set keybind
local flyKeybindLabel = Instance.new("TextLabel")
flyKeybindLabel.Name = "FlyKeybindLabel"
flyKeybindLabel.Size = UDim2.new(1, -30, 0, 20)
flyKeybindLabel.Position = UDim2.new(0, 15, 0, 385)
flyKeybindLabel.Text = "Fly Keybind"
flyKeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flyKeybindLabel.TextSize = 13
flyKeybindLabel.Font = Enum.Font.Gotham
flyKeybindLabel.BackgroundTransparency = 1
flyKeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
flyKeybindLabel.Parent = tabs.Misc

local flyKeybindButton = Instance.new("TextButton")
flyKeybindButton.Name = "FlyKeybindButton"
flyKeybindButton.Size = UDim2.new(0, 130, 0, 28)
flyKeybindButton.Position = UDim2.new(0, 15, 0, 412)
flyKeybindButton.Text = _G.Fly_Keybind.Name
flyKeybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyKeybindButton.TextSize = 12
flyKeybindButton.Font = Enum.Font.GothamMedium
flyKeybindButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flyKeybindButton.BorderSizePixel = 0
flyKeybindButton.AutoButtonColor = false
flyKeybindButton.Parent = tabs.Misc
Instance.new("UICorner", flyKeybindButton).CornerRadius = UDim.new(0, 5)

local flyKeybindHint = Instance.new("TextLabel")
flyKeybindHint.Name = "FlyKeybindHint"
flyKeybindHint.Size = UDim2.new(1, -160, 0, 28)
flyKeybindHint.Position = UDim2.new(0, 155, 0, 412)
flyKeybindHint.Text = "Click to change"
flyKeybindHint.TextColor3 = Color3.fromRGB(155, 155, 165)
flyKeybindHint.TextSize = 11
flyKeybindHint.Font = Enum.Font.Gotham
flyKeybindHint.BackgroundTransparency = 1
flyKeybindHint.TextXAlignment = Enum.TextXAlignment.Left
flyKeybindHint.Parent = tabs.Misc

flyKeybindButton.MouseButton1Click:Connect(function()
    if Fly_KeybindListening then return end
    Fly_KeybindListening = true
    flyKeybindButton.Text = "Press a key..."
    flyKeybindHint.Text = "Press ESC to cancel"
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if Fly_KeybindListening then
        if input.KeyCode == Enum.KeyCode.Escape then
            Fly_KeybindListening = false
            flyKeybindButton.Text = _G.Fly_Keybind.Name
            flyKeybindHint.Text = "Click to change"
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            _G.Fly_Keybind = input.KeyCode
            Fly_KeybindListening = false
            flyKeybindButton.Text = _G.Fly_Keybind.Name
            flyKeybindHint.Text = "Click to change"
            return
        end
    end

    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and _G.Fly_Keybind and input.KeyCode == _G.Fly_Keybind then
        _G.Fly_Enabled = not _G.Fly_Enabled
        updateFlyButton()
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then FlyKeyState.W=true
    elseif key == Enum.KeyCode.A then FlyKeyState.A=true
    elseif key == Enum.KeyCode.S then FlyKeyState.S=true
    elseif key == Enum.KeyCode.D then FlyKeyState.D=true
    elseif key == Enum.KeyCode.Space then FlyKeyState.Space=true
    elseif key == Enum.KeyCode.LeftControl then FlyKeyState.LeftControl=true end
end)
UIS.InputEnded:Connect(function(input)
    local key = input.KeyCode
    if key == Enum.KeyCode.W then FlyKeyState.W=false
    elseif key == Enum.KeyCode.A then FlyKeyState.A=false
    elseif key == Enum.KeyCode.S then FlyKeyState.S=false
    elseif key == Enum.KeyCode.D then FlyKeyState.D=false
    elseif key == Enum.KeyCode.Space then FlyKeyState.Space=false
    elseif key == Enum.KeyCode.LeftControl then FlyKeyState.LeftControl=false end
end)
updateFlyButton()
me.CharacterAdded:Connect(function(character)
    table.clear(FlyKeyState)
    FlyKeyState = {W=false,A=false,S=false,D=false,Space=false,LeftControl=false}
end)


--// Avatar Settings
-- Styled to match the rest of the UI: consistent rows, spacing, sizing, and controls.

avatarPage = tabs.Avatar

-- Dedicated Avatar appearance area so both controls remain clearly visible.
local avatarAppearanceCard = Instance.new("Frame")
avatarAppearanceCard.Name = "AvatarAppearanceCard"
avatarAppearanceCard.Size = UDim2.new(1, -30, 0, 122)
avatarAppearanceCard.Position = UDim2.fromOffset(15, 31)
avatarAppearanceCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
avatarAppearanceCard.BorderSizePixel = 0
avatarAppearanceCard.Parent = avatarPage
local avatarAppearanceStroke = Instance.new("UIStroke")
avatarAppearanceStroke.Color = Color3.fromRGB(166, 184, 124)
avatarAppearanceStroke.Thickness = 1
avatarAppearanceStroke.Parent = avatarAppearanceCard
Instance.new("UICorner", avatarAppearanceCard).CornerRadius = UDim.new(0, 8)

local avatarAppearanceTitle = Instance.new("TextLabel")
avatarAppearanceTitle.Size = UDim2.new(1, -20, 0, 22)
avatarAppearanceTitle.Position = UDim2.fromOffset(10, 8)
avatarAppearanceTitle.BackgroundTransparency = 1
avatarAppearanceTitle.Text = "Appearance"
avatarAppearanceTitle.TextColor3 = Color3.fromRGB(58, 68, 46)
avatarAppearanceTitle.TextSize = 12
avatarAppearanceTitle.Font = Enum.Font.GothamSemibold
avatarAppearanceTitle.TextXAlignment = Enum.TextXAlignment.Left
avatarAppearanceTitle.Parent = avatarAppearanceCard

-- Remove Accessories & Hair
accessoriesRemoved = false
savedAccessories = {}

function setAccessoriesRemoved(enabled)
    accessoriesRemoved = enabled

    local character = me.Character
    if not character then
        return
    end

    if enabled then
        table.clear(savedAccessories)

        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Accessory") then
                table.insert(savedAccessories, object)
                object.Parent = nil
            end
        end
    else
        for _, accessory in ipairs(savedAccessories) do
            if accessory and accessory.Parent == nil then
                accessory.Parent = character
            end
        end

        table.clear(savedAccessories)
    end
end

accessoriesLabel, accessoriesButton =
    createToggle(avatarAppearanceCard, "Remove Accessories & Hair", 72)

function updateAccessoriesButton()
    accessoriesButton.Text = accessoriesRemoved and "ON" or "OFF"
    accessoriesButton.BackgroundColor3 = accessoriesRemoved
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end

accessoriesButton.MouseButton1Click:Connect(function()
    setAccessoriesRemoved(not accessoriesRemoved)
    updateAccessoriesButton()
end)

-- Headless
-- Keep the effect applied after respawns and after Roblox rebuilds the avatar appearance.
headlessEnabled = false
headlessOriginals = {}
headlessEnforcer = nil

local function applyHeadlessToCharacter(character)
    if not character or not headlessEnabled then
        return
    end

    local head = character:FindFirstChild("Head")
    if not head then
        return
    end

    if headlessOriginals[head] == nil then
        headlessOriginals[head] = head.LocalTransparencyModifier
    end
    head.LocalTransparencyModifier = 1

    for _, child in ipairs(head:GetDescendants()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            if headlessOriginals[child] == nil then
                headlessOriginals[child] = child.Transparency
            end
            child.Transparency = 1
        end
    end
end

local function restoreHeadlessCharacter()
    for object, original in pairs(headlessOriginals) do
        if object and object.Parent then
            if object:IsA("BasePart") then
                object.LocalTransparencyModifier = original
            elseif object:IsA("Decal") or object:IsA("Texture") then
                object.Transparency = original
            end
        end
    end
    table.clear(headlessOriginals)
end

function setHeadless(enabled)
    headlessEnabled = enabled

    if enabled then
        table.clear(headlessOriginals)
        applyHeadlessToCharacter(me.Character)

        if not headlessEnforcer then
            headlessEnforcer = RunService.Heartbeat:Connect(function()
                if headlessEnabled and me.Character then
                    applyHeadlessToCharacter(me.Character)
                end
            end)
        end
    else
        restoreHeadlessCharacter()
    end
end

headlessLabel, headlessButton =
    createToggle(avatarAppearanceCard, "Headless", 108)

function updateHeadlessButton()
    headlessButton.Text = headlessEnabled and "ON" or "OFF"
    headlessButton.BackgroundColor3 = headlessEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end

headlessButton.MouseButton1Click:Connect(function()
    setHeadless(not headlessEnabled)
    updateHeadlessButton()
end)

--// Compact Animation Changer
animationTitle = Instance.new("TextLabel")
animationTitle.Name = "AnimationChangerTitle"
animationTitle.Size = UDim2.new(1, -30, 0, 24)
animationTitle.Position = UDim2.new(0, 15, 0, 160)
animationTitle.BackgroundTransparency = 1
animationTitle.Text = "Animation Changer"
animationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
animationTitle.TextSize = 13
animationTitle.Font = Enum.Font.Gotham
animationTitle.TextXAlignment = Enum.TextXAlignment.Left
animationTitle.Parent = avatarPage

animationOptions = {
    "None",
    "Bubbly",
    "Stylish",
    "Zombie",
    "Rthro",
    "Pirate",
    "Ninja",
    "Cartoony",
    "Superhero",
    "Robot",
    "Mage",
    "Levitation",
    "Vampire",
    "Werewolf",
    "Astronaut",
    "Knight",
    "Elder",
    "Toy"
}

animationPacks = {
    Bubbly = {
        Idle1 = "rbxassetid://910004836",
        Idle2 = "rbxassetid://910009958",
        Walk = "rbxassetid://910034870",
        Run = "rbxassetid://910025107",
        Jump = "rbxassetid://910016857",
        Fall = "rbxassetid://910001910"
    },

    Stylish = {
        Idle1 = "rbxassetid://616136790",
        Idle2 = "rbxassetid://616138447",
        Walk = "rbxassetid://616146177",
        Run = "rbxassetid://616140816",
        Jump = "rbxassetid://616139451",
        Fall = "rbxassetid://616134815"
    },

    Zombie = {
        Idle1 = "rbxassetid://616158929",
        Idle2 = "rbxassetid://616160636",
        Walk = "rbxassetid://616168032",
        Run = "rbxassetid://616163682",
        Jump = "rbxassetid://616161997",
        Fall = "rbxassetid://616157476"
    },

    Rthro = {
        Idle1 = "rbxassetid://2510197257",
        Idle2 = "rbxassetid://2510196951",
        Walk = "rbxassetid://2510202577",
        Run = "rbxassetid://2510198475",
        Jump = "rbxassetid://2510197830",
        Fall = "rbxassetid://2510195892"
    },

    Pirate = {
        Idle1 = "rbxassetid://750781874",
        Idle2 = "rbxassetid://750782770",
        Walk = "rbxassetid://750785693",
        Run = "rbxassetid://750783738",
        Jump = "rbxassetid://750782230",
        Fall = "rbxassetid://750780242"
    },

    Ninja = {
        Idle1 = "rbxassetid://656117400",
        Idle2 = "rbxassetid://656118341",
        Walk = "rbxassetid://656121766",
        Run = "rbxassetid://656118852",
        Jump = "rbxassetid://656117878",
        Fall = "rbxassetid://656115606"
    },

    Cartoony = {
        Idle1 = "rbxassetid://742637544",
        Idle2 = "rbxassetid://742638445",
        Walk = "rbxassetid://742640026",
        Run = "rbxassetid://742638842",
        Jump = "rbxassetid://742637942",
        Fall = "rbxassetid://742637151"
    },

    Superhero = {
        Idle1 = "rbxassetid://619512366",
        Idle2 = "rbxassetid://619511947",
        Walk = "rbxassetid://619512767",
        Run = "rbxassetid://619513015",
        Jump = "rbxassetid://619512161",
        Fall = "rbxassetid://619511563"
    },

    Robot = {
        Idle1 = "rbxassetid://616088211",
        Idle2 = "rbxassetid://616089559",
        Walk = "rbxassetid://616095330",
        Run = "rbxassetid://616091570",
        Jump = "rbxassetid://616090535",
        Fall = "rbxassetid://616089014"
    },

    Mage = {
        Idle1 = "rbxassetid://707742142",
        Idle2 = "rbxassetid://707855907",
        Walk = "rbxassetid://707897309",
        Run = "rbxassetid://707861613",
        Jump = "rbxassetid://707853694",
        Fall = "rbxassetid://707829716"
    },

    Levitation = {
        Idle1 = "rbxassetid://616006778",
        Idle2 = "rbxassetid://616008087",
        Walk = "rbxassetid://616013216",
        Run = "rbxassetid://616010382",
        Jump = "rbxassetid://616008936",
        Fall = "rbxassetid://616005863"
    },

    Vampire = {
        Idle1 = "rbxassetid://1083445855",
        Idle2 = "rbxassetid://1083450166",
        Walk = "rbxassetid://1083473930",
        Run = "rbxassetid://1083462077",
        Jump = "rbxassetid://1083455352",
        Fall = "rbxassetid://1083443587"
    },

    Werewolf = {
        Idle1 = "rbxassetid://1083195517",
        Idle2 = "rbxassetid://1083214717",
        Walk = "rbxassetid://1083178339",
        Run = "rbxassetid://1083216690",
        Jump = "rbxassetid://1083218792",
        Fall = "rbxassetid://1083189019"
    },

    Astronaut = {
        Idle1 = "rbxassetid://891621366",
        Idle2 = "rbxassetid://891633237",
        Walk = "rbxassetid://891636393",
        Run = "rbxassetid://891636393",
        Jump = "rbxassetid://891627522",
        Fall = "rbxassetid://891617961"
    },

    Knight = {
        Idle1 = "rbxassetid://658409194",
        Idle2 = "rbxassetid://657595757",
        Walk = "rbxassetid://657552124",
        Run = "rbxassetid://657564596",
        Jump = "rbxassetid://658409194",
        Fall = "rbxassetid://657568135"
    },

    Elder = {
        Idle1 = "rbxassetid://845397899",
        Idle2 = "rbxassetid://845400520",
        Walk = "rbxassetid://845403856",
        Run = "rbxassetid://845386501",
        Jump = "rbxassetid://845398858",
        Fall = "rbxassetid://845396048"
    },

    Toy = {
        Idle1 = "rbxassetid://782841498",
        Idle2 = "rbxassetid://782845736",
        Walk = "rbxassetid://782843345",
        Run = "rbxassetid://782842708",
        Jump = "rbxassetid://782847020",
        Fall = "rbxassetid://782846423"
    }
}

selectedAnimations = {
    Idle = "None",
    Walk = "None",
    Run = "None",
    Jump = "None",
    Fall = "None"
}

originalAnimations = {}
originalAnimationsSaved = false
animationRows = {}

function getAnimationObjects(character)
    if not character then
        return nil
    end

    local animate = character:FindFirstChild("Animate")
    if not animate then
        return nil
    end

    local idle = animate:FindFirstChild("idle")
    local walk = animate:FindFirstChild("walk")
    local run = animate:FindFirstChild("run")
    local jump = animate:FindFirstChild("jump")
    local fall = animate:FindFirstChild("fall")

    return {
        Animate = animate,
        Idle1 = idle and idle:FindFirstChild("Animation1"),
        Idle2 = idle and idle:FindFirstChild("Animation2"),
        Walk = walk and walk:FindFirstChild("WalkAnim"),
        Run = run and run:FindFirstChild("RunAnim"),
        Jump = jump and jump:FindFirstChild("JumpAnim"),
        Fall = fall and fall:FindFirstChild("FallAnim")
    }
end

function saveOriginalAnimations()
    local objects = getAnimationObjects(me.Character)
    if not objects then
        return false
    end

    table.clear(originalAnimations)

    for key, object in pairs(objects) do
        if key ~= "Animate" and object and object:IsA("Animation") then
            originalAnimations[key] = object.AnimationId
        end
    end

    originalAnimationsSaved = true
    return true
end

function restoreOriginalAnimations()
    local objects = getAnimationObjects(me.Character)
    if not objects or not originalAnimationsSaved then
        return
    end

    for key, id in pairs(originalAnimations) do
        local object = objects[key]

        if object and object:IsA("Animation") then
            object.AnimationId = id
        end
    end
end

function restartAnimations()
    local character = me.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local objects = getAnimationObjects(character)

    if not humanoid or not objects then
        return
    end

    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end

    local animate = objects.Animate

    if animate then
        animate.Disabled = true
        task.wait()
        animate.Disabled = false
    end
end

function applyAnimations()
    local character = me.Character
    if not character then
        return
    end

    if not originalAnimationsSaved then
        if not saveOriginalAnimations() then
            return
        end
    end

    local objects = getAnimationObjects(character)
    if not objects then
        return
    end

    local function applyOne(key, selection)
        local object = objects[key]

        if not object or not object:IsA("Animation") then
            return
        end

        if selection == "None" then
            if originalAnimations[key] then
                object.AnimationId = originalAnimations[key]
            end
        else
            local pack = animationPacks[selection]

            if pack and pack[key] then
                object.AnimationId = pack[key]
            end
        end
    end

    applyOne("Idle1", selectedAnimations.Idle)
    applyOne("Idle2", selectedAnimations.Idle)
    applyOne("Walk", selectedAnimations.Walk)
    applyOne("Run", selectedAnimations.Run)
    applyOne("Jump", selectedAnimations.Jump)
    applyOne("Fall", selectedAnimations.Fall)

    restartAnimations()
end

function closeAnimationLists(exceptList)
    for _, data in pairs(animationRows) do
        if data.list ~= exceptList then
            data.list.Visible = false
        end
    end
end

function createAnimationDropdown(name, y)
    local rowLabel = Instance.new("TextLabel")
    rowLabel.Name = name .. "Label"
    rowLabel.Size = UDim2.new(0, 180, 0, 30)
    rowLabel.Position = UDim2.new(0, 15, 0, y - 3)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = name
    rowLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rowLabel.TextSize = 13
    rowLabel.Font = Enum.Font.Gotham
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.Parent = avatarPage

    local main = Instance.new("TextButton")
    main.Name = name .. "Dropdown"
    main.Size = UDim2.new(0, 190, 0, 22)
    main.Position = UDim2.new(1, -205, 0, y + 1)
    main.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
    main.BorderSizePixel = 0
    main.Text = "None  ▲"
    main.TextColor3 = Color3.fromRGB(255, 255, 255)
    main.TextSize = 11
    main.Font = Enum.Font.Gotham
    main.TextXAlignment = Enum.TextXAlignment.Left
    main.AutoButtonColor = false
    main.ZIndex = 20
    main.Parent = avatarPage

    local mainPadding = Instance.new("UIPadding")
    mainPadding.PaddingLeft = UDim.new(0, 9)
    mainPadding.Parent = main

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 6)
    mainCorner.Parent = main

    local list = Instance.new("ScrollingFrame")
    list.Name = name .. "Options"
    list.Size = UDim2.new(0, 190, 0, math.min(#animationOptions * 19 + 4, 150))
    list.CanvasSize = UDim2.new(0, 0, 0, #animationOptions * 19 + 4)
    list.ScrollBarThickness = 3
    list.ScrollBarImageTransparency = 0.25
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ClipsDescendants = true
    list.Position = UDim2.new(1, -205, 0, y + 25)
    list.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 30
    list.Parent = avatarPage

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = list

    for index, option in ipairs(animationOptions) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, -4, 0, 18)
        optionButton.Position = UDim2.new(0, 2, 0, (index - 1) * 19 + 2)
        optionButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.TextSize = 11
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 31
        optionButton.Parent = list

        local optionPadding = Instance.new("UIPadding")
        optionPadding.PaddingLeft = UDim.new(0, 8)
        optionPadding.Parent = optionButton

        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 6)
        optionCorner.Parent = optionButton

        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
        end)

        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
        end)

        optionButton.MouseButton1Click:Connect(function()
            selectedAnimations[name] = option
            main.Text = option .. "  ▲"
            list.Visible = false
        end)
    end

    main.MouseButton1Click:Connect(function()
        local willOpen = not list.Visible

        closeAnimationLists(list)
        list.Visible = willOpen

        if willOpen then
            main.Text = selectedAnimations[name] .. "  ▲"
        end
    end)

    animationRows[name] = {
        button = main,
        list = list
    }
end

createAnimationDropdown("Idle", 189)

movementDivider = Instance.new("Frame")
movementDivider.Name = "MovementDivider"
movementDivider.Size = UDim2.new(1, -30, 0, 1)
movementDivider.Position = UDim2.new(0, 15, 0, 182)
movementDivider.BackgroundColor3 = Color3.fromRGB(220, 226, 208)
movementDivider.BorderSizePixel = 0
movementDivider.Parent = avatarPage

createAnimationDropdown("Walk", 219)
createAnimationDropdown("Run", 249)
createAnimationDropdown("Jump", 279)
createAnimationDropdown("Fall", 309)

previewingAnimations = false

previewAnimationButton = Instance.new("TextButton")
previewAnimationButton.Name = "PreviewAnimations"
previewAnimationButton.Size = UDim2.new(0, 85, 0, 23)
previewAnimationButton.Position = UDim2.new(1, -280, 0, 345)
previewAnimationButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
previewAnimationButton.BorderSizePixel = 0
previewAnimationButton.Text = "Preview"
previewAnimationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
previewAnimationButton.TextSize = 10
previewAnimationButton.Font = Enum.Font.Gotham
previewAnimationButton.AutoButtonColor = false
previewAnimationButton.Parent = avatarPage

previewAnimationCorner = Instance.new("UICorner")
previewAnimationCorner.CornerRadius = UDim.new(0, 6)
previewAnimationCorner.Parent = previewAnimationButton

previewAnimationButton.MouseButton1Click:Connect(function()
    if previewingAnimations then
        restoreOriginalAnimations()
        restartAnimations()
        previewingAnimations = false
        previewAnimationButton.Text = "Preview"
        previewAnimationButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
    else
        if not originalAnimationsSaved then
            saveOriginalAnimations()
        end
        applyAnimations()
        previewingAnimations = true
        previewAnimationButton.Text = "Stop"
        previewAnimationButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
    end
end)

applyAnimationButton = Instance.new("TextButton")
applyAnimationButton.Name = "ApplyAnimations"
applyAnimationButton.Size = UDim2.new(0, 85, 0, 23)
applyAnimationButton.Position = UDim2.new(1, -185, 0, 345)
applyAnimationButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
applyAnimationButton.BorderSizePixel = 0
applyAnimationButton.Text = "Apply"
applyAnimationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
applyAnimationButton.TextSize = 10
applyAnimationButton.Font = Enum.Font.Gotham
applyAnimationButton.AutoButtonColor = false
applyAnimationButton.Parent = avatarPage

applyAnimationCorner = Instance.new("UICorner")
applyAnimationCorner.CornerRadius = UDim.new(0, 6)
applyAnimationCorner.Parent = applyAnimationButton

resetAnimationButton = Instance.new("TextButton")
resetAnimationButton.Name = "ResetAnimations"
resetAnimationButton.Size = UDim2.new(0, 85, 0, 23)
resetAnimationButton.Position = UDim2.new(1, -95, 0, 345)
resetAnimationButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
resetAnimationButton.BorderSizePixel = 0
resetAnimationButton.Text = "Reset"
resetAnimationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetAnimationButton.TextSize = 10
resetAnimationButton.Font = Enum.Font.Gotham
resetAnimationButton.AutoButtonColor = false
resetAnimationButton.Parent = avatarPage

resetAnimationCorner = Instance.new("UICorner")
resetAnimationCorner.CornerRadius = UDim.new(0, 6)
resetAnimationCorner.Parent = resetAnimationButton

applyAnimationButton.MouseButton1Click:Connect(function()
    applyAnimations()
end)

resetAnimationButton.MouseButton1Click:Connect(function()
    previewingAnimations = false
    previewAnimationButton.Text = "Preview"
    previewAnimationButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

    for key in pairs(selectedAnimations) do
        selectedAnimations[key] = "None"
    end

    for name, data in pairs(animationRows) do
        data.button.Text = "None  ▲"
        data.list.Visible = false
    end

    restoreOriginalAnimations()
    restartAnimations()
end)

--// Avatar reset controls
function resetAppearanceOnly()
    if accessoriesRemoved then
        setAccessoriesRemoved(false)
        updateAccessoriesButton()
    end

    if headlessEnabled then
        setHeadless(false)
        updateHeadlessButton()
    end
end

resetAppearanceButton = Instance.new("TextButton")
resetAppearanceButton.Name = "ResetAppearance"
resetAppearanceButton.Size = UDim2.new(0, 125, 0, 26)
resetAppearanceButton.Position = UDim2.new(0, 15, 0, 385)
resetAppearanceButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
resetAppearanceButton.BorderSizePixel = 0
resetAppearanceButton.Text = "Reset Appearance"
resetAppearanceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetAppearanceButton.TextSize = 10
resetAppearanceButton.Font = Enum.Font.Gotham
resetAppearanceButton.AutoButtonColor = false
resetAppearanceButton.Parent = avatarPage
Instance.new("UICorner", resetAppearanceButton).CornerRadius = UDim.new(0, 6)

resetAppearanceButton.MouseEnter:Connect(function()
    resetAppearanceButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
end)
resetAppearanceButton.MouseLeave:Connect(function()
    resetAppearanceButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
end)
resetAppearanceButton.MouseButton1Click:Connect(function()
    resetAppearanceOnly()
end)

resetAvatarButton = Instance.new("TextButton")
resetAvatarButton.Name = "ResetAvatar"
resetAvatarButton.Size = UDim2.new(0, 125, 0, 26)
resetAvatarButton.Position = UDim2.new(0, 150, 0, 385)
resetAvatarButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
resetAvatarButton.BorderSizePixel = 0
resetAvatarButton.Text = "Reset Avatar"
resetAvatarButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetAvatarButton.TextSize = 10
resetAvatarButton.Font = Enum.Font.Gotham
resetAvatarButton.AutoButtonColor = false
resetAvatarButton.Parent = avatarPage
Instance.new("UICorner", resetAvatarButton).CornerRadius = UDim.new(0, 6)

resetAvatarButton.MouseEnter:Connect(function()
    resetAvatarButton.BackgroundColor3 = Color3.fromRGB(205, 220, 170)
end)
resetAvatarButton.MouseLeave:Connect(function()
    resetAvatarButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
end)
resetAvatarButton.MouseButton1Click:Connect(function()
    resetAppearanceOnly()

    previewingAnimations = false
    previewAnimationButton.Text = "Preview"
    previewAnimationButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

    for key in pairs(selectedAnimations) do
        selectedAnimations[key] = "None"
    end

    for name, data in pairs(animationRows) do
        data.button.Text = "None  ▲"
        data.list.Visible = false
    end

    restoreOriginalAnimations()
    restartAnimations()
end)

if me.Character then
    task.defer(function()
        saveOriginalAnimations()
    end)
end

me.CharacterAdded:Connect(function(character)
    task.wait(1)

    originalAnimationsSaved = false
    table.clear(originalAnimations)

    saveOriginalAnimations()

    if accessoriesRemoved then
        setAccessoriesRemoved(true)
        updateAccessoriesButton()
    end

    if headlessEnabled then
        character:WaitForChild("Head", 10)
        task.wait(0.15)
        setHeadless(true)
        updateHeadlessButton()

        task.delay(1, function()
            if me.Character == character and headlessEnabled then
                applyHeadlessToCharacter(character)
            end
        end)
    end

    local hasCustomAnimation = false

    for _, value in pairs(selectedAnimations) do
        if value ~= "None" then
            hasCustomAnimation = true
            break
        end
    end

    if hasCustomAnimation then
        task.wait(0.25)
        applyAnimations()
    end
end)

updateAccessoriesButton()
updateHeadlessButton()

--// Whitelist - Live Player List + Search + Profiles*
whitelistSearch = Instance.new("TextBox")
whitelistSearch.Name = "SearchUser"
whitelistSearch.Size = UDim2.new(1, -30, 0, 34)
whitelistSearch.Position = UDim2.new(0, 15, 0, 36)
whitelistSearch.BackgroundColor3 = activeThemeButton
whitelistSearch.BorderSizePixel = 0
whitelistSearch.ClearTextOnFocus = false
whitelistSearch.PlaceholderText = "Search user..."
whitelistSearch.Text = ""
whitelistSearch.TextColor3 = Color3.fromRGB(255, 255, 255)
whitelistSearch.PlaceholderColor3 = Color3.fromRGB(0, 0, 0)
whitelistSearch.TextSize = 12
whitelistSearch.Font = Enum.Font.Gotham
whitelistSearch.TextXAlignment = Enum.TextXAlignment.Left
whitelistSearch.Parent = tabs.Whitelist
Instance.new("UICorner", whitelistSearch).CornerRadius = UDim.new(0, 6)
whitelistSearchPadding = Instance.new("UIPadding")
whitelistSearchPadding.PaddingLeft = UDim.new(0, 12)
whitelistSearchPadding.Parent = whitelistSearch
whitelistSearchStroke = Instance.new("UIStroke")
whitelistSearchStroke.Color = activeThemeAccent
whitelistSearchStroke.Transparency = 0.45
whitelistSearchStroke.Parent = whitelistSearch

whitelistRefresh = Instance.new("TextButton")
whitelistRefresh.Name = "RefreshList"
whitelistRefresh.Size = UDim2.new(0.5, -23, 0, 32)
whitelistRefresh.Position = UDim2.new(0, 15, 0, 76)
whitelistRefresh.BackgroundColor3 = activeThemeButton
whitelistRefresh.BorderSizePixel = 0
whitelistRefresh.Text = "Refresh List"
whitelistRefresh.TextColor3 = Color3.fromRGB(255, 255, 255)
whitelistRefresh.TextSize = 11
whitelistRefresh.Font = Enum.Font.Gotham
whitelistRefresh.AutoButtonColor = false
whitelistRefresh.Parent = tabs.Whitelist
Instance.new("UICorner", whitelistRefresh).CornerRadius = UDim.new(0, 6)
whitelistRefreshStroke = Instance.new("UIStroke")
whitelistRefreshStroke.Color = activeThemeAccent
whitelistRefreshStroke.Transparency = 0.45
whitelistRefreshStroke.Parent = whitelistRefresh

whitelistScan = Instance.new("TextButton")
whitelistScan.Name = "ScanUsers"
whitelistScan.Size = UDim2.new(0.5, -23, 0, 32)
whitelistScan.Position = UDim2.new(0.5, 8, 0, 86)
whitelistScan.BackgroundColor3 = activeThemeButton
whitelistScan.BorderSizePixel = 0
whitelistScan.Text = "Scan Users"
whitelistScan.TextColor3 = Color3.fromRGB(255, 255, 255)
whitelistScan.TextSize = 11
whitelistScan.Font = Enum.Font.Gotham
whitelistScan.AutoButtonColor = false
whitelistScan.Parent = tabs.Whitelist
Instance.new("UICorner", whitelistScan).CornerRadius = UDim.new(0, 6)
whitelistScanStroke = Instance.new("UIStroke")
whitelistScanStroke.Color = activeThemeAccent
whitelistScanStroke.Transparency = 0.45
whitelistScanStroke.Parent = whitelistScan

whitelistList = Instance.new("ScrollingFrame")
whitelistList.Name = "LivePlayerList"
whitelistList.Size = UDim2.new(1, -30, 1, -133)
whitelistList.Position = UDim2.new(0, 15, 0, 108)
whitelistList.BackgroundColor3 = activeThemeSoft
whitelistList.BorderSizePixel = 0
whitelistList.CanvasSize = UDim2.new(0, 0, 0, 0)
whitelistList.AutomaticCanvasSize = Enum.AutomaticSize.Y
whitelistList.ScrollingDirection = Enum.ScrollingDirection.Y
whitelistList.ScrollBarThickness = 4
whitelistList.ScrollBarImageColor3 = activeThemeAccent
whitelistList.ClipsDescendants = true
whitelistList.Parent = tabs.Whitelist
Instance.new("UICorner", whitelistList).CornerRadius = UDim.new(0, 6)

whitelistLayout = Instance.new("UIListLayout")
whitelistLayout.Padding = UDim.new(0, 6)
whitelistLayout.SortOrder = Enum.SortOrder.LayoutOrder
whitelistLayout.Parent = whitelistList

whitelistPadding = Instance.new("UIPadding")
whitelistPadding.PaddingTop = UDim.new(0, 8)
whitelistPadding.PaddingBottom = UDim.new(0, 8)
whitelistPadding.PaddingLeft = UDim.new(0, 8)
whitelistPadding.PaddingRight = UDim.new(0, 8)
whitelistPadding.Parent = whitelistList

whitelistRows = {}

spectatingPlayer = nil
originalCameraSubject = nil

function stopWhitelistSpectate()
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = me.Character and me.Character:FindFirstChildWhichIsA("Humanoid") or nil
        if not camera.CameraSubject and me.Character then
            camera.CameraSubject = me.Character:FindFirstChildWhichIsA("Humanoid")
        end
    end
    spectatingPlayer = nil
end

function toggleWhitelistSpectate(player, eyeButton)
    if not player or not player.Character then return end
    local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
    local camera = workspace.CurrentCamera
    if not humanoid or not camera then return end

    if spectatingPlayer == player then
        stopWhitelistSpectate()
        if eyeButton then eyeButton.Text = "👁" end
        return
    end

    if not originalCameraSubject then
        originalCameraSubject = camera.CameraSubject
    end
    spectatingPlayer = player
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    if eyeButton then eyeButton.Text = "👁" end
end

function refreshWhitelistRow(player)
    local row = whitelistRows[player.UserId]
    if not row then
        return
    end

    local button = row:FindFirstChild("WhitelistButton")
    if button then
        button.Text = whitelist[player.UserId] and "ON" or "OFF"
        button.BackgroundColor3 = whitelist[player.UserId]
            and activeThemeAccent
            or activeThemeButton
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

function updateWhitelistSearch()
    local query = string.lower(whitelistSearch.Text or "")

    for userId, row in pairs(whitelistRows) do
        local player = plrs:GetPlayerByUserId(userId)
        if player then
            local displayName = string.lower(player.DisplayName or "")
            local username = string.lower(player.Name or "")
            row.Visible = query == ""
                or string.find(displayName, query, 1, true) ~= nil
                or string.find(username, query, 1, true) ~= nil
        else
            row.Visible = false
        end
    end
end

function removeWhitelistRow(player)
    local row = whitelistRows[player.UserId]
    if row then
        row:Destroy()
        whitelistRows[player.UserId] = nil
    end
end

function teleportToWhitelistPlayer(player)
    if not player or player == me then return end
    local targetCharacter = player.Character
    local myCharacter = me.Character
    if not targetCharacter or not myCharacter then return end
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not myRoot then return end
    pcall(function()
        myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
    end)
end

function addWhitelistRow(player)
    if player == me or whitelistRows[player.UserId] then
        return
    end

    local row = Instance.new("Frame")
    row.Name = "Player_" .. tostring(player.UserId)
    row.Size = UDim2.new(1, 0, 0, 64)
    row.BackgroundColor3 = activeThemeButton
    row.BorderSizePixel = 0
    row.LayoutOrder = player.UserId
    row.Parent = whitelistList
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = activeThemeAccent
    rowStroke.Transparency = 0.65
    rowStroke.Parent = row

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Profile"
    avatar.Size = UDim2.new(0, 48, 0, 48)
    avatar.Position = UDim2.new(0, 8, 0.5, -24)
    avatar.BackgroundColor3 = activeThemeSoft
    avatar.BorderSizePixel = 0
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Parent = row
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 6)

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = activeThemeAccent
    avatarStroke.Transparency = 0.35
    avatarStroke.Parent = avatar

    task.spawn(function()
        local ok, image = pcall(function()
            return plrs:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and avatar.Parent then
            avatar.Image = image
        end
    end)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "DisplayName"
    nameLabel.Size = UDim2.new(1, -250, 0, 22)
    nameLabel.Position = UDim2.new(0, 68, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(58, 68, 46)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = row

    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "Username"
    usernameLabel.Size = UDim2.new(1, -250, 0, 18)
    usernameLabel.Position = UDim2.new(0, 68, 0, 32)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = "@" .. player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(58, 68, 46)
    usernameLabel.TextSize = 10
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    usernameLabel.Parent = row

    local eyeButton = Instance.new("TextButton")
    eyeButton.Name = "SpyButton"
    eyeButton.Size = UDim2.new(0, 28, 0, 26)
    eyeButton.Position = UDim2.new(1, -158, 0.5, -13)
    eyeButton.BackgroundColor3 = activeThemeButton
    eyeButton.BorderSizePixel = 0
    eyeButton.Text = "👁"
    eyeButton.TextColor3 = Color3.fromRGB(58, 68, 46)
    eyeButton.Font = Enum.Font.Gotham
    eyeButton.TextSize = 16
    eyeButton.AutoButtonColor = false
    eyeButton.Parent = row
    Instance.new("UICorner", eyeButton).CornerRadius = UDim.new(0, 6)
    local eyeStroke = Instance.new("UIStroke")
    eyeStroke.Color = activeThemeAccent
    eyeStroke.Transparency = 0.35
    eyeStroke.Parent = eyeButton

    eyeButton.MouseButton1Click:Connect(function()
        toggleWhitelistSpectate(player, eyeButton)
    end)

    local button = Instance.new("TextButton")
    button.Name = "WhitelistButton"
    button.Size = UDim2.new(0, 52, 0, 26)
    button.Position = UDim2.new(1, -122, 0.5, -13)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = row
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    button.MouseButton1Click:Connect(function()
        whitelist[player.UserId] = not whitelist[player.UserId]
        refreshWhitelistRow(player)
    end)

    local tpButton = Instance.new("TextButton")
    tpButton.Name = "TeleportButton"
    tpButton.Size = UDim2.new(0, 52, 0, 26)
    tpButton.Position = UDim2.new(1, -64, 0.5, -13)
    tpButton.BackgroundColor3 = activeThemeButton
    tpButton.BorderSizePixel = 0
    tpButton.Text = "TP"
    tpButton.TextColor3 = Color3.fromRGB(58, 68, 46)
    tpButton.Font = Enum.Font.Gotham
    tpButton.TextSize = 10
    tpButton.AutoButtonColor = false
    tpButton.Parent = row
    Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 6)
    local tpStroke = Instance.new("UIStroke")
    tpStroke.Color = activeThemeAccent
    tpStroke.Transparency = 0.35
    tpStroke.Parent = tpButton
    tpButton.MouseButton1Click:Connect(function()
        teleportToWhitelistPlayer(player)
    end)
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UIS:GetMouseLocation()
            local buttonPos = button.AbsolutePosition
            local buttonSize = button.AbsoluteSize
            local insideButton = mousePos.X >= buttonPos.X and mousePos.X <= buttonPos.X + buttonSize.X and mousePos.Y >= buttonPos.Y and mousePos.Y <= buttonPos.Y + buttonSize.Y
            local eyePos = eyeButton.AbsolutePosition
            local eyeSize = eyeButton.AbsoluteSize
            local insideEye = mousePos.X >= eyePos.X and mousePos.X <= eyePos.X + eyeSize.X and mousePos.Y >= eyePos.Y and mousePos.Y <= eyePos.Y + eyeSize.Y
            local tpPos = tpButton.AbsolutePosition
            local tpSize = tpButton.AbsoluteSize
            local insideTP = mousePos.X >= tpPos.X and mousePos.X <= tpPos.X + tpSize.X and mousePos.Y >= tpPos.Y and mousePos.Y <= tpPos.Y + tpSize.Y
            if not insideButton and not insideEye and not insideTP then showPlayerInfo(player) end
        end
    end)

    whitelistRows[player.UserId] = row
    refreshWhitelistRow(player)
end

function showPlayerInfo(player)
    if not player then return end
    if whitelistInfoCard then whitelistInfoCard:Destroy() end
    whitelistInfoCard = Instance.new("Frame")
    whitelistInfoCard.Size = UDim2.new(0, 300, 0, 150)
    whitelistInfoCard.Position = UDim2.new(0.5, -150, 0.5, -75)
    whitelistInfoCard.BackgroundColor3 = activeThemeButton
    whitelistInfoCard.BorderSizePixel = 0
    whitelistInfoCard.ZIndex = 100
    whitelistInfoCard.Parent = gui
    Instance.new("UICorner", whitelistInfoCard).CornerRadius = UDim.new(0, 6)
    whitelistInfoStroke = Instance.new("UIStroke")
    whitelistInfoStroke.Color = activeThemeAccent
    whitelistInfoStroke.Parent = whitelistInfoCard
    whitelistInfoImage = Instance.new("ImageLabel")
    whitelistInfoImage.Size = UDim2.new(0, 70, 0, 70)
    whitelistInfoImage.Position = UDim2.new(0, 15, 0, 15)
    whitelistInfoImage.BackgroundColor3 = activeThemeSoft
    whitelistInfoImage.BorderSizePixel = 0
    whitelistInfoImage.ZIndex = 101
    whitelistInfoImage.Parent = whitelistInfoCard
    Instance.new("UICorner", whitelistInfoImage).CornerRadius = UDim.new(0, 6)
    pcall(function()
        whitelistInfoImage.Image = plrs:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    whitelistInfoName = Instance.new("TextLabel")
    whitelistInfoName.Size = UDim2.new(1, -105, 0, 24)
    whitelistInfoName.Position = UDim2.new(0, 95, 0, 20)
    whitelistInfoName.BackgroundTransparency = 1
    whitelistInfoName.Text = player.DisplayName
    whitelistInfoName.TextColor3 = Color3.fromRGB(58, 68, 46)
    whitelistInfoName.Font = Enum.Font.Gotham
    whitelistInfoName.TextSize = 14
    whitelistInfoName.TextXAlignment = Enum.TextXAlignment.Left
    whitelistInfoName.ZIndex = 101
    whitelistInfoName.Parent = whitelistInfoCard
    whitelistInfoUser = whitelistInfoName:Clone()
    whitelistInfoUser.Text = "@" .. player.Name
    whitelistInfoUser.Position = UDim2.new(0, 95, 0, 48)
    whitelistInfoUser.TextColor3 = Color3.fromRGB(92, 103, 76)
    whitelistInfoUser.Font = Enum.Font.Gotham
    whitelistInfoUser.TextSize = 11
    whitelistInfoUser.Parent = whitelistInfoCard
    whitelistInfoStatus = whitelistInfoName:Clone()
    whitelistInfoStatus.Text = whitelist[player.UserId] and "Whitelisted" or "Not whitelisted"
    whitelistInfoStatus.Position = UDim2.new(0, 95, 0, 72)
    whitelistInfoStatus.TextColor3 = Color3.fromRGB(58, 68, 46)
    whitelistInfoStatus.Font = Enum.Font.Gotham
    whitelistInfoStatus.TextSize = 11
    whitelistInfoStatus.Parent = whitelistInfoCard
    whitelistInfoClose = Instance.new("TextButton")
    whitelistInfoClose.Size = UDim2.new(0, 80, 0, 26)
    whitelistInfoClose.Position = UDim2.new(1, -95, 1, -38)
    whitelistInfoClose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    whitelistInfoClose.Text = "Close"
    whitelistInfoClose.TextColor3 = Color3.fromRGB(58, 68, 46)
    whitelistInfoClose.Font = Enum.Font.Gotham
    whitelistInfoClose.TextSize = 11
    whitelistInfoClose.ZIndex = 101
    whitelistInfoClose.Parent = whitelistInfoCard
    Instance.new("UICorner", whitelistInfoClose).CornerRadius = UDim.new(0, 6)
    whitelistInfoClose.MouseButton1Click:Connect(function() whitelistInfoCard:Destroy() end)
end

function rebuildWhitelistList()
    for _, player in ipairs(plrs:GetPlayers()) do
        if player ~= me then
            addWhitelistRow(player)
        end
    end

    for userId, row in pairs(whitelistRows) do
        local stillHere = false
        for _, player in ipairs(plrs:GetPlayers()) do
            if player.UserId == userId then
                stillHere = true
                break
            end
        end
        if not stillHere then
            row:Destroy()
            whitelistRows[userId] = nil
            whitelist[userId] = nil
        end
    end

    updateWhitelistSearch()
end

whitelistSearch:GetPropertyChangedSignal("Text"):Connect(updateWhitelistSearch)
whitelistRefresh.MouseButton1Click:Connect(rebuildWhitelistList)
whitelistScan.MouseButton1Click:Connect(rebuildWhitelistList)

rebuildWhitelistList()
plrs.PlayerAdded:Connect(function(player)
    if player ~= me then
        addWhitelistRow(player)
        updateWhitelistSearch()
    end
end)

plrs.PlayerRemoving:Connect(function(player)
    whitelist[player.UserId] = nil
    removeWhitelistRow(player)
end)

--// Teleport*
tpLabel = Instance.new("TextLabel")
tpLabel.Size = UDim2.new(1, -30, 0, 30)
tpLabel.Position = UDim2.new(0, 15, 0, 35)
tpLabel.Text = "Target Player Name:"
tpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tpLabel.TextSize = 13
tpLabel.Font = Enum.Font.Gotham
tpLabel.BackgroundTransparency = 1
tpLabel.TextXAlignment = Enum.TextXAlignment.Left
tpLabel.Parent = tabs.Teleport
tpInput = Instance.new("TextBox")
tpInput.Size = UDim2.new(1, -30, 0, 32)
tpInput.Position = UDim2.new(0, 15, 0, 70)
tpInput.BackgroundColor3 = Color3.fromRGB(246, 240, 252)
tpInput.Text = ""
tpInput.PlaceholderText = "Enter User Name"
tpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
tpInput.PlaceholderColor3 = Color3.fromRGB(0, 0, 0)
tpInput.Font = Enum.Font.Gotham
tpInput.TextSize = 12
tpInput.Parent = tabs.Teleport
Instance.new("UICorner", tpInput).CornerRadius = UDim.new(0, 6)
tpStroke = Instance.new("UIStroke")
tpStroke.Color = Color3.fromRGB(166, 184, 124)
tpStroke.Transparency = 0.45
tpStroke.Parent = tpInput
tpActionBtn = Instance.new("TextButton")
tpActionBtn.Size = UDim2.new(0, 120, 0, 30)
tpActionBtn.Position = UDim2.new(0, 15, 0, 95)
tpActionBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
tpActionBtn.Text = "Teleport "
tpActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpActionBtn.Font = Enum.Font.Gotham
tpActionBtn.TextSize = 13
tpActionBtn.AutoButtonColor = false
tpActionBtn.Parent = tabs.Teleport
Instance.new("UICorner", tpActionBtn).CornerRadius = UDim.new(0, 6)
moveConnection1 = nil
function updateSlider1(input)
    local percentage = math.clamp(
        (input.Position.X - slider.AbsolutePosition.X)
        / slider.AbsoluteSize.X,
        0,
        1
    )
    button.Position =
        UDim2.new(percentage, -7, 0.5, -7)
    local finalValue = math.round(percentage * 1000)
    valueLabel.Text = "FOV Radius: " .. tostring(finalValue)
    _G.FOV_RADIUS = finalValue
end
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        moveConnection1 = UIS.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement
                or moveInput.UserInputType == Enum.UserInputType.Touch then
                updateSlider1(moveInput)
            end
        end)
    end
end)
moveConnection2 = nil
function updateSlider2(input)
    local percentage = math.clamp(
        (input.Position.X - spreadSlider.AbsolutePosition.X)
        / spreadSlider.AbsoluteSize.X,
        0,
        1
    )
    spreadBtn.Position =
        UDim2.new(percentage, -7, 0.5, -7)
    local finalValue = math.round(percentage * 100)
    spreadLabel.Text =
        "Bullet Spread: " .. tostring(finalValue)
    _0x52a0d5.BulletSpread.Amount = finalValue
end
spreadBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        moveConnection2 = UIS.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement
                or moveInput.UserInputType == Enum.UserInputType.Touch then
                updateSlider2(moveInput)
            end
        end)
    end
end)
moveConnection4 = nil
function updateSpeedSlider(input)
    local percentage = math.clamp(
        (input.Position.X - speedSlider.AbsolutePosition.X)
        / speedSlider.AbsoluteSize.X,
        0,
        1
    )
    speedSliderBtn.Position =
        UDim2.new(percentage, -7, 0.5, -7)
    local finalValue =
        math.round(50 + (percentage * 950))
    speedValLabel.Text =
        "Speed Value: " .. tostring(finalValue)
    _G.Speed_Value = finalValue
end
speedSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        moveConnection4 = UIS.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement
                or moveInput.UserInputType == Enum.UserInputType.Touch then
                updateSpeedSlider(moveInput)
            end
        end)
    end
end)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if input.KeyCode == _G.Speed_Key
        and not isBinding
        and _G.Speed_ToggleEnabled then
        _G.Speed_Enabled = not _G.Speed_Enabled
    end
end)

--// Click Teleport
clickTeleportEnabled = false
clickTeleportLabel, clickTeleportBtn = createToggle(tabs.Teleport, "Click Teleport", 180)

function updateClickTeleportButton()
    clickTeleportBtn.Text = clickTeleportEnabled and "ON" or "OFF"
    clickTeleportBtn.BackgroundColor3 = clickTeleportEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(246, 240, 252)
    clickTeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

clickTeleportBtn.MouseButton1Click:Connect(function()
    clickTeleportEnabled = not clickTeleportEnabled
    updateClickTeleportButton()
end)

updateClickTeleportButton()

tpActionBtn.MouseButton1Click:Connect(function()
    local targetName = tpInput.Text:lower()
    if targetName ~= "" then
        for _, p in pairs(plrs:GetPlayers()) do
            if p ~= me
                and p.Name:lower():sub(1, #targetName) == targetName
                and p.Character
                and p.Character:FindFirstChild("HumanoidRootPart") then
                if me.Character
                    and me.Character:FindFirstChild("HumanoidRootPart") then
                    me.Character.HumanoidRootPart.CFrame =
                        p.Character.HumanoidRootPart.CFrame
                        * CFrame.new(0, 0, 3)
                end
                break
            end
        end
    end
end)

mouse.Button1Down:Connect(function()
    if not clickTeleportEnabled then
        return
    end

    local character = me.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local hit = mouse.Hit
    if hit then
        root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
    end
end)
--==================================================*
-- CAM LOCK - MAIN GUI*
--==================================================*
RunService = game:GetService("RunService")
camLockEnabled = false
camLockFOV = 150
camLockSmoothness = 0.18
camLockKey = Enum.KeyCode.C
changingCamKeybind = false
-- Sticky target: once C acquires a target, CamLock never retargets while enabled.
lockedTarget = nil
-- Cam Lock toggle*
camToggleLabel, camToggleBtn =
    createToggle(tabs.CamLock, "Cam Lock", 55)
function updateCamLockButton()
    camToggleBtn.Text = camLockEnabled and "ON" or "OFF"
    camToggleBtn.BackgroundColor3 =
        camLockEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end
camToggleBtn.MouseButton1Click:Connect(function()
    camLockEnabled = not camLockEnabled
    if not camLockEnabled then
        lockedTarget = nil
    else
        lockedTarget = getClosestCharacter()
    end
    updateCamLockButton()
end)
-- Keybind*
camKeyLabel = Instance.new("TextLabel")
camKeyLabel.Size = UDim2.new(0, 150, 0, 30)
camKeyLabel.Position = UDim2.new(0, 15, 0, 75)
camKeyLabel.BackgroundTransparency = 1
camKeyLabel.Text = "Keybind"
camKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
camKeyLabel.TextSize = 13
camKeyLabel.Font = Enum.Font.Gotham
camKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
camKeyLabel.Parent = tabs.CamLock
camKeyButton = Instance.new("TextButton")
camKeyButton.Size = UDim2.new(0, 100, 0, 26)
camKeyButton.Position = UDim2.new(1, -115, 0, 97)
camKeyButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
camKeyButton.BorderSizePixel = 0
camKeyButton.Text = "Key: " .. camLockKey.Name
camKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
camKeyButton.TextSize = 11
camKeyButton.Font = Enum.Font.Gotham
camKeyButton.AutoButtonColor = false
camKeyButton.Parent = tabs.CamLock
Instance.new("UICorner", camKeyButton).CornerRadius = UDim.new(0, 6)
camKeyButton.MouseButton1Click:Connect(function()
    if changingCamKeybind then
        return
    end
    changingCamKeybind = true
    camKeyButton.Text = "Press key"
end)
-- Smoothness label*
camSmoothLabel = Instance.new("TextLabel")
camSmoothLabel.Size = UDim2.new(1, -30, 0, 20)
camSmoothLabel.Position = UDim2.new(0, 15, 0, 125)
camSmoothLabel.BackgroundTransparency = 1
camSmoothLabel.Text =
    "Smoothness: " ..
    string.format("%.2f", camLockSmoothness)
camSmoothLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
camSmoothLabel.TextSize = 13
camSmoothLabel.Font = Enum.Font.Gotham
camSmoothLabel.TextXAlignment = Enum.TextXAlignment.Left
camSmoothLabel.Parent = tabs.CamLock
-- Smoothness slider*
camSmoothSlider = Instance.new("Frame")
camSmoothSlider.Size = UDim2.new(1, -30, 0, 6)
camSmoothSlider.Position = UDim2.new(0, 15, 0, 155)
camSmoothSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
camSmoothSlider.BorderSizePixel = 0
camSmoothSlider.Parent = tabs.CamLock
Instance.new("UICorner", camSmoothSlider).CornerRadius =
    UDim.new(0, 0)
camSmoothButton = Instance.new("TextButton")
camSmoothButton.Size = UDim2.new(0, 14, 0, 14)
camSmoothButton.Position =
    UDim2.new(camLockSmoothness, -7, 0.5, -7)
camSmoothButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
camSmoothButton.BorderSizePixel = 0
camSmoothButton.Text = ""
camSmoothButton.AutoButtonColor = false
camSmoothButton.Parent = camSmoothSlider
Instance.new("UICorner", camSmoothButton).CornerRadius =
    UDim.new(0, 0)

camSmoothDragging = false
function updateCamSmoothness(input)
    local width = camSmoothSlider.AbsoluteSize.X
    if width <= 0 then
        return
    end
    local percentage = math.clamp(
        (input.Position.X - camSmoothSlider.AbsolutePosition.X)
        / width,
        0,
        1
    )
    camLockSmoothness =
        math.floor(percentage * 100) / 100
    camSmoothLabel.Text =
        "Smoothness: " ..
        string.format("%.2f", camLockSmoothness)
    camSmoothButton.Position =
        UDim2.new(percentage, -7, 0.5, -7)
end

camSmoothButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        camSmoothDragging = true
    end
end)

camSmoothSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        camSmoothDragging = true
        updateCamSmoothness(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        if camSmoothDragging then
            updateCamSmoothness(input)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        camSmoothDragging = false
    end
end)
-- Keybind handling*
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if changingCamKeybind then
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode ~= Enum.KeyCode.Unknown then
            camLockKey = input.KeyCode
            changingCamKeybind = false
            camKeyButton.Text =
                "Key: " .. camLockKey.Name
        end
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == camLockKey then
        camLockEnabled = not camLockEnabled
        if camLockEnabled then
            lockedTarget = getClosestCharacter()
            if not lockedTarget then
                camLockEnabled = false
                camLockStatus.Text = "Target: none"
            end
        else
            lockedTarget = nil
            camLockStatus.Text = "Target: none"
        end
        updateCamLockButton()
    end
end)
-- Find closest target only when a new lock is requested.
function getClosestCharacter()
    local mousePosition = UIS:GetMouseLocation()
    local closestCharacter = nil
    local closestDistance = camLockFOV

    for _, target in ipairs(plrs:GetPlayers()) do
        if target ~= me and not whitelist[target.UserId] then
            local character = target.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local head = character and character:FindFirstChild("Head")

            if humanoid and head and humanoid.Health > 0
                and isValidSilentAimTarget(target) then
                local screenPosition, visible = cam:WorldToViewportPoint(head.Position)
                if visible then
                    local distance = (
                        Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition
                    ).Magnitude
                    if distance <= camLockFOV and distance < closestDistance then
                        closestDistance = distance
                        closestCharacter = character
                    end
                end
            end
        end
    end

    return closestCharacter
end

camLockStatus = Instance.new("TextLabel")
camLockStatus.Size = UDim2.new(1, -30, 0, 22)
camLockStatus.Position = UDim2.new(0, 15, 0, 262)
camLockStatus.BackgroundTransparency = 1
camLockStatus.Text = "Target: none"
camLockStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
camLockStatus.TextSize = 12
camLockStatus.Font = Enum.Font.Gotham
camLockStatus.TextXAlignment = Enum.TextXAlignment.Left
camLockStatus.Parent = tabs.CamLock

camUnlockButton = Instance.new("TextButton")
camUnlockButton.Size = UDim2.new(0, 100, 0, 26)
camUnlockButton.Position = UDim2.new(1, -115, 0, 280)
camUnlockButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
camUnlockButton.BorderSizePixel = 0
camUnlockButton.Text = "Unlock Target"
camUnlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
camUnlockButton.TextSize = 11
camUnlockButton.Font = Enum.Font.Gotham
camUnlockButton.AutoButtonColor = false
camUnlockButton.Parent = tabs.CamLock
Instance.new("UICorner", camUnlockButton).CornerRadius = UDim.new(0, 6)

function clearCamLockTarget()
    lockedTarget = nil
    camLockStatus.Text = "Target: none"
end

camUnlockButton.MouseButton1Click:Connect(function()
    clearCamLockTarget()
    camLockEnabled = false
    updateCamLockButton()
end)

-- Camera lock. The target is acquired once and deliberately NOT searched again
-- every frame, so another player crossing the FOV cannot steal the lock.
RunService.RenderStepped:Connect(function()
    if camLockEnabled then
        if not lockedTarget or not lockedTarget.Parent then
            clearCamLockTarget()
            camLockEnabled = false
            updateCamLockButton()
            return
        end

        local targetPlayer = plrs:GetPlayerFromCharacter(lockedTarget)
        if not targetPlayer or not isValidSilentAimTarget(targetPlayer) then
            clearCamLockTarget()
            camLockEnabled = false
            updateCamLockButton()
            return
        end

        local head = lockedTarget:FindFirstChild("Head")
        if not head then
            clearCamLockTarget()
            camLockEnabled = false
            updateCamLockButton()
            return
        end

        camLockStatus.Text = "Target: " .. targetPlayer.Name
        local cameraPosition = cam.CFrame.Position
        local targetCFrame = CFrame.lookAt(cameraPosition, head.Position)
        cam.CFrame = cam.CFrame:Lerp(
            targetCFrame,
            math.clamp(camLockSmoothness, 0.01, 1)
        )
    else
        if lockedTarget then
            camLockStatus.Text = "Target: none"
        end
    end
end)
updateCamLockButton()

--// ESP*
function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false
    local name = Drawing.new("Text")
    name.Visible = false
    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Thickness = 1.5
    local skeletonLines = {}
    local skeletonConnections = {
        {"Head", "UpperTorso"}, {"Head", "Torso"},
        {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}, {"Torso", "Left Arm"},
        {"Left Arm", "Left Leg"}, {"Torso", "Right Arm"},
        {"Right Arm", "Right Leg"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
    for _ = 1, #skeletonConnections do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.2
        table.insert(skeletonLines, line)
    end
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Font = Drawing.Fonts.UI
    local conn = nil
    conn = game:GetService("RunService").RenderStepped:Connect(function()
        if player
            and not whitelist[player.UserId]
            and player.Character
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0 then
            local rootPart = player.Character.HumanoidRootPart
            local head =
                player.Character:FindFirstChild("Head")
                or rootPart
            local rootPos, rootOnScreen =
                cam:WorldToViewportPoint(rootPart.Position)
            if rootOnScreen then
                local headPos =
                    cam:WorldToViewportPoint(
                        head.Position + Vector3.new(0, 0.5, 0)
                    )
                local legPos =
                    cam:WorldToViewportPoint(
                        rootPart.Position - Vector3.new(0, 3, 0)
                    )
                local boxHeight =
                    math.abs(headPos.Y - legPos.Y)
                local boxWidth = boxHeight / 2
                if _G.ESP_Boxes then
                    box.Size =
                        Vector2.new(boxWidth, boxHeight)
                    box.Position =
                        Vector2.new(
                            rootPos.X - boxWidth / 2,
                            rootPos.Y - boxHeight / 2
                        )
                    box.Color = _G.ESP_Color
                    box.Visible = true
                else
                    box.Visible = false
                end
                if _G.ESP_Names then
                    name.Position =
                        Vector2.new(
                            rootPos.X,
                            rootPos.Y - boxHeight / 2 - 18
                        )
                    name.Text = player.Name
                    name.Color = _G.ESP_Color
                    name.Visible = true
                else
                    name.Visible = false
                end
                if _G.ESP_Distance then
                    local myRoot = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
                    local distance = myRoot and (myRoot.Position - rootPart.Position).Magnitude or 0
                    distanceText.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 4)
                    distanceText.Text = math.floor(distance) .. " studs"
                    distanceText.Color = _G.ESP_Color
                    distanceText.Size = 13
                    distanceText.Center = true
                    distanceText.Outline = true
                    distanceText.Font = Drawing.Fonts.UI
                    distanceText.Visible = true
                else
                    distanceText.Visible = false
                end
                if _G.ESP_Snaplines then
                    snapline.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    snapline.To = Vector2.new(rootPos.X, rootPos.Y)
                    snapline.Color = _G.ESP_Color
                    snapline.Visible = true
                else
                    snapline.Visible = false
                end
                if _G.ESP_Skeleton then
                    local character = player.Character
                    for index, pair in ipairs(skeletonConnections) do
                        local partA = character:FindFirstChild(pair[1])
                        local partB = character:FindFirstChild(pair[2])
                        local line = skeletonLines[index]
                        if partA and partB then
                            local posA, onA = cam:WorldToViewportPoint(partA.Position)
                            local posB, onB = cam:WorldToViewportPoint(partB.Position)
                            if onA or onB then
                                line.From = Vector2.new(posA.X, posA.Y)
                                line.To = Vector2.new(posB.X, posB.Y)
                                line.Color = _G.ESP_Color
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                else
                    for _, line in ipairs(skeletonLines) do
                        line.Visible = false
                    end
                end
            else
                box.Visible = false
                name.Visible = false
                distanceText.Visible = false
                snapline.Visible = false
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
        else
            box.Visible = false
            name.Visible = false
            distanceText.Visible = false
            snapline.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
            if not player or not player.Parent then
                box:Remove()
                name:Remove()
                distanceText:Remove()
                snapline:Remove()
                for _, line in ipairs(skeletonLines) do
                    line:Remove()
                end
                conn:Disconnect()
            end
        end
    end)
end
for _, p in pairs(plrs:GetPlayers()) do
    if p ~= me then
        createESP(p)
    end
end
plrs.PlayerAdded:Connect(function(p)
    if p ~= me then
        createESP(p)
    end
end)
--// Speed + High Jump*
game:GetService("RunService").Heartbeat:Connect(function()
    if _G.Speed_Enabled
        and me.Character
        and me.Character:FindFirstChild("Humanoid") then
        me.Character.Humanoid.WalkSpeed = _G.Speed_Value
    elseif not _G.Speed_Enabled
        and me.Character
        and me.Character:FindFirstChild("Humanoid") then
        if me.Character.Humanoid.WalkSpeed == _G.Speed_Value then
            me.Character.Humanoid.WalkSpeed = 16
        end
    end
end)

--// Fly movement
-- Uses BodyVelocity/BodyGyro for broad executor/game compatibility.
-- Horizontal movement follows the camera; Space rises and LeftControl descends.
local flyConnection = RunService.RenderStepped:Connect(function()
    local character = me.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera

    if not _G.Fly_Enabled then
        if hrp then
            local velocity = hrp:FindFirstChild("AyeshaFlyVelocity")
            if velocity then velocity:Destroy() end
            local gyro = hrp:FindFirstChild("AyeshaFlyGyro")
            if gyro then gyro:Destroy() end
        end
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        return
    end

    if not humanoid or not hrp or not camera then return end

    local velocity = hrp:FindFirstChild("AyeshaFlyVelocity")
    if not velocity then
        velocity = Instance.new("BodyVelocity")
        velocity.Name = "AyeshaFlyVelocity"
        velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        velocity.P = 12500
        velocity.Velocity = Vector3.zero
        velocity.Parent = hrp
    end

    local gyro = hrp:FindFirstChild("AyeshaFlyGyro")
    if not gyro then
        gyro = Instance.new("BodyGyro")
        gyro.Name = "AyeshaFlyGyro"
        gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        gyro.P = 12500
        gyro.D = 800
        gyro.CFrame = camera.CFrame
        gyro.Parent = hrp
    end

    local look = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector
    local direction = Vector3.zero

    if FlyKeyState.W then direction += look end
    if FlyKeyState.S then direction -= look end
    if FlyKeyState.D then direction += right end
    if FlyKeyState.A then direction -= right end
    if FlyKeyState.Space then direction += Vector3.new(0, 1, 0) end
    if FlyKeyState.LeftControl then direction -= Vector3.new(0, 1, 0) end

    if direction.Magnitude > 0 then
        direction = direction.Unit * math.clamp(tonumber(_G.Fly_Speed) or 50, 10, 500)
    else
        direction = Vector3.zero
    end

    velocity.Velocity = direction
    gyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(look.X, 0, look.Z))
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
end)

--// High Jump*
game:GetService("RunService").Heartbeat:Connect(function()
    if _G.HighJump_Enabled
        and me.Character
        and me.Character:FindFirstChild("Humanoid") then

        local humanoid = me.Character.Humanoid
        if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            humanoid.JumpPower = _G.HighJump_Value
        else
            humanoid.JumpPower = _G.HighJump_Value
        end
    end
end)

--// Right Shift UI toggle*
-- Keep the main UI hidden until the loading screen finishes.
uiVisible = false
frame.Visible = false

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if moveConnection1 then
            moveConnection1:Disconnect()
            moveConnection1 = nil
        end
        if moveConnection2 then
            moveConnection2:Disconnect()
            moveConnection2 = nil
        end
        if moveConnection4 then
            moveConnection4:Disconnect()
            moveConnection4 = nil
        end
    end
end)
--// Cute blue entrance animation*
TweenService = game:GetService("TweenService")
originalSize = frame.Size
frame.Size = UDim2.new(
    originalSize.X.Scale,
    originalSize.X.Offset - 20,
    originalSize.Y.Scale,
    originalSize.Y.Offset - 20
)
TweenService:Create(
    frame,
    TweenInfo.new(
        0.3,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ),
    {
        Size = originalSize
    }
):Play()
--// Fog Toggle + Fog Color + Rainbow + Reset Fog*
Lighting = game:GetService("Lighting")
RunService = game:GetService("RunService")
UIS = game:GetService("UserInputService")

-- Capture the real game fog before Astro.MAIN changes anything.
fogOriginal = {
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

fogEnabled = false
fogThickness = 250
rainbowFog = false
rainbowConnection = nil
-- IMPORTANT: execution must not alter Lighting.  The helper Atmosphere is
-- created only when the user actually enables Ayesha Fog.
fogAtmosphere = Lighting:FindFirstChild("AyeshaFogAtmosphere")
createdFogAtmosphere = false
fogOriginalAtmosphere = nil
if fogAtmosphere then
    fogOriginalAtmosphere = {
        Color = fogAtmosphere.Color,
        Decay = fogAtmosphere.Decay,
        Density = fogAtmosphere.Density,
        Glare = fogAtmosphere.Glare,
        Haze = fogAtmosphere.Haze,
        Offset = fogAtmosphere.Offset,
        Enabled = fogAtmosphere.Enabled
    }
end

function ensureFogAtmosphere()
    if fogAtmosphere and fogAtmosphere.Parent then return fogAtmosphere end
    fogAtmosphere = Instance.new("Atmosphere")
    fogAtmosphere.Name = "AyeshaFogAtmosphere"
    fogAtmosphere.Parent = Lighting
    createdFogAtmosphere = true
    fogOriginalAtmosphere = {
        Color = Color3.new(1,1,1),
        Decay = Color3.new(1,1,1),
        Density = 0, Glare = 0, Haze = 0, Offset = 0, Enabled = false
    }
    return fogAtmosphere
end

function setFogAtmosphere(enabled, color)
    if enabled then
        local atmosphere = ensureFogAtmosphere()
        local c = color or Lighting.FogColor
        local thicknessAmount = math.clamp(1 - ((fogThickness - 50) / 950), 0, 1)
        atmosphere.Color = c
        atmosphere.Decay = c
        atmosphere.Density = 0.08 + (thicknessAmount * 0.72)
        atmosphere.Glare = 0
        atmosphere.Haze = 0.5 + (thicknessAmount * 3.5)
        atmosphere.Offset = 0
        atmosphere.Enabled = true
    elseif fogAtmosphere then
        if fogOriginalAtmosphere then
            fogAtmosphere.Color = fogOriginalAtmosphere.Color
            fogAtmosphere.Decay = fogOriginalAtmosphere.Decay
            fogAtmosphere.Density = fogOriginalAtmosphere.Density
            fogAtmosphere.Glare = fogOriginalAtmosphere.Glare
            fogAtmosphere.Haze = fogOriginalAtmosphere.Haze
            fogAtmosphere.Offset = fogOriginalAtmosphere.Offset
            fogAtmosphere.Enabled = fogOriginalAtmosphere.Enabled or false
        else
            fogAtmosphere.Enabled = false
        end
    end
end

function applyFogColor(color)
    Lighting.FogColor = color
    if fogEnabled then
        Lighting.FogStart = 0
        Lighting.FogEnd = math.max(20, fogThickness)
        setFogAtmosphere(true, color)
    end
end

--// Force Time
forceTimeEnabled = false
forceTimeValue = 12
forceTimeLabel, forceTimeBtn = createToggle(tabs.Visual, "Force Time", 555)
forceTimeBtn.Text = "OFF"
forceTimeBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
forceTimeValueLabel = Instance.new("TextLabel")
forceTimeValueLabel.Name = "AyeshaForceTimeLabel"
forceTimeValueLabel.Size = UDim2.new(1, -30, 0, 20)
forceTimeValueLabel.Position = UDim2.new(0, 15, 0, 585)
forceTimeValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
forceTimeValueLabel.TextSize = 13
forceTimeValueLabel.Font = Enum.Font.Gotham
forceTimeValueLabel.BackgroundTransparency = 1
forceTimeValueLabel.TextXAlignment = Enum.TextXAlignment.Left
forceTimeValueLabel.Parent = tabs.Visual
forceTimeSlider = Instance.new("Frame")
forceTimeSlider.Name = "AyeshaForceTimeSlider"
forceTimeSlider.Size = UDim2.new(1, -30, 0, 6)
forceTimeSlider.Position = UDim2.new(0, 15, 0, 615)
forceTimeSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
forceTimeSlider.BorderSizePixel = 0
forceTimeSlider.Active = true
forceTimeSlider.Parent = tabs.Visual
forceTimeSliderBtn = Instance.new("TextButton")
forceTimeSliderBtn.Size = UDim2.fromOffset(16, 16)
forceTimeSliderBtn.Position = UDim2.new(forceTimeValue / 24, -8, 0.5, -8)
forceTimeSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
forceTimeSliderBtn.BorderSizePixel = 0
forceTimeSliderBtn.Text = ""
forceTimeSliderBtn.AutoButtonColor = false
forceTimeSliderBtn.Parent = forceTimeSlider
function formatForceTime(value)
    local hour = math.floor(value) % 24
    local minute = math.floor((value - math.floor(value)) * 60 + 0.5)
    if minute >= 60 then hour = (hour + 1) % 24 minute = 0 end
    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    if displayHour == 0 then displayHour = 12 end
    return string.format("%02d:%02d %s", displayHour, minute, suffix)
end
function updateForceTimeUI()
    forceTimeValueLabel.Text = "Time: " .. formatForceTime(forceTimeValue)
    forceTimeSliderBtn.Position = UDim2.new((forceTimeValue % 24) / 24, -8, 0.5, -8)
end
function setForceTimeFromX(x)
    local width = forceTimeSlider.AbsoluteSize.X
    if width <= 0 then return end
    local percentage = math.clamp((x - forceTimeSlider.AbsolutePosition.X) / width, 0, 1)
    forceTimeValue = math.clamp(math.round((percentage * 24) * 60) / 60, 0, 24)
    updateForceTimeUI()
    if forceTimeEnabled then Lighting.ClockTime = forceTimeValue % 24 end
end
forceTimeDragging = false
forceTimeSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then forceTimeDragging = true setForceTimeFromX(input.Position.X) end
end)
forceTimeSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then forceTimeDragging = true setForceTimeFromX(input.Position.X) end
end)
UIS.InputChanged:Connect(function(input)
    if forceTimeDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setForceTimeFromX(input.Position.X) end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then forceTimeDragging = false end
end)
forceTimeBtn.MouseButton1Click:Connect(function()
    forceTimeEnabled = not forceTimeEnabled
    forceTimeBtn.Text = forceTimeEnabled and "ON" or "OFF"
    forceTimeBtn.BackgroundColor3 = forceTimeEnabled and Color3.fromRGB(166, 184, 124) or Color3.fromRGB(245, 248, 239)
    if forceTimeEnabled then Lighting.ClockTime = forceTimeValue % 24 end
end)
updateForceTimeUI()

--// Brightness
brightnessEnabled = false
brightnessValue = math.clamp(Lighting.Brightness, 0, 5)

brightnessLabel = Instance.new("TextLabel")
brightnessLabel.Name = "AyeshaBrightnessLabel"
brightnessLabel.Size = UDim2.new(1, -30, 0, 20)
brightnessLabel.Position = UDim2.new(0, 15, 0, 665)
brightnessLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
brightnessLabel.TextSize = 13
brightnessLabel.Font = Enum.Font.Gotham
brightnessLabel.BackgroundTransparency = 1
brightnessLabel.TextXAlignment = Enum.TextXAlignment.Left
brightnessLabel.Parent = tabs.Visual

brightnessToggleLabel, brightnessToggleBtn = createToggle(tabs.Visual, "Brightness Override", 695)
brightnessToggleBtn.Text = "OFF"
brightnessToggleBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

brightnessSlider = Instance.new("Frame")
brightnessSlider.Name = "AyeshaBrightnessSlider"
brightnessSlider.Size = UDim2.new(1, -30, 0, 6)
brightnessSlider.Position = UDim2.new(0, 15, 0, 725)
brightnessSlider.BackgroundColor3 = Color3.fromRGB(220, 226, 208)
brightnessSlider.BorderSizePixel = 0
brightnessSlider.Active = true
brightnessSlider.Parent = tabs.Visual

brightnessSliderFill = Instance.new("Frame")
brightnessSliderFill.Size = UDim2.new(brightnessValue / 5, 0, 1, 0)
brightnessSliderFill.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
brightnessSliderFill.BorderSizePixel = 0
brightnessSliderFill.Parent = brightnessSlider

brightnessSliderBtn = Instance.new("TextButton")
brightnessSliderBtn.Size = UDim2.fromOffset(16, 16)
brightnessSliderBtn.Position = UDim2.new(brightnessValue / 5, -8, 0.5, -8)
brightnessSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
brightnessSliderBtn.BorderSizePixel = 0
brightnessSliderBtn.Text = ""
brightnessSliderBtn.AutoButtonColor = false
brightnessSliderBtn.Parent = brightnessSlider

function updateBrightnessUI()
    brightnessLabel.Text = string.format("Brightness: %.2f", brightnessValue)
    local pct = math.clamp(brightnessValue / 5, 0, 1)
    brightnessSliderFill.Size = UDim2.new(pct, 0, 1, 0)
    brightnessSliderBtn.Position = UDim2.new(pct, -8, 0.5, -8)
end

function setBrightnessFromX(x)
    local width = brightnessSlider.AbsoluteSize.X
    if width <= 0 then return end
    local pct = math.clamp((x - brightnessSlider.AbsolutePosition.X) / width, 0, 1)
    brightnessValue = math.round((pct * 5) * 100) / 100
    updateBrightnessUI()
    if brightnessEnabled then
        Lighting.Brightness = brightnessValue
    end
end

brightnessDragging = false
brightnessSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        brightnessDragging = true
        setBrightnessFromX(input.Position.X)
    end
end)
brightnessSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        brightnessDragging = true
        setBrightnessFromX(input.Position.X)
    end
end)
UIS.InputChanged:Connect(function(input)
    if brightnessDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setBrightnessFromX(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        brightnessDragging = false
    end
end)
brightnessToggleBtn.MouseButton1Click:Connect(function()
    brightnessEnabled = not brightnessEnabled
    brightnessToggleBtn.Text = brightnessEnabled and "ON" or "OFF"
    brightnessToggleBtn.BackgroundColor3 = brightnessEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
    if brightnessEnabled then
        Lighting.Brightness = brightnessValue
    else
        -- Re-apply the current environment so its normal brightness is restored.
        applyEnvironment(currentEnvironment, true)
    end
end)
updateBrightnessUI()

-- Fog toggle
fogLabel, fogBtn = createToggle(tabs.Visual, "Fog", 55)
fogBtn.Text = "OFF"
fogBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
fogBtn.MouseButton1Click:Connect(function()
    fogEnabled = not fogEnabled
    fogBtn.Text = fogEnabled and "ON" or "OFF"
    fogBtn.BackgroundColor3 = fogEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)

    if fogEnabled then
        Lighting.FogStart = 0
        Lighting.FogEnd = math.max(20, fogThickness)
        setFogAtmosphere(true, Lighting.FogColor)
    else
        Lighting.FogStart = fogOriginal.FogStart
        Lighting.FogEnd = fogOriginal.FogEnd
        Lighting.FogColor = fogOriginal.FogColor
        setFogAtmosphere(false)
    end
end)

-- Fog colors: rectangular text list. These buttons change Fog Color only.
fogColors = {
    {"Hot Pink", Color3.fromRGB(255, 70, 160)},
    {"Pink", Color3.fromRGB(255, 145, 195)},
    {"Light Orange", Color3.fromRGB(255, 190, 120)},
    {"Cyan", Color3.fromRGB(80, 210, 240)},
    {"Green", Color3.fromRGB(90, 215, 145)},
    {"Purple", Color3.fromRGB(170, 115, 245)},
    {"Blue", Color3.fromRGB(90, 145, 245)},
    {"Electric Blue", Color3.fromRGB(45, 175, 255)},
    {"Light Red", Color3.fromRGB(255, 115, 115)},
    {"Violet", Color3.fromRGB(135, 75, 220)},
    {"Dark Red", Color3.fromRGB(155, 45, 65)},
    {"Dark Orange", Color3.fromRGB(205, 90, 40)},
    {"Lime", Color3.fromRGB(150, 235, 55)},
    {"Yellow", Color3.fromRGB(255, 220, 55)},
    {"Orange", Color3.fromRGB(255, 135, 45)},
    {"Red", Color3.fromRGB(240, 55, 65)}
}

fogColorTitle = Instance.new("TextLabel")
fogColorTitle.Name = "FogColorTitle"
fogColorTitle.Size = UDim2.new(1, -30, 0, 20)
fogColorTitle.Position = UDim2.new(0, 15, 0, 75)
fogColorTitle.Text = "Fog Color"
fogColorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
fogColorTitle.TextSize = 13
fogColorTitle.Font = Enum.Font.Gotham
fogColorTitle.BackgroundTransparency = 1
fogColorTitle.TextXAlignment = Enum.TextXAlignment.Left
fogColorTitle.Parent = tabs.Visual

fogColorList = Instance.new("ScrollingFrame")
fogColorList.Name = "FogColorList"
fogColorList.Size = UDim2.new(1, -30, 0, 185)
fogColorList.Position = UDim2.new(0, 15, 0, 100)
fogColorList.BackgroundTransparency = 1
fogColorList.BorderSizePixel = 0
fogColorList.ScrollBarThickness = 4
fogColorList.ScrollBarImageColor3 = Color3.fromRGB(166, 184, 124)
fogColorList.CanvasSize = UDim2.new(0, 0, 0, #fogColors * 31 + 31)
fogColorList.Parent = tabs.Visual

for i, item in ipairs(fogColors) do
    local name, color = item[1], item[2]
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "Fog_" .. name:gsub("%s+", "")
    colorButton.Size = UDim2.new(1, -4, 0, 25)
    colorButton.Position = UDim2.new(0, 0, 0, (i - 1) * 31)
    colorButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
    colorButton.BorderColor3 = Color3.fromRGB(166, 184, 124)
    colorButton.BorderSizePixel = 1
    colorButton.Text = name
    colorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorButton.TextSize = 12
    colorButton.Font = Enum.Font.Gotham
    colorButton.AutoButtonColor = false
    colorButton.Parent = fogColorList
    colorButton.MouseEnter:Connect(function()
        colorButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
    colorButton.MouseLeave:Connect(function()
        colorButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
    colorButton.MouseButton1Click:Connect(function()
        applyFogColor(color)
    end)
end

-- Fog thickness
fogThicknessLabel = Instance.new("TextLabel")
fogThicknessLabel.Size = UDim2.new(1, -30, 0, 20)
fogThicknessLabel.Position = UDim2.new(0, 15, 0, 295)
fogThicknessLabel.Text = "Fog Thickness: 250"
fogThicknessLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fogThicknessLabel.TextSize = 13
fogThicknessLabel.Font = Enum.Font.Gotham
fogThicknessLabel.BackgroundTransparency = 1
fogThicknessLabel.TextXAlignment = Enum.TextXAlignment.Left
fogThicknessLabel.Parent = tabs.Visual
fogSlider = Instance.new("Frame")
fogSlider.Name = "AyeshaFogSlider"
fogSlider.Size = UDim2.new(1, -30, 0, 6)
fogSlider.Position = UDim2.new(0, 15, 0, 325)
fogSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
fogSlider.BorderSizePixel = 0
fogSlider.Active = true
fogSlider.Parent = tabs.Visual
Instance.new("UICorner", fogSlider).CornerRadius = UDim.new(0, 6)

fogSliderBtn = Instance.new("TextButton")
fogSliderBtn.Name = "Handle"
fogSliderBtn.Size = UDim2.fromOffset(16, 16)
fogSliderBtn.Position = UDim2.new((1000 - fogThickness) / 950, -8, 0.5, -8)
fogSliderBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
fogSliderBtn.BorderSizePixel = 0
fogSliderBtn.Text = ""
fogSliderBtn.AutoButtonColor = false
fogSliderBtn.ZIndex = 3
fogSliderBtn.Parent = fogSlider
Instance.new("UICorner", fogSliderBtn).CornerRadius = UDim.new(1, 0)

fogDragging = false
function setFogFromX(x)
    local width = fogSlider.AbsoluteSize.X
    if width <= 0 then return end
    local percentage = math.clamp((x - fogSlider.AbsolutePosition.X) / width, 0, 1)
    fogSliderBtn.Position = UDim2.new(percentage, -8, 0.5, -8)
    fogThickness = math.round(1000 - (percentage * 950))
    fogThicknessLabel.Text = "Fog Thickness: " .. tostring(fogThickness)
    if fogEnabled then
        Lighting.FogStart = 0
        Lighting.FogEnd = math.max(20, fogThickness)
        setFogAtmosphere(true, Lighting.FogColor)
    end
end

function beginFogDrag(input)
    fogDragging = true
    setFogFromX(input.Position.X)
end

fogSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginFogDrag(input)
    end
end)

fogSliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginFogDrag(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not fogDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        setFogFromX(input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fogDragging = false
    end
end)


--// Saturation Slider

colorCorrection = Lighting:FindFirstChild("AyeshaColorCorrection")
saturationOriginalSaturation = colorCorrection and colorCorrection.Saturation or 0
saturationCreatedEffect = false

saturationEnabled = false
saturationValue = 1000

function ensureSaturationEffect()
    if colorCorrection and colorCorrection.Parent then return colorCorrection end
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "AyeshaColorCorrection"
    colorCorrection.Saturation = 0
    colorCorrection.Parent = Lighting
    saturationCreatedEffect = true
    saturationOriginalSaturation = 0
    return colorCorrection
end

-- Remove old saturation UI if the script was executed again
oldSaturationLabel = tabs.Visual:FindFirstChild("AyeshaSaturationLabel")
if oldSaturationLabel then
    oldSaturationLabel:Destroy()
end

oldSaturationSlider = tabs.Visual:FindFirstChild("AyeshaSaturationSlider")
if oldSaturationSlider then
    oldSaturationSlider:Destroy()
end

--// Enable Saturation Toggle

saturationEnableLabel, saturationEnableBtn =
    createToggle(tabs.Visual, "Enable Saturation", 405)

saturationEnableBtn.Text = "OFF"
saturationEnableBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

--// Saturation Label

saturationLabel = Instance.new("TextLabel")
saturationLabel.Name = "AyeshaSaturationLabel"
saturationLabel.Size = UDim2.new(1, -30, 0, 20)
saturationLabel.Position = UDim2.new(0, 15, 0, 425)
saturationLabel.Text = "Saturation: " .. tostring(saturationValue)
saturationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
saturationLabel.TextSize = 13
saturationLabel.Font = Enum.Font.Gotham
saturationLabel.BackgroundTransparency = 1
saturationLabel.TextXAlignment = Enum.TextXAlignment.Left
saturationLabel.Parent = tabs.Visual

--// Saturation Slider

saturationSlider = Instance.new("Frame")
saturationSlider.Name = "AyeshaSaturationSlider"
saturationSlider.Size = UDim2.new(1, -30, 0, 6)
saturationSlider.Position = UDim2.new(0, 15, 0, 455)
saturationSlider.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
saturationSlider.BorderSizePixel = 0
saturationSlider.Parent = tabs.Visual

sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 6)
sliderCorner.Parent = saturationSlider

--// Slider Button

saturationButton = Instance.new("TextButton")
saturationButton.Name = "AyeshaSaturationButton"
saturationButton.Size = UDim2.new(0, 14, 0, 14)

-- 1000 starts in the middle
saturationButton.Position = UDim2.new(0.5, -7, 0.5, -7)

saturationButton.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
saturationButton.BorderSizePixel = 0
saturationButton.Text = ""
saturationButton.AutoButtonColor = false
saturationButton.Parent = saturationSlider

buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = saturationButton

--// Start disabled without touching an existing game effect.

--// Apply Saturation

function applySaturation()
    if saturationEnabled then
        local effect = ensureSaturationEffect()
        -- Convert UI value 1-2000 into Roblox -1 to 1
        effect.Saturation = -1 + ((saturationValue - 1) / 1999) * 2
    elseif colorCorrection then
        colorCorrection.Saturation = saturationOriginalSaturation
        if saturationCreatedEffect then
            colorCorrection.Enabled = false
        end
    end
end

--// Enable / Disable

saturationEnableBtn.MouseButton1Click:Connect(function()
    saturationEnabled = not saturationEnabled

    if saturationEnabled then
        saturationEnableBtn.Text = "ON"
        saturationEnableBtn.BackgroundColor3 =
            Color3.fromRGB(166, 184, 124)

        applySaturation()
    else
        saturationEnableBtn.Text = "OFF"
        saturationEnableBtn.BackgroundColor3 =
            Color3.fromRGB(245, 248, 239)

        colorCorrection.Saturation = 0
    end
end)

--// Slider Updating

saturationDragging = false

function updateSaturation(input)
    local width = saturationSlider.AbsoluteSize.X

    if width <= 0 then
        return
    end

    local percentage = math.clamp(
        (input.Position.X - saturationSlider.AbsolutePosition.X) / width,
        0,
        1
    )

    saturationButton.Position =
        UDim2.new(percentage, -7, 0.5, -7)

    saturationValue =
        math.round(1 + percentage * 1999)

    saturationLabel.Text =
        "Saturation: " .. tostring(saturationValue)

    applySaturation()
end

--// Start Dragging

saturationButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        saturationDragging = true

        updateSaturation(input)
    end
end)

--// Continue Dragging

UIS.InputChanged:Connect(function(input)
    if not saturationDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        updateSaturation(input)
    end
end)

--// Stop Dragging

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        saturationDragging = false
    end
end)

--// Rainbow Fog*
rainbowLabel, rainbowBtn =
    createToggle(tabs.Visual, "Rainbow Fog", 520)
rainbowBtn.MouseButton1Click:Connect(function()
    rainbowFog = not rainbowFog
    rainbowBtn.Text = rainbowFog and "ON" or "OFF"
    rainbowBtn.BackgroundColor3 = rainbowFog
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
    if rainbowFog then
        if rainbowConnection then
            rainbowConnection:Disconnect()
        end
        rainbowConnection = RunService.RenderStepped:Connect(function()
            if fogEnabled then
                local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                Lighting.FogColor = rainbowColor
                setFogAtmosphere(true, rainbowColor)
            end
        end)
    else
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
    end
end)
--// Reset Fog
-- Restores the exact fog values captured when the script started.
resetFogButton = Instance.new("TextButton")
resetFogButton.Name = "ResetFog"
resetFogButton.Size = UDim2.new(1, -30, 0, 25)
resetFogButton.Position = UDim2.new(0, 15, 0, 350)
resetFogButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
resetFogButton.BorderColor3 = Color3.fromRGB(166, 184, 124)
resetFogButton.BorderSizePixel = 1
resetFogButton.Text = "Reset Fog"
resetFogButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetFogButton.TextSize = 12
resetFogButton.Font = Enum.Font.Gotham
resetFogButton.AutoButtonColor = false
resetFogButton.Parent = tabs.Visual
resetFogButton.MouseEnter:Connect(function()
    resetFogButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)
resetFogButton.MouseLeave:Connect(function()
    resetFogButton.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
end)
resetFogButton.MouseButton1Click:Connect(function()
    fogEnabled = false
    rainbowFog = false
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end

    fogBtn.Text = "OFF"
    fogBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

    -- Restore the game's original fog exactly as it was at execution.
    Lighting.FogStart = fogOriginal.FogStart
    Lighting.FogEnd = fogOriginal.FogEnd
    Lighting.FogColor = fogOriginal.FogColor

    fogThickness = math.clamp(fogOriginal.FogEnd, 50, 1000)
    fogThicknessLabel.Text = "Fog Thickness: " .. tostring(math.round(fogThickness))
    local pct = math.clamp((1000 - fogThickness) / 950, 0, 1)
    fogSliderBtn.Position = UDim2.new(pct, -7, 0.5, -7)

    -- Do not leave the helper atmosphere active after a reset.
    if fogAtmosphere and createdFogAtmosphere then
        pcall(function() fogAtmosphere:Destroy() end)
        fogAtmosphere = nil
        createdFogAtmosphere = false
    elseif fogAtmosphere and fogOriginalAtmosphere then
        fogAtmosphere.Enabled = fogOriginalAtmosphere.Enabled
    end
end)

--// Environment Presets
environmentOriginal = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ExposureCompensation = Lighting.ExposureCompensation
}

-- Extra visual effects used only by the Environment presets.
-- They are kept separate so Reset/Original does not overwrite other effects.
-- Do not create/disable any Lighting effect during script execution.
environmentColor = Lighting:FindFirstChild("AyeshaEnvironmentColor")
environmentSunRays = Lighting:FindFirstChild("AyeshaEnvironmentSunRays")
environmentBloom = Lighting:FindFirstChild("AyeshaEnvironmentBloom")
environmentAtmosphere = Lighting:FindFirstChild("AyeshaEnvironmentAtmosphere")
environmentSky = Lighting:FindFirstChildOfClass("Sky")
environmentCreatedEffects = false
environmentCreatedAtmosphere = false
environmentCreatedSky = false

function ensureEnvironmentEffects()
    if not environmentColor then
        environmentColor = Instance.new("ColorCorrectionEffect")
        environmentColor.Name = "AyeshaEnvironmentColor"
        environmentColor.Parent = Lighting
    end
    if not environmentSunRays then
        environmentSunRays = Instance.new("SunRaysEffect")
        environmentSunRays.Name = "AyeshaEnvironmentSunRays"
        environmentSunRays.Parent = Lighting
    end
    if not environmentBloom then
        environmentBloom = Instance.new("BloomEffect")
        environmentBloom.Name = "AyeshaEnvironmentBloom"
        environmentBloom.Parent = Lighting
    end
    if not environmentAtmosphere then
        environmentAtmosphere = Instance.new("Atmosphere")
        environmentAtmosphere.Name = "AyeshaEnvironmentAtmosphere"
        environmentAtmosphere.Parent = Lighting
        environmentCreatedAtmosphere = true
    end
end

--// Environment Skybox
function ensureEnvironmentSky()
    if environmentSky and environmentSky.Parent then return environmentSky end
    environmentSky = Instance.new("Sky")
    environmentSky.Name = "AyeshaEnvironmentSky"
    environmentSky.Parent = Lighting
    environmentCreatedSky = true
    return environmentSky
end

environmentOriginalSky = environmentSky and {
    SkyboxBk = environmentSky.SkyboxBk,
    SkyboxDn = environmentSky.SkyboxDn,
    SkyboxFt = environmentSky.SkyboxFt,
    SkyboxLf = environmentSky.SkyboxLf,
    SkyboxRt = environmentSky.SkyboxRt,
    SkyboxUp = environmentSky.SkyboxUp,
    CelestialBodiesShown = environmentSky.CelestialBodiesShown,
    StarCount = environmentSky.StarCount
} or nil

--// Christmas Cloud + Snow layers are created only when Christmas is clicked.
environmentClouds = workspace.Terrain:FindFirstChild("AyeshaChristmasClouds")

snowPart = nil
snowEmitter = nil
snowFollowConnection = nil
function ensureSnow()
    if snowPart and snowPart.Parent then return end
    snowPart = Instance.new("Part")
    snowPart.Name = "AyeshaSeasonalSnow"
    snowPart.Anchored = true
    snowPart.CanCollide = false
    snowPart.CanTouch = false
    snowPart.CanQuery = false
    snowPart.CastShadow = false
    snowPart.Transparency = 1
    snowPart.Size = Vector3.new(1000, 40, 1000)
    snowPart.Parent = workspace

    snowEmitter = Instance.new("ParticleEmitter")
    snowEmitter.Name = "FallingSnow"
    snowEmitter.Enabled = false
    snowEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    snowEmitter.LightEmission = 0.85
    snowEmitter.Lifetime = NumberRange.new(8, 14)
    snowEmitter.Rate = 14000
    snowEmitter.Speed = NumberRange.new(7, 16)
    snowEmitter.SpreadAngle = Vector2.new(18, 18)
    snowEmitter.Shape = Enum.ParticleEmitterShape.Box
    snowEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    snowEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
    snowEmitter.EmissionDirection = Enum.NormalId.Bottom
    snowEmitter.Acceleration = Vector3.new(0, -5, 0)
    snowEmitter.Drag = 0.25
    snowEmitter.Rotation = NumberRange.new(0, 360)
    snowEmitter.RotSpeed = NumberRange.new(-25, 25)
    snowEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.45, 0.7),
        NumberSequenceKeypoint.new(1, 0.28)
    })
    snowEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.82, 0.08),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    snowEmitter.Parent = snowPart

    snowFollowConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if camera and snowPart and snowPart.Parent then
            snowPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 90, 0))
        end
    end)
end

function setSeasonalSnow(mode)
    if mode == "Christmas" then
        ensureSnow()
        if not environmentClouds then
            environmentClouds = Instance.new("Clouds")
            environmentClouds.Name = "AyeshaChristmasClouds"
            environmentClouds.Parent = workspace.Terrain
        end
        environmentClouds.Enabled = true
        environmentClouds.Cover = 0.8
        environmentClouds.Density = 0.75
        environmentClouds.Color = Color3.fromRGB(220, 238, 252)
        snowEmitter.Color = ColorSequence.new(Color3.fromRGB(245, 248, 239))
        snowEmitter.Rate = 9000
        snowEmitter.Lifetime = NumberRange.new(8, 13)
        snowEmitter.Speed = NumberRange.new(8, 17)
        snowEmitter.Enabled = true
        snowEmitter:Emit(3500)
    else
        if snowEmitter then
            snowEmitter.Enabled = false
            snowEmitter:Clear()
        end
        if environmentClouds then
            environmentClouds.Enabled = false
        end
    end
end

environmentNames = {"Sunset", "Galaxy", "Christmas", "Original"}
environmentButtons = {}

environmentOriginalAtmosphere = environmentAtmosphere and {
    Color = environmentAtmosphere.Color,
    Decay = environmentAtmosphere.Decay,
    Density = environmentAtmosphere.Density,
    Glare = environmentAtmosphere.Glare,
    Haze = environmentAtmosphere.Haze,
    Offset = environmentAtmosphere.Offset
} or nil
environmentOriginalColorEffect = environmentColor and {
    Enabled = environmentColor.Enabled,
    TintColor = environmentColor.TintColor,
    Brightness = environmentColor.Brightness,
    Contrast = environmentColor.Contrast,
    Saturation = environmentColor.Saturation
} or nil
environmentOriginalRays = environmentSunRays and {
    Enabled = environmentSunRays.Enabled,
    Intensity = environmentSunRays.Intensity,
    Spread = environmentSunRays.Spread
} or nil
environmentOriginalBloom = environmentBloom and {
    Enabled = environmentBloom.Enabled,
    Intensity = environmentBloom.Intensity,
    Size = environmentBloom.Size,
    Threshold = environmentBloom.Threshold
} or nil

function restoreEnvironmentEffects()
    if environmentColor then
        if environmentOriginalColorEffect then
            environmentColor.Enabled = environmentOriginalColorEffect.Enabled
            environmentColor.TintColor = environmentOriginalColorEffect.TintColor
            environmentColor.Brightness = environmentOriginalColorEffect.Brightness
            environmentColor.Contrast = environmentOriginalColorEffect.Contrast
            environmentColor.Saturation = environmentOriginalColorEffect.Saturation
        else
            environmentColor.Enabled = false
        end
    end
    if environmentSunRays then
        if environmentOriginalRays then
            environmentSunRays.Enabled = environmentOriginalRays.Enabled
            environmentSunRays.Intensity = environmentOriginalRays.Intensity
            environmentSunRays.Spread = environmentOriginalRays.Spread
        else
            environmentSunRays.Enabled = false
        end
    end
    if environmentBloom then
        if environmentOriginalBloom then
            environmentBloom.Enabled = environmentOriginalBloom.Enabled
            environmentBloom.Intensity = environmentOriginalBloom.Intensity
            environmentBloom.Size = environmentOriginalBloom.Size
            environmentBloom.Threshold = environmentOriginalBloom.Threshold
        else
            environmentBloom.Enabled = false
        end
    end
    if environmentAtmosphere and environmentCreatedAtmosphere then
        environmentAtmosphere:Destroy()
        environmentAtmosphere = nil
        environmentCreatedAtmosphere = false
    elseif environmentAtmosphere and environmentOriginalAtmosphere then
        environmentAtmosphere.Color = environmentOriginalAtmosphere.Color
        environmentAtmosphere.Decay = environmentOriginalAtmosphere.Decay
        environmentAtmosphere.Density = environmentOriginalAtmosphere.Density
        environmentAtmosphere.Glare = environmentOriginalAtmosphere.Glare
        environmentAtmosphere.Haze = environmentOriginalAtmosphere.Haze
        environmentAtmosphere.Offset = environmentOriginalAtmosphere.Offset
    end
end

currentEnvironment = "Original"

-- Keep the selected environment locked at render time.
-- A 0.25s loop caused visible flicker when the game also changed Lighting,
-- because both scripts were fighting for ClockTime/sky. RenderPriority.Last
-- applies our selected preset immediately before the frame is rendered.
environmentLockName = "AyeshaEnvironmentLock"
function enforceEnvironment()
    if currentEnvironment == "Original" then
        -- Force Time must still work when the user is on Original.
        if forceTimeEnabled then
            local targetClockTime = forceTimeValue % 24
            if math.abs(Lighting.ClockTime - targetClockTime) > 0.001 then
                Lighting.ClockTime = targetClockTime
            end
        end
        if brightnessEnabled then
            local targetBrightness = math.clamp(brightnessValue, 0, 5)
            if math.abs(Lighting.Brightness - targetBrightness) > 0.001 then
                Lighting.Brightness = targetBrightness
            end
        end
        return
    end

    local preset = environmentPresets[currentEnvironment]
    if not preset then
        return
    end
    ensureEnvironmentEffects()

    -- Force the complete environment, not just ClockTime.
    local targetClockTime = forceTimeEnabled and (forceTimeValue % 24) or preset.ClockTime
    if math.abs(Lighting.ClockTime - targetClockTime) > 0.001 then
        Lighting.ClockTime = targetClockTime
    end
    local targetBrightness = brightnessEnabled
        and math.clamp(brightnessValue, 0, 5)
        or preset.Brightness
    if math.abs(Lighting.Brightness - targetBrightness) > 0.001 then
        Lighting.Brightness = targetBrightness
    end
    if Lighting.FogStart ~= preset.FogStart then
        Lighting.FogStart = preset.FogStart
    end
    if Lighting.FogEnd ~= preset.FogEnd then
        Lighting.FogEnd = preset.FogEnd
    end
    if Lighting.FogColor ~= preset.FogColor then
        Lighting.FogColor = preset.FogColor
    end
    if Lighting.Ambient ~= preset.Ambient then
        Lighting.Ambient = preset.Ambient
    end
    if Lighting.OutdoorAmbient ~= preset.OutdoorAmbient then
        Lighting.OutdoorAmbient = preset.OutdoorAmbient
    end
    if Lighting.ColorShift_Top ~= preset.ColorShift_Top then
        Lighting.ColorShift_Top = preset.ColorShift_Top
    end
    if Lighting.ColorShift_Bottom ~= preset.ColorShift_Bottom then
        Lighting.ColorShift_Bottom = preset.ColorShift_Bottom
    end
    if math.abs(Lighting.ExposureCompensation - preset.ExposureCompensation) > 0.001 then
        Lighting.ExposureCompensation = preset.ExposureCompensation
    end

    -- Keep our sky active if the game replaces/removes it. Only write properties
    -- when they actually differ so the lock itself does not create visual churn.
    if not environmentSky then
        ensureEnvironmentSky()
    elseif environmentSky.Parent ~= Lighting then
        environmentSky.Parent = Lighting
    end
    local sky = skyPresets[currentEnvironment]
    if sky and environmentSky then
        if environmentSky.SkyboxBk ~= sky.SkyboxBk then environmentSky.SkyboxBk = sky.SkyboxBk end
        if environmentSky.SkyboxDn ~= sky.SkyboxDn then environmentSky.SkyboxDn = sky.SkyboxDn end
        if environmentSky.SkyboxFt ~= sky.SkyboxFt then environmentSky.SkyboxFt = sky.SkyboxFt end
        if environmentSky.SkyboxLf ~= sky.SkyboxLf then environmentSky.SkyboxLf = sky.SkyboxLf end
        if environmentSky.SkyboxRt ~= sky.SkyboxRt then environmentSky.SkyboxRt = sky.SkyboxRt end
        if environmentSky.SkyboxUp ~= sky.SkyboxUp then environmentSky.SkyboxUp = sky.SkyboxUp end
        local celestial = (currentEnvironment ~= "Galaxy")
        if environmentSky.CelestialBodiesShown ~= celestial then environmentSky.CelestialBodiesShown = celestial end
        local stars = sky.StarCount or 0
        if environmentSky.StarCount ~= stars then environmentSky.StarCount = stars end
    end

    -- Re-lock environment-only effects without rewriting unchanged values every frame.
    local cc = preset.ColorCorrection
    if environmentColor.TintColor ~= cc.TintColor then environmentColor.TintColor = cc.TintColor end
    if math.abs(environmentColor.Brightness - cc.Brightness) > 0.001 then environmentColor.Brightness = cc.Brightness end
    if math.abs(environmentColor.Contrast - cc.Contrast) > 0.001 then environmentColor.Contrast = cc.Contrast end
    if math.abs(environmentColor.Saturation - cc.Saturation) > 0.001 then environmentColor.Saturation = cc.Saturation end
    if not environmentColor.Enabled then environmentColor.Enabled = true end

    local atmosphere = preset.Atmosphere
    if environmentAtmosphere.Color ~= atmosphere.Color then environmentAtmosphere.Color = atmosphere.Color end
    if environmentAtmosphere.Decay ~= atmosphere.Decay then environmentAtmosphere.Decay = atmosphere.Decay end
    if math.abs(environmentAtmosphere.Density - atmosphere.Density) > 0.001 then environmentAtmosphere.Density = atmosphere.Density end
    if math.abs(environmentAtmosphere.Glare - atmosphere.Glare) > 0.001 then environmentAtmosphere.Glare = atmosphere.Glare end
    if math.abs(environmentAtmosphere.Haze - atmosphere.Haze) > 0.001 then environmentAtmosphere.Haze = atmosphere.Haze end
    if math.abs(environmentAtmosphere.Offset - atmosphere.Offset) > 0.001 then environmentAtmosphere.Offset = atmosphere.Offset end

    local cloudsEnabled = (currentEnvironment == "Christmas")
    if environmentClouds and environmentClouds.Enabled ~= cloudsEnabled then
        environmentClouds.Enabled = cloudsEnabled
    end
end

RunService:BindToRenderStep(environmentLockName, Enum.RenderPriority.Last.Value, enforceEnvironment)

function applyEnvironment(name, skipStateUpdate)
    if not skipStateUpdate then
        currentEnvironment = name
    end

    if name == "Original" then
        Lighting.ClockTime = forceTimeEnabled and (forceTimeValue % 24) or environmentOriginal.ClockTime
        Lighting.Brightness = brightnessEnabled and brightnessValue or environmentOriginal.Brightness
        Lighting.FogStart = environmentOriginal.FogStart
        Lighting.FogEnd = environmentOriginal.FogEnd
        Lighting.FogColor = environmentOriginal.FogColor
        Lighting.Ambient = environmentOriginal.Ambient
        Lighting.OutdoorAmbient = environmentOriginal.OutdoorAmbient
        Lighting.ColorShift_Top = environmentOriginal.ColorShift_Top
        Lighting.ColorShift_Bottom = environmentOriginal.ColorShift_Bottom
        Lighting.ExposureCompensation = environmentOriginal.ExposureCompensation
        if environmentCreatedSky and not environmentOriginalSky and environmentSky then
            environmentSky:Destroy()
            environmentSky = nil
            environmentCreatedSky = false
        else
            applySky("Original")
        end
        restoreEnvironmentGrass()
        restoreEnvironmentEffects()
        if environmentClouds then environmentClouds.Enabled = false end
        setSeasonalSnow("Original")
        -- Returning to Original must release Ayesha's fog helper and restore the game's fog.
        fogEnabled = false
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
        if fogBtn then
            fogBtn.Text = "OFF"
            fogBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
        end
        Lighting.FogStart = fogOriginal.FogStart
        Lighting.FogEnd = fogOriginal.FogEnd
        Lighting.FogColor = fogOriginal.FogColor
        if fogAtmosphere then
            fogAtmosphere.Enabled = false
        end
        return
    end

    local preset = environmentPresets[name]
    if not preset then return end

    ensureEnvironmentEffects()

    Lighting.ClockTime = forceTimeEnabled and (forceTimeValue % 24) or preset.ClockTime
    Lighting.Brightness = brightnessEnabled and brightnessValue or preset.Brightness
    Lighting.FogStart = preset.FogStart
    Lighting.FogEnd = preset.FogEnd
    Lighting.FogColor = preset.FogColor
    Lighting.Ambient = preset.Ambient
    Lighting.OutdoorAmbient = preset.OutdoorAmbient
    Lighting.ColorShift_Top = preset.ColorShift_Top
    Lighting.ColorShift_Bottom = preset.ColorShift_Bottom
    Lighting.ExposureCompensation = preset.ExposureCompensation
    applySky(name)
    if environmentClouds then
        environmentClouds.Enabled = (name == "Christmas")
    end
    setEnvironmentGrass(preset.GrassColor or originalTerrainGrass, preset.GroundColor or originalTerrainGround)

    local cc = preset.ColorCorrection
    environmentColor.TintColor = cc.TintColor
    environmentColor.Brightness = cc.Brightness
    environmentColor.Contrast = cc.Contrast
    environmentColor.Saturation = cc.Saturation
    environmentColor.Enabled = true

    local atmosphere = preset.Atmosphere
    environmentAtmosphere.Color = atmosphere.Color
    environmentAtmosphere.Decay = atmosphere.Decay
    environmentAtmosphere.Density = atmosphere.Density
    environmentAtmosphere.Glare = atmosphere.Glare
    environmentAtmosphere.Haze = atmosphere.Haze
    environmentAtmosphere.Offset = atmosphere.Offset

    local rays = preset.SunRays
    environmentSunRays.Intensity = rays.Intensity
    environmentSunRays.Spread = rays.Spread
    environmentSunRays.Enabled = true

    local bloom = preset.Bloom
    environmentBloom.Intensity = bloom.Intensity
    environmentBloom.Size = bloom.Size
    environmentBloom.Threshold = bloom.Threshold
    environmentBloom.Enabled = true

    setSeasonalSnow(name)
end

tabs.Visual.CanvasSize = UDim2.new(0, 0, 0, 760)

--// HC Tools — Flintlock
-- Flintlock remains available in the HC tab.
local HCTools = {
    ["[Flintlock]"] = true,
}

local HCAutoAcquire = {
    ["[Flintlock]"] = false,
}

local HCAcquired = {}

local function hcOwns(name)
    local bp = me:FindFirstChild("Backpack")
    local ch = me.Character
    return (bp and bp:FindFirstChild(name) ~= nil)
        or (ch and ch:FindFirstChild(name) ~= nil)
end

local function hcGrab(tool)
    if not tool or not tool.Parent or not tool:IsA("Tool") then return end

    local name = tool.Name
    if not HCTools[name] then return end
    if not HCAutoAcquire[name] then return end
    if hcOwns(name) or HCAcquired[name] then return end

    local bp = me:FindFirstChild("Backpack")
    if not bp then return end

    HCAcquired[name] = true

    local ok = pcall(function()
        local copy = tool:Clone()
        task.wait(0.1)
        copy.Parent = bp
    end)

    if not ok then
        HCAcquired[name] = nil
    end
end

local function hcSweep(container, onlyName)
    if not container then return end

    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool")
                and HCTools[obj.Name]
                and HCAutoAcquire[obj.Name]
                and (not onlyName or obj.Name == onlyName) then
                hcGrab(obj)
            end
        end
    end)
end

local function hcPoll(name)
    if not HCAutoAcquire[name] then return end

    hcSweep(workspace, name)

    local bucket = workspace:FindFirstChild("Players")
    if bucket then
        hcSweep(bucket, name)
    end

    for _, plr in ipairs(plrs:GetPlayers()) do
        if plr ~= me then
            if plr.Character then
                hcSweep(plr.Character, name)
            end

            local bp = plr:FindFirstChild("Backpack")
            if bp then
                hcSweep(bp, name)
            end
        end
    end
end

local function hcStart(name, button, status)
    if not HCAutoAcquire[name] then
        status.Text = "OFF • " .. name
        return
    end

    table.clear(HCAcquired)

    status.Text = "ON • searching..."
    task.spawn(function()
        while HCAutoAcquire[name] do
            hcPoll(name)

            if hcOwns(name) then
                status.Text = "ON • acquired"
            else
                status.Text = "ON • searching..."
            end

            task.wait(1)
        end

        status.Text = "OFF • " .. name
    end)
end

workspace.DescendantAdded:Connect(function(obj)
    if not obj:IsA("Tool") or not HCTools[obj.Name] then return end

    local name = obj.Name
    if not HCAutoAcquire[name] then return end

    task.delay(0.1, function()
        if HCAutoAcquire[name] then
            hcGrab(obj)
        end
    end)
end)

plrs.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(ch)
        task.wait(0.5)

        if HCAutoAcquire["[Flintlock]"] then
            hcSweep(ch, "[Flintlock]")
        end
    end)
end)

local hcTitle = Instance.new("TextLabel")
hcTitle.Name = "HCToolTitle"
hcTitle.Size = UDim2.new(1, -30, 0, 22)
hcTitle.Position = UDim2.fromOffset(15, 35)
hcTitle.Text = "HC Tools"
hcTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
hcTitle.TextSize = 13
hcTitle.Font = Enum.Font.Gotham
hcTitle.BackgroundTransparency = 1
hcTitle.TextXAlignment = Enum.TextXAlignment.Left
hcTitle.Parent = tabs.HC

local flintStatus = Instance.new("TextLabel")
flintStatus.Name = "FlintlockStatus"
flintStatus.Size = UDim2.new(1, -30, 0, 18)
flintStatus.Position = UDim2.fromOffset(15, 86)
flintStatus.Text = "OFF • [Flintlock]"
flintStatus.TextColor3 = Color3.fromRGB(105, 116, 88)
flintStatus.TextSize = 10
flintStatus.Font = Enum.Font.Gotham
flintStatus.BackgroundTransparency = 1
flintStatus.TextXAlignment = Enum.TextXAlignment.Left
flintStatus.Parent = tabs.HC

local flintLabel, flintBtn = createToggle(tabs.HC, "Flintlock", 58)
flintBtn.Text = "OFF"
flintBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)

local function updateHCToggle(button, name, enabled)
    button.Text = enabled and "ON" or "OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end

flintBtn.MouseButton1Click:Connect(function()
    local name = "[Flintlock]"
    HCAutoAcquire[name] = not HCAutoAcquire[name]

    updateHCToggle(flintBtn, name, HCAutoAcquire[name])

    if HCAutoAcquire[name] then
        hcStart(name, flintBtn, flintStatus)
    else
        flintStatus.Text = "OFF • [Flintlock]"
    end
end)

tabs.HC.CanvasSize = UDim2.new(0, 0, 0, 125)


--// Force Reset
forceResetEnabled = false
forceResetKey = Enum.KeyCode.R
changingResetKey = false

resetToggleLabel, resetToggleBtn =
    createToggle(tabs.ForceReset, "Force Reset", 55)

resetToggleBtn.MouseButton1Click:Connect(function()
    forceResetEnabled = not forceResetEnabled

    resetToggleBtn.Text = forceResetEnabled and "ON" or "OFF"
    resetToggleBtn.BackgroundColor3 = forceResetEnabled
        and Color3.fromRGB(166, 184, 124)
        or Color3.fromRGB(245, 248, 239)
end)

resetNowBtn = Instance.new("TextButton")
resetNowBtn.Size = UDim2.new(0, 100, 0, 26)
resetNowBtn.Position = UDim2.new(1, -115, 0, 135)
resetNowBtn.BackgroundColor3 = Color3.fromRGB(245, 248, 239)
resetNowBtn.BorderSizePixel = 0
resetNowBtn.Text = "Reset Now"
resetNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetNowBtn.TextSize = 11
resetNowBtn.Font = Enum.Font.Gotham
resetNowBtn.AutoButtonColor = false
resetNowBtn.Parent = tabs.ForceReset
Instance.new("UICorner", resetNowBtn).CornerRadius = UDim.new(0, 6)
resetNowBtn.MouseButton1Click:Connect(function()
    character = me.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
    end
end)

resetKeyLabel = Instance.new("TextLabel")
resetKeyLabel.Size = UDim2.new(0, 150, 0, 30)
resetKeyLabel.Position = UDim2.new(0, 15, 0, 110)
resetKeyLabel.BackgroundTransparency = 1
resetKeyLabel.Text = "Reset Key"
resetKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resetKeyLabel.TextSize = 13
resetKeyLabel.Font = Enum.Font.Gotham
resetKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
resetKeyLabel.Parent = tabs.ForceReset

resetKeyBtn = Instance.new("TextButton")
resetKeyBtn.Size = UDim2.new(0, 100, 0, 26)
resetKeyBtn.Position = UDim2.new(1, -115, 0, 97)
resetKeyBtn.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
resetKeyBtn.BorderSizePixel = 0
resetKeyBtn.Text = "Key: R"
resetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetKeyBtn.TextSize = 11
resetKeyBtn.Font = Enum.Font.Gotham
resetKeyBtn.AutoButtonColor = false
resetKeyBtn.Parent = tabs.ForceReset

Instance.new("UICorner", resetKeyBtn).CornerRadius = UDim.new(0, 6)

resetKeyBtn.MouseButton1Click:Connect(function()
    changingResetKey = true
    resetKeyBtn.Text = "Press key"
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end

    if changingResetKey then
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode ~= Enum.KeyCode.Unknown then

            forceResetKey = input.KeyCode
            resetKeyBtn.Text = "Key: " .. forceResetKey.Name
            changingResetKey = false
        end

        return
    end

    if forceResetEnabled
        and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == forceResetKey then

        character = me.Character
        humanoid = character
            and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.Health = 0
        end
    end
end)

--// V12.4 UI POLISH — silent interactions + cleaner controls (UI only)
for _, btn in pairs(tabButtons) do
    btnHoverStroke = Instance.new("UIStroke")
    btnHoverStroke.Name = "HoverStroke"
    btnHoverStroke.Color = Color3.fromRGB(166, 184, 124)
    btnHoverStroke.Thickness = 1
    btnHoverStroke.Transparency = 1
    btnHoverStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        s = btn:FindFirstChild("HoverStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0.25}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        s = btn:FindFirstChild("HoverStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 1}):Play() end
    end)
end



--// ASTRO.MAIN — final page row normalization
-- Keep every standard toggle row aligned consistently across ALL pages.
do
    local function normalizeTextObject(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.TextColor3 = Color3.fromRGB(58, 68, 46)
            obj.Font = Enum.Font.Gotham
        end
        local corner = obj:FindFirstChildOfClass("UICorner")
        if corner then corner.CornerRadius = UDim.new(0, 6) end
    end

    for _, page in pairs(tabs) do
        for _, obj in ipairs(page:GetChildren()) do
            normalizeTextObject(obj)
            if obj:IsA("GuiButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
                obj.ZIndex = math.max(obj.ZIndex, 2)
            end
        end
    end
end

--// ASTRO.MAIN V12.5 — global visual normalization
-- Keeps every page on the same font, spacing feel, rounded controls and lavender accent.
AyeshaVisualDescendants = gui:GetDescendants()
for AyeshaVisualIndex = 1, #AyeshaVisualDescendants do
    AyeshaVisualObject = AyeshaVisualDescendants[AyeshaVisualIndex]
    if AyeshaVisualObject:IsA("TextLabel") or AyeshaVisualObject:IsA("TextButton") or AyeshaVisualObject:IsA("TextBox") then
        AyeshaVisualObject.Font = Enum.Font.Gotham
        AyeshaVisualObject.TextColor3 = Color3.fromRGB(58, 68, 46)
        if AyeshaVisualObject.TextSize > 0 then
            AyeshaVisualObject.TextSize = math.clamp(AyeshaVisualObject.TextSize + 1, 10, 18)
        end
    end
    if AyeshaVisualObject:IsA("TextButton") or AyeshaVisualObject:IsA("TextBox") then
        AyeshaVisualObject.AutoButtonColor = false
        AyeshaVisualCorner = AyeshaVisualObject:FindFirstChildOfClass("UICorner")
        if AyeshaVisualCorner then
            AyeshaVisualCorner.CornerRadius = UDim.new(0, 6)
        end
    end
end

--// ASTRO.MAIN V16 — COMPACT PAGE SPACING
-- Tightens the visual rhythm on every page without changing backend logic.
-- Keeps headers readable while reducing oversized gaps and oversized controls.
do
    local compactPages = {
        SilentAim=true, Hitbox=true, Flamelock=true, TriggerBot=true,
        CamLock=true, ESP=true, Misc=true, Teleport=true, Visual=true,
        ForceReset=true, Avatar=true, Char=true, Whitelist=true, SkinChanger=true
    }

    local function compactObject(obj, factor)
        if not obj or not obj:IsA("GuiObject") then return end
        if obj:IsA("ScrollingFrame") then
            -- Keep scrolling containers usable; only tighten their internal scale.
            local scale = obj:FindFirstChild("AyeshaCompactScale")
            if not scale then
                scale = Instance.new("UIScale")
                scale.Name = "AyeshaCompactScale"
                scale.Scale = factor
                scale.Parent = obj
            else
                scale.Scale = factor
            end
        else
            local scale = obj:FindFirstChild("AyeshaCompactScale")
            if obj:IsA("Frame") and obj:FindFirstChildOfClass("UIListLayout") then
                -- List containers are already spacing-driven; leave their geometry intact.
                return
            end
            if scale then
                scale.Scale = factor
            end
        end
    end

    for pageName in pairs(compactPages) do
        local page = tabs and tabs[pageName]
        if page then
            -- A subtle page-wide scale makes the content feel denser while keeping
            -- the overall window size unchanged.
            local pageScale = page:FindFirstChild("AyeshaPageCompactScale")
            if not pageScale then
                pageScale = Instance.new("UIScale")
                pageScale.Name = "AyeshaPageCompactScale"
                pageScale.Scale = 1
                pageScale.Parent = page
            else
                pageScale.Scale = 1
            end

            -- Reduce the bottom breathing room so pages don't look empty.
            local pad = page:FindFirstChildOfClass("UIPadding")
            if pad then
                pad.PaddingBottom = UDim.new(0, 8)
            end
        end
    end

    -- Compact the sidebar rows slightly as well so the denser pages feel balanced.
    if ScrollingFrame then
        local sidebarScale = ScrollingFrame:FindFirstChild("AyeshaSidebarCompactScale")
        if not sidebarScale then
            sidebarScale = Instance.new("UIScale")
            sidebarScale.Name = "AyeshaSidebarCompactScale"
            sidebarScale.Scale = 1
            sidebarScale.Parent = ScrollingFrame
        else
            sidebarScale.Scale = 1
        end
    end
end


--// FINAL TOGGLE / TEXT NORMALIZATION
-- Every ON/OFF control uses the same readable matcha toggle style.
do
    local function styleToggle(button)
        if not button or not button:IsA("TextButton") then return end
        local function refresh()
            if button.Text == "ON" then
                button.BackgroundColor3 = Color3.fromRGB(166, 184, 124)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            elseif button.Text == "OFF" then
                button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                button.TextColor3 = Color3.fromRGB(58, 68, 46)
            end
        end
        refresh()
        button:GetPropertyChangedSignal("Text"):Connect(refresh)
    end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") then
            styleToggle(obj)
        elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
            obj.TextColor3 = Color3.fromRGB(58, 68, 46)
        end
    end
end

--// FINAL HOME / AVATAR VISIBILITY FIX
-- Re-assert these page-specific colors after the global visual normalization above.
task.defer(function()
    local home = tabs and tabs.Home
    if home then
        for _, obj in ipairs(home:GetDescendants()) do
            if obj:IsA("TextLabel") then
                obj.TextColor3 = Color3.fromRGB(45, 52, 35)
                obj.Font = Enum.Font.Gotham
                obj.ZIndex = math.max(obj.ZIndex, 3)
            end
        end
    end

    if homeWelcome then homeWelcome.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeUsername then homeUsername.TextColor3 = Color3.fromRGB(92, 103, 76) end
    if homeStatus then homeStatus.TextColor3 = Color3.fromRGB(58, 68, 46) end
    if homeFPSValue then homeFPSValue.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeStatusValue then homeStatusValue.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeProfileName then homeProfileName.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeNickname then homeNickname.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeUsernameValue then homeUsernameValue.TextColor3 = Color3.fromRGB(45, 52, 35) end
    if homeUserId then homeUserId.TextColor3 = Color3.fromRGB(45, 52, 35) end
end)

--// FINAL UI POLISH / SAFETY NORMALIZATION
-- Keep the requested rounded-box style without overriding page-specific text colors.
task.defer(function()
    if not gui then return end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("UICorner") then
            obj.CornerRadius = UDim.new(0, 6)
        elseif obj:IsA("TextBox") then
            obj.PlaceholderColor3 = Color3.fromRGB(58, 68, 46)
        end
    end
end)
