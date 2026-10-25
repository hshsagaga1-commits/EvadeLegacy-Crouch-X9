-- Evade Legacy X9 - Infinite crouch (frame check)
-- Uses the same animation method as the known working CrouchX9.lua,
-- but checks every Heartbeat instead of waiting 0.06 seconds.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")
local CROUCH_ANIMATION_ID = "9224101460"

-- Remove an old status indicator if the script is re-executed.
pcall(function()
    local old = playerGui:FindFirstChild("X9CrouchStatus")
    if old then old:Destroy() end
end)

local statusGui = Instance.new("ScreenGui")
statusGui.Name = "X9CrouchStatus"
statusGui.ResetOnSpawn = false
statusGui.DisplayOrder = 999
statusGui.Parent = playerGui

local statusButton = Instance.new("TextButton")
statusButton.Name = "StatusButton"
statusButton.Size = UDim2.new(0, 250, 0, 44)
statusButton.Position = UDim2.new(0.5, -125, 0.08, 0)
statusButton.BackgroundColor3 = Color3.fromRGB(35, 145, 75)
statusButton.TextColor3 = Color3.new(1, 1, 1)
statusButton.Text = "Script deu certo, tente usar"
statusButton.TextSize = 16
statusButton.Font = Enum.Font.GothamBold
statusButton.Parent = statusGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = statusButton

statusButton.Activated:Connect(function()
    statusGui:Destroy()
end)

local crouchEnabled = nil
local crouchAnimation
local forcedTrack
local forcedAnimator
local connectedButtons = setmetatable({}, { __mode = "k" })

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
    local ok, tracks = pcall(function()
        return animator:GetPlayingAnimationTracks()
    end)
    if not ok then return nil end
    for _, track in ipairs(tracks) do
        if animationNumber(track) == CROUCH_ANIMATION_ID then
            return track
        end
    end
    return nil
end

local function stopCrouchTracks()
    local animator = getAnimator()
    if animator then
        local ok, tracks = pcall(function()
            return animator:GetPlayingAnimationTracks()
        end)
        if ok then
            for _, track in ipairs(tracks) do
                if animationNumber(track) == CROUCH_ANIMATION_ID then
                    pcall(function() track:Stop(0) end)
                end
            end
        end
    end
    if forcedTrack then
        pcall(function() forcedTrack:Stop(0) end)
    end
end

local function playCrouch()
    local animator = getAnimator()
    if not animator then return end

    if forcedTrack and forcedAnimator == animator then
        if not forcedTrack.IsPlaying then
            pcall(function() forcedTrack:Play(0, 1, 1) end)
        end
        return
    end

    pcall(function()
        if forcedTrack then forcedTrack:Stop(0) end
    end)

    if not crouchAnimation then
        crouchAnimation = Instance.new("Animation")
        crouchAnimation.Name = "X9InfiniteCrouch"
        crouchAnimation.AnimationId = "rbxassetid://" .. CROUCH_ANIMATION_ID
    end

    local ok, track = pcall(function()
        return animator:LoadAnimation(crouchAnimation)
    end)
    if not ok or not track then return end

    forcedTrack = track
    forcedAnimator = animator
    forcedTrack.Looped = true
    pcall(function()
        forcedTrack.Priority = Enum.AnimationPriority.Action
    end)
    pcall(function()
        forcedTrack:Play(0, 1, 1)
    end)
end

local function connectCrouchButton(obj)
    if not obj:IsA("GuiButton") or obj.Name ~= "Crouch" or connectedButtons[obj] then
        return
    end
    connectedButtons[obj] = true

    obj.Activated:Connect(function()
        if crouchEnabled == nil then
            crouchEnabled = getCrouchTrack() ~= nil
        end
        crouchEnabled = not crouchEnabled
        if crouchEnabled then
            playCrouch()
        else
            stopCrouchTracks()
        end
    end)
end

for _, obj in ipairs(playerGui:GetDescendants()) do
    connectCrouchButton(obj)
end

playerGui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then
            connectCrouchButton(obj)
        end
    end)
end)

player.CharacterAdded:Connect(function()
    if forcedTrack then
        pcall(function() forcedTrack:Stop(0) end)
    end
    forcedTrack = nil
    forcedAnimator = nil
end)

-- No task.wait(0.06): check each frame while enabled.
RunService.Heartbeat:Connect(function()
    if crouchEnabled and not getCrouchTrack() then
        playCrouch()
    end
end)
