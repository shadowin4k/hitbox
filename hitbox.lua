-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Universal Hitbox UI", "DarkTheme")

local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

getgenv().Config = {
    Size = 5,
    InnerColor = Color3.fromRGB(170, 0, 255),
    Hitpart = "Head",
    Enabled = false
}

-- Keep track of adornments to remove later
local adornments = {}

-- Clear hitbox on a specific character's part
local function clearHitboxOnPart(part)
    if not part then return end
    local adorn = part:FindFirstChild("HitboxAdornment")
    if adorn then
        adorn:Destroy()
    end
    -- Reset part properties
    part.Size = Vector3.new(2, 1, 1)
    part.CanCollide = true
    part.Massless = false
end

-- Clear all hitboxes on all players (except local)
local function clearHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local part = player.Character:FindFirstChild(getgenv().Config.Hitpart)
            clearHitboxOnPart(part)
        end
    end
    adornments = {}
end

-- Apply hitbox adornment to one character
local function applyHitboxToCharacter(char)
    local part = char:FindFirstChild(getgenv().Config.Hitpart)
    if not part then
        -- Wait for part to load if not present yet (helps on respawn)
        part = char:WaitForChild(getgenv().Config.Hitpart, 5)
        if not part then return end
    end

    -- Clear previous adornment
    clearHitboxOnPart(part)

    -- Create adornment
    local adorn = Instance.new("BoxHandleAdornment")
    adorn.Name = "HitboxAdornment"
    adorn.Adornee = part
    adorn.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    adorn.Color3 = getgenv().Config.InnerColor
    adorn.Transparency = 0.5
    adorn.ZIndex = 5
    adorn.AlwaysOnTop = true
    adorn.Parent = part

    -- Modify part size and properties
    part.Size = adorn.Size
    part.CanCollide = false
    part.Massless = true

    -- Store adornment so we can remove later
    adornments[part] = adorn
end

-- Apply hitboxes to all players
local function applyHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            applyHitboxToCharacter(player.Character)
        end
    end
end

-- Connect CharacterAdded event to reapply hitbox when players respawn
local function setupCharacterListener(player)
    player.CharacterAdded:Connect(function(char)
        -- Small delay to let character load parts
        task.wait(0.5)
        if getgenv().Config.Enabled then
            applyHitboxToCharacter(char)
        end
    end)
end

-- Setup listeners for all players, including future joins
for _, player in ipairs(Players:GetPlayers()) do
    setupCharacterListener(player)
end
Players.PlayerAdded:Connect(setupCharacterListener)

-- Toggle hitbox on/off with H key
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

-- Auto refresh loop (backup to keep hitboxes fresh)
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
