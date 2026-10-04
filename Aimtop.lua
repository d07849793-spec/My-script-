-- [[ гемини тупой долбоеб ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "aimtop v2 | Best aim for all games",
   LoadingTitle = "aimtop",
   LoadingSubtitle = "by kupa scripts",
   ConfigurationSaving = {
      Enabled = false,
   },
   KeySystem = false
})

-- Service References
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- State Variables
local AimbotEnabled = false
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

-- Create Rayfield-Styled Floating Button
local function CreateRayfieldButton(name, text, defaultPos)
    local frame = Instance.new("TextButton")
    frame.Name = name
    frame.Size = UDim2.new(0, 75, 0, 75)
    frame.Position = defaultPos
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    frame.AutoButtonColor = false
    frame.Text = ""
    frame.Visible = false
    frame.Parent = MobileScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(44, 44, 56)
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
    label.Font = Enum.Font.GothamBold
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

local AimBtnFrame, AimBtnInd, AimBtnStroke = CreateRayfieldButton("AimButton", "AIM", UDim2.new(0.8, 0, 0.35, 0))
local WallBtnFrame, WallBtnInd, WallBtnStroke = CreateRayfieldButton("WallButton", "WALL", UDim2.new(0.8, 0, 0.48, 0))

local function UpdateButtonState(frame, indicator, stroke, state)
    if state then
        indicator.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
        stroke.Color = Color3.fromRGB(60, 220, 100)
    else
        indicator.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        stroke.Color = Color3.fromRGB(44, 44, 56)
    end
end

-- FOV Circle Object
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = false

-- ESP Highlights Container
local Highlights = {}

-- Tabs
local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VisualsTab = Window:CreateTab("ESP & Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)

-- ================= AIMBOT TAB =================
local AimToggle = MainTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Callback = function(Value)
      AimbotEnabled = Value
      UpdateButtonState(AimBtnFrame, AimBtnInd, AimBtnStroke, Value)
   end,
})

local WallToggle = MainTab:CreateToggle({
   Name = "Wall Check (Проверка стен)",
   CurrentValue = false,
   Callback = function(Value)
      WallCheck = Value
      UpdateButtonState(WallBtnFrame, WallBtnInd, WallBtnStroke, Value)
   end,
})

MainTab:CreateToggle({
   Name = "Team Check (Проверка команд)",
   CurrentValue = false,
   Callback = function(Value)
      TeamCheck = Value
   end,
})

MainTab:CreateToggle({
   Name = "Add Aim Button",
   CurrentValue = false,
   Callback = function(Value)
      AimBtnFrame.Visible = Value
   end,
})

MainTab:CreateToggle({
   Name = "Add Wall Check Button",
   CurrentValue = false,
   Callback = function(Value)
      WallBtnFrame.Visible = Value
   end,
})

MainTab:CreateToggle({
   Name = "No плавность (Мгновенный аим)",
   CurrentValue = false,
   Callback = function(Value)
      NoSmoothness = Value
   end,
})

MainTab:CreateDropdown({
   Name = "Aim Target Part",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = "Head",
   Callback = function(Option)
      AimPart = type(Option) == "table" and Option[1] or Option
   end,
})

MainTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {30, 500},
   Increment = 5,
   Suffix = "px",
   CurrentValue = 150,
   Callback = function(Value)
      AimFOV = Value
      FOVCircle.Radius = Value
   end,
})

MainTab:CreateSlider({
   Name = "Smoothness (Плавность)",
   Range = {0.05, 1},
   Increment = 0.05,
   CurrentValue = 0.2,
   Callback = function(Value)
      Smoothness = Value
   end,
})

-- On-Screen Button Clicks
AimBtnFrame.MouseButton1Click:Connect(function()
   AimToggle:Set(not AimbotEnabled)
end)

WallBtnFrame.MouseButton1Click:Connect(function()
   WallToggle:Set(not WallCheck)
end)

-- ================= VISUALS TAB =================
VisualsTab:CreateSection("ESP Options")

VisualsTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Callback = function(Value)
      EspEnabled = Value
      if not Value then
         for _, highlight in pairs(Highlights) do
            highlight:Destroy()
         end
         Highlights = {}
      end
   end,
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        EspColor = Value
    end
})

VisualsTab:CreateToggle({
   Name = "ESP Rainbow Mode",
   CurrentValue = false,
   Callback = function(Value)
      EspRainbow = Value
   end,
})

VisualsTab:CreateSection("FOV Circle Options")

VisualsTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Callback = function(Value)
      FovVisible = Value
      FOVCircle.Visible = Value
   end,
})

VisualsTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        FovColor = Value
        FOVCircle.Color = Value
    end
})

VisualsTab:CreateToggle({
   Name = "FOV Rainbow Mode",
   CurrentValue = false,
   Callback = function(Value)
      FovRainbow = Value
   end,
})

-- ================= MOVEMENT TAB =================
MovementTab:CreateToggle({
   Name = "Enable Custom Speed",
   CurrentValue = false,
   Callback = function(Value)
      SpeedEnabled = Value
      if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
         LocalPlayer.Character.Humanoid.WalkSpeed = 16
      end
   end,
})

MovementTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   CurrentValue = 16,
   Callback = function(Value)
      WalkSpeedValue = Value
   end,
})

MovementTab:CreateToggle({
   Name = "Enable Custom Jump",
   CurrentValue = false,
   Callback = function(Value)
      JumpEnabled = Value
      if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
         LocalPlayer.Character.Humanoid.JumpPower = 50
      end
   end,
})

MovementTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 300},
   Increment = 5,
   CurrentValue = 50,
   Callback = function(Value)
      JumpPowerValue = Value
   end,
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

-- Проверка команды (Team Check)
local function IsEnemy(player)
   if not TeamCheck then return true end
   return player.Team ~= LocalPlayer.Team
end

-- Поиск ближайшего игрока по центру экрана
local function GetClosestPlayer()
   local closestPlayer = nil
   local shortestDistance = AimFOV
   local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

   for _, player in pairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and IsEnemy(player) and player.Character and player.Character:FindFirstChild(AimPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
         local part = player.Character[AimPart]
         local partPos, onScreen = Camera:WorldToViewportPoint(part.Position)
         
         if onScreen and IsVisible(part) then
            local distance = (Vector2.new(partPos.X, partPos.Y) - screenCenter).Magnitude
            if distance < shortestDistance then
               closestPlayer = player
               shortestDistance = distance
            end
         end
      end
   end

   return closestPlayer
end

-- Основной цикл
RunService.RenderStepped:Connect(function()
   local hue = (tick() % 5) / 5
   local rainbowColor = Color3.fromHSV(hue, 1, 1)

   -- Rainbow для FOV
   if FovRainbow then
      FOVCircle.Color = rainbowColor
   else
      FOVCircle.Color = FovColor
   end

   -- Центрирование круга FOV
   FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

   -- Aimbot
   if AimbotEnabled then
      local target = GetClosestPlayer()
      if target and target.Character and target.Character:FindFirstChild(AimPart) then
         local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Character[AimPart].Position)
         local currentSmoothness = NoSmoothness and 1 or Smoothness
         Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, currentSmoothness)
      end
   end

   -- ESP Логика
   if EspEnabled then
      for _, player in pairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character then
            local highlight = Highlights[player]
            if not highlight or highlight.Parent ~= player.Character then
               if highlight then highlight:Destroy() end
               highlight = Instance.new("Highlight")
               highlight.Adornee = player.Character
               highlight.FillTransparency = 0.5
               highlight.OutlineTransparency = 0
               highlight.Parent = player.Character
               Highlights[player] = highlight
            end

            local activeColor = EspRainbow and rainbowColor or EspColor
            highlight.FillColor = activeColor
            highlight.OutlineColor = activeColor
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
   if Highlights[player] then
      Highlights[player]:Destroy()
      Highlights[player] = nil
   end
end)
