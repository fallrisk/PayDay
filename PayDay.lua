
-- Used https://github.com/Gethe/wow-ui-source/blob/2.4.3/AddOns/Blizzard_TimeManager/Blizzard_TimeManager.lua
-- as a refernce.

SLASH_PAYDAY1 = "/payday"
SLASH_PAYDAY2 = "/pd"

local Settings = {

}

local match = meowth.Match:New()
local stats = meowth.Stats:New()

-- PayDay AddOn

function PayDay_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage("Pay Day loaded")
end

function PayDay_OnSlashCmd(msg, editBox)
	PayDayFrame:Show()
end

-- NEED TO MAKE SURE THEIR ROLL is in the MIN, MAX range
-- the output of the roll command is like "Squirtle rolls 32 (20-40)"

-- PayDayFrame

function PayDayFrame_OnLoad(self)
	UIDropDownMenu_Initialize(PayDayFrameDropDownChannel, PayDayFrameDropDownChannel_Initialize)
	UIDropDownMenu_SetWidth(70, PayDayFrameDropDownChannel)
	PayDayFrameButtonStartRoll:Disable()
	PayDayFrameButtonEndMatch:Disable()
	PayDayFrameButtonPrintStats:Disable()
	PayDayFrameButtonResetStats:Disable()
	PayDayFrameEditBoxMaxRoll:SetText("100")
	PayDayFrameEditBoxMinRoll:SetText("1")
end

function PayDayFrame_OnUpdate(self)
	-- if ( self.prevMouseIsOver ) then
	-- 	if ( not MouseIsOver(self, 20, -8, -8, 20) ) then
	-- 		UIFrameFadeOut(PayDayFrameTabFrame, CHAT_FRAME_FADE_TIME);
	-- 		self.prevMouseIsOver = false;
	-- 	end
	-- else
	-- 	if ( MouseIsOver(self, 20, -8, -8, 20) ) then
	-- 		UIFrameFadeIn(PayDayFrameTabFrame, CHAT_FRAME_FADE_TIME);
	-- 		self.prevMouseIsOver = true;
	-- 	end
	-- end
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
	local info = UIDropDownMenu_CreateInfo()
	info.text = "Party"
	info.value = "party"
	info.justifyH = "RIGHT"
	info.checked = 1
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_SetText("Party", PayDayFrameDropDownChannel)
	-- |c000a49fd  |c00e36b09
	UIDropDownMenu_AddButton(info)

	info.text = "Raid"
	info.value = "raid"
	info.justifyH = "RIGHT"
	info.checked = nil
	info.func = PayDayFrameDropDownChannel_OnClick
	UIDropDownMenu_AddButton(info)
end

function PayDayFrameDropDownChannel_OnClick()

end

function PayDayFrameEditBoxMinRoll_OnLoad(self)

end

function PayDayFrameButtonNewMatch_OnClick(self)
	match = meowth.Match:New()
end

function PayDayFrameButtonStartRolls_OnClick(self)
	match:Start()
end

function PayDayFrameButtonPrintStats_OnClick(self)
	-- DEFAULT_CHAT_FRAME:AddMessage(stats:ToString())
end

SlashCmdList["PAYDAY"] = PayDay_OnSlashCmd
