--[[
    ╔══════════════════════════════════════════════════╗
    ║   1NXS DEMONOLOGY HUB v2.1                      ║
    ║   made by 1nxs on discord                        ║
    ║   Toggle UI: RightShift                          ║
    ║   FIXED: Freezing, Laser, GhostOrb, TP to Exit  ║
    ║   NEW: Hunt Closet TP, Evidence HUD overlay      ║
    ╚══════════════════════════════════════════════════╝
--]]

----------------------------------------------
-- SERVICES
----------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

----------------------------------------------
-- CLEANUP OLD INSTANCE
----------------------------------------------
pcall(function()
    local old = CoreGui:FindFirstChild("1nxsHub")
    if old then old:Destroy() end
    local oldLoad = CoreGui:FindFirstChild("1nxsLoader")
    if oldLoad then oldLoad:Destroy() end
    local oldHud = CoreGui:FindFirstChild("1nxsEvidHUD")
    if oldHud then oldHud:Destroy() end
    local oldBlur = Lighting:FindFirstChild("HubBlur")
    if oldBlur then oldBlur:Destroy() end
end)

----------------------------------------------
-- GREY THEME CONFIG
----------------------------------------------
local C = {
    Key             = Enum.KeyCode.RightShift,
    Bg1             = Color3.fromRGB(14, 14, 18),
    Bg2             = Color3.fromRGB(20, 20, 26),
    Bg3             = Color3.fromRGB(28, 28, 36),
    Bg4             = Color3.fromRGB(36, 36, 46),
    BgHover         = Color3.fromRGB(42, 42, 54),
    Accent          = Color3.fromRGB(160, 165, 180),
    AccentDim       = Color3.fromRGB(100, 105, 120),
    AccentBright    = Color3.fromRGB(210, 215, 225),
    Text1           = Color3.fromRGB(230, 232, 238),
    Text2           = Color3.fromRGB(150, 153, 165),
    Text3           = Color3.fromRGB(85, 88, 100),
    Green           = Color3.fromRGB(74, 222, 128),
    Red             = Color3.fromRGB(248, 113, 113),
    Yellow          = Color3.fromRGB(250, 204, 21),
    Blue            = Color3.fromRGB(96, 165, 250),
    Purple          = Color3.fromRGB(192, 132, 252),
    EvidEMF         = Color3.fromRGB(250, 204, 21),
    EvidPrints      = Color3.fromRGB(192, 132, 252),
    EvidSpirit      = Color3.fromRGB(96, 165, 250),
    EvidOrb         = Color3.fromRGB(74, 222, 128),
    EvidFreeze      = Color3.fromRGB(147, 197, 253),
    EvidInscript    = Color3.fromRGB(248, 113, 113),
    EvidLaser       = Color3.fromRGB(251, 146, 60),
    EvidWither      = Color3.fromRGB(163, 130, 98),
    Speed           = 0.3,
    SpeedFast       = 0.15,
    Font            = Enum.Font.GothamBold,
    FontMed         = Enum.Font.GothamMedium,
    FontReg         = Enum.Font.Gotham,
}

----------------------------------------------
-- GHOST DATABASE
----------------------------------------------
local GhostDB = {
    {name="Aswang",      evidence={"EMF5","Prints","Laser"}},
    {name="Banshee",     evidence={"Prints","GhostOrb","Laser"}},
    {name="Demon",       evidence={"Freezing","Inscription","Prints"}},
    {name="Dullahan",    evidence={"EMF5","Freezing","GhostOrb"}},
    {name="Dybbuk",      evidence={"SpiritBox","GhostOrb","Inscription"}},
    {name="Entity",      evidence={"EMF5","SpiritBox","Wither"}},
    {name="Ghoul",       evidence={"Freezing","Wither","Laser"}},
    {name="Keres",       evidence={"SpiritBox","Freezing","Inscription"}},
    {name="Leviathan",   evidence={"EMF5","GhostOrb","Wither"}},
    {name="Nightmare",   evidence={"SpiritBox","GhostOrb","Inscription"}},
    {name="Oni",         evidence={"EMF5","Freezing","Laser"}},
    {name="Phantom",     evidence={"SpiritBox","Prints","Laser"}},
    {name="Ravager",     evidence={"EMF5","Inscription","Wither"}},
    {name="Revenant",    evidence={"Freezing","GhostOrb","Inscription"}},
    {name="Shadow",      evidence={"EMF5","SpiritBox","Freezing"}},
    {name="Siren",       evidence={"SpiritBox","Prints","Wither"}},
    {name="Skinwalker",  evidence={"Prints","Freezing","Wither"}},
    {name="Specter",     evidence={"GhostOrb","Laser","Wither"}},
}

local EvidenceTypes = {
    {id="EMF5",        label="EMF Level 5",     icon="⚡",  color=C.EvidEMF},
    {id="Prints",      label="Fingerprints",    icon="🖐",  color=C.EvidPrints},
    {id="SpiritBox",   label="Spirit Box",      icon="📻",  color=C.EvidSpirit},
    {id="GhostOrb",    label="Ghost Orb",       icon="🔮",  color=C.EvidOrb},
    {id="Freezing",    label="Freezing Temps",  icon="❄",   color=C.EvidFreeze},
    {id="Inscription", label="Inscription",     icon="✍",   color=C.EvidInscript},
    {id="Laser",       label="Laser Projector", icon="🔴",  color=C.EvidLaser},
    {id="Wither",      label="Wither",          icon="🥀",  color=C.EvidWither},
}

----------------------------------------------
-- STATE
----------------------------------------------
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
    _hudPills    = {},   -- top evidence HUD pill refs
}

for _, ev in ipairs(EvidenceTypes) do
    S.Evidence[ev.id] = false
end

