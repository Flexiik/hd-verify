local gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")

local regenerate: TextButton = gui:WaitForChild("Regenerate")
local solve: TextButton = gui:WaitForChild("Solve")
local sizeX: TextBox = gui:WaitForChild("SizeChanger"):WaitForChild("SizeX")
local sizeY: TextBox = gui:WaitForChild("SizeChanger"):WaitForChild("SizeY")

local remoteEventRegen: RemoteEvent = game:GetService("ReplicatedStorage").Remotes.PlaceMazeOnServer
local remoteEventSolve: RemoteEvent = game:GetService("ReplicatedStorage").Remotes.SolveMazeEvent

regenerate.MouseButton1Click:Connect(function()
    print(remoteEventRegen.Name)
    print(sizeX.Text, sizeY.Text)
    remoteEventRegen:FireServer(sizeX.Text, sizeY.Text)
end)

remoteEventRegen.OnClientEvent:Connect(function()
    solve.Text = "Solve Maze (A*)"
end)

solve.MouseButton1Click:Connect(function()
    print(remoteEventSolve.Name)
    if solve.Text ~= "Stop Solving" then
        remoteEventSolve:FireServer("Start")
        solve.Text = "Stop Solving"
    else
        remoteEventSolve:FireServer("Stop")
        solve.Text = "Solve Maze (A*)"
    end
    
end)

