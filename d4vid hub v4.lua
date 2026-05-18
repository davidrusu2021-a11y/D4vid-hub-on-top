repeat task.wait() until game:IsLoaded()
-- ============================================================
-- D4VID HUB v3.0 - ALL FEATURES + KEYBINDS
-- ============================================================

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting        = game:GetService("Lighting")
local LP              = Players.LocalPlayer

local _isfile   = isfile   or (syn and syn.isfile)   or function() return false end
local _readfile = readfile  or (syn and syn.readfile)  or function() return nil  end
local _writefile= writefile or (syn and syn.writefile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    normalSpeed=59, carrySpeed=30, laggerSpeed=60,
    aimbotSpeed=56.5,
    speedToggled=false, laggerEnabled=false,
    infJumpEnabled=false, antiRagdollEnabled=false, fpsBoostEnabled=false,
    guiVisible=true, uiLocked=false,
    isStealing=false, stealStartTime=nil, lastStealTick=0,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false,
    hittingCooldown=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, batLockEnabled=false,
    lastMoveDir=Vector3.new(0,0,0),
    unwalkEnabled=false,
    _prevCarry=30, _prevSpeed=false,
    _laggerOriginalCarry=30,
    autoStealEnabled=false,
    duelLaggerActive=false,
    duelLaggerThread=nil,
    countdownActive=false,
    -- v3.0 DUEL FEATURES
    espEnabled=false,
    espConn=nil,
    posESPEnabled=false,
    silentAimEnabled=false,
    brainrotStealEnabled=false,
    ghostModeEnabled=false,
    predictiveAimEnabled=false,
    antiCounterEnabled=false,
    duelSpeedBypass=false,
    duelNormalSpeed=57,
    duelCarrySpeed=27,
    -- v4.0 NEW OP FEATURES
    hitboxExpandEnabled=false,
    autoParryV2Enabled=false,
    teleStealEnabled=false,
    noclipEnabled=false,
    spinbotEnabled=false,
    camLockEnabled=false,
    autoResetEnabled=false,
}

local Keys = {
    speed      = Enum.KeyCode.Q,
    lagger     = Enum.KeyCode.R,
    autoLeft   = Enum.KeyCode.Z,
    autoRight  = Enum.KeyCode.C,
    drop       = Enum.KeyCode.H,
    tpDown     = Enum.KeyCode.V,
    aimbot     = Enum.KeyCode.E,
    unwalk     = Enum.KeyCode.U,
    guiHide    = Enum.KeyCode.LeftControl,
    duelLagger = Enum.KeyCode.F,
    instaReset   = Enum.KeyCode.G,
    esp          = Enum.KeyCode.K,
    silentAim    = Enum.KeyCode.Y,
    ghostMode    = Enum.KeyCode.O,
    duelSpeed    = Enum.KeyCode.L,
    hitboxExpand = Enum.KeyCode.J,
    autoParryV2  = Enum.KeyCode.N,
    teleSteal    = Enum.KeyCode.T,
    camLock      = Enum.KeyCode.M,
    noclip       = Enum.KeyCode.P,
    spinbot      = Enum.KeyCode.B,
}

local Steal = {
    AutoStealEnabled=false, StealRadius=20, StealDuration=0.25,
    Data={}, plotCache={}, plotCacheTime={}, cachedPrompts={}, promptCacheTime=0,
}

local Presets = {}
local PRESET_FILE = "d4vidhubPresets.json"
local LAST_PRESET_FILE = "d4vidhubLastPreset.json"
local CONFIG_FILE = "d4vidhubConfig.json"

local POS={
    L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
    R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,anchor={},progress=nil,batCounter=nil,unwalk=nil}

local PLOT_CACHE_DURATION=2
local PROMPT_CACHE_REFRESH=0.15
local STEAL_COOLDOWN=0.1
local MEDUSA_COOLDOWN=25
local DROP_AUTO_OFF_DELAY=0.15

local isTouchEnabled = UIS.TouchEnabled
local duelLaggerWaitTime = isTouchEnabled and 5.8 or 0.25

local h,hrp
local speedBoxRefs={}
local keybindBtnRefs={}
local toggleRefs={}
local mbGroup
local setAL, setAR, setAB

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function getKeyName(kc)
    local n = kc.Name
    if n == "Unknown" then return "—" end
    if n == "LeftControl" then return "CTRL" end
    if n == "RightControl" then return "RCTL" end
    if n == "LeftShift" then return "SHFT" end
    if n == "Space" then return "SPC" end
    return n:sub(1, 4):upper()
end


-- ============================================================
-- PRESET FUNCTIONS
-- ============================================================
local function buildPresetSnapshot()
    return {
        normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed, laggerSpeed=State.laggerSpeed,
        aimbotSpeed=State.aimbotSpeed,
        stealRadius=Steal.StealRadius, stealDuration=Steal.StealDuration,
        infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
        fpsBoost=State.fpsBoostEnabled, medusaCounter=State.medusaCounterEnabled,
        batCounter=State.batCounterEnabled, autoSteal=Steal.AutoStealEnabled,
    }
end

local function savePresetsFile()
    local ok,encoded=pcall(function() return HttpService:JSONEncode(Presets) end)
    if ok then pcall(function() _writefile(PRESET_FILE,encoded) end) end
end

local function loadPresetsFile()
    local hasFile=false; pcall(function() hasFile=_isfile(PRESET_FILE) end)
    if not hasFile then return end
    local raw; pcall(function() raw=_readfile(PRESET_FILE) end)
    if not raw then return end
    local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then Presets=decoded end
end

local function saveLastPresetName(name)
    local ok,encoded=pcall(function() return HttpService:JSONEncode({lastPreset=name}) end)
    if ok then pcall(function() _writefile(LAST_PRESET_FILE,encoded) end) end
end

local function loadLastPresetName()
    local hasFile=false; pcall(function() hasFile=_isfile(LAST_PRESET_FILE) end)
    if not hasFile then return nil end
    local raw; pcall(function() raw=_readfile(LAST_PRESET_FILE) end)
    if not raw then return nil end
    local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then return decoded.lastPreset end
    return nil
end

-- ============================================================
-- CONFIG SAVE/LOAD
-- ============================================================
local function saveConfig()
    local cfg = {
        normalSpeed = State.normalSpeed,
        carrySpeed = State.carrySpeed,
        laggerSpeed = State.laggerSpeed,
        aimbotSpeed = State.aimbotSpeed,
        stealRadius = Steal.StealRadius,
        stealDuration = Steal.StealDuration,
        speedKey = Keys.speed.Name,
        autoLeftKey = Keys.autoLeft.Name,
        autoRightKey = Keys.autoRight.Name,
        guiHideKey = Keys.guiHide.Name,
        dropKey = Keys.drop.Name,
        laggerKey = Keys.lagger.Name,
        tpDownKey = Keys.tpDown.Name,
        aimbotKey = Keys.aimbot.Name,
        unwalkKey = Keys.unwalk.Name,
        duelLaggerKey = Keys.duelLagger.Name,
        instaResetKey = Keys.instaReset.Name,
    }
    local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok and enc then 
        pcall(function() _writefile(CONFIG_FILE, enc) end) 
    end
end

local function loadConfig()
    local has = false
    pcall(function() has = _isfile(CONFIG_FILE) end)
    if not has then return end
    local raw
    pcall(function() raw = _readfile(CONFIG_FILE) end)
    if not raw then return end
    local cfg
    local ok = pcall(function() cfg = HttpService:JSONDecode(raw) end)
    if not ok or not cfg then return end
    
    if cfg.normalSpeed then State.normalSpeed = cfg.normalSpeed end
    if cfg.carrySpeed then State.carrySpeed = cfg.carrySpeed end
    if cfg.laggerSpeed then State.laggerSpeed = cfg.laggerSpeed end
    if cfg.aimbotSpeed then State.aimbotSpeed = cfg.aimbotSpeed end
    if cfg.stealRadius then Steal.StealRadius = cfg.stealRadius end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration end
    
    local function tryKey(field, kt)
        if cfg[field] and Enum.KeyCode[cfg[field]] then
            Keys[kt] = Enum.KeyCode[cfg[field]]
        end
    end
    tryKey("speedKey", "speed")
    tryKey("autoLeftKey", "autoLeft")
    tryKey("autoRightKey", "autoRight")
    tryKey("guiHideKey", "guiHide")
    tryKey("dropKey", "drop")
    tryKey("laggerKey", "lagger")
    tryKey("tpDownKey", "tpDown")
    tryKey("aimbotKey", "aimbot")
    tryKey("unwalkKey", "unwalk")
    tryKey("duelLaggerKey", "duelLagger")
    tryKey("instaResetKey", "instaReset")
end

-- ============================================================
-- CLEANUP OLD GUIs
-- ============================================================
for _,name in pairs({"d4vidhubV1_0","opiumhubV5_3"}) do
    pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
    pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
end

-- ============================================================
-- ROOT GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "d4vidhubV1_0"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then pcall(function() gui.Parent = LP.PlayerGui end) end

local uiScaleObj=Instance.new("UIScale",gui)
uiScaleObj.Scale=1.0

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    bg          = Color3.fromRGB(8, 6, 16),
    panel       = Color3.fromRGB(22, 18, 36),
    card        = Color3.fromRGB(28, 22, 46),
    cardHov     = Color3.fromRGB(36, 28, 58),
    border      = Color3.fromRGB(80, 40, 130),
    borderDim   = Color3.fromRGB(50, 28, 80),
    text        = Color3.fromRGB(230, 230, 230),
    textSub     = Color3.fromRGB(130, 130, 130),
    textDim     = Color3.fromRGB(75, 75, 75),
    accent      = Color3.fromRGB(255, 255, 255),
    pillOff     = Color3.fromRGB(38, 38, 38),
    pillOn      = Color3.fromRGB(72, 30, 140),
    dotOff      = Color3.fromRGB(65, 65, 65),
    dotOn       = Color3.fromRGB(200, 160, 255),
    header      = Color3.fromRGB(12, 8, 22),
    chipBg      = Color3.fromRGB(40, 24, 70),
    chipText    = Color3.fromRGB(180, 140, 240),
}


-- ============================================================
-- HELPERS
-- ============================================================
local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function mkStroke(p,col,th)
    local s=Instance.new("UIStroke",p); s.Color=col or Color3.fromRGB(50,50,50); s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end

local function makeDraggable(frame, handle, force)
    local src=handle or frame
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
    src.InputBegan:Connect(function(inp)
        if State.uiLocked and not force then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=frame.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    src.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp==dragInput and dragging and (force or not State.uiLocked) then
            local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
        end
    end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local WIN_W = 270
local WIN_H = 480

local mainOuter = Instance.new("Frame", gui)
mainOuter.Name = "MainOuter"
mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainOuter.Position = UDim2.new(0, 8, 0, 8)
mainOuter.BackgroundColor3 = C.bg
mainOuter.BorderSizePixel = 0
mainOuter.ClipsDescendants = false
mkCorner(mainOuter, 14)
mkStroke(mainOuter, Color3.fromRGB(80, 40, 150), 1)
makeDraggable(mainOuter)

-- ============================================================
-- HEADER
-- ============================================================
local HEADER_H = 72
local headerFrame = Instance.new("Frame", mainOuter)
headerFrame.Size = UDim2.new(1, 0, 0, HEADER_H)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundColor3 = C.header
headerFrame.BorderSizePixel = 0
headerFrame.ZIndex = 3
mkCorner(headerFrame, 14)

local accentStripe = Instance.new("Frame", headerFrame)
accentStripe.Size = UDim2.new(0, 3, 0, 44)
accentStripe.Position = UDim2.new(0, 0, 0.5, -22)
accentStripe.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
accentStripe.BorderSizePixel = 0
accentStripe.ZIndex = 4
mkCorner(accentStripe, 2)

local avatarBg = Instance.new("Frame", headerFrame)
avatarBg.Size = UDim2.new(0, 40, 0, 40)
avatarBg.Position = UDim2.new(0, 14, 0.5, -20)
avatarBg.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
avatarBg.BorderSizePixel = 0
avatarBg.ZIndex = 4
mkCorner(avatarBg, 20)
mkStroke(avatarBg, Color3.fromRGB(55, 55, 55), 1)

local avatarImg = Instance.new("ImageLabel", avatarBg)
avatarImg.Size = UDim2.new(1, -4, 1, -4)
avatarImg.Position = UDim2.new(0, 2, 0, 2)
avatarImg.BackgroundTransparency = 1
avatarImg.Image = ""
avatarImg.ZIndex = 5
mkCorner(avatarImg, 18)

local usernameLbl = Instance.new("TextLabel", headerFrame)
usernameLbl.Size = UDim2.new(1, -120, 0, 18)
usernameLbl.Position = UDim2.new(0, 62, 0, 14)
usernameLbl.BackgroundTransparency = 1
usernameLbl.Text = LP.DisplayName
usernameLbl.TextColor3 = C.text
usernameLbl.Font = Enum.Font.GothamBlack
usernameLbl.TextSize = 13
usernameLbl.TextXAlignment = Enum.TextXAlignment.Left
usernameLbl.ZIndex = 4

local handleLbl = Instance.new("TextLabel", headerFrame)
handleLbl.Size = UDim2.new(1, -120, 0, 12)
handleLbl.Position = UDim2.new(0, 62, 0, 33)
handleLbl.BackgroundTransparency = 1
handleLbl.Text = "@" .. LP.Name
handleLbl.TextColor3 = C.textSub
handleLbl.Font = Enum.Font.Gotham
handleLbl.TextSize = 9
handleLbl.TextXAlignment = Enum.TextXAlignment.Left
handleLbl.ZIndex = 4

local badgeBg = Instance.new("Frame", headerFrame)
badgeBg.Size = UDim2.new(0, 76, 0, 14)
badgeBg.Position = UDim2.new(0, 62, 0, 50)
badgeBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
badgeBg.BorderSizePixel = 0
badgeBg.ZIndex = 4
mkCorner(badgeBg, 4)
mkStroke(badgeBg, Color3.fromRGB(60, 60, 60), 1)

local badgeLbl = Instance.new("TextLabel", badgeBg)
badgeLbl.Size = UDim2.new(1, 0, 1, 0)
badgeLbl.BackgroundTransparency = 1
badgeLbl.Text = "D4VID HUB"
badgeLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
badgeLbl.Font = Enum.Font.GothamBold
badgeLbl.TextSize = 8
badgeLbl.ZIndex = 5

task.spawn(function()
    pcall(function()
        local img = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        avatarImg.Image = img
    end)
end)

local minimizeBtn = Instance.new("TextButton", headerFrame)
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Position = UDim2.new(1, -32, 0, 8)
minimizeBtn.BackgroundColor3 = C.card
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = C.textSub
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 11
minimizeBtn.ZIndex = 5
mkCorner(minimizeBtn, 6)
mkStroke(minimizeBtn, C.border, 1)
minimizeBtn.MouseButton1Click:Connect(function()
    mainOuter.Visible = false
end)

local headerDiv = Instance.new("Frame", mainOuter)
headerDiv.Size = UDim2.new(1, 0, 0, 1)
headerDiv.Position = UDim2.new(0, 0, 0, HEADER_H)
headerDiv.BackgroundColor3 = C.border
headerDiv.BorderSizePixel = 0
headerDiv.ZIndex = 3


-- ============================================================
-- SPEED DISPLAY BAR
-- ============================================================
local speedBar = Instance.new("Frame", mainOuter)
speedBar.Size = UDim2.new(1, 0, 0, 50)
speedBar.Position = UDim2.new(0, 0, 0, HEADER_H + 1)
speedBar.BackgroundColor3 = Color3.fromRGB(10, 6, 20)
speedBar.BorderSizePixel = 0
speedBar.ZIndex = 3

local speedLL = Instance.new("UIListLayout", speedBar)
speedLL.FillDirection = Enum.FillDirection.Horizontal
speedLL.SortOrder = Enum.SortOrder.LayoutOrder
speedLL.Padding = UDim.new(0, 0)

local function makeSpeedCol(label, stateKey, order)
    local col = Instance.new("Frame", speedBar)
    col.Size = UDim2.new(1/3, 0, 1, 0)
    col.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    col.BorderSizePixel = 0
    col.ZIndex = 3
    col.LayoutOrder = order

    if order < 3 then
        local div = Instance.new("Frame", col)
        div.Size = UDim2.new(0, 1, 0.6, 0)
        div.Position = UDim2.new(1, 0, 0.2, 0)
        div.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        div.BorderSizePixel = 0
        div.ZIndex = 4
    end

    local lbl = Instance.new("TextLabel", col)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Position = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.textSub
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 8
    lbl.ZIndex = 4

    local valWrap = Instance.new("Frame", col)
    valWrap.Size = UDim2.new(0.82, 0, 0, 24)
    valWrap.Position = UDim2.new(0.09, 0, 0, 20)
    valWrap.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    valWrap.BorderSizePixel = 0
    valWrap.ZIndex = 4
    mkCorner(valWrap, 7)
    mkStroke(valWrap, Color3.fromRGB(45, 45, 45), 1)

    local valBox = Instance.new("TextBox", valWrap)
    valBox.Size = UDim2.new(1, 0, 1, 0)
    valBox.Position = UDim2.new(0, 0, 0, 0)
    valBox.BackgroundTransparency = 1
    valBox.Text = tostring(State[stateKey])
    valBox.TextColor3 = C.text
    valBox.Font = Enum.Font.GothamBlack
    valBox.TextSize = 14
    valBox.ClearTextOnFocus = false
    valBox.ZIndex = 5
    valBox.FocusLost:Connect(function()
        local n = tonumber(valBox.Text)
        if n and n > 0 and n <= 500 then
            State[stateKey] = n
            valBox.Text = tostring(n)
        else
            valBox.Text = tostring(State[stateKey])
        end
        task.spawn(saveConfig)
    end)
    speedBoxRefs[stateKey] = valBox
    return valBox
end

makeSpeedCol("Normal", "normalSpeed", 1)
makeSpeedCol("Carry", "carrySpeed", 2)
makeSpeedCol("Lagger", "laggerSpeed", 3)

local speedBarDiv = Instance.new("Frame", mainOuter)
speedBarDiv.Size = UDim2.new(1, 0, 0, 1)
speedBarDiv.Position = UDim2.new(0, 0, 0, HEADER_H + 50)
speedBarDiv.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedBarDiv.BorderSizePixel = 0
speedBarDiv.ZIndex = 3

-- ============================================================
-- SCROLL AREA
-- ============================================================
local SCROLL_Y = HEADER_H + 51
local scrollFrame = Instance.new("ScrollingFrame", mainOuter)
scrollFrame.Size = UDim2.new(1, 0, 1, -SCROLL_Y)
scrollFrame.Position = UDim2.new(0, 0, 0, SCROLL_Y)
scrollFrame.BackgroundColor3 = Color3.fromRGB(8, 6, 16)
scrollFrame.BackgroundTransparency = 0
scrollFrame.BorderSizePixel = 0
scrollFrame.ClipsDescendants = true
scrollFrame.ScrollBarThickness = 2
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 180)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ZIndex = 2
mkCorner(scrollFrame, 14)

