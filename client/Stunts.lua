-- Written by Bram Diericx

class("Stunts")

function Stunts:__init()
	self.info = "JC-MP Stunts alpha by Bradiex"
	self.visible = true

	self.timers = {}
	self.height = 0
	self.vehHeight = 0
	self.stuntTreshhold = 0.2
	self.powerUps = {["drift"] = false}
	self.SETTINGS = {["scoreRendering"] = 0} -- 0: subtile, 1: obvious
	self.streakQueue = {}
	self.sessionResult = nil
	self.spawnedInAir = false
	self.scoreBoard = nil

	self.render = self.DefaultRender -- Render score depending on camera settings

	--print('Reading stunts')
	self.stunts = {}
	for k, v in pairs(StuntFactory) do
		self.stunts[k] = {
			["text"] = v.text,
			["scoreText"] = "",
			["bonusText"] = "",
			["color"] = v.color
		}
		--print(k .. ' ' .. v.text)
	end

	self.scores = {}
	self.total = 0
	self.bonuses = {
					["high"] = {["text"] = "High in the air",
									["active"] = false,
									["mult"] = 1.1,
									["color"] = Color(150,150,200, 255)},
					["damage"] = {["text"] = "Wreckage driver",
									["active"] = false,
									["mult"] = 2,
									["color"] = Color(200,150,150, 255)},
					["reverse"] = {["text"] = "Reversing",
									["active"] = false,
									["mult"] = 1.05,
									["color"] = Color(200,245,184, 255)}
					}
	self.bonusCount = 0
	self.combos = {
		["backflip"] = {["text"] = "BACKFLIP",
					["count"] = 0,
					["coolDown"] = nil,
					["color"] = Color(200, 200, 0, 255)},
		["frontflip"] = {["text"] = "FRONTFLIP",
					["count"] = 0,
					["coolDown"] = nil,
					["color"] = Color(0,200,200, 255)},
		["spin"] = {["text"] = "SPIN",
					["count"] = 0,
					["coolDown"] = nil,
					["color"] = Color(200,200,200, 255)},
		["roll"] = {["text"] = "ROLL",
					["count"] = 0,
					["coolDown"] = nil,
					["color"] = Color(100,100,200, 255)},
		["lowupside"] = {["text"] = "LOW + UPSIDE DOWN",
					["count"] = 0,
					["coolDown"] = nil,
					["color"] = Color(0,0,200, 255)}
	}
	self.comboCount = 0
	for k, v in pairs(self.stunts) do
		--print(v)
		self.scores[k] = {}
		self.scores[k].total = 0
		self.scores[k].curr = 0
	end

	Events:Subscribe("PostTick", self, self.DetectStunts)
	Events:Subscribe("LocalPlayerEnterVehicle", self, self.StartStunts)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.StopStunts)
	Events:Subscribe("FreeCamChange", self, self.StopStunts)
	--Events:Subscribe("PlayerStateChange", self, self.StopStunts)
	Events:Subscribe("Render", self, self.ActiveRender)

	Events:Subscribe("LocalPlayerChat", self, self.TogglePowerUps)

	Events:Subscribe("ModuleLoad", self, self.ModulesLoad)
    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    Network:Subscribe("SessionResult", self, self.UpdateSessionResult)
    Network:Subscribe("ScoreBoard", self, self.UpdateScoreBoard)

    -- Camera changes
    Events:Subscribe("CameraChange", self, self.ChangeRender)
end


---------- STUNT DETECTION ----------

-- Set stuntdetector
function Stunts:SetDetectFunc(id)
	self.stuntDetector = nil
	if Tools.TableContains(Vehicles.Car(), id) then
		self.stuntDetector = StuntDetector.Car
		self.vehType = "car"
	elseif Tools.TableContains(Vehicles.Bike(), id) then
		self.stuntDetector = StuntDetector.Bike
		self.vehType = "bike"
	elseif Tools.TableContains(Vehicles.AirPlane(), id) then
		self.stuntDetector = StuntDetector.AirPlane
		self.vehType = "plane"
	elseif Tools.TableContains(Vehicles.Heli(), id) then
		self.stuntDetector = StuntDetector.Heli
		self.vehType = "heli"
	elseif Tools.TableContains(Vehicles.Boat(), id) then
		self.stuntDetector = StuntDetector.Boat
		self.vehType = "boat"
	elseif Tools.TableContains(Vehicles.Monstertruck(), id) then
		self.stuntDetector = StuntDetector.Monstertruck
		self.vehType = "monstertruck"
	elseif Tools.TableContains(Vehicles.Hovercraft(), id) then
		self.stuntDetector = StuntDetector.Hovercraft
		self.vehType = "hovercraft"
	end
	stuntDetector.rotations = {}
