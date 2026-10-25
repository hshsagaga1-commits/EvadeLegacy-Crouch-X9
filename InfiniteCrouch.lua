-- Evade Legacy X9 - Infinite crouch
-- Keeps the game's original Crouch keybind in its pressed state.
-- No custom GUI and no replacement animation.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")
local events = playerScripts:WaitForChild("Events", 10)
local keybindUsed = events and events:WaitForChild("KeybindUsed", 10)

if not keybindUsed or not keybindUsed:IsA("BindableEvent") then
    warn("[X9] KeybindUsed event not found")
    return
end

local enabled = false
local hooked = setmetatable({}, { __mode = "k" })

local function setCrouchHeld(held)
    pcall(function()
        keybindUsed:Fire("Crouch", held)
    end)
end

local function hookButton(obj)
    if not obj:IsA("GuiButton") or obj.Name ~= "Crouch" or hooked[obj] then
        return
    end
    hooked[obj] = true

    -- The original game button remains the only toggle.
    obj.Activated:Connect(function()
        enabled = not enabled
        setCrouchHeld(enabled)
    end)
end

for _, obj in ipairs(playerGui:GetDescendants()) do
    hookButton(obj)
end

playerGui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then
            hookButton(obj)
        end
    end)
end)

-- Re-assert once after respawn, not every frame (which can spam the keybind).
player.CharacterAdded:Connect(function()
    task.delay(0.6, function()
        if enabled then
            setCrouchHeld(true)
        end
    end)
end)

-- If the game recreates its GUI after respawn, preserve the held state.
playerGui.DescendantAdded:Connect(function(obj)
    if enabled and obj.Name == "Crouch" and obj:IsA("GuiButton") then
        task.defer(function()
            if enabled then setCrouchHeld(true) end
        end)
    end
end)
