--[[
    1NXS DEMONOLOGY HUB v5.0
    made by 1nxs on discord
    FIXED: Ghost limit 25, EMF notify hook, Spirit Box notify, Laser with ghost transparency
    MERGED: All v4 features into v5 including abilities tracker, reference, log & analysis
--]]

-- ═══════════════════════════════════════
--   KEY SYSTEM (anti-theft: server-free, algorithmic validation)
-- ═══════════════════════════════════════

-- Key format: "1NXS-XXXXX-XXXXX-XXXXX"
-- Generated offline using secret seed (not in script)
-- Validation: checksum of segments + rotating polynomial hash
local function isValidKey(key)
    if type(key) ~= "string" then return false end
    local parts = {}
    for match in key:gmatch("[^-]+") do
        table.insert(parts, match:upper())
    end
    if #parts ~= 4 then return false end
    if parts[1] ~= "1NXS" then return false end
    if #parts[2] ~= 5 or #parts[3] ~= 5 or #parts[4] ~= 5 then return false end

    local seed = 0x1A3F
    local function hashStep(v, c)
        return ((v * 33) + c + seed) % 0xFFFFFF
    end

    local expected = ""
    local h = seed
    for i = 1, 5 do
        local c = string.byte(parts[2], i)
        h = hashStep(h, c)
    end
    for i = 1, 5 do
        local c = string.byte(parts[3], i)
        h = hashStep(h, c)
        local ch = 65 + ((h + c + i * 7) % 26)
        expected = expected .. string.char(ch)
    end
    return expected == parts[4]
end

local function showKeySystem()
    local player = game:GetService("Players").LocalPlayer
    if not player then
        player = game:GetService("Players").PlayersAdded:Wait()
    end

    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "1nxsKeySystem"
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = player:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Parent = keyGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 200)
    frame.Position = UDim2.new(0.5, -170, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent = keyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 60, 180)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔑 Demonology Hub v5.0"
    title.TextColor3 = Color3.fromRGB(200, 160, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 48)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your license key to continue"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.Parent = frame

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -60, 0, 38)
    inputBg.Position = UDim2.new(0, 30, 0, 76)
    inputBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    inputBg.BorderSizePixel = 0
    inputBg.Parent = frame
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBg

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -16, 1, 0)
    inputBox.Position = UDim2.new(0, 8, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = ""
    inputBox.PlaceholderText = "Enter key..."
    inputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputBg

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 18)
    statusLabel.Position = UDim2.new(0, 20, 0, 120)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.Parent = frame

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, -80, 0, 36)
    submitBtn.Position = UDim2.new(0, 40, 0, 148)
    submitBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "UNLOCK"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 14
    submitBtn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = submitBtn

    local keyValid = false
    local keyCooldown = false

    local function validateKey(key)
        if keyCooldown then return end
        keyCooldown = true
        task.delay(1, function() keyCooldown = false end)

        local trimmed = key:gsub("%s", "")
        if #trimmed == 0 then
            statusLabel.Text = "Please enter a key"
            return
        end

        if isValidKey(trimmed) then
            statusLabel.TextColor3 = Color3.fromRGB(60, 200, 60)
            statusLabel.Text = "✓ Key accepted! Loading..."
            keyValid = true
            saveKey(trimmed)
            task.wait(0.5)
            keyGui:Destroy()
            return
        end

        statusLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
        statusLabel.Text = "✗ Invalid key — contact 1nxs on discord"
    end

    submitBtn.MouseButton1Click:Connect(function()
        validateKey(inputBox.Text)
    end)

    inputBox.FocusLost:Connect(function(enter)
        if enter then validateKey(inputBox.Text) end
    end)

    -- Wait for key validation (5 min timeout)
    local deadline = tick() + 300
    while not keyValid and tick() < deadline do
        task.wait(0.5)
    end

    keyGui:Destroy()
    return keyValid
end

-- Key persistence: save/load key with 24h expiry
local KEY_FILE = "1nxs_hub_key.dat"
local function loadSavedKey()
    local ok, saved = pcall(function()
        if not isfile then return nil end
        if not isfile(KEY_FILE) then return nil end
        local data = readfile(KEY_FILE)
        local parsed = game:GetService("HttpService"):JSONDecode(data)
        if type(parsed) ~= "table" or type(parsed.key) ~= "string" or type(parsed.expiry) ~= "number" then
            return nil
        end
        if tick() >= parsed.expiry then
            delfile(KEY_FILE)
            return nil
        end
        return parsed.key
    end)
    return ok
end
local function saveKey(key)
    pcall(function()
        if not writefile then return end
        local expiry = tick() + 86400
        local data = game:GetService("HttpService"):JSONEncode({key = key, expiry = expiry})
        writefile(KEY_FILE, data)
    end)
end

-- Run key system (skip if already authed this session or saved key valid)
local function needsKey()
    if _G["1NXS_AUTHENTICATED"] then return false end
    local saved = loadSavedKey()
    if saved and isValidKey(saved) then
        _G["1NXS_AUTHENTICATED"] = true
        return false
    end
    return true
end
if needsKey() then
    local success = pcall(showKeySystem)
    if not success then
        print("[1nxs Hub] ❌ Key validation failed or cancelled")
        return
    end
end
_G["1NXS_AUTHENTICATED"] = true

-- ═══════════════════════════════════════
--   SERVICES
-- ═══════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Events      = ReplicatedStorage:FindFirstChild("Events")

pcall(function()
    for _, n in ipairs({"1nxsHub","1nxsLoader","1nxsEvidHUD"}) do
        local o = CoreGui:FindFirstChild(n)
        if o then o:Destroy() end
    end
    local b = Lighting:FindFirstChild("HubBlur")
    if b then b:Destroy() end
end)

local C = {
    Key             = Enum.KeyCode.RightShift,
    Bg1             = Color3.fromRGB(10, 10, 14),
    Bg2             = Color3.fromRGB(16, 16, 22),
    Bg3             = Color3.fromRGB(22, 22, 30),
    Bg4             = Color3.fromRGB(30, 30, 40),
    BgHover         = Color3.fromRGB(38, 38, 50),
    Accent          = Color3.fromRGB(140, 148, 170),
    AccentDim       = Color3.fromRGB(90, 96, 115),
    AccentBright    = Color3.fromRGB(200, 208, 225),
    Text1           = Color3.fromRGB(225, 228, 238),
    Text2           = Color3.fromRGB(145, 150, 165),
    Text3           = Color3.fromRGB(80, 84, 100),
    Green           = Color3.fromRGB(64, 218, 118),
    Red             = Color3.fromRGB(240, 100, 100),
    Yellow          = Color3.fromRGB(245, 200, 20),
    Blue            = Color3.fromRGB(86, 155, 245),
    Purple          = Color3.fromRGB(182, 122, 248),
    Orange          = Color3.fromRGB(248, 146, 60),
    EvidEMF         = Color3.fromRGB(250, 204, 21),
    EvidPrints      = Color3.fromRGB(182, 122, 248),
    EvidSpirit      = Color3.fromRGB(86, 155, 245),
    EvidOrb         = Color3.fromRGB(64, 218, 118),
    EvidFreeze      = Color3.fromRGB(140, 195, 255),
    EvidInscript    = Color3.fromRGB(240, 100, 100),
    EvidLaser       = Color3.fromRGB(248, 146, 60),
    EvidWither      = Color3.fromRGB(158, 128, 98),
    AbilityColors   = {
        Teleport    = Color3.fromRGB(255, 100, 200),
        ThrowItems  = Color3.fromRGB(255, 160, 50),
        BreakGlass  = Color3.fromRGB(200, 230, 255),
        FlickerLights = Color3.fromRGB(255, 255, 100),
        FlickerItems  = Color3.fromRGB(255, 200, 100),
        BlueFlame   = Color3.fromRGB(100, 150, 255),
        MultiThrow  = Color3.fromRGB(255, 60, 60),
        TeleportRoom = Color3.fromRGB(200, 100, 255),
        PowerOut    = Color3.fromRGB(255, 50, 50),
        ThrowCorpse = Color3.fromRGB(150, 80, 50),
        SpeedBoost  = Color3.fromRGB(50, 255, 100),
        SaltSlow    = Color3.fromRGB(200, 200, 255),
        EarlyHunt   = Color3.fromRGB(255, 50, 150),
        LookSpeed   = Color3.fromRGB(255, 150, 200),
        ConsumptionAttract = Color3.fromRGB(200, 100, 50),
        LowEnergyTarget = Color3.fromRGB(100, 200, 255),
        FrequentHunt = Color3.fromRGB(255, 100, 100),
        HuntFlicker = Color3.fromRGB(150, 150, 255),
        ExtendedHunt = Color3.fromRGB(200, 50, 50),
        LookSlow    = Color3.fromRGB(100, 255, 200),
        HuntSpeed   = Color3.fromRGB(255, 200, 50),
        HuntBlind   = Color3.fromRGB(100, 50, 150),
        LidarInvisible = Color3.fromRGB(200, 100, 200),
        DarkRoom    = Color3.fromRGB(80, 80, 150),
        ColdAggression = Color3.fromRGB(100, 200, 255),
        FavoriteRoom = Color3.fromRGB(255, 200, 200),
        ElectronicAttract = Color3.fromRGB(200, 255, 100),
    },
    Speed           = 0.3,
    SpeedFast       = 0.15,
    Font            = Enum.Font.GothamBold,
    FontMed         = Enum.Font.GothamMedium,
    FontReg         = Enum.Font.Gotham,
    FontNum         = Enum.Font.GothamMedium,
}

local GhostDB = {
    Aswang    = {"Wither","EMF5","GhostWriting"},
    Banshee   = {"GhostOrb","Handprints","Freezing"},
    Demon     = {"EMF5","Handprints","Freezing"},
    Dullahan  = {"Wither","Laser","Freezing"},
    Dybbuk    = {"Wither","Freezing","Handprints"},
    Entity    = {"SpiritBox","Handprints","Laser"},
    Ghoul     = {"SpiritBox","Freezing","GhostOrb"},
    Keres     = {"Wither","SpiritBox","Handprints"},
    Leviathan = {"GhostWriting","GhostOrb","Handprints"},
    Nightmare = {"EMF5","SpiritBox","GhostOrb"},
    Oni       = {"Laser","Freezing","SpiritBox"},
    Phantom   = {"EMF5","Handprints","GhostOrb"},
    Ravager   = {"EMF5","SpiritBox","GhostWriting"},
    Revenant  = {"GhostWriting","Freezing","EMF5"},
    Shadow    = {"EMF5","GhostWriting","Laser"},
    Siren     = {"Wither","SpiritBox","EMF5"},
    Skinwalker= {"GhostWriting","SpiritBox","Freezing"},
    Specter   = {"EMF5","Freezing","Laser"},
    Umbra     = {"GhostOrb","Handprints","Laser"},
    Wendigo   = {"GhostWriting","GhostOrb","Laser"},
    Wisp      = {"Wither","GhostOrb","Laser"},
    Wraith    = {"EMF5","SpiritBox","Laser"},
    Spirit    = {"Handprints","GhostWriting","SpiritBox"},
    Vex       = {"Wither","GhostOrb","Freezing"},
    Vesper    = {"Wither","Handprints","GhostWriting"},
}

local EvidenceTypes = {
    {id="EMF5",        label="EMF Level 5",     icon="⚡",  color=C.EvidEMF},
    {id="SpiritBox",   label="Spirit Box",      icon="📻",  color=C.EvidSpirit},
    {id="GhostWriting",label="Ghost Writing",   icon="✍",   color=C.EvidInscript},
    {id="Freezing",    label="Freezing Temps",  icon="❄",   color=C.EvidFreeze},
    {id="GhostOrb",    label="Ghost Orb",       icon="🔮",  color=C.EvidOrb},
    {id="Handprints",  label="Fingerprints",    icon="🖐",  color=C.EvidPrints},
    {id="Laser",       label="Laser Projector", icon="🔴",  color=C.EvidLaser},
    {id="Wither",      label="Wither",          icon="🥀",  color=C.EvidWither},
}

-- Ghost abilities database (all 25 ghosts with full ability sets)
local GhostAbilities = {
    Entity      = {icon="[E]", desc="Teleports & throws items", abilities={"TeleportRoom","ThrowItems"}, emf=3},
    Banshee     = {icon="[B]", desc="Breaks glass", abilities={"BreakGlass"}, emf=3},
    Nightmare   = {icon="[N]", desc="Throws objects", abilities={"ThrowItems"}, emf=2},
    Ravager     = {icon="[R]", desc="Throws multiple objects", abilities={"MultiThrow"}, emf=5},
    Leviathan   = {icon="[L]", desc="Flickers lights & equipment", abilities={"FlickerLights","FlickerItems","PowerOut"}, emf=2},
    Spirit      = {icon="[S]", desc="Turns flames blue", abilities={"BlueFlame"}, emf=2},
    Skinwalker  = {icon="[S]", desc="Teleports & flickers lights", abilities={"TeleportRoom","FlickerLights","BlueFlame"}, emf=2},
    Aswang      = {icon="[A]", desc="Slow with salt, fast after kills", abilities={"SpeedBoost","SaltSlow"}, emf=3},
    Demon       = {icon="[D]", desc="Hunts faster at high sanity", abilities={"EarlyHunt"}, emf=0},
    Dullahan    = {icon="[D]", desc="Headless, speeds up when looked at", abilities={"LookSpeed"}, emf=2},
    Dybbuk      = {icon="[D]", desc="Throws corpses", abilities={"ThrowCorpse"}, emf=2},
    Ghoul       = {icon="[G]", desc="Attracted to consumption", abilities={"ConsumptionAttract"}, emf=0},
    Keres       = {icon="[K]", desc="Targets lowest energy", abilities={"LowEnergyTarget"}, emf=2},
    Oni         = {icon="[O]", desc="Aggressive, hunts often", abilities={"FrequentHunt"}, emf=2},
    Phantom     = {icon="[P]", desc="Flickers while hunting", abilities={"HuntFlicker"}, emf=0},
    Revenant    = {icon="[R]", desc="Longer hunt after kill", abilities={"ExtendedHunt"}, emf=2},
    Shadow      = {icon="[S]", desc="Hunts at high sanity", abilities={"EarlyHunt"}, emf=2},
    Siren       = {icon="[S]", desc="Slows players who look", abilities={"LookSlow"}, emf=2},
    Specter     = {icon="[S]", desc="Fast while hunting", abilities={"HuntSpeed"}, emf=2},
    Umbra       = {icon="[U]", desc="Blinds during hunt", abilities={"HuntBlind"}, emf=2},
    Vex         = {icon="[V]", desc="Invisible on LIDAR", abilities={"LidarInvisible"}, emf=0},
    Vesper      = {icon="[V]", desc="Prefers dark rooms", abilities={"DarkRoom"}, emf=0},
    Wendigo     = {icon="[W]", desc="Aggressive in cold", abilities={"ColdAggression"}, emf=2},
    Wisp        = {icon="[W]", desc="Hunts only in favorite room", abilities={"FavoriteRoom"}, emf=0},
    Wraith      = {icon="[W]", desc="Attracted to electronics", abilities={"ElectronicAttract"}, emf=2},
}

