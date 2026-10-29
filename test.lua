local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ShootRemote = game:GetService("ReplicatedStorage"):WaitForChild("ShootRemote")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local RANGE = 500
local enabled = true

-- gui
local gui = Instance.new("ScreenGui")
gui.Name = "TestToggle"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(160, 40)
button.Position = UDim2.new(0, 20, 0, 20)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui

local function refresh()
	button.Text = enabled and "Shooting: ON" or "Shooting: OFF"
	button.BackgroundColor3 = enabled and Color3.fromRGB(40, 160, 70) or Color3.fromRGB(160, 40, 40)
end
refresh()

local function toggle()
	enabled = not enabled
	refresh()
end

button.MouseButton1Click:Connect(toggle)

-- visuals: tracer line from the gun to the hit point
local function drawTracer(from, to)
	local dist = (to - from).Magnitude
	if dist < 0.1 then return end

	local tracer = Instance.new("Part")
	tracer.Name = "Tracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 230, 120)
	tracer.Size = Vector3.new(0.08, 0.08, dist)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
	tracer.Parent = Workspace

	TweenService:Create(tracer, TweenInfo.new(0.15), { Transparency = 1 }):Play()
	game:GetService("Debris"):AddItem(tracer, 0.2)
end

-- visuals: red flash on whatever model got hit
local function flashHit(part)
	if not part then return end
	local model = part:FindFirstAncestorOfClass("Model")
	if not model or not model:FindFirstChildOfClass("Humanoid") then return end

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 60, 60)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.3
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = model
	hl.Parent = model

	TweenService:Create(hl, TweenInfo.new(0.4), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	game:GetService("Debris"):AddItem(hl, 0.4)
end

local function fire()
	if not enabled then return end
	local char = player.Character
	if not char then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local origin = camera.CFrame.Position
	local dir = camera.CFrame.LookVector * RANGE
	local result = Workspace:Raycast(origin, dir, params)

	local endPos = result and result.Position or (origin + dir)
	drawTracer(origin, endPos)
	if result then flashHit(result.Instance) end

	ShootRemote:FireServer(origin, dir, result and result.Position)
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then
		toggle()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		fire()
	end
end)