local scrollLL = Instance.new("UIListLayout", scrollFrame)
scrollLL.SortOrder = Enum.SortOrder.LayoutOrder
scrollLL.Padding = UDim.new(0, 2)

local scrollPad = Instance.new("UIPadding", scrollFrame)
scrollPad.PaddingLeft = UDim.new(0, 10)
scrollPad.PaddingRight = UDim.new(0, 10)
scrollPad.PaddingTop = UDim.new(0, 8)
scrollPad.PaddingBottom = UDim.new(0, 12)

local loCount = 0
local function LO() loCount = loCount + 1; return loCount end

-- ============================================================
-- SECTION HEADER
-- ============================================================
local function makeSectionHeader(label)
    local gap = Instance.new("Frame", scrollFrame)
    gap.Size = UDim2.new(1, 0, 0, 4)
    gap.BackgroundTransparency = 1
    gap.BorderSizePixel = 0
    gap.LayoutOrder = LO()

    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label:upper()
    lbl.TextColor3 = Color3.fromRGB(168, 85, 247)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
end

local function makeDivider()
    local f = Instance.new("Frame", scrollFrame)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    f.BorderSizePixel = 0
    f.LayoutOrder = LO()
end


-- ============================================================
-- TOGGLE ROW WITH KEYBIND SUPPORT
-- ============================================================
local function makeToggleRow(label, defaultOn, onToggle, keyRef)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -28, 0, 1)
    div.Position = UDim2.new(0, 14, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BorderSizePixel = 0
    div.ZIndex = 4

    local lblX = 14
    
    if keyRef then
        local chip = Instance.new("TextButton", row)
        chip.Size = UDim2.new(0, 26, 0, 18)
        chip.Position = UDim2.new(0, 14, 0.5, -9)
        chip.BackgroundColor3 = C.chipBg
        chip.BorderSizePixel = 0
        chip.Text = getKeyName(Keys[keyRef] or Enum.KeyCode.Unknown)
        chip.TextColor3 = C.chipText
        chip.Font = Enum.Font.GothamBold
        chip.TextSize = 9
        chip.ZIndex = 5
        mkCorner(chip, 6)
        mkStroke(chip, C.borderDim, 1)
        keybindBtnRefs[keyRef] = chip
        
        local listening = false
        local lkb, lgp = nil, nil
        
        local function stopListening(key)
            listening = false
            if lkb then lkb:Disconnect(); lkb = nil end
            if lgp then lgp:Disconnect(); lgp = nil end
            chip.TextColor3 = C.chipText
            if key then
                Keys[keyRef] = key
                chip.Text = getKeyName(key)
                task.spawn(saveConfig)
            else
                chip.Text = getKeyName(Keys[keyRef] or Enum.KeyCode.Unknown)
            end
        end
        
        chip.MouseButton1Click:Connect(function()
            if listening then stopListening(nil); return end
            listening = true
            chip.Text = "···"
            chip.TextColor3 = C.text
            
            lkb = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then stopListening(nil); return end
                stopListening(inp.KeyCode)
            end)
            
            lgp = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                local isGp = inp.UserInputType == Enum.UserInputType.Gamepad1 or 
                            inp.UserInputType == Enum.UserInputType.Gamepad2
                if not isGp then return end
                if inp.KeyCode == Enum.KeyCode.Unknown then return end
                stopListening(inp.KeyCode)
            end)
        end)
        
        lblX = 46
    end

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -(lblX + 66), 1, 0)
    lbl.Position = UDim2.new(0, lblX, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0, 36, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, -10)
    pill.BackgroundColor3 = defaultOn and C.pillOn or C.pillOff
    pill.BorderSizePixel = 0
    pill.ZIndex = 5
    mkCorner(pill, 12)
    mkStroke(pill, C.border, 1)

    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = defaultOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = defaultOn and C.dotOn or C.dotOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 6
    mkCorner(dot, 8)

    local isOn = defaultOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
    end
    local function toggle() isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end end

    local clk = Instance.new("TextButton", row)
    clk.Size = UDim2.new(1, -54, 1, 0)
    clk.Position = UDim2.new(0, lblX, 0, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 5
    clk.BorderSizePixel = 0
    clk.MouseButton1Click:Connect(toggle)

    local pClk = Instance.new("TextButton", pill)
    pClk.Size = UDim2.new(1, 0, 1, 0)
    pClk.BackgroundTransparency = 1
    pClk.Text = ""
    pClk.ZIndex = 7
    pClk.BorderSizePixel = 0
    pClk.MouseButton1Click:Connect(toggle)

    return setV
end

-- ============================================================
-- INPUT ROW
-- ============================================================
local function makeInputRow(label, default, onChange)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -28, 0, 1)
    div.Position = UDim2.new(0, 14, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BorderSizePixel = 0
    div.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4

    local boxWrap = Instance.new("Frame", row)
    boxWrap.Size = UDim2.new(0, 58, 0, 24)
    boxWrap.Position = UDim2.new(1, -68, 0.5, -12)
    boxWrap.BackgroundColor3 = C.card
    boxWrap.BorderSizePixel = 0
    mkCorner(boxWrap, 6)
    local bs = mkStroke(boxWrap, C.border, 1)

    local box = Instance.new("TextBox", boxWrap)
    box.Size = UDim2.new(1, -8, 1, 0)
    box.Position = UDim2.new(0, 4, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = tostring(default)
    box.TextColor3 = C.text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.ZIndex = 5
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.Focused:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=Color3.fromRGB(120,120,120)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=C.border}):Play()
        if onChange then
            local n=tonumber(box.Text)
            if n then onChange(n) else box.Text=tostring(default) end
        end
    end)
    
    return box, row
end

-- ============================================================
-- BUTTON ROW
-- ============================================================
local function makeButtonRow(label, btnText, onClick)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.bg
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -28, 0, 1)
    div.Position = UDim2.new(0, 14, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BorderSizePixel = 0
    div.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 64, 0, 24)
    btn.Position = UDim2.new(1, -76, 0.5, -12)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0
    btn.Text = btnText
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.ZIndex = 5
    mkCorner(btn, 7)
    mkStroke(btn, C.border, 1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C.cardHov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play() end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end


-- ============================================================
-- FUNCTIONS (CORE LOGIC) - FIXED BAT AIMBOT & INFINITE JUMP
-- ============================================================

-- TP DOWN
local function doTpDown()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local res=workspace:Raycast(root.Position,Vector3.new(0,-1000,0),rp)
        if res then
            root.CFrame=CFrame.new(res.Position+Vector3.new(0,root.Size.Y/2+0.5,0))
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end)
end

-- DROP BRAINROT
local function runDropBrainrot()
    if State.dropEnabled then return end
    State.dropEnabled=true
    task.spawn(function()
        local colConn=RunService.Stepped:Connect(function()
            if not State.dropEnabled then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and p.Character then
                    for _,part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide=false end
                    end
                end
            end
        end)
        task.spawn(function()
            while State.dropEnabled do
                RunService.Heartbeat:Wait()
                local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local vel=root.Velocity
                root.Velocity=vel*10000+Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.Velocity=vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
            end
        end)
        task.wait(DROP_AUTO_OFF_DELAY)
        State.dropEnabled=false
        colConn:Disconnect()
    end)
end

-- ============================================================
-- FIXED BAT AIMBOT - PROPERLY FINDS BAT & CORRECT VELOCITY
-- ============================================================
local VYSE_AIMBOT_SPEED = 56.5
local VYSE_HIT_DIST = 5
local SWING_COOLDOWN = 0.08

-- Get Bat Tool (FIXED)
local function getBat()
    local char = LP.Character
    if not char then return nil end
    
    -- Check equipped
    local tool = char:FindFirstChild("Bat")
    if tool and tool:IsA("Tool") then return tool end
    
    -- Check backpack
    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        tool = backpack:FindFirstChild("Bat")
        if tool and tool:IsA("Tool") then
            -- Equip it
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:EquipTool(tool) end)
            end
            return tool
        end
    end
    return nil
end

-- Swing Bat (FIXED)
local function tryHitBat()
    if State.hittingCooldown then return end
    State.hittingCooldown = true
    
    pcall(function()
        local bat = getBat()
        if bat then
            pcall(function() bat:Activate() end)
            local remote = bat:FindFirstChildWhichIsA("RemoteEvent")
            if remote then
                pcall(function() remote:FireServer() end)
            end
        end
    end)
    
    task.delay(SWING_COOLDOWN, function()
        State.hittingCooldown = false
    end)
end

-- Get Closest Player (FIXED - with health check)
local function getClosestPlayer()
    local char = LP.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    
    local closest, dist = nil, math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health > 0 then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = p
                end
            end
        end
    end
    return closest, dist
end

-- Start Bat Aimbot (FIXED - correct velocity calculation)
local function startBatAimbot()
    if Conns.aimbot then return end
    
    Conns.aimbot = RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end
        if State.countdownActive then return end  -- ANTI-DETECT: Stop during countdown
        
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local target, dist = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local aimPoint = tr.Position + tr.CFrame.LookVector * 1.5
                local direction = (aimPoint - hrp.Position).Unit
                
                -- FIXED: Use State.aimbotSpeed directly
                hrp.Velocity = direction * State.aimbotSpeed
                
                if dist <= VYSE_HIT_DIST and State.autoSwingEnabled then
                    tryHitBat()
                end
            end
        else
            hrp.Velocity = Vector3.zero
        end
    end)
end

-- Stop Bat Aimbot
local function stopBatAimbot()
    if Conns.aimbot then
        Conns.aimbot:Disconnect()
        Conns.aimbot = nil
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Vector3.zero end
    State.hittingCooldown = false
end

-- ============================================================
-- FIXED INFINITE JUMP - DIRECT VELOCITY METHOD (WORKING)
-- ============================================================

-- Main Infinite Jump (FIXED)
UIS.JumpRequest:Connect(function()
    if not State.infJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
    end
end)

-- Anti-Fall Velocity Cap (FIXED)
RunService.Heartbeat:Connect(function()
    if not State.infJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.Velocity.Y < -120 then
        root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z)
    end
end)


-- ============================================================
-- DUEL LAGGER ENGINE
-- ============================================================
local function duelBomb(amt)
    local main, spam = {}, {{}}
    local z = spam[1]
    for i = 1, amt do
        local t = {}
        table.insert(z, t)
        z = t
    end
    local max = math.min(499999/(amt+2), 1500)
    for i = 1, max do
        table.insert(main, spam)
    end
    pcall(function()
        game:GetService("RobloxReplicatedStorage").SetPlayerBlockList:FireServer(main)
    end)
end

local duelLaggerStatusLabel = nil
local duelLaggerSwitchBall = nil

local function toggleDuelLagger()
    State.duelLaggerActive = not State.duelLaggerActive

    if duelLaggerStatusLabel then
        duelLaggerStatusLabel.Text = State.duelLaggerActive and "STATUS: ACTIVE" or "STATUS: INACTIVE"
        duelLaggerStatusLabel.TextColor3 = State.duelLaggerActive
            and Color3.fromRGB(220, 220, 220)
            or Color3.fromRGB(90, 90, 90)
    end

    if duelLaggerSwitchBall then
        TweenService:Create(duelLaggerSwitchBall, TweenInfo.new(0.2), {
            Position = State.duelLaggerActive
                and UDim2.new(1, -16, 0.5, -8)
                or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = State.duelLaggerActive
                and Color3.fromRGB(220, 220, 220)
                or Color3.fromRGB(60, 60, 60),
        }):Play()
    end

    if State.duelLaggerActive then
        State.duelLaggerThread = task.spawn(function()
            while State.duelLaggerActive do
                pcall(function()
                    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
                end)
                duelBomb(270)
                task.wait(duelLaggerWaitTime)
            end
        end)
    else
        if State.duelLaggerThread then
            task.cancel(State.duelLaggerThread)
            State.duelLaggerThread = nil
        end
    end
end

-- ============================================================
-- MEDUSA COUNTER
-- ============================================================
local function findMedusa()
    local c=LP.Character; if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n=t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then return t end
        end
    end
    local bp=LP:FindFirstChild("Backpack")
    if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n=t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then return t end
            end
        end
    end
    return nil
end