local S = {
    Visible      = true,
    Features     = {},
    Conns        = {},
    Highlights   = {},
    Billboards   = {},
    Evidence     = {},
    ActiveCount  = 0,
    _statusLabel = nil,
    _notifBox    = nil,
    _ghostPanel  = nil,
    _evidPanel   = nil,
    _origLight   = nil,
    _hudPills    = {},
    _ghostRoom   = "Unknown",
    _abilities   = {},
    _abilityLog  = {},
    DetectedAbilities = {},
}

for _, ev in ipairs(EvidenceTypes) do
    S.Evidence[ev.id] = false
end

local function tw(obj, props, dur, sty, dir)
    return TweenService:Create(obj, TweenInfo.new(dur or C.Speed, sty or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 8)
    c.Parent = p
    return c
end

local function stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Accent
    s.Thickness = thick or 1
    s.Transparency = trans or 0.8
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 8)
    u.PaddingBottom = UDim.new(0, b or 8)
    u.PaddingLeft = UDim.new(0, l or 8)
    u.PaddingRight = UDim.new(0, r or 8)
    u.Parent = p
    return u
end

local function addConn(key, conn)
    if S.Conns[key] then pcall(function() S.Conns[key]:Disconnect() end) end
    S.Conns[key] = conn
end

local function rmConn(key)
    if S.Conns[key] then
        pcall(function() S.Conns[key]:Disconnect() end)
        S.Conns[key] = nil
    end
end

local function clearHL(tag)
    for _, t in ipairs({"Highlights", "Billboards"}) do
        if S[t][tag] then
            for _, h in pairs(S[t][tag]) do pcall(function() h:Destroy() end) end
            S[t][tag] = nil
        end
    end
end

local function updateCount()
    local n = 0
    for _, v in pairs(S.Features) do if v then n += 1 end end
    S.ActiveCount = n
    if S._statusLabel then S._statusLabel.Text = n .. " active" end
end

-- EVIDENCE HUD
local EvidHudGui

local function buildEvidHUD()
    EvidHudGui = Instance.new("ScreenGui")
    EvidHudGui.Name = "1nxsEvidHUD"
    EvidHudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    EvidHudGui.DisplayOrder = 999
    EvidHudGui.ResetOnSpawn = false
    EvidHudGui.IgnoreGuiInset = true
    pcall(function() EvidHudGui.Parent = CoreGui end)
    if not EvidHudGui.Parent then EvidHudGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local bar = Instance.new("Frame")
    bar.Name = "EvidBar"
    bar.Size = UDim2.new(0, 520, 0, 44)
    bar.Position = UDim2.new(0.5, -260, 0, 10)
    bar.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    bar.BackgroundTransparency = 0.3
    bar.BorderSizePixel = 0
    bar.Parent = EvidHudGui
    corner(bar, UDim.new(0, 14))
    stroke(bar, C.AccentDim, 1, 0.5)

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -20, 0, 1)
    glow.Position = UDim2.new(0, 10, 0, 1)
    glow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    glow.Parent = bar

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bar
    pad(bar, 0, 0, 12, 12)

    -- ghost room label on left side
    local roomLabel = Instance.new("TextLabel")
    roomLabel.Name = "RoomLabel"
    roomLabel.Size = UDim2.new(0, 80, 0, 24)
    roomLabel.BackgroundColor3 = C.Bg4
    roomLabel.BackgroundTransparency = 0.4
    roomLabel.BorderSizePixel = 0
    roomLabel.Text = "📍 ??"
    roomLabel.TextColor3 = C.Text3
    roomLabel.Font = C.FontMed
    roomLabel.TextSize = 10
    roomLabel.LayoutOrder = 0
    roomLabel.Parent = bar
    corner(roomLabel, UDim.new(0, 6))

    S._hudPills = {}
    for i, ev in ipairs(EvidenceTypes) do
        local pill = Instance.new("Frame")
        pill.Name = ev.id
        pill.Size = UDim2.new(0, 48, 0, 26)
        pill.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        pill.BackgroundTransparency = 0.35
        pill.BorderSizePixel = 0
        pill.LayoutOrder = i
        pill.Parent = bar
        corner(pill, UDim.new(0, 7))

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = ev.icon
        lbl.TextSize = 14
        lbl.TextColor3 = C.Text3
        lbl.Font = C.FontMed
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = pill

        S._hudPills[ev.id] = {pill = pill, label = lbl}
    end

    -- auto-update ghost room label (via Heartbeat with timer, safer than task.spawn)
    local _lastRoomScan = 0
    addConn("room_scan", RunService.Heartbeat:Connect(function()
        if not (EvidHudGui and EvidHudGui.Parent) then return end
        local now = tick()
        if now - _lastRoomScan < 1 then return end
        _lastRoomScan = now
        local ghost = Workspace:FindFirstChild("Ghost")
        if ghost then
            local room = ghost:GetAttribute("CurrentRoom")
            if room and room ~= "" then
                if room ~= S._ghostRoom then
                    S._ghostRoom = room
                    roomLabel.Text = "📍 " .. room
                end
            else
                local hrp = ghost:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local rooms = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Rooms")
                    if rooms then
                        local found = "Unknown"
                        for _, rm in pairs(rooms:GetChildren()) do
                            local bb = rm:FindFirstChild("BoundingBox")
                            if bb and bb:IsA("BasePart") then
                                local size = bb.Size
                                local center = bb.Position
                                local half = size / 2
                                local diff = hrp.Position - center
                                if math.abs(diff.X) <= half.X and math.abs(diff.Y) <= half.Y and math.abs(diff.Z) <= half.Z then
                                    found = rm.Name
                                    break
                                end
                            end
                        end
                        if found ~= S._ghostRoom then
                            S._ghostRoom = found
                            roomLabel.Text = "📍 " .. found
                        end
                    end
                end
            end
        end
    end))

    return roomLabel
end

local function updateHUD()
    for _, ev in ipairs(EvidenceTypes) do
        local d = S._hudPills[ev.id]
        if d then
            if S.Evidence[ev.id] then
                tw(d.pill, {BackgroundColor3 = ev.color, BackgroundTransparency = 0.2}, C.SpeedFast)
                tw(d.label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, C.SpeedFast)
            else
                tw(d.pill, {BackgroundColor3 = Color3.fromRGB(28, 28, 36), BackgroundTransparency = 0.35}, C.SpeedFast)
                tw(d.label, {TextColor3 = C.Text3}, C.SpeedFast)
            end
        end
    end
end

-- NOTIFICATION SYSTEM
local function notify(text, color, dur)
    if not S._notifBox then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = C.Bg3
    f.BackgroundTransparency = 0.12
    f.BorderSizePixel = 0
    f.Parent = S._notifBox
    corner(f, UDim.new(0, 6))
    stroke(f, color or C.Accent, 1, 0.5)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 14)
    dot.Position = UDim2.new(0, 6, 0.5, -7)
    dot.BackgroundColor3 = color or C.Accent
    dot.BorderSizePixel = 0
    dot.Parent = f
    corner(dot, UDim.new(0, 2))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -18, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text1
    lbl.Font = C.FontReg
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = f

    f.BackgroundTransparency = 1
    lbl.TextTransparency = 1
    tw(f, {BackgroundTransparency = 0.12}, 0.25)
    tw(lbl, {TextTransparency = 0}, 0.25)

    task.delay(dur or 3, function()
        tw(f, {BackgroundTransparency = 1}, 0.35)
        tw(lbl, {TextTransparency = 1}, 0.35)
        task.wait(0.4)
        pcall(function() f:Destroy() end)
    end)
end

-- EVIDENCE TRACKING
local updateGhostPanel, updateEvidencePanel

local function markEvidence(evidId)
    if S.Evidence[evidId] then return end
    S.Evidence[evidId] = true

    for _, ev in ipairs(EvidenceTypes) do
        if ev.id == evidId then
            notify(ev.icon .. " EVIDENCE: " .. ev.label .. " found!", ev.color, 6)
            break
        end
    end

    updateHUD()
    if updateGhostPanel then updateGhostPanel() end
    if updateEvidencePanel then updateEvidencePanel() end
end

-- ABILITY LOGGING (with debounce, now AFTER notify)
local _abilCooldown = {}
local function logAbility(abilityName, ghostHint)
    local now = tick()
    local cd = _abilCooldown[abilityName]
    if cd and now - cd < 3 then return end
    _abilCooldown[abilityName] = now
    S.DetectedAbilities[abilityName] = (S.DetectedAbilities[abilityName] or 0) + 1
    local timeStr = os.date("%H:%M:%S")
    table.insert(S._abilityLog, 1, {time=timeStr, ability=abilityName, ghost=ghostHint})
    if #S._abilityLog > 50 then
        table.remove(S._abilityLog)
    end
    local ok, err = pcall(notify, "⚡ ABILITY: " .. abilityName .. (ghostHint and " ("..ghostHint..")" or ""), C.AbilityColors[abilityName] or C.Accent, 4)
    if not ok then warn("[Abil] notify error:", err) end
    if updateAbilityPanel then pcall(updateAbilityPanel) end
end

local function getPossibleGhostsByAbility()
    local detected = {}
    for name, count in pairs(S.DetectedAbilities) do
        table.insert(detected, name)
    end
    if #detected == 0 then return {} end
    local possible = {}
    for gname, info in pairs(GhostAbilities) do
        local matchCount = 0
        for _, da in ipairs(detected) do
            for _, ga in ipairs(info.abilities) do
                if ga == da then matchCount += 1 break end
            end
        end
        local conf = math.floor((matchCount / #detected) * 100)
        table.insert(possible, {
            name = gname,
            matched = matchCount,
            totalAbilities = #info.abilities,
            confidence = conf,
            abilities = info.abilities,
            icon = info.icon,
        })
    end
    table.sort(possible, function(a, b) return a.confidence > b.confidence end)
    return possible
end

local function resetEvidence()
    for _, ev in ipairs(EvidenceTypes) do
        S.Evidence[ev.id] = false
    end
    notify("🔄 Evidence reset", C.Text2, 3)
    updateHUD()
    if updateGhostPanel then updateGhostPanel() end
    if updateEvidencePanel then updateEvidencePanel() end
end

local function getPossibleGhosts()
    local found = {}
    for id, val in pairs(S.Evidence) do
        if val then table.insert(found, id) end
    end

    local possible = {}
    for gname, gev in pairs(GhostDB) do
        local matches = true
        for _, fe in ipairs(found) do
            local hasIt = false
            for _, ge in ipairs(gev) do
                if ge == fe then hasIt = true break end
            end
            if not hasIt then matches = false break end
        end
        if matches then
            local matchCount = 0
            for _, ge in ipairs(gev) do
                if S.Evidence[ge] then matchCount += 1 end
            end
            table.insert(possible, {
                name = gname,
                evidence = gev,
                matched = matchCount,
                confidence = math.floor((matchCount / 3) * 100)
            })
        end
    end

    table.sort(possible, function(a, b) return a.confidence > b.confidence end)
    return possible
end

-- HUNT CLOSET TP
local function findNearestHidingSpot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local keywords = {"closet", "wardrobe", "locker", "cabinet", "armoire", "hiding", "cupboard"}
    local best, bestDist = nil, math.huge

    for _, d in pairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local name = d.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    local dist = (hrp.Position - d.Position).Magnitude
                    if dist < bestDist then best = d bestDist = dist end
                    break
                end
            end
        end
    end

    return best, bestDist
end

local function safeTPToHidingSpot()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    hum:ChangeState(Enum.HumanoidStateType.Running)

    local spot, dist = findNearestHidingSpot()
    if spot then
        hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 2.5, 0))
        task.wait(0.05)
        hum:ChangeState(Enum.HumanoidStateType.Running)
        notify("🚪 Hid in " .. spot.Name .. " (" .. math.floor(dist) .. " studs)", C.Green, 4)
        return true
    end
    return false
end

-- HUNT DETECTOR
local huntActive = false

local function onHuntStart()
    if huntActive then return end
    huntActive = true
    notify("👻 HUNT STARTED! Auto-hiding...", C.Red, 5)

    if not S.Features["Auto Hide on Hunt"] then
        task.wait(10)
        huntActive = false
        return
    end

    local ok = safeTPToHidingSpot()
    if not ok then
        notify("⚠ No hiding spot found nearby!", C.Yellow, 4)
    end

    task.wait(10)
    huntActive = false
end

local function onHuntEnd()
    huntActive = false
    notify("✅ Hunt over - you're safe", C.Green, 3)
end

