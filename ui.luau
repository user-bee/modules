local inputService = game:GetService('UserInputService');
local textService = game:GetService('TextService');
local coreGui = game:GetService('CoreGui');
local teams = game:GetService('Teams');
local players = game:GetService('Players');
local runService = game:GetService('RunService')
local tweenService = game:GetService('TweenService');
local renderStepped = runService.RenderStepped;
local localPlayer = players.LocalPlayer;
local mouse = localPlayer:GetMouse();

local protectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local screenGui = Instance.new('ScreenGui');
protectGui(screenGui);

screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
screenGui.Parent = coreGui;

local toggles = {};
local options = {};

getgenv().toggles = toggles;
getgenv().options = options;

local library = {
    registry = {};
    registryMap = {};

    hudRegistry = {};

    fontColor = Color3.fromRGB(255, 255, 255);
    mainColor = Color3.fromRGB(28, 28, 28);
    backgroundColor = Color3.fromRGB(20, 20, 20);
    accentColor = Color3.fromRGB(0, 85, 255);
    outlineColor = Color3.fromRGB(50, 50, 50);
    riskColor = Color3.fromRGB(255, 50, 50),

    -- Custom Cursor Settings
    useCustomCursor = true,
    cursorColor = Color3.fromRGB(255, 255, 255), 

    black = Color3.new(0, 0, 0);
    font = Enum.Font.Code,

    openedFrames = {};
    dependencyBoxes = {};

    signals = {};
    screenGui = screenGui;
};

local rainbowStep = 0
local hue = 0

table.insert(library.signals, renderStepped:Connect(function(delta)
    rainbowStep = rainbowStep + delta

    if rainbowStep >= (1 / 60) then
        rainbowStep = 0

        hue = hue + (1 / 400);

        if hue > 1 then
            hue = 0;
        end;

        library.currentRainbowHue = hue;
        library.currentRainbowColor = Color3.fromHSV(hue, 0.8, 1);
    end
end))

local function getPlayersString()
    local playerList = players:GetPlayers();

    for i = 1, #playerList do
        playerList[i] = playerList[i].Name;
    end;

    table.sort(playerList, function(str1, str2) return str1 < str2 end);

    return playerList;
end;

local function getTeamsString()
    local teamList = teams:GetTeams();

    for i = 1, #teamList do
        teamList[i] = teamList[i].Name;
    end;

    table.sort(teamList, function(str1, str2) return str1 < str2 end);
    
    return teamList;
end;

function library:safeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not library.notifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return library:notify(event);
        end;

        return library:notify(event:sub(i + 1), 3);
    end;
end;

function library:attemptSave()
    if library.saveManager then
        library.saveManager:Save();
    end;
end;

function library:create(class, properties)
    local _instance = class;

    if type(class) == 'string' then
        _instance = Instance.new(class);
    end;

    for property, value in next, properties do
        _instance[property] = value;
    end;

    return _instance;
end;

function library:applyTextStroke(inst)
    inst.TextStrokeTransparency = 1;

    library:create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = inst;
    });
end;

function library:createLabel(properties, isHud)
    local _instance = library:create('TextLabel', {
        BackgroundTransparency = 1;
        Font = library.font;
        TextColor3 = library.fontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    library:applyTextStroke(_instance);

    library:addToRegistry(_instance, {
        TextColor3 = 'fontColor';
    }, isHud);

    return library:create(_instance, properties);
end;

function library:makeDraggable(instance, cutoff)
    instance.Active = true;

    instance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local objPos = Vector2.new(
                mouse.X - instance.AbsolutePosition.X,
                mouse.Y - instance.AbsolutePosition.Y
            );

            if objPos.Y > (cutoff or 40) then
                return;
            end;

            while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                instance.Position = UDim2.new(
                    0,
                    mouse.X - objPos.X + (instance.Size.X.Offset * instance.AnchorPoint.X),
                    0,
                    mouse.Y - objPos.Y + (instance.Size.Y.Offset * instance.AnchorPoint.Y)
                );

                renderStepped:Wait();
            end;
        end;
    end)
end;

function library:addToolTip(infoStr, hoverInstance)
    local x, y = library:getTextBounds(infoStr, library.font, 14);
    local tooltip = library:create('Frame', {
        BackgroundColor3 = library.mainColor,
        BorderColor3 = library.outlineColor,

        Size = UDim2.fromOffset(x + 5, y + 4),
        ZIndex = 100,
        Parent = library.screenGui,

        Visible = false,
    })

    local label = library:createLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(x, y);
        TextSize = 14;
        Text = infoStr,
        TextColor3 = library.fontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = tooltip.ZIndex + 1,

        Parent = tooltip;
    });

    library:addToRegistry(tooltip, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'outlineColor';
    });

    library:addToRegistry(label, {
        TextColor3 = 'fontColor',
    });

    local isHovering = false

    hoverInstance.MouseEnter:Connect(function()
        if library:mouseIsOverOpenedFrame() then
            return
        end

        isHovering = true

        tooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
        tooltip.Visible = true

        while isHovering do
            runService.Heartbeat:Wait()
            tooltip.Position = UDim2.fromOffset(mouse.X + 15, mouse.Y + 12)
        end
    end)

    hoverInstance.MouseLeave:Connect(function()
        isHovering = false
        tooltip.Visible = false
    end)
end

function library:onHighlight(highlightInstance, instance, properties, propertiesDefault)
    highlightInstance.MouseEnter:Connect(function()
        local reg = library.registryMap[instance];

        for property, colorIdx in next, properties do
            instance[property] = library[colorIdx] or colorIdx;

            if reg and reg.properties[property] then
                reg.properties[property] = colorIdx;
            end;
        end;
    end)

    highlightInstance.MouseLeave:Connect(function()
        local reg = library.registryMap[instance];

        for property, colorIdx in next, propertiesDefault do
            instance[property] = library[colorIdx] or colorIdx;

            if reg and reg.properties[property] then
                reg.properties[property] = colorIdx;
            end;
        end;
    end)
end;

function library:mouseIsOverOpenedFrame()
    for frame, _ in next, library.openedFrames do
        local absPos, absSize = frame.AbsolutePosition, frame.AbsoluteSize;

        if mouse.X >= absPos.X and mouse.X <= absPos.X + absSize.X
            and mouse.Y >= absPos.Y and mouse.Y <= absPos.Y + absSize.Y then

            return true;
        end;
    end;
end;

function library:isMouseOverFrame(frame)
    local absPos, absSize = frame.AbsolutePosition, frame.AbsoluteSize;

    if mouse.X >= absPos.X and mouse.X <= absPos.X + absSize.X
        and mouse.Y >= absPos.Y and mouse.Y <= absPos.Y + absSize.Y then

        return true;
    end;
end;

function library:updateDependencyBoxes()
    for _, depbox in next, library.dependencyBoxes do
        depbox:update();
    end;
end;

function library:mapValue(value, minA, maxA, minB, maxB)
    return (1 - ((value - minA) / (maxA - minA))) * minB + ((value - minA) / (maxA - minA)) * maxB;
end;

function library:getTextBounds(text, font, size, resolution)
    local bounds = textService:GetTextSize(text, size, font, resolution or Vector2.new(1920, 1080))
    return bounds.X, bounds.Y
end;

function library:getDarkerColor(color)
    local h, s, v = Color3.toHSV(color);
    return Color3.fromHSV(h, s, v / 1.5);
end;
library.accentColorDark = library:getDarkerColor(library.accentColor);

function library:addToRegistry(instance, properties, isHud)
    local idx = #library.registry + 1;
    local data = {
        instance = instance;
        properties = properties;
        idx = idx;
    };

    table.insert(library.registry, data);
    library.registryMap[instance] = data;

    if isHud then
        table.insert(library.hudRegistry, data);
    end;
end;

function library:removeFromRegistry(instance)
    local data = library.registryMap[instance];

    if data then
        for idx = #library.registry, 1, -1 do
            if library.registry[idx] == data then
                table.remove(library.registry, idx);
            end;
        end;

        for idx = #library.hudRegistry, 1, -1 do
            if library.hudRegistry[idx] == data then
                table.remove(library.hudRegistry, idx);
            end;
        end;

        library.registryMap[instance] = nil;
    end;
end;

function library:updateColorsUsingRegistry()
    for idx, object in next, library.registry do
        for property, colorIdx in next, object.properties do
            if type(colorIdx) == 'string' then
                object.instance[property] = library[colorIdx];
            elseif type(colorIdx) == 'function' then
                object.instance[property] = colorIdx()
            end
        end;
    end;
end;

function library:giveSignal(signal)
    table.insert(library.signals, signal)
end

function library:unload()
    for idx = #library.signals, 1, -1 do
        local connection = table.remove(library.signals, idx)
        connection:Disconnect()
    end

    if library.onUnloadCallback then
        library.onUnloadCallback()
    end

    screenGui:Destroy()
end

function library:onUnload(callback)
    library.onUnloadCallback = callback
end

library:giveSignal(screenGui.DescendantRemoving:Connect(function(instance)
    if library.registryMap[instance] then
        library:removeFromRegistry(instance);
    end;
end))

