
class("StuntManager")


function StuntManager:__init()
	self.activePlayers = {}
	self.db = {}
	self.timer = Timer()
	self.updateCount = 0
	self.maxQuery = 20 -- Maximum query updates allowed for each update
	-- Keep leaderboard in memory (TODO)
	--self.leaderBoard = self:UpdateLeaderBoard()

	self:GenerateLeaderBoard({["id"] = 1, ["name"] = "test", ["score"] = 5})

	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe("PlayerEnterVehicle", self, self.SetVehicle)
	--Events:Subscribe("PostTick", self, self.Save)
	Events:Subscribe("ModuleUnload", self, self.ForceSave)
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    --Events:Subscribe("ModulesLoad", self, self.ModuleLoad)

	Network:Subscribe("StuntScoreUpdate", self, self.UpdateScore)
	Network:Subscribe("StopSession", self, self.StopSession)

	Network:Subscribe("RequestLiveScores", self, self.SendLiveScores)
	Network:Subscribe("LiveScoreDetails", self, self.SendLiveScoreDetails)
	Network:Subscribe("StuntsStats", self, self.SendStats)
	Network:Subscribe("StuntsLeaderBoard", self, self.SendLeaderBoard)
	--Events:Subscribe("PostTick", function() if self.activePlayers["76561198050603285"] then print(self.activePlayers["76561198050603285"].session == nil) end end)

	--SQL:Execute("create table if not exists stunt_players (steamid VARCHAR UNIQUE, global_score REAL)")
	--SQL:Execute("create table if not exists stunt_scores (steamid VARCHAR UNIQUE, vehicle_id INTEGER, stunt_id INTEGER, score REAL)")

	local fileName = "feedback.txt"
	local file = io.open(fileName, "r")
	if file == nil then
		file = io.open(fileName, "w")
	end
	local feedbackFunc = function(text)
		local file = io.open(fileName, "a")
		file:write(text .. "\n")
		file:close()
	end
	file:close()
	Network:Subscribe("FeedBack", function(args, client)
			feedbackFunc(client:GetName() .. ": " .. args.feedback)
		end)
	Events:Subscribe("PlayerChat", function(args)
			local msg = args.text
			if msg:sub(1,1) ~= "/" then return true end
			msg = msg:sub(2):split(" ")
			if msg[1] == "feedback" then
				table.remove(msg, 1)
				feedbackFunc(args.player:GetName() .. ": " .. table.concat(msg))
				args.player:SendChatMessage("[Stunts] Thanks for your feedback " .. args.player:GetName() .. "!", Color(92,184,50))
				return false
			end
			return true
		end)

end

-- Receive new scores from client
function StuntManager:UpdateScore(args, client)
	if self.activePlayers[client:GetSteamId().id] == nil then return end
	local stuntPlayer = self.activePlayers[client:GetSteamId().id]

	if args.score then
		-- Update score
		if stuntPlayer.session == nil then
			-- Create new session
			stuntPlayer.session = {}
			-- Stored vehicle id, otherwise nil if stunt fails
			if client:InVehicle() then
				--print("yes in vehicle " .. tostring(client:GetVehicle():GetModelId()) .. " backup was " .. tostring(stuntPlayer.vehicleID))
				stuntPlayer.session.vehicleID = client:GetVehicle():GetModelId()
			else
				--print("not in vehicle, use " .. tostring(stuntPlayer.vehicleID))
				stuntPlayer.session.vehicleID = stuntPlayer.vehicleID
			end
			stuntPlayer.session.scores = {}
			stuntPlayer.session.total = 0
		end

		local addScore = args.score * (1 + args.bonus)
		-- Add to stunt score
		if stuntPlayer.session.scores[args.stuntName] == nil then
			stuntPlayer.session.scores[args.stuntName] = 0
		end
		stuntPlayer.session.scores[args.stuntName] = stuntPlayer.session.scores[args.stuntName] + addScore
		-- Add to total score
		stuntPlayer.session.total = stuntPlayer.session.total + addScore
		stuntPlayer.lastStunt = args.stuntName
		--monitor:AddScore(string.format("%s %s %d %f %f (%s)",
		--				args.stuntName,
		--				args.vehType,
		--				stuntPlayer.session.vehicleID,
		--				args.score,
		--				addScore,
		--				Vehicle.GetNameByModelId(stuntPlayer.session.vehicleID)))
	end
	-- Saving session scores to db is not really necassery..
	--if stuntPlayer.updated = nil then
	--	stuntPlayer.updated = true
	--	self.updateCount = self.updateCount + 1
	--end
