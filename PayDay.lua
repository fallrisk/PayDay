
-- Used https://github.com/Gethe/wow-ui-source/blob/2.4.3/AddOns/Blizzard_TimeManager/Blizzard_TimeManager.lua
-- as a refernce.

SLASH_PAYDAY1 = "/payday"
SLASH_PAYDAY2 = "/pd"

local match = meowth.Match:New()
local stats = meowth.Stats:New()
local matchStarted = false
local maxRoll = false
local minRoll = false

-- PayDay AddOn

function PrintChat(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function PayDay_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage("Pay Day loaded")
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
	if match.phase ~= "roll" then return end
	local i, j = string.find(msg, "rolls")
	if i == nil then return end
	local name, rolls, mins, maxs = string.match(msg, "^(%w+)%srolls%s(%d+)%s%((%d+)-(%d+)%)")
	local roll, min, max = tonumber(rolls), tonumber(mins), tonumber(maxs)
	if min ~= minRoll or max ~= maxRoll then return end
	match:AddRoll(name, roll)
end

-- PayDayFrame

function PayDayFrame_OnLoad(self)
	UIDropDownMenu_Initialize(PayDayFrameDropDownChannel, PayDayFrameDropDownChannel_Initialize)
	UIDropDownMenu_SetWidth(70, PayDayFrameDropDownChannel)
	UIDropDownMenu_SetSelectedID(PayDayFrameDropDownChannel, 1);
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonPrintStats:Disable()
	PayDayFrameButtonResetStats:Disable()
	PayDayFrameEditBoxMaxRoll:SetText("100")
	PayDayFrameEditBoxMinRoll:SetText("1")
end

function PayDayFrame_OnUpdate(self)
end

function PayDayFrame_OnEvent(self, event, ...)
	if not matchStarted then return end
	if event == "CHAT_MSG_SAY" then
		local msg, _, _, _, name = ...
		PayDay_ParseChat(name, msg)
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		PayDay_ParseRoll(tostring(msg))
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

	info.text = "Say"
	info.value = "say"
	info.justifyH = "RIGHT"
	info.checked = nil
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_AddButton(info)
end

function PayDayFrameDropDownChannel_OnClick()
	UIDropDownMenu_SetSelectedID(PayDayFrameDropDownChannel, this:GetID());
end

function PayDayFrameButtonStartMatch_OnClick(self)
	matchStarted = true
	local max = tonumber(PayDayFrameEditBoxMaxRoll:GetText())
	local min = tonumber(PayDayFrameEditBoxMinRoll:GetText())
	if max == nil or min == nil then return end
	if min >= max then return end
	PayDayFrameButtonStartMatch:Disable()
	match = meowth.Match:New()
	maxRoll = max
	minRoll = min
	PrintChat(string.format("rolling from %d to %d", min, max))
	PrintChat("type 1 to join or -1 to leave")
	-- self:RegisterEvent("CHAT_MSG_RAID")
	-- self:RegisterEvent("CHAT_MSG_PARTY")
	PayDayFrame:RegisterEvent("CHAT_MSG_SAY")
	PayDayFrame:RegisterEvent("CHAT_MSG_SYSTEM")  -- this is where rolls come in
	-- PayDayFrameEditBoxMaxRoll:Disable()
	-- PayDayFrameEditBoxMinRoll:Disable()
	PayDayFrameButtonEndMatch:Enable()
end

function PayDayFrameButtonEndMatch_OnClick(self)
	if not matchStarted then return end
	matchStarted = false
	match = false
	maxRoll = false
	minRoll = false	
	PrintChat("ending this match")
	PayDayFrame:UnregisterEvent("CHAT_MSG_SAY")
	PayDayFrame:UnregisterEvent("CHAT_MSG_SYSTEM")  -- this is where rolls come in	
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonStartMatch:Enable()
	-- PayDayFrameEditBoxMaxRoll:Enable()
	-- PayDayFrameEditBoxMinRoll:Enable()
end

function PayDayFrameButtonStartRoll_OnClick(self)
	if not matchStarted then return end
	match:Start()
	if match.phase ~= "roll" then return end	
	PayDayFrameButtonStartRoll:Disable()
	PrintChat("we rollin!")
end

function PayDayFrameButtonPrintStats_OnClick(self)
	-- DEFAULT_CHAT_FRAME:AddMessage(stats:ToString())
end

SlashCmdList["PAYDAY"] = PayDay_OnSlashCmd
