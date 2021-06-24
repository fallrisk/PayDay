
-- Used https://github.com/Gethe/wow-ui-source/blob/2.4.3/AddOns/Blizzard_TimeManager/Blizzard_TimeManager.lua
-- as a refernce.

SLASH_PAYDAY1 = "/payday"
SLASH_PAYDAY2 = "/pd"

local match = meowth.Match:New()
local stats = meowth.Stats:New()
local matchStarted = false
local maxRoll = false
local minRoll = false
local channelId = 2
local minimapPos = 10
local messages = {}
local iFrame = {}  -- interface frame, the frame in Interface/AddOns

-- PayDay AddOn

function PrintChat(msg)
	local header = messages.header.text
	if channelId == 1 then
		SendChatMessage(header..msg, "SAY", nil, GetChannelName("SAY"))
	elseif channelId == 2 then
		SendChatMessage(header..msg, "PARTY", nil, GetChannelName("PARTY"))
	elseif channelId == 3 then
		SendChatMessage(header..msg, "RAID", nil, GetChannelName("RAID"))
	end
end

function EndMatch()
	matchStarted = false
	match = false
	PayDayFrame:UnregisterEvent("CHAT_MSG_SAY")
	PayDayFrame:UnregisterEvent("CHAT_MSG_PARTY")
	PayDayFrame:UnregisterEvent("CHAT_MSG_RAID")
	PayDayFrame:UnregisterEvent("CHAT_MSG_RAID_LEADER")
	PayDayFrame:UnregisterEvent("CHAT_MSG_SYSTEM")  -- this is where rolls come in
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonLastCall:Disable()
	PayDayFrameButtonReminder:Disable()
	PayDayFrameButtonStartMatch:Enable()
end

function PrintTieMembers()
	PrintChat(messages.askToRoll.text)
	local m = ""
	for i, v in ipairs(match:GetWaitingList()) do
		m = m..v..", "
	end
	if string.len(m) > 1 then
		PrintChat(string.sub(m, 1, string.len(m) - 2))
	end
end

function PayDay_OnLoad()
	local version = GetAddOnMetadata("PayDay", "version")
	DEFAULT_CHAT_FRAME:AddMessage(string.format("Pay Day loaded, version %s", version))
end

function PayDay_OnSlashCmd(msg, editBox)
	local debugGamblers = {"Cartman", "Stan", "Kyle", "Kenny", "Randy", "Sharon", "Butters"}
	if msg == "dj" then  -- debug join
		local outStr = ""
		for i, v in ipairs(debugGamblers) do
			PayDayFrame_OnEvent(PayDayFrame, "CHAT_MSG_SAY", "1", 0, 0, 0, v)
			outStr = string.format("%s %s,", outStr, v)
		end
		outStr = string.sub(outStr, 1, string.len(outStr) - 1)  -- Drop the extra comma.
		SELECTED_CHAT_FRAME:AddMessage(string.format("%s joined the match", outStr))
	elseif msg == "dr" then  -- debug roll
		local outStr = ""
		for i, v in ipairs(debugGamblers) do
			local roll = string.format("%s rolls %d (%d-%d)", v, random(minRoll, maxRoll), minRoll, maxRoll)
			outStr = string.format("%s %s, ", outStr, roll)
			PayDayFrame_OnEvent(PayDayFrame, "CHAT_MSG_SYSTEM", roll)
		end
		outStr = string.sub(outStr, 1, string.len(outStr) - 1)  -- Drop the extra comma.
		-- combined to reduce number of messages to server otherwise I get muted
		SELECTED_CHAT_FRAME:AddMessage(outStr)
	elseif msg == "version" then
		local version = GetAddOnMetadata("PayDay", "version")
		SELECTED_CHAT_FRAME:AddMessage(string.format("PayDay version %s", version))
	else
		PayDayFrame:Show()
	end
end

function PayDay_ParseChat(name, msg)
	if not matchStarted then return end
	if msg == "1" then
		match:AddGambler(name)
		if #match:GetGamblers() >= 2 then
			PayDayFrameButtonStartRoll:Enable()
		end
	elseif msg == "-1" then
		match:RemoveGambler(name)
		if #match:GetGamblers() < 2 then
			PayDayFrameButtonStartRoll:Disable()
		end
	else
		return
	end
end

