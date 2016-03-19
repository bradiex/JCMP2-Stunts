
class("MyCamera")

-- Configurable camera (TODO)

function MyCamera:__init()
	self.event = nil
	--self:Toggle()
	Events:Subscribe("CharPress", self, self.CharPress)
end

-- Topview camera
function MyCamera:SetTopView()
	--if self.on then
	angle = Angle(0, -math.pi/2, 0)
	Camera:SetAngle(angle)
	local position = angle * Vector3(0,0,100)
	Camera:SetPosition(LocalPlayer:GetPosition() + position)
	return true
	--end
end



function MyCamera:Toggle()
	local args = {}
	-- Make sure we have no more than one function connected to our view
	--print(tostring(self.event))
	if self.event then
		Events:Unsubscribe(self.event)
		self.event = nil
	end
	if self.on then
		self.on = false
		args.topview = false
		--Events:Unsubscribe(self.event)
	else
		-- Currently only topview supported
		self.event = Events:Subscribe("CalcView", self, self.SetTopView)
		self.on = true
		args.topview = true
	end
	-- Notice the score renderer
	Events:Fire("CameraChange", args)
end

function MyCamera:CharPress(args)
	if args.character == "m" then
		self:Toggle()
	end
end

myCamera = MyCamera()

--Foo = function(args)
	--Input:SetValue(Action.TurnLeft, 1)
	--return
--end
 
--Events:Subscribe("InputPoll", Foo)

