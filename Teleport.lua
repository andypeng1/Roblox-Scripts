-- 传送脚本 (LocalScript)
-- 功能：按下 'T' 键，打开在线玩家列表，选择目标玩家后将自己传送到其位置

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- 获取本地角色的 RootPart
local function getRootPart()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    end
    return nil
end

-- 将本地玩家传送到目标玩家位置
local function teleportToPlayer(targetPlayer)
    if not targetPlayer then return false end

    local targetChar = targetPlayer.Character
    if not targetChar then
        warn("目标玩家没有角色")
        return false
    end

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
    if not targetRoot then
        warn("目标玩家没有 RootPart")
        return false
    end

    local localRoot = getRootPart()
    if not localRoot then
        warn("本地角色不存在")
        return false
    end

    -- 传送到目标玩家位置上方一点，避免卡进地里
    local position = targetRoot.Position + Vector3.new(0, 3, 0)
    localRoot.CFrame = CFrame.new(position)
    return true
end

-- 显示一个简单的浮动通知（替代 warn，便于用户看到）
local function showNotification(title, text, duration)
    duration = duration or 2
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "TempNotification"
    notificationGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = notificationGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.Parent = frame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 30)
    msgLabel.Position = UDim2.new(0, 0, 0, 28)
    msgLabel.Text = text
    msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Font = Enum.Font.SourceSans
    msgLabel.TextSize = 14
    msgLabel.Parent = frame

    game:GetService("Debris"):AddItem(notificationGui, duration)
end

-- 玩家选择界面（当前打开的实例）
local currentSelectionGui = nil

-- 显示在线玩家列表供选择
local function showPlayerSelection()
    -- 关闭已存在的界面
    if currentSelectionGui then
        currentSelectionGui:Destroy()
        currentSelectionGui = nil
    end

    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlayerSelectGui"
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- 标题栏
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "选择玩家传送"
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.Parent = mainFrame

    -- 滚动区域
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -80)
    scrollFrame.Position = UDim2.new(0, 0, 0, 40)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- 自动适应内容高度
    scrollFrame.Parent = mainFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.Name
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = scrollFrame

    -- 获取在线玩家（排除自己）
    local players = Players:GetPlayers()
    local otherPlayers = {}
    for _, plr in ipairs(players) do
        if plr ~= LocalPlayer then
            table.insert(otherPlayers, plr)
        end
    end

    if #otherPlayers == 0 then
        local noPlayerLabel = Instance.new("TextLabel")
        noPlayerLabel.Size = UDim2.new(1, 0, 0, 50)
        noPlayerLabel.Text = "⚠️ 没有其他在线玩家"
        noPlayerLabel.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        noPlayerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        noPlayerLabel.Font = Enum.Font.SourceSans
        noPlayerLabel.TextSize = 18
        noPlayerLabel.Parent = scrollFrame
    else
        for _, player in ipairs(otherPlayers) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 50)
            button.Position = UDim2.new(0, 5, 0, 0)
            button.Text = player.Name
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.SourceSans
            button.TextSize = 20
            button.AutoButtonColor = true
            button.Parent = scrollFrame

            button.MouseButton1Click:Connect(function()
                -- 检查目标玩家角色是否有效
                local targetChar = player.Character
                local targetRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
                if not targetRoot then
                    showNotification("传送失败", player.Name .. " 的角色尚未加载或无效", 2)
                    return  -- 不关闭界面，用户可以继续选择
                end

                -- 执行传送
                local success = teleportToPlayer(player)
                if success then
                    showNotification("传送成功", "已传送到 " .. player.Name, 1.5)
                    screenGui:Destroy()
                    currentSelectionGui = nil
                else
                    showNotification("传送失败", "无法传送到 " .. player.Name .. "，请重试", 2)
                end
            end)
        end
    end

    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 30)
    closeButton.Position = UDim2.new(1, -110, 1, -40)
    closeButton.Text = "关闭"
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.SourceSans
    closeButton.TextSize = 18
    closeButton.Parent = mainFrame
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        currentSelectionGui = nil
    end)

    currentSelectionGui = screenGui
end

-- 监听 T 键，打开玩家选择界面
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        showPlayerSelection()
    end
end)

print("传送脚本已加载：按 T 键打开在线玩家列表，选择目标玩家即可传送")