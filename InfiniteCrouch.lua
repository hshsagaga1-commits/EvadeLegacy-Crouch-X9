-- Evade Legacy X9 - Crouch GUI + Infinite Crouch
-- Based on the public Legacy Evade GUI's local KeybindUsed event.
-- The lock keeps the crouch animation playing; the game's internal movement state may override it.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local CROUCH_ANIMATION_ID = "9224101460"
local crouchEnabled = false
local crouchAnimation
local forcedTrack
local forcedAnimator
local connectedButtons = {}
local lastCharacter = nil

-- Remove this script's previous GUI if the loader is run more than once.
local oldGui = playerGui:FindFirstChild("X9InfiniteCrouchGui")
if oldGui then oldGui:Destroy() end

local function fireGameCrouch()
    local scripts = player:FindFirstChild("PlayerScripts")
    local events = scripts and scripts:FindFirstChild("Events")
    local keybindUsed = events and events:FindFirstChild("KeybindUsed")
    if keybindUsed and keybindUsed:IsA("BindableEvent") then
        -- This is the local keybind event used by the public Legacy Evade GUI.
        pcall(function() keybindUsed:Fire("Crouch", true) end)
        return true
    end
    return false
end

local function getAnimator()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    return humanoid:FindFirstChildOfClass("Animator")
end

local function animationNumber(track)
    local id = ""
    pcall(function()
        if track.Animation then id = track.Animation.AnimationId end
    end)
    return tostring(id):match("%d+")
end

local function getCrouchTrack()
    local animator = getAnimator()
    if not animator then return nil end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok then return nil end
    for _, track in ipairs(tracks) do
        if animationNumber(track) == CROUCH_ANIMATION_ID then return track end
    end
    return nil
end

local function stopCrouchTracks()
    local animator = getAnimator()
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok then
            for _, track in ipairs(tracks) do
                if animationNumber(track) == CROUCH_ANIMATION_ID then
                    pcall(function() track:Stop(0.1) end)
                end
            end
        end
    end
    if forcedTrack then pcall(function() forcedTrack:Stop(0.1) end) end
end

local function playCrouch()
    local animator = getAnimator()
    if not animator then return end
    if forcedTrack and forcedAnimator == animator then
        if not forcedTrack.IsPlaying then
            pcall(function() forcedTrack:Play(0.08, 1, 1) end)
        end
        return
    end
    pcall(function() if forcedTrack then forcedTrack:Stop(0) end end)
    if not crouchAnimation then
        crouchAnimation = Instance.new("Animation")
        crouchAnimation.Name = "X9InfiniteCrouch"
        crouchAnimation.AnimationId = "rbxassetid://" .. CROUCH_ANIMATION_ID
    end
    local ok, track = pcall(function() return animator:LoadAnimation(crouchAnimation) end)
    if not ok or not track then return end
    forcedTrack = track
    forcedAnimator = animator
    forcedTrack.Looped = true
    pcall(function() forcedTrack.Priority = Enum.AnimationPriority.Action end)
    pcall(function() forcedTrack:Play(0.08, 1, 1) end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "X9InfiniteCrouchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "CrouchToggle"
button.Size = UDim2.new(0, 112, 0, 44)
button.Position = UDim2.new(1, -132, 0.62, 0)
button.BackgroundColor3 = Color3.fromRGB(35, 105, 65)
button.TextColor3 = Color3.new(1, 1, 1)
button.Text = "CROUCH: OFF"
button.TextSize = 13
button.Font = Enum.Font.GothamBold
button.BorderSizePixel = 0
button.Active = true
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local function refreshButton()
    if crouchEnabled then
        button.Text = "CROUCH: ON"
        button.BackgroundColor3 = Color3.fromRGB(25, 145, 75)
    else
        button.Text = "CROUCH: OFF"
        button.BackgroundColor3 = Color3.fromRGB(35, 105, 65)
    end
end

button.Activated:Connect(function()
    crouchEnabled = not crouchEnabled
    if crouchEnabled then
        fireGameCrouch()
        playCrouch()
    else
        fireGameCrouch()
        stopCrouchTracks()
    end
    refreshButton()
end)

-- Make the button draggable on touch or mouse.
local dragging, dragInput, dragStart, startPos
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        button.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

player.CharacterAdded:Connect(function(character)
    if forcedTrack then pcall(function() forcedTrack:Stop(0) end) end
    forcedTrack = nil
    forcedAnimator = nil
    lastCharacter = character
    task.delay(0.8, function()
        if crouchEnabled and player.Character == character then
            fireGameCrouch()
            playCrouch()
        end
    end)
end)

task.spawn(function()
    while gui.Parent do
        if crouchEnabled and not getCrouchTrack() then
            playCrouch()
        end
        task.wait(0.06)
    end
end)

refreshButton()