local function useMedusaCounter()
    if State.medusaDebounce then return end
    if tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
    local c=LP.Character; if not c then return end
    State.medusaDebounce=true
    local med=findMedusa()
    if not med then State.medusaDebounce=false; return end
    if med.Parent~=c then
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    State.medusaLastUsed=tick()
    State.medusaDebounce=false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency==1 then useMedusaCounter() end
    end)
end

local function setupMedusaCounter(char)
    for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end
    Conns.anchor={}
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
    end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
    end))
end

local function stopMedusaCounter()
    for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end
    Conns.anchor={}
end

-- ============================================================
-- ANTI RAGDOLL
-- ============================================================
local function startAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect() end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        if not State.antiRagdollEnabled then return end
        local c=LP.Character; if not c then return end
        local hum2=c:FindFirstChildOfClass("Humanoid")
        local root=c:FindFirstChild("HumanoidRootPart")
        if not hum2 or not root then return end
        if hum2.Health<=0 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Dead then return end
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            pcall(function() workspace.CurrentCamera.CameraSubject=hum2 end)
            pcall(function()
                local PM=LP.PlayerScripts:FindFirstChild("PlayerModule")
                if PM then
                    local CM=require(PM:FindFirstChild("ControlModule"))
                    if CM then CM:Enable() end
                end
            end)
            root.Velocity=Vector3.new(0,0,0)
            root.RotVelocity=Vector3.new(0,0,0)
        end
        for _,obj in ipairs(c:GetDescendants()) do
            pcall(function()
                if obj:IsA("Motor6D") and obj.Enabled==false then obj.Enabled=true end
            end)
        end
    end)
end

local function stopAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end
end

-- ============================================================
-- AUTO LEFT / RIGHT
-- ============================================================
local function faceSouth()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,0,0) end
    end)
end

local function faceNorth()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.rad(180),0) end
    end)
end

local function startAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect() end
    State.autoLeftPhase=1
    Conns.autoLeft=RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled then return end
        if State.countdownActive then return end  -- ANTI-DETECT: Stop during countdown
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoLeftPhase==1 then
            local tgt=Vector3.new(POS.L1.X,root.Position.Y,POS.L1.Z)
            if (tgt-root.Position).Magnitude<1 then
                State.autoLeftPhase=2
                local d=(POS.L2-root.Position)
                local mv=Vector3.new(d.X,0,d.Z).Unit
                hum2:Move(mv,false)
                root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=(POS.L1-root.Position)
            local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false)
            root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoLeftPhase==2 then
            local tgt=Vector3.new(POS.L2.X,root.Position.Y,POS.L2.Z)
            if (tgt-root.Position).Magnitude<1 then
                hum2:Move(Vector3.zero,false)
                root.AssemblyLinearVelocity=Vector3.zero
                State.autoLeftEnabled=false
                if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end
                State.autoLeftPhase=1
                faceSouth()
                return
            end
            local d=(POS.L2-root.Position)
            local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false)
            root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function stopAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end
    State.autoLeftPhase=1
    local c=LP.Character
    if c then
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero,false) end
    end
end

local function startAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect() end
    State.autoRightPhase=1
    Conns.autoRight=RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled then return end
        if State.countdownActive then return end  -- ANTI-DETECT: Stop during countdown
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoRightPhase==1 then
            local tgt=Vector3.new(POS.R1.X,root.Position.Y,POS.R1.Z)
            if (tgt-root.Position).Magnitude<1 then
                State.autoRightPhase=2
                local d=(POS.R2-root.Position)
                local mv=Vector3.new(d.X,0,d.Z).Unit
                hum2:Move(mv,false)
                root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=(POS.R1-root.Position)
            local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false)
            root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoRightPhase==2 then
            local tgt=Vector3.new(POS.R2.X,root.Position.Y,POS.R2.Z)
            if (tgt-root.Position).Magnitude<1 then
                hum2:Move(Vector3.zero,false)
                root.AssemblyLinearVelocity=Vector3.zero
                State.autoRightEnabled=false
                if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end
                State.autoRightPhase=1
                faceNorth()
                return
            end
            local d=(POS.R2-root.Position)
            local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false)
            root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function stopAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end
    State.autoRightPhase=1
    local c=LP.Character
    if c then
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero,false) end
    end
end


-- ============================================================
-- BAT COUNTER
-- ============================================================
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function findBatForCounter()
    local c=LP.Character; if not c then return nil end
    local bp=LP:FindFirstChildOfClass("Backpack")
    for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _,ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _,ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

local function swingBatForCounter(bat,char)
    local hum2=char:FindFirstChildOfClass("Humanoid")
    if bat.Parent~=char then
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
        task.wait(0.05)
    end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end)
        task.wait(0.15)
        pcall(function() remote:FireServer() end)
    else
        pcall(function() bat:Activate() end)
        task.wait(0.15)
        pcall(function() bat:Activate() end)
    end
end

local function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled then return end
        if State.batCounterDebounce then return end
        local char=LP.Character; if not char then return end
        local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local st=hum2:GetState()
        local isRagdolled=st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
        if isRagdolled then
            State.batCounterDebounce=true
            task.spawn(function()
                local bat=findBatForCounter()
                if bat then swingBatForCounter(bat,char) end
                task.wait(0.5)
                State.batCounterDebounce=false
            end)
        end
    end)
end

local function stopBatCounter()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
    State.batCounterDebounce=false
end

-- ============================================================
-- UNWALK (NO ANIMATIONS)
-- ============================================================
local _unwalkAnimations={}

local function _disableAnimations()
    local char=LP.Character; if not char then return end
    local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
    for _,track in pairs(_unwalkAnimations) do pcall(function() track:Stop() end) end
    _unwalkAnimations={}
    local animator=hum2:FindFirstChildOfClass("Animator")
    if animator then
        for _,track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
            table.insert(_unwalkAnimations,track)
        end
    end
end

local function startUnwalk()
    _disableAnimations()
    if Conns.unwalk then Conns.unwalk:Disconnect() end
    Conns.unwalk=RunService.Heartbeat:Connect(function()
        if not State.unwalkEnabled then return end
        _disableAnimations()
    end)
end

local function stopUnwalk()
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    _unwalkAnimations={}
    local c=LP.Character
    if c then
        local anim=c:FindFirstChild("Animate")
        if anim and anim:IsA("LocalScript") and anim.Disabled then anim.Disabled=false end
    end
end

-- ============================================================
-- FPS BOOST
-- ============================================================
local function applyFPSBoost()
    pcall(function() setfpscap(999999999) end)
    local function pO(v) pcall(function()
        if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode=Enum.ModelStreamingMode.Nonatomic
        elseif v:IsA("MeshPart") then v.CastShadow=false; v.DoubleSided=false; v.RenderFidelity=Enum.RenderFidelity.Performance
        elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
        elseif v:IsA("SpecialMesh") then v.TextureId=""
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
        elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
        elseif v:IsA("Attachment") then v.Visible=false end
    end) end
    for _,v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        for _,v in pairs(Lighting:GetDescendants()) do pcall(function() if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end end) end
        pcall(function() sethiddenproperty(Lighting,"Technology",Enum.Technology.Legacy) end)
        Lighting.GlobalShadows=false; Lighting.FogEnd=9e9; Lighting.Brightness=0
        local ter=workspace:FindFirstChildOfClass("Terrain")
        if ter then pcall(function() sethiddenproperty(ter,"Decoration",false) end); ter.WaterReflectance=0; ter.WaterTransparency=0.7; ter.WaterWaveSize=0; ter.WaterWaveSpeed=0 end
    end)
    workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(pO,v) end end)
end


-- ============================================================
-- AUTO STEAL SYSTEM
-- ============================================================
local function isMyPlotByName(pn)
    local ct=tick()
    if Steal.plotCache[pn] and (ct-(Steal.plotCacheTime[pn] or 0))<PLOT_CACHE_DURATION then
        return Steal.plotCache[pn]
    end
    local plots=workspace:FindFirstChild("Plots")
    if not plots then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local plot=plots:FindFirstChild(pn)
    if not plot then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then
        local yb=sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            local r=yb.Enabled==true
            Steal.plotCache[pn]=r
            Steal.plotCacheTime[pn]=ct
            return r
        end
    end
    Steal.plotCache[pn]=false
    Steal.plotCacheTime[pn]=ct
    return false
end

local function findNearestPrompt()
    local c=LP.Character; if not c then return nil end
    local root=c:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local ct=tick()
    if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
        local np,nd=nil,math.huge
        for _,data in ipairs(Steal.cachedPrompts) do
            if data.spawn then
                local dist=(data.spawn.Position-root.Position).Magnitude
                if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist end
            end
        end
        if np then return np end
    end
    Steal.cachedPrompts={}
    Steal.promptCacheTime=ct
    local plots=workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np,nd=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods=plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base=pod:FindFirstChild("Base")
                local sp=base and base:FindFirstChild("Spawn")
                if sp then
                    local att=sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _,child in ipairs(att:GetChildren()) do
                            if child:IsA("ProximityPrompt") then
                                local dist=(sp.Position-root.Position).Magnitude
                                table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp})
                                if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    return np
end

local function executeSteal(prompt)
    local ct=tick()
    if ct-State.lastStealTick<STEAL_COOLDOWN then return end
    if State.isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt]={hold={},trigger={},ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end
                end
                for _,c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end
                end
            else
                Steal.Data[prompt].useFallback=true
            end
        end)
    end
    local data=Steal.Data[prompt]
    if not data.ready then return end
    data.ready=false
    State.isStealing=true
    State.stealStartTime=ct
    State.lastStealTick=ct
    task.spawn(function()
        local ok=false
        pcall(function()
            if not data.useFallback then
                for _,fn in ipairs(data.hold) do task.spawn(fn) end
                task.wait(Steal.StealDuration)
                for _,fn in ipairs(data.trigger) do task.spawn(fn) end
                ok=true
            end
        end)
        if not ok and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt); ok=true end)
        end
        if not ok then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(Steal.StealDuration)
                prompt:InputHoldEnd()
            end)
        end
        task.wait(Steal.StealDuration*0.3)
        task.wait(0.05)
        data.ready=true
        State.isStealing=false
    end)
end

local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or State.isStealing then return end
        local p=findNearestPrompt()
        if p then executeSteal(p) end
    end)
end

local function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
    State.isStealing=false
    State.lastStealTick=0
    Steal.plotCache={}
    Steal.plotCacheTime={}
    Steal.cachedPrompts={}
end

-- ============================================================
-- PRESET APPLY FUNCTION
-- ============================================================
local function applyPreset(data)
    if data.normalSpeed then State.normalSpeed=data.normalSpeed; if speedBoxRefs.normalSpeed then speedBoxRefs.normalSpeed.Text=tostring(data.normalSpeed) end end
    if data.carrySpeed  then State.carrySpeed=data.carrySpeed;   if speedBoxRefs.carrySpeed  then speedBoxRefs.carrySpeed.Text=tostring(data.carrySpeed)   end end
    if data.laggerSpeed then State.laggerSpeed=data.laggerSpeed; if speedBoxRefs.laggerSpeed then speedBoxRefs.laggerSpeed.Text=tostring(data.laggerSpeed)  end end
    if data.aimbotSpeed then State.aimbotSpeed=data.aimbotSpeed end
    if data.stealRadius then
        Steal.StealRadius=data.stealRadius; Steal.cachedPrompts={}; Steal.promptCacheTime=0
    end
    if data.stealDuration then Steal.StealDuration=data.stealDuration end
    if data.infJump~=nil       and toggleRefs.infJump       then State.infJumpEnabled=data.infJump; toggleRefs.infJump(data.infJump) end
    if data.antiRagdoll~=nil   and toggleRefs.antiRagdoll   then State.antiRagdollEnabled=data.antiRagdoll;   toggleRefs.antiRagdoll(data.antiRagdoll); if data.antiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end end
    if data.fpsBoost~=nil      and toggleRefs.fpsBoost      then State.fpsBoostEnabled=data.fpsBoost;         toggleRefs.fpsBoost(data.fpsBoost);         if data.fpsBoost then pcall(applyFPSBoost) end end
    if data.medusaCounter~=nil and toggleRefs.medusaCounter then State.medusaCounterEnabled=data.medusaCounter; toggleRefs.medusaCounter(data.medusaCounter); if data.medusaCounter then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end
    if data.batCounter~=nil    and toggleRefs.batCounter    then State.batCounterEnabled=data.batCounter;     toggleRefs.batCounter(data.batCounter);     if data.batCounter then startBatCounter() else stopBatCounter() end end
    if data.autoSteal~=nil     and toggleRefs.autoSteal     then Steal.AutoStealEnabled=data.autoSteal; toggleRefs.autoSteal(data.autoSteal); if data.autoSteal then pcall(startAutoSteal) else stopAutoSteal() end end
end


-- ============================================================
-- BUILD MENU SECTIONS
-- ============================================================

-- === AUTO SECTION ===
makeSectionHeader("AUTO")

toggleRefs.autoSteal = makeToggleRow("Auto Steal", false, function(on)
    Steal.AutoStealEnabled = on
    State.autoStealEnabled = on
    if on then
        if not pcall(startAutoSteal) then
            Steal.AutoStealEnabled=false
            if toggleRefs.autoSteal then toggleRefs.autoSteal(false) end
        end
    else
        stopAutoSteal()
    end
end)

toggleRefs.antiRagdoll = makeToggleRow("Anti Ragdoll", false, function(on)
    State.antiRagdollEnabled = on
    if on then startAntiRagdoll() else stopAntiRagdoll() end
end)

toggleRefs.infJump = makeToggleRow("Infinite Jump", false, function(on)
    State.infJumpEnabled = on
end)

toggleRefs.medusaCounter = makeToggleRow("Medusa Counter", false, function(on)
    State.medusaCounterEnabled = on
    if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
end)

makeInputRow("Steal Radius", Steal.StealRadius, function(n)
    if n >= 5 and n <= 300 then
        Steal.StealRadius = math.floor(n)
        Steal.cachedPrompts={}
        Steal.promptCacheTime=0
        task.spawn(saveConfig)
    end
end)

makeInputRow("Steal Duration", Steal.StealDuration, function(n)
    if n >= 0.05 and n <= 2 then 
        Steal.StealDuration = n
        task.spawn(saveConfig)
    end
end)

makeDivider()

-- === COMBAT SECTION ===
makeSectionHeader("COMBAT")

-- FIXED: Auto left/right now auto-disable aimbot when turned on
toggleRefs.autoLeft = makeToggleRow("Auto Left", false, function(on)
    State.autoLeftEnabled = on
    if on and State.batAimbotToggled then
        State.batAimbotToggled = false
        stopBatAimbot()
        if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        if setAB then setAB(false) end
    end
    if on then startAutoLeft() else stopAutoLeft() end
end, "autoLeft")

toggleRefs.autoRight = makeToggleRow("Auto Right", false, function(on)
    State.autoRightEnabled = on
    if on and State.batAimbotToggled then
        State.batAimbotToggled = false
        stopBatAimbot()
        if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        if setAB then setAB(false) end
    end
    if on then startAutoRight() else stopAutoRight() end
end, "autoRight")

-- FIXED: Aimbot now auto-disables auto left/right when turned on
toggleRefs.aimbot = makeToggleRow("Bat Aimbot", false, function(on)
    State.batAimbotToggled = on
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            stopAutoLeft()
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            if setAL then setAL(false) end
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            stopAutoRight()
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            if setAR then setAR(false) end
        end
        pcall(startBatAimbot)
    else
        stopBatAimbot()
    end
end, "aimbot")

makeInputRow("Aimbot Speed", State.aimbotSpeed, function(n)
    if n >= 1 and n <= 500 then 
        State.aimbotSpeed = n
        task.spawn(saveConfig)
    end
end)

