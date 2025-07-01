local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraYawModule = require(ReplicatedStorage:WaitForChild("CameraYawModule"))

local core = workspace:WaitForChild("MercuryCharacter"):WaitForChild("Core")
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable

-- Camera settings
local distance = 20
local minDistance = 5
local maxDistance = 50
local zoomSpeed = 2
local height = 10
local smoothSpeed = 0.13

-- Camera rotation variables
local yaw = 0
local pitch = 15
local minPitch = -20
local maxPitch = 60
local rotationSpeed = 0.3

local rotating = false

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotating = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotating = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function(input, gpe)
	if gpe then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement and rotating then
		yaw = yaw - input.Delta.x * rotationSpeed
		pitch = math.clamp(pitch + input.Delta.y * rotationSpeed, minPitch, maxPitch)
	end

	-- Zoom with scroll wheel
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		distance = math.clamp(distance - input.Position.Z * zoomSpeed, minDistance, maxDistance)
	end
end)

RunService.RenderStepped:Connect(function()
	if core and core:IsDescendantOf(workspace) then
		CameraYawModule.Yaw = yaw

		local corePos = core.Position

		local radYaw = math.rad(yaw)
		local radPitch = math.rad(pitch)

		local offset = Vector3.new(
			math.cos(radPitch) * math.sin(radYaw),
			math.sin(radPitch),
			math.cos(radPitch) * math.cos(radYaw)
		) * distance

		local targetPos = corePos + offset + Vector3.new(0, height, 0)
		local currentPos = camera.CFrame.Position
		local newPos = currentPos:Lerp(targetPos, smoothSpeed)

		camera.CFrame = CFrame.new(newPos, corePos + Vector3.new(0, height / 2, 0))
	end
end)