function PayDay_ParseRoll(msg)
	-- returns true if the roll was used, false if it was dropped
	if not (match.phase == "roll" or match.phase == "high tie" or match.phase == "low tie") then
		return false
	end
	local i, j = string.find(msg, "rolls")
	if i == nil then return false end
	local name, rolls, mins, maxs = string.match(msg, "^(%w+)%srolls%s(%d+)%s%((%d+)-(%d+)%)")
	local roll, min, max = tonumber(rolls), tonumber(mins), tonumber(maxs)
	if min ~= minRoll or max ~= maxRoll then return false end
	return match:AddRoll(name, roll)
end

function PayDay_CheckComplete(prevPhase, prevWaitCount)
	if prevWaitCount == nil then
		prevWaitCount = 0
	end
	if prevPhase == "roll" then
		if match.phase == "high tie" then
			PrintChat(messages.onHighTie.text)
			PrintTieMembers()
		elseif match.phase == "low tie" then
			PrintChat(messages.onLowTie.text)
			PrintTieMembers()
		elseif match.phase == "all match" then
			PrintChat(messages.onStandoff.text)
			match:Reroll()
		end
	elseif prevPhase == "high tie" and match.phase ~= "complete"
		   and prevWaitCount - 1 ~= #match:GetWaitingList() then
		if match.phase == "high tie" then
			PrintChat(messages.on2ndHighTie.text)
			PrintTieMembers()
		elseif match.phase == "low tie" then
			PrintChat(messages.onAlsoLowTie.text)
			PrintTieMembers()
		end
	elseif prevPhase == "low tie" and match.phase ~= "complete"
		   and prevWaitCount - 1 ~= #match:GetWaitingList() then
		if match.phase == "low tie" then
			PrintChat(messages.on2ndLowTie.text)
			PrintTieMembers()
		end
	end

	if match.phase == "complete" then
		PrintChat(messages.onMatchComplete.text)
		local diff = match.highRoll - match.lowRoll
		PrintChat(string.format(messages.onMatchCompleteOwe.text, match.lowGambler, diff, match.highGambler))
		stats:AddMatch(match)
		EndMatch()
	end
end

-- PayDay Minimap

function PayDayButtonMinimap_OnLoad(self)
	self:RegisterForDrag('LeftButton')
	self:SetFrameLevel(8)
	PayDayButtonMinimap_SetPosition(minimapPos)
end

function PayDayButtonMinimap_OnClick(self)
	PayDayFrame_Toggle()
end

function PayDayButtonMinimap_OnDragStart(self)
	self.dragging = true
	self:LockHighlight()
	self:SetScript('OnUpdate', PayDayButtonMinimap_UpdatePosition)
end

function PayDayButtonMinimap_OnDragStop(self)
	self.dragging = nil
	self:SetScript('OnUpdate', nil)
	self:UnlockHighlight()
end

