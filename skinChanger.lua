local players = game:GetService("Players")
local rs = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local player = players.LocalPlayer

-- Updated path to target the folder
local knives = replicatedStorage:WaitForChild("Assets"):WaitForChild("SkinAssets"):WaitForChild("ClassicCase"):WaitForChild("Knives")

local function createButton(name, parent, size, pos)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size
    btn.Position = pos
    -- Matching your exact requested style
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    return btn
end

local skinChanger = {}
skinChanger.__index = skinChanger

function skinChanger.new()
    local self = setmetatable({}, skinChanger)
    return self
end

function skinChanger:launch()
    local screenGui = Instance.new("ScreenGui", coreGui)
    
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Dragging Logic
    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Dropdown Setup
    local dropDownOpen = false
    local btnSelect = createButton("Select Knife", mainFrame, UDim2.new(0, 390, 0, 20), UDim2.new(0, 5, 0, 5))
    
    local listContainer = Instance.new("ScrollingFrame", mainFrame)
    listContainer.Size = UDim2.new(0, 390, 0, 200)
    listContainer.Position = UDim2.new(0, 5, 0, 30)
    listContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    listContainer.BorderColor3 = Color3.fromRGB(255, 255, 255)
    listContainer.ScrollBarThickness = 5
    listContainer.Visible = false
    listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", listContainer)
    layout.Padding = UDim.new(0, 2)

    btnSelect.MouseButton1Click:Connect(function()
        dropDownOpen = not dropDownOpen
        listContainer.Visible = dropDownOpen
        
        if dropDownOpen then
            listContainer:ClearAllChildren()
            Instance.new("UIListLayout", listContainer)
            
            local count = 0
            for _, child in pairs(knives:GetChildren()) do
                if child:IsA("Model") then
                    count = count + 1
                    local item = createButton(child.Name, listContainer, UDim2.new(1, -10, 0, 25), UDim2.new(0, 5, 0, 0))
                    item.MouseButton1Click:Connect(function()
                        self:changeSkin(child.Name)
                        btnSelect.Text = child.Name
                        dropDownOpen = false
                        listContainer.Visible = false
                    end)
                end
            end
            -- Dynamically set scroll area height
            listContainer.CanvasSize = UDim2.new(0, 0, 0, count * 27)
        end
    end)
end

function skinChanger:changeSkin(knifeName)
    print("Applying skin: " .. knifeName)
end

return skinChanger
