
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

-- PayDay AddOn

function PrintChat(msg)
	if channelId == 1 then
		SendChatMessage(msg, "SAY", nil, GetChannelName("SAY"))
	elseif channelId == 2 then
		SendChatMessage(msg, "PARTY", nil, GetChannelName("PARTY"))
	elseif channelId == 3 then
		SendChatMessage(msg, "RAID", nil, GetChannelName("RAID"))
	end
end

function EndMatch()
	matchStarted = false
	match = false
	maxRoll = false
	minRoll = false
	PayDayFrame:UnregisterEvent("CHAT_MSG_SAY")
	PayDayFrame:UnregisterEvent("CHAT_MSG_PARTY")
	PayDayFrame:UnregisterEvent("CHAT_MSG_RAID")
	PayDayFrame:UnregisterEvent("CHAT_MSG_SYSTEM")  -- this is where rolls come in
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonLastCall:Disable()
	PayDayFrameButtonReminder:Disable()
	PayDayFrameButtonStartMatch:Enable()
end


function PayDay_OnLoad()
	local version = GetAddOnMetadata("PayDay", "version")
	DEFAULT_CHAT_FRAME:AddMessage(string.format("Pay Day loaded, version %s", version))
end

function PayDay_OnSlashCmd(msg, editBox)
	PayDayFrame:Show()
end

function PayDay_ParseChat(name, msg)
	if not matchStarted then return end
	if msg == "1" then
		match:AddGambler(name)
		if #match:GetGamblers() >= 1 then
			PayDayFrameButtonStartRoll:Enable()
		end
	elseif msg == "-1" then
		match:RemoveGambler(name)
		if #match:GetGamblers() < 1 then
			PayDayFrameButtonStartRoll:Disable()
		end
	else
		return
	end
end

function PayDay_ParseRoll(msg)
	if not (match.phase == "roll" or match.phase == "high tie" or match.phae == "low tie") then
		return
	end
	local i, j = string.find(msg, "rolls")
	if i == nil then return end
	local name, rolls, mins, maxs = string.match(msg, "^(%w+)%srolls%s(%d+)%s%((%d+)-(%d+)%)")
	local roll, min, max = tonumber(rolls), tonumber(mins), tonumber(maxs)
	if min ~= minRoll or max ~= maxRoll then return end
	match:AddRoll(name, roll)
end

function PayDay_CheckComplete(prevPhase)
	if prevPhase == "roll" then
		if match.phase == "high tie" then
			PrintChat("there is a high tie!")
		elseif match.phase == "low tie" then
			PrintChat("there is a low tie!")
		end
	elseif prevPhase == "high tie" and #match:GetWaitingList() == 0 then
		if match.phase == "high tie" then
			PrintChat("we got another high tie!")
		elseif match.phase == "low tie" then
			PrintChat("there is a low tie!")
		end
	elseif prevPhase == "low tie" and #match:GetWaitingList() == 0 then
		if match.phae == "low tie" then
			PrintChat("we got another low tie!")
		end
	end

	if match.phase == "complete" then
		PrintChat("match complete")
		local diff = match.highRoll - match.lowRoll
		PrintChat(string.format("HOoO MAN! %s owes %d to %s", match.lowGambler, diff, match.highGambler))
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
	if not matchStarted then return end
	if event == "CHAT_MSG_SAY" and channelId == 1 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_PARTY" and channelId == 2 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_RAID" and channelId == 3 then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		local prevPhase = match.phase
		PayDay_ParseRoll(tostring(msg))
		PayDay_CheckComplete(prevPhase)
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
	match = meowth.Match:New()
	maxRoll = max
	minRoll = min
	PrintChat(string.format("rolling from %d to %d", min, max))
	PrintChat("type 1 to join or -1 to leave")

	if channelId == 1 then
		PayDayFrame:RegisterEvent("CHAT_MSG_SAY")
	elseif channelId == 2 then
		PayDayFrame:RegisterEvent("CHAT_MSG_PARTY")
	elseif channelId == 3 then
		PayDayFrame:RegisterEvent("CHAT_MSG_RAID")
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
	PrintChat("ending this match")
	EndMatch()
end

function PayDayFrameButtonStartRoll_OnClick(self)
	if not matchStarted then return end
	match:Start()
	if match.phase ~= "roll" then return end
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonReminder:Enable()
	PayDayFrameButtonLastCall:Disable()
	PrintChat("we rollin!")
end

function PayDayFrameButtonPrintStats_OnClick(self)
	for i, v in ipairs(stats:GetGamblersSorted()) do
		PrintChat(string.format("%s %d", v, stats.totals[v]))
	end
end

function PayDayFrameButtonResetStats_OnClick()
	if matchStarted then return end
	SELECTED_CHAT_FRAME:AddMessage("resetting stats")
	PayDayFrameButtonPrintStats:Disable()
	PayDayFrameButtonResetStats:Disable()
	stats = meowth.Stats:New()
end

function PayDayFrameButtonReminder_OnClick(self)
	if not matchStarted then return end
	PrintChat('heads up! we are waiting on:')
	for i, v in ipairs(match:GetWaitingList()) do
		PrintChat(v)
	end
end

function PayDayFrameButtonLastCall_OnClick(self)
	if not matchStarted then return end
	if match.phase ~= "join" then return end
	PrintChat("last call to join honkies")
end

SlashCmdList["PAYDAY"] = PayDay_OnSlashCmd
