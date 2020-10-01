
-- This is equivalent to WoW XML calling <Script file="meowth.lua"/>
-- which is why I am using it instead of require/module.
dofile("meowth.lua")

local function PrintGamblers(match)
	local g = match:GetGamblers()
	for i = 1, #g do
		print(" ", g[i])
	end
end

local function PrintArray(tab)
	for i = 1, #tab do
		print(tab[i])
	end
end

local function HasValue(val, tab)
	for i, v in ipairs(tab) do
		if v == val then
			return true
		end
	end
	return false
end

local function CompareArrays(a, b)
	-- Make sure that all the elements in a are in b, each element you find remove it
	-- then check to make sure there are no elements left in b.
	local diff = {}
	-- print(#a, #b)
	for i, ele in ipairs(a) do
		if not HasValue(ele, b) then
			-- print("b does not have", ele)
			table.insert(diff, ele)
		end
	end
	for i, ele in ipairs(b) do
		if not HasValue(ele, a) then
			-- print("a does not have", ele)
			table.insert(diff, ele)
		end
	end
	if #diff == 0 then
		return true
	end
	return false
end

local function TestMatchDefaultMaxRollMinRoll()
	print("\ntesting match default minRoll and maxRoll")
	local a = meowth.Match:New(100, 10)
	assert(a.maxRoll == 100, "a maxRoll is not 100")
	assert(a.minRoll == 10, "a minRoll is not 10")
	local b = meowth.Match:New(50)
	assert(b.maxRoll == 50, "b maxRoll is not 50")
	local c = meowth.Match:New()
	assert(c.maxRoll == 100, "c maxRoll is not 100")
	assert(c.minRoll == 1, "c minRoll is not 1")
end

local function TestMatchAddRemove()
	print("\ntesting match add and remove gamblers")
	local a = meowth.Match:New(100, 10)
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Squirtle")  -- test that we do not allow duplicates
	assert(CompareArrays({"Squirtle", "Charmander", "Bulbasaur"}, a:GetGamblers()), "the gamblers do not match")
	a:RemoveGambler("Charmander")
	assert(CompareArrays({"Squirtle", "Bulbasaur"}, a:GetGamblers()), "the gamblers do not match")
end

local function TestMatchStart()
	print("\ntesting match start")
	local a = meowth.Match:New(100, 10)
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	assert(a.phase == "join", "phase is not \"join\" at construction")
	assert(a:Start(), "start did not return true")
	assert(a.phase == "roll", "phase is not \"roll\" once start is called")
	local b = meowth.Match:New(100)
	b:AddGambler("Squirtle")
	assert(b:Start() == false, "start did not fail with only 1 gambler")
end

local function TestMatchAddRoll()
	print("\ntesting match add roll")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:Start()
	a:AddRoll("Squirtle", 56)
	a:AddRoll("Gengar", 15)
	a:AddRoll("Charmander", 24)
	a:AddRoll("Bulbasaur", 1)
	assert(a.phase == "complete", "the phase should be complete at this point")
	local x = a.gamblers
	assert(a.gamblers["Squirtle"] == 56, "Squirtle has the wrong roll")
	assert(a.gamblers["Charmander"] == 24, "Charmander has the wrong roll")
	assert(a.gamblers["Bulbasaur"] == 1, "Bulbasaur has the wrong roll")
	assert(a.gamblers["Gengar"] == nil, "Gengar should not be in the gamblers list")
	assert(a.highRoll == 56, "the high roll should be 56")
	assert(a.highGambler == "Squirtle", "the high gambler should be Squirtle")
	assert(a.lowRoll == 1, "the low roll should be 1")
	assert(a.lowGambler == "Bulbasaur", "the low gambler should be Bulbasaur")
end

local function TestMatchMinMaxRoll()
	print("\ntesting match min roll and max roll submissions")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:Start()
	-- test that rolls below min roll are ignored
	a:AddRoll("Squirtle", -1)
	assert(CompareArrays({"Squirtle", "Charmander", "Bulbasaur"}, a:GetWaitingList()), "we should still be waiting on Squirtle")
	a:AddRoll("Squirtle", 0)
	assert(CompareArrays({"Squirtle", "Charmander", "Bulbasaur"}, a:GetWaitingList()), "we should still be waiting on Squirtle")
	a:AddRoll("Squirtle", 1)
	assert(CompareArrays({"Charmander", "Bulbasaur"}, a:GetWaitingList()), "we should not be waiting on Squirtle")
	-- test the rolls above max roll are ignored
	a:AddRoll("Charmander", 100)
	a:AddRoll("Bulbasaur", 101)
	assert(CompareArrays({"Bulbasaur"}, a:GetWaitingList()), "we should still be waiting on Bulbasaur")
end

local function TestMatchWaiting()
	print("\ntesting match GetWaiting")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:Start()
	a:AddRoll("Squirtle", 56)
	a:AddRoll("Charmander", 24)
	local wl = a:GetWaitingList()
	assert(#wl == 1, "the waiting list should be only 1")
	assert(wl[1] == "Bulbasaur", "the gambler you are waiting on should be Bulbasaur")
	local b = meowth.Match:New()
	b:AddGambler("Squirtle")
	b:AddGambler("Charmander")
	b:AddGambler("Bulbasaur")
	assert(b:GetWaitingList() == nil, "waiting list should return nil if you haven't started the match")
end

local function TestMatchCheckComplete()
	print("\ntesting match check complete")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 79)
	a:AddRoll("Charmander", 42)
	a:AddRoll("Bulbasaur", 7)
	a:AddRoll("Gengar", 63)
	assert(a.phase == "complete", "the phase should be \"complete\" once all rolls are submitted and no ties")
end

local function TestMatchCheckHighTie()
	print("\ntesting match check high tie")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 79)
	a:AddRoll("Charmander", 79)
	a:AddRoll("Bulbasaur", 7)
	a:AddRoll("Gengar", 42)
	assert(a.phase == "high tie", "the phase should be \"high tie\" once all rolls are submitted and there is a high tie") 
	assert(CompareArrays({"Squirtle", "Charmander"}, a:GetWaitingList()), "we should be waiting for Squirtle and Charmander")
	a:AddRoll("Charmander", 44)
	assert(a.phase == "high tie", "the phase should be \"high tie\" when still waiting for a high tie roll")
	assert(CompareArrays({"Squirtle"}, a:GetWaitingList()), "we should only be waiting for Squirtle")
	a:AddRoll("Squirtle", 23)
	assert(a.phase == "complete", "should be in phase complete since we submitted high tie rolls")
	assert(a.highGambler == "Charmander", "the high gambler should be Charmander")
	assert(a.highRoll == 79, "the high roll should be 79")
	assert(a.lowGambler == "Bulbasaur", "the low roll gambler should be Bulbasaur")
	assert(a.lowRoll == 7, "the low roll should be 7")
