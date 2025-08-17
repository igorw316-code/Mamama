--[[
    SUPER CHUDY GUI
    Autor: Copilot, na podstawie Twojego opisu oraz dobrych praktyk Roblox
    Funkcje:
    - Bezpieczne i płynne "tweenowanie" gracza do wybranego punktu (baza) z omijaniem ścian (pathfinding)
    - Ochrona przed śmiercią po teleportacji
    - Przejrzysty i rozbudowany interfejs GUI (opis, status, reset, zamykanie)
    - System powrotu do ostatniej pozycji
    - Estetyczne efekty GUI (rainbow stroke, podświetlenia)
    - Wszystko podpisane i rozpisane!
--]]

-- === SERVICES ===
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- === GUI SETUP ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SuperChudyGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Circle button to open main menu
local circleBtn = Instance.new("ImageButton")
circleBtn.Size = UDim2.new(0,80,0,80)
circleBtn.Position = UDim2.new(0,20,0.5,-40)
circleBtn.BackgroundTransparency = 1
circleBtn.Image = "rbxassetid://95609095181189"
circleBtn.Name = "OpenChudyMain"
circleBtn.Parent = screenGui

local circleStroke = Instance.new("UIStroke")
circleStroke.Thickness = 3
circleStroke.Parent = circleBtn

-- Rainbow border for button
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    circleStroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,320,0,240)
frame.Position = UDim2.new(0.5,-160,0.5,-120)
frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
frame.BackgroundTransparency = 0.12
frame.Visible = false
frame.Active = true
frame.Draggable = true
frame.Name = "ChudyMainFrame"
frame.Parent = screenGui

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 3
frameStroke.Parent = frame

RunService.RenderStepped:Connect(function()
    frameStroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,48)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "chudy"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 32
title.Parent = frame

-- DESCRIPTION
local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1,-20,0,36)
desc.Position = UDim2.new(0,10,0,50)
desc.BackgroundTransparency = 1
desc.Text = "Bezpieczny powrót do bazy z omijaniem przeszkód.\nWersja: Super Chudy"
desc.TextColor3 = Color3.fromRGB(190,190,220)
desc.Font = Enum.Font.Gotham
desc.TextSize = 15
desc.TextWrapped = true
desc.TextYAlignment = Enum.TextYAlignment.Top
desc.Parent = frame

-- STATUS LABEL
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,24)
status.Position = UDim2.new(0,10,0,92)
status.BackgroundTransparency = 1
status.Text = "Status: Oczekiwanie..."
status.TextColor3 = Color3.fromRGB(200,255,200)
status.Font = Enum.Font.Gotham
status.TextSize = 15
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

-- === BUTTONS ===
local function createButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85,0,0,36)
    btn.Position = UDim2.new(0.075,0,0,yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = text
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = frame

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 2
    RunService.RenderStepped:Connect(function()
        btnStroke.Color = Color3.fromHSV((hue + yPos*0.01) % 1, 0.7, 1)
    end)

    return btn
end

local setBaseBtn = createButton("Ustaw Bazę", 122)
local goBaseBtn = createButton("Idź do Bazy (Pathfinding)", 164)
local returnBtn = createButton("Powrót na Start", 206)
local resetBtn = createButton("Resetuj GUI", 248)
local closeBtn = createButton("Zamknij", 290)
closeBtn.BackgroundColor3 = Color3.fromRGB(120,0,0)

-- === LOGIKA BAZY I POZYCJI ===
local basePosition = nil
local lastPosition = nil

-- Funkcja sprawdzająca obecność gracza i zwracająca character/HRP/Humanoid lub nil
local function getCharData()
    local char = player.Character
    if not char or not char.Parent then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not humanoid then return nil end
    return char, hrp, humanoid
end

-- Ustawianie bazy
setBaseBtn.MouseButton1Click:Connect(function()
    local char, hrp, humanoid = getCharData()
    if not hrp then
        status.Text = "Status: Nie znaleziono postaci!"
        return
    end
    basePosition = hrp.Position
    status.Text = "Status: Baza ustawiona!"
    setBaseBtn.Text = "Baza Ustawiona!"
    task.wait(1)
    setBaseBtn.Text = "Ustaw Bazę"
    status.Text = "Status: Oczekiwanie..."
end)

-- Powrót do ostatniej pozycji
returnBtn.MouseButton1Click:Connect(function()
    local char, hrp, humanoid = getCharData()
    if not lastPosition then
        status.Text = "Status: Brak zapamiętanej pozycji!"
        return
    end
    status.Text = "Status: Wracam na start!"
    local tween = TweenService:Create(hrp, TweenInfo.new((lastPosition - hrp.Position).Magnitude/60, Enum.EasingStyle.Linear), {Position=lastPosition+Vector3.new(0,2,0)})
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    tween:Play()
    tween.Completed:Wait()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
    status.Text = "Status: Oczekiwanie..."
end)

-- === PATHFINDING POWRÓT DO BAZY ===
goBaseBtn.MouseButton1Click:Connect(function()
    local char, hrp, humanoid = getCharData()
    if not basePosition then
        status.Text = "Status: Najpierw ustaw bazę!"
        return
    end
    status.Text = "Status: Przeliczam ścieżkę..."
    lastPosition = hrp.Position
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 7,
        AgentMaxSlope = 40,
        })
    path:ComputeAsync(hrp.Position, basePosition + Vector3.new(0,2,0))
    if path.Status ~= Enum.PathStatus.Complete then
        status.Text = "Status: Nie znaleziono ścieżki!"
        return
    end

    status.Text = "Status: Idę do bazy!"
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    -- Kroki po punktach ścieżki
    for i, waypoint in ipairs(path:GetWaypoints()) do
        if not char.Parent then break end
        local dist = (hrp.Position - waypoint.Position).Magnitude
        local t = math.clamp(dist/80, 0.2, 1.5)
        local tween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {Position=waypoint.Position+Vector3.new(0,2,0)})
        tween:Play()
        tween.Completed:Wait()
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hrp.Velocity = Vector3.new(0, 45, 0)
        end
    end

    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
    status.Text = "Status: Dotarłeś do bazy!"
    task.wait(1.3)
    status.Text = "Status: Oczekiwanie..."
end)

-- === RESET GUI ===
resetBtn.MouseButton1Click:Connect(function()
    basePosition = nil
    lastPosition = nil
    status.Text = "Status: Resetowane!"
    setBaseBtn.Text = "Ustaw Bazę"
    task.wait(1)
    status.Text = "Status: Oczekiwanie..."
end)

-- Zamknięcie GUI
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

-- Otwieranie GUI
circleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Autoodświeżanie napisu GUI po respawnie
player.CharacterAdded:Connect(function()
    status.Text = "Status: Oczekiwanie..."
end)

-- === PRO TIP: dodaj dźwięk kliknięcia, jeśli chcesz
--[[
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://1234567"
clickSound.Volume = 1
clickSound.Parent = frame
setBaseBtn.MouseButton1Click:Connect(function()
    clickSound:Play()
end)
]]--

-- KONIEC
