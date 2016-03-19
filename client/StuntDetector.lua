class("StuntDetector")

function StuntDetector:__init()
	self.rotations = {}
	self.maxSamples = 10
	self.sampleTimer = Timer()
	self.sampleRate = 0.25 -- in seconds, change according to angular velocity..
	self.sampleRateMIN = 0.5
	self.sampleRateMAX = 0.01
	self.prevAngle = nil
	self.rotationThreshold = 2*math.pi - math.rad(10)
	self.rotationSpeed = Vector3(0,0,0)

	self.prevAngVel = nil

	-- Events:Subscribe("PostTick", function ()
	-- 		if not LocalPlayer:InVehicle() then return end

	-- 		if self.sampleTimer:GetSeconds() > self.sampleRate then
	-- 			--print("test")
	-- 			local interval = self.sampleTimer:GetSeconds()
	-- 			self.sampleTimer:Restart()

	-- 			self.rotationSpeed = -LocalPlayer:GetVehicle():GetAngle() * LocalPlayer:GetVehicle():GetAngularVelocity()
	-- 			--self:AddRotationSample(LocalPlayer:GetVehicle():GetAngle())
	-- 			self:AddRotationSample(self.rotationSpeed, interval)
	-- 			self:DetectRotations()
	-- 			-- Reset sample rate
	-- 			if self.rotationSpeed:Length() < 0.1 then
	-- 				self.sampleRate = self.sampleRateMIN
	-- 				self:ResetRotations("x")
	-- 				self:ResetRotations("y")
	-- 				self:ResetRotations("z")
	-- 			else
	-- 				--print(tostring(self.rotationSpeed))
	-- 				--print(tostring(2*math.pi/self:MaxRotationAxis()))
	-- 				local wantedSamples = 2*math.pi/self:MaxRotationAxis()/3
	-- 				self.sampleRate = math.min(self.sampleRateMIN, math.max(self.sampleRateMAX, wantedSamples))
	-- 				--print(self.rotationSpeed:Normalize())
	-- 				--print(tostring(self.rotationSpeed:Length()) .. " " .. tostring(self.rotationSpeed:LengthSqr()))
	-- 				--self.sampleRate = 0.25
	-- 			end
	-- 			--print(tostring(angVel:Length()))

	-- 		end
	-- 	end)

	-- Events:Subscribe("Render", function()
	-- 		local y_pos = 500
	-- 		Render:DrawText(Vector2(Render.Width/2+500, y_pos - 40), tostring(self.sampleRate), Color(255,255,255))
	-- 		Render:DrawText(Vector2(Render.Width/2+500, y_pos - 20), "pitch         spin            roll", Color(255,255,255))
	-- 		for i = 1, #self.rotations do
	-- 			Render:DrawText(Vector2(Render.Width/2+500, y_pos), tostring(self.rotations[i]), Color(255,255,255))
	-- 			y_pos = y_pos + 20
	-- 		end
	-- 	end)
end