end

-- Save session score to global score
function StuntManager:StopSession(args, client)
	--Chat:Broadcast("RECEIVED", Color(255,255,255))
	local stuntPlayer = self.activePlayers[client:GetSteamId().id]
	if stuntPlayer == nil or stuntPlayer.session == nil then return end
	--Chat:Broadcast("EXISTS", Color(255,255,255))
	if stuntPlayer.session.scores == nil then return end
	--Chat:Broadcast("SCORE ELEMENT", Color(255,255,255))
	if stuntPlayer.session.total == nil then return end
	--Chat:Broadcast("SCORE", Color(255,255,255))

	if stuntPlayer.global == nil then
		-- Create new global result
		stuntPlayer.global = {}
		stuntPlayer.global.total = 0
		stuntPlayer.global.scores = {}
	end
	--Chat:Broadcast("STOPPED", Color(255,255,255))
	-- Update global score
	stuntPlayer.global.total = stuntPlayer.global.total + stuntPlayer.session.total

	local leaderPos = nil
	if (self.leaderBoard == nil or self.leaderBoardMin == nil
		or #self.leaderBoard < 10)
		or stuntPlayer.session.total > self.leaderBoardMin then
		leaderPos = self:GenerateLeaderBoard({["id"] = stuntPlayer.player:GetSteamId().id,
								  ["name"] = stuntPlayer.player:GetName(),
								  ["score"] = stuntPlayer.session.total})

	end

	local newRecordText = ""
	local msg = nil
	local vehicleID = stuntPlayer.session.vehicleID
	if vehicleID == nil then
		print("VEHICLE NOT SET")
	end
	-- Update globalscore for this particular vehicle
	if stuntPlayer.global.scores[vehicleID] == nil then
		-- First session on this vehicle
		stuntPlayer.global.scores[vehicleID] = {}
	end
	--local sessionTotal = 0
	for stuntName, stuntScore in pairs(stuntPlayer.session.scores) do
		if stuntPlayer.global.scores[vehicleID][stuntName] == nil then
			stuntPlayer.global.scores[vehicleID][stuntName] = 0
		end
		stuntPlayer.global.scores[vehicleID][stuntName] = stuntPlayer.global.scores[vehicleID][stuntName] + stuntScore
	--	sessionTotal = sessionTotal + stuntScore
	--	print(stuntName .. " -> " .. tostring(stuntScore))
	end
	--stuntPlayer.global[vehicleID][stuntName] = stuntPlayer.global[vehicleID][stuntName] + stuntPlayer.session.scores.total
	if stuntPlayer.records == nil then
		stuntPlayer.records = {}
	end
	if stuntPlayer.records[vehicleID] == nil then
		stuntPlayer.records[vehicleID] = stuntPlayer.session.total
		newRecordText = " * first score on vehicle *"
	else
		if stuntPlayer.session.total > stuntPlayer.records[vehicleID] then
			newRecordText = " * new record *"
			stuntPlayer.records[vehicleID] = stuntPlayer.session.total
			msg = {"wow such new record!", "new record, very done.."}
		end
	end
	-- + extra session bonuses

	-- Notice saver that this should be saved in db
	if stuntPlayer.updated == nil then
		stuntPlayer.updated = true
		self.updateCount = self.updateCount + 1
	end
	local lastStunt = ""
	if args.lastStunt then
		lastStunt = self:GetSentence(args.lastStunt)
	end

	if leaderPos ~= nil then
		local text = "achieved"
		if not leaderPos.rankUp then
			text = "sustained"
		end

		Chat:Broadcast(string.format("[Stunts] %s %s #%d on the leaderboard with %.2f points!",
									client:GetName(), text, leaderPos.pos, stuntPlayer.session.total),
						Color(150,200,100))
	else
		Chat:Broadcast(string.format("[Stunts] %s%s scored %.2f points in %s!%s",
								client:GetName(), lastStunt, stuntPlayer.session.total,
								Vehicle.GetNameByModelId(vehicleID), newRecordText),
					Color(92,184,50))
	end

	if msg == nil then
		for k, v in pairs(config.messages) do
			if k < stuntPlayer.session.total then
				msg = v
			end
		end
	end
	if msg == nil then
		msg = {"wow", "amazing","dat score"}
	end
	Network:Send(client, "SessionResult", {["text"] = string.format("%.2f", stuntPlayer.session.total), ["subText"] = table.randomvalue(msg), ["offset"] = 0})
	--client:SetMoney(client:GetMoney() + math.floor(sessionTotal))
	stuntPlayer.prevSession = stuntPlayer.session
	stuntPlayer.session = nil
	--stuntPlayer.vehicleID = nil
	stuntPlayer.lastStunt = nil
	--print("session stopped")
	Events:Fire("StopStuntSession", {["player"] = client})
end

function StuntManager:GetSentence(stuntName)
	if stuntName == "lowflyer" then
		return " flew a bit TOO low and"
	elseif stuntName == "air" then
		return " couldn't handle all the airtime and"
	elseif stuntName == "swimming" then
		return table.randomvalue({" noticed that cars don't swim and", " failed at swimming and"})
	elseif stuntName == "diving" then
		return " thought that every boat is a submarine and"
	else
		return ""
	end
end

-- Add player to active players
function StuntManager:PlayerJoin(args)
	local playerID = args.player:GetSteamId().id
	if self.activePlayers[playerID] and self.activePlayers[playerID].quit then
		-- Player was recently active but last score update was not committed yet to db
		-- Request saver not to delete this entry
		self.activePlayers[playerID].quit = nil
	else
		-- Load global scores
		if self.db[playerID] != nil then
			self.activePlayers[playerID] = self.db[playerID]
		else
			self.activePlayers[playerID] = {}
			self.activePlayers[playerID].global = {}
			self.activePlayers[playerID].global.total = 0
			self.activePlayers[playerID].global.scores = {}
		end
		-- TODO Some queries here
	end
	if args.player:InVehicle() then
		-- Make sure vehicle is set even when module reloads
		--print("set vehicle while reloading")
		self.activePlayers[playerID].vehicleID = args.player:GetVehicle():GetModelId()
	end
	self.activePlayers[playerID].player = args.player
	self.activePlayers[playerID].name = args.player:GetName()
	--print("Added " .. args.player:GetName() .. " to activeplayers")
end

-- Remove player from active players
function StuntManager:PlayerQuit(args)
	if self.activePlayers[args.player:GetSteamId().id] ~= nil then
		self.activePlayers[args.player:GetSteamId().id].quit = true
		--print(args.player:GetName() .. " marked as to be removed from activeplayers")
		-- remove
		-- self.activePlayers[args.player:GetSteamId().id].records = nil
		-- self.activePlayers[args.player:GetSteamId().id].scores = nil
		-- self.activePlayers[args.player:GetSteamId().id] = nil
		self.db[args.player:GetSteamId().id] = Copy(self.activePlayers[args.player:GetSteamId().id])
		self.activePlayers[args.player:GetSteamId().id] = nil
	end
end

function StuntManager:SetVehicle(args)
	if self.activePlayers[args.player:GetSteamId().id] ~= nil then
		--print("set vehicle " .. tostring(args.player:GetVehicle():GetModelId()))
		self.activePlayers[args.player:GetSteamId().id].vehicleID = args.player:GetVehicle():GetModelId()
		--print(tostring(self.activePlayers[args.player:GetSteamId().id].vehicleID))
		--print("vehicle set to " .. Vehicle.GetNameByModelId(args.player:GetVehicle():GetModelId()))
	end
end
-- Save scores to db
function StuntManager:Save(args)
	if self.timer:GetSeconds() > 30 or self.updateCount > 20 or args.force then
		self.timer:Restart()
		local updated = 0
		for k, v in self.activePlayers do
			if v.updated then
				-- SQL COMMIT
				updated = updated + 1
			end
			if updated >= self.maxQuery and not args.force then
				-- Max allowed db commits reached
				break
			end
			if v.delete ~= nil then
				-- Delete from memory
				self.activePlayers[k] = nil
			end
		end
		print(string.format("%d score commits", updated))
	end
end

-- Force to save all player entries to db
function StuntManager:ForceSave(args)
	--local args = {["force"] = true}
	--self.Save(args)
	for k, stuntPlayer in pairs(self.activePlayers) do
		if stuntPlayer.delete == nil and stuntPlayer.session ~= nil then
			self:StopSession({}, stuntPlayer.player)
		end
	end
end

function StuntManager:ModuleLoad(args)
	for player in Server:GetPlayers() do
		self:PlayerJoin({["player"] = player})
	end
end

-- Live Scores

function StuntManager:SendLiveScores(args, client)
	--print("request for livescores")
	local args = {
		{
			["playerID"] = 1,
			["playerName"] = "Bramble",
			["vehicle"] = "Car: Racer Car",
			["score"] = "512.12",
			["vehicleHealth"] = "96%",
			["lastStunt"] = "",
			["distance"] = "45m",
			["location"] = "Snowy Mountains"
		},
		{
			["playerID"] = 2,
			["playerName"] = "Bramble2",
			["vehicle"] = "Car: Racer Car2",
			["score"] = "510.12",
			["vehicleHealth"] = "90%",
			["lastStunt"] = "",
			["distance"] = "50m",
			["location"] = "Desert"
		},
		{
			["playerID"] = 3,
			["playerName"] = "Bramble3",
			["vehicle"] = "Plane: Silverbolt",
			["score"] = "510.12",
			["vehicleHealth"] = "100%",
			["lastStunt"] = "",
			["distance"] = "150m",
			["location"] = "Desert"
		},
		{
			["playerID"] = 4,
			["playerName"] = "Bramble4",
			["vehicle"] = "Heli: Superheli",
			["score"] = string.format("%.2f",(math.random()*100)),
			["vehicleHealth"] = "90%",
			["lastStunt"] = "",
			["distance"] = "18m",
			["location"] = "Desert"
		},
		{
			["playerID"] = 5,
			["playerName"] = "Bramble5",
			["vehicle"] = "Bike: Racebike",
			["score"] = string.format("%.2f",(math.random()*100)),
			["vehicleHealth"] = "90%",
			["lastStunt"] = "",
			["distance"] = "50m",
			["location"] = "Desert"
		}
	}
	args = {}
	for id, stuntPlayer in pairs(self.activePlayers) do
		--print(tostring(stuntPlayer.vehicle))
		if stuntPlayer.player ~= nil
			and stuntPlayer.player:InVehicle()
			and stuntPlayer.quit == nil then
			local score = 0
			if stuntPlayer.session then
				score = stuntPlayer.session.total
			end
			local lastStunt = "none"
			if stuntPlayer.lastStunt then
				lastStunt = stuntPlayer.lastStunt
			end
			local distance = Vector3.Distance(client:GetPosition(), stuntPlayer.player:GetPosition())
			--print(distance)
			table.insert(args, {
					["playerID"] = stuntPlayer.player:GetId(),
					["playerName"] = stuntPlayer.player:GetName(),
					["vehicle"] = Vehicle.GetNameByModelId(stuntPlayer.player:GetVehicle():GetModelId()),
					["score"] = string.format("%.2f", score),
					["vehicleHealth"] = string.format("%.2f%%", stuntPlayer.player:GetVehicle():GetHealth()*100),
					["lastStunt"] = lastStunt,
					["distance"] = string.format("%.0f", distance) .. "m",
					["location"] = Locations.getLocation(stuntPlayer.player:GetPosition())
				})
		end
	end
	Network:Send(client, "LiveScoresResponse", args)
	--print("received")
end
function StuntManager:SendLiveScoreDetails(args, client)
	print("received detail request")
	local player = nil
	for v in Server:GetPlayers() do
			if v:GetId() == args.playerID then
				player = v
				break
			end
	end
	if player == nil then print("player not found") return end
	Network:Send(client, "LiveScoreDetails", {["player"] = player})
	print("send details")
end

function StuntManager:SendStats(args, client)
	--print(client:GetName())
	local stuntPlayer = self.activePlayers[client:GetSteamId().id]
	local args = {}
	args.prevSession = stuntPlayer.prevSession
	args.records = stuntPlayer.records
	args.global = stuntPlayer.global
	Network:Send(client, "StuntsStats", args)
end

function StuntManager:SendLeaderBoard(args, client)

	local args = {}
	if self.leaderBoard == nil then
		self.leaderBoard = {}
	end

	args.scores = self.leaderBoard

	Network:Send(client, "StuntsLeaderBoard", args)
end

function StuntManager:GenerateLeaderBoard(args)
	local pos = nil
	local rankUp = true
	if self.leaderBoard == nil then
		self.leaderBoard = {args}
		pos = 1
	else
		local rem = nil
		for i = 1, #self.leaderBoard do
			if pos == nil and args.score > self.leaderBoard[i].score then
				pos = i
			end
			if args.id == self.leaderBoard[i].id then
				if args.score > self.leaderBoard[i].score then
					if pos == i then
						rankUp = false
					end
					rem = i
				else
					return nil
				end
			end
		end
		if pos == nil then
			pos = #self.leaderBoard + 1
		end
		if rem == nil then
			table.insert(self.leaderBoard, pos, args)
			if #self.leaderBoard > 10 then
				table.remove(self.leaderBoard, 11)
			end
		else
			table.remove(self.leaderBoard, rem)
			table.insert(self.leaderBoard, pos, args)
		end
	end

	self.leaderBoardMin = self.leaderBoard[#self.leaderBoard].score
	return {["pos"] = pos, ["rankUp"] = rankUp}

	-- table.sort(self.activePlayers, function(a, b)
	-- 		return a.global.total > b.global.total
	-- 	end)
	-- self.leaderBoard = {}
	-- local count = 0
	-- for k, v in pairs(self.activePlayers) do
	-- 	table.insert(self.leaderBoard, {["name"] = v.name, ["score"] = v.global.total})
	-- 	self.leaderBoardMin = v.global.total
	-- 	count = count + 1
	-- 	if count > 10 then
	-- 		break
	-- 	end
	-- end
end

stuntManager = StuntManager()

-- Powerups
-- spin, drift
function DoBalance(args, client)
	RotateVehicle(client:GetVehicle(), "x", args.pitch)
	--print("set pitch to " .. angle.pitch)
end

function DriftBoost(args, client)
	RotateVehicle(client:GetVehicle(), "y", args.amount)
	Chat:Broadcast("enabled " .. tostring(args.amount), Color(255,255,255))
end

function RotateVehicle(vehicle, axis, rad)
	local angVel = -vehicle:GetAngle() * vehicle:GetAngularVelocity()
	angVel[axis] = angVel[axis] + rad
	angVel = vehicle:GetAngle() * angVel
	vehicle:SetAngularVelocity(angVel)
end

--Network:Subscribe("Balance", DoBalance)
Network:Subscribe("BoostDrift", DriftBoost)


function Autonomous(args, client)
	local add = nil
	local veh = client:GetVehicle()
	local angle = veh:GetAngle()
	if args.sight > 100 then
		add = angle * Vector3(0,0,-1)
	else
		add = angle * Vector3(0,0,1)
	end

	veh:SetLinearVelocity(client:GetLinearVelocity() + add)
end
Network:Subscribe("Autonomous", Autonomous)

--local timer = Timer()
local rnd = {"aapje","krekel","ezel","Bramble"}

function ScoreBoardTest(args)
	if timer:GetSeconds() > 2 then
		--print("yes")
		timer:Restart()
		local scoreBoard = {}
		for i = 1,10 do
			table.insert(scoreBoard, table.randomvalue(rnd))
		end
		Network:Broadcast("ScoreBoard", scoreBoard)
	end
end

--Events:Subscribe("PostTick", ScoreBoardTest)