function PayDayButtonMinimap_UpdatePosition(self)
	-- Most of this came from minimap.lua in the Bongos addon.
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	minimapPos = math.deg(math.atan2(py - my, px - mx)) % 360
	local angle = math.rad(minimapPos)
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local minimapShape = GetMinimapShape and GetMinimapShape() or 'ROUND'

	local round = false
	if minimapShape == 'ROUND' then
		round = true
	elseif minimapShape == 'SQUARE' then
		round = false
	elseif minimapShape == 'CORNER-TOPRIGHT' then
		round = not(cos < 0 or sin < 0)
	elseif minimapShape == 'CORNER-TOPLEFT' then
		round = not(cos > 0 or sin < 0)
	elseif minimapShape == 'CORNER-BOTTOMRIGHT' then
		round = not(cos < 0 or sin > 0)
	elseif minimapShape == 'CORNER-BOTTOMLEFT' then
		round = not(cos > 0 or sin > 0)
	elseif minimapShape == 'SIDE-LEFT' then
		round = cos <= 0
	elseif minimapShape == 'SIDE-RIGHT' then
		round = cos >= 0
	elseif minimapShape == 'SIDE-TOP' then
		round = sin <= 0
	elseif minimapShape == 'SIDE-BOTTOM' then
		round = sin >= 0
	elseif minimapShape == 'TRICORNER-TOPRIGHT' then
		round = not(cos < 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-TOPLEFT' then
		round = not(cos > 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-BOTTOMRIGHT' then
		round = not(cos < 0 and sin < 0)
	elseif minimapShape == 'TRICORNER-BOTTOMLEFT' then
		round = not(cos > 0 and sin < 0)
	end

	local x, y
	if round then
		x = cos*80
		y = sin*80
	else
		x = math.max(-82, math.min(110*cos, 84))
		y = math.max(-86, math.min(110*sin, 82))
	end

	self:SetPoint('CENTER', x, y)
end

function PayDayButtonMinimap_SetPosition(angle)
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local x = cos*80
	local y = sin*80
	PayDayButtonMinimap:SetPoint('CENTER', x, y)
end

-- PayDayFrame

function PayDayFrame_OnLoad(self)
	PayDayFrame:RegisterEvent("ADDON_LOADED")
	PayDayFrame:RegisterEvent("PLAYER_LOGOUT")
	UIDropDownMenu_Initialize(PayDayFrameDropDownChannel, PayDayFrameDropDownChannel_Initialize)
	UIDropDownMenu_SetWidth(70, PayDayFrameDropDownChannel)
	UIDropDownMenu_SetSelectedID(PayDayFrameDropDownChannel, channelId);
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonPrintStats:Disable()
	PayDayFrameButtonResetStats:Disable()
	PayDayFrameButtonReminder:Disable()
	PayDayFrameButtonLastCall:Disable()
	PayDayFrameEditBoxMaxRoll:SetText("50")
	PayDayFrameEditBoxMinRoll:SetText("1")
	PayDayFrameButtonPrintStats:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function PayDayFrame_OnUpdate(self)
	if stats.totalMatches > 0 and not matchStarted then
		PayDayFrameButtonPrintStats:Enable()
		PayDayFrameButtonResetStats:Enable()
	else
		PayDayFrameButtonPrintStats:Disable()
		PayDayFrameButtonResetStats:Disable()
	end
end

function PayDayFrame_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		arg1 = ...
		if arg1 == "PayDay" then  -- Is it for the PayDay AddOn?
			if not PayDaySettings or PayDaySettings.settingsVersion == nil
				or PayDaySettings.settingsVersion ~= 3 then
				PayDaySettings = {
					settingsVersion = 2,
					minimapPos = 10,
					messages = PAYDAY_DEFAULT_MESSAGES
				}
			end
			minimapPos = PayDaySettings.minimapPos
			messages = PayDaySettings.messages
			PayDayButtonMinimap_UpdatePosition(PayDayButtonMinimap)
			PayDayButtonMinimap_SetPosition(minimapPos)
			PayDayButtonMinimap_UpdatePosition(PayDayButtonMinimap)
			PayDayCreateMessagesFrame(messages)
		end
	elseif event == "PLAYER_LOGOUT" then
		PayDaySettings.minimapPos = minimapPos
		PayDaySettings.messages = messages
	end
	if not matchStarted then return end
	if event == "CHAT_MSG_SAY" and channelId == 1 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_PARTY" and channelId == 2 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") and channelId == 3 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		if match.phase == "join" then return end
		local prevPhase = match.phase
		local prevWaitCount = #match:GetWaitingList()
		if PayDay_ParseRoll(tostring(msg)) then
			PayDay_CheckComplete(prevPhase, prevWaitCount)
		end
	end
end

function PayDayFrame_Toggle()
	if (PayDayFrame:IsShown()) then
		PayDayFrame:Hide()
	else
		PayDayFrame:Show()
	end
end

function PayDayFrameCloseButton_OnClick()
	PlaySound("igMainMenuQuit")
	PayDayFrame:Hide()
end

function PayDayFrameDropDownChannel_Initialize()
	-- |c000a49fd  |c00e36b09
	local info = UIDropDownMenu_CreateInfo()

	info.text = "Say"
	info.value = "say"
	info.justifyH = "RIGHT"
	info.checked = nil
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_AddButton(info)

	info.text = "Party"
	info.value = "party"
	info.justifyH = "RIGHT"
	info.checked = nil
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_AddButton(info)

	info.text = "Raid"
	info.value = "raid"
	info.justifyH = "RIGHT"
	info.checked = nil
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_AddButton(info)
end

function PayDayFrameDropDownChannel_OnClick()
	if matchStarted then return end
	UIDropDownMenu_SetSelectedID(PayDayFrameDropDownChannel, this:GetID())
	channelId = this:GetID()
end

function PayDayFrameButtonStartMatch_OnClick(self)
	matchStarted = true
	local max = tonumber(PayDayFrameEditBoxMaxRoll:GetText())
	local min = tonumber(PayDayFrameEditBoxMinRoll:GetText())
	if max == nil or min == nil then return end
	if min >= max then return end
	PlaySoundFile("Interface\\AddOns\\PayDay\\res\\lion1.ogg", "Master")
	maxRoll = max
	minRoll = min
	match = meowth.Match:New(maxRoll, minRoll)
	PrintChat(string.format(messages.rollingToFrom.text, min, max))
	PrintChat(messages.join.text)

	if channelId == 1 then
		PayDayFrame:RegisterEvent("CHAT_MSG_SAY")
	elseif channelId == 2 then
		PayDayFrame:RegisterEvent("CHAT_MSG_PARTY")
	elseif channelId == 3 then
		PayDayFrame:RegisterEvent("CHAT_MSG_RAID")
		PayDayFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	else
		return
	end

	PayDayFrame:RegisterEvent("CHAT_MSG_SYSTEM")  -- this is where rolls come in
	PayDayFrameButtonStartMatch:Disable()
	PayDayFrameButtonLastCall:Enable()
	PayDayFrameButtonEndMatch:Enable()
	PayDayFrameButtonLastCall:Enable()
end

function PayDayFrameButtonEndMatch_OnClick(self)
	if not matchStarted then return end
	PrintChat(messages.onMatchEnd.text)
	EndMatch()
end

function PayDayFrameButtonStartRoll_OnClick(self)
	if not matchStarted then return end
	match:Start()
	if match.phase ~= "roll" then return end
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonReminder:Enable()
	PayDayFrameButtonLastCall:Disable()
	PrintChat(string.format(messages.onStartRoll.text, minRoll, maxRoll))
end

function PayDayFrameButtonPrintStats_OnClick(self, button, down)
	-- top and bottom is how many of the top you want to display
	-- and how many of the bottom you want to display. -1 means all
	if button == "LeftButton" then
		local count = #stats:GetGamblersSorted()
		local topAndBottom = 3
		local top = 0
		local bot = 0
		local outputStr = ""
		if topAndBottom == -1 then
			for i, v in ipairs(stats:GetGamblersSorted()) do
				outputStr = outputStr..(string.format(" %s %d;", v, stats.totals[v]))
			end
		else
			for i, v in ipairs(stats:GetGamblersSorted()) do
				if top < topAndBottom then
					top = top + 1
					outputStr = outputStr..(string.format(" %s %d;", v, stats.totals[v]))
				elseif top == topAndBottom and bot == 0 and count > 2 * topAndBottom then
					outputStr = outputStr.." ... "
					top = top + 1
				elseif top >= topAndBottom and bot < topAndBottom and i > count - topAndBottom then
					bot = bot + 1
					outputStr = outputStr..(string.format(" %s %d;", v, stats.totals[v]))
				end
			end
		end
		-- Drop the last semicolon and print the statistics.
		PrintChat(string.sub(outputStr, 1, string.len(outputStr) - 1))
	else
		local menu = {
			{text = "Select a Gambler", isTitle = true}
		}
		for i, v in ipairs(stats:GetGamblersSortedbyName()) do
			table.insert(menu, {text = v, func = function()
				PrintChat(string.format("%s %d", v, stats.totals[v]))
			end
			})
		end
		local menuFrame = CreateFrame("Frame", "GamblerStatsSelectFrame", UIParent, "UIDropDownMenuTemplate")
		EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU")
	end
end

function PayDayFrameButtonResetStats_OnClick()
	if matchStarted then return end
	SELECTED_CHAT_FRAME:AddMessage("Resetting statistics.")
	PayDayFrameButtonPrintStats:Disable()
	PayDayFrameButtonResetStats:Disable()
	stats = meowth.Stats:New()
end

function PayDayFrameButtonReminder_OnClick(self)
	if not matchStarted then return end
	PrintTieMembers()
end

function PayDayFrameButtonLastCall_OnClick(self)
	if not matchStarted then return end
	if match.phase ~= "join" then return end
	PrintChat(messages.onLastCall.text)
end

-- PayDayInterfaceOptions

function PayDayInterfaceOptions_OnLoad(panel)
	panel.name = "Pay Day"
	InterfaceOptions_AddCategory(panel)
end

function ScrollFrameTest_OnLoad(panel)
	panel.name = "Scroll"
	panel.parent = "Pay Day"
	InterfaceOptions_AddCategory(panel)
end

function PayDayInterfaceOptionsMessagesParent_OnLoad(panel)
	-- Need to make it so that panel.okay callback will apply the changes and cancel will just drop the changes
	panel.name = "Messages"
	panel.parent = "Pay Day"
	InterfaceOptions_AddCategory(panel)
end

SlashCmdList["PAYDAY"] = PayDay_OnSlashCmd