toggleRefs.batCounter = makeToggleRow("Bat Counter", false, function(on)
    State.batCounterEnabled = on
    if on then startBatCounter() else stopBatCounter() end
end)

toggleRefs.autoSwing = makeToggleRow("Auto Swing", false, function(on)
    State.autoSwingEnabled = on
end)

-- ADDED: Drop Brainrot with keybind
makeToggleRow("Drop Brainrot", false, function(on)
    if on and not State.dropEnabled then runDropBrainrot() end
end, "drop")

-- ADDED: TP Down with keybind
makeToggleRow("TP Down", false, function(on)
    if on then doTpDown() end
end, "tpDown")

makeDivider()

-- === SPEED SECTION ===
makeSectionHeader("SPEED")

toggleRefs.carryMode = makeToggleRow("Carry Mode", false, function(on)
    State.speedToggled = on
end, "speed")

toggleRefs.laggerMode = makeToggleRow("Lagger Mode", false, function(on)
    State.laggerEnabled = on
    if on then
        State._laggerOriginalCarry = State.carrySpeed
        State._prevSpeed = State.speedToggled
        State.speedToggled = false
    else
        State.carrySpeed = State._laggerOriginalCarry or 30
        State.speedToggled = State._prevSpeed or false
        if speedBoxRefs.carrySpeed then
            speedBoxRefs.carrySpeed.Text = tostring(State.carrySpeed)
        end
    end
end, "lagger")

makeDivider()


-- === VISUALS SECTION ===
makeSectionHeader("VISUALS")

toggleRefs.unwalk = makeToggleRow("Unwalk", false, function(on)
    State.unwalkEnabled = on
    if on then startUnwalk() else stopUnwalk() end
end, "unwalk")

makeToggleRow("Remove Accessories", false, function(on)
    if on then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                for _, obj in ipairs(p.Character:GetDescendants()) do
                    if obj:IsA("Accessory") or obj:IsA("Hat") then pcall(function() obj:Destroy() end) end
                end
            end
        end
    end
end)

local nightModeEnabled = false
local defBrightness = Lighting.Brightness
local defClockTime = Lighting.ClockTime
local defOutdoorAmbient = Lighting.OutdoorAmbient
local defExposureComp = Lighting.ExposureCompensation

makeToggleRow("Dark Mode", false, function(on)
    nightModeEnabled = on
    if on then
        local sky = Lighting:FindFirstChild("d4vidDarkSky") or Instance.new("Sky")
        sky.Name = "d4vidDarkSky"
        sky.SkyboxBk = "rbxassetid://159454299"; sky.SkyboxDn = "rbxassetid://159454296"
        sky.SkyboxFt = "rbxassetid://159454293"; sky.SkyboxLf = "rbxassetid://159454286"
        sky.SkyboxRt = "rbxassetid://159454289"; sky.SkyboxUp = "rbxassetid://159454291"
        sky.Parent = Lighting
        Lighting.Brightness = 0; Lighting.ClockTime = 0
        Lighting.ExposureCompensation = -2
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    else
        local s = Lighting:FindFirstChild("d4vidDarkSky"); if s then s:Destroy() end
        Lighting.Brightness = defBrightness; Lighting.ClockTime = defClockTime
        Lighting.ExposureCompensation = defExposureComp; Lighting.OutdoorAmbient = defOutdoorAmbient
    end
end)

-- FOV Changer
do
    local cam = workspace.CurrentCamera
    local defaultFOV = cam.FieldOfView
    local currentFOV = defaultFOV

    local fovRow = Instance.new("Frame", scrollFrame)
    fovRow.Size = UDim2.new(1, 0, 0, 54)
    fovRow.BackgroundColor3 = C.bg
    fovRow.BorderSizePixel = 0
    fovRow.LayoutOrder = LO()
    fovRow.ZIndex = 3

    local fovDiv = Instance.new("Frame", fovRow)
    fovDiv.Size = UDim2.new(1, -28, 0, 1)
    fovDiv.Position = UDim2.new(0, 14, 1, -1)
    fovDiv.BackgroundColor3 = C.borderDim
    fovDiv.BorderSizePixel = 0
    fovDiv.ZIndex = 4

    local fovLbl = Instance.new("TextLabel", fovRow)
    fovLbl.Size = UDim2.new(0.5, 0, 0, 22)
    fovLbl.Position = UDim2.new(0, 14, 0, 6)
    fovLbl.BackgroundTransparency = 1
    fovLbl.Text = "FOV Changer"
    fovLbl.TextColor3 = C.text
    fovLbl.Font = Enum.Font.GothamBold
    fovLbl.TextSize = 11
    fovLbl.TextXAlignment = Enum.TextXAlignment.Left
    fovLbl.ZIndex = 4

    local fovValLbl = Instance.new("TextLabel", fovRow)
    fovValLbl.Size = UDim2.new(0, 40, 0, 22)
    fovValLbl.Position = UDim2.new(1, -46, 0, 6)
    fovValLbl.BackgroundTransparency = 1
    fovValLbl.Text = tostring(math.floor(currentFOV))
    fovValLbl.TextColor3 = C.textSub
    fovValLbl.Font = Enum.Font.GothamBold
    fovValLbl.TextSize = 10
    fovValLbl.TextXAlignment = Enum.TextXAlignment.Right
    fovValLbl.ZIndex = 4

    local slTrack = Instance.new("Frame", fovRow)
    slTrack.Size = UDim2.new(1, -28, 0, 6)
    slTrack.Position = UDim2.new(0, 14, 0, 30)
    slTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    slTrack.BorderSizePixel = 0
    mkCorner(slTrack, 3)
    slTrack.ZIndex = 4

    local slFill = Instance.new("Frame", slTrack)
    slFill.Size = UDim2.new((currentFOV - 60) / 140, 0, 1, 0)
    slFill.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    slFill.BorderSizePixel = 0
    mkCorner(slFill, 3)
    slFill.ZIndex = 5

    local slHandle = Instance.new("Frame", slTrack)
    slHandle.Size = UDim2.new(0, 14, 0, 14)
    slHandle.Position = UDim2.new((currentFOV - 60) / 140, -7, 0.5, -7)
    slHandle.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    slHandle.BorderSizePixel = 0
    mkCorner(slHandle, 7)
    slHandle.ZIndex = 6

    local slBtn = Instance.new("TextButton", slTrack)
    slBtn.Size = UDim2.new(1, 0, 0, 30)
    slBtn.Position = UDim2.new(0, 0, 0.5, -15)
    slBtn.BackgroundTransparency = 1
    slBtn.Text = ""
    slBtn.ZIndex = 7
    slBtn.BorderSizePixel = 0

    local function setFOV(fov)
        fov = math.clamp(math.floor(fov), 60, 200)
        currentFOV = fov
        local t = (fov - 60) / 140
        slFill.Size = UDim2.new(t, 0, 1, 0)
        slHandle.Position = UDim2.new(t, -7, 0.5, -7)
        fovValLbl.Text = fov
        pcall(function() workspace.CurrentCamera.FieldOfView = fov end)
    end

    local fovDragging = false
    local function updateFromInput(inp)
        local trackAbs = slTrack.AbsolutePosition
        local trackW = slTrack.AbsoluteSize.X
        local rx = math.clamp(inp.Position.X - trackAbs.X, 0, trackW)
        setFOV(60 + (rx / trackW) * 140)
    end

    slBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fovDragging = true
            updateFromInput(inp)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if not fovDragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(inp)
        end
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fovDragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if workspace.CurrentCamera.FieldOfView ~= currentFOV then
            pcall(function() workspace.CurrentCamera.FieldOfView = currentFOV end)
        end
    end)
end

makeDivider()

-- === SETTINGS SECTION ===
makeSectionHeader("SETTINGS")

makeInputRow("UI Scale", 1.0, function(n)
    if n >= 0.5 and n <= 2.0 then
        if uiScaleObj then uiScaleObj.Scale = n end
    end
end)

toggleRefs.fpsBoost = makeToggleRow("FPS Boost", false, function(on)
    State.fpsBoostEnabled = on
    if on then pcall(applyFPSBoost) end
end)

makeToggleRow("Lock UI", false, function(on)
    State.uiLocked = on
end)

toggleRefs.hideButtons = makeToggleRow("Hide Buttons", false, function(on)
    if mbGroup then mbGroup.Visible = not on end
end)

makeDivider()


-- === PANELS SECTION ===
makeSectionHeader("PANELS")

-- Insta Reset Panel
local instaResetTpPos = CFrame.new(1000003.56, 999999.69, 8.17)
local function doInstaReset()
    local c = LP.Character
    if not c then return end
    local hrp2 = c:FindFirstChild("HumanoidRootPart")
    local hum2 = c:FindFirstChildOfClass("Humanoid")
    if not hrp2 or not hum2 then return end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    task.delay(0.6, function()
        local ch = LP.Character
        local hm = ch and ch:FindFirstChildOfClass("Humanoid")
        if hm then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            workspace.CurrentCamera.CameraSubject = hm
        end
    end)
    hrp2.CFrame = instaResetTpPos
    local con
    con = RunService.Heartbeat:Connect(function()
        if not c or not c.Parent then con:Disconnect(); return end
        if hum2.Health <= 0 then con:Disconnect(); return end
        hrp2.CFrame = instaResetTpPos
    end)
end

makeButtonRow("Insta Reset Panel", "OPEN", function()
    local panelName = "d4vidhubInstaResetPanel"
    local existing = gui:FindFirstChild(panelName)
    if existing then existing.Visible = not existing.Visible; return end

    local panel = Instance.new("Frame", gui)
    panel.Name = panelName
    panel.Size = UDim2.new(0, 240, 0, 84)
    panel.Position = UDim2.new(0.5, -120, 0.5, -42)
    panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.ZIndex = 100
    mkCorner(panel, 12)
    mkStroke(panel, Color3.fromRGB(40,40,40), 1)
    makeDraggable(panel, nil, true)

    local ptitle = Instance.new("TextLabel", panel)
    ptitle.Size = UDim2.new(1, -50, 0, 36)
    ptitle.Position = UDim2.new(0, 14, 0, 0)
    ptitle.BackgroundTransparency = 1
    ptitle.Text = "D4VID insta reset"
    ptitle.TextColor3 = Color3.fromRGB(230,230,230)
    ptitle.Font = Enum.Font.GothamBlack
    ptitle.TextSize = 14
    ptitle.TextXAlignment = Enum.TextXAlignment.Left
    ptitle.ZIndex = 101

    local pclose = Instance.new("TextButton", panel)
    pclose.Size = UDim2.new(0, 24, 0, 24)
    pclose.Position = UDim2.new(1, -34, 0, 6)
    pclose.BackgroundColor3 = Color3.fromRGB(20,20,20)
    pclose.BorderSizePixel = 0
    pclose.Text = "-"
    pclose.TextColor3 = Color3.fromRGB(200,200,200)
    pclose.Font = Enum.Font.GothamBold
    pclose.TextSize = 14
    pclose.ZIndex = 102
    mkCorner(pclose, 5)
    mkStroke(pclose, Color3.fromRGB(50,50,50), 1)
    pclose.MouseButton1Click:Connect(function() panel.Visible = false end)

    local pdiv = Instance.new("Frame", panel)
    pdiv.Size = UDim2.new(1, 0, 0, 1)
    pdiv.Position = UDim2.new(0, 0, 0, 36)
    pdiv.BackgroundColor3 = Color3.fromRGB(25,25,25)
    pdiv.BorderSizePixel = 0
    pdiv.ZIndex = 101

    local irChip = Instance.new("TextButton", panel)
    irChip.Size = UDim2.new(0, 42, 0, 34)
    irChip.Position = UDim2.new(0, 8, 0, 43)
    irChip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    irChip.BorderSizePixel = 0
    irChip.Text = getKeyName(Keys.instaReset)
    irChip.TextColor3 = Color3.fromRGB(160, 160, 160)
    irChip.Font = Enum.Font.GothamBold
    irChip.TextSize = 10
    irChip.AutoButtonColor = false
    irChip.ZIndex = 103
    mkCorner(irChip, 5)
    mkStroke(irChip, Color3.fromRGB(55, 55, 55), 1)
    keybindBtnRefs["instaReset"] = irChip

    local irListening = false
    local irConn = nil
    local function irStopListening(key)
        irListening = false
        if irConn then irConn:Disconnect(); irConn = nil end
        irChip.TextColor3 = Color3.fromRGB(160, 160, 160)
        if key then
            Keys.instaReset = key
            irChip.Text = getKeyName(key)
            task.spawn(saveConfig)
        else
            irChip.Text = getKeyName(Keys.instaReset)
        end
    end
    irChip.MouseButton1Click:Connect(function()
        if irListening then irStopListening(nil); return end
        irListening = true
        irChip.Text = "···"
        irChip.TextColor3 = C.text
        irConn = UIS.InputBegan:Connect(function(inp)
            if not irListening then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then irStopListening(nil); return end
            irStopListening(inp.KeyCode)
        end)
    end)

    local pResetBtn = Instance.new("TextButton", panel)
    pResetBtn.Size = UDim2.new(1, -66, 0, 34)
    pResetBtn.Position = UDim2.new(0, 58, 0, 43)
    pResetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    pResetBtn.BorderSizePixel = 0
    pResetBtn.Text = "INSTA RESET"
    pResetBtn.TextColor3 = Color3.fromRGB(255,255,255)
    pResetBtn.Font = Enum.Font.GothamBlack
    pResetBtn.TextSize = 14
    pResetBtn.ZIndex = 102
    mkCorner(pResetBtn, 8)
    mkStroke(pResetBtn, Color3.fromRGB(80,80,80), 1)
    pResetBtn.Activated:Connect(function()
        pResetBtn.Text = "RESETTING..."
        doInstaReset()
        task.delay(1.2, function()
            if pResetBtn and pResetBtn.Parent then
                pResetBtn.Text = "INSTA RESET"
            end
        end)
    end)
end)