end

local function TestMatchIgnoreNonTieGamblers()
	print("\ntesting match ignores rolls for gamblers not in tie")
	-- need to make sure someone that is not in the tie doesn't get to submit a new roll
	-- in this example we cannot allow Bulbasaur to submit a new roll
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 79)
	a:AddRoll("Charmander", 79)
	a:AddRoll("Bulbasaur", 7)
	a:AddRoll("Gengar", 42)
	assert(a.phase == "high tie", "the phase should be \"high tie\" once all rolls are submitted and there is a high tie") 
	assert(CompareArrays({"Squirtle", "Charmander"}, a:GetWaitingList()), "we should be waiting for Squirtle and Charmander")
	a:AddRoll("Charmander", 44)
	assert(a.phase == "high tie", "the phase should be \"high tie\" when still waiting for a high tie roll")
	assert(CompareArrays({"Squirtle"}, a:GetWaitingList()), "we should only be waiting for Squirtle")
	a:AddRoll("Squirtle", 23)
	a:AddRoll("Gengar", 59)
	assert(a.gamblers["Gengar"] == 42, "Gengar should still be 42 it should not be allowed to be changed b/c it is not in the high tie")
	assert(a.phase == "complete", "should be in phase complete since we submitted high tie rolls")
	assert(a.highGambler == "Charmander", "the high gambler should be Charmander")
	assert(a.highRoll == 79, "the high roll should be 79")
	assert(a.lowGambler == "Bulbasaur", "the low roll gambler should be Bulbasaur")
	assert(a.lowRoll == 7, "the low roll should be 7")	
end

local function TestMatchCheck2HighTies()
	print("\ntesting match check high tie")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 2)
	a:AddRoll("Charmander", 42)
	a:AddRoll("Bulbasaur", 5)
	a:AddRoll("Gengar", 42)

	assert(a.phase == "high tie", "the phase should be \"high tie\" once all rolls are submitted and there is a high tie") 
	assert(CompareArrays({"Gengar", "Charmander"}, a:GetWaitingList()), "we should be waiting for Gengar and Charmander")
	a:AddRoll("Charmander", 23)
	assert(a.phase == "high tie", "the phase should be \"high tie\" when still waiting for a high tie roll")
	assert(CompareArrays({"Gengar"}, a:GetWaitingList()), "we should only be waiting for Gengar")
	a:AddRoll("Gengar", 23)

	assert(a.phase == "high tie", "the phase should be \"high tie\" again") 
	assert(CompareArrays({"Gengar", "Charmander"}, a:GetWaitingList()), "we should be waiting for Gengar and Charmander")
	a:AddRoll("Charmander", 78)
	a:AddRoll("Gengar", 45)

	assert(a.phase == "complete", "should be in phase complete since we submitted high tie rolls")
	assert(a.highGambler == "Charmander", "the high gambler should be Charmander")
	assert(a.highRoll == 42, "the high roll should be 42")
	assert(a.lowGambler == "Squirtle", "the low roll gambler should be Squirtle")
	assert(a.lowRoll == 2, "the low roll should be 7")
end

