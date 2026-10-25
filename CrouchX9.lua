-- Evade Legacy X9 Mobile Diagnostic
-- Draggable panel, report copy with manual-copy fallback.
-- Diagnostic only: does not modify the game's crouch behavior.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end
local pg = player:WaitForChild("PlayerGui")

pcall(function()
    local old = pg:FindFirstChild("X9MobilePanel")
    if old then old:Destroy() end
end)

local logs, watched = {}, {}
local running = true
local MAX_LOGS = 220

local function log(message)
    table.insert(logs, os.date("%H:%M:%S") .. " | " .. tostring(message))
    if #logs > MAX_LOGS then table.remove(logs, 1) end
end

local gui = Instance.new("ScreenGui")
gui.Name = "X9MobilePanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 290, 0, 220)
panel.Position = UDim2.new(0.5, -145, 0.25, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Name = "DragTitle"
title.Size = UDim2.new(1, -12, 0, 32)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "X9 MOBILE  •  ARRASTE AQUI"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = panel
title.Active = true

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 36)
status.Position = UDim2.new(0, 8, 0, 36)
status.BackgroundTransparency = 1
status.Text = "1) Agache  2) Faça o emote  3) Copie o relatório"
status.TextColor3 = Color3.fromRGB(195, 205, 220)
status.TextWrapped = true
status.TextSize = 11
status.Parent = panel

local function makeButton(name, text, y, color, callback)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -16, 0, 32)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Activated:Connect(callback)
    return b
end

local reportBox
local function buildReport()
    local out = {
        "X9 MOBILE REPORT",
        "PlaceId=" .. tostring(game.PlaceId),
        "TouchEnabled=" .. tostring(UIS.TouchEnabled),
        "---- events ----"
    }
    for _, line in ipairs(logs) do table.insert(out, line) end
    return table.concat(out, "\n")
end

local function showReportBox(text)
    if not reportBox then
        reportBox = Instance.new("TextBox")
        reportBox.Name = "ReportBox"
        reportBox.Position = UDim2.new(0, 8, 1, 8)
        reportBox.Size = UDim2.new(0, 274, 0, 155)
        reportBox.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
        reportBox.TextColor3 = Color3.new(1, 1, 1)
        reportBox.PlaceholderText = "Selecione o texto e copie..."
        reportBox.TextSize = 10
        reportBox.Font = Enum.Font.Code
        reportBox.TextXAlignment = Enum.TextXAlignment.Left
        reportBox.TextYAlignment = Enum.TextYAlignment.Top
        reportBox.TextWrapped = false
        reportBox.MultiLine = true
        reportBox.ClearTextOnFocus = false
        reportBox.TextEditable = true
        reportBox.Parent = panel
        panel.Size = UDim2.new(0, 290, 0, 395)
    end
    reportBox.Text = text
    reportBox:CaptureFocus()
    status.Text = "Se não copiar automaticamente, selecione o texto abaixo e copie."
end

local function copyReport()
    local data = buildReport()
    local copied = false
    for _, fnName in ipairs({"setclipboard", "toclipboard", "writeclipboard"}) do
        local fn = nil
        pcall(function() fn = getgenv and getgenv()[fnName] end)
        if type(fn) ~= "function" then
            pcall(function() fn = _G[fnName] end)
        end
        if type(fn) == "function" then
            local ok = pcall(fn, data)
            if ok then copied = true break end
        end
    end
    if copied then
        status.Text = "Relatório copiado! Cole aqui na conversa."
        log("REPORT_COPIED")
    else
        status.Text = "Delta sem cópia automática; abra a caixa e copie manualmente."
        showReportBox(data)
    end
end

-- Crouch persistence: restore the crouch animation after an emote ends.
-- This preserves the animation; the game may still override actual movement state.
local CROUCH_ANIMATION_ID = "9224101460"
local EMOTE_ANIMATION_IDS = {
    ["8734712302"] = true,
    ["8734713502"] = true,
    ["8734714115"] = true,
    ["8734717021"] = true,
}
local crouchEnabled = nil
local crouchAnimation, forcedCrouchTrack
local crouchButtonConnected = {}

local function getAnimator()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        pcall(function() animator = hum:WaitForChild("Animator", 1) end)
    end
    return animator
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
    if ok then
        for _, track in ipairs(tracks) do
            if animationNumber(track) == CROUCH_ANIMATION_ID then return track end
        end
    end
    return nil
end

local function emoteIsPlaying()
    local animator = getAnimator()
    if not animator then return false end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok then return false end
    for _, track in ipairs(tracks) do
        if EMOTE_ANIMATION_IDS[animationNumber(track)] then return true end
    end
    return false
end