local baseAddons = {};

do
    local funcs = {};

    function funcs:addColorPicker(idx, info)
        local toggleLabel = self.textLabel;

        assert(info.Default, 'addColorPicker: Missing default value.');

        local colorPicker = {
            value = info.Default;
            transparency = info.Transparency or 0;
            type = 'colorPicker';
            title = type(info.Title) == 'string' and info.Title or 'Color picker',
            callback = info.Callback or function(color) end;
        };

        function colorPicker:setHSVFromRGB(color)
            local h, s, v = Color3.toHSV(color);

            colorPicker.hue = h;
            colorPicker.sat = s;
            colorPicker.vib = v;
        end;

        colorPicker:setHSVFromRGB(colorPicker.value);

        local displayFrame = library:create('Frame', {
            BackgroundColor3 = colorPicker.value;
            BorderColor3 = library:getDarkerColor(colorPicker.value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = toggleLabel;
        });

        local checkerFrame = library:create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not info.Transparency;
            Parent = displayFrame;
        });

        local pickerFrameOuter = library:create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(displayFrame.AbsolutePosition.X, displayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = screenGui,
        });

        displayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            pickerFrameOuter.Position = UDim2.fromOffset(displayFrame.AbsolutePosition.X, displayFrame.AbsolutePosition.Y + 18);
        end)

        local pickerFrameInner = library:create('Frame', {
            BackgroundColor3 = library.backgroundColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = pickerFrameOuter;
        });

        local highlight = library:create('Frame', {
            BackgroundColor3 = library.accentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = pickerFrameInner;
        });

        local satVibMapOuter = library:create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = pickerFrameInner;
        });

        local satVibMapInner = library:create('Frame', {
            BackgroundColor3 = library.backgroundColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = satVibMapOuter;
        });

        local satVibMap = library:create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = satVibMapInner;
        });

        local cursorOuter = library:create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = satVibMap;
        });

        local cursorInner = library:create('ImageLabel', {
            Size = UDim2.new(0, cursorOuter.Size.X.Offset - 2, 0, cursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = cursorOuter;
        })

        local hueSelectorOuter = library:create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = pickerFrameInner;
        });

        local hueSelectorInner = library:create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = hueSelectorOuter;
        });

        local hueCursor = library:create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = hueSelectorInner;
        });

        local hueBoxOuter = library:create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = pickerFrameInner;
        });

        local hueBoxInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = hueBoxOuter;
        });

        library:create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = hueBoxInner;
        });

        local hueBox = library:create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = library.font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = library.fontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = hueBoxInner;
        });

        library:applyTextStroke(hueBox);

        local rgbBoxBase = library:create(hueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = pickerFrameInner
        });

        local rgbBox = library:create(rgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = library.fontColor
        });

        local transparencyBoxOuter, transparencyBoxInner, transparencyCursor;
        
        if info.Transparency then 
            transparencyBoxOuter = library:create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = pickerFrameInner;
            });

            transparencyBoxInner = library:create('Frame', {
                BackgroundColor3 = colorPicker.value;
                BorderColor3 = library.outlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = transparencyBoxOuter;
            });

            library:addToRegistry(transparencyBoxInner, { BorderColor3 = 'outlineColor' });

            library:create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = transparencyBoxInner;
            });

            transparencyCursor = library:create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = transparencyBoxInner;
            });
        end;

        local displayLabel = library:createLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = colorPicker.title;
            TextWrapped = false;
            ZIndex = 16;
            Parent = pickerFrameInner;
        });


        local contextMenu = {}
        do
            contextMenu.options = {}
            contextMenu.container = library:create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = screenGui
            })

            contextMenu.inner = library:create('Frame', {
                BackgroundColor3 = library.backgroundColor;
                BorderColor3 = library.outlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = contextMenu.container;
            });

            library:create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = contextMenu.inner;
            });

            library:create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = contextMenu.inner,
            });

            local function updateMenuPosition()
                contextMenu.container.Position = UDim2.fromOffset(
                    (displayFrame.AbsolutePosition.X + displayFrame.AbsoluteSize.X) + 4,
                    displayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, contextMenu.inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                contextMenu.container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    contextMenu.inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            displayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            contextMenu.inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            library:addToRegistry(contextMenu.inner, {
                BackgroundColor3 = 'backgroundColor';
                BorderColor3 = 'outlineColor';
            });

            function contextMenu:show()
                self.container.Visible = true
            end

            function contextMenu:hide()
                self.container.Visible = false
            end

            function contextMenu:addOption(str, callback)
                if type(callback) ~= 'function' then
                    callback = function() end
                end

                local button = library:createLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = str;
                    ZIndex = 16;
                    Parent = self.inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                library:onHighlight(button, button, 
                    { TextColor3 = 'accentColor' },
                    { TextColor3 = 'fontColor' }
                );

                button.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    callback()
                end)
            end

            contextMenu:addOption('Copy color', function()
                library.colorClipboard = colorPicker.value
                library:notify('Copied color!', 2)
            end)

            contextMenu:addOption('Paste color', function()
                if not library.colorClipboard then
                    return library:notify('You have not copied a color!', 2)
                end
                colorPicker:setValueRGB(library.colorClipboard)
            end)


            contextMenu:addOption('Copy HEX', function()
                pcall(setclipboard, colorPicker.value:ToHex())
                library:notify('Copied hex code to clipboard!', 2)
            end)

            contextMenu:addOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(colorPicker.value.R * 255), math.floor(colorPicker.value.G * 255), math.floor(colorPicker.value.B * 255) }, ', '))
                library:notify('Copied RGB values to clipboard!', 2)
            end)

        end

        library:addToRegistry(pickerFrameInner, { BackgroundColor3 = 'backgroundColor'; BorderColor3 = 'outlineColor'; });
        library:addToRegistry(highlight, { BackgroundColor3 = 'accentColor'; });
        library:addToRegistry(satVibMapInner, { BackgroundColor3 = 'backgroundColor'; BorderColor3 = 'outlineColor'; });

        library:addToRegistry(hueBoxInner, { BackgroundColor3 = 'mainColor'; BorderColor3 = 'outlineColor'; });
        library:addToRegistry(rgbBoxBase.Frame, { BackgroundColor3 = 'mainColor'; BorderColor3 = 'outlineColor'; });
        library:addToRegistry(rgbBox, { TextColor3 = 'fontColor', });
        library:addToRegistry(hueBox, { TextColor3 = 'fontColor', });

        local sequenceTable = {};

        for h = 0, 1, 0.1 do
            table.insert(sequenceTable, ColorSequenceKeypoint.new(h, Color3.fromHSV(h, 1, 1)));
        end;

        local hueSelectorGradient = library:create('UIGradient', {
            Color = ColorSequence.new(sequenceTable);
            Rotation = 90;
            Parent = hueSelectorInner;
        });

        hueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, hueBox.Text)
                if success and typeof(result) == 'Color3' then
                    colorPicker.hue, colorPicker.sat, colorPicker.vib = Color3.toHSV(result)
                end
            end

            colorPicker:display()
        end)

        rgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = rgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    colorPicker.hue, colorPicker.sat, colorPicker.vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            colorPicker:display()
        end)

        function colorPicker:display()
            colorPicker.value = Color3.fromHSV(colorPicker.hue, colorPicker.sat, colorPicker.vib);
            satVibMap.BackgroundColor3 = Color3.fromHSV(colorPicker.hue, 1, 1);

            library:create(displayFrame, {
                BackgroundColor3 = colorPicker.value;
                BackgroundTransparency = colorPicker.transparency;
                BorderColor3 = library:getDarkerColor(colorPicker.value);
            });

            if transparencyBoxInner then
                transparencyBoxInner.BackgroundColor3 = colorPicker.value;
                transparencyCursor.Position = UDim2.new(1 - colorPicker.transparency, 0, 0, 0);
            end;

            cursorOuter.Position = UDim2.new(colorPicker.sat, 0, 1 - colorPicker.vib, 0);
            hueCursor.Position = UDim2.new(0, 0, colorPicker.hue, 0);

            hueBox.Text = '#' .. colorPicker.value:ToHex()
            rgbBox.Text = table.concat({ math.floor(colorPicker.value.R * 255), math.floor(colorPicker.value.G * 255), math.floor(colorPicker.value.B * 255) }, ', ')

            library:safeCallback(colorPicker.callback, colorPicker.value);
            library:safeCallback(colorPicker.changed, colorPicker.value);
        end;

        function colorPicker:onChanged(func)
            colorPicker.changed = func;
            func(colorPicker.value)
        end;

        function colorPicker:show()
            for frame, val in next, library.openedFrames do
                if frame.Name == 'Color' then
                    frame.Visible = false;
                    library.openedFrames[frame] = nil;
                end;
            end;

            pickerFrameOuter.Visible = true;
            library.openedFrames[pickerFrameOuter] = true;
        end;

        function colorPicker:hide()
            pickerFrameOuter.Visible = false;
            library.openedFrames[pickerFrameOuter] = nil;
        end;

        function colorPicker:setValue(hsv, transparency)
            local color = Color3.fromHSV(hsv[1], hsv[2], hsv[3]);

            colorPicker.transparency = transparency or 0;
            colorPicker:setHSVFromRGB(color);
            colorPicker:display();
        end;

        function colorPicker:setValueRGB(color, transparency)
            colorPicker.transparency = transparency or 0;
            colorPicker:setHSVFromRGB(color);
            colorPicker:display();
        end;

        satVibMap.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local minX = satVibMap.AbsolutePosition.X;
                    local maxX = minX + satVibMap.AbsoluteSize.X;
                    local mouseX = math.clamp(mouse.X, minX, maxX);

                    local minY = satVibMap.AbsolutePosition.Y;
                    local maxY = minY + satVibMap.AbsoluteSize.Y;
                    local mouseY = math.clamp(mouse.Y, minY, maxY);

                    colorPicker.sat = (mouseX - minX) / (maxX - minX);
                    colorPicker.vib = 1 - ((mouseY - minY) / (maxY - minY));
                    colorPicker:display();

                    renderStepped:Wait();
                end;

                library:attemptSave();
            end;
        end);

        hueSelectorInner.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local minY = hueSelectorInner.AbsolutePosition.Y;
                    local maxY = minY + hueSelectorInner.AbsoluteSize.Y;
                    local mouseY = math.clamp(mouse.Y, minY, maxY);

                    colorPicker.hue = ((mouseY - minY) / (maxY - minY));
                    colorPicker:display();

                    renderStepped:Wait();
                end;

                library:attemptSave();
            end;
        end);

        displayFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
                if pickerFrameOuter.Visible then
                    colorPicker:hide()
                else
                    contextMenu:hide()
                    colorPicker:show()
                end;
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not library:mouseIsOverOpenedFrame() then
                contextMenu:show()
                colorPicker:hide()
            end
        end);

        if transparencyBoxInner then
            transparencyBoxInner.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local minX = transparencyBoxInner.AbsolutePosition.X;
                        local maxX = minX + transparencyBoxInner.AbsoluteSize.X;
                        local mouseX = math.clamp(mouse.X, minX, maxX);

                        colorPicker.transparency = 1 - ((mouseX - minX) / (maxX - minX));

                        colorPicker:display();

                        renderStepped:Wait();
                    end;

                    library:attemptSave();
                end;
            end);
        end;

        library:giveSignal(inputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local absPos, absSize = pickerFrameOuter.AbsolutePosition, pickerFrameOuter.AbsoluteSize;

                if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X
                    or mouse.Y < (absPos.Y - 20 - 1) or mouse.Y > absPos.Y + absSize.Y then

                    colorPicker:hide();
                end;

                if not library:isMouseOverFrame(contextMenu.container) then
                    contextMenu:hide()
                end
            end;

            if input.UserInputType == Enum.UserInputType.MouseButton2 and contextMenu.container.Visible then
                if not library:isMouseOverFrame(contextMenu.container) and not library:isMouseOverFrame(displayFrame) then
                    contextMenu:hide()
                end
            end
        end))

        colorPicker:display();
        colorPicker.displayFrame = displayFrame

        options[idx] = colorPicker;

        return self;
    end;

    function funcs:addKeyPicker(idx, info)
        local parentObj = self;
        local toggleLabel = self.textLabel;
        local container = self.container;

        assert(info.Default, 'addKeyPicker: Missing default value.');

        local keyPicker = {
            value = info.Default;
            toggled = false;
            mode = info.Mode or 'Toggle'; 
            type = 'keyPicker';
            callback = info.Callback or function(value) end;
            changedCallback = info.ChangedCallback or function(new) end;

            syncToggleState = info.SyncToggleState or false;
        };

        if keyPicker.syncToggleState then
            info.Modes = { 'Toggle' }
            info.Mode = 'Toggle'
        end

        local pickOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = toggleLabel;
        });

        local pickInner = library:create('Frame', {
            BackgroundColor3 = library.backgroundColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = pickOuter;
        });

        library:addToRegistry(pickInner, {
            BackgroundColor3 = 'backgroundColor';
            BorderColor3 = 'outlineColor';
        });

        local displayLabel = library:createLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = pickInner;
        });

        local modeSelectOuter = library:create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(toggleLabel.AbsolutePosition.X + toggleLabel.AbsoluteSize.X + 4, toggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = screenGui;
        });

        toggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            modeSelectOuter.Position = UDim2.fromOffset(toggleLabel.AbsolutePosition.X + toggleLabel.AbsoluteSize.X + 4, toggleLabel.AbsolutePosition.Y + 1);
        end);

        local modeSelectInner = library:create('Frame', {
            BackgroundColor3 = library.backgroundColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = modeSelectOuter;
        });

        library:addToRegistry(modeSelectInner, {
            BackgroundColor3 = 'backgroundColor';
            BorderColor3 = 'outlineColor';
        });

        library:create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = modeSelectInner;
        });

        local containerLabel = library:createLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = library.keybindContainer;
        },  true);

        local modes = info.Modes or { 'Always', 'Toggle', 'Hold' };
        local modeButtons = {};

        for _, mode in next, modes do
            local modeButton = {};

            local label = library:createLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = mode;
                ZIndex = 16;
                Parent = modeSelectInner;
            });

            function modeButton:select()
                for _, button in next, modeButtons do
                    button:deselect();
                end;

                keyPicker.mode = mode;

                label.TextColor3 = library.accentColor;
                library.registryMap[label].properties.TextColor3 = 'accentColor';

                modeSelectOuter.Visible = false;
            end;

            function modeButton:deselect()
                keyPicker.mode = nil;

                label.TextColor3 = library.fontColor;
                library.registryMap[label].properties.TextColor3 = 'fontColor';
            end;

            label.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    modeButton:select();
                    library:attemptSave();
                end;
            end);

            if mode == keyPicker.mode then
                modeButton:select();
            end;

            modeButtons[mode] = modeButton;
        end;

        function keyPicker:update()
            if info.NoUI then
                return;
            end;

            local state = keyPicker:getState();

            containerLabel.Text = string.format('[%s] %s (%s)', keyPicker.value, info.Text, keyPicker.mode);

            containerLabel.Visible = true;
            containerLabel.TextColor3 = state and library.accentColor or library.fontColor;

            library.registryMap[containerLabel].properties.TextColor3 = state and 'accentColor' or 'fontColor';

            local ySize = 0
            local xSize = 0

            for _, label in next, library.keybindContainer:GetChildren() do
                if label:IsA('TextLabel') and label.Visible then
                    ySize = ySize + 18;
                    if (label.TextBounds.X > xSize) then
                        xSize = label.TextBounds.X
                    end
                end;
            end;

            library.keybindFrame.Size = UDim2.new(0, math.max(xSize + 10, 210), 0, ySize + 23)
        end;

        function keyPicker:getState()
            if keyPicker.mode == 'Always' then
                return true;
            elseif keyPicker.mode == 'Hold' then
                if keyPicker.value == 'None' then
                    return false;
                end

                local key = keyPicker.value;

                if key == 'MB1' or key == 'MB2' then
                    return key == 'MB1' and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or key == 'MB2' and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return inputService:IsKeyDown(Enum.KeyCode[keyPicker.value]);
                end;
            else
                return keyPicker.toggled;
            end;
        end;

        function keyPicker:setValue(data)
            local key, mode = data[1], data[2];
            displayLabel.Text = key;
            keyPicker.value = key;
            modeButtons[mode]:select();
            keyPicker:update();
        end;

        function keyPicker:onClick(callback)
            keyPicker.clicked = callback
        end

        function keyPicker:onChanged(callback)
            keyPicker.changed = callback
            callback(keyPicker.value)
        end

        if parentObj.addons then
            table.insert(parentObj.addons, keyPicker)
        end

        function keyPicker:doClick()
            if parentObj.type == 'Toggle' and keyPicker.syncToggleState then
                parentObj:setValue(not parentObj.value)
            end

            library:safeCallback(keyPicker.callback, keyPicker.toggled)
            library:safeCallback(keyPicker.clicked, keyPicker.toggled)
        end

        local picking = false;

        pickOuter.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
                picking = true;

                displayLabel.Text = '';

                local breakPick;
                local text = '';

                task.spawn(function()
                    while (not breakPick) do
                        if text == '...' then
                            text = '';
                        end;

                        text = text .. '.';
                        displayLabel.Text = text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local event;
                event = inputService.InputBegan:Connect(function(inputEvent)
                    local key;

                    if inputEvent.UserInputType == Enum.UserInputType.Keyboard then
                        key = inputEvent.KeyCode.Name;
                    elseif inputEvent.UserInputType == Enum.UserInputType.MouseButton1 then
                        key = 'MB1';
                    elseif inputEvent.UserInputType == Enum.UserInputType.MouseButton2 then
                        key = 'MB2';
                    end;

                    breakPick = true;
                    picking = false;

                    displayLabel.Text = key;
                    keyPicker.value = key;

                    library:safeCallback(keyPicker.changedCallback, inputEvent.KeyCode or inputEvent.UserInputType)
                    library:safeCallback(keyPicker.changed, inputEvent.KeyCode or inputEvent.UserInputType)

                    library:attemptSave();

                    event:Disconnect();
                end);
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 and not library:mouseIsOverOpenedFrame() then
                modeSelectOuter.Visible = true;
            end;
        end);

        library:giveSignal(inputService.InputBegan:Connect(function(input)
            if (not picking) then
                if keyPicker.mode == 'Toggle' then
                    local key = keyPicker.value;

                    if key == 'MB1' or key == 'MB2' then
                        if key == 'MB1' and input.UserInputType == Enum.UserInputType.MouseButton1
                        or key == 'MB2' and input.UserInputType == Enum.UserInputType.MouseButton2 then
                            keyPicker.toggled = not keyPicker.toggled
                            keyPicker:doClick()
                        end;
                    elseif input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == key then
                            keyPicker.toggled = not keyPicker.toggled;
                            keyPicker:doClick()
                        end;
                    end;
                end;

                keyPicker:update();
            end;

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local absPos, absSize = modeSelectOuter.AbsolutePosition, modeSelectOuter.AbsoluteSize;

                if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X
                    or mouse.Y < (absPos.Y - 20 - 1) or mouse.Y > absPos.Y + absSize.Y then

                    modeSelectOuter.Visible = false;
                end;
            end;
        end))

        library:giveSignal(inputService.InputEnded:Connect(function(input)
            if (not picking) then
                keyPicker:update();
            end;
        end))

        keyPicker:update();

        options[idx] = keyPicker;

        return self;
    end;

    baseAddons.__index = funcs;
    baseAddons.__namecall = function(table, key, ...)
        return funcs[key](...);
    end;
