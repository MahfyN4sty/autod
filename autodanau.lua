-- Auto Fishing Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Konfigurasi
local config = {
    autoClick = true,
    clickDelay = 0.05,
    smartClick = true,
    autoRecast = true,
    castHoldTime = 0.6,
    enabled = false
}

-- Status
local isMinigameActive = false
local isCasting = false
local clickConnection = nil
local lastCastTime = 0

-- Performance Monitoring
local currentFPS = 0
local currentPing = 0
local packetLoss = 0
local frameCount = 0
local lastFPSUpdate = tick()

-- Fungsi untuk hold click (cast fishing rod)
local function holdClick(duration)
    local mouse = player:GetMouse()
    local screenCenter = workspace.CurrentCamera.ViewportSize / 2
    
    VirtualInputManager:SendMouseButtonEvent(
        screenCenter.X,
        screenCenter.Y,
        0,
        true,
        game,
        0
    )
    
    task.wait(duration)
    
    VirtualInputManager:SendMouseButtonEvent(
        screenCenter.X,
        screenCenter.Y,
        0,
        false,
        game,
        0
    )
end

-- Fungsi untuk cast fishing rod
local function castFishingRod()
    if isCasting then return end
    
    isCasting = true
    print("🎣 Casting fishing rod...")
    
    holdClick(config.castHoldTime)
    
    lastCastTime = tick()
    task.wait(0.5)
    isCasting = false
end

-- Fungsi untuk mensimulasikan tap cepat (minigame)
local function quickTap()
    local mouse = player:GetMouse()
    local screenCenter = workspace.CurrentCamera.ViewportSize / 2
    
    VirtualInputManager:SendMouseButtonEvent(
        screenCenter.X,
        screenCenter.Y,
        0,
        true,
        game,
        0
    )
    
    task.wait(0.01)
    
    VirtualInputManager:SendMouseButtonEvent(
        screenCenter.X,
        screenCenter.Y,
        0,
        false,
        game,
        0
    )
end

-- Deteksi minigame UI
local function detectMinigame()
    local miniGameGui = playerGui:FindFirstChild("MiniGameGUI")
    if miniGameGui then
        local background = miniGameGui:FindFirstChild("Background")
        if background then
            local filler = background:FindFirstChild("Filler")
            return filler ~= nil, filler
        end
    end
    return false, nil
end

-- Auto click minigame
local function startAutoClick()
    if clickConnection then
        clickConnection:Disconnect()
    end
    
    clickConnection = RunService.Heartbeat:Connect(function()
        if not config.enabled or not config.autoClick or isCasting then
            return
        end
        
        local active, filler = detectMinigame()
        isMinigameActive = active
        
        if active and filler then
            if config.smartClick then
                if filler.Size.X.Scale < 1 then
                    quickTap()
                    task.wait(config.clickDelay)
                end
            else
                quickTap()
                task.wait(config.clickDelay)
            end
        end
    end)
end

-- Monitor untuk auto recast
local function monitorForRecast()
    task.spawn(function()
        while config.enabled do
            task.wait(1)
            
            if config.autoRecast and not isMinigameActive and not isCasting then
                local active = detectMinigame()
                if not active then
                    if tick() - lastCastTime >= 1 then
                        castFishingRod()
                    end
                end
            end
        end
    end)
end

-- Fungsi untuk menghitung FPS
local function startFPSCounter()
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastFPSUpdate >= 1 then
            currentFPS = frameCount
            frameCount = 0
            lastFPSUpdate = currentTime
        end
    end)
end

-- Fungsi untuk mendapatkan Ping
local function updatePing()
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            local success, result = pcall(function()
                local ping = player:GetNetworkPing()
                return math.floor(ping * 1000)
            end)
            
            if success and result then
                currentPing = result
            else
                -- Fallback method
                local success2, statsItem = pcall(function()
                    return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                end)
                
                if success2 and statsItem then
                    local pingMatch = string.match(statsItem, "(%d+)")
                    if pingMatch then
                        currentPing = tonumber(pingMatch) or 0
                    end
                end
            end
        end
    end)
end

