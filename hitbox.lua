-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal Hitbox UI", "DarkTheme")
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Configuration
getgenv().Config = {
    Size = 5,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false
}

local adornments = {}

-- Clears adornment on a part
local function clearAdornment(part)
    if part and adornments[part] then
        adornments[part]:Destroy()
        adornments[part] = nil
    end
end

-- Applies visual hitbox (adornment) to a part WITHOUT changing physical properties
local function applyAdornmentToPart(part)
    if not part then return end

    local adorn = adornments[part]

    if adorn then
        -- Update size and color if needed
        if adorn.Size.X ~= getgenv().Config.Size then
            adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
        end
        if adorn.Color3 ~= getgenv().Config.InnerColor then
            adorn.Color3 = getgenv().Config.InnerColor
        end
        return
    end

    -- Create adornment
    adorn = Instance.new("BoxHandleAdornment")
    adorn.Name = "HitboxAdornment"
    adorn.Adornee = part
    adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    adorn.Color3 = getgenv().Config.InnerColor
    adorn.Transparency = 0.5
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 5
    adorn.Parent = part

    adornments[part] = adorn
end

-- Apply adornment to character's hitpart
local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if part then
        applyAdornmentToPart(part)
    end
end

-- Clear all adornments
local function clearAllAdornments()
    for part, _ in pairs(adornments) do
        clearAdornment(part)
    end
    adornments = {}
end

-- Apply hitboxes to all players except local player
local function applyHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            applyHitboxToCharacter(player.Character)
        end
    end
end

-- Character and player listeners
local function onCharacterAdded(char)
    task.wait(0.5)
    if getgenv().Config.Enabled then
        applyHitboxToCharacter(char)
    end
end

local function onPlayerAdded(player)
    if player == lp then return end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- Setup existing players
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Update adornments occasionally, not every frame, to avoid overhead
local updateInterval = 0.3
local accumulatedTime = 0
RunService.Heartbeat:Connect(function(dt)
    if not getgenv().Config.Enabled then return end
    accumulatedTime = accumulatedTime + dt
    if accumulatedTime < updateInterval then return end
    accumulatedTime = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            if part then
                applyAdornmentToPart(part)
            end
        end
    end
end)

-- Key toggle [H]
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        getgenv().Config.Enabled = not getgenv().Config.Enabled
        if getgenv().Config.Enabled then
            applyHitboxes()
            print("[Hitbox] Enabled")
        else
            clearAllAdornments()
            print("[Hitbox] Disabled")
        end
    end
end)

-- UI
Section:NewLabel("Toggle Hitbox: [H]")

Section:NewSlider("Hitbox Size", "Adjust hitbox size", 50, 1, function(v)
    getgenv().Config.Size = v
    if getgenv().Config.Enabled then
        applyHitboxes()
    end
end)

Section:NewColorPicker("Hitbox Color", "Set the hitbox color", getgenv().Config.InnerColor, function(c)
    getgenv().Config.InnerColor = c
    if getgenv().Config.Enabled then
        applyHitboxes()
    end
end)

Section:NewDropdown("Hitpart", "Choose body part", {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, function(v)
    getgenv().Config.Hitpart = v
    if getgenv().Config.Enabled then
        applyHitboxes()
    end
end)

Section:NewButton("Apply Manually", "Force apply hitboxes", function()
    applyHitboxes()
end)

Section:NewToggle("Auto Refresh", "Keep hitboxes updated", function(state)
    getgenv().Config.Enabled = state
    if state then
        applyHitboxes()
    else
        clearAllAdornments()
    end
end)