end

function Stunts:DetectStunts()
	if not LocalPlayer:InVehicle() then return end
	--if self.vehicle == nil then
	--	self.vehicle = LocalPlayer:GetVehicle():GetId()
	--	local height = StuntDetector.GetVehicleState().height
	--	if height > 2 then
	--		self.spawnedInAir = true
	--	else
	--		print("new vehicle but not high in air")
	--	end
	--elseif self.vehicle ~= LocalPlayer:GetVehicle():GetId() then
		-- or listen to playerentervehicle event
	--	Chat:Print("Detected new vehicle!",Color(0,0,200))
	--	self:StopStunts()
	--	Chat:Print("stopped all stunts.. " .. tostring(self.stunts.upside.time == nil) .. " " .. tostring(self.stunts.upside.blink == nil) .. " " .. self.scores.upside.curr, Color(255,255,255))
		--return
	--end
	if self.stuntDetector == nil then
		self:SetDetectFunc(LocalPlayer:GetVehicle():GetModelId())
		if self.stuntDetector == nil then
			Chat:Print("should not happen "..tostring(LocalPlayer:GetVehicle():GetModelId()), Color(255,0,0))
			return
		end
	end
	self:stuntDetector()
	stuntDetector:DetectRotations()

	if LocalPlayer:GetVehicle():GetHealth() == 0 then
		self:StopStunts()
	end
end

---------- SCORE STREAK STUNTS ----------
-- Stunt scores that are dependent of stunt duration

function Stunts:runScoreStreak(stuntName, add)
	add = add or 0
	--Chat:Print(tostring(self.vehicle) .. " vs " .. tostring(LocalPlayer:GetVehicle():GetId()),Color(0,0,200))
	if self.stunts[stuntName].time == nil then
		-- Start running
		--print("START "..stuntName)
		self.stunts[stuntName].time = Timer()
		self.stunts[stuntName].blink = nil
	end
	--print("UPDATE "..stuntName)
	-- Update score
	if add == nil then Chat:Print("add was zero! " .. stuntName, Color(255,0,0)) return end
	if add > 0 then
		self.scores[stuntName].curr = self.scores[stuntName].curr + add
		self.stunts[stuntName].scoreText = "+" .. string.format("%.2f", self.scores[stuntName].curr)
	else
		self.stunts[stuntName].scoreText = ""
	end
	--self.total = self.total + add
	-- Set bonus
	local mult = math.floor(self.stunts[stuntName].time:GetSeconds() / 2)
	if mult > 0 then
		self.stunts[stuntName].bonusText = "  " .. mult .. "x BONUS"
	end
end

function Stunts:stopScoreStreak(stuntName, blink, direct)
	blink = blink or true
	direct = direct or false
	local args = {}
	local add = 0
	
	-- Check if stunt is running
	if self.stunts[stuntName].time ~= nil then
		--print("STOP " .. stuntName .. " ".. self.scores[stuntName].curr)
		-- Ignore when under threshhold
		if self.stunts[stuntName].time:GetSeconds() < self.stuntTreshhold and not direct then
			self.scores[stuntName].curr = 0
			self.stunts[stuntName].time = nil
			return
		end
		local mult = math.floor(self.stunts[stuntName].time:GetSeconds() / 2)
		local totalMult = mult + self:BonusMultiplier()
		add = self.scores[stuntName].curr * (1 + totalMult)
		--print("normal " .. tostring(self.scores[stuntName].curr) .. " bonus " .. tostring(add))
		-- Update total score
		self.scores[stuntName].total = self.scores[stuntName].total + add
		if add > 0 then
			self.stunts[stuntName].scoreText = "+" .. string.format("%.2f", add)
		else
			self.stunts[stuntName].scoreText = "  " .. mult .. "x BONUS"
		end
		self.stunts[stuntName].bonusText = ""
		self.total = self.total + add

		-- Send score to server
		args = {
			["stuntName"] = stuntName,
			["score"] = self.scores[stuntName].curr,
			["bonus"] = totalMult,
			["vehType"] = self.vehType
		}
		Network:Send("StuntScoreUpdate", args)
		-- Reset active score
		self.scores[stuntName].curr = 0
		self.stunts[stuntName].time = nil
		if blink then
			-- Start blinking
			self.stunts[stuntName].blink = Timer()
		else
			self.stunts[stuntName].blink = nil
		end
		--print("STOP scorestreak "..stuntName)
		table.insert(self.streakQueue, {["stuntName"] = stuntName, ["offset"] = 0, ["score"] = add})
	end
	return add