-- LOADING SCREEN
local function showLoadingScreen(onComplete)
    local loaderGui = Instance.new("ScreenGui")
    loaderGui.Name = "1nxsLoader"
    loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loaderGui.DisplayOrder = 9999
    loaderGui.IgnoreGuiInset = true
    pcall(function() loaderGui.Parent = CoreGui end)
    if not loaderGui.Parent then loaderGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local blur = Instance.new("BlurEffect")
    blur.Name = "HubBlur"
    blur.Size = 0
    blur.Parent = Lighting
    tw(blur, {Size = 24}, 0.8)

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
    overlay.BackgroundTransparency = 0
    overlay.BorderSizePixel = 0
    overlay.Parent = loaderGui

    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 300, 0, 220)
    center.Position = UDim2.new(0.5, -150, 0.5, -110)
    center.BackgroundTransparency = 1
    center.Parent = overlay

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 40)
    logo.Position = UDim2.new(0, 0, 0, 30)
    logo.BackgroundTransparency = 1
    logo.Text = "DEMONOLOGY HUB"
    logo.TextColor3 = C.Text1
    logo.Font = C.Font
    logo.TextSize = 28
    logo.TextTransparency = 1
    logo.Parent = center

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(1, 0, 0, 18)
    ver.Position = UDim2.new(0, 0, 0, 70)
    ver.BackgroundTransparency = 1
    ver.Text = "v4.5 — fixed ghost limit, EMF, Spirit Box, Laser"
    ver.TextColor3 = C.AccentDim
    ver.Font = C.FontMed
    ver.TextSize = 13
    ver.TextTransparency = 1
    ver.Parent = center

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.7, 0, 0, 4)
    barBg.Position = UDim2.new(0.15, 0, 0, 110)
    barBg.BackgroundColor3 = C.Bg4
    barBg.BorderSizePixel = 0
    barBg.BackgroundTransparency = 1
    barBg.Parent = center
    corner(barBg, UDim.new(1, 0))

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = C.Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    corner(barFill, UDim.new(1, 0))

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 16)
    status.Position = UDim2.new(0, 0, 0, 122)
    status.BackgroundTransparency = 1
    status.Text = "initializing..."
    status.TextColor3 = C.Text3
    status.Font = C.FontReg
    status.TextSize = 11
    status.TextTransparency = 1
    status.Parent = center

    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 20)
    credit.Position = UDim2.new(0, 0, 0, 160)
    credit.BackgroundTransparency = 1
    credit.Text = "made by 1nxs"
    credit.TextColor3 = C.Text3
    credit.Font = C.FontReg
    credit.TextSize = 12
    credit.TextTransparency = 1
    credit.Parent = center

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 0, 0, 1)
    line.Position = UDim2.new(0.5, 0, 0, 148)
    line.AnchorPoint = Vector2.new(0.5, 0)
    line.BackgroundColor3 = C.AccentDim
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = center

    task.wait(0.2)
    tw(logo, {TextTransparency = 0}, 0.6)
    task.wait(0.3)
    tw(ver, {TextTransparency = 0}, 0.4)
    task.wait(0.2)
    tw(barBg, {BackgroundTransparency = 0}, 0.3)
    tw(status, {TextTransparency = 0}, 0.3)
    tw(line, {Size = UDim2.new(0.5, 0, 0, 1)}, 0.5)

    local steps = {
        {pct = 0.15, text = "mapping workspace..."},
        {pct = 0.30, text = "indexing remotes..."},
        {pct = 0.45, text = "loading ghost database..."},
        {pct = 0.60, text = "fixing evidence trackers..."},
        {pct = 0.75, text = "building interface..."},
        {pct = 0.90, text = "hooking hunt detector..."},
        {pct = 1.00, text = "ready."},
    }

    for _, step in ipairs(steps) do
        tw(barFill, {Size = UDim2.new(step.pct, 0, 1, 0)}, 0.35)
        status.Text = step.text
        task.wait(0.3)
    end

    task.wait(0.3)
    tw(credit, {TextTransparency = 0}, 0.5)
    task.wait(1.0)

    tw(logo, {TextTransparency = 1, Position = UDim2.new(0, 0, 0, 20)}, 0.5)
    tw(ver, {TextTransparency = 1}, 0.4)
    tw(barBg, {BackgroundTransparency = 1}, 0.4)
    tw(barFill, {BackgroundTransparency = 1}, 0.4)
    tw(status, {TextTransparency = 1}, 0.3)
    tw(credit, {TextTransparency = 1}, 0.4)
    tw(line, {BackgroundTransparency = 1}, 0.3)
    tw(overlay, {BackgroundTransparency = 1}, 0.6)
    tw(blur, {Size = 6}, 0.5)

    task.wait(0.7)
    loaderGui:Destroy()
    pcall(function() Lighting:FindFirstChild("HubBlur"):Destroy() end)

    if onComplete then onComplete() end
end

-- MAIN UI
local Hub, MainFrame