end;

local baseGroupbox = {};

do
    local funcs = {};

    function funcs:addBlank(size)
        local groupbox = self;
        local container = groupbox.container;

        library:create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, size);
            ZIndex = 1;
            Parent = container;
        });
    end;

    function funcs:addLabel(text, doesWrap)
        local labelObj = {};

        local groupbox = self;
        local container = groupbox.container;

        local textLabel = library:createLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = text;
            TextWrapped = doesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = container;
        });

        if doesWrap then
            local y = select(2, library:getTextBounds(text, library.font, 14, Vector2.new(textLabel.AbsoluteSize.X, math.huge)))
            textLabel.Size = UDim2.new(1, -4, 0, y)
        else
            library:create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = textLabel;
            });
        end

        labelObj.textLabel = textLabel;
        labelObj.container = container;

        function labelObj:setText(newText)
            textLabel.Text = newText

            if doesWrap then
                local y = select(2, library:getTextBounds(newText, library.font, 14, Vector2.new(textLabel.AbsoluteSize.X, math.huge)))
                textLabel.Size = UDim2.new(1, -4, 0, y)
            end

            groupbox:resize();
        end

        if (not doesWrap) then
            setmetatable(labelObj, baseAddons);
        end

        groupbox:addBlank(5);
        groupbox:resize();

        return labelObj;
    end;

    function funcs:addButton(...)
        local button = {};
        local function processButtonParams(class, obj, ...)
            local props = select(1, ...)
            if type(props) == 'table' then
                obj.text = props.Text
                obj.func = props.Func
                obj.doubleClick = props.DoubleClick
                obj.tooltip = props.Tooltip
            else
                obj.text = select(1, ...)
                obj.func = select(2, ...)
            end

            assert(type(obj.func) == 'function', 'addButton: `Func` callback is missing.');
        end

        processButtonParams('button', button, ...)

        local groupbox = self;
        local container = groupbox.container;

        local function createBaseButton(btn)
            local outer = library:create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });

            local inner = library:create('Frame', {
                BackgroundColor3 = library.mainColor;
                BorderColor3 = library.outlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = outer;
            });

            local lbl = library:createLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = btn.text;
                ZIndex = 6;
                Parent = inner;
            });

            library:create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = inner;
            });

            library:addToRegistry(outer, {
                BorderColor3 = 'black';
            });

            library:addToRegistry(inner, {
                BackgroundColor3 = 'mainColor';
                BorderColor3 = 'outlineColor';
            });

            library:onHighlight(outer, outer,
                { BorderColor3 = 'accentColor' },
                { BorderColor3 = 'black' }
            );

            return outer, inner, lbl
        end

        local function initEvents(btn)
            local function waitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:Disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function validateClick(input)
                if library:mouseIsOverOpenedFrame() then
                    return false
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            btn.outer.InputBegan:Connect(function(input)
                if not validateClick(input) then return end
                if btn.locked then return end

                if btn.doubleClick then
                    library:removeFromRegistry(btn.label)
                    library:addToRegistry(btn.label, { TextColor3 = 'accentColor' })

                    btn.label.TextColor3 = library.accentColor
                    btn.label.Text = 'Are you sure?'
                    btn.locked = true

                    local clicked = waitForEvent(btn.outer.InputBegan, 0.5, validateClick)

                    library:removeFromRegistry(btn.label)
                    library:addToRegistry(btn.label, { TextColor3 = 'fontColor' })

                    btn.label.TextColor3 = library.fontColor
                    btn.label.Text = btn.text
                    task.defer(rawset, btn, 'locked', false)

                    if clicked then
                        library:safeCallback(btn.func)
                    end

                    return
                end

                library:safeCallback(btn.func);
            end)
        end

        button.outer, button.inner, button.label = createBaseButton(button)
        button.outer.Parent = container

        initEvents(button)

        function button:addTooltip(tooltipStr)
            if type(tooltipStr) == 'string' then
                library:addToolTip(tooltipStr, self.outer)
            end
            return self
        end


        function button:addButton(...)
            local subButton = {}

            processButtonParams('subButton', subButton, ...)

            self.outer.Size = UDim2.new(0.5, -2, 0, 20)

            subButton.outer, subButton.inner, subButton.label = createBaseButton(subButton)

            subButton.outer.Position = UDim2.new(1, 3, 0, 0)
            subButton.outer.Size = UDim2.fromOffset(self.outer.AbsoluteSize.X - 2, self.outer.AbsoluteSize.Y)
            subButton.outer.Parent = self.outer

            function subButton:addTooltip(tooltipStr)
                if type(tooltipStr) == 'string' then
                    library:addToolTip(tooltipStr, self.outer)
                end
                return subButton
            end

            if type(subButton.tooltip) == 'string' then
                subButton:addTooltip(subButton.tooltip)
            end

            initEvents(subButton)
            return subButton
        end

        if type(button.tooltip) == 'string' then
            button:addTooltip(button.tooltip)
        end

        groupbox:addBlank(5);
        groupbox:resize();

        return button;
    end;

    function funcs:addDivider()
        local groupbox = self;
        local container = self.container

        local divider = {
            type = 'divider',
        }

        groupbox:addBlank(2);
        local dividerOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = container;
        });

        local dividerInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = dividerOuter;
        });

        library:addToRegistry(dividerOuter, {
            BorderColor3 = 'black';
        });

        library:addToRegistry(dividerInner, {
            BackgroundColor3 = 'mainColor';
            BorderColor3 = 'outlineColor';
        });

        groupbox:addBlank(9);
        groupbox:resize();
    end

    function funcs:addInput(idx, info)
        assert(info.Text, 'addInput: Missing `Text` string.')

        local textbox = {
            value = info.Default or '';
            numeric = info.Numeric or false;
            finished = info.Finished or false;
            type = 'input';
            callback = info.Callback or function(val) end;
        };

        local groupbox = self;
        local container = groupbox.container;

        local inputLabel = library:createLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = container;
        });

        groupbox:addBlank(1);

        local textBoxOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = container;
        });

        local textBoxInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = textBoxOuter;
        });

        library:addToRegistry(textBoxInner, {
            BackgroundColor3 = 'mainColor';
            BorderColor3 = 'outlineColor';
        });

        library:onHighlight(textBoxOuter, textBoxOuter,
            { BorderColor3 = 'accentColor' },
            { BorderColor3 = 'black' }
        );

        if type(info.Tooltip) == 'string' then
            library:addToolTip(info.Tooltip, textBoxOuter)
        end

        library:create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = textBoxInner;
        });

        local innerContainer = library:create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = textBoxInner;
        })

        local box = library:create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = library.font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = info.Placeholder or '';

            Text = info.Default or '';
            TextColor3 = library.fontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = innerContainer;
        });

        library:applyTextStroke(box);

        function textbox:setValue(text)
            if info.MaxLength and #text > info.MaxLength then
                text = text:sub(1, info.MaxLength);
            end;

            if textbox.numeric then
                if (not tonumber(text)) and text:len() > 0 then
                    text = textbox.value
                end
            end

            textbox.value = text;
            box.Text = text;

            library:safeCallback(textbox.callback, textbox.value);
            library:safeCallback(textbox.changed, textbox.value);
        end;

        if textbox.finished then
            box.FocusLost:Connect(function(enter)
                if not enter then return end

                textbox:setValue(box.Text);
                library:attemptSave();
            end)
        else
            box:GetPropertyChangedSignal('Text'):Connect(function()
                textbox:setValue(box.Text);
                library:attemptSave();
            end);
        end

        local function updateCursorPosition()
            local PADDING = 2
            local reveal = innerContainer.AbsoluteSize.X

            if not box:IsFocused() or box.TextBounds.X <= reveal - 2 * PADDING then
                box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(box.Text, 1, cursor-1)
                    local width = textService:GetTextSize(subtext, box.TextSize, box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(updateCursorPosition)

        box:GetPropertyChangedSignal('Text'):Connect(updateCursorPosition)
        box:GetPropertyChangedSignal('CursorPosition'):Connect(updateCursorPosition)
        box.FocusLost:Connect(updateCursorPosition)
        box.Focused:Connect(updateCursorPosition)

        library:addToRegistry(box, {
            TextColor3 = 'fontColor';
        });

        function textbox:onChanged(func)
            textbox.changed = func;
            func(textbox.value);
        end;

        groupbox:addBlank(5);
        groupbox:resize();

        options[idx] = textbox;

        return textbox;
    end;

    function funcs:addToggle(idx, info)
        assert(info.Text, 'addInput: Missing `Text` string.')

        local toggle = {
            value = info.Default or false;
            type = 'toggle';

            callback = info.Callback or function(val) end;
            addons = {},
            risky = info.Risky,
        };

        local groupbox = self;
        local container = groupbox.container;

        local toggleOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = container;
        });

        library:addToRegistry(toggleOuter, {
            BorderColor3 = 'black';
        });

        local toggleInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = toggleOuter;
        });

        library:addToRegistry(toggleInner, {
            BackgroundColor3 = 'mainColor';
            BorderColor3 = 'outlineColor';
        });

        local toggleLabel = library:createLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = toggleInner;
        });

        library:create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = toggleLabel;
        });

        local toggleRegion = library:create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = toggleOuter;
        });

        library:onHighlight(toggleRegion, toggleOuter,
            { BorderColor3 = 'accentColor' },
            { BorderColor3 = 'black' }
        );

        function toggle:updateColors()
            toggle:display();
        end;

        if type(info.Tooltip) == 'string' then
            library:addToolTip(info.Tooltip, toggleRegion)
        end

        function toggle:display()
            toggleInner.BackgroundColor3 = toggle.value and library.accentColor or library.mainColor;
            toggleInner.BorderColor3 = toggle.value and library.accentColorDark or library.outlineColor;

            library.registryMap[toggleInner].properties.BackgroundColor3 = toggle.value and 'accentColor' or 'mainColor';
            library.registryMap[toggleInner].properties.BorderColor3 = toggle.value and 'accentColorDark' or 'outlineColor';
        end;

        function toggle:onChanged(func)
            toggle.changed = func;
            func(toggle.value);
        end;

        function toggle:setValue(bool)
            bool = (not not bool);

            toggle.value = bool;
            toggle:display();

            for _, addon in next, toggle.addons do
                if addon.type == 'keyPicker' and addon.syncToggleState then
                    addon.toggled = bool
                    addon:update()
                end
            end

            library:safeCallback(toggle.callback, toggle.value);
            library:safeCallback(toggle.changed, toggle.value);
            library:updateDependencyBoxes();
        end;

        toggleRegion.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
                toggle:setValue(not toggle.value)
                library:attemptSave();
            end;
        end);

        if toggle.risky then
            library:removeFromRegistry(toggleLabel)
            toggleLabel.TextColor3 = library.riskColor
            library:addToRegistry(toggleLabel, { TextColor3 = 'riskColor' })
        end

        toggle:display();
        groupbox:addBlank(info.BlankSize or 5 + 2);
        groupbox:resize();

        toggle.textLabel = toggleLabel;
        toggle.container = container;
        setmetatable(toggle, baseAddons);

        toggles[idx] = toggle;

        library:updateDependencyBoxes();

        return toggle;
    end;

    function funcs:addSlider(idx, info)
    assert(info.Default, 'addSlider: Missing default value.');
    assert(info.Text, 'addSlider: Missing slider text.');
    assert(info.Min, 'addSlider: Missing minimum value.');
    assert(info.Max, 'addSlider: Missing maximum value.');
    assert(info.Rounding, 'addSlider: Missing rounding value.');

    local slider = {
        value = info.Default;
        min = info.Min;
        max = info.Max;
        rounding = info.Rounding;
        type = 'slider';
        callback = info.Callback or function(val) end;
    };

    local groupbox = self;
    local container = groupbox.container;

    if not info.Compact then
        library:createLabel({
            Size = UDim2.new(1, 0, 0, 10);
            TextSize = 14;
            Text = info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Bottom;
            ZIndex = 5;
            Parent = container;
        });

        groupbox:addBlank(3);
    end

    local sliderOuter = library:create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderColor3 = Color3.new(0, 0, 0);
        Size = UDim2.new(1, -4, 0, 13);
        ZIndex = 5;
        Parent = container;
    });

    library:addToRegistry(sliderOuter, {
        BorderColor3 = 'black';
    });

    local sliderInner = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.outlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 6;
        Parent = sliderOuter;
    });

    library:addToRegistry(sliderInner, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'outlineColor';
    });

    local fill = library:create('Frame', {
        BackgroundColor3 = library.accentColor;
        BorderColor3 = library.accentColorDark;
        Size = UDim2.new(0, 0, 1, 0);
        ZIndex = 7;
        Parent = sliderInner;
    });

    library:addToRegistry(fill, {
        BackgroundColor3 = 'accentColor';
        BorderColor3 = 'accentColorDark';
    });

    local hideBorderRight = library:create('Frame', {
        BackgroundColor3 = library.accentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(1, 0, 0, 0);
        Size = UDim2.new(0, 1, 1, 0);
        ZIndex = 8;
        Parent = fill;
    });

    library:addToRegistry(hideBorderRight, {
        BackgroundColor3 = 'accentColor';
    });

    local displayLabel = library:createLabel({
        Size = UDim2.new(1, 0, 1, 0);
        TextSize = 14;
        Text = 'Infinite';
        ZIndex = 9;
        Parent = sliderInner;
    });

    library:onHighlight(sliderOuter, sliderOuter,
        { BorderColor3 = 'accentColor' },
        { BorderColor3 = 'black' }
    );

    if type(info.Tooltip) == 'string' then
        library:addToolTip(info.Tooltip, sliderOuter)
    end

    function slider:updateColors()
        fill.BackgroundColor3 = library.accentColor;
        fill.BorderColor3 = library.accentColorDark;
    end;

    function slider:display()
        local suffix = info.Suffix or '';

        if info.Compact then
            displayLabel.Text = info.Text .. ': ' .. slider.value .. suffix
        elseif info.HideMax then
            displayLabel.Text = string.format('%s', slider.value .. suffix)
        else
            displayLabel.Text = string.format('%s/%s', slider.value .. suffix, slider.max .. suffix);
        end

        -- Account for the 1 pixel border width by subtracting 1
        local maxSize = sliderInner.AbsoluteSize.X - 1;
        local x = math.clamp(math.ceil(library:mapValue(slider.value, slider.min, slider.max, 0, maxSize)), 0, maxSize);
        fill.Size = UDim2.new(0, x, 1, 0);

        hideBorderRight.Visible = not (x >= maxSize or x == 0);
    end;

    function slider:onChanged(func)
        slider.changed = func;
        func(slider.value);
    end;

    local function round(val)
        if slider.rounding == 0 then
            return math.floor(val);
        end;

        return tonumber(string.format('%.' .. slider.rounding .. 'f', val))
    end;

    function slider:getValueFromXOffset(x)
        -- Account for the 1 pixel border width by subtracting 1
        local maxSize = sliderInner.AbsoluteSize.X - 1;
        return round(library:mapValue(x, 0, maxSize, slider.min, slider.max));
    end;

    function slider:setValue(str)
        local num = tonumber(str);

        if (not num) then
            return;
        end;

        num = math.clamp(num, slider.min, slider.max);

        slider.value = num;
        slider:display();

        library:safeCallback(slider.callback, slider.value);
        library:safeCallback(slider.changed, slider.value);
    end;

    sliderInner.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
            local mPos = mouse.X;
            local gPos = fill.Size.X.Offset;
            local diff = mPos - (fill.AbsolutePosition.X + gPos);

            while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nMPos = mouse.X;
                -- Account for the 1 pixel border width by subtracting 1
                local maxSize = sliderInner.AbsoluteSize.X - 1;
                local nX = math.clamp(gPos + (nMPos - mPos) + diff, 0, maxSize);

                local nValue = slider:getValueFromXOffset(nX);
                local oldValue = slider.value;
                slider.value = nValue;

                slider:display();

                if nValue ~= oldValue then
                    library:safeCallback(slider.callback, slider.value);
                    library:safeCallback(slider.changed, slider.value);
                end;

                renderStepped:Wait();
            end;

            library:attemptSave();
        end;
    end);

    slider:display();
    groupbox:addBlank(info.BlankSize or 6);
    groupbox:resize();

    options[idx] = slider;

    return slider;
