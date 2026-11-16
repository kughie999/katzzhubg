-- language: Lua, file: katzhub.lua, target: Roblox Executor (Universal)
-- Elimination remote exploit: Alert spoof, vote redirect, notification farm

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ─── REMOTE DISCOVERY ───────────────────────────────────────────────────────
local function findRemote(name)
    local t = {ReplicatedStorage}
    while #t > 0 do
        local node = table.remove(t, 1)
        for _, v in ipairs(node:GetChildren()) do
            if v.Name == name then return v end
            table.insert(t, v)
        end
    end
    return nil
end

local AlertEvent        = findRemote("Alert")
local CameraShakeEvent  = findRemote("CameraShake")
local NotificationEvent = findRemote("Notification")

-- ─── UI SETUP ───────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KatzHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- goreact compatível: tenta CoreGui primeiro
local ok = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Frame principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Borda verde sutil
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 220, 80)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.4

-- ─── TOPBAR ─────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

-- fix corners só no topo
local CornerFix = Instance.new("Frame")
CornerFix.Size = UDim2.new(1, 0, 0.5, 0)
CornerFix.Position = UDim2.new(0, 0, 0.5, 0)
CornerFix.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
CornerFix.BorderSizePixel = 0
CornerFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Text = "⚡ Katz Hub"
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Botões da janela
local function makeWinBtn(symbol, posX, bgColor)
    local btn = Instance.new("TextButton")
    btn.Text = symbol
    btn.Size = UDim2.new(0, 24, 0, 24)
    btn.Position = UDim2.new(1, posX, 0.5, -12)
    btn.BackgroundColor3 = bgColor
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = TopBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    return btn
end

local CloseBtn    = makeWinBtn("✕", -32,  Color3.fromRGB(220, 50, 50))
local MinimizeBtn = makeWinBtn("─", -60,  Color3.fromRGB(220, 180, 0))
local MaximizeBtn = makeWinBtn("□", -88,  Color3.fromRGB(0, 180, 60))

-- ─── CONTEÚDO ───────────────────────────────────────────────────────────────
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -10, 1, -46)
Content.Position = UDim2.new(0, 5, 0, 41)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(0, 220, 80)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

Instance.new("UIPadding", Content).PaddingTop = UDim.new(0, 6)

-- ─── HELPERS DE UI ──────────────────────────────────────────────────────────
local function sectionLabel(txt)
    local lbl = Instance.new("TextLabel")
    lbl.Text = txt
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(0, 220, 80)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Content
    return lbl
end

local function makeButton(label, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Text = label
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    btn.TextColor3 = Color3.fromRGB(0, 220, 80)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.LayoutOrder = layoutOrder or 0
    btn.Parent = Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(0, 180, 60)
    stroke.Thickness = 1
    stroke.Transparency = 0.6

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(0, 50, 20)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        }):Play()
    end)
    return btn
end

local function makeToggle(label, layoutOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder or 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Color3.fromRGB(0, 180, 60)
    stroke.Thickness = 1
    stroke.Transparency = 0.6

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, -10)
    pill.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    pill.BorderSizePixel = 0
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = false
    local callbacks = {}

    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1, 0, 1, 0)
    clickZone.BackgroundTransparency = 1
    clickZone.Text = ""
    clickZone.Parent = row

    clickZone.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(0, 180, 60) or Color3.fromRGB(50, 50, 50)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        }):Play()
        for _, cb in ipairs(callbacks) do cb(state) end
    end)

    return {
        frame = row,
        getState = function() return state end,
        onChange = function(cb) table.insert(callbacks, cb) end
    }
end

local function statusLabel(parent)
    local lbl = Instance.new("TextLabel")
    lbl.Text = ""
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(0, 220, 80)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent or Content
    return lbl
end

-- ─── STATUS GERAL ────────────────────────────────────────────────────────────
sectionLabel("── STATUS ──")
local statusMain = statusLabel(Content)

local function setStatus(msg, color)
    statusMain.Text = "● " .. msg
    statusMain.TextColor3 = color or Color3.fromRGB(0, 220, 80)
end

setStatus("Remotes carregados: " ..
    (AlertEvent and "Alert✓ " or "Alert✗ ") ..
    (CameraShakeEvent and "CameraShake✓ " or "CameraShake✗ ") ..
    (NotificationEvent and "Notif✓" or "Notif✗"))

-- ─── SEÇÃO 1: VOTE SPOOF ─────────────────────────────────────────────────────
-- Alert arg3/arg4 = userId strings — spoofa voto apontando para alvo
sectionLabel("── VOTE SPOOF ──")

