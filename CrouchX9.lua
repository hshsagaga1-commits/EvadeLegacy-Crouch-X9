-- Evade Legacy Crouch X9 - Diagnostic with visible report/copy UI
-- This script only observes UI and animations. It does NOT change crouch behavior.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
if not player then warn("[X9] LocalPlayer not found"); return end

local report = {}
local MAX_LINES = 350
local function log(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    local line = os.date("%H:%M:%S") .. " | " .. table.concat(parts, " ")
    table.insert(report, line)
    if #report > MAX_LINES then table.remove(report, 1) end
    print("[X9] " .. table.concat(parts, " "))
end

local function pathOf(obj)
    local ok, result = pcall(function() return obj:GetFullName() end)
    return ok and result or tostring(obj.Name)
end

-- Visible panel so the user can copy a report without opening the executor console.
local gui = Instance.new("ScreenGui")
gui.Name = "EvadeLegacyCrouchX9Report"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
local guiParent
pcall(function() guiParent = gethui() end)
if not guiParent then
    local ok = pcall(function() guiParent = CoreGui end)
    if not ok or not guiParent then guiParent = player:WaitForChild("PlayerGui") end
end
local parentOk = pcall(function() gui.Parent = guiParent end)
if not parentOk then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 280, 0, 154)
panel.Position = UDim2.new(0, 14, 0.5, -77)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = panel
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(90, 100, 120); stroke.Thickness = 1; stroke.Parent = panel

local function makeLabel(name, text, pos, size, font, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = pos
    label.Size = size
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 242, 247)
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = panel
    return label
end
makeLabel("Title", "Evade Legacy • X9", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 24), Enum.Font.GothamBold, 16)
local status = makeLabel("Status", "Diagnóstico ativo. Reproduza o bug e copie o relatório.", UDim2.new(0, 12, 0, 35), UDim2.new(1, -24, 0, 34), Enum.Font.Gotham, 11)
status.TextColor3 = Color3.fromRGB(190, 200, 215)
local function makeButton(name, text, pos, size, color)
    local b = Instance.new("TextButton")
    b.Name = name; b.Text = text; b.Position = pos; b.Size = size
    b.BackgroundColor3 = color; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.BorderSizePixel = 0
    b.AutoButtonColor = true; b.Parent = panel
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = b
    return b
end
local copyButton = makeButton("CopyReport", "COPIAR RELATÓRIO", UDim2.new(0, 12, 0, 78), UDim2.new(1, -24, 0, 32), Color3.fromRGB(44, 112, 190))
local scanButton = makeButton("Rescan", "REESCANEAR BOTÕES", UDim2.new(0, 12, 0, 116), UDim2.new(0.58, -8, 0, 26), Color3.fromRGB(65, 72, 86))
local closeButton = makeButton("Close", "FECHAR", UDim2.new(0.62, 0, 0, 116), UDim2.new(0.34, -8, 0, 26), Color3.fromRGB(130, 58, 58))

local seenButtons = setmetatable({}, {__mode = "k"})
local lastVisible = setmetatable({}, {__mode = "k"})

local function getReport()
    local header = {
        "Evade Legacy Crouch X9 report",
        "PlaceId=" .. tostring(game.PlaceId),
        "JobId=" .. tostring(game.JobId),
        "PlatformTouch=" .. tostring(UserInputService.TouchEnabled),
        "Buttons observed=" .. tostring((function() local n=0 for _ in pairs(seenButtons) do n=n+1 end return n end)()),
        "---- events ----"
    }
    for _, line in ipairs(report) do table.insert(header, line) end
    return table.concat(header, "\n")
end
local function copyReport()
    local data = getReport()
    local copied, method = false, ""
    if type(setclipboard) == "function" then
        copied = pcall(setclipboard, data); method = "setclipboard"
    end
    if not copied and type(toclipboard) == "function" then
        copied = pcall(toclipboard, data); method = "toclipboard"
    end
    if not copied and type(writeclipboard) == "function" then
        copied = pcall(writeclipboard, data); method = "writeclipboard"
    end
    if copied then
        status.Text = "Relatório copiado! Cole aqui na conversa."
        log("REPORT_COPIED via " .. method)
    else
        status.Text = "Executor sem clipboard. O relatório será mostrado na caixa abaixo."
        local box = panel:FindFirstChild("ReportBox")
        if not box then
            box = Instance.new("TextBox")
            box.Name = "ReportBox"
            box.Position = UDim2.new(0, 8, 1, 8)
            box.Size = UDim2.new(1, -16, 0, 120)
            box.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
            box.TextColor3 = Color3.fromRGB(240, 242, 247)
            box.TextSize = 10
            box.Font = Enum.Font.Code
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.TextYAlignment = Enum.TextYAlignment.Top
            box.TextWrapped = false
            box.ClearTextOnFocus = false
            box.MultiLine = true
            box.Parent = panel
            panel.Size = UDim2.new(0, 280, 0, 282)
        end
        box.Text = data
        box:CaptureFocus()
        box.CursorPosition = 1
    end
