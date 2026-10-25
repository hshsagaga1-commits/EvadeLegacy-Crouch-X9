-- Evade Legacy X9 - Keyboard macro
-- First tap: G (open/use emote) -> 5 (select emote 5) -> F (light) -> C (crouch).
-- Second tap: G only. It does not send C again.

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
macroButton.Text = "Macro: G > 5 > F > C"
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

local virtualInput
pcall(function()
    virtualInput = game:GetService("VirtualInputManager")
end)

local virtualKeys = {
    G = 0x47,
    Five = 0x35,
    F = 0x46,
    C = 0x43
}

local function tapKey(keyName)
    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then
        status.Text = "Tecla inválida: " .. keyName
        return false
    end

    -- Try executor keyboard functions first when available.
    if type(keypress) == "function" and type(keyrelease) == "function" then
        local ok = pcall(function()
            keypress(virtualKeys[keyName])
            task.wait(0.07)
            keyrelease(virtualKeys[keyName])
        end)
        if ok then
            status.Text = "Tecla enviada: " .. keyName
            return true
        end
    end

    if virtualInput then
        local ok = pcall(function()
            virtualInput:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.07)
            virtualInput:SendKeyEvent(false, keyCode, false, game)
        end)
        if ok then
            status.Text = "Tecla enviada: " .. keyName
            return true
        end
    end

    status.Text = "Não consegui enviar a tecla " .. keyName
    return false
end

local busy = false
local phase = 0

macroButton.Activated:Connect(function()
    if busy then return end
    busy = true

    if phase == 0 then
        status.Text = "1/4: G — Emote..."
        if tapKey("G") then
            task.wait(0.35)
            status.Text = "2/4: 5 — Emote 5..."
            if tapKey("Five") then
                task.wait(0.25)
                status.Text = "3/4: F — Lanterna..."
                if tapKey("F") then
                    task.wait(0.2)
                    status.Text = "4/4: C — Agachar..."
                    if tapKey("C") then
                        phase = 1
                        macroButton.Text = "Macro: G apenas"
                        status.Text = "Sequência concluída. Próximo toque envia só G."
                    end
                end
            end
        end
    else
        status.Text = "Enviando G..."
        if tapKey("G") then
            phase = 0
            macroButton.Text = "Macro: G > 5 > F > C"
            status.Text = "Só G enviado; C não foi enviado de novo."
        end
    end

    busy = false
end)