function StuntDetector:DetectRotations()
	if not LocalPlayer:InVehicle() then return end

	if self.sampleTimer:GetSeconds() > self.sampleRate then
		--print("test")
		local interval = self.sampleTimer:GetSeconds()
		self.sampleTimer:Restart()

		self.rotationSpeed = -LocalPlayer:GetVehicle():GetAngle() * LocalPlayer:GetVehicle():GetAngularVelocity()
		--self:AddRotationSample(LocalPlayer:GetVehicle():GetAngle())
		self:AddRotationSample(self.rotationSpeed, interval)
		self:DetectCompleteRotation()
		-- Reset sample rate
		if self.rotationSpeed:Length() < 0.1 then
			self.sampleRate = self.sampleRateMIN
			self:ResetRotations("x")
			self:ResetRotations("y")
			self:ResetRotations("z")
		else
			--print(tostring(self.rotationSpeed))
			--print(tostring(2*math.pi/self:MaxRotationAxis()))
			local wantedSamples = 2*math.pi/self:MaxRotationAxis()/3
			self.sampleRate = math.min(self.sampleRateMIN, math.max(self.sampleRateMAX, wantedSamples))
			--print(self.rotationSpeed:Normalize())
			--print(tostring(self.rotationSpeed:Length()) .. " " .. tostring(self.rotationSpeed:LengthSqr()))
			--self.sampleRate = 0.25
		end
		--print(tostring(angVel:Length()))
	end
	local angVel = LocalPlayer:GetVehicle():GetAngularVelocity()

	-- MAX
	-- local max = math.abs(angVel.x)
	-- local maxAxis = "x"
	-- local maxStunt = "flipping"
	-- if math.abs(angVel.y) > max then
	-- 	max = math.abs(angVel.y)
	-- 	maxAxis = "y"
	-- 	maxStunt = "spinning"
	-- end
	-- if math.abs(angVel.z) > max then
	-- 	max = math.abs(angVel.z)
	-- 	maxAxis = "z"
	-- 	maxStunt = "rolling"
	-- end

	-- if max > 3 then
	-- 	stunts:runScoreStreak(maxStunt, math.abs(angVel[maxAxis]) * 0.0001)
	-- else
	-- 	stunts:stopScoreStreak("flipping")
	-- 	stunts:stopScoreStreak("spinning")
	-- 	stunts:stopScoreStreak("rolling")
	-- end

	-- ALL
	if math.abs(angVel.x) > 2.5 then
		stunts:runScoreStreak("flipping", math.abs(angVel.x) * 0.0001)
	else
		stunts:stopScoreStreak("flipping")
	end
	if math.abs(angVel.y) > 2.5 then
		stunts:runScoreStreak("spinning", math.abs(angVel.y) * 0.0001)
	else
		stunts:stopScoreStreak("spinning")
	end
	if math.abs(angVel.z) > 2.5 then
		stunts:runScoreStreak("rolling", math.abs(angVel.z) * 0.0001)
	else
		stunts:stopScoreStreak("rolling")
	end
	for k, v in pairs(stunts.combos) do
		if v.coolDown ~= nil then
			if v.coolDown:GetSeconds() > 3 then
				stunts:StopCombo(k)
			end
		end
	end
end

function StuntDetector:MaxRotationAxis()
	local max = 0
	if math.abs(self.rotationSpeed.x) > max then
		max = math.abs(self.rotationSpeed.x)
	end
	if math.abs(self.rotationSpeed.y) > max then
		max = math.abs(self.rotationSpeed.y)
	end
	if math.abs(self.rotationSpeed.z) > max then
		max = math.abs(self.rotationSpeed.z)
	end
	return max
end

---------- ROTATION DETECTION ---------

function StuntDetector:AddRotationSample(sample, interval)
	--sample = Angle(0,0,0)
	-- Get relative rotation to previous angle

	local rotation = Vector3(0,0,0)
	if self.prevAngVel then
		-- Estimate rotation in interval based on average speed
		rotation = interval * (self.prevAngVel + sample)/2
	end
	self.prevAngVel = sample

	-- Save relative rotation
	if #self.rotations < self.maxSamples then
		local s = #self.rotations
		for i = 0, s - 1 do
			self.rotations[s + 1 - i] = self.rotations[s - i]
		end
	else
		for i = 0, self.maxSamples - 1 do
			self.rotations[self.maxSamples - i] = self.rotations[self.maxSamples - 1 - i]
		end
	end
	self.rotations[1] = rotation
	--print("added " .. tostring(rotation))
end