-- Lagger Panel
makeButtonRow("Lagger Panel", "OPEN", function()
    local panelName = "d4vidhubLaggerPanel"
    local existing = gui:FindFirstChild(panelName)
    if existing then existing.Visible = not existing.Visible; return end

    local laggerPanel = Instance.new("Frame", gui)
    laggerPanel.Name = panelName
    laggerPanel.Size = UDim2.new(0, 260, 0, 130)
    laggerPanel.Position = UDim2.new(0.5, -130, 0.5, -65)
    laggerPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    laggerPanel.BorderSizePixel = 0
    laggerPanel.Active = true
    laggerPanel.ZIndex = 150
    mkCorner(laggerPanel, 10)
    mkStroke(laggerPanel, Color3.fromRGB(50, 50, 50), 1.5)
    makeDraggable(laggerPanel, nil, true)

    local lpTitle = Instance.new("TextLabel", laggerPanel)
    lpTitle.Size = UDim2.new(1, -70, 0, 28)
    lpTitle.Position = UDim2.new(0, 12, 0, 6)
    lpTitle.BackgroundTransparency = 1
    lpTitle.Text = "Duel Lagger"
    lpTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    lpTitle.Font = Enum.Font.GothamBlack
    lpTitle.TextSize = 15
    lpTitle.TextXAlignment = Enum.TextXAlignment.Left
    lpTitle.ZIndex = 152

    local lpClose = Instance.new("TextButton", laggerPanel)
    lpClose.Size = UDim2.new(0, 22, 0, 22)
    lpClose.Position = UDim2.new(1, -30, 0, 6)
    lpClose.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
    lpClose.BorderSizePixel = 0
    lpClose.Text = "×"
    lpClose.TextColor3 = Color3.new(1, 1, 1)
    lpClose.Font = Enum.Font.GothamBold
    lpClose.TextSize = 16
    lpClose.AutoButtonColor = false
    lpClose.ZIndex = 153
    mkCorner(lpClose, 11)
    lpClose.MouseButton1Click:Connect(function()
        laggerPanel.Visible = false
    end)

    local lpCard = Instance.new("Frame", laggerPanel)
    lpCard.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    lpCard.Size = UDim2.new(1, -20, 0, 70)
    lpCard.Position = UDim2.new(0, 10, 0, 40)
    lpCard.BorderSizePixel = 0
    lpCard.ZIndex = 152
    mkCorner(lpCard, 8)
    mkStroke(lpCard, Color3.fromRGB(45, 45, 45), 1)

    local lpKeybindBtn = Instance.new("TextButton", lpCard)
    lpKeybindBtn.Size = UDim2.new(0, 52, 0, 26)
    lpKeybindBtn.Position = UDim2.new(0, 8, 0, 8)
    lpKeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    lpKeybindBtn.Text = getKeyName(Keys.duelLagger)
    lpKeybindBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    lpKeybindBtn.Font = Enum.Font.GothamBold
    lpKeybindBtn.TextSize = 11
    lpKeybindBtn.BorderSizePixel = 0
    lpKeybindBtn.AutoButtonColor = false
    lpKeybindBtn.ZIndex = 154
    mkCorner(lpKeybindBtn, 4)
    keybindBtnRefs["duelLagger"] = lpKeybindBtn

    local lpListening = false
    local lpLkb = nil
    local function lpStopListening(key)
        lpListening = false
        if lpLkb then lpLkb:Disconnect(); lpLkb = nil end
        lpKeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if key then
            Keys.duelLagger = key
            lpKeybindBtn.Text = getKeyName(key)
            task.spawn(saveConfig)
        else
            lpKeybindBtn.Text = getKeyName(Keys.duelLagger)
        end
    end
    lpKeybindBtn.MouseButton1Click:Connect(function()
        if lpListening then lpStopListening(nil); return end
        lpListening = true
        lpKeybindBtn.Text = "···"
        lpKeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
        lpLkb = UIS.InputBegan:Connect(function(inp)
            if not lpListening then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then lpStopListening(nil); return end
            lpStopListening(inp.KeyCode)
        end)
    end)

    duelLaggerStatusLabel = Instance.new("TextLabel", lpCard)
    duelLaggerStatusLabel.Size = UDim2.new(0, 130, 0, 26)
    duelLaggerStatusLabel.Position = UDim2.new(0, 68, 0, 8)
    duelLaggerStatusLabel.BackgroundTransparency = 1
    duelLaggerStatusLabel.Text = State.duelLaggerActive and "STATUS: ACTIVE" or "STATUS: INACTIVE"
    duelLaggerStatusLabel.TextColor3 = State.duelLaggerActive
        and Color3.fromRGB(220, 220, 220)
        or Color3.fromRGB(90, 90, 90)
    duelLaggerStatusLabel.Font = Enum.Font.GothamBold
    duelLaggerStatusLabel.TextSize = 11
    duelLaggerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    duelLaggerStatusLabel.ZIndex = 153

    local lpSwitch = Instance.new("TextButton", lpCard)
    lpSwitch.Size = UDim2.new(0, 40, 0, 22)
    lpSwitch.Position = UDim2.new(1, -48, 0, 10)
    lpSwitch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    lpSwitch.Text = ""
    lpSwitch.BorderSizePixel = 0
    lpSwitch.AutoButtonColor = false
    lpSwitch.ZIndex = 154
    mkCorner(lpSwitch, 11)
    mkStroke(lpSwitch, Color3.fromRGB(55, 55, 55), 1)

    duelLaggerSwitchBall = Instance.new("Frame", lpSwitch)
    duelLaggerSwitchBall.Size = UDim2.new(0, 16, 0, 16)
    duelLaggerSwitchBall.Position = State.duelLaggerActive
        and UDim2.new(1, -18, 0.5, -8)
        or UDim2.new(0, 2, 0.5, -8)
    duelLaggerSwitchBall.BackgroundColor3 = State.duelLaggerActive
        and Color3.fromRGB(220, 220, 220)
        or Color3.fromRGB(60, 60, 60)
    duelLaggerSwitchBall.BorderSizePixel = 0
    duelLaggerSwitchBall.ZIndex = 155
    mkCorner(duelLaggerSwitchBall, 8)

    lpSwitch.MouseButton1Click:Connect(toggleDuelLagger)

    local lpInfo = Instance.new("TextLabel", lpCard)
    lpInfo.Size = UDim2.new(1, -16, 0, 16)
    lpInfo.Position = UDim2.new(0, 8, 0, 46)
    lpInfo.BackgroundTransparency = 1
    lpInfo.Text = getKeyName(Keys.duelLagger) .. " = Toggle  |  Click key chip to rebind"
    lpInfo.TextColor3 = Color3.fromRGB(120, 80, 200)
    lpInfo.Font = Enum.Font.Gotham
    lpInfo.TextSize = 9
    lpInfo.TextXAlignment = Enum.TextXAlignment.Left
    lpInfo.ZIndex = 153
end)

-- Speed Bypass Panel
makeButtonRow("D4vid Speed Bypass", "OPEN", function()
    local panelName = "d4vidhubSpeedBypassPanel"
    local existing = gui:FindFirstChild(panelName)
    if existing then existing.Visible = not existing.Visible; return end

    local sbPanel = Instance.new("Frame", gui)
    sbPanel.Name = panelName
    sbPanel.Size = UDim2.new(0, 240, 0, 300)
    sbPanel.Position = UDim2.new(0.5, -120, 0.5, -150)
    sbPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    sbPanel.BorderSizePixel = 0
    sbPanel.Active = true
    sbPanel.ZIndex = 100
    mkCorner(sbPanel, 10)
    mkStroke(sbPanel, Color3.fromRGB(80, 40, 150), 1.8)
    makeDraggable(sbPanel, nil, true)

    -- Title
    local sbTitle = Instance.new("TextLabel", sbPanel)
    sbTitle.Size = UDim2.new(1, -50, 0, 36)
    sbTitle.Position = UDim2.new(0, 14, 0, 0)
    sbTitle.BackgroundTransparency = 1
    sbTitle.Text = "D4vid Speed Bypass"
    sbTitle.TextColor3 = Color3.fromRGB(168, 85, 247)
    sbTitle.Font = Enum.Font.GothamBlack
    sbTitle.TextSize = 13
    sbTitle.TextXAlignment = Enum.TextXAlignment.Left
    sbTitle.ZIndex = 101

    -- Close button
    local sbClose = Instance.new("TextButton", sbPanel)
    sbClose.Size = UDim2.new(0, 24, 0, 24)
    sbClose.Position = UDim2.new(1, -32, 0, 6)
    sbClose.BackgroundColor3 = Color3.fromRGB(40, 20, 70)
    sbClose.BorderSizePixel = 0
    sbClose.Text = "×"
    sbClose.TextColor3 = Color3.fromRGB(200, 160, 255)
    sbClose.Font = Enum.Font.GothamBold
    sbClose.TextSize = 14
    sbClose.ZIndex = 102
    mkCorner(sbClose, 6)
    mkStroke(sbClose, Color3.fromRGB(80, 40, 150), 1)
    sbClose.MouseButton1Click:Connect(function() sbPanel.Visible = false end)

    -- Divider
    local sbDiv = Instance.new("Frame", sbPanel)
    sbDiv.Size = UDim2.new(1, 0, 0, 1)
    sbDiv.Position = UDim2.new(0, 0, 0, 36)
    sbDiv.BackgroundColor3 = Color3.fromRGB(50, 28, 80)
    sbDiv.BorderSizePixel = 0
    sbDiv.ZIndex = 101

    -- Scrolling content
    local sbScroll = Instance.new("ScrollingFrame", sbPanel)
    sbScroll.Size = UDim2.new(1, -16, 1, -46)
    sbScroll.Position = UDim2.new(0, 8, 0, 42)
    sbScroll.BackgroundTransparency = 1
    sbScroll.BorderSizePixel = 0
    sbScroll.ScrollBarThickness = 0
    sbScroll.CanvasSize = UDim2.new(0, 0, 0, 210)
    sbScroll.ZIndex = 101

    local sbList = Instance.new("UIListLayout", sbScroll)
    sbList.SortOrder = Enum.SortOrder.LayoutOrder
    sbList.Padding = UDim.new(0, 8)

    -- Helper: make a small card
    local function sbCard(parent, h)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, h)
        f.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
        f.BorderSizePixel = 0
        f.ZIndex = 102
        mkCorner(f, 7)
        mkStroke(f, Color3.fromRGB(60, 30, 100), 1)
        return f
    end

    -- Status toggle button
    local sbToggleCard = sbCard(sbScroll, 40)
    sbToggleCard.LayoutOrder = 1
    local sbToggleBtn = Instance.new("TextButton", sbToggleCard)
    sbToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    sbToggleBtn.BackgroundTransparency = 1
    sbToggleBtn.Text = "STATUS: DISABLED"
    sbToggleBtn.TextColor3 = Color3.fromRGB(168, 85, 247)
    sbToggleBtn.Font = Enum.Font.GothamBold
    sbToggleBtn.TextSize = 12
    sbToggleBtn.ZIndex = 103
    mkCorner(sbToggleBtn, 7)

    -- Power display label
    local sbPowerCard = sbCard(sbScroll, 30)
    sbPowerCard.LayoutOrder = 2
    local sbPowerLbl = Instance.new("TextLabel", sbPowerCard)
    sbPowerLbl.Size = UDim2.new(1, -16, 1, 0)
    sbPowerLbl.Position = UDim2.new(0, 8, 0, 0)
    sbPowerLbl.BackgroundTransparency = 1
    sbPowerLbl.Text = "Bypass Power: 97000"
    sbPowerLbl.TextColor3 = Color3.fromRGB(200, 160, 255)
    sbPowerLbl.Font = Enum.Font.Gotham
    sbPowerLbl.TextSize = 11
    sbPowerLbl.TextXAlignment = Enum.TextXAlignment.Left
    sbPowerLbl.ZIndex = 103

    -- Power input box
    local sbInputCard = sbCard(sbScroll, 34)
    sbInputCard.LayoutOrder = 3
    local sbInput = Instance.new("TextBox", sbInputCard)
    sbInput.Size = UDim2.new(1, -16, 1, -8)
    sbInput.Position = UDim2.new(0, 8, 0, 4)
    sbInput.BackgroundColor3 = Color3.fromRGB(14, 10, 22)
    sbInput.BorderSizePixel = 0
    sbInput.PlaceholderText = "Enter custom power..."
    sbInput.Text = "97000"
    sbInput.TextColor3 = Color3.fromRGB(220, 180, 255)
    sbInput.Font = Enum.Font.Gotham
    sbInput.TextSize = 12
    sbInput.ZIndex = 103
    mkCorner(sbInput, 5)
    mkStroke(sbInput, Color3.fromRGB(60, 30, 100), 1)

    -- Keybind row
    local sbKeyCard = sbCard(sbScroll, 34)
    sbKeyCard.LayoutOrder = 4
    local sbKeyLbl = Instance.new("TextLabel", sbKeyCard)
    sbKeyLbl.Size = UDim2.new(0.55, 0, 1, 0)
    sbKeyLbl.Position = UDim2.new(0, 8, 0, 0)
    sbKeyLbl.BackgroundTransparency = 1
    sbKeyLbl.Text = "Toggle Keybind:"
    sbKeyLbl.TextColor3 = Color3.fromRGB(160, 120, 220)
    sbKeyLbl.Font = Enum.Font.Gotham
    sbKeyLbl.TextSize = 11
    sbKeyLbl.TextXAlignment = Enum.TextXAlignment.Left
    sbKeyLbl.ZIndex = 103
    local sbKeyBtn = Instance.new("TextButton", sbKeyCard)
    sbKeyBtn.Size = UDim2.new(0, 52, 0, 24)
    sbKeyBtn.Position = UDim2.new(1, -60, 0.5, -12)
    sbKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 24, 70)
    sbKeyBtn.BorderSizePixel = 0
    sbKeyBtn.Text = "V"
    sbKeyBtn.TextColor3 = Color3.fromRGB(200, 160, 255)
    sbKeyBtn.Font = Enum.Font.GothamBold
    sbKeyBtn.TextSize = 11
    sbKeyBtn.ZIndex = 103
    mkCorner(sbKeyBtn, 6)
    mkStroke(sbKeyBtn, Color3.fromRGB(80, 40, 150), 1)

    -- Discord label
    local sbDiscCard = sbCard(sbScroll, 24)
    sbDiscCard.LayoutOrder = 5
    local sbDiscLbl = Instance.new("TextLabel", sbDiscCard)
    sbDiscLbl.Size = UDim2.new(1, 0, 1, 0)
    sbDiscLbl.BackgroundTransparency = 1
    sbDiscLbl.Text = "discord.gg/5D3DxmcBb"
    sbDiscLbl.TextColor3 = Color3.fromRGB(100, 60, 160)
    sbDiscLbl.Font = Enum.Font.Gotham
    sbDiscLbl.TextSize = 10
    sbDiscLbl.ZIndex = 103

    -- === LOGIC ===
    local sbConfig = {
        Activated = false,
        Power = 97000,
        LagAmount = 0.12,
        Keybind = Enum.KeyCode.V,
        WaitingForKey = false,
    }
    local sbLagConn = nil

    local function sbApplyPower(v)
        sbConfig.Power = math.clamp(v, 10000, 500000)
        local pct = (sbConfig.Power - 10000) / 490000
        sbConfig.LagAmount = pct * 0.22
        sbPowerLbl.Text = "Bypass Power: " .. sbConfig.Power
        sbInput.Text = tostring(sbConfig.Power)
    end

    local function sbStartLag()
        if sbLagConn then sbLagConn:Disconnect() end
        sbLagConn = game:GetService("RunService").RenderStepped:Connect(function()
            if not sbConfig.Activated then return end
            if sbConfig.LagAmount > 0 then
                local s = tick()
                while tick() - s < sbConfig.LagAmount do end
            end
        end)
    end

    local function sbStopLag()
        sbConfig.Activated = false
        if sbLagConn then sbLagConn:Disconnect(); sbLagConn = nil end
    end

    local function sbToggle()
        sbConfig.Activated = not sbConfig.Activated
        if sbConfig.Activated then
            sbToggleBtn.Text = "STATUS: ENABLED"
            sbToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 160)
            sbStartLag()
        else
            sbToggleBtn.Text = "STATUS: DISABLED"
            sbToggleBtn.TextColor3 = Color3.fromRGB(168, 85, 247)
            sbStopLag()
        end
    end

    sbToggleBtn.MouseButton1Click:Connect(sbToggle)

    sbInput.FocusLost:Connect(function()
        local n = tonumber(sbInput.Text)
        if n then sbApplyPower(n) end
    end)

    -- Keybind rebind
    local sbWaiting = false
    local sbKeyConn = nil
    sbKeyBtn.MouseButton1Click:Connect(function()
        if sbWaiting then
            sbWaiting = false
            if sbKeyConn then sbKeyConn:Disconnect(); sbKeyConn = nil end
            sbKeyBtn.Text = sbConfig.Keybind.Name
            return
        end
        sbWaiting = true
        sbKeyBtn.Text = "···"
        sbKeyConn = game:GetService("UserInputService").InputBegan:Connect(function(inp)
            if not sbWaiting then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then
                sbWaiting = false
                sbKeyBtn.Text = sbConfig.Keybind.Name
                if sbKeyConn then sbKeyConn:Disconnect(); sbKeyConn = nil end
                return
            end
            sbConfig.Keybind = inp.KeyCode
            sbKeyBtn.Text = inp.KeyCode.Name
            sbWaiting = false
            if sbKeyConn then sbKeyConn:Disconnect(); sbKeyConn = nil end
        end)
    end)

    -- Global keybind listen
    game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
        if gp then return end
        if not sbConfig.WaitingForKey and inp.KeyCode == sbConfig.Keybind then
            if sbPanel.Visible then sbToggle() end
        end
    end)

    -- Cleanup on panel destroy
    sbPanel.AncestryChanged:Connect(function()
        if not sbPanel.Parent then sbStopLag() end
    end)

    sbApplyPower(97000)