end;
    function funcs:addDropdown(idx, info)
        if info.SpecialType == 'Player' then
            info.Values = getPlayersString();
            info.AllowNull = true;
        elseif info.SpecialType == 'Team' then
            info.Values = getTeamsString();
            info.AllowNull = true;
        end;

        assert(info.Values, 'addDropdown: Missing dropdown value list.');
        assert(info.AllowNull or info.Default, 'addDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not info.Text) then
            info.Compact = true;
        end;

        local dropdown = {
            values = info.Values;
            value = info.Multi and {};
            multi = info.Multi;
            type = 'dropdown';
            specialType = info.SpecialType; 
            callback = info.Callback or function(val) end;
        };

        local groupbox = self;
        local container = groupbox.container;

        local relativeOffset = 0;

        if not info.Compact then
            local dropdownLabel = library:createLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = container;
            });

            groupbox:addBlank(3);
        end

        for _, element in next, container:GetChildren() do
            if not element:IsA('UIListLayout') then
                relativeOffset = relativeOffset + element.Size.Y.Offset;
            end;
        end;

        local dropdownOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = container;
        });

        library:addToRegistry(dropdownOuter, {
            BorderColor3 = 'black';
        });

        local dropdownInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = dropdownOuter;
        });

        library:addToRegistry(dropdownInner, {
            BackgroundColor3 = 'mainColor';
            BorderColor3 = 'outlineColor';
        });

        library:create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = dropdownInner;
        });

        local dropdownArrow = library:create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = dropdownInner;
        });

        local itemList = library:createLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = dropdownInner;
        });

        library:onHighlight(dropdownOuter, dropdownOuter,
            { BorderColor3 = 'accentColor' },
            { BorderColor3 = 'black' }
        );

        if type(info.Tooltip) == 'string' then
            library:addToolTip(info.Tooltip, dropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local listOuter = library:create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = screenGui;
        });

        local function recalculateListPosition()
            listOuter.Position = UDim2.fromOffset(dropdownOuter.AbsolutePosition.X, dropdownOuter.AbsolutePosition.Y + dropdownOuter.Size.Y.Offset + 1);
        end;

        local function recalculateListSize(ySize)
            listOuter.Size = UDim2.fromOffset(dropdownOuter.AbsoluteSize.X, ySize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;

        recalculateListPosition();
        recalculateListSize();

        dropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(recalculateListPosition);

        local listInner = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderColor3 = library.outlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = listOuter;
        });

        library:addToRegistry(listInner, {
            BackgroundColor3 = 'mainColor';
            BorderColor3 = 'outlineColor';
        });

        local scrolling = library:create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = listInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = library.accentColor,
        });

        library:addToRegistry(scrolling, {
            ScrollBarImageColor3 = 'accentColor'
        })

        library:create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = scrolling;
        });

        function dropdown:display()
            local vals = dropdown.values;
            local str = '';

            if info.Multi then
                for idx, val in next, vals do
                    if dropdown.value[val] then
                        str = str .. val .. ', ';
                    end;
                end;

                str = str:sub(1, #str - 2);
            else
                str = dropdown.value or '';
            end;

            itemList.Text = (str == '' and '--' or str);
        end;

        function dropdown:getActiveValues()
            if info.Multi then
                local t = {};

                for val, bool in next, dropdown.value do
                    table.insert(t, val);
                end;

                return t;
            else
                return dropdown.value and 1 or 0;
            end;
        end;

        function dropdown:buildDropdownList()
            local vals = dropdown.values;
            local buttons = {};

            for _, element in next, scrolling:GetChildren() do
                if not element:IsA('UIListLayout') then
                    element:Destroy();
                end;
            end;

            local count = 0;

            for idx, val in next, vals do
                local listTable = {};

                count = count + 1;

                local button = library:create('Frame', {
                    BackgroundColor3 = library.mainColor;
                    BorderColor3 = library.outlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = scrolling;
                });

                library:addToRegistry(button, {
                    BackgroundColor3 = 'mainColor';
                    BorderColor3 = 'outlineColor';
                });

                local buttonLabel = library:createLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = val;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = button;
                });

                library:onHighlight(button, button,
                    { BorderColor3 = 'accentColor', ZIndex = 24 },
                    { BorderColor3 = 'outlineColor', ZIndex = 23 }
                );

                local selected;

                if info.Multi then
                    selected = dropdown.value[val];
                else
                    selected = dropdown.value == val;
                end;

                function listTable:updateButton()
                    if info.Multi then
                        selected = dropdown.value[val];
                    else
                        selected = dropdown.value == val;
                    end;

                    buttonLabel.TextColor3 = selected and library.accentColor or library.fontColor;
                    library.registryMap[buttonLabel].properties.TextColor3 = selected and 'accentColor' or 'fontColor';
                end;

                buttonLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local try = not selected;

                        if dropdown:getActiveValues() == 1 and (not try) and (not info.AllowNull) then
                        else
                            if info.Multi then
                                selected = try;

                                if selected then
                                    dropdown.value[val] = true;
                                else
                                    dropdown.value[val] = nil;
                                end;
                            else
                                selected = try;

                                if selected then
                                    dropdown.value = val;
                                else
                                    dropdown.value = nil;
                                end;

                                for _, otherButton in next, buttons do
                                    otherButton:updateButton();
                                end;
                            end;

                            listTable:updateButton();
                            dropdown:display();

                            library:safeCallback(dropdown.callback, dropdown.value);
                            library:safeCallback(dropdown.changed, dropdown.value);

                            library:attemptSave();
                        end;
                    end;
                end);

                listTable:updateButton();
                dropdown:display();

                buttons[button] = listTable;
            end;

            scrolling.CanvasSize = UDim2.fromOffset(0, (count * 20) + 1);

            local y = math.clamp(count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            recalculateListSize(y);
        end;

        function dropdown:setValues(newValues)
            if newValues then
                dropdown.values = newValues;
            end;

            dropdown:buildDropdownList();
        end;

        function dropdown:openDropdown()
            listOuter.Visible = true;
            library.openedFrames[listOuter] = true;
            dropdownArrow.Rotation = 180;
        end;

        function dropdown:closeDropdown()
            listOuter.Visible = false;
            library.openedFrames[listOuter] = nil;
            dropdownArrow.Rotation = 0;
        end;

        function dropdown:onChanged(func)
            dropdown.changed = func;
            func(dropdown.value);
        end;

        function dropdown:setValue(val)
            if dropdown.multi then
                local nTable = {};

                for value, bool in next, val do
                    if table.find(dropdown.values, value) then
                        nTable[value] = true
                    end;
                end;

                dropdown.value = nTable;
            else
                if (not val) then
                    dropdown.value = nil;
                elseif table.find(dropdown.values, val) then
                    dropdown.value = val;
                end;
            end;

            dropdown:buildDropdownList();

            library:safeCallback(dropdown.callback, dropdown.value);
            library:safeCallback(dropdown.changed, dropdown.value);
        end;

        dropdownOuter.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
                if listOuter.Visible then
                    dropdown:closeDropdown();
                else
                    dropdown:openDropdown();
                end;
            end;
        end);

        inputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local absPos, absSize = listOuter.AbsolutePosition, listOuter.AbsoluteSize;

                if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X
                    or mouse.Y < (absPos.Y - 20 - 1) or mouse.Y > absPos.Y + absSize.Y then

                    dropdown:closeDropdown();
                end;
            end;
        end);

        dropdown:buildDropdownList();
        dropdown:display();

        local defaults = {}

        if type(info.Default) == 'string' then
            local findIdx = table.find(dropdown.values, info.Default)
            if findIdx then
                table.insert(defaults, findIdx)
            end
        elseif type(info.Default) == 'table' then
            for _, val in next, info.Default do
                local findIdx = table.find(dropdown.values, val)
                if findIdx then
                    table.insert(defaults, findIdx)
                end
            end
        elseif type(info.Default) == 'number' and dropdown.values[info.Default] ~= nil then
            table.insert(defaults, info.Default)
        end

        if next(defaults) then
            for i = 1, #defaults do
                local index = defaults[i]
                if info.Multi then
                    dropdown.value[dropdown.values[index]] = true
                else
                    dropdown.value = dropdown.values[index];
                end

                if (not info.Multi) then break end
            end

            dropdown:buildDropdownList();
            dropdown:display();
        end

        groupbox:addBlank(info.BlankSize or 5);
        groupbox:resize();

        options[idx] = dropdown;

        return dropdown;
    end;

    function funcs:addDependencyBox()
        local depbox = {
            dependencies = {};
        };
        
        local groupbox = self;
        local container = groupbox.container;

        local holder = library:create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = container;
        });

        local frame = library:create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = holder;
        });

        local layout = library:create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = frame;
        });

        function depbox:resize()
            holder.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y);
            groupbox:resize();
        end;

        layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            depbox:resize();
        end);

        holder:GetPropertyChangedSignal('Visible'):Connect(function()
            depbox:resize();
        end);

        function depbox:update()
            for _, dependency in next, depbox.dependencies do
                local elem = dependency[1];
                local value = dependency[2];

                if elem.type == 'toggle' and elem.value ~= value then
                    holder.Visible = false;
                    depbox:resize();
                    return;
                end;
            end;

            holder.Visible = true;
            depbox:resize();
        end;

        function depbox:setupDependencies(dependencies)
            for _, dependency in next, dependencies do
                assert(type(dependency) == 'table', 'setupDependencies: Dependency is not of type `table`.');
                assert(dependency[1], 'setupDependencies: Dependency is missing element argument.');
                assert(dependency[2] ~= nil, 'setupDependencies: Dependency is missing value argument.');
            end;

            depbox.dependencies = dependencies;
            depbox:update();
        end;

        depbox.container = frame;

        setmetatable(depbox, baseGroupbox);

        table.insert(library.dependencyBoxes, depbox);

        return depbox;
    end;

    baseGroupbox.__index = funcs;
    baseGroupbox.__namecall = function(table, key, ...)
        return funcs[key](...);
    end;
