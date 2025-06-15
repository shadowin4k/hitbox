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
    Hitpart = "LowerTorso", -- default hit part
    Enabled = false,
    MaxDistance = math.huge, -- remove distance limit to cover all players
    AutoRefresh = true
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

local function getValidBodyPart(character, hitPartName)
    if not character then return nil end

    -- Try to get requested hitpart
    local part = character:FindFirstChild(hitPartName)
    if part then return part end

    -- If requested part missing, try common torso parts for R15 or R6
    local possibleParts = {"LowerTorso", "UpperTorso", "Torso", "HumanoidRootPart", "Head"}
    for _, pName in ipairs(possibleParts) do
        part = character:FindFirstChild(pName)
        if part then
            return part
        end
    end

    return nil
end

local function applyHitboxToPlayer(player)
    if not player.Character then return end
    local part = getValidBodyPart(player.Character, getgenv().Config.Hitpart)
    if part then
        applyAdornmentToPart(part)
    end
end

local function updateHitboxes()
    if not getgenv().Config.Enabled then
        clearAllAdornments()
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        applyHitboxToPlayer(player)
    end

    -- Clean up adornments for parts no longer valid
    local validParts = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local part = getValidBodyPart(player.Character, getgenv().Config.Hitpart)
            if part then
                validParts[part] = true
            end
        end
    end

    for part in pairs(adornments) do
        if not validParts[part] then
            clearAdornment(part)
        end
    end
end

-- Helper to wait for character and hitpart before applying adornment
local function setupCharacterListener(player)
    player.CharacterAdded:Connect(function(character)
        -- Wait for the character's required body part to load
        local hitPartName = getgenv().Config.Hitpart
        local bodyPart = character:WaitForChild(hitPartName, 5) -- wait max 5 sec
        if not bodyPart then
            -- fallback if not found
            bodyPart = getValidBodyPart(character, hitPartName)
        end
        if bodyPart and getgenv().Config.Enabled then
            applyAdornmentToPart(bodyPart)
        end
    end)
end

-- Setup for all players
for _, player in pairs(Players:GetPlayers()) do
    setupCharacterListener(player)
end

Players.PlayerAdded:Connect(function(player)
    setupCharacterListener(player)
end)

-- Update every interval if auto refresh enabled
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

-- Start enabled and auto refresh on load
getgenv().Config.Enabled = true
getgenv().Config.AutoRefresh = true
updateHitboxes()
