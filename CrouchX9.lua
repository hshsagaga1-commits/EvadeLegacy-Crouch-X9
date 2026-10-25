-- Evade Legacy Crouch X9 (diagnostic only)
-- Logs existing mobile UI button presses/visibility and character animation changes.
-- Does NOT add buttons or change gameplay. Run in your executor, then:
-- 1) tap/hold the original crouch button
-- 2) start an emote
-- 3) wait for controls to return
-- 4) copy relevant [X9] lines from the executor console.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then
    warn("[X9] LocalPlayer not found")
    return
end

local seenButtons = setmetatable({}, { __mode = "k" })
local lastVisible = setmetatable({}, { __mode = "k" })
local lastAnimState = ""

local function pathOf(obj)
    local ok, result = pcall(function() return obj:GetFullName() end)
    return ok and result or obj.Name
end

local function log(...)
    print("[X9]", ...)
end

local function describeButton(button, eventName, input)
    local extra = ""
    if input then
        pcall(function()
            extra = " input=" .. tostring(input.UserInputType)
                .. " key=" .. tostring(input.KeyCode)
        end)
    end
    log("BUTTON", eventName,
        "name=" .. button.Name,
        "path=" .. pathOf(button),
        "visible=" .. tostring(button.Visible),
        "active=" .. tostring(button.Active),
        "enabled=" .. tostring(button.Interactable) .. extra)
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
            log("BUTTON_VISIBLE_CHANGED", "name=" .. obj.Name,
                "path=" .. pathOf(obj), "visible=" .. tostring(obj.Visible))
        end
    end)
    obj:GetPropertyChangedSignal("Active"):Connect(function()
        log("BUTTON_ACTIVE_CHANGED", "name=" .. obj.Name,
            "path=" .. pathOf(obj), "active=" .. tostring(obj.Active))
    end)
end

local function scanGui()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    for _, obj in ipairs(pg:GetDescendants()) do watchButton(obj) end
end

local function watchPlayerGui()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    pg.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj and obj.Parent then watchButton(obj) end
        end)
    end)
end

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

log("STARTED. Diagnostic only; no controls are modified.")
scanGui()
watchPlayerGui()

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.25 then return end
    elapsed = 0
    local info = getCharacterInfo()
    if info ~= lastAnimState then
        lastAnimState = info
        log("CHARACTER_STATE", info)
    end
end)

player.CharacterAdded:Connect(function()
    log("CHARACTER_RESPAWNED")
    task.wait(1)
    lastAnimState = ""
end)
