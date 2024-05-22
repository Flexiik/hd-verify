local MazeGenerator = {}
MazeGenerator.__index = MazeGenerator

local mazeWidth = 11
local mazeHeight = 11

local CellType = { Wall = 0, Path = 1, Start = 2, End = 3, Trail = 4}

local directions = {
    {x = 1, y = 0}, -- Right
    {x = -1, y = 0}, -- Left
    {x = 0, y = 1}, -- Down
    {x = 0, y = -1} -- Up
}

function MazeGenerator.new(sizeX, sizeY)
    local self = setmetatable({}, MazeGenerator)

    local grid = {}

    mazeWidth = sizeX
    mazeHeight = sizeY

    for y = 1, mazeHeight do
        grid[y] = {}
        for x = 1, mazeWidth do
            grid[y][x] = CellType.Wall
        end
    end

    self.grid = grid

    return self
end

function MazeGenerator:DestroyCurrentMazeFromWorkspace()
    for _, part in pairs(game:GetService("Workspace").Baseplate:GetChildren()) do
        if part:IsA("BasePart") then
            part:Destroy()
        end
    end
end

function MazeGenerator:Generate(startX, startY)
    self.grid[startY][startX] = CellType.Path
    if not self.startPointX and not self.startPointY then
        self.startPointX = startX
        self.startPointY = startY
    end
    
    local directionsShuffled = self:_shuffle(directions)

    for _, direction in ipairs(directionsShuffled) do
        local newX = startX + direction.x * 2
        local newY = startY + direction.y * 2

        if newX > 0 and newX <= mazeWidth and newY > 0 and newY <= mazeHeight and self.grid[newY][newX] == CellType.Wall then
            self.grid[startY + direction.y][startX + direction.x] = CellType.Path
            self.grid[newY][newX] = CellType.Path
            self:Generate(newX, newY)
        end
    end
end


function MazeGenerator:_parseGridPositionIntoPart(cellSize, gridY, gridX, yToPlaceAt, color)
    -- g[1][2] - x = 0, z = 1
    local partPosition = Vector3.new((gridY - 1) * cellSize, yToPlaceAt, (gridX - 1) * cellSize)
    local partSize = Vector3.new(cellSize, 1, cellSize)

    local newPart = Instance.new("Part")
    newPart.Name = "MazePartY" .. gridY .. "X" .. gridX
    newPart.BrickColor = color
    newPart.Position = partPosition
    newPart.Size = partSize
    newPart.Anchored = true

    return newPart
end

-- calculates the Manhattan distance between two points, which is used as the heuristic for the A* algorithm.
function MazeGenerator:_heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

-- Implementing A* Algorithm
function MazeGenerator:_aStar(start, goal)
    local openSet = {start}
    local cameFrom = {}

    local gScore = {}
    local fScore = {}
    for y = 1, mazeHeight do
        gScore[y] = {}
        fScore[y] = {}
        for x = 1, mazeWidth do
            gScore[y][x] = math.huge
            fScore[y][x] = math.huge
        end
    end

    gScore[start.y][start.x] = 0
    fScore[start.y][start.x] = self:_heuristic(start, goal)

    while #openSet > 0 do
        table.sort(openSet, function(a, b)
            return fScore[a.y][a.x] < fScore[b.y][b.x]
        end)

        local current = table.remove(openSet, 1)

        if current.x == goal.x and current.y == goal.y then
            local path = {}
            while current do
                table.insert(path, 1, current)
                current = cameFrom[current.y] and cameFrom[current.y][current.x]
            end
            return path
        end

        for _, direction in ipairs(directions) do
            local neighbor = {x = current.x + direction.x, y = current.y + direction.y}
            if neighbor.x > 0 and neighbor.x <= mazeWidth and neighbor.y > 0 and neighbor.y <= mazeHeight and self.grid[neighbor.y][neighbor.x] ~= CellType.Wall then
                local tentativeGScore = gScore[current.y][current.x] + 1

                if tentativeGScore < gScore[neighbor.y][neighbor.x] then
                    cameFrom[neighbor.y] = cameFrom[neighbor.y] or {}
                    cameFrom[neighbor.y][neighbor.x] = current
                    gScore[neighbor.y][neighbor.x] = tentativeGScore
                    fScore[neighbor.y][neighbor.x] = gScore[neighbor.y][neighbor.x] + self:_heuristic(neighbor, goal)

                    if not self:_isInList(openSet, neighbor) then
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end

    return nil
end