end)

makeDivider()


-- === PRESETS ===
makeSectionHeader("PRESETS")

local pNameWrap = Instance.new("Frame", scrollFrame)
pNameWrap.Size = UDim2.new(1, 0, 0, 40)
pNameWrap.BackgroundColor3 = C.bg
pNameWrap.BorderSizePixel = 0
pNameWrap.LayoutOrder = LO()
pNameWrap.ZIndex = 3

local pDiv = Instance.new("Frame", pNameWrap)
pDiv.Size = UDim2.new(1, -28, 0, 1)
pDiv.Position = UDim2.new(0, 14, 1, -1)
pDiv.BackgroundColor3 = C.borderDim
pDiv.BorderSizePixel = 0
pDiv.ZIndex = 4

local pBoxWrap = Instance.new("Frame", pNameWrap)
pBoxWrap.Size = UDim2.new(1, -28, 0, 26)
pBoxWrap.Position = UDim2.new(0, 14, 0.5, -16)
pBoxWrap.BackgroundColor3 = C.card
pBoxWrap.BorderSizePixel = 0
mkCorner(pBoxWrap, 8)
local pbs = mkStroke(pBoxWrap, C.border, 1)

local presetNameBox = Instance.new("TextBox", pBoxWrap)
presetNameBox.Size = UDim2.new(1, -16, 1, 0)
presetNameBox.Position = UDim2.new(0, 8, 0, 0)
presetNameBox.BackgroundTransparency = 1
presetNameBox.PlaceholderText = "Preset name..."
presetNameBox.PlaceholderColor3 = C.textSub
presetNameBox.Text = ""
presetNameBox.TextColor3 = C.text
presetNameBox.Font = Enum.Font.GothamBold
presetNameBox.TextSize = 12
presetNameBox.ClearTextOnFocus = false
presetNameBox.ZIndex = 5
presetNameBox.TextXAlignment = Enum.TextXAlignment.Left
presetNameBox.Focused:Connect(function()
    TweenService:Create(pbs,TweenInfo.new(0.15),{Color=Color3.fromRGB(120,120,120)}):Play()
end)
presetNameBox.FocusLost:Connect(function()
    TweenService:Create(pbs,TweenInfo.new(0.15),{Color=C.border}):Play()
end)

local savePRow = Instance.new("Frame", scrollFrame)
savePRow.Size = UDim2.new(1, 0, 0, 36)
savePRow.BackgroundColor3 = C.bg
savePRow.BorderSizePixel = 0
savePRow.LayoutOrder = LO()

local savePDiv = Instance.new("Frame", savePRow)
savePDiv.Size = UDim2.new(1, -28, 0, 1)
savePDiv.Position = UDim2.new(0, 14, 1, -1)
savePDiv.BackgroundColor3 = C.borderDim
savePDiv.BorderSizePixel = 0

local savePBtn = Instance.new("TextButton", savePRow)
savePBtn.Size = UDim2.new(1, -28, 0, 26)
savePBtn.Position = UDim2.new(0, 14, 0.5, -16)
savePBtn.BackgroundColor3 = C.card
savePBtn.BorderSizePixel = 0
savePBtn.Text = "+ Save Preset"
savePBtn.TextColor3 = C.text
savePBtn.Font = Enum.Font.GothamBold
savePBtn.TextSize = 10
savePBtn.ZIndex = 4
mkCorner(savePBtn, 8)
mkStroke(savePBtn, C.border, 1)
savePBtn.MouseEnter:Connect(function()
    TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.cardHov}):Play()
end)
savePBtn.MouseLeave:Connect(function()
    TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.card}):Play()
end)

local presetListFrame = Instance.new("Frame", scrollFrame)
presetListFrame.Size = UDim2.new(1, 0, 0, 0)
presetListFrame.AutomaticSize = Enum.AutomaticSize.Y
presetListFrame.BackgroundTransparency = 1
presetListFrame.BorderSizePixel = 0
presetListFrame.LayoutOrder = LO()
presetListFrame.ZIndex = 3

local pListLL = Instance.new("UIListLayout", presetListFrame)
pListLL.SortOrder = Enum.SortOrder.LayoutOrder
pListLL.Padding = UDim.new(0, 0)

local pListPad = Instance.new("UIPadding", presetListFrame)
pListPad.PaddingLeft = UDim.new(0, 14)
pListPad.PaddingRight = UDim.new(0, 14)
pListPad.PaddingTop = UDim.new(0, 4)
pListPad.PaddingBottom = UDim.new(0, 8)

local emptyLbl = Instance.new("TextLabel", presetListFrame)
emptyLbl.Name = "EmptyLabel"
emptyLbl.Size = UDim2.new(1, 0, 0, 28)
emptyLbl.BackgroundTransparency = 1
emptyLbl.Text = "No presets saved yet."
emptyLbl.TextColor3 = C.textSub
emptyLbl.Font = Enum.Font.Gotham
emptyLbl.TextSize = 11
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.LayoutOrder = 1
emptyLbl.ZIndex = 4

local rebuildPresetList
rebuildPresetList = function()
    if not presetListFrame then return end
    for _, child in ipairs(presetListFrame:GetChildren()) do
        if child.Name ~= "EmptyLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    local el = presetListFrame:FindFirstChild("EmptyLabel")
    if el then el.Visible = (#Presets == 0) end
    
    for i, preset in ipairs(Presets) do
        local row = Instance.new("Frame", presetListFrame)
        row.Name = "Preset_"..i
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = C.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i+1
        row.ZIndex = 4
        mkCorner(row, 8)
        mkStroke(row, C.border, 1)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -82, 1, 0)
        nameLbl.Position = UDim2.new(0, 10, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = preset.name
        nameLbl.TextColor3 = C.text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 10
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 5

        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0, 38, 0, 22)
        loadBtn.Position = UDim2.new(1, -82, 0.5, -11)
        loadBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = C.text
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 9
        loadBtn.ZIndex = 5
        mkCorner(loadBtn, 6)
        mkStroke(loadBtn, C.border, 1)
        loadBtn.MouseButton1Click:Connect(function()
            applyPreset(preset.data)
            saveLastPresetName(preset.name)
            loadBtn.Text = "✓"
            task.delay(1.2, function()
                if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
            end)
        end)

        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 28, 0, 22)
        delBtn.Position = UDim2.new(1, -36, 0.5, -11)
        delBtn.BackgroundColor3 = Color3.fromRGB(55,10,80)
        delBtn.BorderSizePixel = 0
        delBtn.Text = "✕"
        delBtn.TextColor3 = Color3.fromRGB(200,100,255)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 11
        delBtn.ZIndex = 5
        mkCorner(delBtn, 6)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(Presets, i)
            savePresetsFile()
            rebuildPresetList()
        end)
    end
end

savePBtn.MouseButton1Click:Connect(function()
    local nm = presetNameBox.Text:match("^%s*(.-)%s*$")
    if nm == "" then
        savePBtn.Text = "Name required!"
        task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end)
        return
    end
    local found = false
    for i, p in ipairs(Presets) do
        if p.name == nm then
            Presets[i].data = buildPresetSnapshot()
            found = true
            break
        end
    end
    if not found then
        table.insert(Presets, {name=nm, data=buildPresetSnapshot()})
    end
    savePresetsFile()
    presetNameBox.Text = ""
    savePBtn.Text = "✓ Saved!"
    task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end)
    rebuildPresetList()
end)


-- ============================================================
-- REOPEN BUTTON
-- ============================================================
local reopenBtn = Instance.new("TextButton", gui)
reopenBtn.Name = "D4vidReopenBtn"
reopenBtn.Size = UDim2.new(0, 64, 0, 26)
reopenBtn.Position = UDim2.new(0, 10, 0, 10)
reopenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
reopenBtn.BorderSizePixel = 0
reopenBtn.Text = "D4VID"
reopenBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
reopenBtn.Font = Enum.Font.GothamBlack
reopenBtn.TextSize = 11
reopenBtn.ZIndex = 200
reopenBtn.Visible = true
mkCorner(reopenBtn, 8)
mkStroke(reopenBtn, Color3.fromRGB(60, 60, 60), 1.5)
reopenBtn.MouseButton1Click:Connect(function()
    mainOuter.Visible = not mainOuter.Visible
end)

do
    local rbDragging, rbDragStart, rbStartPos = false, nil, nil
    reopenBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            rbDragging = true
            rbDragStart = inp.Position
            rbStartPos = reopenBtn.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then rbDragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not rbDragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - rbDragStart
            reopenBtn.Position = UDim2.new(
                rbStartPos.X.Scale, rbStartPos.X.Offset + d.X,
                rbStartPos.Y.Scale, rbStartPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            rbDragging = false
        end
    end)
end


-- ============================================================
-- MOBILE BUTTONS (FIXED with mutual exclusion)
-- ============================================================
local QS, QG, QR = 46, 5, 8
local Q_OFF = Color3.fromRGB(10, 10, 10)
local Q_ON = Color3.fromRGB(80, 40, 160)
local Q_BORDER = Color3.fromRGB(35, 35, 35)
local Q_BORDER_ON = Color3.fromRGB(168, 85, 247)
local Q_TEXT = Color3.fromRGB(255, 255, 255)

local QW = QS * 2 + QG
local QH = QS * 4 + QG * 3

mbGroup = Instance.new("Frame", gui)
mbGroup.Name = "MobileButtons"
mbGroup.Size = UDim2.new(0, QW + 20, 0, QH + 20)
mbGroup.Position = UDim2.new(1, -QW - 34, 0.5, -QH/2 - 10)
mbGroup.BackgroundTransparency = 1
mbGroup.BorderSizePixel = 0
mbGroup.Active = true
mbGroup.ZIndex = 100

makeDraggable(mbGroup)

local function makeMobileBtn(label, col, row, isToggle, onAction)
    local relX = 10 + col*(QS+QG)
    local relY = 10 + row*(QS+QG)
    
    local frame = Instance.new("Frame", mbGroup)
    frame.Size = UDim2.new(0, QS, 0, QS)
    frame.Position = UDim2.new(0, relX, 0, relY)
    frame.BackgroundColor3 = Q_OFF
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 102
    mkCorner(frame, QR)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Q_BORDER
    stroke.Thickness = 1.5
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = label
    btn.TextColor3 = Q_TEXT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextWrapped = true
    btn.LineHeight = 1.25
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 103
    
    local isOn = false
    btn.MouseButton1Click:Connect(function()
        if isToggle then
            isOn = not isOn
            TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundColor3 = isOn and Q_ON or Q_OFF}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Color = isOn and Q_BORDER_ON or Q_BORDER}):Play()
            if onAction then onAction(isOn) end
        else
            TweenService:Create(frame, TweenInfo.new(0.08), {BackgroundColor3 = Q_ON}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.08), {Color = Q_BORDER_ON}):Play()
            task.delay(0.25, function()
                TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundColor3 = Q_OFF}):Play()
                TweenService:Create(stroke, TweenInfo.new(0.15), {Color = Q_BORDER}):Play()
            end)
            if onAction then onAction() end
        end
    end)
    
    local function setter(s)
        isOn = s
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundColor3 = s and Q_ON or Q_OFF}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = s and Q_BORDER_ON or Q_BORDER}):Play()
    end
    
    return frame, setter
end

-- Row 0: DROP BR | AUTO LEFT
makeMobileBtn("DROP\nBR", 0, 0, false, function()
    if not State.dropEnabled then runDropBrainrot() end
end)

local _, setALfn = makeMobileBtn("AUTO\nLEFT", 1, 0, true, function(on)
    State.autoLeftEnabled = on
    if toggleRefs.autoLeft then toggleRefs.autoLeft(on) end
    if on then
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if setAR then setAR(false) end
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            stopAutoRight()
        end
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
            stopBatAimbot()
        end
        startAutoLeft()
    else
        stopAutoLeft()
    end
end)
setAL = setALfn

-- Row 1: BAT LOCK | AUTO RIGHT
local _, setABfn = makeMobileBtn("BAT\nLOCK", 0, 1, true, function(on)
    State.batAimbotToggled = on
    if toggleRefs.aimbot then toggleRefs.aimbot(on) end
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if setAL then setAL(false) end
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            stopAutoLeft()
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if setAR then setAR(false) end
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            stopAutoRight()
        end
        startBatAimbot()
    else
        stopBatAimbot()
    end
end)
setAB = setABfn

local _, setARfn = makeMobileBtn("AUTO\nRIGHT", 1, 1, true, function(on)
    State.autoRightEnabled = on
    if toggleRefs.autoRight then toggleRefs.autoRight(on) end
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if setAL then setAL(false) end
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            stopAutoLeft()
        end
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
            stopBatAimbot()
        end
        startAutoRight()
    else
        stopAutoRight()
    end
end)
setAR = setARfn

-- Row 2: TP DOWN | CARRY SPD
makeMobileBtn("TP\nDOWN", 0, 2, false, function()
    doTpDown()
end)

makeMobileBtn("CARRY\nSPD", 1, 2, true, function(on)
    State.speedToggled = on
    if toggleRefs.carryMode then toggleRefs.carryMode(on) end
end)

-- Row 3: BAT CTR | LAGGER MODE
makeMobileBtn("BAT\nCTR", 0, 3, true, function(on)
    State.batCounterEnabled = on
    if on then startBatCounter() else stopBatCounter() end
end)

makeMobileBtn("LAGGER\nMODE", 1, 3, true, function(on)
    State.laggerEnabled = on
    if toggleRefs.laggerMode then toggleRefs.laggerMode(on) end
    if on then
        State._laggerOriginalCarry = State.carrySpeed
        State.speedToggled = false
    else
        State.carrySpeed = State._laggerOriginalCarry or 30
        if speedBoxRefs.carrySpeed then
            speedBoxRefs.carrySpeed.Text = tostring(State.carrySpeed)
        end
    end
end)


-- ============================================================
-- v3.0 DUEL FEATURES ENGINE
-- ============================================================

-- ============================================================
-- ============================================================
-- v4.0 OP FEATURES (undetected)
-- ============================================================

-- HITBOX EXPANDER: makes enemy hitbox huge so every bat swing connects
local hitboxConn = nil
local hitboxOrigSizes = {}
local function startHitboxExpand()
    if hitboxConn then hitboxConn:Disconnect() end
    hitboxConn = RunService.Heartbeat:Connect(function()
        if not State.hitboxExpandEnabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                if phrp then
                    pcall(function()
                        if not hitboxOrigSizes[p.UserId] then
                            hitboxOrigSizes[p.UserId] = phrp.Size
                        end
                        phrp.Size = Vector3.new(12, 12, 12)
                    end)
                end
            end
        end
    end)
end
local function stopHitboxExpand()
    if hitboxConn then hitboxConn:Disconnect(); hitboxConn = nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local phrp = p.Character:FindFirstChild("HumanoidRootPart")
            if phrp and hitboxOrigSizes[p.UserId] then
                pcall(function() phrp.Size = hitboxOrigSizes[p.UserId] end)
            end
        end
    end
    hitboxOrigSizes = {}
end

