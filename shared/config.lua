
config = {
	-- BOOSTING
	-- 0: ignore stunts when boosting a car
	-- 1: special boost stunts when boosting a car
	["boost"] = 1,
	-- 0: no boat boost (suggested when you're already using a boost script)
	-- 1: enable Stunts' boat boost
	["boostBoat"] = 1,

	-- STUNTS
	["stunts"] = {
		-- DEFAULT STUNTS
		-- PLEASE DO NOT DELETE THESE UNLESS YOU REMOVE THEIR IMPLEMENTATION
		["default"] = {
			["drift"]	= {["text"] = "DRIFT"},
			["donut"]	= {["text"] = "DONUT"},
			["air"]		= {["text"] = "AIRTIME"},
			["speed"]	= {["text"] = "SPEED"}
		},

		-- USER-DEFINED STUNTS
		-- These are really simple stunts but easy to configure
		-- params
		["userDefined"] = {

		-- EXAMPLE
		-- ["highFrontFlip"] = {["text"] = "HIGH FRONT FLIP",
		--							["trigger"] = {
		--								["height"] = ">100",
		--								["rotation"] = "pitchFront"
		--						},
		--						["score"] = "height*0.1"}
		},


	},

	["messages"] = {
		[0] = {"wow such points","such amaze","DAT SCORE","very le"},
		[100] = {"very le"},
		[1000] = {"such amaze!",
				  "wow"},
		[5000] = {"GREAT!"},
		[10000] = {"SPECTACULAR!"}
	},

	-- SERVER

	-- Save scores to db
	-- 0: don't save any scores
	-- 1: save to default sql-lite db
	-- 2: save to superfast noSQL db (suggested)
	["saveDB"] = 0,

	-- Database configs
	["nosql"] = {},


}