end

function Stunts:directStunt(stuntName, score)
	stunts:runScoreStreak(stuntName, score)
	stunts:stopScoreStreak(stuntName, true, true)
end

function Stunts:StartStunts(args)
	if self.vehicle ~= nil then
		--Chat:Print("Detected new vehicle!",Color(0,0,200))
		self:StopStunts()
		--Chat:Print("stopped all stunts.. " .. tostring(self.stunts.upside.time == nil) .. " " .. tostring(self.stunts.upside.blink == nil) .. " " .. self.scores.upside.curr, Color(255,255,255))
	end
	self.vehicle = LocalPlayer:GetVehicle():GetId()
	local height = StuntDetector.GetVehicleState().height
	if height > 2 then
		self.spawnedInAir = true
	--else
		--print("new vehicle but not high in air")
	end
end

function Stunts:StopStunts(bl)
	local blink = true or bl
	local bestLastStunt = nil
	local bestScore = 0
	local add = 0
	for k, v in pairs(self.stunts) do
		add = self:stopScoreStreak(k, blink)
		if add ~= nil and add > bestScore then
			bestScore = add
			bestLastStunt = k
		end
		--print(tostring(k).." stopped with " .. tostring(add))
	end
	--Chat:Print("stunt :" .. tostring(bestLastStunt), Color())
	Network:Send("StopSession", {["lastStunt"] = bestLastStunt})
	-- Reset stunt detector
	self.stuntDetector = nil
	self.vehicle = nil
	self.total = 0
	for k, v in pairs(self.stunts) do
		self.scores[k] = {}
		self.scores[k].total = 0
		self.scores[k].curr = 0
	end
	for k, v in pairs(self.bonuses) do
		v.active = false
	end
	for k, v in pairs(self.combos) do
		--print("stop " .. k)
		self:StopCombo(k)
	end
	self.bonusCount = 0
	stuntDetector:ResetAllRotations()
end

function Stunts:UpdateSessionResult(args)
	--print("ok " .. tostring(args.sessionResult == nil))
	self.sessionResult = args
end

function Stunts:IsActive(stuntName)
	return(self.stunts[stuntName].time ~= nil)
end

---------- BONUSES ----------
function Stunts:StartBonus(bonusName)
	if not self.bonuses[bonusName].active then
		if bonusName == "reverse" then
			if self.bonuses[bonusName].threshold == nil then
				self.bonuses[bonusName].threshold = Timer()
			elseif self.bonuses[bonusName].threshold:GetSeconds() > 0.5 then
				self.bonuses[bonusName].active = true
				self.bonusCount = self.bonusCount + 1
			end
		else
			self.bonuses[bonusName].active = true
			self.bonusCount = self.bonusCount + 1
		end
	end
end
function Stunts:StopBonus(bonusName)
	if self.bonuses[bonusName].active then
		self.bonuses[bonusName].active = false
		self.bonusCount = self.bonusCount - 1
		self.bonuses[bonusName].threshold = nil
	end
end
function Stunts:BonusMultiplier()
	if self.bonusCount == 0 then return 0 end
	local bonusMult = 0
	for k, v in pairs(self.bonuses) do
		if v.active then
			bonusMult = bonusMult + (v.mult - 1)
		end
	end
	--print("bonus mult " .. tostring(bonusMult))
	return bonusMult
