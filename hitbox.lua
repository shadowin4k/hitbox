-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Da Hood Universal Hitbox UI", "DarkTheme")
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- Config
getgenv().Config = {
    Size = 10,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Enabled = false,
    AutoRefresh = true,
}

local adornments = {}
local updateInterval = 1
local accumulatedTime = 0

-- Clear adornment from a player's HumanoidRootPart
local function clearAdornment(player)
    if adornments[player] then
        adornments[player]:Destroy()
        adornments[player] = nil
    end
end

-- Apply or update adornment on HumanoidRootPart
local function applyAdornmentToPlayer(player)
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local config = getgenv().Config

    if adornments[player] then
        local adorn = adornments[player]
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
    adorn.Adornee = rootPart
    adorn.Size = Vector3.new(config.Size, config.Size, config.Size)
    adorn.Color3 = config.InnerColor
    adorn.Transparency = 0.5
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 5
    adorn.Parent = workspace

    adornments[player] = adorn
end

-- Clear all adornments
local function clearAllAdornments()
    for player in pairs(adornments) do
        clearAdornment(player)
    end
    adornments = {}
end

-- Update hitboxes for all players
local function updateHitboxes()
    if not getgenv().Config.Enabled then
        clearAllAdornments()
        return
    end

    local validPlayers = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            applyAdornmentToPlayer(player)
            validPlayers[player] = true
        end
    end

    -- Remove adornments for players no longer valid
    for player in pairs(adornments) do
        if not validPlayers[player] then
            clearAdornment(player)
        end
    end
end

-- Setup listener for when player character respawns
local function setupCharacterListener(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if getgenv().Config.Enabled then
            updateHitboxes()
        end
    end)
end

-- Setup listeners for all players now and future
for _, player in pairs(Players:GetPlayers()) do
    setupCharacterListener(player)
end
Players.PlayerAdded:Connect(setupCharacterListener)

-- Heartbeat update loop throttled
RunService.Heartbeat:Connect(function(dt)
    if getgenv().Config.Enabled and getgenv().Config.AutoRefresh then
        accumulatedTime = accumulatedTime + dt
        if accumulatedTime >= updateInterval then
            accumulatedTime = 0
            updateHitboxes()
        end
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

-- Start enabled & auto refresh on
getgenv().Config.Enabled = true
getgenv().Config.AutoRefresh = true
updateHitboxes()
