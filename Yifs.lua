local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- إنشاء الواجهة الأساسية
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProMiniExplorer"
local success, _ = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- النافذة الرئيسية
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- العنوان والمسار الحالي
local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TopBar.Size = UDim2.new(1, 0, 0, 40)
local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local PathLabel = Instance.new("TextLabel")
PathLabel.Parent = TopBar
PathLabel.BackgroundTransparency = 1
PathLabel.Position = UDim2.new(0, 50, 0, 0)
PathLabel.Size = UDim2.new(1, -60, 1, 0)
PathLabel.Font = Enum.Font.GothamSemibold
PathLabel.Text = "game.Workspace"
PathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PathLabel.TextSize = 14
PathLabel.TextXAlignment = Enum.TextXAlignment.Left

-- زر الرجوع للخلف
local BackBtn = Instance.new("TextButton")
BackBtn.Parent = TopBar
BackBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
BackBtn.Position = UDim2.new(0, 5, 0, 5)
BackBtn.Size = UDim2.new(0, 35, 0, 30)
BackBtn.Font = Enum.Font.GothamBold
BackBtn.Text = "<"
BackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BackBtn.TextSize = 18
local BackCorner = Instance.new("UICorner")
BackCorner.CornerRadius = UDim.new(0, 6)
BackCorner.Parent = BackBtn

-- القائمة الخاصة بالملفات (اليسار)
local ItemList = Instance.new("ScrollingFrame")
ItemList.Parent = MainFrame
ItemList.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
ItemList.Position = UDim2.new(0, 10, 0, 50)
ItemList.Size = UDim2.new(0.5, -15, 1, -60)
ItemList.ScrollBarThickness = 4
local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ItemList
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.Name

-- القائمة الخاصة بالمعلومات (اليمين)
local InfoFrame = Instance.new("ScrollingFrame")
InfoFrame.Parent = MainFrame
InfoFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
InfoFrame.Position = UDim2.new(0.5, 5, 0, 50)
InfoFrame.Size = UDim2.new(0.5, -15, 1, -60)
InfoFrame.ScrollBarThickness = 4
local InfoLayout = Instance.new("UIListLayout")
InfoLayout.Parent = InfoFrame
InfoLayout.Padding = UDim.new(0, 5)

-----------------------------------
-- نظام التنقل
-----------------------------------
local CurrentNode = workspace

-- دالة لإضافة نص في قائمة المعلومات
local function addInfoText(text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = InfoFrame
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -10, 0, 25)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
end

-- دالة لتحديث قائمة المعلومات لشيء معين
local function updateInfo(item)
    for _, child in pairs(InfoFrame:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    addInfoText("📌 Name: " .. item.Name, Color3.fromRGB(100, 200, 255))
    addInfoText("🏷️ Class: " .. item.ClassName, Color3.fromRGB(200, 200, 100))
    
    -- البحث عن قيمة (Value) إذا كانت موجودة
    pcall(function()
        if item.Value ~= nil then
            addInfoText("💰 Value: " .. tostring(item.Value), Color3.fromRGB(150, 255, 150))
        end
    end)
    
    -- البحث عن Attributes (خصائص مخصصة)
    addInfoText("--- Attributes ---", Color3.fromRGB(150, 150, 150))
    local hasAttributes = false
    pcall(function()
        local attributes = item:GetAttributes()
        for k, v in pairs(attributes) do
            addInfoText(k .. ": " .. tostring(v), Color3.fromRGB(255, 150, 150))
            hasAttributes = true
        end
    end)
    if not hasAttributes then
        addInfoText("No attributes found.", Color3.fromRGB(100, 100, 100))
    end
end

-- دالة لتحديث الشاشة وعرض محتويات المجلد الحالي
local function refreshView()
    -- مسح القائمة القديمة
    for _, child in pairs(ItemList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    PathLabel.Text = CurrentNode:GetFullName()
    
    local yOffset = 0
    local success, children = pcall(function() return CurrentNode:GetChildren() end)
    
    if success and children then
        for _, child in pairs(children) do
            local btn = Instance.new("TextButton")
            btn.Parent = ItemList
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.Font = Enum.Font.Gotham
            
            -- تمييز المجلدات عن القيم والنصوص
            if child:IsA("Folder") or child:IsA("Model") then
                btn.Text = "📁 " .. child.Name
                btn.TextColor3 = Color3.fromRGB(255, 200, 100)
            elseif child:IsA("ValueBase") then
                btn.Text = "🔢 " .. child.Name
                btn.TextColor3 = Color3.fromRGB(150, 255, 150)
            else
                btn.Text = "📄 " .. child.Name
                btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            
            -- عند الضغط مرة واحدة: عرض المعلومات
            -- عند الضغط مرتين بسرعة: الدخول للمجلد
            local lastClick = 0
            btn.MouseButton1Click:Connect(function()
                updateInfo(child)
                
                local now = tick()
                if now - lastClick < 0.4 then
                    -- الدخول للمجلد (Double Click)
                    CurrentNode = child
                    refreshView()
                end
                lastClick = now
            end)
            
            yOffset = yOffset + 27
        end
    end
    ItemList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- زر الرجوع
BackBtn.MouseButton1Click:Connect(function()
    if CurrentNode.Parent and CurrentNode ~= game then
        CurrentNode = CurrentNode.Parent
        refreshView()
        updateInfo(CurrentNode)
    end
end)

-- تشغيل لأول مرة
refreshView()
updateInfo(CurrentNode)
