
PAYDAY_DEFAULT_MESSAGES = {
	on2ndHighTie = {
		text = "We got another high tie!",
		desc = "Printed on 2nd time a high tie occurs."
	},
	on2ndLowTie = {
		text = "We got another low tie!",
		desc = "Printed on 2nd time a low tie occurs."
	},
	onAlsoLowTie = {
		text = "There is also a low tie!",
		desc = "Printed when a low tie occurs after a high tie."
	},
	onHighTie = {
		text = "There is a high tie!",
		desc = "Printed on a high tie occurs."
	},
	onLastCall = {
		text = "Last call to join honkies.",
		desc = "Printed when you press the last call button."
	},
	onLowTie = {
		text = "There is a low tie!",
		desc = "Printed when a low tie occurs."
	},
	onMatchComplete = {
		text = "Match complete.",
		desc = "Printed on match complete."
	},
	onMatchCompleteOwe = {
		text = "HOoO MAN! %s owes %d gold to %s!",
		desc = "This is the message that shows who owes who.\r\nMust contain 2 %s and 1 %d."
	},
	onMatchEnd = {
		text = "Ending this match.",
		desc = "This is printed when you end a match early."
	},
	onStandoff = {
		text = "We got ourselves a standoff, ffs. Everybody roll again.",
		desc = "Printed when gamblers all have the same roll."
	},
	onStartRoll = {
		text = "We rollin (%d to %d)!",
		desc = "Printed at the start of rolling. This means the join phase is complete."
	},
	askToRoll = {
		text = "The following gamblers need to roll:",
		desc = "Printed when you request the list of gamblers you are waiting on."
	},
	header = {
		text = "[PD] ",
		desc = "Printed in front of every Pay Day message."
	},
	join = {
		text = "Type 1 to join or -1 to leave.",
		desc = "This is printed when you start a match. It indicates you are in the join phase."
	},
	rollingToFrom = {
		text = "Rolling from %d to %d.",
		desc = "When you start the match this indicated the min and max of the match. Must contain 2 %d."
	}
}

function PayDayCreateMessagesFrame(messages)
	-- This is the equivalent XML.
	--
	-- <EditBox name="$parent2ndHighTie" inherits="InputBoxTemplate" hidden="false" autoFocus="false" letters="100" enableKeyboard="true" enableMouse="true">
	--   <Size x="300" y="26"/>
	--   <Anchors>
	--     <Anchor point="TOPLEFT" relativeTo="PayDayInterfaceOptionsMessagesSubText" relativePoint="BOTTOMLEFT">
	--       <Offset>
	--         <AbsDimension x="0" y="-20"/>
	--       </Offset>
	--     </Anchor>
	--   </Anchors>
	--   <Layers>
	--     <Layer level="OVERLAY">
	--       <FontString name="$parentText" inherits="GameFontWhite" justifyH="LEFT" text="Printed on 2nd time a high tie occurs.">
	--         <Anchors>
	--           <Anchor point="BOTTOMLEFT" relativePoint="TOPLEFT" x="-5" y="0"/>
	--         </Anchors>
	--       </FontString>
	--     </Layer>
	--   </Layers>
	--   <FontString inherits="ChatFontNormal"/>
	-- </EditBox>
	-- local scrollChild = CreateFrame("ScrollChild", nil, PayDayInterfaceOptionsMessagesScrollFrame)
	local containerFrame = CreateFrame("Frame", "PayDayInterfaceOptionsMessages", PayDayInterfaceOptionsMessagesScrollFrame)
	containerFrame:SetWidth(100)
	containerFrame:SetHeight(150)
	containerFrame:ClearAllPoints()
	containerFrame:SetPoint("TOPLEFT", 50, 0)
	containerFrame.title = containerFrame:CreateFontString("PayDayInterfaceOptionsMessagesTitle", "OVERLAY", "GameFontNormalLarge")
	containerFrame.title:SetPoint("TOPLEFT", 0, 0)
	containerFrame.title:SetText("Messages")
	containerFrame.subText = containerFrame:CreateFontString("PayDayInterfaceOptionsMessagesSubText", "OVERLAY", "GameFontHighlightSmall")
	containerFrame.subText:SetPoint("TOPLEFT", "PayDayInterfaceOptionsMessagesTitle", "BOTTOMLEFT", 0, 0)
	containerFrame.subText:SetText("Change the messages Pay Day prints in the following form.")
	-- containerFrame.subText:SetHeight(30)
	local lastEditBox = containerFrame.subText;
	for k, v in pairs(messages) do
		local editBox = CreateFrame("EditBox", k.."EditBox", containerFrame, "InputBoxTemplate")
		-- LayoutFrame
		editBox.title = editBox:CreateFontString(k.."Title", "OVERLAY", "GameFontWhite") -- agrcwow 166
		editBox.title:SetPoint("TOPLEFT", 0, 0)
		editBox.title:SetText(v.desc)
		-- Frame
		editBox:EnableKeyboard(true)
		editBox:EnableMouse(true)
		editBox:SetPoint("TOPLEFT", lastEditBox, "BOTTOMLEFT", 0, -20)  -- https://wow.gamepedia.com/API_Region_SetPoint
		editBox:SetWidth(300)
		editBox:SetHeight(40)
		-- EditBox
		editBox:SetMaxLetters(100)
		editBox:SetAutoFocus(false)
		editBox:SetText(v.text)
		editBox:SetCursorPosition(0)
		lastEditBox = editBox
	end
	PayDayInterfaceOptionsMessagesScrollFrame:SetScrollChild(containerFrame)