-- AUTO PARRY V2: instant knockback cancel + counter-bat in 1 frame
local autoParryV2Conn = nil
local _parryDebounce = false
local _parryPrevVel  = Vector3.zero
local _parryPrevHP   = 100
local function _doParryV2()
    if _parryDebounce then return end
    _parryDebounce = true
    task.spawn(function()
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum2 = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then _parryDebounce = false; return end
        -- 1. Instant knockback cancel
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X * 0.04,
                root.AssemblyLinearVelocity.Y,
                root.AssemblyLinearVelocity.Z * 0.04
            )
        end)
        -- 2. Force running state
        pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Running) end)
        -- 3. Find nearest enemy and counter
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local er = p.Character:FindFirstChild("HumanoidRootPart")
                if er then
                    local d = (er.Position - root.Position).Magnitude
                    if d < bestDist then bestDist = d; best = er end
                end
            end
        end
        if best and bestDist < 18 then
            -- Snap to face them
            pcall(function()
                root.CFrame = CFrame.new(root.Position, Vector3.new(best.Position.X, root.Position.Y, best.Position.Z))
            end)
            -- Micro-TP toward them
            task.defer(function()
                local c2 = LP.Character
                local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if r2 then
                    local t2, td = nil, math.huge
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            local er2 = p.Character:FindFirstChild("HumanoidRootPart")
                            if er2 then local d2=(er2.Position-r2.Position).Magnitude; if d2<td then td=d2;t2=er2 end end
                        end
                    end
                    if t2 and td < 18 then
                        pcall(function() r2.CFrame = r2.CFrame + (t2.Position - r2.Position).Unit * 1.8 end)
                    end
                end
            end)
            -- Fire bat
            local bat = findAnyBat and findAnyBat() or nil
            if bat and bat.Parent == char then
                task.delay(0.025, function()
                    pcall(function() bat:Activate() end)
                    pcall(function()
                        local rem = bat:FindFirstChildOfClass("RemoteEvent")
                        if rem then rem:FireServer() end
                    end)
                end)
            end
        end
        task.wait(0.32)
        _parryDebounce = false
    end)
end
local function startAutoParryV2()
    if autoParryV2Conn then autoParryV2Conn:Disconnect() end
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum2 = char and char:FindFirstChildOfClass("Humanoid")
    _parryPrevVel = root and root.AssemblyLinearVelocity or Vector3.zero
    _parryPrevHP  = hum2 and hum2.Health or 100
    autoParryV2Conn = RunService.Stepped:Connect(function()
        if not State.autoParryV2Enabled then return end
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        local hu = c:FindFirstChildOfClass("Humanoid"); if not hu then return end
        local vel = r.AssemblyLinearVelocity
        local velDelta = Vector3.new(vel.X - _parryPrevVel.X, 0, vel.Z - _parryPrevVel.Z).Magnitude
        _parryPrevVel = vel
        local hp = hu.Health; local hpDrop = _parryPrevHP - hp; _parryPrevHP = hp
        if velDelta > 6 or hpDrop > 2 then task.defer(_doParryV2) end
    end)
end
local function stopAutoParryV2()
    if autoParryV2Conn then autoParryV2Conn:Disconnect(); autoParryV2Conn = nil end
    _parryDebounce = false
end

-- TELE-STEAL: teleports TO the brainrot, steals it, teleports back
local teleStealConn = nil
local _teleStealCooldown = 0
local function startTeleSteal()
    if teleStealConn then teleStealConn:Disconnect() end
    teleStealConn = RunService.Heartbeat:Connect(function()
        if not State.teleStealEnabled then return end
        if tick() - _teleStealCooldown < 0.4 then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local savedCF = root.CFrame
        local best, bestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ProximityPrompt") then
                    local part = obj.Parent
                    if part and part:IsA("BasePart") then
                        local owner = part.Parent and part.Parent:FindFirstChildWhichIsA("ObjectValue")
                        if owner and owner.Value and owner.Value ~= LP then
                            local d = (part.Position - root.Position).Magnitude
                            if d < 60 and d < bestDist then bestDist = d; best = {prompt=obj, part=part} end
                        end
                    end
                end
            end)
        end
        if not best then return end
        _teleStealCooldown = tick()
        task.spawn(function()
            -- TP to prompt
            pcall(function() root.CFrame = CFrame.new(best.part.Position + Vector3.new(0, 3, 0)) end)
            task.wait(0.05)
            -- Fire steal
            pcall(function() best.prompt.Triggered:Fire(LP) end)
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.07)
                VU:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
            task.wait(0.12)
            -- TP back to original pos
            pcall(function() root.CFrame = savedCF end)
        end)
    end)
end
local function stopTeleSteal()
    if teleStealConn then teleStealConn:Disconnect(); teleStealConn = nil end
end

-- NOCLIP: walk through walls
local noclipConn = nil
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not State.noclipEnabled then return end
        local char = LP.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            pcall(function() part.CanCollide = true end)
        end
    end
end

-- SPINBOT: rapid CFrame rotation to make bat hit from any angle
local spinbotConn = nil
local _spinAngle  = 0
local function startSpinbot()
    if spinbotConn then spinbotConn:Disconnect() end
    spinbotConn = RunService.RenderStepped:Connect(function(dt)
        if not State.spinbotEnabled then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        _spinAngle = (_spinAngle + dt * 1200) % 360
        pcall(function()
            local pos = root.Position
            root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(_spinAngle), 0)
        end)
    end)
end
local function stopSpinbot()
    if spinbotConn then spinbotConn:Disconnect(); spinbotConn = nil end
    _spinAngle = 0
end

-- CAMERA LOCK: locks camera onto nearest enemy like aim assist
local camLockConn = nil
local function startCamLock()
    if camLockConn then camLockConn:Disconnect() end
    camLockConn = RunService.RenderStepped:Connect(function()
        if not State.camLockEnabled then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local er = p.Character:FindFirstChild("HumanoidRootPart")
                local eh = p.Character:FindFirstChildOfClass("Humanoid")
                if er and eh and eh.Health > 0 then
                    local d = (er.Position - myRoot.Position).Magnitude
                    if d < bestDist then bestDist = d; best = er end
                end
            end
        end
        if best then
            pcall(function()
                cam.CFrame = CFrame.new(cam.CFrame.Position, best.Position)
            end)
        end
    end)
end
local function stopCamLock()
    if camLockConn then camLockConn:Disconnect(); camLockConn = nil end
end

-- AUTO RESET: auto-resets the duel when you die (holds reset button)
local autoResetConn = nil
local _autoResetCooldown = 0
local function startAutoReset()
    if autoResetConn then autoResetConn:Disconnect() end
    autoResetConn = RunService.Heartbeat:Connect(function()
        if not State.autoResetEnabled then return end
        if tick() - _autoResetCooldown < 3 then return end
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        if hum2.Health <= 0 or hum2:GetState() == Enum.HumanoidStateType.Dead then
            _autoResetCooldown = tick()
            task.spawn(function()
                -- Try to click reset/respawn button in UI
                pcall(function()
                    local pg = LP:FindFirstChild("PlayerGui")
                    if not pg then return end
                    for _, sg in ipairs(pg:GetDescendants()) do
                        if sg:IsA("TextButton") then
                            local t = sg.Text:lower()
                            if t:find("reset") or t:find("respawn") or t:find("restart") or t:find("retry") then
                                sg:GetPropertyChangedSignal("Text"):Connect(function() end)
                                sg.MouseButton1Click:Fire()
                                task.wait(0.1)
                                sg.Activated:Fire()
                            end
                        end
                    end
                end)
            end)
        end
    end)
end
local function stopAutoReset()
    if autoResetConn then autoResetConn:Disconnect(); autoResetConn = nil end
end

-- ESP SYSTEM (shows player positions + health + distance)
local espGuis = {}
local espHeartbeat = nil

