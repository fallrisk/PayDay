
-- Utility Functions
--------------------

local function HasValue(val, tab)
	for i, v in ipairs(tab) do
		if v == val then
			return true
		end
	end
	return false
end

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Match Class
--------------

local Match = {}
Match.__index = Match

function Match:New(maxRoll, minRoll)
	local o = {}
	setmetatable(o, Match)
	o.maxRoll = maxRoll or 100
	o.minRoll = minRoll or 1
	o.gamblers = {}  -- gamblers["gambler name"] = roll
	o.phase = "join"
	o.lowRoll = nil
	o.lowGambler = nil
	o.highRoll = nil
	o.highGambler = nil
	o.highTieGamblers = {}  -- highTieGamblers["gambler name"] = roll
	o.lowTieGamblers = {}  -- lowTieGamblers["gambler name"] = roll
	return o
end

function Match:AddGambler(name)
	-- This is following the idea in section 11.5 of "Programming in LUA 2nd ed.".
	if self.phase ~= "join" then return end
	self.gamblers[name] = true
end

function Match:RemoveGambler(name)
	if self.phase ~= "join" then return end
	self.gamblers[name] = nil  -- setting to nil allows for garbage collection
end

function Match:GetGamblers()
	local gamblers = {}
	for k in pairs(self.gamblers) do
		table.insert(gamblers, k)
	end
	return gamblers
end

function Match:Start()
	if self.phase ~= "join" then return false end
	g = self:GetGamblers()
	if #g < 2 then return false end
	self.phase = "roll"
	return true
end

function Match:AddRoll(name, roll)
	if self.phase == "roll" then
		if self.phase ~= "roll" then return end
		if roll < self.minRoll then return end
		if roll > self.maxRoll then return end
		if self.gamblers[name] == nil then return end
		self.gamblers[name] = roll
		if #self:GetWaitingList() == 0 then
			if self:_IsHighTie(self.gamblers) then
				self.phase = "high tie"
			elseif self:_IsLowTie(self.gamblers) then
				self.phase = "low tie"
			else
				self.phase = "complete"
			end
		end
	elseif self.phase == "high tie" then
		if self.highTieGamblers[name] == nil then return end
		self.highTieGamblers[name] = roll
		if #self:GetWaitingList() == 0 then
			if self:_IsHighTie(self.highTieGamblers) then
				self.phase = "high tie"  -- repeating high ties
				-- print("there is still a high tie")
			elseif self:_IsLowTie(self.gamblers) then
				self.phase = "low tie"
			else
				self.phase = "complete"
			end
		end
	elseif self.phase == "low tie" then
		if self.lowTieGamblers[name] == nil then return end
		self.lowTieGamblers[name] = roll		
		if #self:GetWaitingList() == 0 then
			if self:_IsLowTie(self.lowTieGamblers) then
				self.phase = "low tie"  -- repeating low ties
			else
				self.phase = "complete"
			end
		end
	else
		return
	end
end

function Match:GetWaitingList()
	if not HasValue(self.phase, {"roll", "high tie", "low tie"}) then return nil end
	local waitList = {}
	if self.phase == "roll" then
		for k in pairs(self.gamblers) do
			if type(self.gamblers[k]) ~= "number" then
				table.insert(waitList, k)
			end
		end
	elseif self.phase == "high tie" then
		for k in pairs(self.highTieGamblers) do
			if type(self.highTieGamblers[k]) ~= "number" then
				table.insert(waitList, k)
			end
		end
	elseif self.phase == "low tie" then
		for k in pairs(self.lowTieGamblers) do
			if type(self.lowTieGamblers[k]) ~= "number" then
				table.insert(waitList, k)
			end
		end
	end

	return waitList
end

