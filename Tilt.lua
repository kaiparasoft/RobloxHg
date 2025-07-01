local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraYawModule = require(ReplicatedStorage:WaitForChild("CameraYawModule"))

local platformModel = workspace:WaitForChild("MercuryLevel")

while not platformModel.PrimaryPart do
	local base = platformModel:FindFirstChild("Base")
	if base then
		platformModel.PrimaryPart = base
	else
		platformModel:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end
end

local basePosition = platformModel.PrimaryPart.Position

-- Tilt control variables
local tiltX, tiltZ = 0, 0
local smoothTiltX, smoothTiltZ = 0, 0
local maxTilt = 20
local tiltSpeed = 1
local lerpSpeed = 0.15
local keysDown = {}

-- Handle input
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe then keysDown[input.KeyCode] = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if not gpe then keysDown[input.KeyCode] = false end
end)

-- Update tilt
RunService.RenderStepped:Connect(function()
	local yaw = math.rad(CameraYawModule.Yaw)
	local camForward = Vector3.new(math.sin(yaw), 0, math.cos(yaw)).Unit
	local camRight = Vector3.new(-camForward.Z, 0, camForward.X).Unit

	local inputDir = Vector3.zero
	if keysDown[Enum.KeyCode.W] then inputDir += Vector3.new(0, 0, 1) end
	if keysDown[Enum.KeyCode.S] then inputDir += Vector3.new(0, 0, -1) end
	if keysDown[Enum.KeyCode.A] then inputDir += Vector3.new(-1, 0, 0) end
	if keysDown[Enum.KeyCode.D] then inputDir += Vector3.new(1, 0, 0) end

	if inputDir.Magnitude > 0 then
		inputDir = inputDir.Unit
		local worldInput = (camForward * inputDir.Z + camRight * inputDir.X)

		tiltX += -worldInput.Z * tiltSpeed -- forward/backward tilt
		tiltZ += worldInput.X * tiltSpeed  -- left/right tilt
	else
		-- decay tilt over time
		tiltX *= 0.9
		tiltZ *= 0.9
	end

	-- Clamp and smooth tilt
	tiltX = math.clamp(tiltX, -maxTilt, maxTilt)
	tiltZ = math.clamp(tiltZ, -maxTilt, maxTilt)
	smoothTiltX += (tiltX - smoothTiltX) * lerpSpeed
	smoothTiltZ += (tiltZ - smoothTiltZ) * lerpSpeed

	local rotation = CFrame.Angles(math.rad(smoothTiltX), 0, math.rad(smoothTiltZ))
	platformModel:SetPrimaryPartCFrame(CFrame.new(basePosition) * rotation)
end)
