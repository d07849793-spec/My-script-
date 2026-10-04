-- [[ aimtop v2 | Skeet (Gamesense) Edition ]] --

-- Загрузка библиотеки Skeet UI (Gamesense)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/skatbr/Luau-SkeetUI/main/SkeetUI.lua"))()

local Window = Library:CreateWindow("aimtop v2 | Skeet Edition")

-- Service References
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- State Variables
local AimbotEnabled = false
local TargetNPCs = true
local AimFOV = 150
local AimPart = "Head"
local Smoothness = 0.2
local NoSmoothness = false
local WallCheck = false
local TeamCheck = false

local EspEnabled = false
local EspRainbow = false
local EspColor = Color3.fromRGB(255, 0, 0)

local FovVisible = false
local FovRainbow = false
local FovColor = Color3.fromRGB(255, 255, 255)

local SpeedEnabled = false
local WalkSpeedValue = 16
local JumpEnabled = false
local JumpPowerValue = 50

-- Screen GUI for Mobile On-Screen Buttons
local MobileScreenGui = Instance.new("ScreenGui")
MobileScreenGui.Name = "AimtopMobileUI"
MobileScreenGui.ResetOnSpawn = false
if gethui then
    MobileScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(MobileScreenGui)
    MobileScreenGui.Parent = game:GetService("CoreGui")
else
    MobileScreenGui.Parent = game:GetService("CoreGui")
end

