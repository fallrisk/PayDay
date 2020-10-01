
-- Used https://github.com/Gethe/wow-ui-source/blob/2.4.3/AddOns/Blizzard_TimeManager/Blizzard_TimeManager.lua
-- as a refernce.

local Settings = {

}

-- PayDay AddOn

function PayDay_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage("Pay Day loaded")
end

-- PayDayFrame

function PayDayFrame_OnLoad(self)
	
end

function PayDayFrame_Toggle()
	if (PayDayFrame:IsShown()) then
		PayDayFrame:Hide()
	else
		PayDayFrame:Show()
	end
end

function PayDayFrameEditBoxMinRoll_OnLoad(self)

end

function PayDayFrameCloseButton_OnClick()
	PlaySound("igMainMenuQuit")
	PayDayFrame:Hide()
end

function PayDayFrame_OnUpdate(self)
	if ( self.prevMouseIsOver ) then
		if ( not MouseIsOver(self, 20, -8, -8, 20) ) then
			UIFrameFadeOut(PayDayFrameTabFrame, CHAT_FRAME_FADE_TIME);
			self.prevMouseIsOver = false;
		end
	else
		if ( MouseIsOver(self, 20, -8, -8, 20) ) then
			UIFrameFadeIn(PayDayFrameTabFrame, CHAT_FRAME_FADE_TIME);
			self.prevMouseIsOver = true;
		end
	end
end
