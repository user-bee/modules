local players = game:GetService("Players")
local rs = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local httpService = game:GetService("HttpService")
local camera = workspace.CurrentCamera
local player = players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local mouse = player:GetMouse()

local knives = replicatedStorage.Assets.SkinAssets.ClassicCase.Knives

local function createButton(name, parent, size, pos)
    local btn = Instance.new("TextButton", parent)
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    return btn
end

local function createTextBox(placeholder, parent, size, pos)
    local box = Instance.new("TextBox", parent)
    box.Size = size
    box.Position = pos
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.BorderColor3 = Color3.fromRGB(255, 255, 255)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
    box.Text = ""
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.ClearTextOnFocus = false
    return box
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

    self.txtSetSkin = createTextBox("Target Skin", mainFrame, UDim2.new(0, 390, 0, 20), UDim2.new(0, 5, 0, 5))
    
    local btnChange = createButton("Apply Skin", mainFrame, UDim2.new(0, 390, 0, 20), UDim2.new(0, 5, 0, 31))
    btnChange.MouseButton1Click:Connect(function()
        self:changeSkin()
    end)
end

function skinChanger:changeSkin()
    local skinValue = self.txtSetSkin.Text
    if (knives:FindFirstChild(skinValue)) then
        print(knives:FindFirstChild(skinValue))
    end
end

return skinChanger
