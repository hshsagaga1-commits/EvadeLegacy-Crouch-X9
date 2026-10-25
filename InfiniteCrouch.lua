-- Evade Legacy X9 - Infinite crouch
-- Uses the game's own KeybindUsed event; no custom GUI or animation replacement.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
local hooked = setmetatable({}, {__mode = "k"})

local function connectButton(obj)
    if not obj:IsA("GuiButton") or obj.Name ~= "Crouch" or hooked[obj] then return end
    hooked[obj] = true

    -- The game's own button still handles the normal crouch toggle.
    -- This only tracks whether the user wants crouch held continuously.
    obj.Activated:Connect(function()
        enabled = not enabled
        if not enabled then
            pcall(function() keybindUsed:Fire("Crouch", false) end)
        else
            pcall(function() keybindUsed:Fire("Crouch", true) end)
        end
    end)
end

for _, obj in ipairs(playerGui:GetDescendants()) do
    connectButton(obj)
end

playerGui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then connectButton(obj) end
    end)
end)

-- Re-send the original game's crouch input while enabled, including after respawn
-- and when an emote interrupts the held input.
RunService.Heartbeat:Connect(function()
    if enabled then
        pcall(function() keybindUsed:Fire("Crouch", true) end)
    end
end)

player.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        if enabled then
            pcall(function() keybindUsed:Fire("Crouch", true) end)
        end
    end)
end)
