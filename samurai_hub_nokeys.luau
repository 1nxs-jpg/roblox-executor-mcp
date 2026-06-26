--[[
    1NXS SAMURAI HUB v1.0
    made by 1nxs on discord
    PvP combat features for Samurai DUELS
--]]

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
--   SERVICES
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

pcall(function()
    for _, n in ipairs({"1nxsHub","1nxsLoader","1nxsMatchHUD","1nxsEvidHUD"}) do
        local o = CoreGui:FindFirstChild(n)
        if o then o:Destroy() end
    end
    local b = Lighting:FindFirstChild("HubBlur")
    if b then b:Destroy() end
end)

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
--   KEY SYSTEM (anti-theft: server-free, algorithmic validation)
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

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
        if type(parsed.userId) ~= "number" or parsed.userId ~= LocalPlayer.UserId then
            return nil
        end
        if tick() >= parsed.expiry then
            delfile(KEY_FILE)
            return nil
        end
        return parsed.key
    end)
    if not ok then return nil end
    return saved
end

local function needsKey() return false end
local function showKeySystem() return true end
if needsKey() then
    local success = pcall(showKeySystem)
    if not success then
        print("[1nxs Hub] ÔØî Key validation failed or cancelled")
        return
    end
end
_G["1NXS_AUTHENTICATED"] = true

local function isEnemy(p)
    if p == LocalPlayer then return false end
    if not p.Character then return false end
    local teammateStr = LocalPlayer:GetAttribute("Teammate") or ""
    if teammateStr ~= "" then
        for name in teammateStr:gmatch("[^,]+") do
            if p.Name == name then return false end
        end
    end
    return true
end

local C = {
    Key             = Enum.KeyCode.RightShift,
    Bg1             = Color3.fromRGB(12, 12, 16),
    Bg2             = Color3.fromRGB(18, 18, 24),
    Bg3             = Color3.fromRGB(24, 24, 32),
    Bg4             = Color3.fromRGB(34, 34, 44),
    BgHover         = Color3.fromRGB(42, 42, 54),
    Accent          = Color3.fromRGB(92, 220, 121),
    AccentDim       = Color3.fromRGB(64, 94, 73),
    AccentBright    = Color3.fromRGB(231, 235, 240),
    Text1           = Color3.fromRGB(236, 238, 243),
    Text2           = Color3.fromRGB(154, 158, 170),
    Text3           = Color3.fromRGB(88, 92, 104),
    Green           = Color3.fromRGB(64, 218, 118),
    Red             = Color3.fromRGB(240, 100, 100),
    Yellow          = Color3.fromRGB(245, 200, 20),
    Blue            = Color3.fromRGB(86, 155, 245),
    Purple          = Color3.fromRGB(182, 122, 248),
    Orange          = Color3.fromRGB(248, 146, 60),
    EvidEMF         = Color3.fromRGB(250, 204, 21),
    EvidPrints      = Color3.fromRGB(182, 122, 248),
    Speed           = 0.3,
    SpeedFast       = 0.15,
    Font            = Enum.Font.GothamBold,
    FontMed         = Enum.Font.GothamMedium,
    FontReg         = Enum.Font.Gotham,
    FontNum         = Enum.Font.GothamMedium,
}

local Rarities = {
    Rare        = Color3.fromRGB(0, 112, 255),
    Epic        = Color3.fromRGB(163, 53, 238),
    Legendary   = Color3.fromRGB(255, 165, 0),
    Mystery     = Color3.fromRGB(30, 215, 215),
    Special     = Color3.fromRGB(255, 50, 50),
}

local SwordDB = {
    {name="Katana",          rarity="Rare",      desc="Simple and sharp"},
    {name="Glacial Katana",  rarity="Rare",      desc="Ice cold"},
    {name="Ninja Katana",    rarity="Rare",      desc="Silent and deadly"},
    {name="Bombastic Katana",rarity="Rare",      desc="Zero chill"},
    {name="Moon Katana",     rarity="Rare",      desc="Forged in moonlight"},
    {name="Neon Katana",     rarity="Rare",      desc="Glows in the dark"},
    {name="Toxicity",        rarity="Rare",      desc="Hazardous material"},
    {name="Chromatic Edge",  rarity="Epic",      desc="Every color. No favorite."},
    {name="Inferno Katana",  rarity="Epic",      desc="Extremely hot. Handle carefully."},
    {name="Laser Sword",     rarity="Epic",      desc="Totally not from space."},
    {name="Tempest",         rarity="Epic",      desc="Brings the storm."},
    {name="Cursed Blade",    rarity="Legendary", desc="The curse is included."},
    {name="Eclipse",         rarity="Legendary", desc="Blots out the sun."},
    {name="Glitch",          rarity="Legendary", desc="Reality.exe stopped working."},
    {name="Omega Katana",    rarity="Legendary", desc="The final blade."},
    {name="Crescendo",       rarity="Mystery",   desc="Starts quiet. Ends loud."},
    {name="Astral Blade",    rarity="Special",   desc="Beyond reality."},
    {name="Void",            rarity="Special",   desc="The abyss fights back."},
    {name="Demon Blade",     rarity="Special",   desc="Forged in hell."},
    {name="Cyber Katana",    rarity="Special",   desc="404: mercy not found."},
    {name="Ghost Blade",     rarity="Special",   desc="Cold to the touch. Colder in death."},
    {name="KryptoniteSword", rarity="Special",   desc="Weakens gods. Splits atoms."},
    {name="ShadowFang",      rarity="Special",   desc="What it cuts, the dark reclaims."},
    {name="STARRY",          rarity="Special",   desc="Twinkle Twinkle."},
    {name="APOCALYPSE",      rarity="Special",   desc="Its so over."},
    {name="Avenger",         rarity="Special",   desc="A sword fit for a hero"},
    {name="Angel Blade",     rarity="Special",   desc="Mercy comes from above."},
    {name="OBLIVION",        rarity="Special",   desc="Nothing remains."},
    {name="Frostbite",       rarity="Special",   desc="The chill that bites back."},
    {name="Spider Sword",    rarity="Special",   desc="Caught in the web."},
    {name="Forsaken",        rarity="Special",   desc="Abandoned by all."},
    {name="CELESTIAL BLADE", rarity="Special",   desc="Light of a thousand stars."},
    {name="HELLFIRE",        rarity="Special",   desc="Straight from the inferno."},
}

local AbilityDataDB = {
    {name="Rage",        desc="Speed boost",                 keysPrice=0},
    {name="Skydive",     desc="Launch upward",              keysPrice=100},
    {name="Invisible",   desc="Turn invisible",             keysPrice=500},
    {name="Teleport",    desc="Short teleport",             keysPrice=850},
    {name="DemonStep",   desc="Rapid teleports",            keysPrice=99,  robux=true},
    {name="TrinitySlash",desc="Triple dash",                keysPrice=99,  robux=true},
    {name="Berzerk",     desc="No cooldown + 3x charge",    keysPrice=1500},
}

local FinisherDataDB = {
    {name="Shatter",    desc="Crystal shatter",       type="Keys",   amount=300},
    {name="Supernova",  desc="Golden detonation",     type="Keys",   amount=500},
    {name="Singularity",desc="Violet phantom",        type="Keys",   amount=1000},
    {name="Ripples",    desc="Shockwave",             type="Wins",   amount=50},
    {name="Phantom",    desc="Ghost fade",            type="Robux",  amount=49},
    {name="Implosion",  desc="Dark collapse",         type="Robux",  amount=79},
}

local S = {
    Visible         = true,
    Features        = {},
    Conns           = {},
    Highlights      = {},
    Billboards      = {},
    ActiveCount     = 0,
    _statusLabel    = nil,
    _notifBox       = nil,
    _origLight      = nil,
    _hudLabels      = {},
    _toggleControls = {},
    _matchInProgress = false,
    _currentRound   = 0,
    _maxRounds      = 8,
    _myKills        = 0,
    _myDeaths       = 0,
    _enemyName      = "",
    _roundTimeLeft  = 90,
    _queueJoined    = false,
}

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

-- MATCH HUD
local MatchHudGui

local function buildMatchHUD()
    MatchHudGui = Instance.new("ScreenGui")
    MatchHudGui.Name = "1nxsMatchHUD"
    MatchHudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MatchHudGui.DisplayOrder = 999
    MatchHudGui.ResetOnSpawn = false
    MatchHudGui.IgnoreGuiInset = true
    pcall(function() MatchHudGui.Parent = CoreGui end)
    if not MatchHudGui.Parent then MatchHudGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local bar = Instance.new("Frame")
    bar.Name = "MatchBar"
    bar.Size = UDim2.new(0, 480, 0, 40)
    bar.Position = UDim2.new(0.5, -240, 0, 10)
    bar.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    bar.BackgroundTransparency = 0.3
    bar.BorderSizePixel = 0
    bar.Parent = MatchHudGui
    corner(bar, UDim.new(0, 14))
    stroke(bar, C.AccentDim, 1, 0.5)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bar
    pad(bar, 0, 0, 10, 10)

    local function makePill(w)
        local p = Instance.new("Frame")
        p.Size = UDim2.new(0, w, 0, 24)
        p.BackgroundColor3 = C.Bg4
        p.BackgroundTransparency = 0.35
        p.BorderSizePixel = 0
        p.Parent = bar
        corner(p, UDim.new(0, 6))
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Font = C.FontMed
        l.TextSize = 10
        l.TextColor3 = C.Text3
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.Parent = p
        return l
    end

    S._hudLabels = {
        status   = makePill(80),
        round    = makePill(90),
        timer    = makePill(70),
        kills    = makePill(70),
        enemy    = makePill(120),
    }
    S._hudLabels.status.Text = "ÔÅ│ Idle"
    S._hudLabels.round.Text = "Round 0/8"
    S._hudLabels.timer.Text = "90s"
    S._hudLabels.kills.Text = "K:0 D:0"
    S._hudLabels.enemy.Text = "vs ---"

    addConn("hud_update", RunService.Heartbeat:Connect(function()
        if not (MatchHudGui and MatchHudGui.Parent) then return end
        local plr = LocalPlayer
        local kills = plr:GetAttribute("Kills") or 0
        local deaths = plr:GetAttribute("Deaths") or 0
        S._hudLabels.kills.Text = "K:" .. kills .. " D:" .. deaths
    end))
end

