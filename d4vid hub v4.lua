-- [[ D4VID HUB V4 ULTIMATE ]] --
-- [[ THE COMPETITION KILLER ]] --
-- [[ FULLY UNDETECTED & 0 LAGBACK ]] --

repeat task.wait() until game:IsLoaded()

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local LP              = Players.LocalPlayer
local Mouse           = LP:GetMouse()

-- ============================================================
-- STATE MANAGEMENT
-- ============================================================
local State = {
    normalSpeed = 59, carrySpeed = 30, laggerSpeed = 60, aimbotSpeed = 56.5,
    speedToggled = false, laggerEnabled = false,
    infJumpEnabled = false, antiRagdollEnabled = false,
    medusaCounterEnabled = false, batAimbotToggled = false, autoSwingEnabled = false,
    batCounterEnabled = false, autoStealEnabled = false,
    espEnabled = false, silentAimEnabled = false,
    antiCounterEnabled = false, hitboxExpandEnabled = false,
    autoParryV2Enabled = false, camLockEnabled = false,
    autoResetEnabled = false,

    -- Internal State
    isStealing = false, hittingCooldown = false,
    _parryDebounce = false, _parryPrevHP = 100, _parryPrevVel = Vector3.zero,
    hitboxOrigSizes = {}, espGuis = {}, batCounterDebounce = false,
    guiVisible = true, activeTab = "Home"
}

local Conns = {aimbot = nil, parry = nil, hitbox = nil, silent = nil, autoSteal = nil, antiRag = nil, batCounter = nil, medusa = nil, camlock = nil, esp = nil, anticounter = nil}
local tabObjs = {}

local Theme = {
    MainBg = Color3.fromRGB(11, 11, 16),
    SidebarBg = Color3.fromRGB(16, 16, 24),
    TabActive = Color3.fromRGB(55, 45, 95),
    TabHover = Color3.fromRGB(30, 30, 45),
    Accent = Color3.fromRGB(150, 80, 255),
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(160, 160, 185),
    Border = Color3.fromRGB(45, 45, 70),
    SectionBg = Color3.fromRGB(18, 18, 28)
}

-- ============================================================
-- UTILITIES
-- ============================================================
local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or Theme.Border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function makeDraggable(frame, handle)
    local src = handle or frame
    local dragging, dragInput, dragStart, startPos
    src.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; startPos = frame.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    src.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local dx = inp.Position.X - dragStart.X; local dy = inp.Position.Y - dragStart.Y
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
        end
    end)
end

-- ============================================================
-- CORE LOGIC
-- ============================================================

local function getBat()
    local char = LP.Character; if not char then return nil end
    local tool = char:FindFirstChild("Bat") or LP.Backpack:FindFirstChild("Bat")
    if tool and tool.Parent == LP.Backpack then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(tool) end
    end
    return tool
end

local function tryHitBat()
    if State.hittingCooldown then return end
    State.hittingCooldown = true
    local bat = getBat()
    if bat then
        bat:Activate()
        local rem = bat:FindFirstChildWhichIsA("RemoteEvent")
        if rem then rem:FireServer() end
    end
    task.delay(0.08, function() State.hittingCooldown = false end)
end

local function getClosestPlayer()
    local char = LP.Character; if not char then return nil, 9999 end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil, 9999 end
    local closest, dist = nil, 9999
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if t and h and h.Health > 0 then
                local d = (hrp.Position - t.Position).Magnitude
                if d < dist then dist = d; closest = p end
            end
        end
    end
    return closest, dist
end

-- SPEED (0 LAGBACK)
RunService.Heartbeat:Connect(function()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if hum.MoveDirection.Magnitude > 0 then
        local targetSpd = State.normalSpeed
        if State.speedToggled then targetSpd = State.carrySpeed end
        if State.laggerEnabled then targetSpd = State.laggerSpeed end

        local vel = hum.MoveDirection * targetSpd
        hrp.Velocity = Vector3.new(vel.X, hrp.Velocity.Y, vel.Z)
    end
end)

UIS.JumpRequest:Connect(function()
    if State.infJumpEnabled then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- COMBAT LOGIC
local function startBatAimbot()
    if Conns.aimbot then return end
    Conns.aimbot = RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local target, dist = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local dir = (tr.Position - hrp.Position).Unit
                hrp.Velocity = Vector3.new(dir.X * State.aimbotSpeed, hrp.Velocity.Y, dir.Z * State.aimbotSpeed)
                if dist <= 5 and State.autoSwingEnabled then tryHitBat() end
            end
        end
    end)
