
class("Menu")

function Menu:__init()
	self.active = false

	self.window = Window.Create()
	self.window:SetSizeRel(Vector2(0.4, 0.5))
	self.window:SetPositionRel(Vector2(0.75, 0.5) - self.window:GetSizeRel()/2)
	self.window:SetVisible(self.active)
	self.window:SetTitle("JC2-MP Stunts - alpha")
	self.window:Subscribe("WindowClosed", self, self.Close)

    self.sort_dir = true
    self.sortColumn = 1

	--local base = BaseWindow.Create(self.window)

    self.tabControl = TabControl.Create( self.window )
    self.tabControl:SetDock( GwenPosition.Fill )
    self.detailLabel = nil
    self.spectateButton = nil

    self:LiveScore()
    self:LeaderBoard()
    self:Challenges()
    self:Stats()
    self:Stunts()
    self:Settings()
    self:About()

	Events:Subscribe("Render", self, self.Render)
    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)

    self:ToggleLiveScores(self.active)
    Network:Subscribe("LiveScoresResponse", self, self.MakeLiveScores)
    Network:Subscribe("LiveScoreDetails", self, self.LiveScoreDetailsRecv)
end
function Menu:SortFunction(column, a, b)
    local a_value = a:GetCellText(column)
    local b_value = b:GetCellText(column)

    self.sortColumn = column
    if column == 1 then
        a_value = tonumber(a_value)
        b_value = tonumber(b_value)
    elseif column == 3 then
        a_value = tonumber(a_value:sub(1,-2))
        b_value = tonumber(b_value:sub(1,-2))
    elseif column == 5 then
        a_value = tonumber(a_value:sub(1,-2))
        b_value = tonumber(b_value:sub(1,-2))
    end
    if self.sort_dir then
        return a_value > b_value
    else
        return a_value < b_value
    end
end

function Menu:LeaderBoard()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    local button = self.tabControl:AddPage("LeaderBoard", base)

    button:Subscribe("Press", function()
    		Network:Send("StuntsLeaderBoard")
    	end)

    local board = SortedList.Create(base)
    board:SetDock(GwenPosition.Fill)
    board:AddColumn("#", 32)
    board:AddColumn("Player")
    board:AddColumn("Session Scores")

	Network:Subscribe("StuntsLeaderBoard", function(args)
			board:Clear()
			for k, v in pairs(args.scores) do
				local row = board:AddItem(tostring(k))
				row:SetCellText(1, v.name)
				row:SetCellText(2, string.format("%.2f", v.score))
		    end
    	end)

end
function Menu:LiveScore()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    --self.window:Blur()
    self.tabControl:AddPage("Live Scores", base)


        self.listbox = SortedList.Create( base )
        self.listbox:SetDock( GwenPosition.Fill )
        self.listbox:AddColumn("Name", 128)
        self.listbox:AddColumn("Score",64)
        self.listbox:AddColumn("Vehicle", 128)
        self.listbox:AddColumn("Vehicle health", 88)
        self.listbox:AddColumn("Last Stunt", 64)
        self.listbox:AddColumn("Distance", 64)
        self.listbox:AddColumn("Location")
        self.listbox:SetSort( self, self.SortFunction )
        self.listbox:Subscribe( "SortPress",
        function(button)
            self.sort_dir = not self.sort_dir
        end)
        self.listbox:Subscribe("RowSelected", self, self.LiveScoreDetails)
        local status = BaseWindow.Create(base)
        status:SetDock( GwenPosition.Bottom )
        status:SetSize( Vector2( self.window:GetSize().x, 32 ) )
        local background = Rectangle.Create( status )
        background:SetSizeRel( Vector2( 0.5, 1.0 ) )
        background:SetDock( GwenPosition.Fill )
        background:SetColor( Color( 0, 0, 0, 100 ) )
        self.detailLabel = Label.Create(background)
        self.detailLabel:SetDock(GwenPosition.Fill)
        self.detailLabel:SetAlignment(GwenPosition.Center)
        self.detailLabel:SetText("Status")
        self.spectateButton = Button.Create(status)
        self.spectateButton:SetDock(GwenPosition.Right)
        self.spectateButton:Subscribe("Press", self, self.SpectateRequest)

        --self.spectateButton:SetColorHighlight()
        self.spectateButton:SetText("Spectate")
        self.spectateButton:SetTextColor(Color(255,0,0))
        self.spectateButton:SetEnabled(false)
