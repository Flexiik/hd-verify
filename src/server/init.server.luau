local placeEvent: RemoteEvent = game:GetService("ReplicatedStorage").Remotes.PlaceMazeOnServer
local solveMazeEvent: RemoteEvent = game:GetService("ReplicatedStorage").Remotes.SolveMazeEvent

local mazegen = require(game:GetService("ReplicatedStorage").Modules.MazeGenerator)

local maze1 = mazegen.new(21, 21)
maze1:Generate(2, 2)
maze1:PlaceMazeInWorkspace(1, 0.5, 0, 0, true)


placeEvent.OnServerEvent:Connect(function(player: Player, sizeX: number?, sizeY: number?)
    if not (type(tonumber(sizeX)) == "number") or not (type(tonumber(sizeY)) == "number") then
        return
    end
    if game.Workspace.Baseplate:GetAttribute("isSolving") then
        maze1:StopSolving()
    end
    maze1:DestroyCurrentMazeFromWorkspace()
    wait(0.01)
    maze1 = mazegen.new(tonumber(sizeX), tonumber(sizeY))
    maze1:Generate(2, 2)
    -- maze:Debug()
    maze1:PlaceMazeInWorkspace(1, 0.5, 0, 0, true)
    placeEvent:FireClient(player)
end)

solveMazeEvent.OnServerEvent:Connect(function(player: Player, toDo: string)
   if toDo == "Start" then
        maze1:Solve()
   else
        maze1:StopSolving()
   end
end)