end

local function startAutoParryV2()
    if Conns.parry then return end
    Conns.parry = RunService.Heartbeat:Connect(function()
        if not State.autoParryV2Enabled then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local dVel = (hrp.Velocity - State._parryPrevVel).Magnitude
            local dHP = State._parryPrevHP - hum.Health
            if (dVel > 18 or dHP > 5) and not State._parryDebounce then
                State._parryDebounce = true
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                tryHitBat()
                task.delay(0.25, function() State._parryDebounce = false end)
            end
            State._parryPrevVel = hrp.Velocity
            State._parryPrevHP = hum.Health
        end
    end)
end

local function startHitboxExpand()
    if Conns.hitbox then return end
    Conns.hitbox = RunService.Heartbeat:Connect(function()
        if not State.hitboxExpandEnabled then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                if phrp then
                    if not State.hitboxOrigSizes[p.UserId] then State.hitboxOrigSizes[p.UserId] = phrp.Size end
                    phrp.Size = Vector3.new(12, 12, 12)
                    phrp.Transparency = 0.5
                    phrp.Color = Color3.fromRGB(150, 80, 255)
                end
            end
        end
    end)
end

local function stopHitboxExpand()
    if Conns.hitbox then Conns.hitbox:Disconnect(); Conns.hitbox = nil end
    for id, size in pairs(State.hitboxOrigSizes) do
        local p = Players:GetPlayerByUserId(id)
        if p and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Size = size; hrp.Transparency = 1 end
        end
    end
    State.hitboxOrigSizes = {}
end

local function startSilentAim()
    if Conns.silent then return end
    Conns.silent = RunService.Heartbeat:Connect(function()
        if not State.silentAimEnabled then return end
        local target, dist = getClosestPlayer()
        if target and dist < 25 then
            local thrp = target.Character:FindFirstChild("HumanoidRootPart")
            local mhrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if thrp and mhrp then
                local dir = (mhrp.Position - thrp.Position).Unit
                thrp.CFrame = thrp.CFrame + dir * 0.3
            end
        end
    end)
end

local function startCamLock()
    if Conns.camlock then return end
    Conns.camlock = RunService.RenderStepped:Connect(function()
        if not State.camLockEnabled then return end
        local target, dist = getClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, head.Position)
            end
        end
    end)
end

local function startAntiCounter()
    if Conns.anticounter then return end
    Conns.anticounter = RunService.Heartbeat:Connect(function()
        if not State.antiCounterEnabled then return end
        local target, dist = getClosestPlayer()
        if target and dist < 8 then
            local char = target.Character
            if char:FindFirstChild("Counter") or char:FindFirstChild("Shield") then
                LP.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,5)
            end
        end
    end)
end

-- SAB LOGIC
local function startAntiRagdoll()
    if Conns.antiRag then return end
    Conns.antiRag = RunService.Heartbeat:Connect(function()
        if not State.antiRagdollEnabled then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and (hum:GetState() == Enum.HumanoidStateType.Physics or hum:GetState() == Enum.HumanoidStateType.Ragdoll) then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

local function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled or State.batCounterDebounce then return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and (hum:GetState() == Enum.HumanoidStateType.Physics or hum:GetState() == Enum.HumanoidStateType.Ragdoll) then
            State.batCounterDebounce = true
            tryHitBat()
            task.delay(0.5, function() State.batCounterDebounce = false end)
        end
    end)
end

local function startMedusaCounter()
    if Conns.medusa then return end
    Conns.medusa = workspace.DescendantAdded:Connect(function(obj)
        if not State.medusaCounterEnabled then return end
        if obj.Name == "MedusaEffect" or obj.Name == "Petrify" then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (obj.Position - hrp.Position).Magnitude < 15 then
                tryHitBat()
            end
        end
    end)
end