----------------------------------------------
-- UTILITIES
----------------------------------------------
local function tw(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(dur or C.Speed, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
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

local function safeFind(parent, ...)
    local cur = parent
    for _, n in ipairs({...}) do
        if not cur then return nil end
        cur = cur:FindFirstChild(n)
    end
    return cur
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

----------------------------------------------
-- EVIDENCE HUD (top-bar frosted pill strip)
-- shows all 8 evidence icons, dims/lights on found
----------------------------------------------
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

    -- frosted container — centered top bar
    local bar = Instance.new("Frame")
    bar.Name = "EvidBar"
    bar.Size = UDim2.new(0, 432, 0, 38)
    bar.Position = UDim2.new(0.5, -216, 0, 10)
    bar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    bar.BackgroundTransparency = 0.35  -- semi-transparent glassy look
    bar.BorderSizePixel = 0
    bar.Parent = EvidHudGui
    corner(bar, UDim.new(0, 12))
    stroke(bar, C.AccentDim, 1, 0.55)

    -- subtle inner highlight line (glass effect top edge)
    local topGlow = Instance.new("Frame")
    topGlow.Size = UDim2.new(1, -24, 0, 1)
    topGlow.Position = UDim2.new(0, 12, 0, 1)
    topGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topGlow.BackgroundTransparency = 0.82
    topGlow.BorderSizePixel = 0
    topGlow.Parent = bar

    -- pill row layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bar
    pad(bar, 0, 0, 10, 10)

    S._hudPills = {}

    for i, ev in ipairs(EvidenceTypes) do
        local pill = Instance.new("Frame")
        pill.Name = ev.id
        pill.Size = UDim2.new(0, 46, 0, 24)
        pill.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        pill.BackgroundTransparency = 0.4
        pill.BorderSizePixel = 0
        pill.LayoutOrder = i
        pill.Parent = bar
        corner(pill, UDim.new(0, 6))

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = ev.icon
        lbl.TextSize = 13
        lbl.TextColor3 = C.Text3
        lbl.Font = C.FontMed
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = pill

        S._hudPills[ev.id] = {pill = pill, label = lbl}
    end
end

local function updateHUD()
    for _, ev in ipairs(EvidenceTypes) do
        local d = S._hudPills[ev.id]
        if d then
            if S.Evidence[ev.id] then
                tw(d.pill, {BackgroundColor3 = ev.color, BackgroundTransparency = 0.25}, C.SpeedFast)
                tw(d.label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, C.SpeedFast)
            else
                tw(d.pill, {BackgroundColor3 = Color3.fromRGB(30, 30, 38), BackgroundTransparency = 0.4}, C.SpeedFast)
                tw(d.label, {TextColor3 = C.Text3}, C.SpeedFast)
            end
        end
    end
end

----------------------------------------------
-- NOTIFICATION SYSTEM
----------------------------------------------
local function notify(text, color, dur)
    if not S._notifBox then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = C.Bg3
    f.BackgroundTransparency = 0.15
    f.BorderSizePixel = 0
    f.Parent = S._notifBox
    corner(f, UDim.new(0, 6))
    stroke(f, color or C.Accent, 1, 0.6)

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
    tw(f, {BackgroundTransparency = 0.15}, 0.25)
    tw(lbl, {TextTransparency = 0}, 0.25)

    task.delay(dur or 3, function()
        tw(f, {BackgroundTransparency = 1}, 0.35)
        tw(lbl, {TextTransparency = 1}, 0.35)
        task.wait(0.4)
        pcall(function() f:Destroy() end)
    end)
end

----------------------------------------------
-- EVIDENCE TRACKING & GHOST IDENTIFIER
----------------------------------------------
-- forward declare so markEvidence can call them
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
    for _, ghost in ipairs(GhostDB) do
        local matches = true
        for _, foundEvid in ipairs(found) do
            local hasIt = false
            for _, ghostEvid in ipairs(ghost.evidence) do
                if ghostEvid == foundEvid then hasIt = true break end
            end
            if not hasIt then matches = false break end
        end
        if matches then
            local matchCount = 0
            for _, ghostEvid in ipairs(ghost.evidence) do
                if S.Evidence[ghostEvid] then matchCount += 1 end
            end
            table.insert(possible, {
                name = ghost.name,
                evidence = ghost.evidence,
                matched = matchCount,
                confidence = math.floor((matchCount / 3) * 100)
            })
        end
    end

    table.sort(possible, function(a, b) return a.confidence > b.confidence end)
    return possible
end

----------------------------------------------
-- HUNT CLOSET TELEPORT
-- Finds nearest hiding spot (closet/wardrobe/locker)
-- and teleports player without triggering ragdoll
----------------------------------------------
local function findNearestHidingSpot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local keywords = {"closet", "wardrobe", "locker", "cabinet", "armoire", "hiding", "cupboard"}
    local best, bestDist = nil, math.huge

    local function checkPart(part)
        if not part:IsA("BasePart") then return end
        local name = part.Name:lower()
        for _, kw in ipairs(keywords) do
            if name:find(kw) then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist < bestDist then
                    best = part
                    bestDist = dist
                end
                break
            end
        end
    end

    for _, d in pairs(Workspace:GetDescendants()) do
        pcall(checkPart, d)
    end

    return best, bestDist
end

local function safeTPToHidingSpot()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    -- prevent ragdoll: lock state to Running before teleport
    local prevState = hum:GetState()
    hum:ChangeState(Enum.HumanoidStateType.Running)

    local spot, dist = findNearestHidingSpot()
    if spot then
        -- offset inside the closet, slightly above floor
        hrp.CFrame = CFrame.new(spot.Position + Vector3.new(0, 2.5, 0))
        -- re-lock state so physics doesn't rag-doll on arrival
        task.wait(0.05)
        hum:ChangeState(Enum.HumanoidStateType.Running)
        notify("🚪 Hid in " .. spot.Name .. " (" .. math.floor(dist) .. " studs away)", C.Green, 4)
        return true
    end
    return false
end

----------------------------------------------
-- HUNT DETECTOR
-- Watches remotes + workspace flag for hunt start
----------------------------------------------
local huntActive = false
local lastHuntTP  = 0

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

    task.wait(10) -- rough hunt duration cooldown
    huntActive = false
end

local function onHuntEnd()
    huntActive = false
    notify("✅ Hunt over - you're safe", C.Green, 3)
end

----------------------------------------------
-- LOADING SCREEN
----------------------------------------------
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
    overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    overlay.BackgroundTransparency = 0
    overlay.BorderSizePixel = 0
    overlay.Parent = loaderGui

    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 300, 0, 200)
    center.Position = UDim2.new(0.5, -150, 0.5, -100)
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
    ver.Text = "v2.1 — fixed + upgraded"
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
    credit.Text = "made by 1nxs on discord"
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
    blur.Size = 6

    if onComplete then onComplete() end
end

----------------------------------------------
-- MAIN UI BUILDER
----------------------------------------------
local Hub, MainFrame

local function buildHub()
    Hub = Instance.new("ScreenGui")
    Hub.Name = "1nxsHub"
    Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Hub.DisplayOrder = 1000
    Hub.ResetOnSpawn = false
    pcall(function() Hub.Parent = CoreGui end)
    if not Hub.Parent then Hub.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ═══ MAIN WINDOW — glassy / blurry ═══
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 580, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -290, 0.5, -230)
    -- transparency=0.18 gives a frosted look on top of the hub's blur
    MainFrame.BackgroundColor3 = C.Bg1
    MainFrame.BackgroundTransparency = 0.18
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = Hub
    corner(MainFrame, UDim.new(0, 12))
    stroke(MainFrame, C.AccentDim, 1, 0.4)

    -- top glass highlight edge
    local topSheen = Instance.new("Frame")
    topSheen.Size = UDim2.new(1, -30, 0, 1)
    topSheen.Position = UDim2.new(0, 15, 0, 1)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BackgroundTransparency = 0.78
    topSheen.BorderSizePixel = 0
    topSheen.Parent = MainFrame

    -- ═══ TITLE BAR ═══
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = C.Bg2
    titleBar.BackgroundTransparency = 0.25
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    corner(titleBar, UDim.new(0, 12))

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = C.Bg2
    titleFix.BackgroundTransparency = 0.25
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, 0)
    titleLine.BackgroundColor3 = C.AccentDim
    titleLine.BackgroundTransparency = 0.65
    titleLine.BorderSizePixel = 0
    titleLine.Parent = titleBar

    local titleTxt = Instance.new("TextLabel")
    titleTxt.Size = UDim2.new(0, 200, 0, 18)
    titleTxt.Position = UDim2.new(0, 14, 0, 7)
    titleTxt.BackgroundTransparency = 1
    titleTxt.Text = "DEMONOLOGY HUB"
    titleTxt.TextColor3 = C.Text1
    titleTxt.Font = C.Font
    titleTxt.TextSize = 14
    titleTxt.TextXAlignment = Enum.TextXAlignment.Left
    titleTxt.Parent = titleBar

    local subtitleTxt = Instance.new("TextLabel")
    subtitleTxt.Size = UDim2.new(0, 200, 0, 12)
    subtitleTxt.Position = UDim2.new(0, 14, 0, 25)
    subtitleTxt.BackgroundTransparency = 1
    subtitleTxt.Text = "made by 1nxs · v2.1"
    subtitleTxt.TextColor3 = C.Text3
    subtitleTxt.Font = C.FontReg
    subtitleTxt.TextSize = 10
    subtitleTxt.TextXAlignment = Enum.TextXAlignment.Left
    subtitleTxt.Parent = titleBar

    local statusBadge = Instance.new("TextLabel")
    statusBadge.Size = UDim2.new(0, 70, 0, 18)
    statusBadge.Position = UDim2.new(1, -180, 0.5, -9)
    statusBadge.BackgroundColor3 = C.Bg4
    statusBadge.BackgroundTransparency = 0.3
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
        btn.BackgroundTransparency = 0.88
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = col
        btn.Font = C.Font
        btn.TextSize = 11
        btn.Parent = titleBar
        corner(btn, UDim.new(0, 6))
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundTransparency = 0.5}, C.SpeedFast) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundTransparency = 0.88}, C.SpeedFast) end)
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

    -- ═══ SIDEBAR ═══
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 115, 1, -43)
    sidebar.Position = UDim2.new(0, 0, 0, 43)
    sidebar.BackgroundColor3 = C.Bg2
    sidebar.BackgroundTransparency = 0.3
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainFrame

    local sideLayout = Instance.new("UIListLayout")
    sideLayout.Padding = UDim.new(0, 2)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Parent = sidebar
    pad(sidebar, 6, 6, 6, 6)

    local categories = {
        {name="ESP",       icon="👁",   order=1},
        {name="Evidence",  icon="🔍",   order=2},
        {name="Ghost ID",  icon="👻",   order=3},
        {name="Survival",  icon="🛡",   order=4},
        {name="Visual",    icon="✨",   order=5},
        {name="Tools",     icon="⚙",    order=6},
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
        ico.Size = UDim2.new(0, 22, 1, 0)
        ico.Position = UDim2.new(0, 4, 0, 0)
        ico.BackgroundTransparency = 1
        ico.Text = cat.icon
        ico.TextSize = 13
        ico.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, -30, 1, 0)
        lbl.Position = UDim2.new(0, 28, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = cat.name
        lbl.TextColor3 = C.Text2
        lbl.Font = C.FontMed
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        sideBtns[cat.name] = {button = btn, label = lbl}

        btn.MouseEnter:Connect(function()
            if currentCat ~= cat.name then
                tw(btn, {BackgroundTransparency = 0.9}, C.SpeedFast)
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentCat ~= cat.name then
                tw(btn, {BackgroundTransparency = 1}, C.SpeedFast)
            end
        end)
    end

    -- ═══ CONTENT AREA ═══
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -117, 1, -43)
    content.Position = UDim2.new(0, 117, 0, 43)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = MainFrame

    -- ═══ NOTIFICATION CONTAINER ═══
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

    -- ═══ PAGE BUILDER ═══
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
        pad(pg, 6, 6, 6, 6)

        local hdr = Instance.new("TextLabel")
        hdr.Size = UDim2.new(1, 0, 0, 18)
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
        cont.BackgroundTransparency = 0.5
        cont.BorderSizePixel = 0
        cont.LayoutOrder = order
        cont.Parent = parent
        corner(cont, UDim.new(0, 7))

        cont.MouseEnter:Connect(function() tw(cont, {BackgroundTransparency = 0.15}, C.SpeedFast) end)
        cont.MouseLeave:Connect(function() tw(cont, {BackgroundTransparency = 0.5}, C.SpeedFast) end)

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -60, 0, 16)
        nm.Position = UDim2.new(0, 10, 0, 7)
        nm.BackgroundTransparency = 1
        nm.Text = name
        nm.TextColor3 = C.Text1
        nm.Font = C.FontMed
        nm.TextSize = 12
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = cont

        local ds = Instance.new("TextLabel")
        ds.Size = UDim2.new(1, -60, 0, 12)
        ds.Position = UDim2.new(0, 10, 0, 24)
        ds.BackgroundTransparency = 1
        ds.Text = desc
        ds.TextColor3 = C.Text3
        ds.Font = C.FontReg
        ds.TextSize = 10
        ds.TextXAlignment = Enum.TextXAlignment.Left
        ds.TextTruncate = Enum.TextTruncate.AtEnd
        ds.Parent = cont

        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 36, 0, 18)
        pill.Position = UDim2.new(1, -46, 0.5, -9)
        pill.BackgroundColor3 = C.Bg4
        pill.BorderSizePixel = 0
        pill.Parent = cont
        corner(pill, UDim.new(1, 0))

        local circ = Instance.new("Frame")
        circ.Size = UDim2.new(0, 14, 0, 14)
        circ.Position = UDim2.new(0, 2, 0.5, -7)
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
                    tw(circ, {Position = UDim2.new(0, 20, 0.5, -7), BackgroundColor3 = C.Text1}, C.SpeedFast)
                    tw(nm,   {TextColor3 = C.AccentBright}, C.SpeedFast)
                else
                    tw(pill, {BackgroundColor3 = C.Bg4}, C.SpeedFast)
                    tw(circ, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = C.Text2}, C.SpeedFast)
                    tw(nm,   {TextColor3 = C.Text1}, C.SpeedFast)
                end
            else
                pill.BackgroundColor3 = v and C.Accent or C.Bg4
                circ.Position = v and UDim2.new(0, 20, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
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

    -- Ghost ESP
    makeToggle(espPage, "Ghost ESP", "Highlight ghost through walls", 1, function(on)
        clearHL("ghost")
        rmConn("ghost_loop")
        if not on then return end
        S.Highlights["ghost"] = {}
        S.Billboards["ghost"] = {}

        local function scan()
            clearHL("ghost")
            S.Highlights["ghost"] = {}
            S.Billboards["ghost"] = {}
            local holder = safeFind(Workspace, "CursedPossessionHolder")
            if holder then
                for _, d in pairs(holder:GetDescendants()) do
                    if d.Name == "GhostAnchor" and d:IsA("BasePart") then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 0, 60)
                        hl.FillTransparency = 0.55
                        hl.OutlineColor = Color3.fromRGB(255, 40, 80)
                        hl.OutlineTransparency = 0.15
                        hl.Adornee = d.Parent or d
                        hl.Parent = CoreGui
                        table.insert(S.Highlights["ghost"], hl)
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 110, 0, 26)
                        bb.StudsOffset = Vector3.new(0, 4, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = d
                        bb.Parent = CoreGui
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundColor3 = Color3.fromRGB(30, 0, 10)
                        l.BackgroundTransparency = 0.3
                        l.Text = "👻 GHOST"
                        l.TextColor3 = Color3.fromRGB(255, 80, 100)
                        l.Font = C.Font
                        l.TextSize = 13
                        l.Parent = bb
                        corner(l, UDim.new(0, 5))
                        table.insert(S.Billboards["ghost"], bb)
                    end
                end
            end
            for _, ch in pairs(Workspace:GetChildren()) do
                if ch:IsA("Model") and ch.Name ~= LocalPlayer.Name then
                    local nm = ch.Name:lower()
                    if nm:find("ghost") or nm:find("demon") or nm:find("spirit") or nm:find("entity") or nm:find("cursed") then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 0, 60)
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 40, 80)
                        hl.OutlineTransparency = 0.1
                        hl.Adornee = ch
                        hl.Parent = CoreGui
                        table.insert(S.Highlights["ghost"], hl)
                    end
                end
            end
        end
        scan()
        task.spawn(function()
            while S.Features["Ghost ESP"] do task.wait(2) pcall(scan) end
        end)
    end)

    -- Handprint ESP
    makeToggle(espPage, "Handprint ESP", "Highlight handprints with UV glow", 2, function(on)
        clearHL("handprints")
        rmConn("hp_added")
        rmConn("hp_removed")
        if not on then return end
        S.Highlights["handprints"] = {}
        S.Billboards["handprints"] = {}

        local function hlPrint(obj)
            if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = C.EvidPrints
            hl.FillTransparency = 0.4
            hl.OutlineColor = C.EvidPrints
            hl.OutlineTransparency = 0.1
            hl.Adornee = obj
            hl.Parent = CoreGui
            table.insert(S.Highlights["handprints"], hl)

            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 100, 0, 22)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = part
                bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = Color3.fromRGB(20, 8, 30)
                l.BackgroundTransparency = 0.25
                l.Text = "🖐 HANDPRINT"
                l.TextColor3 = C.EvidPrints
                l.Font = C.FontMed
                l.TextSize = 11
                l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["handprints"], bb)
            end
            markEvidence("Prints")
        end

        local folder = Workspace:FindFirstChild("Handprints")
        if folder then
            for _, ch in pairs(folder:GetChildren()) do pcall(hlPrint, ch) end
            addConn("hp_added", folder.ChildAdded:Connect(function(ch)
                task.wait(0.1)
                if S.Features["Handprint ESP"] then pcall(hlPrint, ch) end
            end))
            addConn("hp_removed", folder.ChildRemoved:Connect(function()
                if S.Features["Handprint ESP"] then
                    clearHL("handprints")
                    S.Highlights["handprints"] = {}
                    S.Billboards["handprints"] = {}
                    for _, ch in pairs(folder:GetChildren()) do pcall(hlPrint, ch) end
                end
            end))
        end
    end)

    -- Player ESP
    makeToggle(espPage, "Player ESP", "Show all players with distance", 3, function(on)
        clearHL("players")
        rmConn("plr_loop")
        if not on then return end
        S.Highlights["players"] = {}
        S.Billboards["players"] = {}

        local function scan()
            clearHL("players")
            S.Highlights["players"] = {}
            S.Billboards["players"] = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = C.Green
                        hl.FillTransparency = 0.65
                        hl.OutlineColor = C.Green
                        hl.OutlineTransparency = 0.2
                        hl.Adornee = p.Character
                        hl.Parent = CoreGui
                        table.insert(S.Highlights["players"], hl)
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 110, 0, 30)
                        bb.StudsOffset = Vector3.new(0, 3.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = hrp
                        bb.Parent = CoreGui
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 0.55, 0)
                        l.BackgroundColor3 = Color3.fromRGB(5, 18, 8)
                        l.BackgroundTransparency = 0.25
                        l.Text = "👤 " .. p.Name
                        l.TextColor3 = C.Green
                        l.Font = C.FontMed
                        l.TextSize = 11
                        l.Parent = bb
                        corner(l, UDim.new(0, 4))
                        local dl = Instance.new("TextLabel")
                        dl.Name = "Dist"
                        dl.Size = UDim2.new(1, 0, 0.45, 0)
                        dl.Position = UDim2.new(0, 0, 0.55, 0)
                        dl.BackgroundTransparency = 1
                        dl.Text = ""
                        dl.TextColor3 = C.Text3
                        dl.Font = C.FontReg
                        dl.TextSize = 9
                        dl.Parent = bb
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
        task.spawn(function() while S.Features["Player ESP"] do task.wait(4) pcall(scan) end end)
    end)

    -- Item ESP
    makeToggle(espPage, "Item ESP", "Highlight all pickable items", 4, function(on)
        clearHL("items")
        rmConn("item_a")
        rmConn("item_r")
        if not on then return end
        S.Highlights["items"] = {}
        S.Billboards["items"] = {}

        local function hlItem(item)
            if not item:IsA("Model") and not item:IsA("BasePart") then return end
            local hl = Instance.new("Highlight")
            hl.FillColor = C.Blue
            hl.FillTransparency = 0.7
            hl.OutlineColor = C.Blue
            hl.OutlineTransparency = 0.3
            hl.Adornee = item
            hl.Parent = CoreGui
            table.insert(S.Highlights["items"], hl)
            local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 90, 0, 20)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = part
                bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = Color3.fromRGB(8, 12, 25)
                l.BackgroundTransparency = 0.25
                l.Text = "📦 " .. item.Name
                l.TextColor3 = C.Blue
                l.Font = C.FontMed
                l.TextSize = 10
                l.TextScaled = false
                l.TextTruncate = Enum.TextTruncate.AtEnd
                l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["items"], bb)
            end
        end

        local function scan()
            clearHL("items")
            S.Highlights["items"] = {}
            S.Billboards["items"] = {}
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
        S.Highlights["doors"] = {}
        S.Billboards["doors"] = {}
        local df = safeFind(Workspace, "Doors")
        if not df then notify("⚠ Doors folder not found", C.Yellow) return end
        for _, dm in pairs(df:GetChildren()) do
            if dm:IsA("Model") then
                local hl = Instance.new("Highlight")
                hl.FillColor = C.Yellow
                hl.FillTransparency = 0.8
                hl.OutlineColor = C.Yellow
                hl.OutlineTransparency = 0.4
                hl.Adornee = dm
                hl.Parent = CoreGui
                table.insert(S.Highlights["doors"], hl)
                local part = dm:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 80, 0, 20)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = part
                    bb.Parent = CoreGui
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundColor3 = Color3.fromRGB(25, 20, 5)
                    l.BackgroundTransparency = 0.3
                    l.Text = "🚪 " .. dm.Name
                    l.TextColor3 = C.Yellow
                    l.Font = C.FontMed
                    l.TextSize = 10
                    l.Parent = bb
                    corner(l, UDim.new(0, 4))
                    table.insert(S.Billboards["doors"], bb)
                end
            end
        end
    end)

    -- ═══════════════════════════════════════
    --   PAGE: EVIDENCE (ALL FIXED)
    -- ═══════════════════════════════════════
    local evidPage = makePage("Evidence")

    -- Evidence ESP
    makeToggle(evidPage, "Evidence ESP", "Highlight ALL evidence in world", 1, function(on)
        clearHL("evidence")
        rmConn("ev_hp_a") rmConn("ev_air_a") rmConn("ev_scr_a")
        rmConn("ev_salt_a") rmConn("ev_glass_a") rmConn("ev_lidar_a")
        if not on then return end
        S.Highlights["evidence"] = {}
        S.Billboards["evidence"] = {}

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
            hl.FillColor = info.col
            hl.FillTransparency = 0.45
            hl.OutlineColor = info.col
            hl.OutlineTransparency = 0.1
            hl.Adornee = obj
            hl.Parent = CoreGui
            table.insert(S.Highlights["evidence"], hl)

            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 100, 0, 22)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = part
                bb.Parent = CoreGui
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 1, 0)
                l.BackgroundColor3 = C.Bg1
                l.BackgroundTransparency = 0.2
                l.Text = info.emoji .. " " .. info.name
                l.TextColor3 = info.col
                l.Font = C.FontMed
                l.TextSize = 10
                l.Parent = bb
                corner(l, UDim.new(0, 4))
                table.insert(S.Billboards["evidence"], bb)
            end
            if info.evid then markEvidence(info.evid) end
        end

        for _, info in ipairs(evidFolders) do
            local folder = Workspace:FindFirstChild(info.name)
            if folder then
                for _, ch in pairs(folder:GetChildren()) do pcall(hlEvidence, ch, info) end
                addConn("ev_" .. info.name:lower():gsub("%s","") .. "_a", folder.ChildAdded:Connect(function(ch)
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

    -- ═══ FIX: FREEZING DETECTOR ═══
    -- Demonology uses a 0-20°C scale on the client.
    -- We hook ALL numeric arguments from thermometer-adjacent remotes,
    -- detect ≤ 10°C as cold and ≤ 5°C as confirmed freezing evidence.
    makeToggle(evidPage, "Freezing Detector", "Alert on freezing temps (fixed)", 2, function(on)
        rmConn("temp_hook")
        rmConn("temp_scan")
        if not on then return end

        local function checkTemp(temp)
            if type(temp) ~= "number" then return end
            if temp <= 5 then
                markEvidence("Freezing")
                notify("❄ FREEZING: " .. string.format("%.1f°C", temp), C.EvidFreeze, 6)
            elseif temp <= 10 then
                notify("❄ Cold temp: " .. string.format("%.1f°C", temp) .. " (watching...)", C.EvidFreeze, 3)
            end
        end

        -- Hook any thermometer-related remote (name-agnostic)
        local hooked = false
        local thermKeywords = {"thermo", "temp", "temperature", "cold", "freeze", "freezing", "celsius"}
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local nm = r.Name:lower()
                for _, kw in ipairs(thermKeywords) do
                    if nm:find(kw) then
                        addConn("temp_hook", r.OnClientEvent:Connect(function(...)
                            for _, v in ipairs({...}) do checkTemp(v) end
                        end))
                        hooked = true
                        notify("🌡 Thermometer hooked: " .. r.Name, C.Green, 3)
                        break
                    end
                end
                if hooked then break end
            end
        end

        -- Fallback: also watch for Value objects named temp/cold/freeze
        addConn("temp_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Freezing Detector"] then return end
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("NumberValue") then
                    local nm = v.Name:lower()
                    for _, kw in ipairs(thermKeywords) do
                        if nm:find(kw) then
                            checkTemp(v.Value)
                            break
                        end
                    end
                end
            end
        end))

        if not hooked then
            notify("🌡 Temp monitor active (scanning values)", C.Yellow, 3)
        end
    end)

    -- EMF Detector
    makeToggle(evidPage, "EMF Monitor", "Watch for EMF Level 5 readings", 3, function(on)
        rmConn("emf_hook")
        if not on then return end
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local nm = r.Name:lower()
                if nm:find("emf") or nm:find("electromagnetic") then
                    addConn("emf_hook", r.OnClientEvent:Connect(function(...)
                        for _, v in ipairs({...}) do
                            if type(v) == "number" and v >= 5 then
                                markEvidence("EMF5")
                                notify("⚡ EMF LEVEL 5!", C.EvidEMF, 5)
                            end
                        end
                    end))
                    notify("⚡ EMF remote hooked: " .. r.Name, C.Green, 3)
                    return
                end
            end
        end
        notify("⚡ EMF monitor active (visual scan)", C.Yellow, 3)
    end)

    -- Spirit Box Monitor
    makeToggle(evidPage, "Spirit Box Monitor", "Detect spirit box responses", 4, function(on)
        rmConn("spiritbox_hook")
        if not on then return end
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local nm = r.Name:lower()
                if nm:find("spirit") or nm:find("spiritbox") or nm:find("response") then
                    addConn("spiritbox_hook", r.OnClientEvent:Connect(function(...)
                        markEvidence("SpiritBox")
                        notify("📻 Spirit Box response!", C.EvidSpirit, 5)
                    end))
                    notify("📻 Spirit Box hooked: " .. r.Name, C.Green, 3)
                    return
                end
            end
        end
        notify("📻 Spirit Box monitor active", C.Yellow, 3)
    end)

    -- ═══ FIX: GHOST ORB DETECTOR ═══
    -- Old code only watched ChildAdded on Airballs folder.
    -- Now: persistent scan every 0.5s, checks multiple folder names,
    -- also scans entire workspace for any orb-like parts.
    makeToggle(evidPage, "Ghost Orb Detector", "Monitor for ghost orbs (fixed)", 5, function(on)
        rmConn("orb_watch")
        rmConn("orb_scan")
        if not on then return end

        local orbFolderNames = {"Airballs", "GhostOrb", "GhostOrbs", "Orbs", "Orb"}
        local orbPartNames   = {"airball", "orb", "ghostorb", "ball"}

        local function checkOrbFolder(folder)
            if not folder then return false end
            if #folder:GetChildren() > 0 then
                markEvidence("GhostOrb")
                notify("🔮 Ghost Orb detected in " .. folder.Name .. "!", C.EvidOrb, 5)
                return true
            end
            return false
        end

        -- hook ChildAdded on any matching folder
        for _, fname in ipairs(orbFolderNames) do
            local folder = Workspace:FindFirstChild(fname)
            if folder then
                checkOrbFolder(folder)
                addConn("orb_watch_" .. fname, folder.ChildAdded:Connect(function()
                    markEvidence("GhostOrb")
                    notify("🔮 Ghost Orb appeared in " .. fname .. "!", C.EvidOrb, 5)
                end))
            end
        end

        -- persistent workspace scan (catches dynamically spawned folders or parts)
        addConn("orb_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Ghost Orb Detector"] then return end
            if S.Evidence["GhostOrb"] then return end -- already found, chill
            for _, d in pairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("MeshPart") or d:IsA("SpecialMesh") then
                    local nm = d.Name:lower()
                    for _, kw in ipairs(orbPartNames) do
                        if nm:find(kw) then
                            markEvidence("GhostOrb")
                            notify("🔮 Ghost Orb part found: " .. d.Name, C.EvidOrb, 5)
                            return
                        end
                    end
                end
            end
        end))
        notify("🔮 Orb detector active (multi-scan)", C.Green, 3)
    end)

    -- Inscription Detector
    makeToggle(evidPage, "Inscription Detector", "Watch for ghost writing", 6, function(on)
        rmConn("inscr_watch")
        if not on then return end
        local folder = Workspace:FindFirstChild("ScratchText")
        if folder then
            addConn("inscr_watch", folder.ChildAdded:Connect(function()
                markEvidence("Inscription")
                notify("✍ Inscription found!", C.EvidInscript, 5)
            end))
            if #folder:GetChildren() > 0 then markEvidence("Inscription") end
            notify("✍ Inscription detector active", C.Green, 3)
        else
            notify("⚠ ScratchText folder not found", C.Yellow, 3)
        end
    end)

    -- Wither Detector
    makeToggle(evidPage, "Wither Detector", "Monitor for plant wilting effects", 7, function(on)
        rmConn("wither_watch")
        if not on then return end
        addConn("wither_watch", Workspace.DescendantAdded:Connect(function(d)
            local nm = d.Name:lower()
            if nm:find("wither") or nm:find("wilt") or nm:find("dead_plant") or nm:find("deadplant") then
                markEvidence("Wither")
                notify("🥀 Wither evidence!", C.EvidWither, 5)
            end
        end))
        notify("🥀 Wither detector active", C.Green, 3)
    end)

    -- ═══ FIX: LASER PROJECTOR DETECTOR ═══
    -- Old: only watched LIDAR folder. Now: multi-folder + remote hook + part name scan.
    makeToggle(evidPage, "Laser Detector", "Watch for laser projector (fixed)", 8, function(on)
        rmConn("laser_watch")
        rmConn("laser_scan")
        if not on then return end

        local laserFolders = {"LIDAR", "Laser", "LaserProjector", "Projector", "LiDAR"}
        local laserKeywords = {"lidar", "laser", "projector", "silhouette"}

        -- folder watchers
        local foundFolder = false
        for _, fname in ipairs(laserFolders) do
            local folder = Workspace:FindFirstChild(fname)
            if folder then
                foundFolder = true
                if #folder:GetChildren() > 0 then markEvidence("Laser") end
                addConn("laser_watch_" .. fname, folder.ChildAdded:Connect(function()
                    markEvidence("Laser")
                    notify("🔴 Laser silhouette in " .. fname .. "!", C.EvidLaser, 5)
                end))
            end
        end

        -- remote hook for laser-named events
        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local nm = r.Name:lower()
                for _, kw in ipairs(laserKeywords) do
                    if nm:find(kw) then
                        addConn("laser_remote", r.OnClientEvent:Connect(function()
                            markEvidence("Laser")
                            notify("🔴 Laser remote fired: " .. r.Name, C.EvidLaser, 5)
                        end))
                        notify("🔴 Laser remote hooked: " .. r.Name, C.Green, 2)
                        break
                    end
                end
            end
        end

        -- workspace scan fallback
        addConn("laser_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Laser Detector"] then return end
            if S.Evidence["Laser"] then return end
            for _, d in pairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("Model") then
                    local nm = d.Name:lower()
                    for _, kw in ipairs(laserKeywords) do
                        if nm:find(kw) then
                            markEvidence("Laser")
                            notify("🔴 Laser part found: " .. d.Name, C.EvidLaser, 5)
                            return
                        end
                    end
                end
            end
        end))

        notify("🔴 Laser detector active (" .. (foundFolder and "folder found" or "scanning") .. ")", C.Green, 3)
    end)

    -- Reset Evidence button
    local resetBtn = Instance.new("Frame")
    resetBtn.Size = UDim2.new(1, 0, 0, 36)
    resetBtn.BackgroundColor3 = C.Red
    resetBtn.BackgroundTransparency = 0.85
    resetBtn.BorderSizePixel = 0
    resetBtn.LayoutOrder = 20
    resetBtn.Parent = evidPage
    corner(resetBtn, UDim.new(0, 7))
    stroke(resetBtn, C.Red, 1, 0.6)

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

    resetBtn.MouseEnter:Connect(function() tw(resetBtn, {BackgroundTransparency = 0.6}, C.SpeedFast) end)
    resetBtn.MouseLeave:Connect(function() tw(resetBtn, {BackgroundTransparency = 0.85}, C.SpeedFast) end)

    -- ═══════════════════════════════════════
    --   PAGE: GHOST ID
    -- ═══════════════════════════════════════
    local ghostPage = makePage("Ghost ID")

    local evidStatusFrame = Instance.new("Frame")
    evidStatusFrame.Size = UDim2.new(1, 0, 0, 80)
    evidStatusFrame.BackgroundColor3 = C.Bg3
    evidStatusFrame.BackgroundTransparency = 0.3
    evidStatusFrame.BorderSizePixel = 0
    evidStatusFrame.LayoutOrder = 1
    evidStatusFrame.Parent = ghostPage
    corner(evidStatusFrame, UDim.new(0, 7))

    local evidTitle = Instance.new("TextLabel")
    evidTitle.Size = UDim2.new(1, 0, 0, 16)
    evidTitle.Position = UDim2.new(0, 8, 0, 4)
    evidTitle.BackgroundTransparency = 1
    evidTitle.Text = "FOUND EVIDENCE"
    evidTitle.TextColor3 = C.AccentDim
    evidTitle.Font = C.Font
    evidTitle.TextSize = 9
    evidTitle.TextXAlignment = Enum.TextXAlignment.Left
    evidTitle.Parent = evidStatusFrame

    local evidGrid = Instance.new("Frame")
    evidGrid.Size = UDim2.new(1, -16, 0, 50)
    evidGrid.Position = UDim2.new(0, 8, 0, 22)
    evidGrid.BackgroundTransparency = 1
    evidGrid.Parent = evidStatusFrame

    local evidGridLayout = Instance.new("UIGridLayout")
    evidGridLayout.CellSize = UDim2.new(0, 52, 0, 22)
    evidGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
    evidGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    evidGridLayout.Parent = evidGrid

    local evidIndicators = {}
    for i, ev in ipairs(EvidenceTypes) do
        local ind = Instance.new("Frame")
        ind.Name = ev.id
        ind.BackgroundColor3 = C.Bg4
        ind.BackgroundTransparency = 0.3
        ind.BorderSizePixel = 0
        ind.LayoutOrder = i
        ind.Parent = evidGrid
        corner(ind, UDim.new(0, 4))

        local il = Instance.new("TextLabel")
        il.Size = UDim2.new(1, 0, 1, 0)
        il.BackgroundTransparency = 1
        il.Text = ev.icon
        il.TextSize = 10
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
            updateHUD()
            updateGhostPanel()
            updateEvidencePanel()
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
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1e5
            Lighting.FogStart = 1e5
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        else
            if S._origLight then
                for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end
            end
        end
    end)

    makeToggle(survPage, "Night Vision", "Green-tinted enhanced visibility", 2, function(on)
        if on then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "HubNV"
            cc.Brightness = 0.15
            cc.Contrast = 0.1
            cc.Saturation = -0.5
            cc.TintColor = Color3.fromRGB(130, 255, 130)
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

    -- ═══ NEW: AUTO HIDE ON HUNT ═══
    makeToggle(survPage, "Auto Hide on Hunt", "TP into nearest closet when hunt starts", 5, function(on)
        rmConn("hunt_remote")
        rmConn("hunt_scan")
        if not on then return end

        -- hook hunt-related remotes
        local huntKeywords = {"hunt", "huntstart", "huntbegin", "ghosthunt", "chase", "huntstate"}
        local endKeywords   = {"huntend", "huntstop", "safe", "huntover"}

        for _, r in pairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local nm = r.Name:lower()
                for _, kw in ipairs(huntKeywords) do
                    if nm:find(kw) then
                        addConn("hunt_remote", r.OnClientEvent:Connect(function(...)
                            local args = {...}
                            -- check if it's an end signal packed in same remote
                            for _, kw2 in ipairs(endKeywords) do
                                if nm:find(kw2) then onHuntEnd() return end
                            end
                            -- some games pass bool/string for start/stop
                            local isEnd = false
                            for _, v in ipairs(args) do
                                if v == false or tostring(v):lower():find("stop") or tostring(v):lower():find("end") then
                                    isEnd = true break
                                end
                            end
                            if isEnd then onHuntEnd() else onHuntStart() end
                        end))
                        notify("👻 Hunt remote hooked: " .. r.Name, C.Green, 3)
                        break
                    end
                end
            end
        end

        -- fallback: watch for hunt-state BoolValues or NumberValues in workspace
        addConn("hunt_scan", RunService.Heartbeat:Connect(function()
            if not S.Features["Auto Hide on Hunt"] then return end
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BoolValue") then
                    local nm = v.Name:lower()
                    if nm:find("hunt") or nm:find("chasing") or nm:find("ghostactive") then
                        if v.Value == true and not huntActive then
                            onHuntStart()
                        elseif v.Value == false and huntActive then
                            onHuntEnd()
                        end
                    end
                end
            end
        end))

        notify("🛡 Hunt auto-hide armed", C.Green, 3)
    end)

    -- Manual hide button
    local hideBtn = Instance.new("Frame")
    hideBtn.Size = UDim2.new(1, 0, 0, 36)
    hideBtn.BackgroundColor3 = C.Blue
    hideBtn.BackgroundTransparency = 0.85
    hideBtn.BorderSizePixel = 0
    hideBtn.LayoutOrder = 6
    hideBtn.Parent = survPage
    corner(hideBtn, UDim.new(0, 7))
    stroke(hideBtn, C.Blue, 1, 0.6)

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

    hideBtn.MouseEnter:Connect(function() tw(hideBtn, {BackgroundTransparency = 0.6}, C.SpeedFast) end)
    hideBtn.MouseLeave:Connect(function() tw(hideBtn, {BackgroundTransparency = 0.85}, C.SpeedFast) end)

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
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 1e6
        else
            if S._origFog then
                Lighting.FogEnd = S._origFog.FogEnd
                Lighting.FogStart = S._origFog.FogStart
            end
        end
    end)

    makeToggle(visPage, "No Weather", "Disable clouds & atmosphere", 3, function(on)
        if on then
            local t = Workspace:FindFirstChildOfClass("Terrain")
            if t then for _, ch in pairs(t:GetChildren()) do if ch:IsA("Clouds") then ch.Enabled = false end end end
            for _, e in pairs(Lighting:GetChildren()) do
                if e:IsA("Atmosphere") then e.Density = 0 end
            end
        else
            local t = Workspace:FindFirstChildOfClass("Terrain")
            if t then for _, ch in pairs(t:GetChildren()) do if ch:IsA("Clouds") then ch.Enabled = true end end end
        end
    end)

    makeToggle(visPage, "No Shake", "Stabilize camera shake", 4, function(on)
        notify(on and "📷 Shake dampening active" or "📷 Shake dampening off", C.Green, 2)
    end)

    -- ═══════════════════════════════════════
    --   PAGE: TOOLS (TP to Exit FIXED)
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
            if c then
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end))
    end)

    -- ═══ FIX: TP TO EXIT ═══
    -- Old code looked for "ExitDoor" exact name — most games use different names.
    -- Now: scans all door models for exit-related keywords, falls back to
    -- nearest door model if nothing matches, then ultimate fallback to workspace scan.
    makeToggle(toolsPage, "TP to Exit", "Teleport to exit (fixed)", 3, function(on)
        if not on then return end

        local char = LocalPlayer.Character
        if not char then notify("⚠ No character", C.Red, 3) return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then notify("⚠ No HumanoidRootPart", C.Red, 3) return end
        local hum = char:FindFirstChildOfClass("Humanoid")

        local exitKeywords = {"exit", "escape", "door_out", "outdoors", "exitdoor", "leave", "maindoor"}
        local bestPart, bestScore = nil, -1

        -- search Doors folder first
        local function scoreModel(model)
            local nm = model.Name:lower()
            for i, kw in ipairs(exitKeywords) do
                if nm:find(kw) then
                    return (#exitKeywords - i + 1) * 10 -- higher score = more exit-like
                end
            end
            return 0
        end

        local df = Workspace:FindFirstChild("Doors")
        if df then
            for _, dm in pairs(df:GetChildren()) do
                if dm:IsA("Model") then
                    local score = scoreModel(dm)
                    if score > bestScore then
                        local p = dm:FindFirstChildWhichIsA("BasePart", true)
                        if p then bestPart = p bestScore = score end
                    end
                end
            end
        end

        -- if nothing scored, grab nearest door model
        if not bestPart and df then
            local closestDist = math.huge
            for _, dm in pairs(df:GetChildren()) do
                if dm:IsA("Model") then
                    local p = dm:FindFirstChildWhichIsA("BasePart", true)
                    if p then
                        local dist = (hrp.Position - p.Position).Magnitude
                        if dist < closestDist then closestDist = dist bestPart = p end
                    end
                end
            end
        end

        -- ultimate fallback: scan entire workspace for exit-named parts
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
            -- prevent ragdoll on teleport
            if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
            hrp.CFrame = CFrame.new(bestPart.Position + Vector3.new(0, 4, 5))
            task.wait(0.05)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
            notify("🚪 Teleported to Exit: " .. bestPart.Parent.Name, C.Green, 3)
        else
            notify("⚠ Exit door not found in workspace", C.Yellow, 4)
        end

        -- toggle back off (one-shot)
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
        lf.BackgroundColor3 = C.Bg1
        lf.BackgroundTransparency = 0.18
        lf.BorderSizePixel = 0
        lf.Parent = Hub
        corner(lf, UDim.new(0, 8))
        stroke(lf, C.AccentDim, 1, 0.6)
        S._logFrame = lf

        local lt = Instance.new("TextLabel")
        lt.Size = UDim2.new(1, 0, 0, 24)
        lt.BackgroundColor3 = C.Bg2
        lt.BackgroundTransparency = 0.25
        lt.BorderSizePixel = 0
        lt.Text = "  📡 Remote Logger"
        lt.TextColor3 = C.AccentBright
        lt.Font = C.Font
        lt.TextSize = 10
        lt.TextXAlignment = Enum.TextXAlignment.Left
        lt.Parent = lf
        corner(lt, UDim.new(0, 8))

        local ls = Instance.new("ScrollingFrame")
        ls.Size = UDim2.new(1, -6, 1, -30)
        ls.Position = UDim2.new(0, 3, 0, 27)
        ls.BackgroundTransparency = 1
        ls.BorderSizePixel = 0
        ls.ScrollBarThickness = 2
        ls.ScrollBarImageColor3 = C.AccentDim
        ls.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ls.CanvasSize = UDim2.new(0, 0, 0, 0)
        ls.Parent = lf

        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 2)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = ls

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
                        e.BackgroundColor3 = C.Bg3
                        e.BackgroundTransparency = 0.5
                        e.BorderSizePixel = 0
                        e.Text = " ← " .. r.Name .. "\n " .. argStr
                        e.TextColor3 = C.Blue
                        e.Font = C.FontReg
                        e.TextSize = 9
                        e.TextXAlignment = Enum.TextXAlignment.Left
                        e.TextYAlignment = Enum.TextYAlignment.Top
                        e.LayoutOrder = idx
                        e.Parent = ls
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
                tw(d.button, {BackgroundTransparency = 0.82}, C.Speed)
                tw(d.label, {TextColor3 = C.AccentBright}, C.Speed)
            else
                tw(d.button, {BackgroundTransparency = 1}, C.Speed)
                tw(d.label, {TextColor3 = C.Text2}, C.Speed)
            end
        end
    end

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
            if i > 12 then break end
            local gf = Instance.new("Frame")
            gf.Size = UDim2.new(1, 0, 0, 36)
            gf.BackgroundColor3 = C.Bg3
            gf.BackgroundTransparency = 0.4
            gf.BorderSizePixel = 0
            gf.LayoutOrder = i
            gf.Parent = S._ghostPanel
            corner(gf, UDim.new(0, 6))

            if i == 1 and ghost.confidence > 0 then
                stroke(gf, C.Green, 1, 0.5)
            end

            local gName = Instance.new("TextLabel")
            gName.Size = UDim2.new(0.5, 0, 0, 16)
            gName.Position = UDim2.new(0, 8, 0, 4)
            gName.BackgroundTransparency = 1
            gName.Text = (i == 1 and ghost.confidence > 0) and ("👻 " .. ghost.name) or ghost.name
            gName.TextColor3 = (i == 1 and ghost.confidence > 0) and C.Green or C.Text1
            gName.Font = C.FontMed
            gName.TextSize = 11
            gName.TextXAlignment = Enum.TextXAlignment.Left
            gName.Parent = gf

            local confBg = Instance.new("Frame")
            confBg.Size = UDim2.new(0, 60, 0, 6)
            confBg.Position = UDim2.new(1, -80, 0, 8)
            confBg.BackgroundColor3 = C.Bg4
            confBg.BorderSizePixel = 0
            confBg.Parent = gf
            corner(confBg, UDim.new(1, 0))

            local confFill = Instance.new("Frame")
            confFill.Size = UDim2.new(ghost.confidence / 100, 0, 1, 0)
            confFill.BackgroundColor3 = ghost.confidence >= 66 and C.Green or ghost.confidence >= 33 and C.Yellow or C.Text3
            confFill.BorderSizePixel = 0
            confFill.Parent = confBg
            corner(confFill, UDim.new(1, 0))

            local confTxt = Instance.new("TextLabel")
            confTxt.Size = UDim2.new(0, 20, 0, 12)
            confTxt.Position = UDim2.new(1, -16, 0, 5)
            confTxt.BackgroundTransparency = 1
            confTxt.Text = ghost.confidence .. "%"
            confTxt.TextColor3 = C.Text3
            confTxt.Font = C.FontReg
            confTxt.TextSize = 9
            confTxt.Parent = gf

            local tagParts = {}
            for _, ev in ipairs(ghost.evidence) do
                local found = S.Evidence[ev]
                for _, evInfo in ipairs(EvidenceTypes) do
                    if evInfo.id == ev then
                        table.insert(tagParts, (found and "✓" or "·") .. evInfo.icon)
                        break
                    end
                end
            end
            local evidTags = Instance.new("TextLabel")
            evidTags.Size = UDim2.new(1, -16, 0, 12)
            evidTags.Position = UDim2.new(0, 8, 0, 21)
            evidTags.BackgroundTransparency = 1
            evidTags.Text = table.concat(tagParts, "  ")
            evidTags.TextColor3 = C.Text3
            evidTags.Font = C.FontReg
            evidTags.TextSize = 9
            evidTags.TextXAlignment = Enum.TextXAlignment.Left
            evidTags.Parent = gf
        end
    end

    function updateEvidencePanel()
        if not S._evidPanel then return end
        for id, data in pairs(S._evidPanel) do
            local found = S.Evidence[id]
            for _, ev in ipairs(EvidenceTypes) do
                if ev.id == id then
                    if found then
                        tw(data.frame, {BackgroundColor3 = ev.color, BackgroundTransparency = 0.5}, C.SpeedFast)
                        data.label.TextColor3 = C.Text1
                    else
                        tw(data.frame, {BackgroundColor3 = C.Bg4, BackgroundTransparency = 0.3}, C.SpeedFast)
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
        pcall(function() Lighting:FindFirstChild("HubBlur"):Destroy() end)
        if S._origLight then for k, v in pairs(S._origLight) do pcall(function() Lighting[k] = v end) end end
        if S._origFog then pcall(function()
            Lighting.FogEnd = S._origFog.FogEnd
            Lighting.FogStart = S._origFog.FogStart
        end) end
        pcall(function() EvidHudGui:Destroy() end)
        tw(MainFrame, {Size = UDim2.new(0, 580, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        Hub:Destroy()
    end)

    minBtn.MouseButton1Click:Connect(function()
        S.Visible = not S.Visible
        if S.Visible then
            MainFrame.Visible = true
            tw(MainFrame, {Size = UDim2.new(0, 580, 0, 460)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tw(MainFrame, {Size = UDim2.new(0, 580, 0, 42)}, 0.2)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == C.Key then
            S.Visible = not S.Visible
            if S.Visible then
                MainFrame.Visible = true
                MainFrame.BackgroundTransparency = 0.6
                tw(MainFrame, {BackgroundTransparency = 0.18}, 0.25)
            else
                tw(MainFrame, {BackgroundTransparency = 1}, 0.2)
                task.wait(0.25)
                MainFrame.Visible = false
            end
        end
    end)

    -- ═══ OPEN ANIMATION ═══
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundTransparency = 0.8
    task.wait(0.1)
    tw(MainFrame, {
        BackgroundTransparency = 0.18,
        Size = UDim2.new(0, 580, 0, 460),
        Position = UDim2.new(0.5, -290, 0.5, -230)
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.wait(0.6)
    notify("🕯 Demonology Hub v2.1 loaded", C.Accent, 4)
    notify("made by 1nxs on discord", C.Text3, 5)
    notify("RightShift to toggle", C.Text3, 4)
end

----------------------------------------------
-- LAUNCH SEQUENCE
----------------------------------------------
showLoadingScreen(function()
    buildEvidHUD()
    buildHub()
end)

print("[1nxs Hub] ✅ v2.1 Loaded — fixes: Freezing, GhostOrb, Laser, TP to Exit | new: Hunt TP, Evidence HUD")