function MazeGenerator:_isInList(list, node)
    for _, v in ipairs(list) do
        if v.x == node.x and v.y == node.y then
            return true
        end
    end
    return false
end

-- FIND FARTHEST POINT FROM X AND Y FOLLOWING PATHS
function MazeGenerator:_findFarthestPoint(startX, startY)
    local distances = {}
    for y = 1, mazeHeight do
        distances[y] = {}
        for x = 1, mazeWidth do
            distances[y][x] = -1
        end
    end

    local queue = {{x = startX, y = startY}}
    distances[startY][startX] = 0
    local farthestPoint = {x = startX, y = startY}
    local maxDistance = 0

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local currentDist = distances[current.y][current.x]

        for _, direction in ipairs(directions) do
            local newX = current.x + direction.x
            local newY = current.y + direction.y

            if newX > 0 and newX <= mazeWidth and newY > 0 and newY <= mazeHeight and self.grid[newY][newX] ~= CellType.Wall and distances[newY][newX] == -1 then
                distances[newY][newX] = currentDist + 1
                table.insert(queue, {x = newX, y = newY})

                if distances[newY][newX] > maxDistance then
                    maxDistance = distances[newY][newX]
                    farthestPoint = {x = newX, y = newY}
                end
            end
        end
    end

    return farthestPoint
end

-- STOP SOLVING
function MazeGenerator:StopSolving()
    game.Workspace.Baseplate:SetAttribute("isSolving", false)
end

-- START SOLVING
function MazeGenerator:Solve()
    local path = self:_aStar({x = self.startPointX, y = self.startPointY}, {x = self.farthestPointX, y = self.farthestPointY})

    game.Workspace.Baseplate:SetAttribute("isSolving", true)

    if path then
        for _, node in ipairs(path) do
            self.grid[node.y][node.x] = CellType.Trail
            local part = self:_parseGridPositionIntoPart(self.cellSize, node.y, node.x, 0.5, BrickColor.new("Lime green"))
            part.Parent = game.Workspace.Baseplate
            wait(0.02) -- Delay to visualize the path-building process
            if not game.Workspace.Baseplate:GetAttribute("isSolving") then
                break
            end
        end
    else
        print("No path found")
    end
end

-- PLACING THE WHOLE MAZE INTO WORKSPACE
function MazeGenerator:PlaceMazeInWorkspace(cellSize, yToPlaceSpawn, centerX, centerY, includeStartAndEnd)
    if cellSize <= 0 then
        return
    end

    self.cellSize = cellSize

    if includeStartAndEnd then
        local farthestPoint = self:_findFarthestPoint(self.startPointX, self.startPointY)
        self.grid[self.startPointY][self.startPointX] = CellType.Start
        self.grid[farthestPoint.y][farthestPoint.x] = CellType.End
        self.farthestPointX = farthestPoint.x
        self.farthestPointY = farthestPoint.y
    end

    -- TODO: IMPLEMENT CENTERX, CENTERY

    local parent = game.Workspace.Baseplate

    for y = 1, mazeHeight do
        for x = 1, mazeWidth do
            if self.grid[y][x] == CellType.Path then
                continue
            end
            
            -- CHANGING COLOR BASED ON TYPE
            local part: Part
            if self.grid[y][x] == CellType.Wall then
                part = self:_parseGridPositionIntoPart(cellSize, y, x, yToPlaceSpawn, BrickColor.new("Mid gray"))
            elseif self.grid[y][x] == CellType.Start then
                part = self:_parseGridPositionIntoPart(cellSize, y, x, yToPlaceSpawn, BrickColor.new("Lime green"))
            elseif self.grid[y][x] == CellType.End then
                part = self:_parseGridPositionIntoPart(cellSize, y, x, yToPlaceSpawn, BrickColor.new("Light purple"))
            end
            if self.grid[y][x] == CellType.Start or self.grid[y][x] == CellType.End then
                part.Size = Vector3.new(part.Size.X, 0.1, part.Size.Z)
            end
            part.Parent = parent

        end
    end
end

function MazeGenerator:Debug()
    for y = 1, mazeHeight do
        local line = ""
        for x = 1, mazeWidth do
            if self.grid[y][x] == CellType.Wall then
                line = line .. "#"
            else
                line = line .. " "
            end
        end
        print(line)
    end
end

-- Shuffle a Table
function MazeGenerator:_shuffle(t)
    local shuffled = {}
    for i = #t, 1, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
        table.insert(shuffled, t[i])
    end
    return shuffled
end

return MazeGenerator