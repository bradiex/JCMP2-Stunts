class("StuntPark")

function StuntPark:__init()
	self.basePos = Vector3(0, 400, 0)
	self.baseAngle = Angle(0, 0, 0)

	self.parts = {}

	self:Build()
	self.timer = Timer()
	self.mainTimer = Timer()
	self.ticks = 0

	Events:Subscribe("ModuleUnload", self, self.CleanUp)
	Events:Subscribe("PostTick", self, self.rotate)
end

function StuntPark:SpawnPart(partName, pos, angle)
	local part = Parts[partName]
	if part == nil then return end
	local pos = pos or Vector3.Zero
	local angle = angle or self.baseAngle
	local obj = StaticObject.Create({
	                model = part.archive .. '/' .. part.lod,
	                collision = part.archive .. '/' .. part.pfx,
	                position = self.basePos + pos,
	                angle = angle,
	                fixed = false
	        })
	table.insert(self.parts, obj)
	return obj
end

function StuntPark:Build()
	self:BuildBase()
end

function StuntPark:CleanUp()
	for i, v in ipairs(self.parts) do
		v:Remove()
	end
	self.parts = {}
end

function StuntPark:BuildBase()
	self:SpawnPart("balloon")
	self.windmill = self:SpawnPart("windmillb", Vector3(70, -180, 70), Angle(0, 0, 0))
	--self.blimp = self:SpawnPart("blimp", Vector3(0, -100, 0), Angle(math.pi/2, 0, 0))
	--self:SpawnPart("road1")
	self.up = 1
end

function StuntPark:rotate()
	--if self.mainTimer:GetSeconds() < 2 then return end
	if self.timer:GetSeconds() >= 0.01 then
		self.timer:Restart()

		if self.windmill == nil then return end
		local newAngle = self.windmill:GetAngle()
		newAngle.roll = newAngle.roll - 0.01
		--print(newAngle.roll)
		self.windmill:SetAngle(newAngle)

		if self.blimp == nil then return end

		newAngle = self.blimp:GetAngle()
		newAngle.yaw = newAngle.yaw - 0.03
		--print(newAngle.roll)
		self.blimp:SetAngle(newAngle)
		if self.blimp:GetPosition().y >= 600 then
			self.up = -4
		elseif self.blimp:GetPosition().y <= 200 then
			self.up = 4
		end

		self.blimp:SetPosition(self.blimp:GetPosition() + self.blimp:GetAngle() * Vector3(0,self.up,0.5))
	end
end

stuntPark = StuntPark()