end
---------- COMBOS ----------
function Stunts:AddCombo(comboName, score)
    --print("adding combo " .. comboName)
	local combo = self.combos[comboName]
	if combo.count == 0 then
		self.comboCount = self.comboCount + 1
	end
	combo.count = combo.count + 1
	local mult = 0
	if combo.count <= 10 then
		mult = 1/5 * combo.count
	else
		mult = 2
	end
	if combo.score == nil then
		combo.score = 0
		combo.scoreMult = 0
	end
	local totalMult = mult + self:BonusMultiplier()
	local add = score * (1 + totalMult)

	combo.score = combo.score + score
	combo.scoreMult = combo.scoreMult + add
	--self.total = self.total + add
	--print("combo normal " .. tostring(score) .. " bonus " .. tostring(add))
	-- Send score to server
	args = {
		["stuntName"] = comboName,
		["score"] = score,
		["bonus"] = mult,
		["vehType"] = self.vehType
	}
	Network:Send("StuntScoreUpdate", args)
	combo.coolDown = Timer()
end
function Stunts:StopCombo(comboName)
	if self.combos[comboName].count > 0 then
		local combo = self.combos[comboName]
		self.total = self.total + combo.scoreMult
		combo.count = 0
		combo.coolDown = nil
        --print("stopped " .. comboName)
		combo.score = 0
		combo.scoreMult = 0
		self.comboCount = self.comboCount - 1
	end
end


---------- ONE-TIME STUNTS ----------
-- Scores for stunts without duration

-- TODO

---------- SIMULTANIOUS STUNTS ----------
-- Bonuses for simultanious stunts

-- TODO

---------- COMBO STUNTS ----------

-- TODO

---------- RENDERING ----------
function TestCompare(a, b)
	return a[2] > b[2]
end
-- Fire active renderer
function Stunts:ActiveRender()
	self:render()
end