-- AUTO LOGIC
local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not State.autoStealEnabled or State.isStealing then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local dist = (obj.Parent.Position - hrp.Position).Magnitude
                if dist <= 20 then
                    State.isStealing = true
                    task.spawn(function()
                        task.wait(0.05 + math.random() * 0.1)
                        if fireproximityprompt then fireproximityprompt(obj)
                        else
                            obj:InputHoldBegin()
                            task.wait(obj.HoldDuration + 0.05)
                            obj:InputHoldEnd()
                        end
                        task.wait(0.2)
                        State.isStealing = false
                    end)
                    return
                end
            end
        end
    end)
end

-- VISUALS
local function startESP()
    if Conns.esp then return end
    Conns.esp = RunService.RenderStepped:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                    if State.espEnabled and onScreen then
                        if not State.espGuis[p.UserId] then
                            local g = Instance.new("BillboardGui", game:GetService("CoreGui"))
                            g.AlwaysOnTop = true; g.Size = UDim2.new(0, 100, 0, 50); g.Adornee = hrp
                            local l = Instance.new("TextLabel", g)
                            l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextColor3=Theme.Accent; l.Font=Enum.Font.GothamBold; l.TextSize=12
                            State.espGuis[p.UserId] = {gui = g, lbl = l}
                        end
                        local e = State.espGuis[p.UserId]
                        e.gui.Enabled = true
                        e.lbl.Text = p.DisplayName .. "\n[" .. math.floor((LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) .. "m]"
                    else
                        if State.espGuis[p.UserId] then State.espGuis[p.UserId].gui.Enabled = false end
                    end
                end
            end
        end
    end)
end

-- [[ UI SYSTEM IMPLEMENTATION ]] --

local function addTab(sidebar, content, name)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.BackgroundColor3 = Theme.SidebarBg
    btn.BorderSizePixel = 0
    btn.Text = "      " .. name
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    mkCorner(btn, 10)

    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 12)
    Instance.new("UIPadding", page).PaddingLeft = UDim.new(0, 10)

    tabObjs[name] = {btn = btn, page = page}
    btn.MouseButton1Click:Connect(function()
        if State.activeTab then
            tabObjs[State.activeTab].page.Visible = false
            TweenService:Create(tabObjs[State.activeTab].btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.SidebarBg, TextColor3 = Theme.TextDim}):Play()
        end
        State.activeTab = name
        page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.TabActive, TextColor3 = Theme.Text}):Play()
    end)
    return page
end

local function makeSection(parent, title)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = Theme.SectionBg
    mkCorner(frame, 8)
    mkStroke(frame, Theme.Border, 1)
    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 8)
    Instance.new("UIPadding", frame).PaddingBottom = UDim.new(0, 10)
    Instance.new("UIPadding", frame).PaddingTop = UDim.new(0, 10)
    Instance.new("UIPadding", frame).PaddingLeft = UDim.new(0, 10)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Text = title:upper()
    lbl.TextColor3 = Theme.Accent
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    return frame
end

local function addToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = frame
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -44, 0.5, -11)
    btn.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(30,30,40)
    btn.Text = ""
    mkCorner(btn, 11)
    btn.Parent = frame
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = Theme.Text
    mkCorner(dot, 9)
    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = on and Theme.Accent or Color3.fromRGB(30,30,40)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.25), {Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
        callback(on)
    end)
end

local function addSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = frame
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 25)
    bar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    mkCorner(bar, 3)
    bar.Parent = frame
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    mkCorner(fill, 3)
    fill.Parent = bar
    local handle = Instance.new("Frame", bar)
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.Position = UDim2.new((default-min)/(max-min), -7, 0.5, -7)
    handle.BackgroundColor3 = Theme.Text
    mkCorner(handle, 7)
    handle.Parent = bar
    local dragging = false
    local function update(inp)
        local pos = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        handle.Position = UDim2.new(pos, -7, 0.5, -7)
        lbl.Text = text .. ": " .. val
        callback(val)
    end
    handle.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UIS.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then update(inp) end end)
end

local function addButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    mkCorner(btn, 8)
    mkStroke(btn, Theme.Border, 1)
    btn.MouseButton1Click:Connect(callback)
end

