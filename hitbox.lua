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
local camera = workspace.CurrentCamera

-- Configuration
getgenv().Config = {
    Size = 5,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false,
    MaxDistance = 100
}

local adornments = {}
local updateInterval = 1 -- update every 1 second to reduce lag
local accumulatedTime = 0

local function clearAdornment(part)
    if part and adornments[part] then
        adornments[part]:Destroy()
        adornments[part] = nil
    end
end

local function applyAdornmentToPart(part)
    if not part then return end

    if adornments[part] then
        -- update size and color if changed
        local adorn = adornments[part]
        local newSize = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
        if adorn.Size ~= newSize then
            adorn.Size = newSize
        end
        if adorn.Color3 ~= getgenv().Config.InnerColor then
            adorn.Color3 = getgenv().Config.InnerColor
        end
        return
    end

    local adorn = Instance.new("BoxHandleAdornment")
    adorn.Name = "HitboxAdornment"
    adorn.Adornee = part
    adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    adorn.Color3 = getgenv().Config.InnerColor
    adorn.Transparency = 0.5
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 5
    adorn.Parent = workspace -- Parenting to workspace is less laggy than part sometimes

    adornments[part] = adorn
end

local function isPlayerRelevant(player)
    local char = player.Character
    if not char then return false end
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if not part then return false end

    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local distance = (part.Position - hrp.Position).Magnitude
    if distance > getgenv().Config.MaxDistance then
        return false
    end

    return true -- Removed the onScreen check for reliability
end

local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if part then
        applyAdornmentToPart(part)
    end
end

local function clearAllAdornments()
    for part, _ in pairs(adornments) do
        clearAdornment(part)
    end
    adornments = {}
end

local function updateHitboxes()
    if not getgenv().Config.Enabled then
        clearAllAdornments()
        return
    end

    local players = Players:GetPlayers()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local activeParts = {}

    for _, player in ipairs(players) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= getgenv().Config.MaxDistance then
                    applyAdornmentToPart(part)
                    activeParts[part] = true
                else
                    clearAdornment(part)
                end
            end
        end
    end

    -- Clear adornments for parts no longer valid
    for part, adorn in pairs(adornments) do
        if not activeParts[part] then
            clearAdornment(part)
        end
    end
end

-- Player/Character connections
local function onCharacterAdded(char)
    task.wait(0.5)
    if getgenv().Config.Enabled then
        updateHitboxes()
    end
end

local function onPlayerAdded(player)
    if player == lp then return end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Heartbeat update (throttled)
RunService.Heartbeat:Connect(function(dt)
    if not getgenv().Config.Enabled then return end
    accumulatedTime = accumulatedTime + dt
    if accumulatedTime >= updateInterval then
        accumulatedTime = 0
        updateHitboxes()
    end
end)

-- Toggle hitboxes with [H]
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
    getgenv().Config.Enabled = state
    if state then
        updateHitboxes()
    else
        clearAllAdornments()
    end
end)
