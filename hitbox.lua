-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal Hitbox UI", "DarkTheme")

-- Tabs and Sections
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

-- Services
local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Config
getgenv().Config = {
    Size = 5,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false,
}

-- Table to track adornments so we can clean up easily
local adornments = {}

local function clearHitboxes()
    for _, adorn in pairs(adornments) do
        if adorn and adorn.Parent then
            adorn:Destroy()
        end
    end
    adornments = {}
end

local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if part and part:IsA("BasePart") then
        -- Remove old adornment if exists
        if adornments[part] and adornments[part].Parent then
            adornments[part]:Destroy()
            adornments[part] = nil
        end

        -- Create new adornment
        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Name = "HitboxAdornment"
        adorn.Adornee = part
        adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
        adorn.Color3 = getgenv().Config.InnerColor
        adorn.Transparency = 0.5
        adorn.ZIndex = 5
        adorn.AlwaysOnTop = true
        adorn.Parent = CoreGui -- Parent to CoreGui to prevent removal on character changes

        adornments[part] = adorn
    end
end

local function applyHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            applyHitboxToCharacter(player.Character)
        end
    end
end

-- Listen for new characters loading and apply hitboxes immediately
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if getgenv().Config.Enabled then
            -- small delay to ensure parts exist
            task.wait(0.1)
            applyHitboxToCharacter(char)
        end
    end)
end)

-- For existing players, bind CharacterAdded
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(char)
        if getgenv().Config.Enabled then
            task.wait(0.1)
            applyHitboxToCharacter(char)
        end
    end)
end

-- Keybind Toggle (H)
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

-- Auto refresh loop
task.spawn(function()
    while true do
        if getgenv().Config.Enabled then
            applyHitboxes()
        else
            clearHitboxes()
        end
        task.wait(1.5)
    end
end)

-- UI
Section:NewLabel("Toggle Hitbox: [H]")

Section:NewSlider("Hitbox Size", "Adjust hitbox size", 50, 1, function(v)
    getgenv().Config.Size = v
    if getgenv().Config.Enabled then applyHitboxes() end
end)

Section:NewColorPicker("Hitbox Color", "Set the hitbox color", getgenv().Config.InnerColor, function(c)
    getgenv().Config.InnerColor = c
    if getgenv().Config.Enabled then applyHitboxes() end
end)

Section:NewDropdown("Hitpart", "Choose body part", {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, function(v)
    getgenv().Config.Hitpart = v
    if getgenv().Config.Enabled then applyHitboxes() end
end)

Section:NewButton("Apply Manually", "Apply hitboxes right now", function()
    applyHitboxes()
end)

Section:NewToggle("Auto Refresh", "Keep hitboxes updated", function(state)
    getgenv().Config.Enabled = state
end)