end
function Menu:Challenges()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    self.tabControl:AddPage("Challenges", base)

    local content = Label.Create(base)
    content:SetDock(GwenPosition.Fill)
    content:SetText("\n\nChallenges not implemented yet")
end
function Menu:Stats()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    local button = self.tabControl:AddPage("My Stats", base)

    local scrollControl = ScrollControl.Create(base)
    scrollControl:SetDock(GwenPosition.Fill)
    scrollControl:SetScrollable(false, true)

    local content = Label.Create(scrollControl)
    content:SetDock(GwenPosition.Fill)
    button:Subscribe("Press", function()
             content:SetText("\n\n Loading stats..")
             Network:Send("StuntsStats")
        end)
    Network:Subscribe("StuntsStats", function(args)
    		local stats = "\n\n"
    		if args.prevSession ~= nil then
	    		stats = stats .. "*Previous Session:\n"..
	    						" Vehicle:\n  " ..  Vehicle.GetNameByModelId(args.prevSession.vehicleID) .. " " ..
	    						string.format("%.2f",args.prevSession.total) .. " points\n" ..
	    						" Stunts:\n"
	    		for k, v in pairs(args.prevSession.scores) do
	    			stats = stats .. "  " .. k .. " -> " .. string.format("%.2f", v) .. "\n"
	    		end
	    		stats = stats .. "\n"
    		end
    		if args.records ~= nil then
    			stats = stats .. "*Records:\n"
    			for k, v in pairs(args.records) do
    				stats = stats .. " " .. Vehicle.GetNameByModelId(k) .. " -> " .. string.format("%.2f", v) .. "\n"
    			end
    			stats = stats .. "\n"
    		end
    		if args.global ~= nil then
    			stats = stats .. "*Global: " .. string.format("%.2f", args.global.total) .. " points\n"
    			for k, v in pairs(args.global.scores) do
    				stats = stats .. " Vehicle: " .. Vehicle.GetNameByModelId(k) .. "\n"
    				for stunt, stuntScore in pairs(v) do
    					stats = stats .. "  " .. stunt .. " -> " .. string.format("%.2f", stuntScore) .. "\n"
    				end
    				stats = stats .. "\n"
    			end
    		end
    		content:SetText(stats)
    	end)

end
function Menu:Stunts()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    self.tabControl:AddPage("Stunts", base)

    local content = Label.Create(base)
    content:SetDock(GwenPosition.Fill)
    content:SetText("Currently implemented stunts (most of them still need some tweaks):\n\n" ..
    	"* car\n" ..
	"- airtime\n" ..
	"- drifting\n" ..
	"- speeding\n" ..
	"- 2 wheels\n" ..
	"- swimming\n" ..
	"- reversing\n" ..
	"- spinning\n" ..
	"- front/back flip\n" ..
	"- roll\n\n" ..
"* plane\n" ..
	"- low flyer\n" ..
	"- upside down\n" ..
	"- flying backwards\n" ..
	"- flying slow\n" ..
	"- overbanking\n" ..
	"- swimming\n" ..
	"- limbo\n" ..
	"- roll\n\n" ..
"* bike\n" ..
	"- back/front wheelie\n" ..
	"- tilting\n\n" ..
"* boat\n" ..
	"- airtime\n" ..
	"- landslide + water re-entry bonus\n" ..
	"- diving\n\n" ..
"* heli\n" ..
	"none")
