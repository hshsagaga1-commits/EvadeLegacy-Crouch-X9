-- Evade Legacy X9 - Macro for the actual mobile GUI buttons
-- First tap: Emote tab -> Emote 5 -> Flashlight -> Crouch.
-- Second tap: Emote tab only. The macro does not tap Crouch again.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    local old = playerGui:FindFirstChild("X9CrouchStatus")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "X9CrouchStatus"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = playerGui

local macroButton = Instance.new("TextButton")
macroButton.Name = "X9MacroButton"
macroButton.Size = UDim2.new(0, 260, 0, 48)
macroButton.Position = UDim2.new(0.5, -130, 0.08, 0)
macroButton.BackgroundColor3 = Color3.fromRGB(35, 115, 190)
macroButton.TextColor3 = Color3.new(1, 1, 1)
macroButton.Text = "Macro: executar sequência"
macroButton.TextSize = 15
macroButton.Font = Enum.Font.GothamBold
macroButton.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = macroButton

local status = Instance.new("TextLabel")
status.Name = "MacroStatus"
status.Size = UDim2.new(0, 320, 0, 42)
status.Position = UDim2.new(0.5, -160, 0.08, 52)
status.BackgroundTransparency = 0.25
status.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
status.TextColor3 = Color3.new(1, 1, 1)
status.Text = "Macro carregada"
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.Parent = gui

local function norm(s)
    return string.lower(tostring(s or "")):gsub("[%s_%-]", "")
end

local function buttonText(obj)
    local result = {obj.Name}
    pcall(function() table.insert(result, obj.Text) end)
    pcall(function() table.insert(result, obj:GetAttribute("Text")) end)
    pcall(function() table.insert(result, obj:GetAttribute("Name")) end)
    return norm(table.concat(result, " "))
end

local function allButtons()
    local result = {}
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Active then
            table.insert(result, obj)
        end
    end
    return result
end

local function findButton(kind)
    local buttons = allButtons()
    local best, bestScore = nil, 0
    for _, obj in ipairs(buttons) do
        local s = buttonText(obj)
        local score = 0
        if kind == "emoteTab" then
            if s == "emote" or s == "emotes" or s:find("emotemenu", 1, true) or s:find("emotetab", 1, true) then score = 100 end
            if s:find("emote5", 1, true) or s:find("slot5", 1, true) then score = 0 end
        elseif kind == "emote5" then
            if s:find("emote5", 1, true) or s:find("emote05", 1, true) or s:find("slot5", 1, true) then score = 100 end
            if s:find("emote", 1, true) and (s:find("5", 1, true) or s:find("five", 1, true)) then score = math.max(score, 90) end
        elseif kind == "flashlight" then
            if s:find("flashlight", 1, true) or s:find("lanterna", 1, true) then score = 100 end
        elseif kind == "crouch" then
            if s == "crouch" or s:find("crouchbutton", 1, true) or s == "agachar" then score = 100 end
        end
        if score > bestScore then
            best, bestScore = obj, score
        end
    end
    return best
end

local function activateButton(obj)
    if not obj then return false end
    local ok = pcall(function() obj:Activate() end)
    if ok then return true end
    -- Some executor/game combinations expose Activated as a signal only.
    local fired = pcall(function() firesignal(obj.Activated) end)
    return fired
end

local function tap(kind)
    local obj = findButton(kind)
    if not obj then
        status.Text = "Não achei o botão: " .. kind
        return false
    end
    local ok = activateButton(obj)
    if not ok then
        status.Text = "Achei " .. kind .. ", mas não consegui ativar"
        return false
    end
    status.Text = "OK: " .. kind
    return true
end

local busy = false
local phase = 0

macroButton.Activated:Connect(function()
    if busy then return end
    busy = true
    if phase == 0 then
        status.Text = "1/4: abrindo Emotes..."
        if tap("emoteTab") then
            task.wait(0.25)
            status.Text = "2/4: selecionando Emote 5..."
            if tap("emote5") then
                task.wait(0.2)
                status.Text = "3/4: ativando lanterna..."
                if tap("flashlight") then
                    task.wait(0.2)
                    status.Text = "4/4: ativando agachar..."
                    if tap("crouch") then
                        phase = 1
                        macroButton.Text = "Macro: abrir Emotes"
                        status.Text = "Sequência feita. Próximo toque abre Emotes."
                    end
                end
            end
        end
    else
        status.Text = "Abrindo Emotes..."
        if tap("emoteTab") then
            phase = 0
            macroButton.Text = "Macro: executar sequência"
            status.Text = "Emotes aberto. Crouch não foi tocado."
        end
    end
    busy = false
end)