end;

do
    library.notificationArea = library:create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = screenGui;
    });

    library:create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = library.notificationArea;
    });

    local watermarkOuter = library:create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = screenGui;
    });

    local watermarkInner = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.accentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = watermarkOuter;
    });

    library:addToRegistry(watermarkInner, {
        BorderColor3 = 'accentColor';
    });

    local innerFrame = library:create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = watermarkInner;
    });

    local gradient = library:create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, library:getDarkerColor(library.mainColor)),
            ColorSequenceKeypoint.new(1, library.mainColor),
        });
        Rotation = -90;
        Parent = innerFrame;
    });

    library:addToRegistry(gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, library:getDarkerColor(library.mainColor)),
                ColorSequenceKeypoint.new(1, library.mainColor),
            });
        end
    });

    local watermarkLabel = library:createLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = innerFrame;
    });

    library.watermark = watermarkOuter;
    library.watermarkText = watermarkLabel;
    library:makeDraggable(library.watermark);

    local keybindOuter = library:create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = screenGui;
    });

    local keybindInner = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.outlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = keybindOuter;
    });

    library:addToRegistry(keybindInner, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'outlineColor';
    }, true);

    local colorFrame = library:create('Frame', {
        BackgroundColor3 = library.accentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = keybindInner;
    });

    library:addToRegistry(colorFrame, {
        BackgroundColor3 = 'accentColor';
    }, true);

    local keybindLabel = library:createLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = keybindInner;
    });

    local keybindContainer = library:create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = keybindInner;
    });

    library:create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = keybindContainer;
    });

    library:create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = keybindContainer,
    })

    library.keybindFrame = keybindOuter;
    library.keybindContainer = keybindContainer;
    library:makeDraggable(keybindOuter);