function Match:_IsHighTie(tab)
	-- you must ensure that we are not waiting for any more rolls before checking for ties
	-- otherwise you are modfying the participants in the tie
	local high = self.minRoll
	local highGambler = nil
	-- table of gamblers and their rolls who are part of the high tie
	-- a method to generate a list of gamblers part of the tie
	local highTieGamblers = {}
	local tabCopy = shallowcopy(tab)
	-- find the highest roll in the table tab
	for k in pairs(tabCopy) do
		if tabCopy[k] > high then
			high = tabCopy[k]
			highGambler = k
		end
	end
	-- print("the high roll is", high)
	-- print("the high roller is", highGambler)
	-- check to see if there was a tie
	for k in pairs(tabCopy) do
		if tabCopy[k] == high and k ~= highGambler then
			highTieGamblers[k] = true
		end
	end
	-- in the event of a tie
	if next(highTieGamblers) then -- are there any elements in highTieGamblers, meaning there was a tie
		highTieGamblers[highGambler] = true
		self.highTieGamblers = highTieGamblers
		if self.highRoll == nil then
			self.highRoll = high
		end		
		-- print("there is a high tie")
		return true
	end
	-- in the event of no ties
	self.highTieGamblers = {}
	if self.highRoll == nil then
		self.highRoll = high
	end
	self.highGambler = highGambler
	return false
end

function Match:_IsLowTie(tab)
	-- you must ensure that we are not waiting for any more rolls before checking for ties
	-- otherwise you are modfying the participants in the tie
	local low = self.maxRoll
	local lowGambler = nil
	-- table of gamblers and their rolls who are part of the low tie
	-- a method to generate a list of gamblers part of the tie
	local lowTieGamblers = {}
	local tabCopy = shallowcopy(tab)
	-- find the lowest roll in the table tab
	for k in pairs(tabCopy) do
		if tabCopy[k] < low then
			low = tabCopy[k]
			lowGambler = k
		end
	end
	-- print("the low roll is", low)
	-- print("the low roller is", lowGambler)
	-- check to see if there was a tie
	for k in pairs(tabCopy) do
		if tabCopy[k] == low and k ~= lowGambler then
			lowTieGamblers[k] = true
		end
	end
	-- in the event of a tie
	if next(lowTieGamblers) then -- are there any elements in lowTieGamblers, meaning there was a tie
		lowTieGamblers[lowGambler] = true
		self.lowTieGamblers = lowTieGamblers
		if self.lowRoll == nil then
			self.lowRoll = low
		end		
		-- print("there is a low tie")
		return true
	end
	-- in the event of no ties
	self.lowTieGamblers = {}
	-- print("low", low)
	if self.lowRoll == nil then
		self.lowRoll = low
	end
	self.lowGambler = lowGambler
	return false
end

function Match:Check()
	-- get the high
	local high = self.minRoll
	for k in pairs(self.gamblers) do
		if self.gamblers[k] > high then
			high = self.gamblers[k]
			self.highRoll = high
			self.highGambler = k
		end
	end
	-- check for any high ties
	local isHighTie = false
	for k in pairs(self.gamblers) do
		if self.gamblers[k] == high and k ~= self.highGambler then
			self.highTieRolls[k] = true
			isHighTie = true
		end
	end
	if isHighTie then
		self.highTieRolls[self.highGambler] = true
		self.phase = "high tie"
		self.highRoll = self.minRoll
		self.highGambler = nil
		return
	end
	-- get the low
	local low = self.maxRoll
	for k in pairs(self.gamblers) do
		if self.gamblers[k] < low then
			low = self.gamblers[k]
			self.lowRoll = low
			self.lowGambler = k
		end
	end
	-- check for any low ties
	for k in pairs(self.gamblers) do
		if self.gamblers[k] == low and k ~= self.lowGambler then
			self.phase = "low tie"
			return
		end
	end
	-- all ties are done if we made it here
	self.phase = "complete"
end

-- Stats Class
--------------

Stats = {}


-- Module Exporting
meowth = {}
meowth.Match = Match
