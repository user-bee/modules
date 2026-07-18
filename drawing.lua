local drawing = {}

local rs = game:GetService("RunService")
local activeConnections = {}
local activeDrawings = {}

function drawing.drawLine(fromPos, toPos, color, thickness, transparency, visible)
    local line = Drawing.new("Line")
    line.From = fromPos or Vector2.new(0, 0)
    line.To = toPos or Vector2.new(0, 0)
    line.Color = color or Color3.fromRGB(255, 255, 255)
    line.Thickness = thickness or 1
    line.Transparency = transparency or 1
    line.Visible = visible == nil and true or visible
    table.insert(activeDrawings, line)
    return line
end

function drawing.drawCircle(position, radius, color, thickness, transparency, filled, numSides, visible)
    local circle = Drawing.new("Circle")
    circle.Position = position or Vector2.new(0, 0)
    circle.Radius = radius or 50
    circle.Color = color or Color3.fromRGB(255, 255, 255)
    circle.Thickness = thickness or 1
    circle.Transparency = transparency or 1
    circle.Filled = filled or false
    circle.NumSides = numSides or 32
    circle.Visible = visible == nil and true or visible
    table.insert(activeDrawings, circle)
    return circle
end

function drawing.drawSquare(position, size, color, thickness, transparency, filled, visible)
    local square = Drawing.new("Square")
    square.Position = position or Vector2.new(0, 0)
    square.Size = size or Vector2.new(50, 50)
    square.Color = color or Color3.fromRGB(255, 255, 255)
    square.Thickness = thickness or 1
    square.Transparency = transparency or 1
    square.Filled = filled or false
    square.Visible = visible == nil and true or visible
    table.insert(activeDrawings, square)
    return square
end

function drawing.drawText(text, position, size, color, center, outline, outlineColor, visible)
    local txt = Drawing.new("Text")
    txt.Text = text or ""
    txt.Position = position or Vector2.new(0, 0)
    txt.Size = size or 16
    txt.Color = color or Color3.fromRGB(255, 255, 255)
    txt.Center = center or false
    txt.Outline = outline or false
    txt.OutlineColor = outlineColor or Color3.fromRGB(0, 0, 0)
    txt.Visible = visible == nil and true or visible
    table.insert(activeDrawings, txt)
    return txt
end

function drawing.drawTriangle(posA, posB, posC, color, thickness, transparency, filled, visible)
    local triangle = Drawing.new("Triangle")
    triangle.PointA = posA or Vector2.new(0, 0)
    triangle.PointB = posB or Vector2.new(50, 50)
    triangle.PointC = posC or Vector2.new(0, 50)
    triangle.Color = color or Color3.fromRGB(255, 255, 255)
    triangle.Thickness = thickness or 1
    triangle.Transparency = transparency or 1
    triangle.Filled = filled or false
    triangle.Visible = visible == nil and true or visible
    table.insert(activeDrawings, triangle)
    return triangle
end

function drawing.drawQuad(posA, posB, posC, posD, color, thickness, transparency, filled, visible)
    local quad = Drawing.new("Quad")
    quad.PointA = posA or Vector2.new(0, 0)
    quad.PointB = posB or Vector2.new(50, 0)
    quad.PointC = posC or Vector2.new(50, 50)
    quad.PointD = posD or Vector2.new(0, 50)
    quad.Color = color or Color3.fromRGB(255, 255, 255)
    quad.Thickness = thickness or 1
    quad.Transparency = transparency or 1
    quad.Filled = filled or false
    quad.Visible = visible == nil and true or visible
    table.insert(activeDrawings, quad)
    return quad
end

function drawing.drawRotatingShape(position, sides, radius, rotationSpeed, color, thickness, transparency)
    local lines = {}
    local rotation = 0
    local shapeData = {}
    
    for i = 1, sides do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = color or Color3.fromRGB(255, 255, 255)
        line.Thickness = thickness or 1
        line.Transparency = transparency or 1
        table.insert(lines, line)
        table.insert(activeDrawings, line)
    end
    
    local connection = rs.RenderStepped:Connect(function()
        local pos = type(position) == "function" and position() or position
        rotation = rotation + rotationSpeed
        
        for i = 1, sides do
            local angle1 = rotation + (math.pi * 2 / sides) * i
            local angle2 = rotation + (math.pi * 2 / sides) * (i + 1)
            
            lines[i].From = Vector2.new(
                pos.X + math.cos(angle1) * radius,
                pos.Y + math.sin(angle1) * radius
            )
            lines[i].To = Vector2.new(
                pos.X + math.cos(angle2) * radius,
                pos.Y + math.sin(angle2) * radius
            )
        end
    end)
    
    table.insert(activeConnections, connection)
    
    shapeData.lines = lines
    shapeData.connection = connection
    
    function shapeData:removeShape()
        self.connection:Disconnect()
        for _, line in ipairs(self.lines) do
            line:Remove()
        end
    end
    
    return shapeData
end

function drawing.clearAll()
    for _, conn in ipairs(activeConnections) do
        conn:Disconnect()
    end
    table.clear(activeConnections)
    
    for _, drawObj in ipairs(activeDrawings) do
        drawObj:Remove()
    end
    table.clear(activeDrawings)
end

return drawing