local function TestMatchCheckLowTie()
	print("\ntesting match check low tie")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 5)
	a:AddRoll("Charmander", 47)
	a:AddRoll("Bulbasaur", 5)
	a:AddRoll("Gengar", 42)

	assert(a.phase == "low tie", "the phase should be \"low tie\"") 
	assert(CompareArrays({"Squirtle", "Bulbasaur"}, a:GetWaitingList()), "we should be waiting for Squirtle and Bulbasaur")
	a:AddRoll("Squirtle", 44)
	a:AddRoll("Bulbasaur", 61)

	assert(a.phase == "complete", "should be in phase complete since we submitted low tie rolls")
	assert(a.highGambler == "Charmander", "the high gambler should be Charmander")
	assert(a.highRoll == 47, "the high roll should be 44")
	assert(a.lowGambler == "Squirtle", "the low roll gambler should be Squirtle")
	assert(a.lowRoll == 5, "the low roll should be 5")	
end

local function TestMatchCheck2LowTies()
	print("\ntesting match check 2 low ties")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 5)
	a:AddRoll("Charmander", 47)
	a:AddRoll("Bulbasaur", 5)
	a:AddRoll("Gengar", 42)

	assert(a.phase == "low tie", "the phase should be \"low tie\"") 
	assert(CompareArrays({"Squirtle", "Bulbasaur"}, a:GetWaitingList()), "we should be waiting for Squirtle and Bulbasaur")
	a:AddRoll("Squirtle", 44)
	a:AddRoll("Bulbasaur", 44)

	assert(a.phase == "low tie", "should be in phase low tie again")
	a:AddRoll("Squirtle", 67)
	a:AddRoll("Bulbasaur", 48)

	assert(a.highGambler == "Charmander", "the high gambler should be Charmander")
	assert(a.highRoll == 47, "the high roll should be 44")
	assert(a.lowGambler == "Bulbasaur", "the low roll gambler should be Bulbasaur")
	assert(a.lowRoll == 5, "the low roll should be 5")	
end

local function TestMatchHighTieAndLowTie()
	print("\ntesting match check high tie followed by low tie")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 79)
	a:AddRoll("Charmander", 79)
	a:AddRoll("Bulbasaur", 7)
	a:AddRoll("Gengar", 7)
	assert(a.phase == "high tie", "the phase should be \"high tie\"")
	-- resolve high tie
	a:AddRoll("Squirtle", 75)
	a:AddRoll("Charmander", 64)
	assert(a.phase == "low tie", "the phase should be \"low tie\"")
	-- resolve low tie
	a:AddRoll("Bulbasaur", 32)
	a:AddRoll("Gengar", 22)
	-- check winners
	assert(a.phase == "complete", "the phase should be \"complete\"")
	assert(a.highGambler == "Squirtle", "the high gambler should be Squirtle")
	assert(a.highRoll == 79, "the high roll should be 79")
	assert(a.lowGambler == "Gengar", "the low roll gambler should be Gengar")
	assert(a.lowRoll == 7, "the low roll should be 7")
end

local function TestStatsAdd()
	print("\ntesting the stats add match function")
	local a = meowth.Match:New()
	a:AddGambler("Squirtle")
	a:AddGambler("Charmander")
	a:AddGambler("Bulbasaur")
	a:AddGambler("Gengar")
	a:Start()
	a:AddRoll("Squirtle", 100)
	a:AddRoll("Charmander", 79)
	a:AddRoll("Bulbasaur", 7)
	a:AddRoll("Gengar", 1)
	local b = meowth.Match:New()
	b:AddGambler("Squirtle")
	b:AddGambler("Charmander")
	b:AddGambler("Bulbasaur")
	b:AddGambler("Gengar")
	b:Start()
	b:AddRoll("Squirtle", 50)
	b:AddRoll("Charmander", 79)
	b:AddRoll("Bulbasaur", 7)
	b:AddRoll("Gengar", 15)
	local c = meowth.Match:New()
	c:AddGambler("Squirtle")
	c:AddGambler("Charmander")
	c:AddGambler("Bulbasaur")
	c:AddGambler("Gengar")
	c:Start()
	c:AddRoll("Squirtle", 84)
	c:AddRoll("Charmander", 21)
	c:AddRoll("Bulbasaur", 22)
	c:AddRoll("Gengar", 62)	
	local s = meowth.Stats:New()
	s:AddMatch(a)
	s:AddMatch(b)
	s:AddMatch(c)
	-- s:Print()
	print(s:ToString())
end

print(_VERSION)

TestMatchDefaultMaxRollMinRoll()
TestMatchAddRemove()
TestMatchStart()
TestMatchAddRoll()
TestMatchMinMaxRoll()
TestMatchWaiting()
TestMatchCheckComplete()
TestMatchCheckHighTie()
TestMatchIgnoreNonTieGamblers()
TestMatchCheck2HighTies()
TestMatchCheckLowTie()
TestMatchCheck2LowTies()
TestMatchHighTieAndLowTie()

TestStatsAdd()
