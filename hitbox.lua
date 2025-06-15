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

-- Clear hitbox
local function clearHitboxOnPart(part)
    if part then
        local adorn = part:FindFirstChild("HitboxAdornment")
        if adorn then
            adorn:Destroy()
        end
        part.CanCollide = true
        part.Massless = false
        part.Size = Vector3.new(2, 1, 1)
    end
end

-- Apply hitbox using CFrame preserving
local function applyHitboxToPart(part)
    if not part then return end
    clearHitboxOnPart(part)

    local oldCFrame = part.CFrame
    part.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    part.CFrame = oldCFrame
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

-- Apply to a character
local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if not part then return end
    applyHitboxToPart(part)
end

-- Clear all hitboxes
local function clearHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            clearHitboxOnPart(part)
        end
    end
end

-- Apply to all players
local function applyHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            applyHitboxToCharacter(player.Character)
        end
    end
end

-- Handle new player
local function onCharacterAdded(char)
    task.wait(1)
    if getgenv().Config.Enabled then
        applyHitboxToCharacter(char)
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Setup existing and future players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= lp then
        if p.Character then onCharacterAdded(p.Character) end
        onPlayerAdded(p)
    end
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Auto refresh (live updates)
RunService.RenderStepped:Connect(function()
    if getgenv().Config.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
                if part and (not adornments[part] or part.Size.X ~= getgenv().Config.Size) then
                    applyHitboxToPart(part)
                elseif adornments[part] then
                    adornments[part].Color3 = getgenv().Config.InnerColor
                end
            end
        end
    end
end)

-- Key toggle
uis.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.H then
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

-- UI Controls
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
    if not state then
        clearHitboxes()
    else
        applyHitboxes()
    end
end)