local function updateMatchHUD()
    if not S._hudLabels then return end
    S._hudLabels.status.Text = S._matchInProgress and "ÔÜö Fighting" or "ÔÅ│ Idle"
    S._hudLabels.round.Text = "Round " .. S._currentRound .. "/" .. S._maxRounds
    S._hudLabels.timer.Text = math.max(0, math.floor(S._roundTimeLeft)) .. "s"
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

-- GAME EVENT TRACKING
local function hookGameEvents()
    local rs = ReplicatedStorage
    local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("Events")
    if not remotes then return end

    local gameEvent = remotes:FindFirstChild("GameEvent") or remotes:FindFirstChild("GameEvent")
    if gameEvent and gameEvent:IsA("RemoteEvent") then
        gameEvent.OnClientEvent:Connect(function(eventName, ...)
            if eventName == "MatchStart" then
                S._matchInProgress = true
                S._myKills = 0
                S._myDeaths = 0
                S._queueJoined = false
                notify("ÔÜö Match started!", C.Accent, 4)
                updateMatchHUD()
            elseif eventName == "RoundFight" then
                S._currentRound = (S._currentRound or 0) + 1
                notify("­ƒöä Round " .. S._currentRound .. " ÔÇö Fight!", C.Yellow, 3)
                updateMatchHUD()
            elseif eventName == "MatchEnd" then
                S._matchInProgress = false
                S._currentRound = 0
                S._queueJoined = false
                notify("­ƒÅü Match ended", C.Red, 4)
                updateMatchHUD()
            elseif eventName == "DeathFeed" then
                local args = {...}
                local killer = tostring(args[1] or "?")
                local victim = tostring(args[2] or "?")
                if killer == LocalPlayer.Name then
                    S._myKills = (S._myKills or 0) + 1
                    notify("­ƒÆÇ You killed " .. victim, C.Green, 3)
                elseif victim == LocalPlayer.Name then
                    S._myDeaths = (S._myDeaths or 0) + 1
                    notify("­ƒÆÇ You were killed by " .. killer, C.Red, 3)
                end
                updateMatchHUD()
            end
        end)
    end

    local dashEvent = remotes:FindFirstChild("DashEvent")
    if dashEvent and dashEvent:IsA("RemoteEvent") then
        -- Client can fire but also watch for enemy dashes via gameplay effects
    end

    local blockEvent = remotes:FindFirstChild("BlockEvent")
    if blockEvent and blockEvent:IsA("RemoteEvent") then
        -- For auto-parry usage
    end
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
    logo.Text = "SAMURAI HUB"
    logo.TextColor3 = C.Text1
    logo.Font = C.Font
    logo.TextSize = 28
    logo.TextTransparency = 1
    logo.Parent = center

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(1, 0, 0, 18)
    ver.Position = UDim2.new(0, 0, 0, 70)
    ver.BackgroundTransparency = 1
    ver.Text = "v1.0 ÔÇö PvP combat features"
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
        {pct = 0.15, text = "mapping remotes..."},
        {pct = 0.30, text = "loading sword database..."},
        {pct = 0.45, text = "indexing abilities..."},
        {pct = 0.60, text = "building combat features..."},
        {pct = 0.75, text = "building interface..."},
        {pct = 0.90, text = "hooking game events..."},
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
    local viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    local isPhone = viewport.X < 700 or viewport.Y < 600
    local windowW = isPhone and math.clamp(math.floor(viewport.X * 0.92), 320, 560) or 620
    local windowH = isPhone and math.clamp(math.floor(viewport.Y * 0.82), 360, 500) or 480

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
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, windowW, 0, windowH)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = C.Bg1
    MainFrame.BackgroundTransparency = 0.14
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = Hub
    corner(MainFrame, UDim.new(0, 14))
    stroke(MainFrame, C.AccentDim, 1, 0.45)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = isPhone and math.clamp(math.min(viewport.X / 620, viewport.Y / 480), 0.78, 0.92) or 1
    uiScale.Parent = MainFrame

    local topSheen = Instance.new("Frame")
    topSheen.Size = UDim2.new(1, -30, 0, 1)
    topSheen.Position = UDim2.new(0, 15, 0, 1)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BackgroundTransparency = 0.82
    topSheen.BorderSizePixel = 0
    topSheen.Parent = MainFrame

    -- TITLE BAR
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 54)
    titleBar.BackgroundColor3 = C.Bg2
    titleBar.BackgroundTransparency = 0.15
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    corner(titleBar, UDim.new(0, 14))

    local logoBadge = Instance.new("Frame")
    logoBadge.Size = UDim2.new(0, 38, 0, 38)
    logoBadge.Position = UDim2.new(0, 14, 0.5, -19)
    logoBadge.BackgroundColor3 = C.Bg3
    logoBadge.BackgroundTransparency = 0.05
    logoBadge.BorderSizePixel = 0
    logoBadge.Parent = titleBar
    corner(logoBadge, UDim.new(1, 0))
    stroke(logoBadge, C.Accent, 1, 0.65)

    local logoGlyph = Instance.new("TextLabel")
    logoGlyph.Size = UDim2.new(1, 0, 1, 0)
    logoGlyph.BackgroundTransparency = 1
    logoGlyph.Text = "1NXS"
    logoGlyph.TextColor3 = C.AccentBright
    logoGlyph.Font = C.Font
    logoGlyph.TextSize = 22
    logoGlyph.Parent = logoBadge

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = C.Bg2
    titleFix.BackgroundTransparency = 0.15
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
    titleTxt.Size = UDim2.new(0, 250, 0, 20)
    titleTxt.Position = UDim2.new(0, 60, 0, 8)
    titleTxt.BackgroundTransparency = 1
    titleTxt.Text = "SAMURAI HUB"
    titleTxt.TextColor3 = C.Text1
    titleTxt.Font = C.Font
    titleTxt.TextSize = 16
    titleTxt.TextXAlignment = Enum.TextXAlignment.Left
    titleTxt.Parent = titleBar

    local subtitleTxt = Instance.new("TextLabel")
    subtitleTxt.Size = UDim2.new(0, 240, 0, 12)
    subtitleTxt.Position = UDim2.new(0, 60, 0, 28)
    subtitleTxt.BackgroundTransparency = 1
    subtitleTxt.Text = "1nxs - v1.0"
    subtitleTxt.TextColor3 = C.Text3
    subtitleTxt.Font = C.FontReg
    subtitleTxt.TextSize = 10
    subtitleTxt.TextXAlignment = Enum.TextXAlignment.Left
    subtitleTxt.Parent = titleBar

    local statusBadge = Instance.new("TextLabel")
    statusBadge.Size = UDim2.new(0, 72, 0, 20)
    statusBadge.Position = UDim2.new(1, -200, 0.5, -10)
    statusBadge.BackgroundColor3 = C.Bg4
    statusBadge.BackgroundTransparency = 0.18
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
        btn.Size = UDim2.new(0, 34, 0, 34)
        btn.Position = UDim2.new(1, posX, 0.5, -17)
        btn.BackgroundColor3 = C.Bg3
        btn.BackgroundTransparency = 0.12
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = col
        btn.Font = C.Font
        btn.TextSize = 14
        btn.Parent = titleBar
        corner(btn, UDim.new(0, 8))
        stroke(btn, C.AccentDim, 1, 0.7)
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundTransparency = 0}, C.SpeedFast) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundTransparency = 0.12}, C.SpeedFast) end)
        return btn
    end

    local closeBtn = makeBtn("Close", "├ù", C.Red, -46)
    local minBtn   = makeBtn("Min",   "Ôûó", C.Text2, -86)

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
    sidebar.Size = UDim2.new(0, 104, 1, -54)
    sidebar.Position = UDim2.new(0, 0, 0, 54)
    sidebar.BackgroundColor3 = C.Bg2
    sidebar.BackgroundTransparency = 0.15
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainFrame

    local sideLayout = Instance.new("UIListLayout")
    sideLayout.Padding = UDim.new(0, 4)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Parent = sidebar
    pad(sidebar, 8, 8, 8, 8)

    local categories = {
        {name="Combat",    icon="ÔÜö",   order=1},
        {name="ESP",       icon="­ƒæü",   order=2},
        {name="Match",     icon="­ƒÅƒ",   order=3},
        {name="Swords",    icon="­ƒùí",   order=4},
        {name="Abilities", icon="ÔÜí",   order=5},
        {name="Visual",    icon="Ô£¿",   order=6},
        {name="Finishers", icon="­ƒÆÑ",   order=7},
        {name="Misc",      icon="ÔÜÖ",   order=8},
        {name="Config",    icon="­ƒùé",   order=9},
    }

    local sideBtns = {}
    local currentCat = "Home"

    local homeBtn = Instance.new("TextButton")
    homeBtn.Size = UDim2.new(1, 0, 0, 34)
    homeBtn.BackgroundColor3 = C.Bg3
    homeBtn.BackgroundTransparency = 0.18
    homeBtn.BorderSizePixel = 0
    homeBtn.Text = ""
    homeBtn.LayoutOrder = 0
    homeBtn.Parent = sidebar
    corner(homeBtn, UDim.new(0, 6))
    stroke(homeBtn, C.AccentDim, 1, 0.75)

    local homeIco = Instance.new("TextLabel")
    homeIco.Size = UDim2.new(0, 36, 1, 0)
    homeIco.Position = UDim2.new(0, 8, 0, 0)
    homeIco.BackgroundTransparency = 1
    homeIco.Text = "­ƒÅá"
    homeIco.TextColor3 = C.Text2
    homeIco.Font = C.FontMed
    homeIco.TextSize = 10
    homeIco.Parent = homeBtn

    local homeLbl = Instance.new("TextLabel")
    homeLbl.Name = "Lbl"
    homeLbl.Size = UDim2.new(1, -34, 1, 0)
    homeLbl.Position = UDim2.new(0, 44, 0, 0)
    homeLbl.BackgroundTransparency = 1
    homeLbl.Text = "Home"
    homeLbl.TextColor3 = C.Text2
    homeLbl.Font = C.FontMed
    homeLbl.TextSize = 10
    homeLbl.TextXAlignment = Enum.TextXAlignment.Left
    homeLbl.Parent = homeBtn

    sideBtns["Home"] = {button = homeBtn, label = homeLbl}
    homeBtn.MouseEnter:Connect(function()
        if currentCat ~= "Home" then tw(homeBtn, {BackgroundTransparency = 0.08}, C.SpeedFast) end
    end)
    homeBtn.MouseLeave:Connect(function()
        if currentCat ~= "Home" then tw(homeBtn, {BackgroundTransparency = 0.18}, C.SpeedFast) end
    end)

    for _, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = C.Bg3
        btn.BackgroundTransparency = 0.18
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = cat.order
        btn.Parent = sidebar
        corner(btn, UDim.new(0, 6))
        stroke(btn, C.AccentDim, 1, 0.75)

        local ico = Instance.new("TextLabel")
        ico.Size = UDim2.new(0, 36, 1, 0)
        ico.Position = UDim2.new(0, 8, 0, 0)
        ico.BackgroundTransparency = 1
        ico.Text = cat.icon
        ico.TextColor3 = C.Text2
        ico.Font = C.FontMed
        ico.TextSize = 10
        ico.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -34, 1, 0)
        lbl.Position = UDim2.new(0, 44, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cat.name
        lbl.TextColor3 = C.Text2
        lbl.Font = C.FontMed
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        sideBtns[cat.name] = {button = btn, label = lbl}

        btn.MouseEnter:Connect(function()
            if currentCat ~= cat.name then tw(btn, {BackgroundTransparency = 0.08}, C.SpeedFast) end
        end)
        btn.MouseLeave:Connect(function()
            if currentCat ~= cat.name then tw(btn, {BackgroundTransparency = 0.18}, C.SpeedFast) end
        end)
    end

    local profileTile = Instance.new("Frame")
    profileTile.Size = UDim2.new(1, -16, 0, 72)
    profileTile.Position = UDim2.new(0, 8, 1, -80)
    profileTile.BackgroundColor3 = C.Bg3
    profileTile.BackgroundTransparency = 0.1
    profileTile.BorderSizePixel = 0
    profileTile.Parent = sidebar
    corner(profileTile, UDim.new(0, 10))
    stroke(profileTile, C.AccentDim, 1, 0.8)

    local profileAvatar = Instance.new("ImageLabel")
    profileAvatar.Size = UDim2.new(0, 40, 0, 40)
    profileAvatar.Position = UDim2.new(0, 12, 0.5, -20)
    profileAvatar.BackgroundColor3 = C.Bg4
    profileAvatar.BackgroundTransparency = 0.05
    profileAvatar.BorderSizePixel = 0
    profileAvatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId)
    profileAvatar.Parent = profileTile
    corner(profileAvatar, UDim.new(1, 0))

    local profileName = Instance.new("TextLabel")
    profileName.Size = UDim2.new(1, -66, 0, 16)
    profileName.Position = UDim2.new(0, 58, 0, 16)
    profileName.BackgroundTransparency = 1
    profileName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    profileName.TextColor3 = C.Text1
    profileName.Font = C.FontMed
    profileName.TextSize = 10
    profileName.TextXAlignment = Enum.TextXAlignment.Left
    profileName.Parent = profileTile

    local profileTag = Instance.new("TextLabel")
    profileTag.Size = UDim2.new(1, -66, 0, 12)
    profileTag.Position = UDim2.new(0, 58, 0, 34)
    profileTag.BackgroundTransparency = 1
    profileTag.Text = "Home"
    profileTag.TextColor3 = C.Text3
    profileTag.Font = C.FontReg
    profileTag.TextSize = 9
    profileTag.TextXAlignment = Enum.TextXAlignment.Left
    profileTag.Parent = profileTile

    -- CONTENT AREA
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -104, 1, -54)
    content.Position = UDim2.new(0, 104, 0, 54)
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
        pg.Position = UDim2.new(0, 0, 0, 0)
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
        if name == "Home" then
            hdr.Size = UDim2.new(1, 0, 0, 0)
            hdr.Visible = false
        end

        pages[name] = pg
        return pg
    end

    local homePage = makePage("Home")
    local homeRoot = Instance.new("Frame")
    homeRoot.Size = UDim2.new(1, 0, 0, 0)
    homeRoot.BackgroundTransparency = 1
    homeRoot.BorderSizePixel = 0
    homeRoot.AutomaticSize = Enum.AutomaticSize.Y
    homeRoot.LayoutOrder = 1
    homeRoot.Parent = homePage

    local homeLayout = Instance.new("UIListLayout")
    homeLayout.Padding = UDim.new(0, 8)
    homeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    homeLayout.Parent = homeRoot

    local runStart = os.clock()
    local homeServerValue, homeOnlineValue, homeOfflineValue, homeAllValue
    local homeElapsedValue

    local function panel(frame, height, bg, trans)
        frame.Size = UDim2.new(1, 0, 0, height)
        frame.BackgroundColor3 = bg or C.Bg3
        frame.BackgroundTransparency = trans or 0.18
        frame.BorderSizePixel = 0
        corner(frame, UDim.new(0, 10))
        stroke(frame, C.AccentDim, 1, 0.75)
        return frame
    end

    local hero = panel(Instance.new("Frame"), 130, C.Bg3, 0.12)
    hero.LayoutOrder = 1
    hero.Parent = homeRoot

    local heroAvatar = Instance.new("ImageLabel")
    heroAvatar.Size = UDim2.new(0, 92, 0, 92)
    heroAvatar.Position = UDim2.new(0, 18, 0, 19)
    heroAvatar.BackgroundColor3 = C.Bg4
    heroAvatar.BackgroundTransparency = 0.04
    heroAvatar.BorderSizePixel = 0
    heroAvatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId)
    heroAvatar.Parent = hero
    corner(heroAvatar, UDim.new(0, 12))

    local heroName = Instance.new("TextLabel")
    heroName.Size = UDim2.new(1, -140, 0, 28)
    heroName.Position = UDim2.new(0, 126, 0, 34)
    heroName.BackgroundTransparency = 1
    heroName.Text = "Hello, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
    heroName.TextColor3 = C.Text1
    heroName.Font = C.Font
    heroName.TextSize = 22
    heroName.TextXAlignment = Enum.TextXAlignment.Left
    heroName.Parent = hero

    local heroSub = Instance.new("TextLabel")
    heroSub.Size = UDim2.new(1, -140, 0, 18)
    heroSub.Position = UDim2.new(0, 126, 0, 66)
    heroSub.BackgroundTransparency = 1
    heroSub.Text = "1nxs - Samurai Hub"
    heroSub.TextColor3 = C.Text2
    heroSub.Font = C.FontReg
    heroSub.TextSize = 12
    heroSub.TextXAlignment = Enum.TextXAlignment.Left
    heroSub.Parent = hero

    local heroChip = Instance.new("Frame")
    heroChip.Size = UDim2.new(0, 150, 0, 44)
    heroChip.Position = UDim2.new(1, -168, 0, 18)
    heroChip.BackgroundColor3 = C.Bg4
    heroChip.BackgroundTransparency = 0.2
    heroChip.BorderSizePixel = 0
    heroChip.Parent = hero
    corner(heroChip, UDim.new(0, 10))

    local heroChipTitle = Instance.new("TextLabel")
    heroChipTitle.Size = UDim2.new(1, -16, 0, 16)
    heroChipTitle.Position = UDim2.new(0, 8, 0, 7)
    heroChipTitle.BackgroundTransparency = 1
    heroChipTitle.Text = "Active session"
    heroChipTitle.TextColor3 = C.Text1
    heroChipTitle.Font = C.FontMed
    heroChipTitle.TextSize = 11
    heroChipTitle.TextXAlignment = Enum.TextXAlignment.Left
    heroChipTitle.Parent = heroChip

    homeElapsedValue = Instance.new("TextLabel")
    homeElapsedValue.Size = UDim2.new(1, -16, 0, 14)
    homeElapsedValue.Position = UDim2.new(0, 8, 0, 22)
    homeElapsedValue.BackgroundTransparency = 1
    homeElapsedValue.Text = "00:00:00"
    homeElapsedValue.TextColor3 = C.Text2
    homeElapsedValue.Font = C.FontReg
    homeElapsedValue.TextSize = 10
    homeElapsedValue.TextXAlignment = Enum.TextXAlignment.Left
    homeElapsedValue.Parent = heroChip

    local row1 = Instance.new("Frame")
    row1.Size = UDim2.new(1, 0, 0, 88)
    row1.BackgroundTransparency = 1
    row1.BorderSizePixel = 0
    row1.LayoutOrder = 2
    row1.Parent = homeRoot

    local row1Layout = Instance.new("UIGridLayout")
    row1Layout.CellSize = UDim2.new(0.5, -4, 1, 0)
    row1Layout.CellPadding = UDim2.new(0, 8, 0, 0)
    row1Layout.FillDirectionMaxCells = 2
    row1Layout.SortOrder = Enum.SortOrder.LayoutOrder
    row1Layout.Parent = row1

    local serverCard = panel(Instance.new("Frame"), 88, C.Bg3, 0.2)
    serverCard.Parent = row1

    local serverAccent = Instance.new("Frame")
    serverAccent.Size = UDim2.new(0, 4, 1, -20)
    serverAccent.Position = UDim2.new(0, 12, 0, 10)
    serverAccent.BackgroundColor3 = C.Green
    serverAccent.BorderSizePixel = 0
    serverAccent.Parent = serverCard
    corner(serverAccent, UDim.new(1, 0))

    local serverTitle = Instance.new("TextLabel")
    serverTitle.Size = UDim2.new(1, -34, 0, 18)
    serverTitle.Position = UDim2.new(0, 24, 0, 14)
    serverTitle.BackgroundTransparency = 1
    serverTitle.Text = "In server for"
    serverTitle.TextColor3 = C.Text1
    serverTitle.Font = C.FontMed
    serverTitle.TextSize = 12
    serverTitle.TextXAlignment = Enum.TextXAlignment.Left
    serverTitle.Parent = serverCard

    homeServerValue = Instance.new("TextLabel")
    homeServerValue.Size = UDim2.new(1, -34, 0, 18)
    homeServerValue.Position = UDim2.new(0, 24, 0, 36)
    homeServerValue.BackgroundTransparency = 1
    homeServerValue.Text = "00:00:00"
    homeServerValue.TextColor3 = C.Text2
    homeServerValue.Font = C.FontReg
    homeServerValue.TextSize = 11
    homeServerValue.TextXAlignment = Enum.TextXAlignment.Left
    homeServerValue.Parent = serverCard

    local joinCard = panel(Instance.new("Frame"), 88, C.Bg3, 0.2)
    joinCard.Parent = row1
    local joinAccent = Instance.new("Frame")
    joinAccent.Size = UDim2.new(0, 4, 1, -20)
    joinAccent.Position = UDim2.new(0, 12, 0, 10)
    joinAccent.BackgroundColor3 = C.Accent
    joinAccent.BorderSizePixel = 0
    joinAccent.Parent = joinCard
    corner(joinAccent, UDim.new(1, 0))

    local joinTitle = Instance.new("TextLabel")
    joinTitle.Size = UDim2.new(1, -34, 0, 18)
    joinTitle.Position = UDim2.new(0, 24, 0, 14)
    joinTitle.BackgroundTransparency = 1
    joinTitle.Text = "Join Script"
    joinTitle.TextColor3 = C.Text1
    joinTitle.Font = C.FontMed
    joinTitle.TextSize = 12
    joinTitle.TextXAlignment = Enum.TextXAlignment.Left
    joinTitle.Parent = joinCard

    local joinDesc = Instance.new("TextLabel")
    joinDesc.Size = UDim2.new(1, -34, 0, 18)
    joinDesc.Position = UDim2.new(0, 24, 0, 36)
    joinDesc.BackgroundTransparency = 1
    joinDesc.Text = "Tap to copy join script"
    joinDesc.TextColor3 = C.Text2
    joinDesc.Font = C.FontReg
    joinDesc.TextSize = 11
    joinDesc.TextXAlignment = Enum.TextXAlignment.Left
    joinDesc.Parent = joinCard

    local row2 = Instance.new("Frame")
    row2.Size = UDim2.new(1, 0, 0, 150)
    row2.BackgroundTransparency = 1
    row2.BorderSizePixel = 0
    row2.LayoutOrder = 3
    row2.Parent = homeRoot

    local row2Layout = Instance.new("UIGridLayout")
    row2Layout.CellSize = UDim2.new(0.5, -4, 1, 0)
    row2Layout.CellPadding = UDim2.new(0, 8, 0, 0)
    row2Layout.FillDirectionMaxCells = 2
    row2Layout.SortOrder = Enum.SortOrder.LayoutOrder
    row2Layout.Parent = row2

    local discordCard = panel(Instance.new("Frame"), 150, C.Bg3, 0.2)
    discordCard.Parent = row2
    local discordGrad = Instance.new("UIGradient")
    discordGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(78, 90, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 28)),
    })
    discordGrad.Rotation = 0
    discordGrad.Parent = discordCard

    local discordTitle = Instance.new("TextLabel")
    discordTitle.Size = UDim2.new(1, -20, 0, 24)
    discordTitle.Position = UDim2.new(0, 16, 0, 18)
    discordTitle.BackgroundTransparency = 1
    discordTitle.Text = "Discord"
    discordTitle.TextColor3 = C.Text1
    discordTitle.Font = C.Font
    discordTitle.TextSize = 22
    discordTitle.TextXAlignment = Enum.TextXAlignment.Left
    discordTitle.Parent = discordCard

    local discordDesc = Instance.new("TextLabel")
    discordDesc.Size = UDim2.new(1, -20, 0, 22)
    discordDesc.Position = UDim2.new(0, 16, 0, 52)
    discordDesc.BackgroundTransparency = 1
    discordDesc.Text = "Click to join Discord"
    discordDesc.TextColor3 = C.AccentBright
    discordDesc.Font = C.FontReg
    discordDesc.TextSize = 14
    discordDesc.TextXAlignment = Enum.TextXAlignment.Left
    discordDesc.Parent = discordCard

    local discordClick = Instance.new("TextButton")
    discordClick.Size = UDim2.new(1, 0, 1, 0)
    discordClick.BackgroundTransparency = 1
    discordClick.Text = ""
    discordClick.Parent = discordCard
    discordClick.MouseButton1Click:Connect(function()
        local invite = "https://discord.gg/EAU6kf5CMA"
        if type(setclipboard) == "function" then
            pcall(setclipboard, invite)
            notify("Discord invite copied", C.Green, 3)
        else
            notify("Discord invite: " .. invite, C.AccentBright, 4)
        end
    end)

    local statsCard = panel(Instance.new("Frame"), 150, C.Bg3, 0.2)
    statsCard.Parent = row2

    local statsLayout = Instance.new("UIGridLayout")
    statsLayout.CellSize = UDim2.new(0.5, -4, 0.5, -4)
    statsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    statsLayout.FillDirectionMaxCells = 2
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statsLayout.Parent = statsCard

    local function makeStat(parent, title)
        local stat = Instance.new("Frame")
        stat.Size = UDim2.new(1, 0, 1, 0)
        stat.BackgroundColor3 = C.Bg4
        stat.BackgroundTransparency = 0.18
        stat.BorderSizePixel = 0
        stat.Parent = parent
        corner(stat, UDim.new(0, 8))
        local statTitle = Instance.new("TextLabel")
        statTitle.Size = UDim2.new(1, -16, 0, 16)
        statTitle.Position = UDim2.new(0, 8, 0, 10)
        statTitle.BackgroundTransparency = 1
        statTitle.Text = title
        statTitle.TextColor3 = C.Text1
        statTitle.Font = C.FontMed
        statTitle.TextSize = 11
        statTitle.TextXAlignment = Enum.TextXAlignment.Left
        statTitle.Parent = stat
        local statValue = Instance.new("TextLabel")
        statValue.Size = UDim2.new(1, -16, 0, 16)
        statValue.Position = UDim2.new(0, 8, 0, 30)
        statValue.BackgroundTransparency = 1
        statValue.Text = "0"
        statValue.TextColor3 = C.Text2
        statValue.Font = C.FontReg
        statValue.TextSize = 11
        statValue.TextXAlignment = Enum.TextXAlignment.Left
        statValue.Parent = stat
        return statValue
    end

    homeServerValue.Text = "0 players"
    homeOnlineValue = makeStat(statsCard, "Online")
    homeOfflineValue = makeStat(statsCard, "Offline")
    homeAllValue = makeStat(statsCard, "All")
    local inServerValue = makeStat(statsCard, "In Server")

    local function updateHomeStats()
        local elapsed = math.max(0, math.floor(os.clock() - runStart))
        local hh = math.floor(elapsed / 3600)
        local mm = math.floor((elapsed % 3600) / 60)
        local ss = elapsed % 60
        local elapsedText = string.format("%02d:%02d:%02d", hh, mm, ss)
        if homeElapsedValue then homeElapsedValue.Text = elapsedText end
        if inServerValue then inServerValue.Text = tostring(#Players:GetPlayers()) .. " players" end

        local online, offline, total = 0, 0, 0
        pcall(function()
            local friends = LocalPlayer:GetFriendsOnline()
            if type(friends) == "table" then
                for _, friend in ipairs(friends) do
                    total += 1
                    if friend.IsOnline then
                        online += 1
                    else
                        offline += 1
                    end
                end
            end
        end)
        if homeOnlineValue then homeOnlineValue.Text = tostring(online) .. " friends" end
        if homeOfflineValue then homeOfflineValue.Text = tostring(offline) .. " friends" end
        if homeAllValue then homeAllValue.Text = tostring(total) .. " friends" end
        if homeServerValue then homeServerValue.Text = elapsedText end
    end

    updateHomeStats()
    task.spawn(function()
        while Hub and Hub.Parent do
            task.wait(1)
            updateHomeStats()
        end
    end)

    local function sanitizeProfileName(name)
        name = tostring(name or "")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        name = name:gsub("[^%w%-%_ ]", "")
        name = name:gsub("%s+", "_")
        if #name > 24 then name = name:sub(1, 24) end
        return name
    end

    local function canUseFileApi()
        return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    end

    local function profilePath(name)
        return "1nxs_hub_profile_" .. sanitizeProfileName(name) .. ".json"
    end

    local AUTOLOAD_FILE = "1nxs_hub_autoload.json"

    local function snapshotFeatures()
        local out = {}
        for featureName, enabled in pairs(S.Features) do
            out[featureName] = enabled and true or false
        end
        return out
    end

    local function saveProfile(name)
        if not canUseFileApi() then return false, "File API unavailable" end
        local clean = sanitizeProfileName(name)
        if clean == "" then return false, "Enter a profile name" end
        local payload = {name = clean, features = snapshotFeatures(), savedAt = os.time()}
        writefile(profilePath(clean), HttpService:JSONEncode(payload))
        return true, clean
    end

    local function loadProfile(name, silent)
        if not canUseFileApi() then return false, "File API unavailable" end
        local clean = sanitizeProfileName(name)
        if clean == "" then return false, "Enter a profile name" end
        local path = profilePath(clean)
        if not isfile(path) then return false, "Profile not found" end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(data) ~= "table" or type(data.features) ~= "table" then
            return false, "Profile file is invalid"
        end
        S._configLoading = true
        for featureName, ctrl in pairs(S._toggleControls) do
            local target = data.features[featureName]
            if target ~= nil then
                ctrl.set(target, true)
            end
        end
        S._configLoading = false
        updateCount()
        if not silent then
            notify("Loaded profile: " .. clean, C.Green, 3)
        end
        return true, clean
    end

    local function deleteProfile(name)
        if not canUseFileApi() then return false, "File API unavailable" end
        local clean = sanitizeProfileName(name)
        if clean == "" then return false, "Enter a profile name" end
        local path = profilePath(clean)
        if not isfile(path) then return false, "Profile not found" end
        delfile(path)
        return true, clean
    end

    local function saveAutoload(name, enabled)
        if not canUseFileApi() then return false, "File API unavailable" end
        local clean = sanitizeProfileName(name)
        if clean == "" then return false, "Enter a profile name" end
        writefile(AUTOLOAD_FILE, HttpService:JSONEncode({enabled = enabled and true or false, profile = clean}))
        return true, clean
    end

    local function loadAutoload()
        if not canUseFileApi() or not isfile(AUTOLOAD_FILE) then return nil end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(AUTOLOAD_FILE))
        end)
        if ok and type(data) == "table" then
            return data
        end
        return nil
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
                    tw(nm, {TextColor3 = C.AccentBright}, C.SpeedFast)
                else
                    tw(pill, {BackgroundColor3 = C.Bg4}, C.SpeedFast)
                    tw(circ, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = C.Text2}, C.SpeedFast)
                    tw(nm, {TextColor3 = C.Text1}, C.SpeedFast)
                end
            else
                pill.BackgroundColor3 = v and C.Accent or C.Bg4
                circ.Position = v and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                circ.BackgroundColor3 = v and C.Text1 or C.Text2
                nm.TextColor3 = v and C.AccentBright or C.Text1
            end
        end

        local function setState(v, silent)
            v = not not v
            if on == v then
                S.Features[name] = on
                setVisual(on, false)
                updateCount()
                return
            end
            on = v
            S.Features[name] = on
            setVisual(on, true)
            updateCount()
            local ok, err = pcall(callback, on)
            if not ok then
                warn("[Hub] Error in " .. name .. ":", err)
                if not silent then
                    notify("ÔÜá " .. name .. " error", C.Red, 4)
                end
            elseif not silent then
                notify(name .. " ÔåÆ " .. (on and "ON" or "OFF"), on and C.Green or C.Text3, 2)
            end
        end

        S._toggleControls[name] = {
            get = function() return on end,
            set = setState,
        }

        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.Parent = cont

        click.MouseButton1Click:Connect(function()
            setState(not on, false)
        end)

        return cont
    end

    --   PAGE: COMBAT
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local combatPage = makePage("Combat")

    local remotes = (ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events"))
    local blockEvent = remotes and remotes:FindFirstChild("BlockEvent")
    local useAbility = remotes and remotes:FindFirstChild("UseAbility")

    local function findDashEvent()
        local char = LocalPlayer.Character
        if not char then return nil end
        for _, t in pairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local de = t:FindFirstChild("DashEvent")
                if de and de:IsA("RemoteEvent") then return de end
            end
        end
        return nil
    end

    local function fireDash()
        local dashEvent = findDashEvent()
        if not dashEvent then return false end
        local char = LocalPlayer.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local target, bestDist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) then
                local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                if thrp then
                    local d = (hrp.Position - thrp.Position).Magnitude
                    if d < bestDist and d < 130 then bestDist = d target = thrp end
                end
            end
        end
        if target then
            local aimDir = (target.Position - hrp.Position).Unit
            dashEvent:FireServer(1.0, true, aimDir)
            return true
        end
        return false
    end

    makeToggle(combatPage, "Auto-Dash", "Auto-dash at nearest enemy (full charge)", 1, function(on)
        rmConn("autodash")
        if not on then return end
        addConn("autodash", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto-Dash"] then return end
            fireDash()
        end))
    end)

    makeToggle(combatPage, "Auto-Parry", "Auto-block when enemy dashes nearby", 2, function(on)
        rmConn("autoparry")
        if not on then return end
        addConn("autoparry", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto-Parry"] or not blockEvent then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local myPos = hrp.Position
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) then
                    local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if not thrp then continue end
                    local dir = myPos - thrp.Position
                    local dist = dir.Magnitude
                    if dist < 20 then
                        blockEvent:FireServer()
                        break
                    end
                    if dist < 55 then
                        local vel = thrp.Velocity
                        local speed = vel.Magnitude
                        if speed > 30 then
                            local toward = dir.Unit
                            local velDir = vel.Unit
                            if velDir:Dot(toward) > 0.6 then
                                blockEvent:FireServer()
                                break
                            end
                        end
                    end
                end
            end
        end))
    end)

    makeToggle(combatPage, "Aimbot", "Auto-aim camera at nearest enemy", 4, function(on)
        rmConn("aimbot")
        if not on then return end
        addConn("aimbot", RunService.RenderStepped:Connect(function()
            if not S.Features["Aimbot"] then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local target, bestDist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) then
                    local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if thrp then
                        local d = (hrp.Position - thrp.Position).Magnitude
                        if d < bestDist and d < 130 then bestDist = d target = thrp end
                    end
                end
            end
            if target then
                local goal = CFrame.new(Camera.CFrame.Position, target.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goal, 0.25)
            end
        end))
    end)

    makeToggle(combatPage, "Infinite Jump", "Jump in air (multi-jump) ÔÇö 0.5s cooldown", 5, function(on)
        rmConn("infjump")
        if not on then return end
        local UIS = UserInputService
        local lastJump = 0
        addConn("infjump", UIS.JumpRequest:Connect(function()
            if not S.Features["Infinite Jump"] then return end
            local now = tick()
            if now - lastJump < 0.5 then return end
            lastJump = now
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    end)

    makeToggle(combatPage, "Berzerk", "Remove dash cooldown (client-side)", 6, function(on)
        local plr = LocalPlayer
        if on then
            plr:SetAttribute("Berzerk", true)
            notify("ÔÜí Berzerk mode activated", C.Yellow, 3)
        else
            plr:SetAttribute("Berzerk", nil)
            notify("ÔÜí Berzerk deactivated", C.Text3, 3)
        end
    end)

    makeToggle(combatPage, "Anti-Death", "Keep health max and auto-respawn", 7, function(on)
        rmConn("antideath")
        rmConn("antideath_respawn")
        if not on then return end
        addConn("antideath", RunService.Heartbeat:Connect(function()
            if not S.Features["Anti-Death"] then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
        end))
        addConn("antideath_respawn", LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
        end))
    end)

    local mechHooked = false
    makeToggle(combatPage, "Mechanic", "Hook dash release to cancel cooldown", 9, function(on)
        if not on then
            notify("Mechanic deactivated", C.Text3, 3)
            return
        end
        if not mechHooked then
            local ch = require(ReplicatedStorage.ToolModules.ChargeHandler)
            if ch and type(ch.onReleased) == "function" then
                local orig = hookfunction(ch.onReleased, function(charge, perfect)
                    if S.Features["Mechanic"] then
                        ch.cancel()
                        return
                    end
                    return orig(charge, perfect)
                end)
                mechHooked = true
                notify("Mechanic activated (dash blocked)", C.Accent, 3)
            else
                notify("Mechanic: no onReleased hook", C.Red, 4)
            end
        end
    end)

    makeToggle(combatPage, "Auto-Ability", "Auto-use special ability on cooldown", 10, function(on)
        rmConn("autoabil")
        if not on or not useAbility then return end
        addConn("autoabil", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto-Ability"] then return end
            local plr = LocalPlayer
            local ability = plr:GetAttribute("Ability")
            if ability and ability ~= "" then
                useAbility:FireServer("SpecialAbility")
            end
        end))
    end)
    --   PAGE: ESP
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local espPage = makePage("ESP")

    makeToggle(espPage, "Player Highlight", "Highlight all players through walls", 1, function(on)
        clearHL("players")
        rmConn("plr_esp")
        if not on then return end
        S.Highlights["players"] = {}
        S.Billboards["players"] = {}

        local function scan()
            clearHL("players")
            S.Highlights["players"] = {}
            S.Billboards["players"] = {}
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = C.Red
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = C.Red
                        hl.OutlineTransparency = 0.1
                        hl.Adornee = p.Character
                        hl.Parent = CoreGui
                        table.insert(S.Highlights["players"], hl)

                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 110, 0, 26)
                        bb.StudsOffset = Vector3.new(0, 3.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = hrp
                        bb.Parent = CoreGui

                        local bg = Instance.new("Frame")
                        bg.Size = UDim2.new(1, 0, 1, 0)
                        bg.BackgroundColor3 = C.Bg1
                        bg.BackgroundTransparency = 0.15
                        bg.BorderSizePixel = 0
                        bg.Parent = bb
                        corner(bg, UDim.new(0, 4))
                        stroke(bg, C.Red, 1, 0.4)

                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundTransparency = 1
                        l.Text = "­ƒùí " .. p.Name
                        l.TextColor3 = C.Red
                        l.Font = C.FontMed
                        l.TextSize = 11
                        l.Parent = bb
                        table.insert(S.Billboards["players"], bb)
                    end
                end
            end
        end
        scan()
        addConn("plr_esp", RunService.Heartbeat:Connect(function()
            if not S.Features["Player Highlight"] then return end
            local now = tick()
            if not S._lastPlrScan or now - S._lastPlrScan >= 3 then
                S._lastPlrScan = now
                pcall(scan)
            end
        end))
    end)

    makeToggle(espPage, "Team Rings", "Color rings below all players", 2, function(on)
        clearHL("rings")
        rmConn("ring_loop")
        if not on then return end
        S.Highlights["rings"] = {}

        local function scan()
            clearHL("rings")
            S.Highlights["rings"] = {}
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local ring = Instance.new("Part")
                        ring.Name = "TeamRing"
                        ring.Size = Vector3.new(6, 0.2, 6)
                        ring.Shape = Enum.PartType.Cylinder
                        ring.Material = Enum.Material.Neon
                        ring.Color = Color3.fromRGB(240, 80, 80)
                        ring.BrickColor = BrickColor.new("Bright red")
                        ring.Anchored = true
                        ring.CanCollide = false
                        ring.Transparency = 0.3
                        ring.Parent = CoreGui
                        local ma = Instance.new("ManualWeld")
                        ma.Part0 = hrp
                        ma.Part1 = ring
                        ma.C1 = CFrame.new(0, -3, 0)
                        ma.Parent = ring
                        table.insert(S.Highlights["rings"], ring)
                    end
                end
            end
        end
        scan()
        addConn("ring_loop", RunService.Heartbeat:Connect(function()
            if not S.Features["Team Rings"] then return end
            local now = tick()
            if not S._lastRingScan or now - S._lastRingScan >= 2 then
                S._lastRingScan = now
                pcall(scan)
            end
        end))
    end)

    makeToggle(espPage, "Show All Players", "Show all players (spectate mode)", 3, function(on)
        rmConn("showall")
        if not on then return end
        addConn("showall", RunService.Heartbeat:Connect(function()
            if not S.Features["Show All Players"] then return end
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then
                    p.Character:SetAttribute("Visible", true)
                end
            end
        end))
    end)

    makeToggle(espPage, "Distance ESP", "Show distance to enemies", 4, function(on)
        rmConn("dist_esp")
        if not on then return end
        addConn("dist_esp", RunService.Heartbeat:Connect(function()
            if not S.Features["Distance ESP"] then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, p in pairs(Players:GetPlayers()) do
                if isEnemy(p) then
                    local thrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if thrp then
                        local dist = (hrp.Position - thrp.Position).Magnitude
                        p:SetAttribute("DistanceLabel", math.floor(dist))
                    end
                end
            end
        end))
    end)

    --   PAGE: MATCH
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local matchPage = makePage("Match")

    makeToggle(matchPage, "Auto-Join Queue", "Automatically join match queue", 1, function(on)
        rmConn("autoqueue")
        if not on then return end
        local joinReq = remotes and remotes:FindFirstChild("JoinQueueRequest")
        addConn("autoqueue", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto-Join Queue"] or not joinReq then return end
            if not S._matchInProgress and not S._queueJoined then
                joinReq:FireServer()
                S._queueJoined = true
                notify("­ƒÄ« Joined queue", C.Accent, 3)
            end
        end))
    end)

    makeToggle(matchPage, "Auto-Vote Map", "Auto-vote first map when voting starts", 2, function(on)
        rmConn("autovote")
        if not on then return end
        local mapVote = remotes and remotes:FindFirstChild("MapVote")
        local voted = false
        addConn("autovote", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto-Vote Map"] or not mapVote or voted then return end
            local voteGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("MapVote")
            if voteGui then
                local firstBtn = voteGui:FindFirstChildWhichIsA("TextButton")
                if firstBtn then
                    mapVote:FireServer(firstBtn.Name)
                    voted = true
                end
            end
        end))
    end)

    makeToggle(matchPage, "Auto-Spectate", "Auto-spectate after death", 3, function(on)
        rmConn("autospec")
        if not on then return end
        addConn("autospec", LocalPlayer.CharacterAdded:Connect(function()
            task.wait(3)
            local respawnGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Respawn")
            if respawnGui then
                local specBtn = respawnGui:FindFirstChildWhichIsA("TextButton")
                if specBtn then
                    specBtn:FindFirstChildOfClass("LocalScript"):Destroy()
                end
            end
        end))
    end)

    -- Match info display
    local matchInfoFrame = Instance.new("Frame")
    matchInfoFrame.Size = UDim2.new(1, 0, 0, 120)
    matchInfoFrame.BackgroundColor3 = C.Bg3
    matchInfoFrame.BackgroundTransparency = 0.25
    matchInfoFrame.BorderSizePixel = 0
    matchInfoFrame.LayoutOrder = 10
    matchInfoFrame.Parent = matchPage
    corner(matchInfoFrame, UDim.new(0, 8))

    local matchInfoTitle = Instance.new("TextLabel")
    matchInfoTitle.Size = UDim2.new(1, -16, 0, 16)
    matchInfoTitle.Position = UDim2.new(0, 10, 0, 6)
    matchInfoTitle.BackgroundTransparency = 1
    matchInfoTitle.Text = "MATCH INFO"
    matchInfoTitle.TextColor3 = C.AccentDim
    matchInfoTitle.Font = C.Font
    matchInfoTitle.TextSize = 9
    matchInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
    matchInfoTitle.Parent = matchInfoFrame

    local matchInfoGrid = Instance.new("UIGridLayout")
    matchInfoGrid.CellSize = UDim2.new(0.5, -6, 0, 22)
    matchInfoGrid.CellPadding = UDim2.new(0, 6, 0, 4)
    matchInfoGrid.SortOrder = Enum.SortOrder.LayoutOrder
    matchInfoGrid.Parent = matchInfoFrame

    local function makeMatchStat(parent, text, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = C.Bg4
        f.BackgroundTransparency = 0.2
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        f.Parent = parent
        corner(f, UDim.new(0, 4))
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = C.Text2
        l.Font = C.FontReg
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        return l
    end

    local matchStatusLabel = makeMatchStat(matchInfoFrame, "Status: Idle", 1)
    local matchRoundLabel = makeMatchStat(matchInfoFrame, "Round: -", 2)
    local matchKillsLabel = makeMatchStat(matchInfoFrame, "Kills: 0", 3)
    local matchDeathsLabel = makeMatchStat(matchInfoFrame, "Deaths: 0", 4)

    addConn("matchinfo_upd", RunService.Heartbeat:Connect(function()
        local status = S._matchInProgress and "Fighting" or "Idle"
        matchStatusLabel.Text = "Status: " .. status
        matchRoundLabel.Text = "Round: " .. S._currentRound .. "/" .. S._maxRounds
        matchKillsLabel.Text = "Kills: " .. (S._myKills or 0)
        matchDeathsLabel.Text = "Deaths: " .. (S._myDeaths or 0)
    end))
    --   PAGE: SWORDS
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local swordsPage = makePage("Swords")

    local swordsTitle = Instance.new("TextLabel")
    swordsTitle.Size = UDim2.new(1, 0, 0, 16)
    swordsTitle.BackgroundTransparency = 1
    swordsTitle.Text = "SWORD INVENTORY"
    swordsTitle.TextColor3 = C.AccentDim
    swordsTitle.Font = C.Font
    swordsTitle.TextSize = 9
    swordsTitle.TextXAlignment = Enum.TextXAlignment.Left
    swordsTitle.LayoutOrder = 0
    swordsTitle.Parent = swordsPage

    for i, sword in ipairs(SwordDB) do
        local gf = Instance.new("Frame")
        gf.Size = UDim2.new(1, 0, 0, 36)
        gf.BackgroundColor3 = C.Bg3
        gf.BackgroundTransparency = 0.4
        gf.BorderSizePixel = 0
        gf.LayoutOrder = i
        gf.Parent = swordsPage
        corner(gf, UDim.new(0, 6))
        stroke(gf, Rarities[sword.rarity] or C.AccentDim, 1, 0.65)

        local rarityCol = Rarities[sword.rarity] or C.Text2
        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(0.4, 0, 0, 16)
        nm.Position = UDim2.new(0, 10, 0, 3)
        nm.BackgroundTransparency = 1
        nm.Text = sword.name
        nm.TextColor3 = rarityCol
        nm.Font = C.FontMed
        nm.TextSize = 11
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = gf

        local rarityLbl = Instance.new("TextLabel")
        rarityLbl.Size = UDim2.new(0.25, 0, 0, 12)
        rarityLbl.Position = UDim2.new(0, 10, 0, 20)
        rarityLbl.BackgroundTransparency = 1
        rarityLbl.Text = sword.rarity
        rarityLbl.TextColor3 = rarityCol
        rarityLbl.Font = C.FontReg
        rarityLbl.TextSize = 8
        rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
        rarityLbl.Parent = gf

        local rarityLbl2 = Instance.new("TextLabel")
        rarityLbl2.Size = UDim2.new(0.3, 0, 0, 14)
        rarityLbl2.Position = UDim2.new(0.35, 0, 0.5, -7)
        rarityLbl2.BackgroundTransparency = 1
        rarityLbl2.Text = sword.rarity:upper()
        rarityLbl2.TextColor3 = rarityCol
        rarityLbl2.Font = C.FontReg
        rarityLbl2.TextSize = 8
        rarityLbl2.Parent = gf

        local equipBtn = Instance.new("TextButton")
        equipBtn.Size = UDim2.new(0, 60, 0, 24)
        equipBtn.Position = UDim2.new(1, -68, 0.5, -12)
        equipBtn.BackgroundColor3 = rarityCol
        equipBtn.BackgroundTransparency = 0.35
        equipBtn.BorderSizePixel = 0
        equipBtn.Text = "Equip"
        equipBtn.TextColor3 = C.Text1
        equipBtn.Font = C.FontMed
        equipBtn.TextSize = 10
        equipBtn.Parent = gf
        corner(equipBtn, UDim.new(0, 5))

        local eqRemote = remotes and remotes:FindFirstChild("EquipEvent")
        equipBtn.MouseButton1Click:Connect(function()
            if eqRemote then
                eqRemote:FireServer("WeaponEquip", sword.name)
                notify("­ƒùí Equipped " .. sword.name, rarityCol, 3)
            end
        end)
    end

    --   PAGE: ABILITIES
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local abilsPage = makePage("Abilities")

    local abilsTitle = Instance.new("TextLabel")
    abilsTitle.Size = UDim2.new(1, 0, 0, 16)
    abilsTitle.BackgroundTransparency = 1
    abilsTitle.Text = "SPECIAL ABILITIES"
    abilsTitle.TextColor3 = C.AccentDim
    abilsTitle.Font = C.Font
    abilsTitle.TextSize = 9
    abilsTitle.TextXAlignment = Enum.TextXAlignment.Left
    abilsTitle.LayoutOrder = 0
    abilsTitle.Parent = abilsPage

    for i, abil in ipairs(AbilityDataDB) do
        local gf = Instance.new("Frame")
        gf.Size = UDim2.new(1, 0, 0, 36)
        gf.BackgroundColor3 = C.Bg3
        gf.BackgroundTransparency = 0.4
        gf.BorderSizePixel = 0
        gf.LayoutOrder = i
        gf.Parent = abilsPage
        corner(gf, UDim.new(0, 6))

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(0.35, 0, 0, 16)
        nm.Position = UDim2.new(0, 10, 0, 3)
        nm.BackgroundTransparency = 1
        nm.Text = abil.name
        nm.TextColor3 = C.Text1
        nm.Font = C.FontMed
        nm.TextSize = 11
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = gf

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(0.35, 0, 0, 12)
        descLbl.Position = UDim2.new(0, 10, 0, 20)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = abil.desc
        descLbl.TextColor3 = C.Text3
        descLbl.Font = C.FontReg
        descLbl.TextSize = 8
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = gf

        local priceTxt = Instance.new("TextLabel")
        priceTxt.Size = UDim2.new(0.2, 0, 0, 14)
        priceTxt.Position = UDim2.new(0.55, 0, 0.5, -7)
        priceTxt.BackgroundTransparency = 1
        priceTxt.Text = abil.robux and tostring(abil.keysPrice) .. " R$" or (abil.keysPrice == 0 and "Free" or tostring(abil.keysPrice) .. " Keys")
        priceTxt.TextColor3 = abil.robux and C.Green or C.Yellow
        priceTxt.Font = C.FontReg
        priceTxt.TextSize = 8
        priceTxt.Parent = gf

        local selectBtn = Instance.new("TextButton")
        selectBtn.Size = UDim2.new(0, 60, 0, 24)
        selectBtn.Position = UDim2.new(1, -68, 0.5, -12)
        selectBtn.BackgroundColor3 = C.Purple
        selectBtn.BackgroundTransparency = 0.35
        selectBtn.BorderSizePixel = 0
        selectBtn.Text = "Select"
        selectBtn.TextColor3 = C.Text1
        selectBtn.Font = C.FontMed
        selectBtn.TextSize = 10
        selectBtn.Parent = gf
        corner(selectBtn, UDim.new(0, 5))

        local abilShopEvent = remotes and remotes:FindFirstChild("AbilityShopEvent")
        selectBtn.MouseButton1Click:Connect(function()
            if abilShopEvent then
                abilShopEvent:FireServer(abil.name, true, true)
                notify("ÔÜí Equipped " .. abil.name, C.Purple, 3)
            end
        end)
    end

    --   PAGE: FINISHERS
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local finishersPage = makePage("Finishers")

    local finishersTitle = Instance.new("TextLabel")
    finishersTitle.Size = UDim2.new(1, 0, 0, 16)
    finishersTitle.BackgroundTransparency = 1
    finishersTitle.Text = "FINISHER MOVES"
    finishersTitle.TextColor3 = C.AccentDim
    finishersTitle.Font = C.Font
    finishersTitle.TextSize = 9
    finishersTitle.TextXAlignment = Enum.TextXAlignment.Left
    finishersTitle.LayoutOrder = 0
    finishersTitle.Parent = finishersPage

    for i, fin in ipairs(FinisherDataDB) do
        local gf = Instance.new("Frame")
        gf.Size = UDim2.new(1, 0, 0, 36)
        gf.BackgroundColor3 = C.Bg3
        gf.BackgroundTransparency = 0.4
        gf.BorderSizePixel = 0
        gf.LayoutOrder = i
        gf.Parent = finishersPage
        corner(gf, UDim.new(0, 6))

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(0.35, 0, 0, 16)
        nm.Position = UDim2.new(0, 10, 0, 3)
        nm.BackgroundTransparency = 1
        nm.Text = fin.name
        nm.TextColor3 = C.Text1
        nm.Font = C.FontMed
        nm.TextSize = 11
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = gf

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(0.35, 0, 0, 12)
        descLbl.Position = UDim2.new(0, 10, 0, 20)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = fin.desc
        descLbl.TextColor3 = C.Text3
        descLbl.Font = C.FontReg
        descLbl.TextSize = 8
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = gf

        local priceTxt = Instance.new("TextLabel")
        priceTxt.Size = UDim2.new(0.2, 0, 0, 14)
        priceTxt.Position = UDim2.new(0.55, 0, 0.5, -7)
        priceTxt.BackgroundTransparency = 1
        local priceStr = fin.type == "Robux" and tostring(fin.amount) .. " R$" or (fin.type == "Wins" and tostring(fin.amount) .. " Wins" or tostring(fin.amount) .. " Keys")
        priceTxt.Text = priceStr
        priceTxt.TextColor3 = fin.type == "Robux" and C.Green or (fin.type == "Wins" and C.Yellow or C.Accent)
        priceTxt.Font = C.FontReg
        priceTxt.TextSize = 8
        priceTxt.Parent = gf

        local equipBtn = Instance.new("TextButton")
        equipBtn.Size = UDim2.new(0, 60, 0, 24)
        equipBtn.Position = UDim2.new(1, -68, 0.5, -12)
        equipBtn.BackgroundColor3 = C.Purple
        equipBtn.BackgroundTransparency = 0.35
        equipBtn.BorderSizePixel = 0
        equipBtn.Text = "Equip"
        equipBtn.TextColor3 = C.Text1
        equipBtn.Font = C.FontMed
        equipBtn.TextSize = 10
        equipBtn.Parent = gf
        corner(equipBtn, UDim.new(0, 5))

        local finisherShopEvent = remotes and remotes:FindFirstChild("FinisherShopEvent")
        equipBtn.MouseButton1Click:Connect(function()
            if finisherShopEvent then
                finisherShopEvent:FireServer("Equip", fin.name)
                notify("­ƒÆÑ Equipped finisher " .. fin.name, C.Purple, 3)
            end
        end)
    end

    --   PAGE: VISUAL
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local visPage = makePage("Visual")

    makeToggle(visPage, "Fullbright", "Max brightness, clear vision", 1, function(on)
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
        elseif S._origLight then
            for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end
        end
    end)

    -- FOV Slider
    local fovFrame = Instance.new("Frame")
    fovFrame.Size = UDim2.new(1, 0, 0, 44)
    fovFrame.BackgroundColor3 = C.Bg3
    fovFrame.BackgroundTransparency = 0.45
    fovFrame.BorderSizePixel = 0
    fovFrame.LayoutOrder = 2
    fovFrame.Parent = visPage
    corner(fovFrame, UDim.new(0, 8))

    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(0.6, 0, 0, 16)
    fovLabel.Position = UDim2.new(0, 12, 0, 6)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "Field of View"
    fovLabel.TextColor3 = C.Text1
    fovLabel.Font = C.FontMed
    fovLabel.TextSize = 12
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = fovFrame

    local fovValue = Instance.new("TextLabel")
    fovValue.Size = UDim2.new(0.3, 0, 0, 16)
    fovValue.Position = UDim2.new(0.7, 0, 0, 6)
    fovValue.BackgroundTransparency = 1
    fovValue.Text = "70"
    fovValue.TextColor3 = C.Accent
    fovValue.Font = C.FontMed
    fovValue.TextSize = 12
    fovValue.Parent = fovFrame

    local fovSlider = Instance.new("TextBox")
    fovSlider.Size = UDim2.new(0.9, -24, 0, 18)
    fovSlider.Position = UDim2.new(0.05, 0, 0, 22)
    fovSlider.BackgroundColor3 = C.Bg4
    fovSlider.BackgroundTransparency = 0.2
    fovSlider.BorderSizePixel = 0
    fovSlider.PlaceholderText = "70"
    fovSlider.Text = ""
    fovSlider.TextColor3 = C.Text1
    fovSlider.PlaceholderColor3 = C.Text3
    fovSlider.Font = C.FontReg
    fovSlider.TextSize = 11
    fovSlider.Parent = fovFrame
    corner(fovSlider, UDim.new(0, 4))

    fovSlider.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(fovSlider.Text) or 70
            val = math.clamp(val, 40, 120)
            Camera.FieldOfView = val
            fovValue.Text = tostring(val)
            fovSlider.Text = ""
        end
    end)

    makeToggle(visPage, "No Fog", "Remove all fog", 3, function(on)
        if on then
            S._origFog = {FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart}
            Lighting.FogEnd = 1e6; Lighting.FogStart = 1e6
        elseif S._origFog then
            Lighting.FogEnd = S._origFog.FogEnd; Lighting.FogStart = S._origFog.FogStart
        end
    end)

    makeToggle(visPage, "No Effects", "Disable screen effects/visuals", 4, function(on)
        rmConn("noeff")
        if on then
            addConn("noeff", RunService.Heartbeat:Connect(function()
                if not S.Features["No Effects"] then return end
                for _, v in pairs(Camera:GetDescendants()) do
                    if v:IsA("PostEffect") or v:IsA("BlurEffect") then
                        v.Enabled = false
                    end
                end
            end))
        end
    end)

    --   PAGE: MISC
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local miscPage = makePage("Misc")

    makeToggle(miscPage, "Anti-AFK", "Prevent being kicked for AFK", 1, function(on)
        rmConn("antiafk")
        if not on then return end
        addConn("antiafk", RunService.Heartbeat:Connect(function()
            if not S.Features["Anti-AFK"] then return end
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:Move(Vector3.new(0, 0, 0), false)
                end
            end
        end))
    end)

    -- Server Info display
    local serverInfoFrame = Instance.new("Frame")
    serverInfoFrame.Size = UDim2.new(1, 0, 0, 100)
    serverInfoFrame.BackgroundColor3 = C.Bg3
    serverInfoFrame.BackgroundTransparency = 0.25
    serverInfoFrame.BorderSizePixel = 0
    serverInfoFrame.LayoutOrder = 5
    serverInfoFrame.Parent = miscPage
    corner(serverInfoFrame, UDim.new(0, 8))

    local serverInfoTitle = Instance.new("TextLabel")
    serverInfoTitle.Size = UDim2.new(1, -16, 0, 16)
    serverInfoTitle.Position = UDim2.new(0, 10, 0, 6)
    serverInfoTitle.BackgroundTransparency = 1
    serverInfoTitle.Text = "SERVER INFO"
    serverInfoTitle.TextColor3 = C.AccentDim
    serverInfoTitle.Font = C.Font
    serverInfoTitle.TextSize = 9
    serverInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
    serverInfoTitle.Parent = serverInfoFrame

    local siGrid = Instance.new("UIGridLayout")
    siGrid.CellSize = UDim2.new(0.5, -6, 0, 22)
    siGrid.CellPadding = UDim2.new(0, 6, 0, 4)
    siGrid.SortOrder = Enum.SortOrder.LayoutOrder
    siGrid.Parent = serverInfoFrame

    local function makeSIStat(parent, text, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = C.Bg4
        f.BackgroundTransparency = 0.2
        f.BorderSizePixel = 0
        f.LayoutOrder = order
        f.Parent = parent
        corner(f, UDim.new(0, 4))
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = C.Text2
        l.Font = C.FontReg
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        return l
    end

    local siPlayers = makeSIStat(serverInfoFrame, "Players: 0", 1)
    local siPing = makeSIStat(serverInfoFrame, "Ping: 0ms", 2)
    local siPlaceId = makeSIStat(serverInfoFrame, "Place: -", 3)
    local siUptime = makeSIStat(serverInfoFrame, "Uptime: 0s", 4)

    addConn("si_update", RunService.Heartbeat:Connect(function()
        siPlayers.Text = "Players: " .. #Players:GetPlayers()
        siPing.Text = "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms"
        siPlaceId.Text = "Place: " .. (game.PlaceId or "-")
        local up = math.floor(os.clock())
        siUptime.Text = "Uptime: " .. up .. "s"
    end))

    -- Rejoin button
    local rejoinBtn = Instance.new("Frame")
    rejoinBtn.Size = UDim2.new(1, 0, 0, 36)
    rejoinBtn.BackgroundColor3 = C.Blue
    rejoinBtn.BackgroundTransparency = 0.82
    rejoinBtn.BorderSizePixel = 0
    rejoinBtn.LayoutOrder = 6
    rejoinBtn.Parent = miscPage
    corner(rejoinBtn, UDim.new(0, 8))
    stroke(rejoinBtn, C.Blue, 1, 0.5)

    local rejoinLbl = Instance.new("TextLabel")
    rejoinLbl.Size = UDim2.new(1, 0, 1, 0)
    rejoinLbl.BackgroundTransparency = 1
    rejoinLbl.Text = "­ƒöä Rejoin Server"
    rejoinLbl.TextColor3 = C.Blue
    rejoinLbl.Font = C.FontMed
    rejoinLbl.TextSize = 12
    rejoinLbl.Parent = rejoinBtn

    local rejoinClick = Instance.new("TextButton")
    rejoinClick.Size = UDim2.new(1, 0, 1, 0)
    rejoinClick.BackgroundTransparency = 1
    rejoinClick.Text = ""
    rejoinClick.Parent = rejoinBtn
    rejoinClick.MouseButton1Click:Connect(function()
        local ts = game:GetService("TeleportService")
        ts:Teleport(game.PlaceId, LocalPlayer)
    end)

    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    -- CONFIGURATION PAGE
    local configPage = makePage("Config")
    local configRoot = Instance.new("Frame")
    configRoot.Size = UDim2.new(1, 0, 0, 0)
    configRoot.BackgroundTransparency = 1
    configRoot.BorderSizePixel = 0
    configRoot.AutomaticSize = Enum.AutomaticSize.Y
    configRoot.LayoutOrder = 1
    configRoot.Parent = configPage

    local configLayout = Instance.new("UIListLayout")
    configLayout.Padding = UDim.new(0, 8)
    configLayout.SortOrder = Enum.SortOrder.LayoutOrder
    configLayout.Parent = configRoot

    local configPanel = panel(Instance.new("Frame"), 196, C.Bg3, 0.12)
    configPanel.LayoutOrder = 1
    configPanel.Parent = configRoot

    local configTitle = Instance.new("TextLabel")
    configTitle.Size = UDim2.new(1, -20, 0, 20)
    configTitle.Position = UDim2.new(0, 12, 0, 12)
    configTitle.BackgroundTransparency = 1
    configTitle.Text = "Configuration"
    configTitle.TextColor3 = C.Text1
    configTitle.Font = C.Font
    configTitle.TextSize = 18
    configTitle.TextXAlignment = Enum.TextXAlignment.Left
    configTitle.Parent = configPanel

    local configSub = Instance.new("TextLabel")
    configSub.Size = UDim2.new(1, -20, 0, 16)
    configSub.Position = UDim2.new(0, 12, 0, 34)
    configSub.BackgroundTransparency = 1
    configSub.Text = "Save profiles, load them later, or keep one on autoload."
    configSub.TextColor3 = C.Text3
    configSub.Font = C.FontReg
    configSub.TextSize = 11
    configSub.TextXAlignment = Enum.TextXAlignment.Left
    configSub.Parent = configPanel

    local profileNameBox = Instance.new("TextBox")
    profileNameBox.Size = UDim2.new(1, -24, 0, 34)
    profileNameBox.Position = UDim2.new(0, 12, 0, 58)
    profileNameBox.BackgroundColor3 = C.Bg4
    profileNameBox.BackgroundTransparency = 0.12
    profileNameBox.BorderSizePixel = 0
    profileNameBox.ClearTextOnFocus = false
    profileNameBox.PlaceholderText = "Profile name"
    profileNameBox.Text = ""
    profileNameBox.TextColor3 = C.Text1
    profileNameBox.PlaceholderColor3 = C.Text3
    profileNameBox.Font = C.FontMed
    profileNameBox.TextSize = 12
    profileNameBox.TextXAlignment = Enum.TextXAlignment.Left
    profileNameBox.Parent = configPanel
    corner(profileNameBox, UDim.new(0, 8))
    pad(profileNameBox, 10, 10, 0, 0)

    local function actionButton(parent, text, x, y, w, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 30)
        b.Position = UDim2.new(0, x, 0, y)
        b.BackgroundColor3 = col or C.Bg4
        b.BackgroundTransparency = 0.12
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = C.Text1
        b.Font = C.FontMed
        b.TextSize = 11
        b.Parent = parent
        corner(b, UDim.new(0, 8))
        stroke(b, C.AccentDim, 1, 0.75)
        return b
    end

    local saveBtn = actionButton(configPanel, "Save", 12, 104, 84, C.Accent)
    local loadBtn = actionButton(configPanel, "Load", 104, 104, 84, C.Bg4)
    local deleteBtn = actionButton(configPanel, "Delete", 196, 104, 84, C.Red)
    local autoBtn = actionButton(configPanel, "Autoload", 288, 104, 104, C.Bg4)

    local configStatus = Instance.new("TextLabel")
    configStatus.Size = UDim2.new(1, -24, 0, 16)
    configStatus.Position = UDim2.new(0, 12, 0, 142)
    configStatus.BackgroundTransparency = 1
    configStatus.Text = "No profile selected"
    configStatus.TextColor3 = C.Text2
    configStatus.Font = C.FontReg
    configStatus.TextSize = 11
    configStatus.TextXAlignment = Enum.TextXAlignment.Left
    configStatus.Parent = configPanel

    local function currentProfileName()
        return sanitizeProfileName(profileNameBox.Text)
    end

    local function refreshConfigStatus(message, color)
        configStatus.Text = message
        configStatus.TextColor3 = color or C.Text2
    end

    saveBtn.MouseButton1Click:Connect(function()
        local ok, result = saveProfile(currentProfileName())
        if ok then
            refreshConfigStatus("Saved profile: " .. result, C.Green)
            notify("Saved profile: " .. result, C.Green, 3)
        else
            refreshConfigStatus(result or "Save failed", C.Red)
            notify(result or "Save failed", C.Red, 3)
        end
    end)

    loadBtn.MouseButton1Click:Connect(function()
        local ok, result = loadProfile(currentProfileName())
        if ok then
            refreshConfigStatus("Loaded profile: " .. result, C.Green)
        else
            refreshConfigStatus(result or "Load failed", C.Red)
            notify(result or "Load failed", C.Red, 3)
        end
    end)

    deleteBtn.MouseButton1Click:Connect(function()
        local ok, result = deleteProfile(currentProfileName())
        if ok then
            refreshConfigStatus("Deleted profile: " .. result, C.Green)
            notify("Deleted profile: " .. result, C.Green, 3)
        else
            refreshConfigStatus(result or "Delete failed", C.Red)
            notify(result or "Delete failed", C.Red, 3)
        end
    end)

    autoBtn.MouseButton1Click:Connect(function()
        local name = currentProfileName()
        if name == "" then
            refreshConfigStatus("Enter a profile name first", C.Red)
            notify("Enter a profile name first", C.Red, 3)
            return
        end
        local ok, result = saveAutoload(name, true)
        if ok then
            refreshConfigStatus("Autoload set: " .. result, C.AccentBright)
            notify("Autoload set: " .. result, C.AccentBright, 3)
        else
            refreshConfigStatus(result or "Autoload failed", C.Red)
            notify(result or "Autoload failed", C.Red, 3)
        end
    end)

    local autoData = loadAutoload()
    local autoLoadEnabled = false
    if type(autoData) == "table" and autoData.enabled and type(autoData.profile) == "string" then
        autoLoadEnabled = true
        profileNameBox.Text = autoData.profile
        refreshConfigStatus("Autoload profile: " .. autoData.profile, C.AccentBright)
        task.defer(function()
            loadProfile(autoData.profile, true)
        end)
    end

    makeToggle(configPage, "Auto-Load", "Apply the saved profile on startup", 2, function(on)
        local name = currentProfileName()
        if name == "" then
            notify("Enter a profile name first", C.Yellow, 3)
            S.Features["Auto-Load"] = false
            return
        end
        saveAutoload(name, on)
        refreshConfigStatus((on and "Autoload enabled: " or "Autoload disabled: ") .. name, on and C.AccentBright or C.Text2)
    end)

    if autoLoadEnabled and S._toggleControls["Auto-Load"] then
        S._toggleControls["Auto-Load"].set(true, true)
    end

    --   CATEGORY SWITCHING
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    local function switchCat(name)
        currentCat = name
        for n, pg in pairs(pages) do
            if n == name then
                pg.Visible = true
                pg.Position = UDim2.new(0, 14, 0, 0)
                tw(pg, {Position = UDim2.new(0, 0, 0, 0)}, C.SpeedFast)
            else
                pg.Visible = false
            end
        end
        for n, d in pairs(sideBtns) do
            if n == name then
                tw(d.button, {BackgroundTransparency = 0.05}, C.Speed)
                tw(d.label, {TextColor3 = C.AccentBright}, C.Speed)
            else
                tw(d.button, {BackgroundTransparency = 0.18}, C.Speed)
                tw(d.label, {TextColor3 = C.Text2}, C.Speed)
            end
        end
    end

    for name, d in pairs(sideBtns) do
        d.button.MouseButton1Click:Connect(function() switchCat(name) end)
    end
    switchCat("Home")

    updateMatchHUD()

    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    --   WINDOW CONTROLS
    -- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
    closeBtn.MouseButton1Click:Connect(function()
        for k, c in pairs(S.Conns) do pcall(function() c:Disconnect() end) end
        for t, _ in pairs(S.Highlights) do clearHL(t) end
        pcall(function() Lighting:FindFirstChild("HubNV"):Destroy() end)
        if S._origLight then for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end end
        if S._origFog then pcall(function() Lighting.FogEnd = S._origFog.FogEnd; Lighting.FogStart = S._origFog.FogStart end) end
        pcall(function() if MatchHudGui then MatchHudGui:Destroy() end end)
            tw(MainFrame, {Size = UDim2.new(0, windowW, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        Hub:Destroy()
    end)

    minBtn.MouseButton1Click:Connect(function()
        S.Visible = not S.Visible
        if S.Visible then
            MainFrame.Visible = true
            uiScale.Scale = isPhone and 0.88 or 0.94
            tw(uiScale, {Scale = isPhone and 0.92 or 1}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tw(MainFrame, {Size = UDim2.new(0, windowW, 0, windowH)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tw(uiScale, {Scale = isPhone and 0.9 or 1}, 0.18)
            tw(MainFrame, {Size = UDim2.new(0, windowW, 0, 44)}, 0.2)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == C.Key then
            S.Visible = not S.Visible
            if S.Visible then
                MainFrame.Visible = true
                MainFrame.BackgroundTransparency = 0.6
                tw(MainFrame, {BackgroundTransparency = 0.14}, 0.25)
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
    uiScale.Scale = isPhone and 0.88 or 0.94
    task.wait(0.1)
    tw(MainFrame, {BackgroundTransparency = 0.14, Size = UDim2.new(0, windowW, 0, windowH), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(uiScale, {Scale = isPhone and 0.92 or 1}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.wait(0.6)
    notify("­ƒùí´©Å Samurai Hub v1.0 loaded", C.Accent, 4)
    notify("made by 1nxs on discord", C.Text3, 5)
    notify("RightShift to toggle", C.Text3, 4)
end

-- LAUNCH
local ok, err = pcall(function()
    showLoadingScreen(function()
        local ok2, err2 = pcall(function()
            buildMatchHUD()
            hookGameEvents()
            buildHub()
        end)
        if not ok2 then
            warn("[Hub] Build failed:", err2)
            print("[Hub] BUILD FAILED:", err2)
        end
    end)
end)
if not ok then
    warn("[Hub] Fatal error:", err)
    print("[Hub] FATAL ERROR:", err)
else
    print("[1nxs Hub] Ô£à Samurai Hub v1.0 Loaded")
end