function Stunts:DefaultRender()
	if Game:GetState() ~= GUIState.Game then return end
	-- Info and total score
	Render:DrawText(Vector2(2, Render.Height - Render:GetTextHeight(self.info, 12) - 2), self.info, Color(150,80,10), 12)

	local text = "PowerUps"
	local height = Render:GetTextHeight(text, 12)
	Render:DrawText(Vector2(Render.Width - Render:GetTextWidth(text, 12) - 2, 60), text, Color(150,80,10), 12)

	for k, v in pairs(self.streakQueue) do
		local stuntText = string.format("+%.2f", v.score)-- .. " " .. self.stunts[v.stuntName].text
		Render:DrawText(Vector2((Render.Width - Render:GetTextWidth(stuntText, TextSize.Huge/2))/2,100-v.offset),
								stuntText,
								self.stunts[v.stuntName].color - Color(0,0,0,0+math.min(200,v.offset)),
								TextSize.Huge/2)
		v.offset = v.offset + 2
		--print(v.offset)
		if v.offset > 255 then
			--print("ok")
			self.streakQueue[k] = nil
		end
	end
	if self.sessionResult then
		local text = "Earned " .. self.sessionResult.text .. " points!"
		local textWidth = Render:GetTextWidth(text, TextSize.Huge)
		local textHeight = Render:GetTextHeight(text, TextSize.Huge)
		local subText = self.sessionResult.subText
		local subTextWidth = Render:GetTextWidth(subText, TextSize.Large)
		Render:DrawText(Vector2((Render.Width-textWidth)/2, Render.Height / 4) + Vector2(self.sessionResult.offset/2, 0),
						text,
						Color(0,0,0,200) - Color(0,0,0,0+math.min(200, self.sessionResult.offset)),
						TextSize.Huge)
		Render:DrawText(Vector2((Render.Width-textWidth)/2, Render.Height / 4) + Vector2(self.sessionResult.offset, 0),
						text,
						Color(50,200,0,200) - Color(0,0,0,0+math.min(200, self.sessionResult.offset)),
						TextSize.Huge)
		Render:DrawText(Vector2((Render.Width-subTextWidth)/2, Render.Height / 4 + textHeight) + Vector2(self.sessionResult.offset/3, 0),
						subText,
						Color(0,0,0,200) - Color(0,0,0,0+math.min(200, self.sessionResult.offset)),
						TextSize.Large)
		Render:DrawText(Vector2((Render.Width-subTextWidth)/2, Render.Height / 4 + textHeight) + Vector2(self.sessionResult.offset/2, 0),
						subText,
						Color(50,200,0,200) - Color(0,0,0,0+math.min(200, self.sessionResult.offset)),
						TextSize.Large)

		self.sessionResult.offset = self.sessionResult.offset + 0.50
		if self.sessionResult.offset > 500 then
			self.sessionResult = nil
		end
	end

    
    --local yPos = 200
    --for i=1, #stuntDetector.rotations do
    --    Render:DrawText(Vector2(Render.Width/2, yPos),
    --        string.format("%f %f %f", stuntDetector.rotations[i].x,
    --                                    stuntDetector.rotations[i].y,
    --                                    stuntDetector.rotations[i].z),
    --        Color.White, TextSize.Default)
    --    yPos = yPos + 20
    --end
    
	if LocalPlayer:InVehicle() then
        local vehHealth = LocalPlayer:GetVehicle():GetHealth()
		local total = string.format("%.2f", self.total)
		local textSize = 12
		textSize = 32
		local pointAlignment = 15
		local widthTotal = math.max(Render:GetTextWidth(total, textSize) + pointAlignment, 100)
		local heightTotal = Render:GetTextHeight(total, textSize)
		--Render:FillArea(Vector2((Render.Width - widthTotal - 5) / 2, 0), Vector2(widthTotal+10, heightTotal+10), Color(0, 0, 0, 100))
		--Render:DrawText(Vector2((Render.Width - widthTotal)/2, 5), total, Color(200,200,0, 200), textSize)
		Render:FillArea(Vector2((Render.Width - widthTotal - 5) / 2, 0), Vector2(widthTotal+10, heightTotal), Color(0, 0, 0, 100))
		Render:FillTriangle(Vector2((Render.Width - widthTotal - 5) / 2 + widthTotal+10, 0),
							Vector2((Render.Width - widthTotal - 5) / 2 + widthTotal+10, heightTotal),
							Vector2((Render.Width - widthTotal - 5) / 2 + widthTotal+10 + 200, 0),
							Color(0,0,0,100))
		Render:FillTriangle(Vector2((Render.Width - widthTotal - 5) / 2, 0),
							Vector2((Render.Width - widthTotal - 5) / 2, heightTotal),
							Vector2((Render.Width - widthTotal - 5) / 2 - 200, 0),
							Color(0,0,0,100))
		-- Render:FillCircle(Vector2((Render.Width - widthTotal - 5) / 2 + widthTotal+10, 0), heightTotal, Color(0,0,0,100))
		-- Render:FillCircle(Vector2((Render.Width - widthTotal - 5) / 2, 0), heightTotal, Color(0,0,0,100))
		Render:DrawText(Vector2((Render.Width - widthTotal)/2 + pointAlignment, 5), total, Color(200,200,0, 200), textSize)
		Render:DrawText(Vector2((Render.Width - widthTotal - 5) / 2 + widthTotal+10 + 5, 5), "points", Color(200,200,0, 200), 12)
		Render:DrawText(Vector2((Render.Width - widthTotal - 5) / 2 - 60, 5), "health", Color(200,200,0, 200), 10)
		-- Render:DrawLine(Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 13.5),
		-- 				Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 13.5) + Vector2(51, 0),
		-- 				Color(255, 255, 255, 100))
		-- Render:DrawLine(Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 20),
		-- 				Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 20) + Vector2(51, 0),
		-- 				Color(255, 255, 255, 100))
		-- Render:DrawLine(Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 14),
		-- 				Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 19.5),
		-- 				Color(255, 255, 255, 100))
		-- Render:DrawLine(Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 14) + Vector2(51, 0),
		-- 				Vector2((Render.Width - widthTotal - 5) / 2 - 60 -1, 19.5) + Vector2(51, 0),
		-- 				Color(255, 255, 255, 100))
		Render:FillArea(Vector2((Render.Width - widthTotal - 5) / 2 - 60, 14), Vector2(50 * vehHealth, 5), Color.FromHSV(120 * vehHealth, 80, 0.8))
	end

	-- Powerups
	for k, v in pairs(self.powerUps) do
		if v then
			local text = k .. " enabled"
			height = height + Render:GetTextHeight(text, 12) + 2
			Render:DrawText(Vector2(Render.Width - Render:GetTextWidth(text, 12) - 2, 60 + height), text, Color(150,80,10), 12)
		end
	end
	local activeStuntCount = 0
	local lastOffset = 0
	local scale = 2
	local scoreTop = Render.Height / 10
	if self.SETTINGS.scoreRendering == 1 then
		scoreTop = Render.Height / 8
	end
	local testSort = {}
	for k, v in pairs(self.scores) do
		table.insert(testSort, {k,v.curr})
	end
	table.sort(testSort, TestCompare)
	-- Active stunts
	for i, v in pairs(testSort) do
		stuntName = v[1]
		stuntData = self.stunts[stuntName]
	--for stuntName, stuntData in pairs(self.stunts) do
		if (stuntData.time and stuntData.time:GetSeconds() >= self.stuntTreshhold)
				or (stuntData.blink) then
			if self.SETTINGS.scoreRendering == 1 then
				scale = math.min(activeStuntCount + 1, 2)
			end
			local stuntText 		= stuntData["text"]-- .. " " .. tostring(activeStuntCount) .. " " .. tostring(lastOffset)
			local stuntTextWidth 	= Render:GetTextWidth(stuntText, TextSize.Huge / scale)
			local stuntTextHeight 	= Render:GetTextHeight(stuntText, TextSize.Huge / scale)
			--Chat:Print(stuntTextHeight .. " ", Color())
			local scoreText 		= stuntData["scoreText"]
			local scoreTextWidth 	= Render:GetTextWidth(scoreText, TextSize.Large / scale)
			local scoreTextHeight 	= Render:GetTextHeight(scoreText, TextSize.Large / scale)
			local y_pos 			= scoreTop + lastOffset
			--print(scoreText)
			-- Render stuntname

			Render:DrawText(Vector2((Render.Width - stuntTextWidth)/2, y_pos) + Vector2(1, 1),
								stuntText,
								Color(0, 0, 0, 200),
								TextSize.Huge / scale)
			Render:DrawText(Vector2((Render.Width - stuntTextWidth)/2, y_pos),
								stuntText,
								self.stunts[stuntName].color,
								TextSize.Huge / scale)



			activeStuntCount = activeStuntCount + 1

			local offset = stuntTextHeight + scoreTextHeight/2
			local ttt = lastOffset
			local xOffset = 0
			local yOffset = 0
			if self.SETTINGS.scoreRendering == 1 then
				lastOffset = lastOffset + offset + scoreTextHeight + 10
				xOffset = (Render.Width - scoreTextWidth)/2
				yOffset = offset
			else
				lastOffset = lastOffset + stuntTextHeight + 10
				xOffset = (Render.Width - stuntTextWidth)/2 + stuntTextWidth + 10
				yOffset = stuntTextHeight/2
			end

			--Render:DrawText(Vector2(2, Render.Height / 2 + 20*activeStuntCount), string.format("%d: ypos(%.2f) %.2f + %.2f + %.2f + 0 = %.2f",activeStuntCount,y_pos,ttt,offset,scoreTextHeight,lastOffset), Color(150,80,10), 12)
			--Render:DrawLine(Vector2(0,y_pos), Vector2(Render.Width,y_pos), Color(255,255,255))
			--Render:DrawLine(Vector2(0, Render.Height / 8 + lastOffset), Vector2(Render.Width, Render.Height / 8 + lastOffset), Color(255,255,0))
			-- Render active score
			if stuntData.blink == nil
			or stuntData.blink:GetSeconds() % 0.5 < 0.25 then
				Render:DrawText(Vector2(xOffset, y_pos + yOffset) + Vector2(1, 1),
								scoreText .. stuntData["bonusText"],
								Color(0, 0, 0, 200),
								TextSize.Large / scale)
				Render:DrawText(Vector2(xOffset, y_pos + yOffset),
								scoreText .. stuntData["bonusText"],
								Color.FromHSV(math.max(180 - self.scores[stuntName].curr, 0), 1, 1),
								TextSize.Large / scale)
			end
			if stuntData.blink and stuntData.blink:GetSeconds() > 2 then
				-- Stop blinking
				--print("STOP BLINKING "..stuntName)
				stuntData.blink = nil
			end
		end
	end
	if self.bonusCount > 0 then
		Render:DrawText(Vector2(Render.Width * 5/16, scoreTop),
								"BONUSES",
								Color.FromHSV(math.max(180 - self.bonusCount * 40, 0), 1, 0.5),
								TextSize.Large)
		local offSet = 40
		for k, v in pairs(self.bonuses) do
			if v.active then
				--print(k .. "  " .. v.text)
				Render:DrawText(Vector2(Render.Width * 5/16, scoreTop + offSet),
									v.text .. " (x" .. v.mult .. ")",
									v.color,
									TextSize.Default)
				offSet = offSet + 40
			end
		end
	end
	if self.comboCount > 0 then
		Render:DrawText(Vector2(Render.Width * 11/16, scoreTop),
								"COMBOS",
								Color.White,
								TextSize.Large)
		local offSet = 40
		for k, v in pairs(self.combos) do
			if v.count > 0 then
				Render:DrawText(Vector2(Render.Width * 11/16, scoreTop + offSet),
									string.format("%s (x%d) %.2f",v.text, v.count, v.scoreMult),
									v.color,
									TextSize.Default)
				local width = 0
				local sec = v.coolDown:GetSeconds()
				if sec < 2 then
					width = (3 - math.floor(sec))/3 * 50
				else
					width = (3 - sec)/3 * 50
				end
				Render:FillArea(Vector2(Render.Width * 11/16 + 150, scoreTop + offSet),
								Vector2(width, 10),
								Color(230, 230, 50, 150))
				offSet = offSet + 40
			end
		end
	end
	if self.scoreBoard then
		Render:DrawText(Vector2(10, 250),
								"challenge scoreboardtest",
								Color(200,100,100,200))
		for k, v in pairs(self.scoreBoard) do
			local color = Color(255,255,255,200)
			if v == LocalPlayer:GetName() then
				color = Color(100,200,100,200)
			end
			Render:DrawText(Vector2(10, 250+k*20),
								tostring(k) .. ". " .. v,
								color)
		end
	end