end

function PayDayCreateMessagesFrame(messages)
	local containerFrame = CreateFrame("Frame", "ScrollFrameTestMessages")
	containerFrame:SetWidth(100)
	containerFrame:SetHeight(150)
	containerFrame:ClearAllPoints()
	containerFrame:SetPoint("TOPLEFT", 50, 0)
	containerFrame.title = containerFrame:CreateFontString("ScrollFrameTestMessagesTitle", "OVERLAY", "GameFontNormalLarge")
	containerFrame.title:SetPoint("TOPLEFT", 0, 0)
	containerFrame.title:SetText("Messages")
	containerFrame.subText = containerFrame:CreateFontString("ScrollFrameTestMessagesSubText", "OVERLAY", "GameFontHighlightSmall")
	containerFrame.subText:SetPoint("TOPLEFT", "ScrollFrameTestMessagesTitle", "BOTTOMLEFT", 0, 0)
	containerFrame.subText:SetText("Change the messages Pay Day prints in the following form.")
	-- containerFrame.subText:SetHeight(30)
	local lastEditBox = containerFrame.subText;
	for k, v in pairs(messages) do
		local editBox = CreateFrame("EditBox", k.."EditBox", containerFrame, "InputBoxTemplate")
		-- LayoutFrame
		editBox.title = editBox:CreateFontString(k.."Title", "OVERLAY", "GameFontWhite") -- agrcwow 166
		editBox.title:SetPoint("TOPLEFT", 0, 0)
		editBox.title:SetText(v.desc)
		-- Frame
		editBox:EnableKeyboard(true)
		editBox:EnableMouse(true)
		editBox:SetPoint("TOPLEFT", lastEditBox, "BOTTOMLEFT", 0, -20)  -- https://wow.gamepedia.com/API_Region_SetPoint
		editBox:SetWidth(300)
		editBox:SetHeight(40)
		-- EditBox
		editBox:SetMaxLetters(100)
		editBox:SetAutoFocus(false)
		editBox:SetText(v.text)
		editBox:SetCursorPosition(0)
		lastEditBox = editBox
	end
	ScrollFrameTest:SetScrollChild(containerFrame)
end

