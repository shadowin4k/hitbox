-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Da Hood Hitbox UI", "DarkTheme")
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

getgenv().Config = {
    Size = 10,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "LowerTorso",
    Enabled = false,
    MaxDistance = 150,
    AutoRefresh = true -- Always auto-refresh by default
}

local adornments = {}
local updateInterval = 1
local accumulatedTime = 0

local function clearAdornment(part)
    if part and adornments[part] then
        adornments[part]:Destroy()
        adornments[part] = nil
    end
end

local function applyAdornmentToPart(part)
    if not part then return end
    local config = getgenv().Config

    if adornments[part] then
        local adorn = adornments[part]
        local newSize = Vector3.new(config.Size, config.Size, config.Size)
        if adorn.Size ~= newSize then
            adorn.Size = newSize
        end
        if adorn.Color3 ~= config.InnerColor then
            adorn.Color3 = config.InnerColor
        end
        return
    end

    local adorn = Instance.new("BoxHandleAdornment")
    adorn.Name = "HitboxAdornment"
    adorn.Adornee = part
    adorn.Size = Vector3.new(config.Size, config.Size, config.Size)
    adorn.Color3 = config.InnerColor
    adorn.Transparency = 0.5
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 5
    adorn.Parent = workspace

    adornments[part] = adorn
end

local function clearAllAdornments()
    for part in pairs(adornments) do
        clearAdornment(part)
    end
    adornments = {}
end

local function getCharacterRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
end

local function updateHitboxes()
    if not getgenv().Config.Enabled then
        clearAllAdornments()
        return
    end

    local config = getgenv().Config
    local hrp = lp.Character and getCharacterRoot(lp.Character)
    if not hrp then
        return
    end

    local activeParts = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local targetPart = player.Character:FindFirstChild(config.Hitpart)

            if not targetPart then
                targetPart = player.Character:FindFirstChild("LowerTorso") or player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
            end

            if targetPart then
                local dist = (targetPart.Position - hrp.Position).Magnitude
                if dist <= config.MaxDistance then
                    applyAdornmentToPart(targetPart)
                    activeParts[targetPart] = true
                else
                    clearAdornment(targetPart)
                end
            end
        end
    end

    for part in pairs(adornments) do
        if not activeParts[part] then
            clearAdornment(part)
        end
    end
end

-- Connect Player.CharacterAdded to immediately apply hitbox when a player respawns
Players.PlayerAdded:Connect(function(player)
    if player == lp then return end
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if getgenv().Config.Enabled then
            updateHitboxes()
        end
    end)
end)

-- Also for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= lp then
        if player.Character then
            task.spawn(function()
                task.wait(0.5)
                if getgenv().Config.Enabled then
                    updateHitboxes()
                end
            end)
        end
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if getgenv().Config.Enabled then
                updateHitboxes()
            end
        end)
    end
end

-- Heartbeat for auto update
RunService.Heartbeat:Connect(function(dt)
    if not getgenv().Config.Enabled or not getgenv().Config.AutoRefresh then return end
    accumulatedTime = accumulatedTime + dt
    if accumulatedTime >= updateInterval then
        accumulatedTime = 0
        updateHitboxes()
    end
end)

-- Toggle hitboxes with H key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        getgenv().Config.Enabled = not getgenv().Config.Enabled
        if getgenv().Config.Enabled then
            updateHitboxes()
            print("[Hitbox] Enabled")
        else
            clearAllAdornments()
            print("[Hitbox] Disabled")
        end
    end
end)

-- UI Controls
Section:NewLabel("Toggle Hitbox: [H]")

Section:NewSlider("Hitbox Size", "Adjust hitbox size", 50, 1, function(v)
    getgenv().Config.Size = v
    if getgenv().Config.Enabled then
        updateHitboxes()
    end
end)

Section:NewColorPicker("Hitbox Color", "Set the hitbox color", getgenv().Config.InnerColor, function(c)
    getgenv().Config.InnerColor = c
    if getgenv().Config.Enabled then
        updateHitboxes()
    end
end)

Section:NewDropdown("Hitpart", "Choose body part", {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, function(v)
    getgenv().Config.Hitpart = v
    if getgenv().Config.Enabled then
        updateHitboxes()
    end
end)

Section:NewButton("Apply Manually", "Force apply hitboxes", function()
    updateHitboxes()
end)

Section:NewToggle("Auto Refresh", "Keep hitboxes updated", function(state)
    getgenv().Config.AutoRefresh = state
    if state then
        getgenv().Config.Enabled = true
        updateHitboxes()
    else
        clearAllAdornments()
    end
end)

-- Start enabled and auto refresh on script load for immediate effect
getgenv().Config.Enabled = true
getgenv().Config.AutoRefresh = true
updateHitboxes()