local targetInput = Instance.new("TextBox")
targetInput.PlaceholderText = "Username alvo (ex: santiagoleon2026)"
targetInput.Size = UDim2.new(1, -10, 0, 34)
targetInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetInput.TextColor3 = Color3.fromRGB(0, 220, 80)
targetInput.PlaceholderColor3 = Color3.fromRGB(80, 120, 80)
targetInput.Font = Enum.Font.Gotham
targetInput.TextSize = 12
targetInput.BorderSizePixel = 0
targetInput.Text = ""
targetInput.Parent = Content
Instance.new("UICorner", targetInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", targetInput).Color = Color3.fromRGB(0, 180, 60)

local voteBtn = makeButton("🎯  Disparar Voto no Alvo", 2)
local voteStatus = statusLabel(Content)

local function getTargetUserId(username)
    -- tenta resolver pelo Players local primeiro, depois enumera
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == username:lower() then
            return tostring(p.UserId)
        end
    end
    return username -- fallback: passa o nome direto como arg
end

voteBtn.MouseButton1Click:Connect(function()
    if not AlertEvent then
        voteStatus.Text = "✗ AlertEvent não encontrado"
        voteStatus.TextColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    local target = targetInput.Text:match("^%s*(.-)%s*$")
    if target == "" then
        voteStatus.Text = "✗ Digite um alvo"
        voteStatus.TextColor3 = Color3.fromRGB(220, 180, 0)
        return
    end
    local uid = getTargetUserId(target)
    -- replica exatamente o formato capturado: nil, true, userId, userId
    AlertEvent:FireServer(nil, true, uid, uid)
    voteStatus.Text = "✓ Voto enviado → " .. target
    voteStatus.TextColor3 = Color3.fromRGB(0, 220, 80)
end)

-- ─── SEÇÃO 2: AUTO-VOTE LOOP ──────────────────────────────────────────────────
sectionLabel("── AUTO-VOTE LOOP ──")

local autoVoteToggle = makeToggle("Auto-Vote contínuo no alvo", 3)
local autoVoteStatus = statusLabel(Content)
local autoVoteConn

autoVoteToggle.onChange(function(on)
    if on then
        local target = targetInput.Text:match("^%s*(.-)%s*$")
        if target == "" or not AlertEvent then
            autoVoteStatus.Text = "✗ Defina o alvo primeiro"
            autoVoteStatus.TextColor3 = Color3.fromRGB(220, 50, 50)
            autoVoteToggle.frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
            return
        end
        local uid = getTargetUserId(target)
        local count = 0
        autoVoteConn = RunService.Heartbeat:Connect(function()
            -- dispara 1x por segundo para não saturar
            count = count + 1
            if count >= 60 then
                count = 0
                AlertEvent:FireServer(nil, true, uid, uid)
                autoVoteStatus.Text = "● Loop ativo → " .. target
                autoVoteStatus.TextColor3 = Color3.fromRGB(0, 220, 80)
            end
        end)
    else
        if autoVoteConn then autoVoteConn:Disconnect() autoVoteConn = nil end
        autoVoteStatus.Text = "○ Loop parado"
        autoVoteStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

-- ─── SEÇÃO 3: CAMERA SHAKE SPAM ──────────────────────────────────────────────
-- CameraShake: 10, 1, true — envia para todos ou para si mesmo via cliente
sectionLabel("── CAMERA SHAKE SPAM ──")

local shakeBtn = makeButton("📷  Spammar CameraShake (inimigos)", 4)
local shakeStatus = statusLabel(Content)
local shaking = false

shakeBtn.MouseButton1Click:Connect(function()
    if not CameraShakeEvent then
        shakeStatus.Text = "✗ CameraShakeEvent não encontrado"
        shakeStatus.TextColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    shaking = not shaking
    shakeBtn.Text = shaking and "■  Parar Shake" or "📷  Spammar CameraShake (inimigos)"
    if shaking then
        shakeStatus.Text = "● Shake ativo"
        shakeStatus.TextColor3 = Color3.fromRGB(0, 220, 80)
        task.spawn(function()
            while shaking do
                CameraShakeEvent:FireServer(10, 1, true)
                task.wait(0.3)
            end
            shakeStatus.Text = "○ Shake parado"
            shakeStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end)
    end
end)

-- ─── SEÇÃO 4: FAKE NOTIFICATION ──────────────────────────────────────────────
-- Notification: 2, string — pode injetar texto falso na UI de outros jogadores
sectionLabel("── FAKE NOTIFICATION ──")

local notifInput = Instance.new("TextBox")
notifInput.PlaceholderText = "Texto da notificação falsa..."
notifInput.Size = UDim2.new(1, -10, 0, 34)
notifInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
notifInput.TextColor3 = Color3.fromRGB(0, 220, 80)
notifInput.PlaceholderColor3 = Color3.fromRGB(80, 120, 80)
notifInput.Font = Enum.Font.Gotham
notifInput.TextSize = 12
notifInput.BorderSizePixel = 0
notifInput.Text = ""
notifInput.Parent = Content
Instance.new("UICorner", notifInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", notifInput).Color = Color3.fromRGB(0, 180, 60)

local notifBtn = makeButton("📢  Enviar Notificação Falsa", 5)
local notifStatus = statusLabel(Content)

notifBtn.MouseButton1Click:Connect(function()
    if not NotificationEvent then
        notifStatus.Text = "✗ NotificationEvent não encontrado"
        notifStatus.TextColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    local msg = notifInput.Text:match("^%s*(.-)%s*$")
    if msg == "" then msg = "Katz Hub says hi 👋" end
    -- formato capturado: 2, string
    NotificationEvent:FireServer(2, msg)
    notifStatus.Text = "✓ Notificação enviada"
    notifStatus.TextColor3 = Color3.fromRGB(0, 220, 80)
end)

-- ─── SEÇÃO 5: SPY / MONITOR ───────────────────────────────────────────────────
sectionLabel("── SPY DE REMOTES ──")

local spyToggle = makeToggle("Monitorar todos os remotes recebidos", 6)
local spyLog = Instance.new("TextLabel")
spyLog.Size = UDim2.new(1, -10, 0, 60)
spyLog.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
spyLog.TextColor3 = Color3.fromRGB(0, 180, 60)
spyLog.Font = Enum.Font.Code
spyLog.TextSize = 10
spyLog.TextXAlignment = Enum.TextXAlignment.Left
spyLog.TextYAlignment = Enum.TextYAlignment.Top
spyLog.TextWrapped = true
spyLog.BorderSizePixel = 0
spyLog.Text = "nenhum evento ainda..."
spyLog.Parent = Content
Instance.new("UICorner", spyLog).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", spyLog).PaddingLeft = UDim.new(0, 4)

local spyConns = {}

local function hookRemote(evt, name)
    if not evt then return end
    local conn = evt.OnClientEvent:Connect(function(...)
        local args = {...}
        local parts = {}
        for i, v in ipairs(args) do
            parts[i] = tostring(v)
        end
        spyLog.Text = "[" .. name .. "] " .. table.concat(parts, ", ")
    end)
    table.insert(spyConns, conn)
end

spyToggle.onChange(function(on)
    if on then
        hookRemote(AlertEvent, "Alert")
        hookRemote(CameraShakeEvent, "CameraShake")
        hookRemote(NotificationEvent, "Notification")
        spyLog.Text = "● monitorando..."
    else
        for _, c in ipairs(spyConns) do c:Disconnect() end
        spyConns = {}
        spyLog.Text = "○ spy desligado"
    end
end)

-- ─── SEÇÃO 6: UTILS ───────────────────────────────────────────────────────────
sectionLabel("── UTILS ──")

local listBtn = makeButton("👥  Listar Jogadores no Output", 7)
listBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        print(string.format("[KatzHub] %s | UserId: %d", p.Name, p.UserId))
    end
    setStatus("Jogadores listados no output", Color3.fromRGB(0, 220, 80))
end)

local copyIdBtn = makeButton("📋  Copiar UserId do Alvo", 8)
copyIdBtn.MouseButton1Click:Connect(function()
    local target = targetInput.Text:match("^%s*(.-)%s*$")
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == target:lower() then
            setclipboard and setclipboard(tostring(p.UserId))
            setStatus("UserId " .. p.UserId .. " copiado", Color3.fromRGB(0, 220, 80))
            return
        end
    end
    setStatus("Alvo não encontrado nos players", Color3.fromRGB(220, 180, 0))
end)

-- ─── DRAG ────────────────────────────────────────────────────────────────────
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ─── BOTÕES DA JANELA ────────────────────────────────────────────────────────
local minimized = false
local normalSize = MainFrame.Size

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(MainFrame, TweenInfo.new(0.2), {
        Size = minimized and UDim2.new(0, 400, 0, 36) or normalSize
    }):Play()
    Content.Visible = not minimized
end)

MaximizeBtn.MouseButton1Click:Connect(function()
    minimized = false
    normalSize = UDim2.new(0, 400, 0, 500)
    TweenService:Create(MainFrame, TweenInfo.new(0.2), {
        Size = normalSize
    }):Play()
    Content.Visible = true
end)

-- ─── OPEN ANIM ───────────────────────────────────────────────────────────────
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 400, 0, 500),
    Position = UDim2.new(0.5, -200, 0.5, -250)
}):Play()

print("[KatzHub] carregado. Remotes:", AlertEvent, CameraShakeEvent, NotificationEvent)
