-- Gradient-Based Platform Tilting with Consistent Feel
-- Place this in StarterPlayer > StarterPlayerScripts

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraYawModule = require(ReplicatedStorage:WaitForChild("CameraYawModule"))

-- Configuration
local MAX_TILT_ANGLE = 15 -- Maximum tilt in degrees
local TILT_SMOOTHING = 0.1 -- How quickly platform tilts (lower = smoother)

-- Input tracking
local inputVector = Vector3.new(0, 0, 0)
local currentTilt = Vector3.new(0, 0, 0) -- Current tilt angles (smoothed)

-- References (will be found dynamically)
local blobCore = nil
local platform = nil
local platformBaseCFrame = nil -- Store original platform position/rotation

-- Find the blob core in the workspace
local function findBlobCore()
	local mercuryCharacter = Workspace:WaitForChild("MercuryCharacter")
	local core = mercuryCharacter:WaitForChild("Core") -- Fixed capitalization
	return core
end

-- Find the platform/level to tilt
local function findPlatform()
	local mercuryLevel = Workspace:WaitForChild("MercuryLevel")

	-- Ensure it has a PrimaryPart set
	if not mercuryLevel.PrimaryPart then
		local basePart = mercuryLevel:FindFirstChild("Base") or mercuryLevel:FindFirstChildOfClass("BasePart")
		if basePart then
			mercuryLevel.PrimaryPart = basePart
		else
			warn("MercuryLevel model has no PrimaryPart and no 'Base' part found!")
		end
	end

	return mercuryLevel
end

-- Initialize references
local function initializeReferences()
	blobCore = findBlobCore()
	platform = findPlatform()

	if not blobCore or not platform then
		return false
	end

	-- Store the original platform CFrame
	if platform.PrimaryPart then
		platformBaseCFrame = platform.PrimaryPart.CFrame
	else
		warn("Platform has no PrimaryPart set!")
		return false
	end

	return true
end

-- Handle input
local function handleInput()
	local moveVector = Vector3.new(0, 0, 0)

	-- WASD input
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveVector = moveVector + Vector3.new(0, 0, 1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveVector = moveVector + Vector3.new(0, 0, -1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveVector = moveVector + Vector3.new(1, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveVector = moveVector + Vector3.new(-1, 0, 0)
	end

	-- Convert to camera-relative direction using your camera yaw
	local cameraYaw = CameraYawModule.Yaw
	local cameraLookVector = Vector3.new(
		math.sin(math.rad(cameraYaw)), 
		0, 
		math.cos(math.rad(cameraYaw))
	)
	local cameraRightVector = Vector3.new(
		math.cos(math.rad(cameraYaw)), 
		0, 
		-math.sin(math.rad(cameraYaw))
	)

	-- Calculate world-space input direction
	inputVector = (cameraRightVector * moveVector.X + cameraLookVector * moveVector.Z)

	-- Normalize if needed
	if inputVector.Magnitude > 1 then
		inputVector = inputVector.Unit
	end
end

-- Apply gradient-based tilting to platform
local function applyGradientTilt()
	if not platform or not blobCore or not platformBaseCFrame then return end

	-- Get blob position relative to platform center
	local blobPosition = blobCore.Position
	local platformCenter = platformBaseCFrame.Position
	local blobOffset = blobPosition - platformCenter

	-- Calculate tilt that would make the blob "roll" in input direction
	-- The key insight: tilt strength should be based on how the forces would affect the blob
	local targetTiltX = -inputVector.Z * math.rad(MAX_TILT_ANGLE) -- Forward/back input tilts around X
	local targetTiltZ = inputVector.X * math.rad(MAX_TILT_ANGLE)  -- Left/right input tilts around Z

	-- Smooth the tilt transition
	local targetTilt = Vector3.new(targetTiltX, 0, targetTiltZ)
	currentTilt = currentTilt:Lerp(targetTilt, TILT_SMOOTHING)

	-- Apply tilt around the blob's full position (X, Y, Z)
	-- This makes it feel consistent in all 3 dimensions!
	local tiltPivot = blobPosition

	-- Create rotation around the blob's XZ position
	local rotationCFrame = CFrame.new(tiltPivot) * CFrame.Angles(currentTilt.X, 0, currentTilt.Z)

	-- Calculate where the platform center should be after rotation
	local offsetFromPivot = platformCenter - tiltPivot
	local rotatedOffset = rotationCFrame:VectorToWorldSpace(offsetFromPivot)
	local newPlatformCenter = tiltPivot + rotatedOffset

	-- Apply the final transformation
	local finalCFrame = CFrame.new(newPlatformCenter) * CFrame.Angles(currentTilt.X, 0, currentTilt.Z)
	platform:SetPrimaryPartCFrame(finalCFrame)
end

-- Main game loop
RunService.Heartbeat:Connect(function()
	handleInput()
	applyGradientTilt()
end)

-- Initialize when script starts
local function initialize()
	local success = initializeReferences()
	if success then
		print("system should work")
		print("blob:", blobCore:GetFullName())
		print("level:", platform:GetFullName())
		if platform.PrimaryPart then
			print("primarypart:", platform.PrimaryPart.Name)
		end
	else
		warn("didnt work you probably changed the name or hirearchy of either the blob, the core, or the level. stupid")
	end
end

-- Start the system
initialize()

--[[
GRADIENT-BASED PLATFORM TILTING - Mercury Hg Style

This script solves the "inconsistent tilt feeling" problem by:
1. Always tilting around the blob's current XZ position, not the platform center
2. Using camera-relative input from your existing camera system
3. Smooth transitions to prevent jerky movement

CONTROLS:
- WASD: Tilt platform (relative to your camera direction)

KEY FEATURES:
- Platform tilts around blob position (gradient effect)
- Consistent control feel regardless of blob location
- Integrates with your existing Camera.lua script
- Works with MercuryCharacter.Core and MercuryLevel setup

TUNING PARAMETERS:
- MAX_TILT_ANGLE: Maximum platform tilt in degrees
- TILT_SMOOTHING: How quickly platform responds (lower = smoother)

This creates the Super Monkey Ball / Mercury Hg effect where tilting always feels natural!
--]]