end

function Stunts:ChangeRender(args)
	if args == nil then return end
	if args.topview then
		-- no rendering supported for this view yet
		-- use default
		self.render = self.DefaultRender
	else
		-- default rendering
		self.render = self.DefaultRender
	end
end

---------- POWERUPS ----------

function Stunts:TogglePowerUps(args)
	if args.text == "/driftboost" then
		self.powerUps.drift = not self.powerUps.drift
	end
end

---------- INFO ----------

function Stunts:ModulesLoad()
    Events:Fire("HelpAddItem",
        {
            name = "Stunts",
            text =
                "JC2-MP Stunts alpha\n\n"..
                "Press 'K' to access the menu"
        })
end

function Stunts:ModuleUnload()
    Events:Fire("HelpRemoveItem",
        {
            name = "Stunts"
        })
end

function Stunts:UpdateScoreBoard(args)
	self.scoreBoard = args
end

---------- VEHICLES ----------
class("Vehicles")
function Vehicles.Car()
	return {1,2,4,7,8,9,10,11,12,13,15,18,22,23,26,29,31,32,33,35,36,40,41,42,44,46,47,48,49,52,54,55,56,58,60,63,66,68,70,71,72,73,75,76,77,78,79,82,84,86,87,91}
end

function Vehicles.Bike()
	return {21,43,61,74,83,89,90}
end

function Vehicles.AirPlane()
	return {24,30,34,39,51,59,81,85}
end

function Vehicles.Heli()
	return {3,14,37,57,62,64,65,67}
end

function Vehicles.Boat()
	return {5,6,16,19,25,27,28,38,45,50,69,80,88}
end

function Vehicles.Monstertruck()
	return {20}
end

function Vehicles.Hovercraft()
	return {53}
end
---------- TOOLS ----------
class("Tools")
function Tools.TableContains(vehTable, id)
	for k, v in pairs(vehTable) do
		if id == v then
			return true
		end
	end
	return false
end