end
function Menu:Settings()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    self.tabControl:AddPage("Settings", base)

    local table = Table.Create(base)
    --table:SetDock(GwenPosition.Fill)
    table:SetColumnCount(3)

    -- Stuntdetector ON/OFF
    local stuntDetectorWindow = BaseWindow.Create()
    --stuntDetectorWindow:SetDock(GwenPosition.Fill)
    stuntDetectorWindow:SetSize(Vector2(200,32))
    local stuntDetector = LabeledCheckBox.Create(stuntDetectorWindow)
    stuntDetector:SetDock(GwenPosition.Top)
    stuntDetector:GetLabel():SetText("on/off")
    stuntDetector:GetCheckBox():Toggle()

    -- ADD TO TABLE --
    local tableRow = TableRow.Create()
    --tableRow:SetDock(GwenPosition.Fill)
    tableRow:SetColumnCount(3)
    tableRow:SetCellText(0, "Stunt Detector:")
    tableRow:SetCellContents(1, stuntDetectorWindow)
    tableRow:SetCellText(2, "Turn stunts mode on/off")
    table:AddRow(tableRow)


    -- RENDERING --
    local renderWindow = BaseWindow.Create()
    --renderWindow:SetDock(GwenPosition.Fill)
    renderWindow:SetSize(Vector2(200,84))
    -- Score rendering
    local rendering = RadioButtonController.Create(renderWindow)
    rendering:SetDock(GwenPosition.Fill)

    local options = {"off","subtile","obvious"}
    for i, v in ipairs(options) do
        local option = rendering:AddOption(v)
        --option:SetDock(GwenPosition.Left)
        --option:SetSize(Vector2(100, 32))
        if i == 2 then
            option:Select()
        end
    end

    -- Live Scores
    local liveScores = LabeledCheckBox.Create(renderWindow)
    liveScores:SetDock(GwenPosition.Bottom)
    liveScores:GetLabel():SetText("Show Live Scores")


    -- ADD RENDERING TO TABLE --
    tableRow = TableRow.Create()
    tableRow:SetDock(GwenPosition.Fill)
    tableRow:SetColumnCount(3)
    tableRow:SetCellText(0, "Score Rendering:")
    tableRow:SetCellContents(1, renderWindow)
    tableRow:SetTextColor(Color(100,100,200))
    tableRow:SetCellText(2, "Show no stunts/score while doing stunts\n\nShow stunts/scores\n\nShow large score popups\n\nRender live scores ingame")
    table:AddRow(tableRow)



    table:SetSize(Vector2(self.window:GetSize().x, 200))
    table:SetColumnWidth(0, 128)
    table:SetColumnWidth(1, 200)
    -- On/off

    local label = Label.Create(base)
    label:SetDock(GwenPosition.Bottom)
    label:SetTextColor(Color(200,0,0))
    label:SetText("NOT FUNCTIONAL YET")
end
function Menu:About()
    local base = BaseWindow.Create(self.window)
    base:SetDock(GwenPosition.Fill)
    self.tabControl:AddPage("About", base)
    local scrollControl = ScrollControl.Create(base)
    scrollControl:SetDock(GwenPosition.Fill)
    scrollControl:SetScrollable(false, true)

    local title = Label.Create(scrollControl)
    --title:SetDock(GwenPosition.Top)
    title:SetTextColor(Color(150,80,10))
    title:SetText("JC2-MP Stunts alpha - by Bradiex")
    title:SizeToContents()

    local content = Label.Create(scrollControl)
    --content:SetDock(GwenPosition.Fill)
    --content:SetTextColor(Color(200,200,100))
    content:SetText("\n\nGet points for making stunts with your vehicle.\n\n"..
                    "Each score session is bound to ONE vehicle so if you LEAVE/CHANGE your vehicle or it EXPLODES,\nyour session will end.\n"..
                    "\n\n"..
                    "* Live Scores:\nView the live scores of the best stuntdrivers/pilots.\n\n"..
                    "* Challenges:\nTake part of some challenges.\n\n"..
                    "* My Stats:\nView your latest session score and your overal scores and milestones.\n\n"..
                    "* Settings:\nConfigure JC2-MP Stunts to your needs.")
    content:SizeToContents()
    local content2 = Label.Create(scrollControl)
    content2:SetTextColor(Color(100,200,10))
    content2:SetText("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nSpecial thanks to the JC2-MP dev team for making this possible!")
    content2:SizeToContents()
    local bottomWindow = BaseWindow.Create(base)
    bottomWindow:SetDock(GwenPosition.Bottom)
    bottomWindow:SetSize(Vector2(self.window:GetSize().x, 64))
    local feedBackTitle = Label.Create(bottomWindow)
    feedBackTitle:SetDock(GwenPosition.Top)
    feedBackTitle:SetText("Got feedback?")
    self.feedBackBox = TextBoxMultiline.Create(bottomWindow)
    self.feedBackBox:SetTextColor(Color(0,0,0))
    self.feedBackBox:SetDock(GwenPosition.Fill)
    self.sendFeedBack = Button.Create(bottomWindow)
    self.sendFeedBack:SetDock(GwenPosition.Right)
    self.sendFeedBack:SetText("Send")
    self.feedBackLabel = Label.Create(bottomWindow)
    self.feedBackLabel:SetDock(GwenPosition.Fill)
    self.feedBackLabel:SetAlignment(GwenPosition.Center)
    self.feedBackLabel:SetTextColor(Color(0,200,0))
    self.sendFeedBack:Subscribe("Press", function()
            local feedback = self.feedBackBox:GetText():sub(1,1000)
            Network:Send("FeedBack", {["feedback"] = feedback})
            self.feedBackBox:SetText("")
            self.feedBackBox:Hide()
            self.feedBackLabel:SetText("Thanks for your feedback, " .. LocalPlayer:GetName() .. "!")
            self.sendFeedBack:Hide()
        end)


