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
    Instance.new("UIListLayout", listContainer)
    
    local dropDownOpen = false

    local function updateList(directory)
        -- Clear existing items
        for _, child in pairs(listContainer:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end

        local count = 0

        -- Add "Back" button if we are not at the root Knives folder
        if directory ~= knives then
            local btnBack = createButton("< Back", listContainer, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0))
            btnBack.MouseButton1Click:Connect(function()
                updateList(directory.Parent)
            end)
            count = count + 1
        end

        -- Populate items
        for _, item in pairs(directory:GetChildren()) do
            -- Only include Folders or Models
            if item:IsA("Folder") or item:IsA("Model") then
                count = count + 1
                
                -- Create button text: "Name: ClassName"
                local displayText = item.Name .. ": " .. item.ClassName
                local btn = createButton(displayText, listContainer, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0))
                
                btn.MouseButton1Click:Connect(function()
                    if item:IsA("Folder") then
                        -- Drill down into the folder
                        updateList(item)
                    elseif item:IsA("Model") then
                        -- Select the model
                        self:changeSkin(item.Name)
                        btnSelect.Text = item.Name
                        dropDownOpen = false
                        listContainer.Visible = false
                    end
                end)
            end
        end
        listContainer.CanvasSize = UDim2.new(0, 0, 0, count * 25)
    end

    btnSelect.MouseButton1Click:Connect(function()
        dropDownOpen = not dropDownOpen
        listContainer.Visible = dropDownOpen
        if dropDownOpen then
            updateList(knives)
        end
    end)
end

function skinChanger:changeSkin(knifeName)
    print("Applying skin: " .. knifeName)
end

return skinChanger
