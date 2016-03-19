class("Spectator")

function Spectator:__init()
	self.spectators = {}
	self.timer = Timer()

	Network:Subscribe("SpectateRequest", self, self.SpectateRequest)
	Events:Subscribe("PostTick", self, self.SendPositions)
	Events:Subscribe("StopStuntSession", self, self.StopSpectator)
end

function Spectator:SpectateRequest(args, client)
	print("ok")
	--if args.playerID == nil then return end
	if args.stop then
		for i, v in ipairs(self.spectators) do
			print(client:GetName() .. " " .. v.spectator:GetName())
			if client == v.spectator then
				self:StopSpectator({["player"] = v.spectated})
				print("found and stopped")
				return
			end
		end
	else
		local player = nil
		print(client:GetName() .. " request")
		-- Find player
		for v in Server:GetPlayers() do
			if v:GetId() == args.playerID then
				player = v
				break
			end
		end
		if player == nil or not player:InVehicle() then return end
		print(client:GetName() .. " request for " .. player:GetName())
		table.insert(self.spectators, {["spectator"] = client, ["spectated"] = player})
		Network:Send(player, "Spectated", {["player"] = client, ["stop"] = false})
	end
end

function Spectator:SendPositions(args)
	if self.timer:GetSeconds() > 0.2 then
		self.timer:Restart()
		for i, v in ipairs(self.spectators) do
			if self.spectators[i] ~= nil and v.spectated:InVehicle() then -- make sure spectated is still spectatable
			Network:Send(v.spectator, "Spectate", {["pos"] = v.spectated:GetPosition(), ["yaw"] = v.spectated:GetVehicle():GetAngle().yaw,
				["direction"] =  v.spectated:GetVehicle():GetLinearVelocity()})
			else
				self.spectators[i] = nil
				-- Send stop message to spectator
				Network:Send(v.spectator, "Spectate", {["stop"] = true})
				Network:Send(v.spectated, "Spectated", {["player"] = v.spectator, ["stop"] = true})
			end
		end
	end
end

function Spectator:StopSpectator(args)
	--print("stopsession fired")
	for i, v in ipairs(self.spectators) do
		if v ~= nil and v.spectated == args.player then
			print("spectator founded")
			-- Send stop message to spectator
			Network:Send(v.spectator, "Spectate", {["stop"] = true})
			Network:Send(v.spectated, "Spectated", {["player"] = v.spectator, ["stop"] = true})
			self.spectators[i] = nil
			break
		end
	end
end

spectator = Spectator()