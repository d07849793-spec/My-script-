-- [[ aimtop v2 | by kupa scripts ]] --

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
local TargetNPCs = true -- Флаг для захвата ботов
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

MainTab:CreateToggle({
   Name = "Target NPCs (Детектить ботов)",
   CurrentValue = true,
   Callback = function(Value)
      TargetNPCs = Value
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
            if typeof(highlight) == "Instance" then
               highlight:Destroy()
            end
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
      -- Если это реальный игрок
      if TeamCheck and player.Team == LocalPlayer.Team then
         return false
      end
   else
      -- Если это бот/NPC
      if not TargetNPCs then
         return false
      end
   end

   return true, targetPart
end

-- Поиск ближайшей цели (Игрока или Бота) по центру экрана
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

   -- Сканируем ботов в Workspace (если включено TargetNPCs)
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
      local targetPart = GetClosestTarget()
      if targetPart then
         local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
         local currentSmoothness = NoSmoothness and 1 or Smoothness
         Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, currentSmoothness)
      end
   end

   -- ESP Логика (Игроки + Боты)
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

-- Очистка при удалении персонажа/игрока
Players.PlayerRemoving:Connect(function(player)
   if player.Character and Highlights[player.Character] then
      Highlights[player.Character]:Destroy()
      Highlights[player.Character] = nil
   end
end)