local function prepareCrouchTrack()
    local animator = getAnimator()
    if not animator then return nil end
    if forcedCrouchTrack and forcedCrouchTrack.Parent == animator then
        return forcedCrouchTrack
    end
    pcall(function() if forcedCrouchTrack then forcedCrouchTrack:Stop(0) end end)
    if not crouchAnimation then
        crouchAnimation = Instance.new("Animation")
        crouchAnimation.Name = "X9CrouchAnimation"
        crouchAnimation.AnimationId = "rbxassetid://" .. CROUCH_ANIMATION_ID
    end
    local ok, track = pcall(function() return animator:LoadAnimation(crouchAnimation) end)
    if not ok then
        log("CROUCH_LOAD_FAILED " .. tostring(track))
        return nil
    end
    forcedCrouchTrack = track
    forcedCrouchTrack.Looped = true
    pcall(function() forcedCrouchTrack.Priority = Enum.AnimationPriority.Action end)
    return forcedCrouchTrack
end

local function stopCrouchTracks()
    local animator = getAnimator()
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok then
            for _, track in ipairs(tracks) do
                if animationNumber(track) == CROUCH_ANIMATION_ID then
                    pcall(function() track:Stop(0.12) end)
                end
            end
        end
    end
    if forcedCrouchTrack then pcall(function() forcedCrouchTrack:Stop(0.12) end) end
end

local function connectCrouchButton(obj)
    if crouchButtonConnected[obj] then return end
    crouchButtonConnected[obj] = true
    obj.Activated:Connect(function()
        if crouchEnabled == nil then crouchEnabled = getCrouchTrack() ~= nil end
        crouchEnabled = not crouchEnabled
        log("CROUCH_LOCK=" .. tostring(crouchEnabled))
        if not crouchEnabled then stopCrouchTracks() end
    end)
end

local function watch(obj)
    if not obj:IsA("GuiButton") or watched[obj] then return end
    watched[obj] = true
    log("BUTTON_FOUND " .. obj.Name .. " | " .. obj:GetFullName())
    if obj.Name == "Crouch" then connectCrouchButton(obj) end
    obj.Activated:Connect(function()
        log("BUTTON_ACTIVATED " .. obj.Name)
    end)
    obj.InputBegan:Connect(function(input)
        log("BUTTON_INPUT_BEGIN " .. obj.Name .. " | " .. tostring(input.UserInputType))
    end)
    obj.InputEnded:Connect(function(input)
        log("BUTTON_INPUT_END " .. obj.Name .. " | " .. tostring(input.UserInputType))
    end)
    obj:GetPropertyChangedSignal("Visible"):Connect(function()
        log("BUTTON_VISIBLE " .. obj.Name .. "=" .. tostring(obj.Visible))
    end)
    obj:GetPropertyChangedSignal("Active"):Connect(function()
        log("BUTTON_ACTIVE " .. obj.Name .. "=" .. tostring(obj.Active))
    end)
end

local function scan()
    local count = 0
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("GuiButton") then
            count += 1
            pcall(watch, obj)
        end
    end
    log("SCAN_COMPLETE count=" .. tostring(count))
    status.Text = "Monitorando. Botões encontrados: " .. tostring(count)
end

makeButton("CopyReport", "COPIAR RELATÓRIO", 78, Color3.fromRGB(42, 115, 190), copyReport)
makeButton("Scan", "REESCANEAR BOTÕES", 116, Color3.fromRGB(65, 72, 86), scan)
makeButton("Close", "FECHAR PAINEL", 154, Color3.fromRGB(130, 58, 58), function()
    running = false
    gui:Destroy()
end)

-- Drag/move with touch or mouse using the title bar.
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

pg.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then pcall(watch, obj) end
    end)
end)

local lastAnimations = ""
task.spawn(function()
    while running and gui.Parent do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        local ids = {}
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok then
                for _, track in ipairs(tracks) do
                    local id = "?"
                    pcall(function()
                        if track.Animation then id = track.Animation.AnimationId end
                    end)
                    table.insert(ids, id)
                end
            end
        end
        table.sort(ids)
        local joined = table.concat(ids, ",")
        if joined ~= lastAnimations then
            lastAnimations = joined
            log("ANIMATIONS " .. joined)
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    local deadline = os.clock() + 3
    repeat
        if getAnimator() then break end
        task.wait(0.1)
    until os.clock() >= deadline
    if crouchEnabled == nil then crouchEnabled = getCrouchTrack() ~= nil end
    log("CROUCH_INITIAL=" .. tostring(crouchEnabled))
    while running and gui.Parent do
        if crouchEnabled and not emoteIsPlaying() and not getCrouchTrack() then
            local track = prepareCrouchTrack()
            if track then
                pcall(function() track:Play(0.12, 1, 1) end)
                log("CROUCH_ANIMATION_RESTORED")
            end
        end
        task.wait(0.12)
    end
end)

log("STARTED touch=" .. tostring(UIS.TouchEnabled))
scan()
