class("Spectator")

function Spectator:__init()
	self.spect = nil
	self.pos = {}
	self.yaw = {}
	self.posAvg = nil
	self.yawAvg = nil
	self.camPos = nil
	self.playerPos = nil
	self.camAngle = nil
	self.playerAngle = nil
	self.yawDir = nil
	self.vehYaw = nil
	self.prevArgsYaw = nil

	self.hist = {}

	self.spectating = {}
	self.isSpectator = false
	self.spectatingPlayer = nil

	Network:Subscribe("Spectate", self, self.UpdatePos)
	Network:Subscribe("Spectated", self, self.Spectated)
	Events:Subscribe("CalcView", self, self.SetCamera)

	Events:Subscribe("Render", self, self.Render)

	Events:Subscribe("KeyUp", self, self.KeyUp)
end
function sgn(x)
  return x>0 and 1 or x<0 and -1 or 0
end
function Spectator:UpdatePos(args)

	if args.stop then
		-- Turn off spectator cam
		self.camPos = nil
		self.isSpectator = false
        self.spectatingPlayer = nil
		return
	end

	local latSpeed = math.abs(args.direction.x) + math.abs(args.direction.z)

	if latSpeed < 0.01 then
		args.yaw = args.yaw
	elseif latSpeed < 15 then
		args.yaw = self.prevArgsYaw or args.yaw
	else
		args.yaw = math.atan2(args.direction.x, args.direction.z) + math.pi
	end
	self.prevArgsYaw = args.yaw
	self.playerPos = args.pos
	if self.camPos == nil then
		self.camPos = args.pos
		self.direction = Vector3(0,0,0)
		if args.yaw < 0 then
			args.yaw = args.yaw + 2*math.pi
		elseif args.yaw >= 2*math.pi then
			args.yaw = args.yaw - 2*math.pi
		end
		self.camYaw = args.yaw
		self.prevPos = args.pos
		self.yawDir = 0
	else
		local v = self.playerPos - self.camPos
		self.direction = v/norm(v)


		if args.yaw < 0 then
			args.yaw = args.yaw + 2*math.pi
		elseif args.yaw >= 2*math.pi then
			args.yaw = args.yaw - 2*math.pi
		end
		if self.camYaw < 0 then
			self.camYaw = self.camYaw + 2*math.pi
		elseif self.camYaw >= 2*math.pi then
			self.camYaw = self.camYaw - 2*math.pi
		end
		--print(tostring(self.camYaw) .. " " .. tostring(args.yaw))
		if math.abs(self.camYaw - args.yaw) < math.rad(1) then
			self.yawDir = 0
		-- elseif math.abs(args.yaw-self.camYaw)<=math.pi then
		-- 	self.yawDir = sgn(args.yaw-self.camYaw)*0.002
		-- else
		-- 	self.yawDir = -sgn(args.yaw-self.camYaw)*0.002
		-- end
		elseif self.camYaw >= args.yaw then
			if self.camYaw - args.yaw >= math.pi then
				self.yawDir = 0.002
			else
				self.yawDir = -0.002
			end
		else
			if args.yaw - self.camYaw >= math.pi then
				self.yawDir = -0.002
			else
				self.yawDir = 0.002
			end
		end

		--self.yawDir = self.yawDir * (math.abs(self.camYaw - args.yaw)*1.5)

		--print(self.direction.x)
		if self.direction.x ~= self.direction.x
			or self.direction.y ~= self.direction.y
			or self.direction.z ~= self.direction.z
		then
			self.direction = Vector3(0,0,0)
		end

	end
	--if latSpeed > 10 then
		local dist = Vector3.Distance(self.camPos, self.playerPos)
		local vehDist = Vector3.Distance(args.pos, self.prevPos)
		--if dist > 2 then
			self.speed = dist/50-- + dist*dist/500--+dist*dist/1000
		--else
		--	self.speed = 0.05
		--end
	-- else
	-- 	if self.speed ~= nil and self.speed > 0 then
	-- 		self.speed = self.speed - 0.01
	-- 	else
	-- 		self.speed = 0
	-- 	end
	-- end
	--if vehDist ~= 0 then
	--	self.speed = self.speed * (vehDist/4)
	--end

	self.vehYaw = args.yaw
	self.prevPos = args.pos

	self:AddHist(self.speed)

