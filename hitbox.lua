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
    MaxDistance = math.huge,
    AutoRefresh = true,
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

-- Recursively collect all BaseParts inside character to cover all hitbox parts
local function getAllValidParts(character)
    local parts = {}
    if not character then return parts end

    local function findParts(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            elseif child:IsA("Model") or child:IsA("Folder") then
                findParts(child)
            end
        end
    end

    findParts(character)
    return parts
end

local function updateHitboxes()
    if not getgenv().Config.Enabled then
        clearAllAdornments()
        return
    end

    local validPartsSet = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp then -- optional: skip local player
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local parts = getAllValidParts(player.Character)
                for _, part in pairs(parts) do
                    applyAdornmentToPart(part)
                    validPartsSet[part] = true
                end
            end
        end
    end

    -- Remove adornments no longer valid
    for part in pairs(adornments) do
        if not validPartsSet[part] then
            clearAdornment(part)
        end
    end
end

local function setupCharacterListener(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(1) -- Wait for character to load parts
        if getgenv().Config.Enabled then
            updateHitboxes()
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    setupCharacterListener(player)
end
Players.PlayerAdded:Connect(setupCharacterListener)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        local parts = getAllValidParts(player.Character)
        for _, part in pairs(parts) do
            clearAdornment(part)
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if getgenv().Config.Enabled and getgenv().Config.AutoRefresh then
        accumulatedTime = accumulatedTime + dt
        if accumulatedTime >= updateInterval then
            accumulatedTime = 0
            updateHitboxes()
        end
    end
end)

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

-- Start enabled by default with auto refresh on
getgenv().Config.Enabled = true
getgenv().Config.AutoRefresh = true
updateHitboxes()