-- Analyze relative rotations
function StuntDetector:DetectCompleteRotation()
	local state = StuntDetector.GetVehicleState()
	local rotationsCCW = Vector3(0,0,0) -- # of counter clockwize rotations
	local rotationsCW = Vector3(0,0,0) -- # of clockwize rotations
	local sum = Vector3(0,0,0)
	local detected = false
	for i = 1, #self.rotations do
		sum = StuntDetector.RotationSum(sum, self.rotations[i])
		detected = self:CheckSum(sum, rotationsCCW, rotationsCW)
        --if math.abs(sum.x) > math.rad(1) or math.abs(sum.y) > math.rad(1) or math.abs(sum.z) > math.rad(1) then
            --print(string.format("sum = %f %f %f", sum.x, sum.y, sum.z))
        --end
		if detected then
			-- SPIN
			if rotationsCCW.y > 0 or rotationsCW.y > 0 then
				if rotationsCCW.y > 0 then
					--print("CCW SPIN " .. tostring(rotationsCCW.y))
					--Chat:Print("CCW SPIN", Color(255,255,255))
					rotationsCCW.y = 0
					stunts:AddCombo("spin", math.abs(self.rotationSpeed.y))
					--stunts:directStunt("spin", 2 * math.abs(self.rotationSpeed.y))--*math.abs(state.velocity.z/10))
					--if sum.x ~= 0 then Chat:Print("NOT OK", Color(255,0,0)) end
				end
				if rotationsCW.y > 0 then
					--print("CW SPIN " .. tostring(rotationsCW.y))
					--Chat:Print("CW SPIN", Color(255,255,255))
					rotationsCW.y = 0
					stunts:AddCombo("spin", math.abs(self.rotationSpeed.y))
					--stunts:directStunt("spin", 2 * math.abs(self.rotationSpeed.y))--*math.abs(state.velocity.z/10))
				end
				self:ResetRotations("y")
			end
			-- FLIP
			if rotationsCCW.x > 0 or rotationsCW.x > 0 then
				if rotationsCCW.x > 0 then
					--print("BACK FLIP " .. tostring(rotationsCCW.x))
					--Chat:Print("BACK FLIP", Color(255,255,255))
					rotationsCCW.x = 0
					if state.height > 2 then
						stunts:AddCombo("backflip", math.abs(self.rotationSpeed.x))
						--stunts:directStunt("backflip", 2 * math.abs(self.rotationSpeed.x))
					end
				end
				if rotationsCW.x > 0 then
					--print("FRONT FLIP " .. tostring(rotationsCW.x))
					--Chat:Print("FRONT FLIP", Color(255,255,255))
					rotationsCW.x = 0
					if state.height > 2 then
						stunts:AddCombo("frontflip", math.abs(self.rotationSpeed.x))
						--stunts:directStunt("frontflip", 2 * math.abs(self.rotationSpeed.x))
					end
				end
				self:ResetRotations("x")
			end
			-- ROLL
			if rotationsCCW.z > 0 or rotationsCW.z > 0 then
				if rotationsCCW.z > 0 then
					--print("LEFT ROLL " .. tostring(rotationsCCW.z))
					--Chat:Print("LEFT ROLL", Color(255,255,255))
					rotationsCCW.z = 0
					stunts:AddCombo("roll", math.abs(self.rotationSpeed.z))
					--stunts:directStunt("roll", 2 * math.abs(self.rotationSpeed.z))
				end
				if rotationsCW.z > 0 then
					--print("RIGHT ROLL " .. tostring(rotationsCW.z))
					--Chat:Print("RIGHT ROLL", Color(255,255,255))
					rotationsCW.z = 0
					stunts:AddCombo("roll", math.abs(self.rotationSpeed.z))
					--stunts:directStunt("roll", 2 * math.abs(self.rotationSpeed.z))
				end
				self:ResetRotations("z")
			end
			detected = false
		end
	end
	--print("CCW: " .. tostring(rotationsCCW))
	--print("CW: " .. tostring(rotationsCW))
end

function StuntDetector.RotationSum(sum, rotation)
	sum.x = sum.x + rotation.x
	sum.y = sum.y + rotation.y
	sum.z = sum.z + rotation.z
	return sum