end
function Menu:LiveScoreDetails()
    local selectedItem = self.listbox:GetSelectedRow()
	if selectedItem ~= nil then
        local playerID = selectedItem:GetDataNumber("playerID")
        Network:Send("LiveScoreDetails", {["playerID"] = playerID})
        print("send detail request")
    end
end

function Menu:LiveScoreDetailsRecv(args)
    print("received details")
    local player = args.player
    self.detailLabel:SetText("Player: " .. tostring(player:GetId()) .. " " .. player:GetName())
    self.selectedPlayerID = player:GetId()
    self.selectedPlayer = player
    --self.spectateButton:SetEnabled(true)
end

function Menu:SpectateRequest()
        local playerID = self.selectedPlayerID
        Network:Send("SpectateRequest", {["playerID"] = playerID})
        spectator.isSpectator = true
        spectator.spectatingPlayer = self.selectedPlayer
        print("spectate request send")

end

function Menu:MakeLiveScores(args)
    --print("ok received")
    self.listbox:Clear()
    if #args == 0 then
        self:AddEmptyLiveScore()
        return
    end
    for i, v in ipairs(args) do
        --print(i .. v)
        self:AddLiveScore(v)
    end
    self.listbox:Sort(self.sortColumn)
end
function Menu:AddLiveScore(args)
    local row = self.listbox:AddItem(args.playerName)
        row:SetDataNumber("playerID", args.playerID)
        row:SetCellText(1, args.score)
        row:SetCellText(2, args.vehicle)
        row:SetCellText(3, args.vehicleHealth)
        row:SetCellText(4, args.lastStunt)
        row:SetCellText(5, args.distance)
        row:SetCellText(6, args.location)
end
function Menu:AddEmptyLiveScore()
    local row = self.listbox:AddItem("no stunters")
end
function Menu:ToggleLiveScores()
    if self.active then
        self.timer = Timer()
        self.liveScoreEvent = Events:Subscribe("PostTick", function()
            if self.timer:GetSeconds() > 2 then
                self.timer:Restart()
                Network:Send("RequestLiveScores")
            end
            end)
        Network:Send("RequestLiveScores")
    else
        self.timer = nil
        if self.liveScoreEvent then
            Events:Unsubscribe(self.liveScoreEvent)
        end
    end
end
function Menu:GetActive()
    return self.active
end
function Menu:SetActive( active )
    if self.active ~= active then
        if active == true and LocalPlayer:GetWorld() ~= DefaultWorld then
            Chat:Print("You are not in the main world!", Color( 255, 0, 0 ))
            return
        end
        if active == true and self.feedBackBox ~= nil and self.sendFeedBack ~= nil then
        	self.feedBackBox:Show()
        	self.sendFeedBack:Show()
        	self.feedBackLabel:SetText("")
        end
        if active == true then
            Network:Send("StuntsLeaderBoard")
            Network:Send("StuntsStats")
        end

        self.active = active
        Mouse:SetVisible( self.active )
        self:ToggleLiveScores()
    end
end

function Menu:Render()
    local is_visible = self.active and (Game:GetState() == GUIState.Game)

    if self.window:GetVisible() ~= is_visible then
        self.window:SetVisible(is_visible)
    end

    if self.active then
        Mouse:SetVisible(true)
    end
end

function Menu:KeyUp( args )
    if args.key == string.byte('K') then
        self:SetActive(not self:GetActive())
    end
end

function Menu:LocalPlayerInput( args )
    if self.active and Game:GetState() == GUIState.Game then
        return false
    end
end

function Menu:Close(args)
    self:SetActive(false)
end

menu = Menu()