end

local function describeButton(button, eventName, input)
    local extra = ""
    if input then
        pcall(function() extra = " input=" .. tostring(input.UserInputType) .. " key=" .. tostring(input.KeyCode) end)
    end
    log("BUTTON", eventName, "name=" .. button.Name, "path=" .. pathOf(button),
        "visible=" .. tostring(button.Visible), "active=" .. tostring(button.Active), extra)
end
local function watchButton(obj)
    if not obj:IsA("GuiButton") or seenButtons[obj] then return end
    seenButtons[obj] = true
    lastVisible[obj] = obj.Visible
    log("FOUND_BUTTON", "name=" .. obj.Name, "path=" .. pathOf(obj),
        "visible=" .. tostring(obj.Visible), "active=" .. tostring(obj.Active))
    obj.Activated:Connect(function() describeButton(obj, "Activated") end)
    obj.InputBegan:Connect(function(input) describeButton(obj, "InputBegan", input) end)
    obj.InputEnded:Connect(function(input) describeButton(obj, "InputEnded", input) end)
    obj:GetPropertyChangedSignal("Visible"):Connect(function()
        if lastVisible[obj] ~= obj.Visible then
            lastVisible[obj] = obj.Visible
            log("BUTTON_VISIBLE_CHANGED", "name=" .. obj.Name, "path=" .. pathOf(obj), "visible=" .. tostring(obj.Visible))
        end
    end)
    obj:GetPropertyChangedSignal("Active"):Connect(function()
        log("BUTTON_ACTIVE_CHANGED", "name=" .. obj.Name, "path=" .. pathOf(obj), "active=" .. tostring(obj.Active))
    end)
end
function scanGui()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, obj in ipairs(pg:GetDescendants()) do pcall(watchButton, obj) end
    end
    -- Try CoreGui too; some executors expose game controls there.
    pcall(function()
        for _, obj in ipairs(CoreGui:GetDescendants()) do
            if obj:IsA("GuiButton") then pcall(watchButton, obj) end
        end
    end)
    local count = 0
    for _ in pairs(seenButtons) do count += 1 end
    log("SCAN_COMPLETE", "buttons_seen=" .. tostring(count))
    if count == 0 then status.Text = "Nenhum botão encontrado ainda. Toque em REESCANEAR." end
end
copyButton.Activated:Connect(copyReport)
scanButton.Activated:Connect(scanGui)
closeButton.Activated:Connect(function() gui:Destroy() end)

local function watchPlayerGui()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    pg.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj and obj.Parent then pcall(watchButton, obj) end
        end)
    end)
end
local lastCharacterState = ""
local function getCharacterInfo()
    local character = player.Character
    if not character then return "no-character" end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return "no-humanoid" end
    local state = "?"
    pcall(function() state = tostring(humanoid:GetState()) end)
    local tracks = {}
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local ok, playing = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok then
            for _, track in ipairs(playing) do
                local animId, animName = "?", "?"
                pcall(function()
                    animId = track.Animation and track.Animation.AnimationId or "?"
                    animName = track.Animation and track.Animation.Name or "?"
                end)
                table.insert(tracks, animName .. ":" .. animId .. ":w" .. tostring(track.WeightCurrent))
            end
        end
    end
    table.sort(tracks)
    return state .. " | animations=[" .. table.concat(tracks, ", ") .. "]"
end

log("STARTED. Diagnostic only; crouch behavior is not modified.")
scanGui()
watchPlayerGui()
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.35 then return end
    elapsed = 0
    local info = getCharacterInfo()
    if info ~= lastCharacterState then
        lastCharacterState = info
        log("CHARACTER_STATE", info)
    end
end)
player.CharacterAdded:Connect(function()
    log("CHARACTER_RESPAWNED")
    task.wait(1)
    lastCharacterState = ""
    scanGui()
end)
