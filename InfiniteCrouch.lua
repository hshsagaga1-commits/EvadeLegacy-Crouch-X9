-- Evade Legacy X9 - Infinite Crouch (mobile)
-- No diagnostic panel. Uses the game's existing Crouch button as the toggle.
-- This forces the crouch animation; actual movement state may still be controlled by the game.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end

local pg = player:WaitForChild("PlayerGui")
local CROUCH_ANIMATION_ID = "9224101460"

local crouchEnabled = nil
local crouchAnimation
local forcedTrack
local forcedAnimator
local connectedButtons = {}
local running = true

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
                    pcall(function() track:Stop(0.1) end)
                end
            end
        end
    end
    if forcedTrack then
        pcall(function() forcedTrack:Stop(0.1) end)
    end
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
        forcedTrack:Play(0.08, 1, 1)
    end)
end

local function connectCrouchButton(obj)
    if connectedButtons[obj] then return end
    connectedButtons[obj] = true

    obj.Activated:Connect(function()
        if crouchEnabled == nil then
            crouchEnabled = getCrouchTrack() ~= nil
        end
        crouchEnabled = not crouchEnabled
        if not crouchEnabled then
            stopCrouchTracks()
        else
            playCrouch()
        end
    end)
end

local function inspect(obj)
    if obj:IsA("GuiButton") and obj.Name == "Crouch" then
        connectCrouchButton(obj)
    end
end

for _, obj in ipairs(pg:GetDescendants()) do
    inspect(obj)
end

pg.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then inspect(obj) end
    end)
end)

player.CharacterAdded:Connect(function()
    if forcedTrack then
        pcall(function() forcedTrack:Stop(0) end)
    end
    forcedTrack = nil
    forcedAnimator = nil
    -- Keep crouchEnabled across respawns; the loop will restore it on the new character.
end)

task.spawn(function()
    local deadline = os.clock() + 3
    repeat
        if getAnimator() then break end
        task.wait(0.1)
    until os.clock() >= deadline

    if crouchEnabled == nil then
        crouchEnabled = getCrouchTrack() ~= nil
    end

    while running do
        if crouchEnabled then
            -- Restore it even if an emote or another animation replaces the crouch track.
            if not getCrouchTrack() then
                playCrouch()
            end
        end
        task.wait(0.06)
    end
end)