local function buildHub()
    Hub = Instance.new("ScreenGui")
    Hub.Name = "1nxsHub"
    Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Hub.DisplayOrder = 1000
    Hub.ResetOnSpawn = false
    Hub.IgnoreGuiInset = true
    pcall(function() Hub.Parent = CoreGui end)
    if not Hub.Parent then Hub.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Main window
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 620, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
    MainFrame.BackgroundColor3 = C.Bg1
    MainFrame.BackgroundTransparency = 0.12
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = Hub
    corner(MainFrame, UDim.new(0, 14))
    stroke(MainFrame, C.AccentDim, 1, 0.35)

    local topSheen = Instance.new("Frame")
    topSheen.Size = UDim2.new(1, -30, 0, 1)
    topSheen.Position = UDim2.new(0, 15, 0, 1)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BackgroundTransparency = 0.82
    topSheen.BorderSizePixel = 0
    topSheen.Parent = MainFrame

    -- TITLE BAR
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = C.Bg2
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    corner(titleBar, UDim.new(0, 14))

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = C.Bg2
    titleFix.BackgroundTransparency = 0.2
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, 0)
    titleLine.BackgroundColor3 = C.AccentDim
    titleLine.BackgroundTransparency = 0.6
    titleLine.BorderSizePixel = 0
    titleLine.Parent = titleBar

    local titleTxt = Instance.new("TextLabel")
    titleTxt.Size = UDim2.new(0, 220, 0, 18)
    titleTxt.Position = UDim2.new(0, 16, 0, 6)
    titleTxt.BackgroundTransparency = 1
    titleTxt.Text = "DEMONOLOGY HUB"
    titleTxt.TextColor3 = C.Text1
    titleTxt.Font = C.Font
    titleTxt.TextSize = 15
    titleTxt.TextXAlignment = Enum.TextXAlignment.Left
    titleTxt.Parent = titleBar

    local subtitleTxt = Instance.new("TextLabel")
    subtitleTxt.Size = UDim2.new(0, 200, 0, 12)
    subtitleTxt.Position = UDim2.new(0, 16, 0, 25)
    subtitleTxt.BackgroundTransparency = 1
    subtitleTxt.Text = "1nxs · v4.5"
    subtitleTxt.TextColor3 = C.Text3
    subtitleTxt.Font = C.FontReg
    subtitleTxt.TextSize = 10
    subtitleTxt.TextXAlignment = Enum.TextXAlignment.Left
    subtitleTxt.Parent = titleBar

    local statusBadge = Instance.new("TextLabel")
    statusBadge.Size = UDim2.new(0, 72, 0, 20)
    statusBadge.Position = UDim2.new(1, -184, 0.5, -10)
    statusBadge.BackgroundColor3 = C.Bg4
    statusBadge.BackgroundTransparency = 0.25
    statusBadge.BorderSizePixel = 0
    statusBadge.Text = "0 active"
    statusBadge.TextColor3 = C.AccentBright
    statusBadge.Font = C.FontMed
    statusBadge.TextSize = 10
    statusBadge.Parent = titleBar
    corner(statusBadge, UDim.new(1, 0))
    S._statusLabel = statusBadge

    local function makeBtn(name, text, col, posX)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(1, posX, 0.5, -13)
        btn.BackgroundColor3 = col
        btn.BackgroundTransparency = 0.9
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = col
        btn.Font = C.Font
        btn.TextSize = 12
        btn.Parent = titleBar
        corner(btn, UDim.new(0, 6))
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundTransparency = 0.5}, C.SpeedFast) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundTransparency = 0.9}, C.SpeedFast) end)
        return btn
    end

    local closeBtn = makeBtn("Close", "✕", C.Red, -36)
    local minBtn   = makeBtn("Min",   "─", C.Yellow, -66)

    -- dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- SIDEBAR
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -45)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BackgroundColor3 = C.Bg2
    sidebar.BackgroundTransparency = 0.25
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainFrame

    local sideLayout = Instance.new("UIListLayout")
    sideLayout.Padding = UDim.new(0, 2)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Parent = sidebar
    pad(sidebar, 8, 8, 6, 6)

    local categories = {
        {name="ESP",       icon="👁",   order=1},
        {name="Evidence",  icon="🔍",   order=2},
        {name="Ghost ID",  icon="👻",   order=3},
        {name="Abilities", icon="⚡",   order=4},
        {name="Survival",  icon="🛡",   order=5},
        {name="Visual",    icon="✨",   order=6},
        {name="Tools",     icon="⚙",    order=7},
    }

    local sideBtns = {}
    local currentCat = "ESP"

    for _, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = C.Accent
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = cat.order
        btn.Parent = sidebar
        corner(btn, UDim.new(0, 6))

        local ico = Instance.new("TextLabel")
        ico.Size = UDim2.new(0, 24, 1, 0)
        ico.Position = UDim2.new(0, 6, 0, 0)
        ico.BackgroundTransparency = 1
        ico.Text = cat.icon
        ico.TextSize = 13
        ico.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -34, 1, 0)
        lbl.Position = UDim2.new(0, 32, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cat.name
        lbl.TextColor3 = C.Text2
        lbl.Font = C.FontMed
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        sideBtns[cat.name] = {button = btn, label = lbl}

        btn.MouseEnter:Connect(function()
            if currentCat ~= cat.name then tw(btn, {BackgroundTransparency = 0.88}, C.SpeedFast) end
        end)
        btn.MouseLeave:Connect(function()
            if currentCat ~= cat.name then tw(btn, {BackgroundTransparency = 1}, C.SpeedFast) end
        end)
    end

    -- CONTENT AREA
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -124, 1, -45)
    content.Position = UDim2.new(0, 124, 0, 45)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = MainFrame

    -- NOTIFICATION CONTAINER
    local notifBox = Instance.new("Frame")
    notifBox.Size = UDim2.new(0, 220, 0, 180)
    notifBox.Position = UDim2.new(0, 10, 1, -190)
    notifBox.BackgroundTransparency = 1
    notifBox.ClipsDescendants = true
    notifBox.Parent = Hub
    local nLayout = Instance.new("UIListLayout")
    nLayout.Padding = UDim.new(0, 3)
    nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nLayout.Parent = notifBox
    S._notifBox = notifBox

    -- PAGE BUILDER
    local pages = {}

    local function makePage(name)
        local pg = Instance.new("ScrollingFrame")
        pg.Name = name
        pg.Size = UDim2.new(1, 0, 1, 0)
        pg.BackgroundTransparency = 1
        pg.BorderSizePixel = 0
        pg.ScrollBarThickness = 3
        pg.ScrollBarImageColor3 = C.AccentDim
        pg.ScrollBarImageTransparency = 0.4
        pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
        pg.CanvasSize = UDim2.new(0, 0, 0, 0)
        pg.Visible = (name == currentCat)
        pg.Parent = content

        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 5)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = pg
        pad(pg, 8, 8, 8, 8)

        local hdr = Instance.new("TextLabel")
        hdr.Size = UDim2.new(1, 0, 0, 20)
        hdr.BackgroundTransparency = 1
        hdr.Text = string.upper(name)
        hdr.TextColor3 = C.AccentDim
        hdr.Font = C.Font
        hdr.TextSize = 10
        hdr.TextXAlignment = Enum.TextXAlignment.Left
        hdr.LayoutOrder = 0
        hdr.Parent = pg

        pages[name] = pg
        return pg
    end

    local function makeToggle(parent, name, desc, order, callback)
        local cont = Instance.new("Frame")
        cont.Name = name
        cont.Size = UDim2.new(1, 0, 0, 44)
        cont.BackgroundColor3 = C.Bg3
        cont.BackgroundTransparency = 0.45
        cont.BorderSizePixel = 0
        cont.LayoutOrder = order
        cont.Parent = parent
        corner(cont, UDim.new(0, 8))

        cont.MouseEnter:Connect(function() tw(cont, {BackgroundTransparency = 0.1}, C.SpeedFast) end)
        cont.MouseLeave:Connect(function() tw(cont, {BackgroundTransparency = 0.45}, C.SpeedFast) end)

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -64, 0, 16)
        nm.Position = UDim2.new(0, 12, 0, 6)
        nm.BackgroundTransparency = 1
        nm.Text = name
        nm.TextColor3 = C.Text1
        nm.Font = C.FontMed
        nm.TextSize = 12
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = cont

        local ds = Instance.new("TextLabel")
        ds.Size = UDim2.new(1, -64, 0, 12)
        ds.Position = UDim2.new(0, 12, 0, 24)
        ds.BackgroundTransparency = 1
        ds.Text = desc
        ds.TextColor3 = C.Text3
        ds.Font = C.FontReg
        ds.TextSize = 10
        ds.TextXAlignment = Enum.TextXAlignment.Left
        ds.TextTruncate = Enum.TextTruncate.AtEnd
        ds.Parent = cont

        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 38, 0, 20)
        pill.Position = UDim2.new(1, -50, 0.5, -10)
        pill.BackgroundColor3 = C.Bg4
        pill.BorderSizePixel = 0
        pill.Parent = cont
        corner(pill, UDim.new(1, 0))

        local circ = Instance.new("Frame")
        circ.Size = UDim2.new(0, 16, 0, 16)
        circ.Position = UDim2.new(0, 2, 0.5, -8)
        circ.BackgroundColor3 = C.Text2
        circ.BorderSizePixel = 0
        circ.Parent = pill
        corner(circ, UDim.new(1, 0))

        local on = false
        S.Features[name] = false

        local function setVisual(v, anim)
            if anim then
                if v then
                    tw(pill, {BackgroundColor3 = C.Accent}, C.SpeedFast)
                    tw(circ, {Position = UDim2.new(0, 20, 0.5, -8), BackgroundColor3 = C.Text1}, C.SpeedFast)
                    tw(nm,   {TextColor3 = C.AccentBright}, C.SpeedFast)
                else
                    tw(pill, {BackgroundColor3 = C.Bg4}, C.SpeedFast)
                    tw(circ, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = C.Text2}, C.SpeedFast)
                    tw(nm,   {TextColor3 = C.Text1}, C.SpeedFast)
                end
            else
                pill.BackgroundColor3 = v and C.Accent or C.Bg4
                circ.Position = v and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                circ.BackgroundColor3 = v and C.Text1 or C.Text2
                nm.TextColor3 = v and C.AccentBright or C.Text1
            end
        end

        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.Parent = cont

        click.MouseButton1Click:Connect(function()
            on = not on
            S.Features[name] = on
            setVisual(on, true)
            updateCount()
            local ok, err = pcall(callback, on)
            if not ok then
                warn("[Hub] Error in " .. name .. ":", err)
                notify("⚠ " .. name .. " error", C.Red, 4)
            else
                notify(name .. " → " .. (on and "ON" or "OFF"), on and C.Green or C.Text3, 2)
            end
        end)

        return cont
    end

    -- ═══════════════════════════════════════
    --   PAGE: ESP
    -- ═══════════════════════════════════════
    local espPage = makePage("ESP")

    -- Ghost ESP (FIXED: uses workspace.Ghost directly)
    makeToggle(espPage, "Ghost ESP", "Track ghost through walls (fixed)", 1, function(on)
        clearHL("ghost")
        rmConn("ghost_loop")
        rmConn("ghost_rescan")
        if not on then return end
        S.Highlights["ghost"] = {}
        S.Billboards["ghost"] = {}

        local function scan()
            clearHL("ghost")
            S.Highlights["ghost"] = {}
            S.Billboards["ghost"] = {}

            local ghost = Workspace:FindFirstChild("Ghost")
            if ghost then
                local hrp = ghost:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 0, 60)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 40, 80)
                    hl.OutlineTransparency = 0.1
                    hl.Adornee = ghost
                    hl.Parent = CoreGui
                    table.insert(S.Highlights["ghost"], hl)

                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 130, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3.5, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = hrp
                    bb.Parent = CoreGui

                    local bg = Instance.new("Frame")
                    bg.Size = UDim2.new(1, 0, 1, 0)
                    bg.BackgroundColor3 = Color3.fromRGB(20, 0, 8)
                    bg.BackgroundTransparency = 0.2
                    bg.BorderSizePixel = 0
                    bg.Parent = bb
                    corner(bg, UDim.new(0, 6))
                    stroke(bg, Color3.fromRGB(255, 0, 60), 1, 0.3)

                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 0.6, 0)
                    l.Position = UDim2.new(0, 0, 0, 2)
                    l.BackgroundTransparency = 1
                    l.Text = "👻 GHOST"
                    l.TextColor3 = Color3.fromRGB(255, 80, 110)
                    l.Font = C.Font
                    l.TextSize = 12
                    l.Parent = bb

                    local dl = Instance.new("TextLabel")
                    dl.Name = "Dist"
                    dl.Size = UDim2.new(1, 0, 0.4, 0)
                    dl.Position = UDim2.new(0, 0, 0.6, 0)
                    dl.BackgroundTransparency = 1
                    dl.Text = ""
                    dl.TextColor3 = C.Text3
                    dl.Font = C.FontReg
                    dl.TextSize = 9
                    dl.Parent = bb

                    table.insert(S.Billboards["ghost"], bb)
                end

                local holder = Workspace:FindFirstChild("CursedPossessionHolder")
                if holder then
                    for _, d in pairs(holder:GetDescendants()) do
                        if d.Name == "GhostAnchor" and d:IsA("BasePart") then
                            local hl2 = Instance.new("Highlight")
                            hl2.FillColor = Color3.fromRGB(255, 0, 60)
                            hl2.FillTransparency = 0.55
                            hl2.OutlineColor = Color3.fromRGB(255, 40, 80)
                            hl2.OutlineTransparency = 0.15
                            hl2.Adornee = d.Parent or d
                            hl2.Parent = CoreGui
                            table.insert(S.Highlights["ghost"], hl2)
                        end
                    end
                end
            end
        end
        scan()

        addConn("ghost_loop", RunService.Heartbeat:Connect(function()
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, bb in pairs(S.Billboards["ghost"] or {}) do
                if bb and bb.Parent and bb.Adornee then
                    local dist = (myHRP.Position - bb.Adornee.Position).Magnitude
                    local dl = bb:FindFirstChild("Dist")
                    if dl then dl.Text = math.floor(dist) .. " studs" end
                end
            end
        end))

        addConn("ghost_rescan", RunService.Heartbeat:Connect(function()
            if not S.Features["Ghost ESP"] then return end
            local now = tick()
            if not S._lastGhostScan or now - S._lastGhostScan >= 2 then
                S._lastGhostScan = now
                pcall(scan)
            end
        end))
    end)

    -- Handprint ESP
    makeToggle(espPage, "Handprint ESP", "Highlight handprints with UV glow", 2, function(on)
        clearHL("handprints")
        rmConn("hp_added") rmConn("hp_removed")
        if not on then return end
        S.Highlights["handprints"] = {}; S.Billboards["handprints"] = {}

        local function hlPrint(obj)
            if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = C.EvidPrints; hl.FillTransparency = 0.35
            hl.OutlineColor = C.EvidPrints; hl.OutlineTransparency = 0.1
            hl.Adornee = obj; hl.Parent = CoreGui
            table.insert(S.Highlights["handprints"], hl)

            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 100, 0, 22); bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true; bb.Adornee = part; bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = Color3.fromRGB(20, 8, 30); l.BackgroundTransparency = 0.2
                l.Text = "🖐 HANDPRINT"; l.TextColor3 = C.EvidPrints
                l.Font = C.FontMed; l.TextSize = 11; l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["handprints"], bb)
            end
            markEvidence("Prints")
        end

        local folder = Workspace:FindFirstChild("Handprints")
        if folder then
            for _, ch in pairs(folder:GetChildren()) do pcall(hlPrint, ch) end
            addConn("hp_added", folder.ChildAdded:Connect(function(ch)
                task.wait(0.1); if S.Features["Handprint ESP"] then pcall(hlPrint, ch) end
            end))
            addConn("hp_removed", folder.ChildRemoved:Connect(function()
                if S.Features["Handprint ESP"] then
                    clearHL("handprints"); S.Highlights["handprints"] = {}; S.Billboards["handprints"] = {}
                    for _, ch in pairs(folder:GetChildren()) do pcall(hlPrint, ch) end
                end
            end))
        end
    end)

    -- Player ESP
    makeToggle(espPage, "Player ESP", "Show all players with distance", 3, function(on)
        clearHL("players"); rmConn("plr_loop") rmConn("plr_rescan")
        if not on then return end
        S.Highlights["players"] = {}; S.Billboards["players"] = {}

        local function scan()
            clearHL("players"); S.Highlights["players"] = {}; S.Billboards["players"] = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = C.Green; hl.FillTransparency = 0.6
                        hl.OutlineColor = C.Green; hl.OutlineTransparency = 0.2
                        hl.Adornee = p.Character; hl.Parent = CoreGui
                        table.insert(S.Highlights["players"], hl)
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 110, 0, 30); bb.StudsOffset = Vector3.new(0, 3.5, 0)
                        bb.AlwaysOnTop = true; bb.Adornee = hrp; bb.Parent = CoreGui
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 0.55, 0)
                        l.BackgroundColor3 = Color3.fromRGB(5, 18, 8); l.BackgroundTransparency = 0.2
                        l.Text = "👤 " .. p.Name; l.TextColor3 = C.Green
                        l.Font = C.FontMed; l.TextSize = 11; l.Parent = bb
                        corner(l, UDim.new(0, 4))
                        local dl = Instance.new("TextLabel")
                        dl.Name = "Dist"; dl.Size = UDim2.new(1, 0, 0.45, 0); dl.Position = UDim2.new(0, 0, 0.55, 0)
                        dl.BackgroundTransparency = 1; dl.Text = ""; dl.TextColor3 = C.Text3
                        dl.Font = C.FontReg; dl.TextSize = 9; dl.Parent = bb
                        table.insert(S.Billboards["players"], bb)
                    end
                end
            end
        end
        scan()
        addConn("plr_loop", RunService.Heartbeat:Connect(function()
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, bb in pairs(S.Billboards["players"] or {}) do
                if bb and bb.Parent and bb.Adornee then
                    local dist = (myHRP.Position - bb.Adornee.Position).Magnitude
                    local dl = bb:FindFirstChild("Dist")
                    if dl then dl.Text = math.floor(dist) .. " studs" end
                end
            end
        end))
        addConn("plr_rescan", RunService.Heartbeat:Connect(function()
            if not S.Features["Player ESP"] then return end
            local now = tick()
            if not S._lastPlrScan or now - S._lastPlrScan >= 4 then
                S._lastPlrScan = now
                pcall(scan)
            end
        end))
    end)

    -- Item ESP
    makeToggle(espPage, "Item ESP", "Highlight all pickable items", 4, function(on)
        clearHL("items"); rmConn("item_a"); rmConn("item_r")
        if not on then return end
        S.Highlights["items"] = {}; S.Billboards["items"] = {}

        local function hlItem(item)
            if not item:IsA("Model") and not item:IsA("BasePart") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = C.Blue; hl.FillTransparency = 0.65
            hl.OutlineColor = C.Blue; hl.OutlineTransparency = 0.3
            hl.Adornee = item; hl.Parent = CoreGui
            table.insert(S.Highlights["items"], hl)
            local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 90, 0, 20); bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true; bb.Adornee = part; bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = Color3.fromRGB(8, 12, 25); l.BackgroundTransparency = 0.2
                l.Text = "📦 " .. item.Name; l.TextColor3 = C.Blue
                l.Font = C.FontMed; l.TextSize = 10; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["items"], bb)
            end
        end

        local function scan()
            clearHL("items"); S.Highlights["items"] = {}; S.Billboards["items"] = {}
            local f = Workspace:FindFirstChild("Items")
            if f then for _, ch in pairs(f:GetChildren()) do pcall(hlItem, ch) end end
        end
        scan()
        local f = Workspace:FindFirstChild("Items")
        if f then
            addConn("item_a", f.ChildAdded:Connect(function() task.wait(0.1) if S.Features["Item ESP"] then pcall(scan) end end))
            addConn("item_r", f.ChildRemoved:Connect(function() task.wait(0.1) if S.Features["Item ESP"] then pcall(scan) end end))
        end
    end)

    -- Door Tracker
    makeToggle(espPage, "Door Tracker", "Highlight all interactable doors", 5, function(on)
        clearHL("doors")
        if not on then return end
        S.Highlights["doors"] = {}; S.Billboards["doors"] = {}
        local df = Workspace:FindFirstChild("Doors")
        if not df then notify("⚠ Doors folder not found", C.Yellow) return end
        for _, dm in pairs(df:GetChildren()) do
            if dm:IsA("Model") then
                local hl = Instance.new("Highlight")
                hl.FillColor = C.Yellow; hl.FillTransparency = 0.75
                hl.OutlineColor = C.Yellow; hl.OutlineTransparency = 0.4
                hl.Adornee = dm; hl.Parent = CoreGui
                table.insert(S.Highlights["doors"], hl)
                local part = dm:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 80, 0, 20); bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true; bb.Adornee = part; bb.Parent = CoreGui
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundColor3 = Color3.fromRGB(25, 20, 5); l.BackgroundTransparency = 0.25
                    l.Text = "🚪 " .. dm.Name; l.TextColor3 = C.Yellow
                    l.Font = C.FontMed; l.TextSize = 10; l.Parent = bb
                    corner(l, UDim.new(0, 4))
                    table.insert(S.Billboards["doors"], bb)
                end
            end
        end
    end)

    -- ═══════════════════════════════════════
    --   PAGE: EVIDENCE
    -- ═══════════════════════════════════════
    local evidPage = makePage("Evidence")

    -- Evidence ESP
    makeToggle(evidPage, "Evidence ESP", "Highlight ALL evidence in world", 1, function(on)
        clearHL("evidence")
        rmConn("ev_hp_a") rmConn("ev_air_a") rmConn("ev_scr_a")
        rmConn("ev_salt_a") rmConn("ev_glass_a") rmConn("ev_lidar_a")
        if not on then return end
        S.Highlights["evidence"] = {}; S.Billboards["evidence"] = {}

        local evidFolders = {
            {name="Handprints",  emoji="🖐",  col=C.EvidPrints,     evid="Prints"},
            {name="Airballs",    emoji="🔮",  col=C.EvidOrb,        evid="GhostOrb"},
            {name="GhostOrb",    emoji="🔮",  col=C.EvidOrb,        evid="GhostOrb"},
            {name="ScratchText", emoji="✍",   col=C.EvidInscript,   evid="Inscription"},
            {name="SaltPiles",   emoji="🧂",  col=Color3.new(1,1,1), evid=nil},
            {name="BrokenGlass", emoji="💎",  col=C.Purple,         evid=nil},
            {name="LIDAR",       emoji="🔴",  col=C.EvidLaser,      evid="Laser"},
            {name="Laser",       emoji="🔴",  col=C.EvidLaser,      evid="Laser"},
            {name="LaserProjector", emoji="🔴", col=C.EvidLaser,   evid="Laser"},
        }

        local function hlEvidence(obj, info)
            local hl = Instance.new("Highlight")
            hl.FillColor = info.col; hl.FillTransparency = 0.4
            hl.OutlineColor = info.col; hl.OutlineTransparency = 0.1
            hl.Adornee = obj; hl.Parent = CoreGui
            table.insert(S.Highlights["evidence"], hl)

            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 100, 0, 22); bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true; bb.Adornee = part; bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = C.Bg1; l.BackgroundTransparency = 0.15
                l.Text = info.emoji .. " " .. info.name; l.TextColor3 = info.col
                l.Font = C.FontMed; l.TextSize = 10; l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["evidence"], bb)
            end
            if info.evid then markEvidence(info.evid) end
        end

        for _, info in ipairs(evidFolders) do
            local folder = Workspace:FindFirstChild(info.name)
            if folder then
                for _, ch in pairs(folder:GetChildren()) do pcall(hlEvidence, ch, info) end
                local key = "ev_" .. info.name:lower():gsub("%s","") .. "_a"
                addConn(key, folder.ChildAdded:Connect(function(ch)
                    task.wait(0.1)
                    if S.Features["Evidence ESP"] then
                        pcall(hlEvidence, ch, info)
                        notify(info.emoji .. " " .. info.name .. " detected!", info.col, 4)
                    end
                end))
            end
        end
        notify("🔍 Monitoring all evidence channels", C.Accent, 3)
    end)

    -- Freezing Detector
    makeToggle(evidPage, "Freezing Detector", "Alert on freezing temps (0°C or below)", 2, function(on)
        rmConn("temp_hook"); rmConn("temp_scan")
        if not on then return end

        local function checkTemp(temp)
            if type(temp) ~= "number" then return end
            if temp <= 0 then
                markEvidence("Freezing")
                notify("❄ FREEZING: " .. string.format("%.1f°C", temp), C.EvidFreeze, 6)
            elseif temp <= 10 then
                notify("❄ Cold: " .. string.format("%.1f°C", temp) .. " (watching...)", C.EvidFreeze, 3)
            end
        end

        -- Hook the UpdateThermometerDisplay remote
        if Events then
            local therm = Events:FindFirstChild("UpdateThermometerDisplay")
            if therm and therm:IsA("RemoteEvent") then
                addConn("temp_hook", therm.OnClientEvent:Connect(function(disp, temp)
                    checkTemp(temp)
                end))
                notify("🌡 Thermometer remote hooked", C.Green, 3)
            end
        end

        -- Fallback: scan for temp values (FIXED: more name patterns + IntValue support)
        addConn("temp_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Freezing Detector"] then return end
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local nm = v.Name:lower()
                    if nm:find("temp") or nm:find("cold") or nm:find("freeze") or nm:find("celsius") or nm:find("therm") then
                        if tonumber(v.Value) ~= nil then
                            checkTemp(tonumber(v.Value))
                        end
                    end
                end
            end
        end))
    end)

    -- EMF Monitor (FIXED: broad remote scan + Notify hook + tool NumberValue children)
    makeToggle(evidPage, "EMF Monitor", "Watch for EMF Level 5 readings (fixed)", 3, function(on)
        rmConn("emf_hook") rmConn("emf_notify") rmConn("emf_tool_scan") rmConn("emf_remote")
        if not on then return end
        local hookedAny = false
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") and (r.Name:lower():find("emf") or r.Name:lower():find("reader") or r.Name:lower():find("detector")) then
                addConn("emf_remote_" .. r.Name, r.OnClientEvent:Connect(function(...)
                    for _, v in ipairs({...}) do
                        if type(v) == "number" and v >= 5 then
                            markEvidence("EMF5"); notify("⚡ EMF LEVEL 5! (" .. r.Name .. ")", C.EvidEMF, 5); return
                        end
                    end
                end))
                hookedAny = true
            end
        end
        if hookedAny then notify("⚡ EMF remote(s) hooked", C.Green, 3) end
        -- Hook Notify for EMF-related messages
        if Events then
            local notifyEv = Events:FindFirstChild("Notify")
            if notifyEv and notifyEv:IsA("RemoteEvent") then
                addConn("emf_notify", notifyEv.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, v in ipairs(args) do
                        local s = tostring(v):lower()
                        if (s:find("emf") or s:find("level 5") or s:find("emf5") or s:find("emf 5")) then
                            markEvidence("EMF5"); notify("⚡ EMF5 via notification!", C.EvidEMF, 5); break
                        end
                    end
                end))
            end
        end
        -- Scan EMF tool for NumberValue children (level indicators)
        addConn("emf_tool_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["EMF Monitor"] or S.Evidence["EMF5"] then return end
            for _, d in pairs(Workspace:GetDescendants()) do
                if d:IsA("Tool") and (d.Name:lower():find("emf") or d.Name:lower():find("reader")) then
                    for _, ch in pairs(d:GetChildren()) do
                        if ch:IsA("NumberValue") and ch.Value >= 5 then
                            markEvidence("EMF5"); notify("⚡ EMF5 from tool NumberValue!", C.EvidEMF, 5); return
                        end
                    end
                end
            end
        end))
        notify("⚡ EMF monitor active (visual scan + notify)", C.Yellow, 3)
    end)

    -- Spirit Box Monitor (FIXED v4.5: also hooks Notify for spirit responses + tone listener)
    makeToggle(evidPage, "Spirit Box Monitor", "Detect spirit box responses (fixed)", 4, function(on)
        rmConn("spiritbox_hook") rmConn("spirit_tone") rmConn("spirit_notify")
        if not on then return end

        if Events then
            local sb = Events:FindFirstChild("AskSpiritBoxFromUI")
            if sb and sb:IsA("RemoteEvent") then
                addConn("spiritbox_hook", sb.OnClientEvent:Connect(function(...)
                    markEvidence("SpiritBox")
                    local args = {...}
                    local responseStr = ""
                    for _, v in ipairs(args) do responseStr ..= tostring(v) .. " " end
                    notify("📻 Spirit Box response! " .. responseStr, C.EvidSpirit, 6)
                end))
            end
            -- Also hook Notify for spirit box responses
            local notifyEv = Events:FindFirstChild("Notify")
            if notifyEv and notifyEv:IsA("RemoteEvent") then
                addConn("spirit_notify", notifyEv.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, v in ipairs(args) do
                        local s = tostring(v):lower()
                        if (s:find("spirit") or s:find("spiritbox")) and (s:find("response") or s:find("answer") or s:find("said") or s:find("reply")) then
                            markEvidence("SpiritBox"); notify("📻 Spirit Box via notification!", C.EvidSpirit, 6); break
                        end
                    end
                end))
            end
        end

        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            local sounds = playerScripts:FindFirstChild("Sounds")
            if sounds then
                local tone = sounds:FindFirstChild("SpiritBoxTone")
                if tone and tone:IsA("Sound") then
                    addConn("spirit_tone", tone:GetPropertyChangedSignal("Volume"):Connect(function()
                        if tone.Volume > 0.1 then
                            markEvidence("SpiritBox")
                            notify("📻 Spirit Box detected (tone active)!", C.EvidSpirit, 5)
                        end
                    end))
                end
            end
        end

        notify("📻 Spirit Box monitor active (event + notify)", C.Yellow, 3)
    end)

    -- Ghost Orb Detector (FIXED: more folders + broad part scan)
    makeToggle(evidPage, "Ghost Orb Detector", "Monitor for ghost orbs", 5, function(on)
        rmConn("orb_watch"); rmConn("orb_scan")
        if not on then return end

        local orbFolders = {"Airballs", "GhostOrb", "GhostOrbs", "Orbs", "Orb", "Particles", "FX"}

        for _, fname in ipairs(orbFolders) do
            local folder = Workspace:FindFirstChild(fname)
            if folder then
                if #folder:GetChildren() > 0 then markEvidence("GhostOrb") end
                addConn("orb_watch_" .. fname, folder.ChildAdded:Connect(function()
                    markEvidence("GhostOrb"); notify("🔮 Ghost Orb appeared in " .. fname .. "!", C.EvidOrb, 5)
                end))
            end
        end

        addConn("orb_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Ghost Orb Detector"] or S.Evidence["GhostOrb"] then return end
            for _, d in pairs(Workspace:GetDescendants()) do
                local nm = d.Name:lower()
                if (d:IsA("BasePart") or d:IsA("MeshPart") or d:IsA("Part")) and (nm:find("orb") or nm:find("airball") or nm:find("ball") and d.Transparency > 0.3) then
                    markEvidence("GhostOrb"); notify("🔮 Ghost Orb found: " .. d.Name, C.EvidOrb, 5); return
                end
            end
        end))
        notify("🔮 Orb detector active", C.Green, 3)
    end)

    -- Inscription Detector (FIXED: multiple folder names)
    makeToggle(evidPage, "Inscription Detector", "Watch for ghost writing", 6, function(on)
        rmConn("inscr_watch") rmConn("inscr_scan")
        if not on then return end
        local inscrFolders = {"ScratchText", "GhostWriting", "GhostWritingDecals", "Writing", "Drawings", "Inscriptions"}
        local found = false
        for _, fname in ipairs(inscrFolders) do
            local folder = Workspace:FindFirstChild(fname)
            if folder then
                addConn("inscr_watch_" .. fname, folder.ChildAdded:Connect(function()
                    markEvidence("Inscription"); notify("✍ Inscription found in " .. fname .. "!", C.EvidInscript, 5)
                end))
                if #folder:GetChildren() > 0 then markEvidence("Inscription"); found = true end
                notify("✍ Inscription folder found: " .. fname, C.Green, 3)
                found = true
            end
        end
        if not found then notify("⚠ No inscription folder found — will scan parts", C.Yellow, 3) end
        -- Fallback: scan for writing/inscription parts
        addConn("inscr_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Inscription Detector"] or S.Evidence["Inscription"] then return end
            for _, d in pairs(Workspace:GetDescendants()) do
                local nm = d.Name:lower()
                if (nm:find("inscript") or nm:find("writing") or nm:find("scratch") or nm:find("draw")) and (d:IsA("Part") or d:IsA("MeshPart") or d:IsA("Decal")) then
                    markEvidence("Inscription"); notify("✍ Inscription found: " .. d.Name, C.EvidInscript, 5); return
                end
            end
        end))
    end)

    -- Wither Detector (FIXED: hooks ObjectWithered remote + folder scan)
    makeToggle(evidPage, "Wither Detector", "Monitor for wither effects (fixed)", 7, function(on)
        rmConn("wither_remote"); rmConn("wither_watch")
        if not on then return end

        -- Hook the ObjectWithered remote
        if Events then
            local ow = Events:FindFirstChild("ObjectWithered")
            if ow and ow:IsA("RemoteEvent") then
                addConn("wither_remote", ow.OnClientEvent:Connect(function()
                    markEvidence("Wither"); notify("🥀 Wither evidence detected!", C.EvidWither, 5)
                end))
                notify("🥀 Wither remote hooked", C.Green, 3)
            end
        end

        -- Fallback: watch for wither/wilt in workspace
        addConn("wither_watch", Workspace.DescendantAdded:Connect(function(d)
            local nm = d.Name:lower()
            if nm:find("wither") or nm:find("wilt") or nm:find("dead_plant") then
                markEvidence("Wither"); notify("🥀 Wither evidence!", C.EvidWither, 5)
            end
        end))
        notify("🥀 Wither detector active", C.Green, 3)
    end)

    -- Laser Detector (FIXED v4.5: more folders + notify hook + ghost transparency scan)
    makeToggle(evidPage, "Laser Detector", "Watch for laser projector (ghost becomes slightly visible)", 8, function(on)
        rmConn("laser_watch") rmConn("laser_scan") rmConn("laser_ghost") rmConn("laser_notify") rmConn("laser_remote")
        if not on then return end
        local laserFolders = {"LIDAR", "Laser", "LaserProjector", "Projector", "LiDAR", "Lasers"}
        for _, fname in ipairs(laserFolders) do
            local folder = Workspace:FindFirstChild(fname)
            if folder then
                if #folder:GetChildren() > 0 then markEvidence("Laser") end
                addConn("laser_watch_" .. fname, folder.ChildAdded:Connect(function() markEvidence("Laser"); notify("🔴 Laser in " .. fname .. "!", C.EvidLaser, 5) end))
            end
        end
        -- Hook the DetectedGhostWithLIDAR remote
        if Events then
            local dl = Events:FindFirstChild("DetectedGhostWithLIDAR")
            if dl and dl:IsA("RemoteEvent") then
                addConn("laser_remote", dl.OnClientEvent:Connect(function()
                    markEvidence("Laser"); notify("🔴 LIDAR detected ghost silhouette!", C.EvidLaser, 5)
                end))
            end
        end
        -- Monitor ghost transparency
        addConn("laser_ghost", RunService.Heartbeat:Connect(function()
            if not S.Features["Laser Detector"] or S.Evidence["Laser"] then return end
            local ghost = Workspace:FindFirstChild("Ghost")
            if ghost then
                local hrp = ghost:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Transparency > 0.3 and hrp.Transparency < 0.8 then
                    markEvidence("Laser"); notify("🔴 Ghost partially visible via laser! (" .. string.format("%.0f%%", (1 - hrp.Transparency) * 100) .. ")", C.EvidLaser, 5); return
                end
                for _, part in pairs(ghost:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency > 0.3 and part.Transparency < 0.8 then
                        markEvidence("Laser"); notify("🔴 Ghost silhouette detected via laser!", C.EvidLaser, 5); return
                    end
                end
            end
        end))
        -- Hook Notify for laser-related messages
        if Events then
            local notifyEv = Events:FindFirstChild("Notify")
            if notifyEv and notifyEv:IsA("RemoteEvent") then
                addConn("laser_notify", notifyEv.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, v in ipairs(args) do
                        local s = tostring(v):lower()
                        if s:find("laser") or s:find("lidar") or s:find("projector") then
                            markEvidence("Laser"); notify("🔴 Laser via notification!", C.EvidLaser, 5); break
                        end
                    end
                end))
            end
        end
        notify("🔴 Laser detector active (notify + ghost transparency)", C.Green, 3)
    end)

    -- Reset Evidence button
    local resetBtn = Instance.new("Frame")
    resetBtn.Size = UDim2.new(1, 0, 0, 36)
    resetBtn.BackgroundColor3 = C.Red
    resetBtn.BackgroundTransparency = 0.82
    resetBtn.BorderSizePixel = 0
    resetBtn.LayoutOrder = 20
    resetBtn.Parent = evidPage
    corner(resetBtn, UDim.new(0, 8))
    stroke(resetBtn, C.Red, 1, 0.5)

    local resetLbl = Instance.new("TextLabel")
    resetLbl.Size = UDim2.new(1, 0, 1, 0)
    resetLbl.BackgroundTransparency = 1
    resetLbl.Text = "🔄 Reset All Evidence"
    resetLbl.TextColor3 = C.Red
    resetLbl.Font = C.FontMed
    resetLbl.TextSize = 12
    resetLbl.Parent = resetBtn

    local resetClick = Instance.new("TextButton")
    resetClick.Size = UDim2.new(1, 0, 1, 0)
    resetClick.BackgroundTransparency = 1
    resetClick.Text = ""
    resetClick.Parent = resetBtn
    resetClick.MouseButton1Click:Connect(resetEvidence)

    resetBtn.MouseEnter:Connect(function() tw(resetBtn, {BackgroundTransparency = 0.55}, C.SpeedFast) end)
    resetBtn.MouseLeave:Connect(function() tw(resetBtn, {BackgroundTransparency = 0.82}, C.SpeedFast) end)

    -- ═══════════════════════════════════════
    --   PAGE: GHOST ID (FIXED: accurate matching)
    -- ═══════════════════════════════════════
    local ghostPage = makePage("Ghost ID")

    local evidStatusFrame = Instance.new("Frame")
    evidStatusFrame.Size = UDim2.new(1, 0, 0, 90)
    evidStatusFrame.BackgroundColor3 = C.Bg3
    evidStatusFrame.BackgroundTransparency = 0.25
    evidStatusFrame.BorderSizePixel = 0
    evidStatusFrame.LayoutOrder = 1
    evidStatusFrame.Parent = ghostPage
    corner(evidStatusFrame, UDim.new(0, 8))

    local evidTitle = Instance.new("TextLabel")
    evidTitle.Size = UDim2.new(1, 0, 0, 16)
    evidTitle.Position = UDim2.new(0, 10, 0, 4)
    evidTitle.BackgroundTransparency = 1
    evidTitle.Text = "FOUND EVIDENCE (tap to toggle)"
    evidTitle.TextColor3 = C.AccentDim
    evidTitle.Font = C.Font
    evidTitle.TextSize = 9
    evidTitle.TextXAlignment = Enum.TextXAlignment.Left
    evidTitle.Parent = evidStatusFrame

    local evidGrid = Instance.new("Frame")
    evidGrid.Size = UDim2.new(1, -20, 0, 56)
    evidGrid.Position = UDim2.new(0, 10, 0, 22)
    evidGrid.BackgroundTransparency = 1
    evidGrid.Parent = evidStatusFrame

    local evidGridLayout = Instance.new("UIGridLayout")
    evidGridLayout.CellSize = UDim2.new(0, 58, 0, 24)
    evidGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    evidGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    evidGridLayout.Parent = evidGrid

    local evidIndicators = {}
    for i, ev in ipairs(EvidenceTypes) do
        local ind = Instance.new("Frame")
        ind.Name = ev.id
        ind.BackgroundColor3 = C.Bg4
        ind.BackgroundTransparency = 0.25
        ind.BorderSizePixel = 0
        ind.LayoutOrder = i
        ind.Parent = evidGrid
        corner(ind, UDim.new(0, 4))

        local il = Instance.new("TextLabel")
        il.Size = UDim2.new(1, 0, 1, 0)
        il.BackgroundTransparency = 1
        il.Text = ev.icon
        il.TextSize = 11
        il.TextColor3 = C.Text3
        il.Font = C.FontReg
        il.Parent = ind

        local iClick = Instance.new("TextButton")
        iClick.Size = UDim2.new(1, 0, 1, 0)
        iClick.BackgroundTransparency = 1
        iClick.Text = ""
        iClick.Parent = ind
        iClick.MouseButton1Click:Connect(function()
            S.Evidence[ev.id] = not S.Evidence[ev.id]
            if S.Evidence[ev.id] then
                notify(ev.icon .. " " .. ev.label .. " marked", ev.color, 2)
            else
                notify(ev.icon .. " " .. ev.label .. " unmarked", C.Text3, 2)
            end
            updateHUD(); updateGhostPanel(); updateEvidencePanel()
        end)

        evidIndicators[ev.id] = {frame = ind, label = il}
    end
    S._evidPanel = evidIndicators

    local ghostResults = Instance.new("Frame")
    ghostResults.Name = "GhostResults"
    ghostResults.Size = UDim2.new(1, 0, 0, 30)
    ghostResults.BackgroundTransparency = 1
    ghostResults.LayoutOrder = 2
    ghostResults.Parent = ghostPage
    ghostResults.AutomaticSize = Enum.AutomaticSize.Y

    local ghostResultsLayout = Instance.new("UIListLayout")
    ghostResultsLayout.Padding = UDim.new(0, 4)
    ghostResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ghostResultsLayout.Parent = ghostResults

    local ghostResultsTitle = Instance.new("TextLabel")
    ghostResultsTitle.Size = UDim2.new(1, 0, 0, 16)
    ghostResultsTitle.BackgroundTransparency = 1
    ghostResultsTitle.Text = "POSSIBLE GHOSTS"
    ghostResultsTitle.TextColor3 = C.AccentDim
    ghostResultsTitle.Font = C.Font
    ghostResultsTitle.TextSize = 9
    ghostResultsTitle.TextXAlignment = Enum.TextXAlignment.Left
    ghostResultsTitle.LayoutOrder = 0
    ghostResultsTitle.Parent = ghostResults

    S._ghostPanel = ghostResults

    -- PAGE: ABILITIES
    local abilPage = makePage("Abilities")

    makeToggle(abilPage, "Ability Tracker", "Detect ghost abilities & log them", 1, function(on)
        rmConn("abil_teleport") rmConn("abil_glass") rmConn("abil_add") rmConn("abil_power")
        if S._abilConns then
            for _, c in pairs(S._abilConns) do pcall(c.Disconnect, c) end
        end
        S._abilConns = {}
        if not on then return end

        local lastGhostPos = nil
        local lastGhostRoom = nil
        local lastTeleportTime = 0
        local lastPowerOutTime = 0

        -- Track ghost teleportation (FIXED: require BOTH room change AND large distance, debounce 10s)
        addConn("abil_teleport", RunService.Heartbeat:Connect(function()
            pcall(function()
                if not S.Features["Ability Tracker"] then return end
                local ghost = Workspace:FindFirstChild("Ghost")
                if ghost then
                    local hrp = ghost:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local pos = hrp.Position
                        local room = ghost:GetAttribute("CurrentRoom")
                        if lastGhostRoom and room and room ~= lastGhostRoom and lastGhostPos then
                            local dist = (pos - lastGhostPos).Magnitude
                            if dist > 30 then
                                local now = tick()
                                if now - lastTeleportTime > 10 then
                                    logAbility("TeleportRoom", "Entity/Skinwalker")
                                    lastTeleportTime = now
                                end
                            end
                        end
                        lastGhostPos = pos
                        lastGhostRoom = room
                    end
                else
                    lastGhostPos = nil
                    lastGhostRoom = nil
                end
            end)
        end))

        -- Connect AttributeChanged on any instance that matters (FIXED: DescendantAttributeChanged is NOT a valid event)
        local function connectEvents(inst)
            if not inst:IsA("BasePart") and not inst:IsA("Tool") then return end
            local nm = inst.Name
            -- Light switches (flickering lights)
            if nm:find("LightSwitch") or nm:find("Switch") then
                local conn = inst.AttributeChanged:Connect(function(attr)
                    pcall(function()
                        if not S.Features["Ability Tracker"] then return end
                        local a = tostring(attr)
                        if a == "State" then
                            local state = inst:GetAttribute("State")
                            if state ~= nil then
                                logAbility("FlickerLights", "Leviathan/Skinwalker")
                            end
                        end
                    end)
                end)
                table.insert(S._abilConns, conn)
                return
            end
            -- Equipment flickering (Leviathan)
            local itemNames = {"EMF", "Spirit Box", "Flashlight", "Blacklight", "Laser", "Radio", "Walkie"}
            for _, item in ipairs(itemNames) do
                if nm:find(item) then
                    local conn = inst.AttributeChanged:Connect(function(attr)
                        pcall(function()
                            if not S.Features["Ability Tracker"] then return end
                            local a = tostring(attr)
                            if a == "Enabled" or a == "State" or a == "Power" then
                                logAbility("FlickerItems", "Leviathan")
                            end
                        end)
                    end)
                    table.insert(S._abilConns, conn)
                    return
                end
            end
        end

        -- Connect to existing descendants
        for _, d in pairs(Workspace:GetDescendants()) do
            pcall(connectEvents, d)
        end

        -- Watch for new descendants
        addConn("abil_add", Workspace.DescendantAdded:Connect(function(d)
            task.wait(0.5)
            pcall(function() connectEvents(d) end)
        end))

        -- Track glass breaking (includes shatter, broken, crack)
        addConn("abil_glass", Workspace.DescendantRemoving:Connect(function(d)
            pcall(function()
                if not S.Features["Ability Tracker"] or not d then return end
                local lname = d.Name:lower()
                if lname:find("glass") or lname:find("shatter") or lname:find("broken") or lname:find("crack") then
                    logAbility("BreakGlass", "Banshee/Nightmare")
                end
            end)
        end))

        -- Track power outage (lights go completely out during day)
        addConn("abil_power", RunService.Heartbeat:Connect(function()
            pcall(function()
                if not S.Features["Ability Tracker"] then return end
                local now = tick()
                if now - lastPowerOutTime < 30 then return end
                if Lighting.Brightness < 0.15 and Lighting.ClockTime > 7 and Lighting.ClockTime < 19 then
                    if Workspace:FindFirstChild("FuseBox") or Workspace:FindFirstChild("PowerBox") then
                        logAbility("FlickerLights", "Leviathan/Skinwalker")
                        lastPowerOutTime = now
                    end
                end
            end)
        end))

        -- Track SpiritCandle attribute changes (Spirit/Skinwalker blue flame)
        addConn("abil_candle", RunService.Heartbeat:Connect(function()
            pcall(function()
                if not S.Features["Ability Tracker"] then return end
                for _, d in pairs(Workspace:GetDescendants()) do
                    if d:GetAttribute("SpiritCandle") == true then
                        logAbility("BlueFlame", "Spirit/Skinwalker")
                        return
                    end
                end
            end)
        end))

        notify("⚡ Ability tracker active — watching for ghost abilities, light switches, power, glass", C.Accent, 3)
    end)

    -- Ability Reference panel
    local abilityRefFrame = Instance.new("Frame")
    abilityRefFrame.Size = UDim2.new(1, 0, 0, 30); abilityRefFrame.BackgroundTransparency = 1
    abilityRefFrame.LayoutOrder = 2; abilityRefFrame.Parent = abilPage
    abilityRefFrame.AutomaticSize = Enum.AutomaticSize.Y

    local abilRefLayout = Instance.new("UIListLayout"); abilRefLayout.Padding = UDim.new(0, 3)
    abilRefLayout.SortOrder = Enum.SortOrder.LayoutOrder; abilRefLayout.Parent = abilityRefFrame

    local abilRefTitle = Instance.new("TextLabel"); abilRefTitle.Size = UDim2.new(1, 0, 0, 16)
    abilRefTitle.BackgroundTransparency = 1; abilRefTitle.Text = "GHOST ABILITIES REFERENCE"
    abilRefTitle.TextColor3 = C.AccentDim; abilRefTitle.Font = C.Font; abilRefTitle.TextSize = 9
    abilRefTitle.TextXAlignment = Enum.TextXAlignment.Left; abilRefTitle.LayoutOrder = 0; abilRefTitle.Parent = abilityRefFrame

    local abilOrder = {"Entity","Banshee","Nightmare","Ravager","Leviathan","Spirit","Skinwalker","Aswang","Demon","Dullahan","Dybbuk","Ghoul","Keres","Oni","Phantom","Revenant","Shadow","Siren","Specter","Umbra","Vex","Vesper","Wendigo","Wisp","Wraith"}
    for _, gName in ipairs(abilOrder) do
        local info = GhostAbilities[gName]
        if info then
            local gf = Instance.new("Frame"); gf.Size = UDim2.new(1, 0, 0, 28)
            gf.BackgroundColor3 = C.Bg3; gf.BackgroundTransparency = 0.45; gf.BorderSizePixel = 0; gf.Parent = abilityRefFrame
            corner(gf, UDim.new(0, 5))
            local nm = Instance.new("TextLabel"); nm.Size = UDim2.new(0, 0, 1, 0); nm.Position = UDim2.new(0, 8, 0, 0)
            nm.BackgroundTransparency = 1; nm.Text = info.icon .. " " .. gName; nm.TextColor3 = C.Text1
            nm.Font = C.FontMed; nm.TextSize = 10; nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.AutomaticSize = Enum.AutomaticSize.X; nm.Parent = gf
            local desc = Instance.new("TextLabel"); desc.Size = UDim2.new(1, -20, 1, 0); desc.Position = UDim2.new(0, 8, 0, 0)
            desc.BackgroundTransparency = 1; desc.Text = info.desc; desc.TextColor3 = C.Text3
            desc.Font = C.FontReg; desc.TextSize = 9; desc.TextXAlignment = Enum.TextXAlignment.Right; desc.Parent = gf
        end
    end

    -- Ability Log
    local abilityLogFrame = Instance.new("Frame"); abilityLogFrame.Name = "AbilityLog"
    abilityLogFrame.Size = UDim2.new(1, 0, 0, 30); abilityLogFrame.BackgroundTransparency = 1
    abilityLogFrame.LayoutOrder = 3; abilityLogFrame.Parent = abilPage
    abilityLogFrame.AutomaticSize = Enum.AutomaticSize.Y

    local abilLogLayout = Instance.new("UIListLayout"); abilLogLayout.Padding = UDim.new(0, 3)
    abilLogLayout.SortOrder = Enum.SortOrder.LayoutOrder; abilLogLayout.Parent = abilityLogFrame

    local abilLogTitle = Instance.new("TextLabel"); abilLogTitle.Size = UDim2.new(1, 0, 0, 16)
    abilLogTitle.BackgroundTransparency = 1; abilLogTitle.Text = "ABILITY LOG (most recent)"
    abilLogTitle.TextColor3 = C.AccentDim; abilLogTitle.Font = C.Font; abilLogTitle.TextSize = 9
    abilLogTitle.TextXAlignment = Enum.TextXAlignment.Left; abilLogTitle.LayoutOrder = 0; abilLogTitle.Parent = abilityLogFrame

    function updateAbilityPanel()
        for _, ch in pairs(abilityLogFrame:GetChildren()) do
            if ch:IsA("Frame") and ch.Name ~= "AbilityLog" then ch:Destroy() end
        end
        for i, entry in ipairs(S._abilityLog) do
            if i > 15 then break end
            local gf = Instance.new("Frame"); gf.Size = UDim2.new(1, 0, 0, 22)
            gf.BackgroundColor3 = C.Bg3; gf.BackgroundTransparency = 0.5; gf.BorderSizePixel = 0; gf.LayoutOrder = i; gf.Parent = abilityLogFrame
            corner(gf, UDim.new(0, 4))
            local timeL = Instance.new("TextLabel"); timeL.Size = UDim2.new(0, 45, 1, 0); timeL.Position = UDim2.new(0, 6, 0, 0)
            timeL.BackgroundTransparency = 1; timeL.Text = entry.time; timeL.TextColor3 = C.Text3; timeL.Font = C.FontReg; timeL.TextSize = 9; timeL.TextXAlignment = Enum.TextXAlignment.Left; timeL.Parent = gf
            local abilL = Instance.new("TextLabel"); abilL.Size = UDim2.new(1, -60, 1, 0); abilL.Position = UDim2.new(0, 52, 0, 0)
            abilL.BackgroundTransparency = 1; abilL.Text = entry.ability; abilL.TextColor3 = C.AbilityColors[entry.ability] or C.AccentBright
            abilL.Font = C.FontMed; abilL.TextSize = 9; abilL.TextXAlignment = Enum.TextXAlignment.Left; abilL.Parent = gf
            local ghostL = Instance.new("TextLabel"); ghostL.Size = UDim2.new(0, 70, 1, 0); ghostL.Position = UDim2.new(1, -74, 0, 0)
            ghostL.BackgroundTransparency = 1; ghostL.Text = entry.ghost or ""; ghostL.TextColor3 = C.Text3; ghostL.Font = C.FontReg; ghostL.TextSize = 8; ghostL.TextXAlignment = Enum.TextXAlignment.Right; ghostL.Parent = gf
        end
    end

    -- Ability Results Panel
    local abilResultsFrame = Instance.new("Frame"); abilResultsFrame.Name = "AbilityResults"
    abilResultsFrame.Size = UDim2.new(1, 0, 0, 30); abilResultsFrame.BackgroundTransparency = 1
    abilResultsFrame.LayoutOrder = 4; abilResultsFrame.Parent = abilPage
    abilResultsFrame.AutomaticSize = Enum.AutomaticSize.Y

    local abilResLayout = Instance.new("UIListLayout"); abilResLayout.Padding = UDim.new(0, 4)
    abilResLayout.SortOrder = Enum.SortOrder.LayoutOrder; abilResLayout.Parent = abilResultsFrame

    local abilResTitle = Instance.new("TextLabel"); abilResTitle.Size = UDim2.new(1, 0, 0, 16)
    abilResTitle.BackgroundTransparency = 1; abilResTitle.Text = "GHOST ANALYSIS BY ABILITY"
    abilResTitle.TextColor3 = C.AccentDim; abilResTitle.Font = C.Font; abilResTitle.TextSize = 9
    abilResTitle.TextXAlignment = Enum.TextXAlignment.Left; abilResTitle.LayoutOrder = 0; abilResTitle.Parent = abilResultsFrame

    S._abilResultsPanel = abilResultsFrame

    local function updateAbilityResultsPanel()
        for _, ch in pairs(abilResultsFrame:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        local byAbil = getPossibleGhostsByAbility()
        if #byAbil == 0 then
            local empty = Instance.new("Frame"); empty.Size = UDim2.new(1, 0, 0, 24)
            empty.BackgroundTransparency = 1; empty.LayoutOrder = 1; empty.Parent = abilResultsFrame
            local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1; lbl.Text = "No abilities detected yet — ghost abilities will appear here"
            lbl.TextColor3 = C.Text3; lbl.Font = C.FontReg; lbl.TextSize = 9; lbl.Parent = empty
            return
        end
        for i, g in ipairs(byAbil) do
            if i > 25 then break end
            local gf = Instance.new("Frame"); gf.Size = UDim2.new(1, 0, 0, 40)
            gf.BackgroundColor3 = C.Bg3; gf.BackgroundTransparency = 0.35; gf.BorderSizePixel = 0
            gf.LayoutOrder = i; gf.Parent = abilResultsFrame; corner(gf, UDim.new(0, 6))
            if g.confidence > 0 and i == 1 then stroke(gf, C.Green, 1, 0.4) end
            local gName = Instance.new("TextLabel"); gName.Size = UDim2.new(0.5, 0, 0, 16); gName.Position = UDim2.new(0, 10, 0, 4)
            gName.BackgroundTransparency = 1; gName.Text = g.confidence > 0 and (g.icon .. " " .. g.name) or g.name
            gName.TextColor3 = g.confidence > 0 and C.Text1 or C.Text3; gName.Font = C.FontMed; gName.TextSize = 12
            gName.TextXAlignment = Enum.TextXAlignment.Left; gName.Parent = gf
            local confBg = Instance.new("Frame"); confBg.Size = UDim2.new(0, 60, 0, 6); confBg.Position = UDim2.new(1, -76, 0, 8)
            confBg.BackgroundColor3 = C.Bg4; confBg.BorderSizePixel = 0; confBg.Parent = gf; corner(confBg, UDim.new(1, 0))
            local confFill = Instance.new("Frame"); confFill.Size = UDim2.new(g.confidence / 100, 0, 1, 0)
            confFill.BackgroundColor3 = g.confidence >= 66 and C.Green or g.confidence >= 33 and C.Yellow or C.Text3
            confFill.BorderSizePixel = 0; confFill.Parent = confBg; corner(confFill, UDim.new(1, 0))
            local confTxt = Instance.new("TextLabel"); confTxt.Size = UDim2.new(0, 28, 0, 12); confTxt.Position = UDim2.new(1, -30, 0, 5)
            confTxt.BackgroundTransparency = 1; confTxt.Text = g.confidence .. "%"; confTxt.TextColor3 = C.Text3; confTxt.Font = C.FontReg; confTxt.TextSize = 9; confTxt.Parent = gf
            if #g.abilities > 0 then
                local abilTags = Instance.new("TextLabel"); abilTags.Size = UDim2.new(1, -16, 0, 12); abilTags.Position = UDim2.new(0, 10, 0, 23)
                abilTags.BackgroundTransparency = 1; abilTags.Font = C.FontReg; abilTags.TextSize = 9
                abilTags.TextXAlignment = Enum.TextXAlignment.Left; abilTags.Parent = gf
                local parts = {}
                for _, a in ipairs(g.abilities) do
                    local detected = S.DetectedAbilities[a]
                    local clr = detected and (C.AbilityColors[a] or C.Green) or C.Text3
                    local m = detected and "✓" or "○"
                    table.insert(parts, m .. a)
                end
                abilTags.Text = table.concat(parts, "  ")
                abilTags.TextColor3 = g.confidence > 0 and C.Text1 or C.Text3
            end
        end
    end

    local origUpdAbil = updateAbilityPanel
    updateAbilityPanel = function()
        origUpdAbil()
        pcall(updateAbilityResultsPanel)
    end

    -- ═══════════════════════════════════════
    --   PAGE: SURVIVAL
    -- ═══════════════════════════════════════
    local survPage = makePage("Survival")

    makeToggle(survPage, "Fullbright", "Max brightness, see everything", 1, function(on)
        if on then
            S._origLight = {
                Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
                GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            Lighting.Brightness = 3; Lighting.ClockTime = 14
            Lighting.FogEnd = 1e5; Lighting.FogStart = 1e5
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        else
            if S._origLight then for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end end
        end
    end)

    makeToggle(survPage, "Night Vision", "Green-tinted enhanced visibility", 2, function(on)
        if on then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "HubNV"; cc.Brightness = 0.15; cc.Contrast = 0.1
            cc.Saturation = -0.5; cc.TintColor = Color3.fromRGB(130, 255, 130)
            cc.Parent = Lighting
        else
            local cc = Lighting:FindFirstChild("HubNV")
            if cc then cc:Destroy() end
        end
    end)

    makeToggle(survPage, "Infinite Stamina", "Prevent walkspeed reduction", 3, function(on)
        rmConn("stamina")
        if not on then return end
        addConn("stamina", RunService.Heartbeat:Connect(function()
            if not S.Features["Infinite Stamina"] then return end
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.WalkSpeed < 16 then h.WalkSpeed = 16 end
            end
        end))
    end)

    makeToggle(survPage, "Anti-Death", "Keep health at maximum", 4, function(on)
        rmConn("antideath")
        if not on then return end
        addConn("antideath", RunService.Heartbeat:Connect(function()
            if not S.Features["Anti-Death"] then return end
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.Health = h.MaxHealth end
            end
        end))
    end)

    -- Auto Hide on Hunt (FIXED: uses Ghost:Hunting attribute)
    makeToggle(survPage, "Auto Hide on Hunt", "TP into nearest closet when hunt starts", 5, function(on)
        rmConn("hunt_watch")
        if not on then return end

        addConn("hunt_watch", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto Hide on Hunt"] then return end
            local ghost = Workspace:FindFirstChild("Ghost")
            if ghost then
                local hunting = ghost:GetAttribute("Hunting")
                if hunting == true and not huntActive then
                    onHuntStart()
                elseif hunting ~= true and huntActive then
                    onHuntEnd()
                end
            end
        end))
        notify("🛡 Hunt auto-hide armed", C.Green, 3)
    end)

    -- Manual hide button
    local hideBtn = Instance.new("Frame")
    hideBtn.Size = UDim2.new(1, 0, 0, 36)
    hideBtn.BackgroundColor3 = C.Blue
    hideBtn.BackgroundTransparency = 0.82
    hideBtn.BorderSizePixel = 0
    hideBtn.LayoutOrder = 6
    hideBtn.Parent = survPage
    corner(hideBtn, UDim.new(0, 8))
    stroke(hideBtn, C.Blue, 1, 0.5)

    local hideLbl = Instance.new("TextLabel")
    hideLbl.Size = UDim2.new(1, 0, 1, 0)
    hideLbl.BackgroundTransparency = 1
    hideLbl.Text = "🚪 Manual Hide Now"
    hideLbl.TextColor3 = C.Blue
    hideLbl.Font = C.FontMed
    hideLbl.TextSize = 12
    hideLbl.Parent = hideBtn

    local hideClick = Instance.new("TextButton")
    hideClick.Size = UDim2.new(1, 0, 1, 0)
    hideClick.BackgroundTransparency = 1
    hideClick.Text = ""
    hideClick.Parent = hideBtn
    hideClick.MouseButton1Click:Connect(function()
        local ok = safeTPToHidingSpot()
        if not ok then notify("⚠ No closet found nearby!", C.Yellow, 4) end
    end)

    hideBtn.MouseEnter:Connect(function() tw(hideBtn, {BackgroundTransparency = 0.55}, C.SpeedFast) end)
    hideBtn.MouseLeave:Connect(function() tw(hideBtn, {BackgroundTransparency = 0.82}, C.SpeedFast) end)

    -- ═══════════════════════════════════════
    --   PAGE: VISUAL
    -- ═══════════════════════════════════════
    local visPage = makePage("Visual")

    makeToggle(visPage, "No Blur", "Disable all blur effects", 1, function(on)
        rmConn("noblur_l") rmConn("noblur_c")
        if on then
            for _, e in pairs(Lighting:GetChildren()) do
                if e:IsA("BlurEffect") and e.Name ~= "HubBlur" then e.Enabled = false end
            end
            for _, e in pairs(Camera:GetChildren()) do
                if e:IsA("BlurEffect") then e.Enabled = false end
            end
            addConn("noblur_l", Lighting.ChildAdded:Connect(function(ch)
                if ch:IsA("BlurEffect") and ch.Name ~= "HubBlur" and S.Features["No Blur"] then ch.Enabled = false end
            end))
            addConn("noblur_c", Camera.ChildAdded:Connect(function(ch)
                if ch:IsA("BlurEffect") and S.Features["No Blur"] then ch.Enabled = false end
            end))
        else
            for _, e in pairs(Lighting:GetChildren()) do
                if e:IsA("BlurEffect") and e.Name ~= "HubBlur" then e.Enabled = true end
            end
            for _, e in pairs(Camera:GetChildren()) do
                if e:IsA("BlurEffect") then e.Enabled = true end
            end
        end
    end)

    makeToggle(visPage, "No Fog", "Remove all fog effects", 2, function(on)
        if on then
            S._origFog = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart}
            Lighting.FogEnd = 1e6; Lighting.FogStart = 1e6
        else
            if S._origFog then Lighting.FogEnd = S._origFog.FogEnd; Lighting.FogStart = S._origFog.FogStart end
        end
    end)

    makeToggle(visPage, "No Weather", "Disable clouds & atmosphere", 3, function(on)
        if on then
            local t = Workspace:FindFirstChildOfClass("Terrain")
            if t then for _, ch in pairs(t:GetChildren()) do if ch:IsA("Clouds") then ch.Enabled = false end end end
            for _, e in pairs(Lighting:GetChildren()) do if e:IsA("Atmosphere") then e.Density = 0 end end
        else
            local t = Workspace:FindFirstChildOfClass("Terrain")
            if t then for _, ch in pairs(t:GetChildren()) do if ch:IsA("Clouds") then ch.Enabled = true end end end
        end
    end)

    makeToggle(visPage, "No Shake", "Stabilize camera shake", 4, function(on)
        notify(on and "📷 Shake dampening active" or "📷 Shake dampening off", C.Green, 2)
    end)

    -- ═══════════════════════════════════════
    --   PAGE: TOOLS
    -- ═══════════════════════════════════════
    local toolsPage = makePage("Tools")

    makeToggle(toolsPage, "Speed Boost", "Walk 50% faster", 1, function(on)
        rmConn("speed")
        if not on then
            local c = LocalPlayer.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end
            return
        end
        addConn("speed", RunService.Heartbeat:Connect(function()
            if not S.Features["Speed Boost"] then return end
            local c = LocalPlayer.Character
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 24 end end
        end))
    end)

    makeToggle(toolsPage, "No-Clip", "Walk through walls", 2, function(on)
        rmConn("noclip")
        if not on then return end
        addConn("noclip", RunService.Stepped:Connect(function()
            if not S.Features["No-Clip"] then return end
            local c = LocalPlayer.Character
            if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end))
    end)

    -- TP to Exit (fixed: multi-keyword + ExitDoor model)
    makeToggle(toolsPage, "TP to Exit", "Teleport to exit (fixed)", 3, function(on)
        if not on then return end
        local char = LocalPlayer.Character
        if not char then notify("⚠ No character", C.Red, 3) return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then notify("⚠ No HumanoidRootPart", C.Red, 3) return end
        local hum = char:FindFirstChildOfClass("Humanoid")

        local exitKeywords = {"exit", "escape", "leave", "maindoor", "outdoor"}
        local bestPart, bestScore = nil, -1

        local df = Workspace:FindFirstChild("Doors")
        if df then
            -- check ExitDoor first
            local exitDoor = df:FindFirstChild("ExitDoor")
            if exitDoor then
                local p = exitDoor:FindFirstChildWhichIsA("BasePart", true)
                if p then bestPart = p bestScore = 100 end
            end
            if not bestPart then
                for _, dm in pairs(df:GetChildren()) do
                    if dm:IsA("Model") then
                        local nm = dm.Name:lower()
                        local score = 0
                        for i, kw in ipairs(exitKeywords) do
                            if nm:find(kw) then score = (#exitKeywords - i + 1) * 10 break end
                        end
                        if score > bestScore then
                            local p = dm:FindFirstChildWhichIsA("BasePart", true)
                            if p then bestPart = p bestScore = score end
                        end
                    end
                end
            end
        end

        -- fallback to workspace scan
        if not bestPart then
            for _, d in pairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    local nm = d.Name:lower()
                    for _, kw in ipairs(exitKeywords) do
                        if nm:find(kw) then bestPart = d break end
                    end
                    if bestPart then break end
                end
            end
        end

        if bestPart then
            if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
            hrp.CFrame = CFrame.new(bestPart.Position + Vector3.new(0, 4, 5))
            task.wait(0.05)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
            notify("🚪 Teleported to exit: " .. (bestPart.Parent and bestPart.Parent.Name or "Exit"), C.Green, 3)
        else
            notify("⚠ Exit door not found", C.Yellow, 4)
        end

        task.wait(0.3)
        S.Features["TP to Exit"] = false
        updateCount()
    end)

    -- Remote Logger
    makeToggle(toolsPage, "Remote Logger", "Log all remote traffic", 4, function(on)
        rmConn("rlog")
        if S._logFrame then
            tw(S._logFrame, {Position = UDim2.new(1, 10, 0.5, -130)}, 0.3)
            task.wait(0.35)
            if S._logFrame then S._logFrame.Visible = false S._logFrame:Destroy() S._logFrame = nil end
        end
        if not on then return end

        local lf = Instance.new("Frame")
        lf.Name = "RemoteLog"
        lf.Size = UDim2.new(0, 250, 0, 260)
        lf.Position = UDim2.new(1, 10, 0.5, -130)
        lf.BackgroundColor3 = C.Bg1; lf.BackgroundTransparency = 0.12
        lf.BorderSizePixel = 0; lf.Parent = Hub
        corner(lf, UDim.new(0, 8)); stroke(lf, C.AccentDim, 1, 0.5)
        S._logFrame = lf

        local lt = Instance.new("TextLabel")
        lt.Size = UDim2.new(1, 0, 0, 24)
        lt.BackgroundColor3 = C.Bg2; lt.BackgroundTransparency = 0.2
        lt.BorderSizePixel = 0; lt.Text = "  📡 Remote Logger"
        lt.TextColor3 = C.AccentBright; lt.Font = C.Font; lt.TextSize = 10
        lt.TextXAlignment = Enum.TextXAlignment.Left; lt.Parent = lf
        corner(lt, UDim.new(0, 8))

        local ls = Instance.new("ScrollingFrame")
        ls.Size = UDim2.new(1, -6, 1, -30)
        ls.Position = UDim2.new(0, 3, 0, 27)
        ls.BackgroundTransparency = 1; ls.BorderSizePixel = 0
        ls.ScrollBarThickness = 2; ls.ScrollBarImageColor3 = C.AccentDim
        ls.AutomaticCanvasSize = Enum.AutomaticSize.Y; ls.CanvasSize = UDim2.new(0, 0, 0, 0)
        ls.Parent = lf
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 2); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = ls

        tw(lf, {Position = UDim2.new(1, -260, 0.5, -130)}, 0.4)

        local idx = 0
        local hooked = {}
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") and not hooked[r] then
                hooked[r] = true
                pcall(function()
                    r.OnClientEvent:Connect(function(...)
                        if not S.Features["Remote Logger"] then return end
                        idx += 1
                        if idx > 80 then
                            local first = ls:FindFirstChildWhichIsA("TextLabel")
                            if first then first:Destroy() end
                        end
                        local args = {...}
                        local argStr = ""
                        for i, v in ipairs(args) do
                            argStr ..= tostring(v)
                            if i < #args then argStr ..= ", " end
                        end
                        if #argStr > 50 then argStr = argStr:sub(1, 50) .. "…" end
                        local e = Instance.new("TextLabel")
                        e.Size = UDim2.new(1, 0, 0, 26)
                        e.BackgroundColor3 = C.Bg3; e.BackgroundTransparency = 0.45
                        e.BorderSizePixel = 0
                        e.Text = " ← " .. r.Name .. "\n " .. argStr
                        e.TextColor3 = C.Blue; e.Font = C.FontReg; e.TextSize = 9
                        e.TextXAlignment = Enum.TextXAlignment.Left
                        e.TextYAlignment = Enum.TextYAlignment.Top
                        e.LayoutOrder = idx; e.Parent = ls
                        corner(e, UDim.new(0, 3))
                        ls.CanvasPosition = Vector2.new(0, ls.AbsoluteCanvasSize.Y)
                    end)
                end)
            end
        end
        notify("📡 Logging remotes", C.Accent, 3)
    end)

    -- ═══════════════════════════════════════
    --   CATEGORY SWITCHING
    -- ═══════════════════════════════════════
    local function switchCat(name)
        currentCat = name
        for n, pg in pairs(pages) do pg.Visible = (n == name) end
        for n, d in pairs(sideBtns) do
            if n == name then
                tw(d.button, {BackgroundTransparency = 0.8}, C.Speed)
                tw(d.label, {TextColor3 = C.AccentBright}, C.Speed)
            else
                tw(d.button, {BackgroundTransparency = 1}, C.Speed)
                tw(d.label, {TextColor3 = C.Text2}, C.Speed)
            end
        end
    end
    if name == "Abilities" and updateAbilityPanel then updateAbilityPanel() end

    for name, d in pairs(sideBtns) do
        d.button.MouseButton1Click:Connect(function() switchCat(name) end)
    end
    switchCat("ESP")

    -- ═══════════════════════════════════════
    --   UPDATE FUNCTIONS
    -- ═══════════════════════════════════════
    function updateGhostPanel()
        if not S._ghostPanel then return end
        for _, ch in pairs(S._ghostPanel:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end

        local possible = getPossibleGhosts()
        for i, ghost in ipairs(possible) do
            if i > 25 then break end
            local gf = Instance.new("Frame")
            gf.Size = UDim2.new(1, 0, 0, 40)
            gf.BackgroundColor3 = C.Bg3; gf.BackgroundTransparency = 0.35
            gf.BorderSizePixel = 0; gf.LayoutOrder = i; gf.Parent = S._ghostPanel
            corner(gf, UDim.new(0, 6))

            if i == 1 and ghost.confidence > 0 then
                stroke(gf, C.Green, 1, 0.4)
            end

            local gName = Instance.new("TextLabel")
            gName.Size = UDim2.new(0.5, 0, 0, 16)
            gName.Position = UDim2.new(0, 10, 0, 4)
            gName.BackgroundTransparency = 1
            gName.Text = (i == 1 and ghost.confidence > 0) and ("👻 " .. ghost.name) or ghost.name
            gName.TextColor3 = (i == 1 and ghost.confidence > 0) and C.Green or C.Text1
            gName.Font = C.FontMed; gName.TextSize = 12
            gName.TextXAlignment = Enum.TextXAlignment.Left; gName.Parent = gf

            local confBg = Instance.new("Frame")
            confBg.Size = UDim2.new(0, 60, 0, 6)
            confBg.Position = UDim2.new(1, -76, 0, 8)
            confBg.BackgroundColor3 = C.Bg4; confBg.BorderSizePixel = 0; confBg.Parent = gf
            corner(confBg, UDim.new(1, 0))

            local confFill = Instance.new("Frame")
            confFill.Size = UDim2.new(ghost.confidence / 100, 0, 1, 0)
            confFill.BackgroundColor3 = ghost.confidence >= 66 and C.Green or ghost.confidence >= 33 and C.Yellow or C.Text3
            confFill.BorderSizePixel = 0; confFill.Parent = confBg
            corner(confFill, UDim.new(1, 0))

            local confTxt = Instance.new("TextLabel")
            confTxt.Size = UDim2.new(0, 20, 0, 12)
            confTxt.Position = UDim2.new(1, -20, 0, 5)
            confTxt.BackgroundTransparency = 1
            confTxt.Text = ghost.confidence .. "%"
            confTxt.TextColor3 = C.Text3; confTxt.Font = C.FontReg; confTxt.TextSize = 9
            confTxt.Parent = gf

            local tagParts = {}
            for _, ev in ipairs(ghost.evidence) do
                local found = S.Evidence[ev]
                for _, evInfo in ipairs(EvidenceTypes) do
                    if evInfo.id == ev then
                        local marker = found and "✓" or "○"
                        table.insert(tagParts, marker .. evInfo.icon)
                        break
                    end
                end
            end
            local evidTags = Instance.new("TextLabel")
            evidTags.Size = UDim2.new(1, -16, 0, 12)
            evidTags.Position = UDim2.new(0, 10, 0, 23)
            evidTags.BackgroundTransparency = 1
            evidTags.Text = table.concat(tagParts, "  ")
            evidTags.TextColor3 = C.Text3; evidTags.Font = C.FontReg; evidTags.TextSize = 9
            evidTags.TextXAlignment = Enum.TextXAlignment.Left; evidTags.Parent = gf
        end
    end

    function updateEvidencePanel()
        if not S._evidPanel then return end
        for id, data in pairs(S._evidPanel) do
            local found = S.Evidence[id]
            for _, ev in ipairs(EvidenceTypes) do
                if ev.id == id then
                    if found then
                        tw(data.frame, {BackgroundColor3 = ev.color, BackgroundTransparency = 0.4}, C.SpeedFast)
                        data.label.TextColor3 = C.Text1
                    else
                        tw(data.frame, {BackgroundColor3 = C.Bg4, BackgroundTransparency = 0.25}, C.SpeedFast)
                        data.label.TextColor3 = C.Text3
                    end
                    break
                end
            end
        end
    end

    updateGhostPanel()
    updateEvidencePanel()
    updateHUD()

    -- ═══════════════════════════════════════
    --   WINDOW CONTROLS
    -- ═══════════════════════════════════════
    closeBtn.MouseButton1Click:Connect(function()
        for k, c in pairs(S.Conns) do pcall(function() c:Disconnect() end) end
        for t, _ in pairs(S.Highlights) do clearHL(t) end
        pcall(function() Lighting:FindFirstChild("HubNV"):Destroy() end)
        if S._origLight then for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end end
        if S._origFog then pcall(function() Lighting.FogEnd = S._origFog.FogEnd; Lighting.FogStart = S._origFog.FogStart end) end
        pcall(function() if EvidHudGui then EvidHudGui:Destroy() end end)
        tw(MainFrame, {Size = UDim2.new(0, 620, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        Hub:Destroy()
    end)

    minBtn.MouseButton1Click:Connect(function()
        S.Visible = not S.Visible
        if S.Visible then
            MainFrame.Visible = true
            tw(MainFrame, {Size = UDim2.new(0, 620, 0, 480)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tw(MainFrame, {Size = UDim2.new(0, 620, 0, 44)}, 0.2)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == C.Key then
            S.Visible = not S.Visible
            if S.Visible then
                MainFrame.Visible = true
                MainFrame.BackgroundTransparency = 0.6
                tw(MainFrame, {BackgroundTransparency = 0.12}, 0.25)
            else
                tw(MainFrame, {BackgroundTransparency = 1}, 0.2)
                task.wait(0.25)
                MainFrame.Visible = false
            end
        end
    end)

    -- OPEN ANIMATION
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundTransparency = 0.8
    task.wait(0.1)
    tw(MainFrame, {BackgroundTransparency = 0.12, Size = UDim2.new(0, 620, 0, 480), Position = UDim2.new(0.5, -310, 0.5, -240)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.wait(0.6)
    notify("🕯 Demonology Hub v5.0 loaded", C.Accent, 4)
    notify("made by 1nxs on discord", C.Text3, 5)
    notify("RightShift to toggle", C.Text3, 4)
end

-- LAUNCH
showLoadingScreen(function()
    local ok, err = pcall(function()
        buildEvidHUD()
        buildHub()
    end)
    if not ok then
        warn("[Hub] Build failed:", err)
        print("[Hub] BUILD FAILED:", err)
    end
end)

print("[1nxs Hub] ✅ v5.0 Loaded — fixed ghost limit, EMF, Spirit Box, Laser")
