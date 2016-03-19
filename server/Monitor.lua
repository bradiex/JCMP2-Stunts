
class("Monitor")

function Monitor:__init()
	self.logFile = "scorelog.txt"
	local file = io.open(self.logFile,"r")
	if file == nil then
		file = io.open(self.logFile,"w")
	end
	file:close()

	self.scores = ""
	self.counter = 0

end

function Monitor:AddScore(score)
	self.scores = self.scores .. score .. "\n"
	self.counter = self.counter + 1

	if self.counter >= 10 then
		local file = io.open(self.logFile,"a")
		file:write(self.scores)
		file:close()
		self.scores = ""
		self.counter = 0
	end
end

--monitor = Monitor()