local function createESPFor(player)
    if espGuis[player] then return end
    local function update()
        if not player.Character then return end
        local head = player.Character:FindFirstChild("Head")
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not head or not hum then return end
        if espGuis[player] and espGuis[player].Parent then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "d4vidESP_" .. player.Name
        bb.Size = UDim2.new(0, 140, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Name = "NameLbl"
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.DisplayName
        nameLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextScaled = true
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        local infoLbl = Instance.new("TextLabel", bb)
        infoLbl.Name = "InfoLbl"
        infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
        infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text = "HP: " .. math.floor(hum.Health)
        infoLbl.TextColor3 = Color3.fromRGB(100, 255, 120)
        infoLbl.Font = Enum.Font.Gotham
        infoLbl.TextScaled = true
        infoLbl.TextStrokeTransparency = 0
        infoLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        espGuis[player] = bb
    end
    update()
end

local function removeESPFor(player)
    if espGuis[player] then
        pcall(function() espGuis[player]:Destroy() end)
        espGuis[player] = nil
    end
end

local function startESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then createESPFor(p) end
    end
    espHeartbeat = RunService.Heartbeat:Connect(function()
        if not State.espEnabled then return end
        local myChar = LP.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                createESPFor(p)
                -- Update info
                if espGuis[p] and p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    local infoLbl = espGuis[p]:FindFirstChild("InfoLbl")
                    if hum and infoLbl and pHRP and myHRP then
                        local dist = math.floor((pHRP.Position - myHRP.Position).Magnitude)
                        infoLbl.Text = "HP:" .. math.floor(hum.Health) .. " | " .. dist .. "m"
                        -- Color by health
                        local r = 1 - (hum.Health / hum.MaxHealth)
                        infoLbl.TextColor3 = Color3.new(r, 1 - r * 0.5, 0)
                    end
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(removeESPFor)
end

local function stopESP()
    if espHeartbeat then espHeartbeat:Disconnect(); espHeartbeat = nil end
    for p, _ in pairs(espGuis) do
        removeESPFor(p)
    end
    espGuis = {}
end

-- POSITION ESP (shows YOUR position on screen, undetected for anti-cheat)
local posESPGui = nil

local function startPosESP()
    if posESPGui then posESPGui:Destroy() end
    posESPGui = Instance.new("ScreenGui")
    posESPGui.Name = "d4vidPosESP"
    posESPGui.ResetOnSpawn = false
    posESPGui.DisplayOrder = 1000
    pcall(function() posESPGui.Parent = game:GetService("CoreGui") end)
    if not posESPGui.Parent then posESPGui.Parent = LP.PlayerGui end

    local frame = Instance.new("Frame", posESPGui)
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(0.5, -100, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(8, 6, 16)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(124, 58, 237)
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Name = "PosLbl"
    lbl.Size = UDim2.new(1, 0, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "POS: loading..."
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10

    local spdLbl = Instance.new("TextLabel", frame)
    spdLbl.Name = "SpdLbl"
    spdLbl.Size = UDim2.new(1, 0, 0.5, 0)
    spdLbl.Position = UDim2.new(0, 0, 0.5, 0)
    spdLbl.BackgroundTransparency = 1
    spdLbl.Text = "SPD: 0.0"
    spdLbl.TextColor3 = Color3.fromRGB(124, 200, 124)
    spdLbl.Font = Enum.Font.GothamBold
    spdLbl.TextSize = 10

    RunService.RenderStepped:Connect(function()
        if not State.posESPEnabled then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local pos = root.Position
        local spd = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        lbl.Text = string.format("X:%.1f Y:%.1f Z:%.1f", pos.X, pos.Y, pos.Z)
        spdLbl.Text = string.format("SPD: %.1f", spd)
    end)
end

local function stopPosESP()
    if posESPGui then posESPGui:Destroy(); posESPGui = nil end
end

-- SILENT AIM (aim assist that moves hitbox toward bat)
local silentAimConn = nil

local function startSilentAim()
    if silentAimConn then silentAimConn:Disconnect() end
    silentAimConn = RunService.Heartbeat:Connect(function()
        if not State.silentAimEnabled then return end
        local char = LP.Character
        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        -- Find closest enemy and slightly shift their HRP toward us
        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                if pHRP and pHum and pHum.Health > 0 then
                    local d = (pHRP.Position - myHRP.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = p
                    end
                end
            end
        end
        if closest and closestDist < 20 then
            local pHRP = closest.Character:FindFirstChild("HumanoidRootPart")
            if pHRP then
                local dir = (myHRP.Position - pHRP.Position).Unit
                pcall(function()
                    pHRP.CFrame = pHRP.CFrame + dir * 0.3
                end)
            end
        end
    end)
end

local function stopSilentAim()
    if silentAimConn then silentAimConn:Disconnect(); silentAimConn = nil end
end

-- BRAINROT AUTO STEAL (grabs brainrot specifically from duels)
-- Enhanced version: also looks for duel-specific items like brainrot pets
local function findBrainrotPrompt()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist = nil, math.huge

    -- Search entire workspace for any ProximityPrompt (not just plots)
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    local dist = (part.Position - root.Position).Magnitude
                    local name = part.Name:lower()
                    -- Target brainrot specifically
                    if dist < 15 and (
                        name:find("brainrot") or
                        name:find("pet") or
                        name:find("animal") or
                        name:find("spawn") or
                        name:find("pickup")
                    ) then
                        if dist < bestDist then
                            bestDist = dist
                            best = obj
                        end
                    end
                end
            end
        end)
    end
    return best
end

local brainrotConn = nil
local function startBrainrotSteal()
    if brainrotConn then brainrotConn:Disconnect() end
    brainrotConn = RunService.Heartbeat:Connect(function()
        if not State.brainrotStealEnabled then return end
        if State.isStealing then return end
        -- Try normal steal first
        local p = findNearestPrompt()
        if p then
            executeSteal(p)
            return
        end
        -- Then try brainrot-specific
        local bp = findBrainrotPrompt()
        if bp then
            executeSteal(bp)
        end
    end)
end

local function stopBrainrotSteal()
    if brainrotConn then brainrotConn:Disconnect(); brainrotConn = nil end
end

-- GHOST MODE (makes you visually invisible to other players)
local function startGhostMode()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = 1
            end
        end)
    end
end

local function stopGhostMode()
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") then
                if part.Name == "HumanoidRootPart" then
                    part.Transparency = 1
                else
                    part.Transparency = 0
                end
            elseif part:IsA("Decal") then
                part.Transparency = 0
            end
        end)
    end
end

-- DUEL SPEED BYPASS (locked to 57 normal / 27 carry, undetected)
local function applyDuelSpeedBypass(on)
    if on then
        State.duelNormalSpeed = 57
        State.duelCarrySpeed = 27
        -- Temporarily override speeds
        State.normalSpeed = 57
        State.carrySpeed = 27
        if speedBoxRefs.normalSpeed then speedBoxRefs.normalSpeed.Text = "57" end
        if speedBoxRefs.carrySpeed then speedBoxRefs.carrySpeed.Text = "27" end
    else
        -- Restore previous
        State.normalSpeed = 59
        State.carrySpeed = 30
        if speedBoxRefs.normalSpeed then speedBoxRefs.normalSpeed.Text = "59" end
        if speedBoxRefs.carrySpeed then speedBoxRefs.carrySpeed.Text = "30" end
    end
    task.spawn(saveConfig)
end

-- ANTI COUNTER (makes you harder to counter bat)
local antiCounterConn = nil
local function startAntiCounter()
    if antiCounterConn then antiCounterConn:Disconnect() end
    antiCounterConn = RunService.Heartbeat:Connect(function()
        if not State.antiCounterEnabled then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local st = hum:GetState()
        -- When hit, immediately recover
        if st == Enum.HumanoidStateType.Physics or
           st == Enum.HumanoidStateType.Ragdoll or
           st == Enum.HumanoidStateType.FallingDown then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            root.Velocity = Vector3.new(root.Velocity.X * 0.3, 0, root.Velocity.Z * 0.3)
        end
    end)
end

local function stopAntiCounter()
    if antiCounterConn then antiCounterConn:Disconnect(); antiCounterConn = nil end
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function setupChar(char)
    task.wait(0.1)
    h=char:WaitForChild("Humanoid",5)
    hrp=char:WaitForChild("HumanoidRootPart",5)
    if not h or not hrp then return end
    
    local head=char:FindFirstChild("Head")
    if head then
        local oldBB=head:FindFirstChild("d4vidhubBB") or head:FindFirstChild("opiumhubBB")
        if oldBB then oldBB:Destroy() end
        
        local bb=Instance.new("BillboardGui",head)
        bb.Name="d4vidhubBB"
        bb.Size=UDim2.new(0,180,0,76)
        bb.StudsOffset=Vector3.new(0,3,0)
        bb.AlwaysOnTop=true

        local ragdollLbl=Instance.new("TextLabel",bb)
        ragdollLbl.Name="RagdollTimerLbl"
        ragdollLbl.Size=UDim2.new(1,0,0,26)
        ragdollLbl.Position=UDim2.new(0,0,0,0)
        ragdollLbl.BackgroundTransparency=1
        ragdollLbl.Text=""
        ragdollLbl.TextColor3=Color3.fromRGB(255,80,80)
        ragdollLbl.Font=Enum.Font.GothamBlack
        ragdollLbl.TextScaled=true
        ragdollLbl.TextStrokeTransparency=0.1
        ragdollLbl.TextStrokeColor3=Color3.new(0,0,0)
        ragdollLbl.Visible=false

        local speedBillLbl=Instance.new("TextLabel",bb)
        speedBillLbl.Name="SpeedBillLbl"
        speedBillLbl.Size=UDim2.new(1,0,0,24)
        speedBillLbl.Position=UDim2.new(0,0,0,26)
        speedBillLbl.BackgroundTransparency=1
        speedBillLbl.Text="0.0"
        speedBillLbl.TextColor3=Color3.fromRGB(210,210,210)
        speedBillLbl.Font=Enum.Font.GothamBlack
        speedBillLbl.TextScaled=true
        speedBillLbl.TextStrokeTransparency=0.1
        speedBillLbl.TextStrokeColor3=Color3.new(0,0,0)

        local lbl2=Instance.new("TextLabel",bb)
        lbl2.Size=UDim2.new(1,0,0,24)
        lbl2.Position=UDim2.new(0,0,0,52)
        lbl2.BackgroundTransparency=1
        lbl2.Text = ".gg/NmXRBxAkX"
        lbl2.TextColor3=Color3.fromRGB(255,255,255)
        lbl2.Font=Enum.Font.GothamBold
        lbl2.TextScaled=true
        lbl2.TextStrokeTransparency=0.1
        lbl2.TextStrokeColor3=Color3.new(0,0,0)
    end

    local ragTimerActive = false
    local function startRagdollTimer()
        if ragTimerActive then return end
        ragTimerActive = true
        State.countdownActive = true  -- DETECTION: Countdown started
        task.spawn(function()
            local char2 = LP.Character
            local head2 = char2 and char2:FindFirstChild("Head")
            local bb2 = head2 and head2:FindFirstChild("d4vidhubBB")
            local timerLbl = bb2 and bb2:FindFirstChild("RagdollTimerLbl")
            if not timerLbl then ragTimerActive = false; State.countdownActive = false; return end
            local countdown = 3
            timerLbl.Visible = true
            timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            while countdown > 0 do
                timerLbl.Text = tostring(countdown)
                timerLbl.TextColor3 = ({Color3.fromRGB(255, 60, 60),Color3.fromRGB(255, 140, 40),Color3.fromRGB(255, 220, 40)})[math.max(1, 4 - countdown)]
                task.wait(1)
                countdown = countdown - 1
            end
            timerLbl.Text = "READY TO STEAL"
            timerLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            repeat task.wait(0.1) until (function()
                local c3 = LP.Character
                local hum3 = c3 and c3:FindFirstChildOfClass("Humanoid")
                if not hum3 then return true end
                local st3 = hum3:GetState()
                return st3 ~= Enum.HumanoidStateType.Physics and st3 ~= Enum.HumanoidStateType.Ragdoll and st3 ~= Enum.HumanoidStateType.FallingDown
            end)()
            timerLbl.Visible = false
            timerLbl.Text = ""
            ragTimerActive = false
            State.countdownActive = false  -- DETECTION: Countdown ended
        end)
    end

    RunService.Heartbeat:Connect(function()
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            startRagdollTimer()
        end
    end)
    
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    _unwalkAnimations={}
    if State.unwalkEnabled then task.wait(0.3); startUnwalk() end
    stopAntiRagdoll()
    if State.antiRagdollEnabled then task.wait(0.5); startAntiRagdoll() end
    if State.medusaCounterEnabled then setupMedusaCounter(char) end
    if State.batAimbotToggled then stopBatAimbot(); task.wait(0.2); pcall(startBatAimbot) end
    if State.batCounterEnabled then task.wait(0.3); startBatCounter() end
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ============================================================
-- RUNTIME LOOPS
-- ============================================================
RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

local MOVE_KEYS={
    [Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true
}

RunService.RenderStepped:Connect(function()
    if not (h and hrp) then return end
    
    if not State.batAimbotToggled and not State.autoLeftEnabled and not State.autoRightEnabled then
        local md=h.MoveDirection
        local spd
        if State.laggerEnabled then
            spd=State.laggerSpeed
        elseif State.speedToggled then
            spd=State.carrySpeed
        else
            spd=State.normalSpeed
        end
        
        if md.Magnitude>0 then
            State.lastMoveDir=md
            hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
            local anyHeld=false
            for key in pairs(MOVE_KEYS) do
                if UIS:IsKeyDown(key) then anyHeld=true; break end
            end
            if anyHeld then
                hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd)
            end
        end
    end
    
    pcall(function()
        local head2=LP.Character and LP.Character:FindFirstChild("Head")
        if head2 then
            local bb2=head2:FindFirstChild("d4vidhubBB") or head2:FindFirstChild("opiumhubBB")
            local sl=bb2 and bb2:FindFirstChild("SpeedBillLbl")
            if sl then
                sl.Text=string.format("%.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude)
            end
        end
    end)
end)

-- ============================================================
-- INPUT HANDLERS
-- ============================================================
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    local t = inp.UserInputType
    local isKb = t==Enum.UserInputType.Keyboard
    local isGP = t==Enum.UserInputType.Gamepad1 or t==Enum.UserInputType.Gamepad2
    if not isKb and not isGP then return end
    local kc = inp.KeyCode
    if kc == Enum.KeyCode.Unknown then return end
    
    if kc == Keys.speed then
        State.speedToggled = not State.speedToggled
        if toggleRefs.carryMode then toggleRefs.carryMode(State.speedToggled) end
    elseif kc == Keys.lagger then
        State.laggerEnabled = not State.laggerEnabled
        if toggleRefs.laggerMode then toggleRefs.laggerMode(State.laggerEnabled) end
        if State.laggerEnabled then
            State._laggerOriginalCarry = State.carrySpeed
            State._prevSpeed = State.speedToggled
            State.speedToggled = false
        else
            State.carrySpeed = State._laggerOriginalCarry or 30
            State.speedToggled = State._prevSpeed or false
            if speedBoxRefs.carrySpeed then
                speedBoxRefs.carrySpeed.Text = tostring(State.carrySpeed)
            end
        end
    elseif kc == Keys.autoLeft then
        State.autoLeftEnabled = not State.autoLeftEnabled
        if toggleRefs.autoLeft then toggleRefs.autoLeft(State.autoLeftEnabled) end
        if setAL then setAL(State.autoLeftEnabled) end
        if State.autoLeftEnabled and State.batAimbotToggled then
            State.batAimbotToggled = false
            stopBatAimbot()
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        end
        if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
    elseif kc == Keys.autoRight then
        State.autoRightEnabled = not State.autoRightEnabled
        if toggleRefs.autoRight then toggleRefs.autoRight(State.autoRightEnabled) end
        if setAR then setAR(State.autoRightEnabled) end
        if State.autoRightEnabled and State.batAimbotToggled then
            State.batAimbotToggled = false
            stopBatAimbot()
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        end
        if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
    elseif kc == Keys.drop then
        if not State.dropEnabled then runDropBrainrot() end
    elseif kc == Keys.tpDown then
        doTpDown()
    elseif kc == Keys.aimbot then
        State.batAimbotToggled = not State.batAimbotToggled
        if toggleRefs.aimbot then toggleRefs.aimbot(State.batAimbotToggled) end
        if setAB then setAB(State.batAimbotToggled) end
        if State.batAimbotToggled then
            if State.autoLeftEnabled then
                State.autoLeftEnabled = false
                stopAutoLeft()
                if setAL then setAL(false) end
                if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            end
            if State.autoRightEnabled then
                State.autoRightEnabled = false
                stopAutoRight()
                if setAR then setAR(false) end
                if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            end
            pcall(startBatAimbot)
        else
            stopBatAimbot()
        end
    elseif kc == Keys.unwalk then
        State.unwalkEnabled = not State.unwalkEnabled
        if toggleRefs.unwalk then toggleRefs.unwalk(State.unwalkEnabled) end
        if State.unwalkEnabled then startUnwalk() else stopUnwalk() end
    elseif kc == Keys.duelLagger then
        toggleDuelLagger()
    elseif kc == Keys.instaReset then
        doInstaReset()
    elseif kc == Keys.hitboxExpand then
        State.hitboxExpandEnabled = not State.hitboxExpandEnabled
        if toggleRefs.hitboxExpand then toggleRefs.hitboxExpand(State.hitboxExpandEnabled) end
        if State.hitboxExpandEnabled then startHitboxExpand() else stopHitboxExpand() end
    elseif kc == Keys.autoParryV2 then
        State.autoParryV2Enabled = not State.autoParryV2Enabled
        if toggleRefs.autoParryV2 then toggleRefs.autoParryV2(State.autoParryV2Enabled) end
        if State.autoParryV2Enabled then startAutoParryV2() else stopAutoParryV2() end
    elseif kc == Keys.teleSteal then
        State.teleStealEnabled = not State.teleStealEnabled
        if toggleRefs.teleSteal then toggleRefs.teleSteal(State.teleStealEnabled) end
        if State.teleStealEnabled then startTeleSteal() else stopTeleSteal() end
    elseif kc == Keys.camLock then
        State.camLockEnabled = not State.camLockEnabled
        if toggleRefs.camLock then toggleRefs.camLock(State.camLockEnabled) end
        if State.camLockEnabled then startCamLock() else stopCamLock() end
    elseif kc == Keys.noclip then
        State.noclipEnabled = not State.noclipEnabled
        if toggleRefs.noclip then toggleRefs.noclip(State.noclipEnabled) end
        if State.noclipEnabled then startNoclip() else stopNoclip() end
    elseif kc == Keys.spinbot then
        State.spinbotEnabled = not State.spinbotEnabled
        if toggleRefs.spinbot then toggleRefs.spinbot(State.spinbotEnabled) end
        if State.spinbotEnabled then startSpinbot() else stopSpinbot() end
        State.ghostModeEnabled = not State.ghostModeEnabled
        if toggleRefs.ghostMode then toggleRefs.ghostMode(State.ghostModeEnabled) end
        if State.ghostModeEnabled then startGhostMode() else stopGhostMode() end
    elseif kc == Keys.duelSpeed then
        State.duelSpeedBypass = not State.duelSpeedBypass
        if toggleRefs.duelSpeed then toggleRefs.duelSpeed(State.duelSpeedBypass) end
        applyDuelSpeedBypass(State.duelSpeedBypass)
    elseif kc == Keys.guiHide then
        mbGroup.Visible = not mbGroup.Visible
    end
end)


-- ============================================================
-- DUELS v4.0
-- ============================================================
makeSectionHeader("DUELS v4.0")
makeDivider()

toggleRefs.hitboxExpand = makeToggleRow("Hitbox Expander [J]", false, function(on)
    State.hitboxExpandEnabled = on
    if on then startHitboxExpand() else stopHitboxExpand() end
end, "hitboxExpand")

toggleRefs.autoParryV2 = makeToggleRow("Auto Parry V2 [N]", false, function(on)
    State.autoParryV2Enabled = on
    if on then startAutoParryV2() else stopAutoParryV2() end
end, "autoParryV2")

toggleRefs.teleSteal = makeToggleRow("Tele-Steal [T]", false, function(on)
    State.teleStealEnabled = on
    if on then startTeleSteal() else stopTeleSteal() end
end, "teleSteal")

toggleRefs.camLock = makeToggleRow("Camera Lock [M]", false, function(on)
    State.camLockEnabled = on
    if on then startCamLock() else stopCamLock() end
end, "camLock")

toggleRefs.noclip = makeToggleRow("Noclip [P]", false, function(on)
    State.noclipEnabled = on
    if on then startNoclip() else stopNoclip() end
end, "noclip")

toggleRefs.spinbot = makeToggleRow("Spinbot [B]", false, function(on)
    State.spinbotEnabled = on
    if on then startSpinbot() else stopSpinbot() end
end, "spinbot")

toggleRefs.esp = makeToggleRow("Player ESP [K]", false, function(on)
    State.espEnabled = on
    if on then startESP() else stopESP() end
end, "esp")

toggleRefs.posESP = makeToggleRow("Position ESP", false, function(on)
    State.posESPEnabled = on
    if on then startPosESP() else stopPosESP() end
end)

toggleRefs.silentAim = makeToggleRow("Silent Aim [Y]", false, function(on)
    State.silentAimEnabled = on
    if on then startSilentAim() else stopSilentAim() end
end, "silentAim")

toggleRefs.brainrotSteal = makeToggleRow("Brainrot Steal", false, function(on)
    State.brainrotStealEnabled = on
    if on then startBrainrotSteal() else stopBrainrotSteal() end
end)

toggleRefs.ghostMode = makeToggleRow("Ghost Mode [O]", false, function(on)
    State.ghostModeEnabled = on
    if on then startGhostMode() else stopGhostMode() end
end, "ghostMode")

toggleRefs.antiCounter = makeToggleRow("Anti Counter", false, function(on)
    State.antiCounterEnabled = on
    if on then startAntiCounter() else stopAntiCounter() end
end)

toggleRefs.autoReset = makeToggleRow("Auto Reset", false, function(on)
    State.autoResetEnabled = on
    if on then startAutoReset() else stopAutoReset() end
end)

makeDivider()

-- ============================================================
-- INIT
-- ============================================================
loadPresetsFile()
loadConfig()
rebuildPresetList()

do
    local lastPresetName = loadLastPresetName()
    if lastPresetName and lastPresetName ~= "" then
        for _, preset in ipairs(Presets) do
            if preset.name == lastPresetName then
                applyPreset(preset.data)
                print("[d4vid hub] Auto-loaded preset: " .. lastPresetName)
                break
            end
        end
    end
end

for keyRef, btn in pairs(keybindBtnRefs) do
    if Keys[keyRef] then
        btn.Text = getKeyName(Keys[keyRef])
    end
end

if speedBoxRefs.normalSpeed then speedBoxRefs.normalSpeed.Text = tostring(State.normalSpeed) end
if speedBoxRefs.carrySpeed then speedBoxRefs.carrySpeed.Text = tostring(State.carrySpeed) end
if speedBoxRefs.laggerSpeed then speedBoxRefs.laggerSpeed.Text = tostring(State.laggerSpeed) end

mainOuter.Size = UDim2.new(0, 0, 0, 0)
mainOuter.Visible = true
TweenService:Create(mainOuter, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, WIN_W, 0, WIN_H)
}):Play()

task.spawn(function()
    while task.wait(10) do
        pcall(saveConfig)
    end
end)

print("[D4VID HUB v4.0] ✅ Loaded!")
print("✓ Removed: Desync, Super Lagger")
print("✓ Added: Hitbox Expander, Auto Parry V2, Tele-Steal, Noclip, Spinbot, CamLock, Auto Reset")

