-- Evade Legacy X9 - Infinite crouch
-- Keeps the game's original Crouch keybind pressed while enabled.
-- The original in-game Crouch button is the only toggle; no custom GUI/animation.

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

    -- Toggle using the game's original Crouch button.
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

-- Re-assert the held state every frame so emotes/canceling emotes
-- cannot leave the game's Crouch keybind released while the toggle is on.
RunService.Heartbeat:Connect(function()
    if enabled then
        setCrouchHeld(true)
    end
end)

-- The heartbeat continues across respawns; reapply once when the new character appears.
player.CharacterAdded:Connect(function()
    task.defer(function()
        if enabled then
            setCrouchHeld(true)
        end
    end)
end)
