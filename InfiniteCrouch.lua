-- Evade Legacy X9 - Infinite crouch
-- No custom GUI. Uses the game's existing crouch button and crouch animation.
-- Animation lock only; the game may control the actual crouch movement state.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local CROUCH_ID = "9224101460"
local enabled = false
local track, animatorRef
local animation = Instance.new("Animation")
animation.Name = "X9InfiniteCrouch"
animation.AnimationId = "rbxassetid://" .. CROUCH_ID

local function animator()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:FindFirstChildOfClass("Animator")
end

local function idOf(t)
    local id = ""
    pcall(function() id = t.Animation.AnimationId end)
    return tostring(id):match("%d+")
end

local function findTrack()
    local a = animator()
    if not a then return nil end
    local ok, list = pcall(function() return a:GetPlayingAnimationTracks() end)
    if not ok then return nil end
    for _, t in ipairs(list) do
        if idOf(t) == CROUCH_ID then return t end
    end
end

local function stopTracks()
    local a = animator()
    if a then
        local ok, list = pcall(function() return a:GetPlayingAnimationTracks() end)
        if ok then
            for _, t in ipairs(list) do
                if idOf(t) == CROUCH_ID then pcall(function() t:Stop(0.1) end) end
            end
        end
    end
    if track then pcall(function() track:Stop(0.1) end) end
    track, animatorRef = nil, nil
end

local function play()
    local a = animator()
    if not a then return end
    if track and animatorRef == a then
        if not track.IsPlaying then pcall(function() track:Play(0.08, 1, 1) end) end
        return
    end
    if track then pcall(function() track:Stop(0) end) end
    local ok, t = pcall(function() return a:LoadAnimation(animation) end)
    if not ok or not t then return end
    track, animatorRef = t, a
    t.Looped = true
    pcall(function() t.Priority = Enum.AnimationPriority.Action end)
    pcall(function() t:Play(0.08, 1, 1) end)
end

local function connect(obj)
    if not obj:IsA("GuiButton") or obj.Name ~= "Crouch" or obj:GetAttribute("X9CrouchHooked") then return end
    obj:SetAttribute("X9CrouchHooked", true)
    obj.Activated:Connect(function()
        enabled = not enabled
        if enabled then
            play()
        else
            stopTracks()
        end
    end)
end

for _, obj in ipairs(playerGui:GetDescendants()) do connect(obj) end
playerGui.DescendantAdded:Connect(function(obj)
    task.defer(function() if obj.Parent then connect(obj) end end)
end)

player.CharacterAdded:Connect(function()
    if track then pcall(function() track:Stop(0) end) end
    track, animatorRef = nil, nil
    task.delay(0.7, function() if enabled then play() end end)
end)

task.spawn(function()
    while player.Parent do
        if enabled and not findTrack() then play() end
        task.wait(0.12)
    end
end)
