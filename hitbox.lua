-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal Hitbox UI", "DarkTheme")

-- Tabs and Sections
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

-- Services
local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Config
getgenv().Config = {
    Size = 5, -- Minimum is now lower
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false
}

-- Clear previous hitboxes
local function clearHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            if part and part:IsA("BasePart") then
                local adorn = part:FindFirstChild("HitboxAdornment")
                if adorn then adorn:Destroy() end
                part.Size = Vector3.new(2, 1, 1) -- reset to default-safe size
                part.CanCollide = true
                part.Massless = false
            end
        end
    end
end

-- Apply hitbox to a character
local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if part and part:IsA("BasePart") then
        local existing = part:FindFirstChild("HitboxAdornment")
        if existing then existing:Destroy() end

        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Name = "HitboxAdornment"
        adorn.Adornee = part
        adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
        adorn.Color3 = getgenv().Config.InnerColor
        adorn.Transparency = 0.5
        adorn.ZIndex = 5
        adorn.AlwaysOnTop = true
        adorn.Parent = part

        part.Size = adorn.Size
        part.CanCollide = false
        part.Massless = true
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