-- GUI Control Panel
local function createControlPanel()
    -- Hapus GUI lama jika ada
    local oldGui = playerGui:FindFirstChild("AutoFishingGUI")
    if oldGui then
        oldGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFishingGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 250, 0, 230)
    frame.Position = UDim2.new(0.85, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    title.BorderSizePixel = 0
    title.Text = "🎣 Auto Fishing"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
    toggleBtn.Position = UDim2.new(0.05, 0, 0, 45)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    toggleBtn.Text = "⏹ DISABLED"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 95)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame
    
    -- Performance Stats Box
    local statsBox = Instance.new("Frame")
    statsBox.Name = "StatsBox"
    statsBox.Size = UDim2.new(0.9, 0, 0, 80)
    statsBox.Position = UDim2.new(0.05, 0, 0, 135)
    statsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    statsBox.BackgroundTransparency = 0.3
    statsBox.BorderSizePixel = 0
    statsBox.Parent = frame
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsBox
    
    -- Stats Title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, 0, 0, 20)
    statsTitle.Position = UDim2.new(0, 0, 0, 5)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "📊 Performance"
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextSize = 11
    statsTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
    statsTitle.Parent = statsBox
    
    -- FPS Label
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPS"
    fpsLabel.Size = UDim2.new(1, -16, 0, 18)
    fpsLabel.Position = UDim2.new(0, 8, 0, 28)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 11
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = statsBox
    
    -- Ping Label
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "Ping"
    pingLabel.Size = UDim2.new(1, -16, 0, 18)
    pingLabel.Position = UDim2.new(0, 8, 0, 46)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0 ms"
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextSize = 11
    pingLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = statsBox
    
    -- Status Label
    local connectionLabel = Instance.new("TextLabel")
    connectionLabel.Name = "Connection"
    connectionLabel.Size = UDim2.new(1, -16, 0, 18)
    connectionLabel.Position = UDim2.new(0, 8, 0, 64)
    connectionLabel.BackgroundTransparency = 1
    connectionLabel.Text = "Status: Good"
    connectionLabel.Font = Enum.Font.Gotham
    connectionLabel.TextSize = 10
    connectionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    connectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    connectionLabel.Parent = statsBox
    
    -- Update stats loop
    task.spawn(function()
        while statsBox and statsBox.Parent do
            task.wait(0.5)
            
            -- Update FPS
            local fpsColor = Color3.fromRGB(0, 255, 150)
            if currentFPS < 30 then
                fpsColor = Color3.fromRGB(255, 50, 50)
            elseif currentFPS < 50 then
                fpsColor = Color3.fromRGB(255, 200, 0)
            end
            fpsLabel.Text = "FPS: " .. currentFPS
            fpsLabel.TextColor3 = fpsColor
            
            -- Update Ping
            local pingColor = Color3.fromRGB(0, 255, 150)
            if currentPing > 200 then
                pingColor = Color3.fromRGB(255, 50, 50)
            elseif currentPing > 100 then
                pingColor = Color3.fromRGB(255, 200, 0)
            end
            pingLabel.Text = "Ping: " .. currentPing .. " ms"
            pingLabel.TextColor3 = pingColor
            
            -- Update Connection Status
            local connectionStatus = "Good"
            local statusColor = Color3.fromRGB(0, 255, 150)
            
            if currentFPS < 30 or currentPing > 200 then
                connectionStatus = "Poor"
                statusColor = Color3.fromRGB(255, 50, 50)
            elseif currentFPS < 50 or currentPing > 100 then
                connectionStatus = "Fair"
                statusColor = Color3.fromRGB(255, 200, 0)
            end
            
            connectionLabel.Text = "Status: " .. connectionStatus
            connectionLabel.TextColor3 = statusColor
        end
    end)
    
    -- Toggle functionality
    toggleBtn.MouseButton1Click:Connect(function()
        config.enabled = not config.enabled
        
        if config.enabled then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
            toggleBtn.Text = "▶ ENABLED"
            statusLabel.Text = "Status: Running..."
            statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
            
            startAutoClick()
            monitorForRecast()
            
            task.wait(0.5)
            castFishingRod()
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            toggleBtn.Text = "⏹ DISABLED"
            statusLabel.Text = "Status: Idle"
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            
            if clickConnection then
                clickConnection:Disconnect()
            end
        end
    end)
    
    -- Draggable
    local dragging = false
    local dragInput, mousePos, framePos
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
        end
    end)
    
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    screenGui.Parent = playerGui
    print("🎣 Auto Fishing Script Loaded!")
    print("✅ Performance Monitor Active")
    print("▶ Tekan tombol ENABLED untuk memulai")
end

-- Initialize
task.wait(1)
startFPSCounter()
updatePing()
createControlPanel()