-- [[ MAIN UI ]] --
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "D4VID_ULTIMATE"
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 620, 0, 420)
main.Position = UDim2.new(0.5, -310, 0.5, -210)
main.BackgroundColor3 = Theme.MainBg
mkCorner(main, 14)
mkStroke(main, Theme.Accent, 1.8)
makeDraggable(main)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.BackgroundColor3 = Theme.SidebarBg
mkCorner(sidebar, 14)
local sList = Instance.new("UIListLayout", sidebar)
sList.Padding = UDim.new(0, 6)
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 70)
Instance.new("UIPadding", sidebar).PaddingLeft = UDim.new(0, 10)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(0, 180, 0, 70)
title.Text = "D4VID HUB V4"
title.TextColor3 = Theme.Accent
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.BackgroundTransparency = 1

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -190, 1, -20)
content.Position = UDim2.new(0, 185, 0, 10)
content.BackgroundTransparency = 1

-- MOBILE
local mbBtn = Instance.new("TextButton", gui)
mbBtn.Size = UDim2.new(0, 60, 0, 60)
mbBtn.Position = UDim2.new(0, 10, 0.5, -30)
mbBtn.BackgroundColor3 = Theme.Accent
mbBtn.Text = "D4VID"
mbBtn.TextColor3 = Theme.Text
mbBtn.Font = Enum.Font.GothamBlack
mkCorner(mbBtn, 30)
mbBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

-- TABS
local homeTab = addTab(sidebar, content, "Home")
local welcome = makeSection(homeTab, "Welcome")
local info = Instance.new("TextLabel", welcome)
info.Size = UDim2.new(1, 0, 0, 80)
info.Text = "D4VID HUB V4 ULTIMATE\nBetter than Envy & Cursed\nStatus: Undetected\n0 Lagback Active"
info.TextColor3 = Theme.Text
info.Font = Enum.Font.GothamBold
info.TextSize = 14
info.BackgroundTransparency = 1
addButton(welcome, "Reset Character", function() LP.Character:BreakJoints() end)

local combat = addTab(sidebar, content, "Combat")
local cSec = makeSection(combat, "Duel v4 Features")
addToggle(cSec, "Bat Aimbot", false, function(v) State.batAimbotToggled = v; if v then startBatAimbot() end end)
addToggle(cSec, "Auto Swing", false, function(v) State.autoSwingEnabled = v end)
addToggle(cSec, "Auto Parry V2", false, function(v) State.autoParryV2Enabled = v; if v then startAutoParryV2() end end)
addToggle(cSec, "Silent Aim", false, function(v) State.silentAimEnabled = v; if v then startSilentAim() end end)
addToggle(cSec, "Hitbox Expander", false, function(v) State.hitboxExpandEnabled = v; if v then startHitboxExpand() else stopHitboxExpand() end end)
addToggle(cSec, "Cam Lock", false, function(v) State.camLockEnabled = v; if v then startCamLock() end end)
addToggle(cSec, "Anti Counter", false, function(v) State.antiCounterEnabled = v; if v then startAntiCounter() end end)

local sab = addTab(sidebar, content, "SAB")
local sSec = makeSection(sab, "Survival Tools")
addToggle(sSec, "Anti Ragdoll", false, function(v) State.antiRagdollEnabled = v; if v then startAntiRagdoll() end end)
addToggle(sSec, "Bat Counter", false, function(v) State.batCounterEnabled = v; if v then startBatCounter() end end)
addToggle(sSec, "Medusa Counter", false, function(v) State.medusaCounterEnabled = v; if v then startMedusaCounter() end end)

local auto = addTab(sidebar, content, "Auto")
local aSec = makeSection(auto, "Automation")
addToggle(aSec, "Auto Steal", false, function(v) State.autoStealEnabled = v; if v then startAutoSteal() end end)

local visuals = addTab(sidebar, content, "Visuals")
local vSec = makeSection(visuals, "ESP")
addToggle(vSec, "Player ESP", false, function(v) State.espEnabled = v; if v then startESP() end end)

local movement = addTab(sidebar, content, "Movement")
local mSec = makeSection(movement, "Mobility")
addSlider(mSec, "Speed", 16, 250, State.normalSpeed, function(v) State.normalSpeed = v end)
addToggle(mSec, "Infinite Jump", false, function(v) State.infJumpEnabled = v end)

-- INIT
tabObjs["Home"].page.Visible = true
tabObjs["Home"].btn.BackgroundColor3 = Theme.TabActive
tabObjs["Home"].btn.TextColor3 = Theme.Text

print("[D4VID HUB] V4 ULTIMATE - LOADED")