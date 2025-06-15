-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Da Hood Universal Hitbox UI", "DarkTheme")
local Tab = Window:NewTab("Hitbox")
local Section = Tab:NewSection("Hitbox Controls")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer

getgenv().Config = {
    Size = 10,
    Color = Color3.fromRGB(170, 0, 255),
    Enabled = false,
    AutoRefresh = true,
}

local hitboxes = {}

local function createHitboxForCharacter(character)
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    -- Remove existing hitbox if any
    if hitboxes[character] and hitboxes[character].Parent then
        hitboxes[character]:Destroy()
        hitboxes[character] = nil
    end

    -- Create a new invisible hitbox part
    local hitbox = Instance.new("Part")
    hitbox.Name = "UniversalHitbox"
    hitbox.Transparency = 0.5
    hitbox.CanCollide = false
    hitbox.Anchored = false
    hitbox.Size = Vector3.new(getgenv().Config.Size, getgenv().Config.Size, getgenv().Config.Size)
    hitbox.Color = getgenv().Config.Color
    hitbox.Material = Enum.Material.Neon
    hitbox.Parent = workspace

    -- Attach to HumanoidRootPart with WeldConstraint
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox

    -- Position hitbox exactly on rootPart
    hitbox.CFrame = rootPart.CFrame

    hitboxes[character] = hitbox
end

local function removeHitboxForCharacter(character)
    if hitboxes[character] then
        hitboxes[character]:Destroy()
        hitboxes[character] = nil
    end
end

local function updateAllHitboxes()
    if not getgenv().Config.Enabled then
        -- Remove all
        for character, hitbox in pairs(hitboxes) do
            if hitbox then
                hitbox:Destroy()
            end
        end
        hitboxes = {}
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            createHitboxForCharacter(player.Character)
        end
    end
end

local function setupCharacterListeners(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if getgenv().Config.Enabled then
            createHitboxForCharacter(char)
        end
    end)

    player.CharacterRemoving:Connect(function(char)
        removeHitboxForCharacter(char)
    end)
end

-- Setup for existing players
for _, player in pairs(Players:GetPlayers()) do
    setupCharacterListeners(player)
end
Players.PlayerAdded:Connect(setupCharacterListeners)
Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        removeHitboxForCharacter(player.Character)
    end
end)

-- Auto refresh hitboxes periodically
RunService.Heartbeat:Connect(function(dt)
    if getgenv().Config.Enabled and getgenv().Config.AutoRefresh then
        updateAllHitboxes()
    end
end)

-- Toggle with H key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        getgenv().Config.Enabled = not getgenv().Config.Enabled
        if getgenv().Config.Enabled then
            updateAllHitboxes()
            print("[Hitbox] Enabled")
        else
            for _, hitbox in pairs(hitboxes) do
                if hitbox then hitbox:Destroy() end
            end
            hitboxes = {}
            print("[Hitbox] Disabled")
        end
    end
end)

-- UI Controls
Section:NewLabel("Toggle Hitbox: [H]")
Section:NewSlider("Hitbox Size", "Adjust hitbox size", 50, 1, function(value)
    getgenv().Config.Size = value
    if getgenv().Config.Enabled then
        updateAllHitboxes()
    end
end)
Section:NewColorPicker("Hitbox Color", "Set hitbox color", getgenv().Config.Color, function(color)
    getgenv().Config.Color = color
    if getgenv().Config.Enabled then
        updateAllHitboxes()
    end
end)
Section:NewToggle("Auto Refresh", "Keep hitboxes updated", function(state)
    getgenv().Config.AutoRefresh = state
    if state then
        getgenv().Config.Enabled = true
        updateAllHitboxes()
    else
        for _, hitbox in pairs(hitboxes) do
            if hitbox then hitbox:Destroy() end
        end
        hitboxes = {}
    end
end)

-- Start enabled by default
getgenv().Config.Enabled = true
getgenv().Config.AutoRefresh = true
updateAllHitboxes()
