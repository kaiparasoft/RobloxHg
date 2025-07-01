local Players = game:GetService("Players")
local mercuryBlob = workspace:WaitForChild("MercuryCharacter")

Players.PlayerAdded:Connect(function(player)
	-- Wait for the client to load before assigning
	task.wait(0.1)

	for _, part in ipairs(mercuryBlob:GetDescendants()) do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(player)
		end
	end
end)