-- Helper for Mobile Draggable Elements
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Create Floating Mobile Button
local function CreateMobileButton(name, text, defaultPos)
    local frame = Instance.new("TextButton")
    frame.Name = name
    frame.Size = UDim2.new(0, 75, 0, 75)
    frame.Position = defaultPos
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.AutoButtonColor = false
    frame.Text = ""
    frame.Visible = false
    frame.Parent = MobileScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 180, 50)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.6, 0)
    label.Position = UDim2.new(0, 0, 0.1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 24, 0, 8)
    indicator.Position = UDim2.new(0.5, -12, 0.72, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    indicator.Parent = frame

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    MakeDraggable(frame)

    return frame, indicator, stroke
end

local AimBtnFrame, AimBtnInd, AimBtnStroke = CreateMobileButton("AimButton", "AIM", UDim2.new(0.8, 0, 0.35, 0))
local WallBtnFrame, WallBtnInd, WallBtnStroke = CreateMobileButton("WallButton", "WALL", UDim2.new(0.8, 0, 0.48, 0))

local function UpdateButtonState(frame, indicator, stroke, state)
    if state then
        indicator.BackgroundColor3 = Color3.fromRGB(150, 200, 60)
        stroke.Color = Color3.fromRGB(150, 200, 60)
    else
        indicator.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        stroke.Color = Color3.fromRGB(50, 50, 50)
    end
end

-- ESP Highlights Container
local Highlights = {}

-- ================= SKEET UI TABS =================
local LegitTab = Window:AddTab("Legit")
local VisualsTab = Window:AddTab("Visuals")
local MiscTab = Window:AddTab("Misc")

-- ================= LEGIT TAB =================
local AimGroup = LegitTab:AddGroupBox("Aimbot Settings")

local AimToggle = AimGroup:AddToggle("Enable Aimbot", {
    Default = false,
    Callback = function(Value)
        AimbotEnabled = Value
        UpdateButtonState(AimBtnFrame, AimBtnInd, AimBtnStroke, Value)
    end
})

AimGroup:AddToggle("Target NPCs (Боты)", {
    Default = true,
    Callback = function(Value)
        TargetNPCs = Value
    end
})

local WallToggle = AimGroup:AddToggle("Wall Check", {
    Default = false,
    Callback = function(Value)
        WallCheck = Value
        UpdateButtonState(WallBtnFrame, WallBtnInd, WallBtnStroke, Value)
    end
})

AimGroup:AddToggle("Team Check", {
    Default = false,
    Callback = function(Value)
        TeamCheck = Value
    end
})

AimGroup:AddToggle("No Smoothness (Мгновенно)", {
    Default = false,
    Callback = function(Value)
        NoSmoothness = Value
    end
})

AimGroup:AddDropdown("Aim Target Part", {
    Values = {"Head", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(Value)
        AimPart = Value
    end
})

AimGroup:AddSlider("Aimbot FOV", {
    Min = 30,
    Max = 500,
    Default = 150,
    Rounding = 0,
    Callback = function(Value)
        AimFOV = Value
        Library.FovCircle.Radius = Value
    end
})

AimGroup:AddSlider("Smoothness", {
    Min = 0.05,
    Max = 1,
    Default = 0.2,
    Rounding = 2,
    Callback = function(Value)
        Smoothness = Value
    end
})

local MobileGroup = LegitTab:AddGroupBox("Mobile Buttons")

MobileGroup:AddToggle("Show Aim Button", {
    Default = false,
    Callback = function(Value)
        AimBtnFrame.Visible = Value
    end
})

MobileGroup:AddToggle("Show Wall Check Button", {
    Default = false,
    Callback = function(Value)
        WallBtnFrame.Visible = Value
    end
})

-- On-Screen Button Clicks
AimBtnFrame.MouseButton1Click:Connect(function()
    AimToggle:SetState(not AimbotEnabled)
end)

WallBtnFrame.MouseButton1Click:Connect(function()
    WallToggle:SetState(not WallCheck)
end)

-- ================= VISUALS TAB =================
local EspGroup = VisualsTab:AddGroupBox("ESP Options")

EspGroup:AddToggle("Enable ESP", {
    Default = false,
    Callback = function(Value)
        EspEnabled = Value
        if not Value then
            for _, highlight in pairs(Highlights) do
                if typeof(highlight) == "Instance" then
                    highlight:Destroy()
                end
            end
            Highlights = {}
        end
    end
})

EspGroup:AddColorpicker("ESP Color", {
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        EspColor = Value
    end
})

EspGroup:AddToggle("ESP Rainbow Mode", {
    Default = false,
    Callback = function(Value)
        EspRainbow = Value
    end
})

local FovGroup = VisualsTab:AddGroupBox("FOV Circle Options")

FovGroup:AddToggle("Show FOV Circle", {
    Default = false,
    Callback = function(Value)
        FovVisible = Value
        Library.FovCircle.Visible = Value
    end
})

FovGroup:AddColorpicker("FOV Circle Color", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        FovColor = Value
        Library.FovCircle.Color = Value
    end
})

FovGroup:AddToggle("FOV Rainbow Mode", {
    Default = false,
    Callback = function(Value)
        FovRainbow = Value
    end
})

-- ================= MISC TAB =================
local MovementGroup = MiscTab:AddGroupBox("Movement Modifications")

MovementGroup:AddToggle("Enable Custom Speed", {
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

MovementGroup:AddSlider("WalkSpeed", {
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 0,
    Callback = function(Value)
        WalkSpeedValue = Value
    end
})

MovementGroup:AddToggle("Enable Custom Jump", {
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
        if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
    end
})

MovementGroup:AddSlider("JumpPower", {
    Min = 50,
    Max = 300,
    Default = 50,
    Rounding = 0,
    Callback = function(Value)
        JumpPowerValue = Value
    end
})

-- ================= LOGIC & LOOPS =================

-- Проверка видимости за стеной
local function IsVisible(targetPart)
    if not WallCheck then return true end
   
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local raycastParams = RaycastParams.new()
   
    raycastParams.FilterType = RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.IgnoreWater = true
   
    local result = workspace:Raycast(origin, destination - origin, raycastParams)
   
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

-- Проверка валидности цели (Игрок или Бот)
local function IsValidTarget(model)
    if not model or not model:IsA("Model") or model == LocalPlayer.Character then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local targetPart = model:FindFirstChild(AimPart) or model:FindFirstChild("HumanoidRootPart")
   
    if not humanoid or humanoid.Health <= 0 or not targetPart then
        return false
    end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if TeamCheck and player.Team == LocalPlayer.Team then
            return false
        end
    else
        if not TargetNPCs then
            return false
        end
    end

    return true, targetPart
end

-- Поиск ближайшей цели по центру экрана
local function GetClosestTarget()
    local closestTargetPart = nil
    local shortestDistance = AimFOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Сканируем игроков
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local valid, part = IsValidTarget(player.Character)
            if valid then
                local partPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and IsVisible(part) then
                    local distance = (Vector2.new(partPos.X, partPos.Y) - screenCenter).Magnitude
                    if distance < shortestDistance then
                        closestTargetPart = part
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    -- Сканируем ботов в Workspace
    if TargetNPCs then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local valid, part = IsValidTarget(obj)
                if valid then
                    local partPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and IsVisible(part) then
                        local distance = (Vector2.new(partPos.X, partPos.Y) - screenCenter).Magnitude
                        if distance < shortestDistance then
                            closestTargetPart = part
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return closestTargetPart
end

-- Основной рабочий цикл
RunService.RenderStepped:Connect(function()
    local hue = (tick() % 5) / 5
    local rainbowColor = Color3.fromHSV(hue, 1, 1)

    -- Rainbow для FOV
    if FovRainbow then
        Library.FovCircle.Color = rainbowColor
    else
        Library.FovCircle.Color = FovColor
    end

    -- Аимбот
    if AimbotEnabled then
        local targetPart = GetClosestTarget()
        if targetPart then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            local currentSmoothness = NoSmoothness and 1 or Smoothness
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, currentSmoothness)
        end
    end

    -- ESP Логика
    if EspEnabled then
        local activeColor = EspRainbow and rainbowColor or EspColor

        local function ApplyHighlight(model)
            local highlight = Highlights[model]
            if not highlight or highlight.Parent ~= model then
                if highlight and typeof(highlight) == "Instance" then highlight:Destroy() end
                highlight = Instance.new("Highlight")
                highlight.Adornee = model
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Parent = model
                Highlights[model] = highlight
            end
            highlight.FillColor = activeColor
            highlight.OutlineColor = activeColor
        end

        -- ESP на игроков
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local valid = IsValidTarget(player.Character)
                if valid then
                    ApplyHighlight(player.Character)
                elseif Highlights[player.Character] then
                    Highlights[player.Character]:Destroy()
                    Highlights[player.Character] = nil
                end
            end
        end

        -- ESP на ботов
        if TargetNPCs then
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                    local valid = IsValidTarget(obj)
                    if valid then
                        ApplyHighlight(obj)
                    elseif Highlights[obj] then
                        Highlights[obj]:Destroy()
                        Highlights[obj] = nil
                    end
                end
            end
        end
    end

    -- Скорость и Прыжок
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if SpeedEnabled then
            LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
        end
        if JumpEnabled then
            LocalPlayer.Character.Humanoid.JumpPower = JumpPowerValue
        end
    end
end)

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    if player.Character and Highlights[player.Character] then
        Highlights[player.Character]:Destroy()
        Highlights[player.Character] = nil
    end
end)