end
function Spectator:GetAverage()
	local avg = 0--Vector3(0,0,0)
	for i, v in ipairs(self.hist) do
		avg = avg + (11-i)*v
	end
	avg = avg / (10+9+8+7+6+5+4+3+2+1)
	return avg
end
function Spectator:AddHist(val, weighted)
	local weighted = false or weighted
	if #self.hist < 10 then
		local s = #self.hist
		for i = 0, s - 1 do
			self.hist[s + 1 - i] = self.hist[s - i]
		end
	else
		for i = 0, 9 do
			self.hist[10 - i] = self.hist[9 - i]
			--print("addhist " .. tostring(10 - i) .. " " .. tostring(self.hist[10-i]))
		end
	end
	self.hist[1] = val
	--print("new val " .. tostring(val))
	--print("new avg " .. tostring(self:GetAverage()))
end
function Spectator:SetCamera()
	if self.camPos then
		--local dist = Vector3.Distance(self.camPos, self.playerPos)
		--if dist < 10 then
		--	self.speed = 0.001
		--end
		--self.speed = dist/100 + dist*dist/500
		--self.camPos = self.camPos + self.direction*self.speed
		self.camPos = self.camPos + self.direction*self:GetAverage()
		self.camYaw = self.camYaw + self.yawDir
		--print(posAvg)
		local anglePitch = -math.pi/8
		self.camYaw = self.camYaw + self.yawDir * (math.abs(self.camYaw - self.vehYaw)*1.5)
		angle = Angle(self.camYaw, anglePitch, 0)
		Camera:SetAngle(angle)
		local position = angle * Vector3(0,0,25)
		Camera:SetPosition(self.camPos + position)
		return self.isSpectator
	end
end
function Spectator:SetCamera2()
	if self.camPos then
		self.camPos = self.camPos + self.direction*self.speed
		self.camYaw = self.camYaw + self.yawDir
		--print(posAvg)
		local anglePitch = -math.pi/8
		angle = Angle(0, anglePitch, 0)
		Camera:SetAngle(angle)
		local position = angle * Vector3(0,0,25)
		Camera:SetPosition(self.camPos + position)
		return false
	end
end
function norm(v1, v2)
	v2 = v2 or v1
	return math.sqrt(Vector3.Dot(v1, v2))
end
function Spectator:Spectated(args)
	if args.stop then
		print("stopped spectating")
		for k, v in pairs(self.spectating) do
			if v.player == args.player then
				self.spectating[k] = nil
				print(args.player:GetName() .. " stopped spectating")
				break
			end
		end
		self.spectating[args.player] = nil
	else
		--self.spectating[args.player] = true
		table.insert(self.spectating, {["player"] = args.player})
		print("spectating: " .. tostring(#(self.spectating)))
	end
end
function Spectator:Render()
	local y_pos = 100
	if #self.spectating ~= 0 then
		local text = "Spectators:"
		Render:DrawText(Vector2((Render.Width - Render:GetTextWidth(text)) - 5, y_pos), text, Color(255,255,255))
		for k, v in pairs(self.spectating) do
			--print(tostring(v))
			text = v.player:GetName()
			if v.player == LocalPlayer then
				text = text .. " (you)"
			end
			y_pos = y_pos + Render:GetTextHeight(text)
			Render:DrawText(Vector2((Render.Width - Render:GetTextWidth(text)) - 5, y_pos), text, v.player:GetColor())
			--print(tostring(text))
			--Render:DrawText(Vector2())
		end
		y_pos = y_pos + 2*Render:GetTextHeight(text)
	end
	if self.isSpectator then
		local text = "Spectating " .. self.spectatingPlayer:GetName()
		if self.spectatingPlayer == LocalPlayer then
			text = text .. " (you)"
		end
		Render:DrawText(Vector2((Render.Width - Render:GetTextWidth(text)) - 5, y_pos), text, self.spectatingPlayer:GetColor())
		text = "Press L to leave"
		y_pos = y_pos + 2*Render:GetTextHeight(text)
		Render:DrawText(Vector2((Render.Width - Render:GetTextWidth(text)) - 5, y_pos), text, Color.White)
	end
end

function Spectator:KeyUp(args)
    if args.key == string.byte('L') then
    	print("L")
    	if self.isSpectator then
			print("stoprequest")
        	Network:Send("SpectateRequest", {["stop"] = true})
        	self.isSpectator = false
        	self.spectatingPlayer = nil
        end
    end
end

spectator = Spectator()