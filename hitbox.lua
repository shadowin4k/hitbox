-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal Hitbox UI", "DarkTheme")
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Configuration
getgenv().Config = {
    Size = 5,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false
}

local adornments = {}

-- Clears hitbox and resets part
local function clearHitboxOnPart(part)
    if not part then return end
    if adornments[part] then
        adornments[part]:Destroy()
        adornments[part] = nil
    end
    part.CanCollide = true
    part.Massless = false
    part.Size = Vector3.new(2, 1, 1)
end

-- Applies hitbox to part with preserved CFrame
local function applyHitboxToPart(part)
    if not part then return end

    clearHitboxOnPart(part)

    local oldCF = part.CFrame
    part.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    part.CFrame = oldCF
    part.CanCollide = false
    part.Massless = true

    local adorn = Instance.new("BoxHandleAdornment")
    adorn.Name = "HitboxAdornment"
    adorn.Adornee = part
    adorn.Size = part.Size
    adorn.Color3 = getgenv().Config.InnerColor
    adorn.Transparency = 0.5
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 5
    adorn.Parent = part

    adornments[part] = adorn
end

-- Applies hitbox to a character
local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if part then
        applyHitboxToPart(part)
    end
end

-- Clears all hitboxes
local function clearHitboxes()
    for part, _ in pairs(adornments) do
        if part then
            clearHitboxOnPart(part)
        end
    end
end

-- Applies to all players
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

-- Live update using RenderStepped
RunService.RenderStepped:Connect(function()
    if not getgenv().Config.Enabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            if part then
                local adorn = adornments[part]
                if not adorn or adorn.Size.X ~= getgenv().Config.Size then
                    applyHitboxToPart(part)
                elseif adorn then
                    adorn.Color3 = getgenv().Config.InnerColor
                end
            end
        end
    end
end)

-- Key toggle [H]
uis.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        getgenv().Config.Enabled = not getgenv().Config.Enabled
        if getgenv().Config.Enabled then
            applyHitboxes()
            print("[Hitbox] Enabled")
        else
            clearHitboxes()
            print("[Hitbox] Disabled")
        end
    end
end)

-- UI
Section:NewLabel("Toggle Hitbox: [H]")

Section:NewSlider("Hitbox Size", "Adjust hitbox size", 50, 1, function(v)
    getgenv().Config.Size = v
end)

Section:NewColorPicker("Hitbox Color", "Set the hitbox color", getgenv().Config.InnerColor, function(c)
    getgenv().Config.InnerColor = c
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
        clearHitboxes()
    end
end)
