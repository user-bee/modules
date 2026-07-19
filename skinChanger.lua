local players = game:GetService("Players")
local rs = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local player = players.LocalPlayer

local knives = replicatedStorage:WaitForChild("Assets"):WaitForChild("SkinAssets"):WaitForChild("Case3"):WaitForChild("Knives")

local function createButton(name, parent, size, pos)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 1
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.Parent = parent
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
    
    local btnSelect = createButton("Select Knife", mainFrame, UDim2.new(0, 390, 0, 20), UDim2.new(0, 5, 0, 5))
    
    local listContainer = Instance.new("ScrollingFrame", mainFrame)
    listContainer.Size = UDim2.new(0, 390, 0, 200)
    listContainer.Position = UDim2.new(0, 5, 0, 30)
    listContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    listContainer.BorderColor3 = Color3.fromRGB(255, 255, 255)
    listContainer.BorderSizePixel = 1
    listContainer.ScrollBarThickness = 5
    listContainer.Visible = false
    
    local dropDownOpen = false
    
    btnSelect.MouseButton1Click:Connect(function()
        dropDownOpen = not dropDownOpen
        listContainer.Visible = dropDownOpen
        
        if dropDownOpen then
            for _, child in pairs(listContainer:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
            
            if not listContainer:FindFirstChild("UIListLayout") then
                Instance.new("UIListLayout", listContainer)
            end
            
            local count = 0
            for _, descendant in pairs(knives:GetDescendants()) do
                    count = count + 1
                    print("Found: " .. descendant.Name)
                    
                    local item = createButton(descendant.Name, listContainer, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0))
                    
                    item.MouseButton1Click:Connect(function()
                        self:changeSkin(descendant.Name)
                        btnSelect.Text = descendant.Name
                        dropDownOpen = false
                        listContainer.Visible = false
                    end)
            end
            
            listContainer.CanvasSize = UDim2.new(0, 0, 0, count * 25)
        end
    end)
end

function skinChanger:changeSkin(knifeName)
    print("Applying skin: " .. knifeName)
end

return skinChanger