end

function StuntDetector:CheckSum(sum, rotationsCCW, rotationsCW)
	local detected = false
	if sum.x >= self.rotationThreshold then
		rotationsCCW.x = rotationsCCW.x + 1
		sum.x = 0
		detected = true
	elseif -sum.x >= self.rotationThreshold then
		rotationsCW.x = rotationsCW.x + 1
		sum.x = 0
		detected = true
	end
	if sum.y >= self.rotationThreshold then
		rotationsCCW.y = rotationsCCW.y + 1
		sum.y = 0
		detected = true
	elseif -sum.y >= self.rotationThreshold then
		rotationsCW.y = rotationsCW.y + 1
		sum.y = 0
		detected = true
	end
	if sum.z >= self.rotationThreshold then
		rotationsCCW.z = rotationsCCW.z + 1
		sum.z = 0
		detected = true
	elseif -sum.z >= self.rotationThreshold then
		rotationsCW.z = rotationsCW.z + 1
		sum.z = 0
		detected = true
	end
	return detected
end

function StuntDetector:ResetAllRotations()
	self.rotations = {}
end
-- Set relative rotations to zero
function StuntDetector:ResetRotations(axis)
	for i = 1, #self.rotations do
		self.rotations[i][axis] = 0
	end
end
-- Convert angle to [0..2*Pi[ range
function StuntDetector.NormalizeAngle(angle)
	while angle.yaw < 0 do
		angle.yaw = angle.yaw + 2*math.pi
	end
	while angle.yaw >= 2*math.pi do
		angle.yaw = angle.yaw - 2*math.pi
	end
	while angle.pitch < 0 do
		angle.pitch = angle.pitch + 2*math.pi
	end
	while angle.pitch >= 2*math.pi do
		angle.pitch = angle.pitch - 2*math.pi
	end
	while angle.roll < 0 do
		angle.roll = angle.roll + 2*math.pi
	end
	while angle.roll >= 2*math.pi do
		angle.roll = angle.roll - 2*math.pi
	end
	return angle
end

function StuntDetector.AngleDiff(a1, a2)
	local diff = Angle()
	diff.yaw = a1.yaw - a2.yaw
	if math.abs(diff.yaw) > math.pi then
		if a1.yaw > a2.yaw then
			diff.yaw = -(math.pi - math.abs(a1.yaw) + math.pi - math.abs(a2.yaw))
		else
			diff.yaw = math.pi - math.abs(a2.yaw) + math.pi - math.abs(a1.yaw)
		end
	end
	diff.pitch = a1.pitch - a2.pitch
	if math.abs(diff.pitch) > math.pi then
		if a1.pitch > a2.pitch then
			diff.pitch = -(math.pi - math.abs(a1.pitch) + math.pi - math.abs(a2.pitch))
		else
			diff.pitch = math.pi - math.abs(a2.pitch) + math.pi - math.abs(a1.pitch)
		end
	end
	diff.roll = a1.roll - a2.roll
	if math.abs(diff.roll) > math.pi then
		if a1.roll > a2.roll then
			diff.roll = -(math.pi - math.abs(a1.roll) + math.pi - math.abs(a2.roll))
		else
			diff.roll = math.pi - math.abs(a2.roll) + math.pi - math.abs(a1.roll)
		end
	end
	return diff
end

---------- STUNT DETECTION ----------

-- Car stunts
function StuntDetector.Car()
	local state = StuntDetector.GetVehicleState()

	stunts.height = state.height
	stunts.vehHeight = state.height
	local velocity = Vector3()
	velocity.x = math.abs(state.velocity.x)
	velocity.y = math.abs(state.velocity.y)
	velocity.z = math.abs(state.velocity.z)
	local absoluteHeight = LocalPlayer:GetVehicle():GetPosition().y - 200

	if state.height > 2 and velocity:Length() > 1 then
		-- AIRTIME
		--Chat:Print(tostring(stunts.spawnedInAir), Color())
		if not stunts.spawnedInAir then
			stunts:runScoreStreak("air", (stunts.height + velocity:Length()) * 0.002)
		end
	else
		if stunts.spawnedInAir == true then
			stunts.spawnedInAir = false
			print("put false " .. tostring(state.height))
		end
		stunts:stopScoreStreak("air")

		if velocity.z > 0.4 and velocity.x > 0.8 then
			if velocity.x > velocity.z * 0.25 then
				-- SPINNING/DONUT
				stunts:stopScoreStreak("drift", false)
				--stunts:runScoreStreak("spin", velocity.x * 0.002)
			else
				-- DRIFTING
				--stunts:stopScoreStreak("spin", false)

				stunts:runScoreStreak("drift", velocity.x * 0.016)
			end
		else
			-- No stunts
			--stunts:stopScoreStreak("spin")
			stunts:stopScoreStreak("drift")
		end
	end
	if velocity.z * 3.6 > 180 then
		-- SPEED
		stunts:runScoreStreak("speed", velocity.z * 0.0001)
	else
		stunts:stopScoreStreak("speed")
	end
	if math.abs(state.terrRollAngle) > math.rad(20)
		and math.abs(state.terrRollAngle) < math.pi/2
		and state.height < 2 then
		stunts:runScoreStreak("twowheels", math.abs(state.terrRollAngle) * 0.1)
	else
		stunts:stopScoreStreak("twowheels")
	end
	if stunts.powerUps["drift"] then
		StuntDetector.BoostDrift(LocalPlayer:GetVehicle(), velocity.z)
	end
	if absoluteHeight < 0 then
		local score = 0
		if absoluteHeight > -0.5 then
			score = 0
		else
			score = 0.0001 * -(absoluteHeight) * velocity.z
		end
		stunts:runScoreStreak("swimming", score)
	else
		stunts:stopScoreStreak("swimming")
	end
	if -state.velocity.z < -5 then
		-- DRIVE BACKWARDS
		stunts:StartBonus("reverse")
	else
		stunts:StopBonus("reverse")
	end
	if LocalPlayer:GetVehicle():GetHealth() <= 0.3 then
		stunts:StartBonus("damage")
	end
	if state.height >= 100 then
		stunts:StartBonus("high")
	else
		stunts:StopBonus("high")
	end
end

-- Bike stunts
function StuntDetector.Bike()
	local state = StuntDetector.GetVehicleState()
	local angle = LocalPlayer:GetVehicle():GetAngle()
	stunts.vehHeight = Physics:Raycast(LocalPlayer:GetVehicle():GetPosition(), Vector3( 0, -1, 0 ), 0, 200).distance

	if state.height > 2 and not stunts.spawnedInAir then
		-- AIRTIME
		stunts:runScoreStreak("air", (stunts.height + math.abs(state.velocity.z)) * 0.002)
	else
		stunts.spawnedInAir = false
		stunts:stopScoreStreak("air")
		-- WHEELIES
		if state.terrPitchAngle > math.pi / 8 and state.terrPitchAngle < math.pi / 2 then
			--Chat:Print(string.format("%.2f", math.deg(state.terrPitchAngle)),Color())
			-- WHEELIE
			stunts:stopScoreStreak("fwheelie")
			stunts:runScoreStreak("wheelie", state.terrPitchAngle * 0.05)
		elseif state.terrPitchAngle < -math.pi / 8 and state.terrPitchAngle > -math.pi / 2 then
			-- FRONT WHEELIE
			stunts:stopScoreStreak("wheelie")
			stunts:runScoreStreak("fwheelie", math.abs(state.terrPitchAngle) * 0.05)
		else
			stunts:stopScoreStreak("wheelie")
			stunts:stopScoreStreak("fwheelie")
		end
		if math.abs(state.terrRollAngle) > math.rad(35) then
			--Chat:Print("tilting!"..string.format("%.2f %.2f",math.pi/4,math.abs(state.terrRollAngle)),Color(0,255,0))
			stunts:runScoreStreak("biketilt", math.abs(state.terrRollAngle) * 0.05)
		else
			stunts:stopScoreStreak("biketilt")
		end
	end
end

-- Airplane stunts
function StuntDetector.AirPlane()
	local state = StuntDetector.GetVehicleState()

	stunts.height = state.height
	stunts.vehHeight = Physics:Raycast(LocalPlayer:GetVehicle():GetPosition(), Vector3( 0, -1, 0 ), 0, 200).distance
	local velocity = {}
	velocity.x = math.abs(state.velocity.x)
	velocity.y = math.abs(state.velocity.y)
	velocity.z = math.abs(state.velocity.z)
	local roll = state.angle.roll
	local absoluteHeight = LocalPlayer:GetVehicle():GetPosition().y - 200
	local upSight = Physics:Raycast(LocalPlayer:GetVehicle():GetPosition(), Vector3( 0, 1, 0 ), 0, 500).distance

	if stunts.height > 4 and stunts.height < 40 and velocity.z * 3.6 > 100 then
		-- LOWFLYER
		stunts:runScoreStreak("lowflyer", 1/stunts.height * absoluteHeight * 0.002*(1-state.normal.y))
	else
		stunts:stopScoreStreak("lowflyer")
	end
	if roll > math.pi / 2 or roll < -math.pi / 2 then
		if (roll > math.pi / 2 and roll < 0.749*math.pi) or (roll < -math.pi / 2 and roll > -0.749*math.pi) then
			-- OVERBANKING
			stunts:stopScoreStreak("upside")
			stunts:runScoreStreak("overbank", 0.0002)
		else
			-- UPSIDE DOWN
			stunts:stopScoreStreak("overbank")
			stunts:runScoreStreak("upside", 1/state.height * 0.02)
		end

	else
		stunts:stopScoreStreak("overbank")
		stunts:stopScoreStreak("upside")
	end
	if velocity.z * 3.6 < 50 and stunts.height > 4 then
		-- SLOWFLYER
		stunts:runScoreStreak("flyslow", 1/velocity.z * 1/absoluteHeight)
	else
		stunts:stopScoreStreak("flyslow")
	end
	if -state.velocity.z < 0 and stunts.height > 4 then
		-- FLY BACKWARDS
		stunts:runScoreStreak("flyback", velocity.z * 0.1 * 1/absoluteHeight)
	else
		stunts:stopScoreStreak("flyback")
	end
	if upSight < 500 and state.height > 4 then
		-- LIMBO
		if upSight <= 0.00001 then
			upSight = 1
		end
		if state.height <= 0.00001 then
			state.height = 1
		end
		stunts:runScoreStreak("limbo", velocity.z * 1 * 1/upSight * 1/state.height)
	else
		stunts:stopScoreStreak("limbo")
	end
	if absoluteHeight < 0 then
		local score = 0
		if absoluteHeight > -0.5 then
			score = 0
		else
			score = 0.0001 * -(absoluteHeight) * velocity.z
		end
		stunts:runScoreStreak("swimming", score)
	else
		stunts:stopScoreStreak("swimming")
	end
end

-- Heli stunts
function StuntDetector.Heli()

end

local boatSliding = nil
-- Boat stunts
function StuntDetector.Boat()
	local state = StuntDetector.GetVehicleState()
	local absoluteHeight = LocalPlayer:GetVehicle():GetPosition().y - 200
	--Chat:Print(tostring(absoluteHeight), Color())
	if absoluteHeight > 1 and state.height > 2 then
		if not stunts.spawnedInAir then
			local score = 0
			if absoluteHeight > 50 then
				score = 0.00001
			else
				score = (stunts.height + math.abs(state.velocity.z)) * 0.001
			end
			stunts:runScoreStreak("air", score)
		end
	else
		if stunts.spawnedInAir == true then
			stunts.spawnedInAir = false
			print("put false " .. tostring(state.height))
		end
		stunts:stopScoreStreak("air")
		if absoluteHeight > 0
			and state.height <= 2
			and math.abs(state.velocity:Length()) > 5 then
			local score = 0
			if absoluteHeight > 50 then
				score = 0.00001
			else
				score = absoluteHeight*0.001
			end
			stunts:runScoreStreak("boatslide", score)
			if boatSliding == nil then
				boatSliding = Timer()
			end
		else
			stunts:stopScoreStreak("boatslide")
		end
	end
	if absoluteHeight <= 0 and boatSliding then
		stunts:directStunt("waterreentry", boatSliding:GetSeconds()*2)
		boatSliding = nil
	end
	if absoluteHeight < -1 then
		stunts:runScoreStreak("diving", 0.01)
	else
		stunts:stopScoreStreak("diving")
	end

end
-- Monstertruck stunts
function StuntDetector.Monstertruck()
	stunts:runScoreStreak("awesome", 0.00001)
end

-- Hovercraft stunts
function StuntDetector.Hovercraft()
	stunts:runScoreStreak("awesome", 0.00001)
end

local zVector = Vector3(0, 0, -1)
local xVector = Vector3(1, 0, 0)

function StuntDetector.GetVehicleState()
	local veh = LocalPlayer:GetVehicle()
	local angle = veh:GetAngle()
	local terrain = Physics:Raycast(LocalPlayer:GetPosition(), Vector3( 0, -1, 0 ), 0, 400)
	local state = {}
	state.height = terrain.distance
	state.angle = angle
	state.normal = terrain.normal
	state.terrPitchAngle = math.asin(
									Vector3.Dot(
										terrain.normal, angle * zVector
									)
							)
	state.terrRollAngle = math.asin(
									Vector3.Dot(
										terrain.normal, angle * xVector
									)
							)
	state.velocity = -veh:GetAngle() * veh:GetLinearVelocity()
	state.terrNormal = terrain.normal
	return state
end

function norm(v1, v2)
	v2 = v2 or v1
	return math.sqrt(Vector3.Dot(v1, v2))
end

function norm2(v1)
	return v1:Distance(Vector3())
end

function StuntDetector.BoostDrift(vehicle, forwardSpeed)
	local vehicle = LocalPlayer:GetVehicle()
	local angVel = -vehicle:GetAngle() * vehicle:GetAngularVelocity()
	if forwardSpeed * 3.6 > 40 and math.abs(angVel.y) > 0.4 then
		Network:Send("BoostDrift", {["amount"] = angVel.y / 50})
	end
	--angVel[axis] = angVel[axis] + rad
	--angVel = vehicle:GetAngle() * angVel
	--vehicle:SetAngularVelocity(angVel)
end

function Balancing(args)
	if LocalPlayer:GetVehicle() then
		if Game:GetSetting(GameSetting.GamepadInUse) != 1 then
			local argsSend = {}
			if args.key == 38 then
				argsSend.pitch = -1
				Chat:Print("up",Color())
				Network:Send("Balance", argsSend)
			elseif args.key == 40 then
				argsSend.pitch = 1
				Chat:Print("down",Color())
				Network:Send("Balance", argsSend)
			end
		end
	end
end

Events:Subscribe("KeyDown", Balancing)


function AutonomousTest(args)
	if not LocalPlayer:InVehicle() then return end

	local sight = Physics:Raycast(LocalPlayer:GetVehicle():GetPosition()+Vector3(0,0.1,0), LocalPlayer:GetVehicle():GetAngle() * Vector3(0, 0, -1), 0, 500).distance
	Network:Send("Autonomous", {["sight"] = sight})
	-- Send sight to server

end
--Events:Subscribe("PostTick", AutonomousTest)

stuntDetector = StuntDetector()