end;

function library:setWatermarkVisibility(bool)
    library.watermark.Visible = bool;
end;

function library:setWatermark(text)
    local x, y = library:getTextBounds(text, library.font, 14);
    library.watermark.Size = UDim2.new(0, x + 15, 0, (y * 1.5) + 3);
    library:setWatermarkVisibility(true)

    library.watermarkText.Text = text;
end;

function library:notify(text, timeAmount)
    local xSize, ySize = library:getTextBounds(text, library.font, 14);

    ySize = ySize + 7

    local notifyOuter = library:create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, ySize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = library.notificationArea;
    });

    local notifyInner = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.outlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = notifyOuter;
    });

    library:addToRegistry(notifyInner, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'outlineColor';
    }, true);

    local innerFrame = library:create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = notifyInner;
    });

    local gradient = library:create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, library:getDarkerColor(library.mainColor)),
            ColorSequenceKeypoint.new(1, library.mainColor),
        });
        Rotation = -90;
        Parent = innerFrame;
    });

    library:addToRegistry(gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, library:getDarkerColor(library.mainColor)),
                ColorSequenceKeypoint.new(1, library.mainColor),
            });
        end
    });

    local notifyLabel = library:createLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = innerFrame;
    });

    local leftColor = library:create('Frame', {
        BackgroundColor3 = library.accentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = notifyOuter;
    });

    library:addToRegistry(leftColor, {
        BackgroundColor3 = 'accentColor';
    }, true);

    pcall(notifyOuter.TweenSize, notifyOuter, UDim2.new(0, xSize + 8 + 4, 0, ySize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(timeAmount or 5);

        pcall(notifyOuter.TweenSize, notifyOuter, UDim2.new(0, 0, 0, ySize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        notifyOuter:Destroy();
    end);
end;

function library:createWindow(...)
    local arguments = { ... }
    local config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        config = ...;
    else
        config.Title = arguments[1]
        config.AutoShow = arguments[2] or false;
    end

    if type(config.Title) ~= 'string' then config.Title = 'No title' end
    if type(config.TabPadding) ~= 'number' then config.TabPadding = 0 end
    if type(config.MenuFadeTime) ~= 'number' then config.MenuFadeTime = 0.2 end

    if typeof(config.Position) ~= 'UDim2' then config.Position = UDim2.fromOffset(175, 50) end
    if typeof(config.Size) ~= 'UDim2' then config.Size = UDim2.fromOffset(550, 600) end

    if config.Center then
        config.AnchorPoint = Vector2.new(0.5, 0.5)
        config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local window = {
        tabs = {};
    };

    local outer = library:create('Frame', {
        AnchorPoint = config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = config.Position,
        Size = config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = screenGui;
    });

    library:makeDraggable(outer, 25);

    local inner = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.accentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = outer;
    });

    library:addToRegistry(inner, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'accentColor';
    });

    local windowLabel = library:createLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = inner;
    });

    local mainSectionOuter = library:create('Frame', {
        BackgroundColor3 = library.backgroundColor;
        BorderColor3 = library.outlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = inner;
    });

    library:addToRegistry(mainSectionOuter, {
        BackgroundColor3 = 'backgroundColor';
        BorderColor3 = 'outlineColor';
    });

    local mainSectionInner = library:create('Frame', {
        BackgroundColor3 = library.backgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = mainSectionOuter;
    });

    library:addToRegistry(mainSectionInner, {
        BackgroundColor3 = 'backgroundColor';
    });

    local tabArea = library:create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = mainSectionInner;
    });

    local tabListLayout = library:create('UIListLayout', {
        Padding = UDim.new(0, config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = tabArea;
    });

    local tabContainer = library:create('Frame', {
        BackgroundColor3 = library.mainColor;
        BorderColor3 = library.outlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = mainSectionInner;
    });
    

    library:addToRegistry(tabContainer, {
        BackgroundColor3 = 'mainColor';
        BorderColor3 = 'outlineColor';
    });

    function window:setWindowTitle(title)
        windowLabel.Text = title;
    end;

    function window:addTab(name)
        local tab = {
            groupboxes = {};
            tabboxes = {};
        };

        local tabButtonWidth = library:getTextBounds(name, library.font, 16);

        local tabButton = library:create('Frame', {
            BackgroundColor3 = library.backgroundColor;
            BorderColor3 = library.outlineColor;
            Size = UDim2.new(0, tabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = tabArea;
        });

        library:addToRegistry(tabButton, {
            BackgroundColor3 = 'backgroundColor';
            BorderColor3 = 'outlineColor';
        });

        local tabButtonLabel = library:createLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = name;
            ZIndex = 1;
            Parent = tabButton;
        });

        local blocker = library:create('Frame', {
            BackgroundColor3 = library.mainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = tabButton;
        });

        library:addToRegistry(blocker, {
            BackgroundColor3 = 'mainColor';
        });

        local tabFrame = library:create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = tabContainer;
        });

        local leftSide = library:create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = tabFrame;
        });

        local rightSide = library:create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = tabFrame;
        });

        library:create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = leftSide;
        });

        library:create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = rightSide;
        });

        for _, side in next, { leftSide, rightSide } do
            side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                side.CanvasSize = UDim2.fromOffset(0, side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function tab:showTab()
            for _, tabRef in next, window.tabs do
                tabRef:hideTab();
            end;

            blocker.BackgroundTransparency = 0;
            tabButton.BackgroundColor3 = library.mainColor;
            library.registryMap[tabButton].properties.BackgroundColor3 = 'mainColor';
            tabFrame.Visible = true;
        end;

        function tab:hideTab()
            blocker.BackgroundTransparency = 1;
            tabButton.BackgroundColor3 = library.backgroundColor;
            library.registryMap[tabButton].properties.BackgroundColor3 = 'backgroundColor';
            tabFrame.Visible = false;
        end;

        function tab:setLayoutOrder(position)
            tabButton.LayoutOrder = position;
            tabListLayout:ApplyLayout();
        end;

        function tab:addGroupbox(info)
            local groupbox = {};

            local boxOuter = library:create('Frame', {
                BackgroundColor3 = library.backgroundColor;
                BorderColor3 = library.outlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = info.Side == 1 and leftSide or rightSide;
            });

            library:addToRegistry(boxOuter, {
                BackgroundColor3 = 'backgroundColor';
                BorderColor3 = 'outlineColor';
            });

            local boxInner = library:create('Frame', {
                BackgroundColor3 = library.backgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = boxOuter;
            });

            library:addToRegistry(boxInner, {
                BackgroundColor3 = 'backgroundColor';
            });

            local highlight = library:create('Frame', {
                BackgroundColor3 = library.accentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = boxInner;
            });

            library:addToRegistry(highlight, {
                BackgroundColor3 = 'accentColor';
            });

            local groupboxLabel = library:createLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = boxInner;
            });

            local container = library:create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = boxInner;
            });

            library:create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = container;
            });

            function groupbox:resize()
                local size = 0;

                for _, element in next, groupbox.container:GetChildren() do
                    if (not element:IsA('UIListLayout')) and element.Visible then
                        size = size + element.Size.Y.Offset;
                    end;
                end;

                boxOuter.Size = UDim2.new(1, 0, 0, 20 + size + 2 + 2);
            end;

            groupbox.container = container;
            setmetatable(groupbox, baseGroupbox);

            groupbox:addBlank(3);
            groupbox:resize();

            tab.groupboxes[info.Name] = groupbox;

            return groupbox;
        end;

        function tab:addLeftGroupbox(name)
            return tab:addGroupbox({ Side = 1; Name = name; });
        end;

        function tab:addRightGroupbox(name)
            return tab:addGroupbox({ Side = 2; Name = name; });
        end;

        function tab:addTabbox(info)
            local tabbox = {
                tabs = {};
            };

            local boxOuter = library:create('Frame', {
                BackgroundColor3 = library.backgroundColor;
                BorderColor3 = library.outlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = info.Side == 1 and leftSide or rightSide;
            });

            library:addToRegistry(boxOuter, {
                BackgroundColor3 = 'backgroundColor';
                BorderColor3 = 'outlineColor';
            });

            local boxInner = library:create('Frame', {
                BackgroundColor3 = library.backgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = boxOuter;
            });

            library:addToRegistry(boxInner, {
                BackgroundColor3 = 'backgroundColor';
            });

            local highlight = library:create('Frame', {
                BackgroundColor3 = library.accentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = boxInner;
            });

            library:addToRegistry(highlight, {
                BackgroundColor3 = 'accentColor';
            });

            local tabboxButtons = library:create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = boxInner;
            });

            library:create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = tabboxButtons;
            });

            function tabbox:addTab(name)
                local subTab = {};

                local button = library:create('Frame', {
                    BackgroundColor3 = library.mainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = tabboxButtons;
                });

                library:addToRegistry(button, {
                    BackgroundColor3 = 'mainColor';
                });

                local buttonLabel = library:createLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = button;
                });

                local block = library:create('Frame', {
                    BackgroundColor3 = library.backgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = button;
                });

                library:addToRegistry(block, {
                    BackgroundColor3 = 'backgroundColor';
                });

                local container = library:create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = boxInner;
                });

                library:create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = container;
                });

                function subTab:show()
                    for _, t in next, tabbox.tabs do
                        t:hide();
                    end;

                    container.Visible = true;
                    block.Visible = true;

                    button.BackgroundColor3 = library.backgroundColor;
                    library.registryMap[button].properties.BackgroundColor3 = 'backgroundColor';

                    subTab:resize();
                end;

                function subTab:hide()
                    container.Visible = false;
                    block.Visible = false;

                    button.BackgroundColor3 = library.mainColor;
                    library.registryMap[button].properties.BackgroundColor3 = 'mainColor';
                end;

                function subTab:resize()
                    local tabCount = 0;

                    for _, _ in next, tabbox.tabs do
                        tabCount = tabCount + 1;
                    end;

                    for _, btn in next, tabboxButtons:GetChildren() do
                        if not btn:IsA('UIListLayout') then
                            btn.Size = UDim2.new(1 / tabCount, 0, 1, 0);
                        end;
                    end;

                    if (not container.Visible) then
                        return;
                    end;

                    local size = 0;

                    for _, element in next, subTab.container:GetChildren() do
                        if (not element:IsA('UIListLayout')) and element.Visible then
                            size = size + element.Size.Y.Offset;
                        end;
                    end;

                    boxOuter.Size = UDim2.new(1, 0, 0, 20 + size + 2 + 2);
                end;

                button.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and not library:mouseIsOverOpenedFrame() then
                        subTab:show();
                        subTab:resize();
                    end;
                end);

                subTab.container = container;
                tabbox.tabs[name] = subTab;

                setmetatable(subTab, baseGroupbox);

                subTab:addBlank(3);
                subTab:resize();

                if #tabboxButtons:GetChildren() == 2 then
                    subTab:show();
                end;

                return subTab;
            end;

            tab.tabboxes[info.Name or ''] = tabbox;

            return tabbox;
        end;

        function tab:addLeftTabbox(name)
            return tab:addTabbox({ Name = name, Side = 1; });
        end;

        function tab:addRightTabbox(name)
            return tab:addTabbox({ Name = name, Side = 2; });
        end;

        tabButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                tab:showTab();
            end;
        end);

        if #tabContainer:GetChildren() == 1 then
            tab:showTab();
        end;

        window.tabs[name] = tab;
        return tab;
    end;

    local modalElement = library:create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = screenGui;
    });

    local transparencyCache = {};
    local toggled = false;
    local fading = false;

    function library:toggle()
        if fading then
            return;
        end;

        local fadeTime = config.MenuFadeTime;
        fading = true;
        toggled = (not toggled);
        modalElement.Modal = toggled;

        if toggled then
            outer.Visible = true;

            task.spawn(function()
                local state = inputService.MouseIconEnabled;

                local cursor = Drawing.new('Triangle');
                cursor.Thickness = 1;
                cursor.Filled = true;
                cursor.Visible = library.useCustomCursor;

                local cursorOutline = Drawing.new('Triangle');
                cursorOutline.Thickness = 1;
                cursorOutline.Filled = false;
                cursorOutline.Color = Color3.new(0, 0, 0);
                cursorOutline.Visible = library.useCustomCursor;

                while toggled and screenGui.Parent do
                    if library.useCustomCursor then
                        inputService.MouseIconEnabled = false;
                        cursor.Visible = true;
                        cursorOutline.Visible = true;
                        
                        local mPos = inputService:GetMouseLocation();

                        cursor.Color = library.cursorColor or library.accentColor;

                        cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                        cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                        cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);

                        cursorOutline.PointA = cursor.PointA;
                        cursorOutline.PointB = cursor.PointB;
                        cursorOutline.PointC = cursor.PointC;
                    else
                        inputService.MouseIconEnabled = true;
                        cursor.Visible = false;
                        cursorOutline.Visible = false;
                    end

                    renderStepped:Wait();
                end;

                inputService.MouseIconEnabled = state;

                cursor:Remove();
                cursorOutline:Remove();
            end);
        end;

        for _, desc in next, outer:GetDescendants() do
            local properties = {};

            if desc:IsA('ImageLabel') then
                table.insert(properties, 'ImageTransparency');
                table.insert(properties, 'BackgroundTransparency');
            elseif desc:IsA('TextLabel') or desc:IsA('TextBox') then
                table.insert(properties, 'TextTransparency');
            elseif desc:IsA('Frame') or desc:IsA('ScrollingFrame') then
                table.insert(properties, 'BackgroundTransparency');
            elseif desc:IsA('UIStroke') then
                table.insert(properties, 'Transparency');
            end;

            local cache = transparencyCache[desc];

            if (not cache) then
                cache = {};
                transparencyCache[desc] = cache;
            end;

            for _, prop in next, properties do
                if not cache[prop] then
                    cache[prop] = desc[prop];
                end;

                if cache[prop] == 1 then
                    continue;
                end;

                tweenService:Create(desc, TweenInfo.new(fadeTime, Enum.EasingStyle.Linear), { [prop] = toggled and cache[prop] or 1 }):Play();
            end;
        end;

        task.wait(fadeTime);

        outer.Visible = toggled;

        fading = false;
    end

    library:giveSignal(inputService.InputBegan:Connect(function(input, processed)
        if type(library.toggleKeybind) == 'table' and library.toggleKeybind.type == 'keyPicker' then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == library.toggleKeybind.value then
                task.spawn(library.toggle, library)
            end
        elseif input.KeyCode == Enum.KeyCode.RightControl or (input.KeyCode == Enum.KeyCode.RightShift and (not processed)) then
            task.spawn(library.toggle, library)
        end
    end))

    if config.AutoShow then task.spawn(library.toggle, library) end

    window.holder = outer;

    return window;
end;

local function onPlayerChange()
    local playerList = getPlayersString();

    for _, value in next, options do
        if value.type == 'dropdown' and value.specialType == 'Player' then
            value:setValues(playerList);
        end;
    end;
end;

players.PlayerAdded:Connect(onPlayerChange);
players.PlayerRemoving:Connect(onPlayerChange);

getgenv().library = library
return library
