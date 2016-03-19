
StuntFactory = {}

-- GENERAL STUNTS --

StuntFactory.flipping = {
	["text"] = "FLIPPING",
	["description"] = "Flipping",
	["color"] = Color(200, 200, 184, 200),
	["vehTypes"] = {"car"}
}

StuntFactory.spinning = {
	["text"] = "SPINNING",
	["description"] = "Spinning",
	["color"] = Color(200, 200, 184, 200),
	["vehTypes"] = {"car"}
}

StuntFactory.rolling = {
	["text"] = "ROLLING",
	["description"] = "Flipping",
	["color"] = Color(200, 245, 184, 200),
	["vehTypes"] = {"car"}
}

-- SPECIAL EXCLUSIVES --

StuntFactory.awesome = {
	["text"] = "BEING AWESOME",
	["description"] = "Being awesome",
	["color"] = Color(250, 150, 0, 200),
	["vehTypes"] = {"car"}
}

-- GROUND VEHICLE EXCLUSIVES --

StuntFactory.air = {
	["text"] = "AIRTIME",
	["description"] = "Try to fly",
	["color"] = Color(0, 200, 200, 200),
	["vehTypes"] = {"car", "bike"},
	["detect"] = function(state)
			if state.height > 100 then
				return 50 * state.height
			end
		end
}

StuntFactory.speed = {
	["text"] = "SPEEDING",
	["description"] = "Put your pedal to the limit",
	["color"] = Color(200, 0, 200, 200),
	["vehTypes"] = {"car", "bike"}
}

StuntFactory.swimming = {
	["text"] = "SWIMMING",
	["description"] = "Put your pedal to the limit",
	["color"] = Color(0, 50, 200, 200),
	["vehTypes"] = {"car", "bike"}
}

-- CAR VEHICLE EXCLUSIVES --

StuntFactory.drift = {
	["text"] = "DRIFT",
	["description"] = "Drifting",
	["color"] = Color(200, 200, 0, 200),
	["vehTypes"] = {"car"}
}

StuntFactory.twowheels = {
	["text"] = "TWO WHEELS",
	["description"] = "You obviously don't need 4 wheels",
	["color"] = Color(100, 200, 100, 200),
	["vehTypes"] = {"car"}
}

-- BIKE VEHICLE EXCLUSIVES

StuntFactory.wheelie = {
	["text"] = "WHEELIE",
	["description"] = "Perform a wheelie",
	["color"] = Color(100, 200, 100, 200),
	["vehTypes"] = {"bike"}
}

StuntFactory.fwheelie = {
	["text"] = "FRONT WHEELIE",
	["description"] = "Perform a front wheelie",
	["color"] = Color(100, 200, 100, 200),
	["vehTypes"] = {"bike"}
}

StuntFactory.biketilt = {
	["text"] = "TILTING",
	["description"] = "Tilt your bike as steep as possible",
	["color"] = Color(100, 200, 100, 200),
	["vehTypes"] = {"bike"}
}

-- AIR VEHICLE EXCLUSIVES --

StuntFactory.lowflyer = {
	["text"] = "LOW FLYER",
	["description"] = "Fly as low as possible",
	["color"] = Color(0, 200, 200, 200),
	["vehTypes"] = {"plane"}
}

StuntFactory.upside = {
	["text"] = "UPSIDE DOWN",
	["description"] = "Fly upside down",
	["color"] = Color(200, 100, 0, 200),
	["vehTypes"] = {"plane"}
}

StuntFactory.flyback = {
	["text"] = "FLYING BACKWARDS",
	["description"] = "Try to fly backwards",
	["color"] = Color(100, 200, 0, 200),
	["vehTypes"] = {"plane"}
}

StuntFactory.flyslow = {
	["text"] = "FLYING SLOW",
	["description"] = "Fly as slow as possible",
	["color"] = Color(100, 200, 0, 200),
	["vehTypes"] = {"plane"}
}

StuntFactory.overbank = {
	["text"] = "OVERBANKING",
	["description"] = "Overbanking.",
	["color"] = Color(100, 200, 100, 200),
	["vehTypes"] = {"plane"}
}

StuntFactory.limbo = {
	["text"] = "LIMBO",
	["description"] = "Fly under things",
	["color"] = Color(255, 255, 255, 200),
	["vehTypes"] = {"plane"}
}

-- WATER VEHICLES EXCLUSIVES --

StuntFactory.boatslide = {
	["text"] = "BOAT SLIDING",
	["description"] = "Slide your boat over dry land",
	["color"] = Color(255, 255, 255, 200),
	["vehTypes"] = {"boat"}
}

StuntFactory.waterreentry = {
	["text"] = "WATER RE-ENTRY",
	["description"] = "Re-enter the water",
	["color"] = Color(255, 255, 255, 200),
	["vehTypes"] = {"boat"}
}

StuntFactory.diving = {
	["text"] = "DIVING",
	["description"] = "Diving",
	["color"] = Color(255, 255, 255, 200),
	["vehTypes"] = {"boat"}
}