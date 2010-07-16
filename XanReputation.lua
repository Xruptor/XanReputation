--Inspired by Author Tekkub and his mod PicoEXP
--Special thanks to Aranarth for Ara_Broker_Reputations

local start, max, starttime
local levels = { FACTION_STANDING_LABEL1, FACTION_STANDING_LABEL2, FACTION_STANDING_LABEL3, FACTION_STANDING_LABEL4, FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6, FACTION_STANDING_LABEL7, FACTION_STANDING_LABEL8 }
local colors = { "8b0000", "ff1919", "ff8c00", "dddddd", "ffff00", "19e619", "4169e1", "9932cc", "67009a" }
local GetFactionInfo, FACTION_INACTIVE = GetFactionInfo, FACTION_INACTIVE

local f = CreateFrame("frame","XanReputation",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not XanREP_DB then XanREP_DB = {} end
	if XanREP_DB.bgShown == nil then XanREP_DB.bgShown = true end
	if XanREP_DB.scale == nil then XanREP_DB.scale = 1 end
	if XanREP_DB.autoSwitch == nil then XanREP_DB.autoSwitch = true end

	self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("UPDATE_FACTION")

	--create the default frame and position it
	self:CreateREP_Frame()
	self:RestoreLayout("XanReputation")
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
	
	SLASH_XANREPUTATION1 = "/xanrep";
	SlashCmdList["XANREPUTATION"] = XanReputation_SlashCommand;

	local ver = GetAddOnMetadata("XanReputation","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /xanrep", "XanReputation", ver or "1.0"))
end

function XanReputation_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "bg" then
			XanReputation:BackgroundToggle()
			return true
		elseif c and c:lower() == "reset" then
			DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Frame position has been reset!");
			XanReputation:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
			return true
		elseif c and c:lower() == "auto" then
			XanREP_DB.autoSwitch = not XanREP_DB.autoSwitch
			if XanREP_DB.autoSwitch then
				DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Auto switching is now ON!");
			else
				DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Auto switching is now OFF!");
			end
			return true
		elseif c and c:lower() == "scale" then
			if b then
				local scalenum = strsub(cmd, b+2)
				if scalenum and scalenum ~= "" and tonumber(scalenum) then
					XanREP_DB.scale = tonumber(scalenum)
					XanReputation:SetScale(tonumber(scalenum))
					DEFAULT_CHAT_FRAME:AddMessage("XanReputation: scale has been set to ["..tonumber(scalenum).."]")
					return true
				end
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("XanReputation");
	DEFAULT_CHAT_FRAME:AddMessage("/xanrep reset - resets the frame position");
	DEFAULT_CHAT_FRAME:AddMessage("/xanrep bg - toggles the background on/off");
	DEFAULT_CHAT_FRAME:AddMessage("/xanrep scale # - Set the scale of the XanReputation frame")
	DEFAULT_CHAT_FRAME:AddMessage("/xanrep auto - Set to auto switch on reputation gain/loss.")
end

function f:CreateREP_Frame()

	f:SetWidth(61)
	f:SetHeight(27)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	
	f:SetScale(XanREP_DB.scale)
	
	if XanREP_DB.bgShown then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		f:SetBackdropBorderColor(0.5, 0.5, 0.5);
		f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
	f:EnableMouse(true);
	
	local iconTexture = UnitFactionGroup("player") == "Horde" and "Interface\\Icons\\Spell_Misc_HellifrePVPThrallmarFavor" or "Interface\\Icons\\Spell_Misc_HellifrePVPHonorHoldFavor"
	
	local t = f:CreateTexture("$parentIcon", "ARTWORK")
	t:SetTexture(iconTexture)
	t:SetWidth(16)
	t:SetHeight(16)
	t:SetPoint("TOPLEFT",5,-6)

	local g = f:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	g:SetJustifyH("LEFT")
	g:SetPoint("CENTER",8,0)
	g:SetText("?")

	f:SetScript("OnMouseDown",function(self, button)
		if button == "LeftButton" and IsShiftKeyDown() then
			self.isMoving = true
			self:StartMoving();
		elseif button == "RightButton" then
			ToggleDropDownMenu(1, nil, self.DD, self, 0, 0)
	 	end
	end)
	f:SetScript("OnMouseUp",function()
		if( self.isMoving ) then

			self.isMoving = nil
			self:StopMovingOrSizing()

			f:SaveLayout(self:GetName());

		end
	end)
	f:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)

	f:SetScript("OnEnter",function()
		if XanREP_DB.factionWatched and XanREP_DB.factionIndex and XanREP_DB.factionIndex > 0 then
			local name, showValue, level, minVal, maxVal, value, atWar, canBeAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(XanREP_DB.factionIndex)
			if not isHeader then
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				GameTooltip:SetPoint(self:GetTipAnchor(self))
				GameTooltip:ClearLines()
				
				GameTooltip:AddLine("XanReputation")

				local remainXP = maxVal - value
				local toLevelPercent = math.floor((maxVal - value) / maxVal * 100)
				
				GameTooltip:AddDoubleLine("Faction:", name, nil,nil,nil, 1,1,1)
				GameTooltip:AddDoubleLine("Status:", string.format("|cFF%s%s|r", colors[level], levels[level]), nil,nil,nil, 1,1,1)
				GameTooltip:AddDoubleLine("Current:", value, nil,nil,nil, 1,1,1)
				GameTooltip:AddDoubleLine("TNR:", remainXP..(" ("..toLevelPercent.."%)"), nil,nil,nil, 1,1,1)
				if start and starttime then
					GameTooltip:AddLine(string.format("%.1f hours played this session", (GetTime()-starttime)/3600), 1,1,1)
					GameTooltip:AddLine((value - start).." REP gained this session", 1,1,1)
				end

				GameTooltip:Show()
			end
		end
	end)
	
	f:Show();
end

function f:UpdateREP_Frame()
	if XanREP_DB.factionWatched and XanREP_DB.factionIndex and XanREP_DB.factionIndex > 0 then
		local name, showValue, level, minVal, maxVal, value, atWar, canBeAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(XanREP_DB.factionIndex)
		if not isHeader and maxVal > 0 then
			getglobal("XanReputationText"):SetText(string.format("|cFF%s%d%%|r", colors[level], value/maxVal*100))
			return
		end
	end
	getglobal("XanReputationText"):SetText("None")
end

function f:SaveLayout(frame)

	if not XanREP_DB then XanREP_DB = {} end

	local opt = XanREP_DB[frame] or nil;

	if opt == nil then
		XanREP_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["PosX"] = 0,
			["PosY"] = 0,
		}
		opt = XanREP_DB[frame];
	end

	local f = getglobal(frame);
	local scale = f:GetEffectiveScale();
	opt.PosX = f:GetLeft() * scale;
	opt.PosY = f:GetTop() * scale;

end

function f:RestoreLayout(frame)

	if not XanREP_DB then XanREP_DB = {} end	

	local f = getglobal(frame);
	local opt = XanREP_DB[frame] or nil;

	if opt == nil then
		XanREP_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["PosX"] = 0,
			["PosY"] = 0,
		}
		opt = XanREP_DB[frame];
	end

	local x = opt.PosX;
	local y = opt.PosY;
	local s = f:GetEffectiveScale();

	if (not x or not y) or (x==0 and y==0) then
		f:ClearAllPoints();
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		return 
	end

	--calculate the scale
	x,y = x/s,y/s;

	--set the location
	f:ClearAllPoints();
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y);

end

function f:BackgroundToggle(switch)
	if not switch then
		if not XanREP_DB then XanREP_DB = {} end
		if XanREP_DB.bgShown == nil then XanREP_DB.bgShown = true end
		
		if not XanREP_DB.bgShown then
			XanREP_DB.bgShown = true
			DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Background Shown");
		elseif XanREP_DB.bgShown then
			XanREP_DB.bgShown = false
			DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Background Hidden");
		else
			XanREP_DB.bgShown = true
			DEFAULT_CHAT_FRAME:AddMessage("XanReputation: Background Shown");
		end
	end

	--now change background
	if XanREP_DB.bgShown then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		f:SetBackdropBorderColor(0.5, 0.5, 0.5);
		f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
end

function f:GetFactionWatched(sSwitch, faction)
	local chkFaction = faction or XanREP_DB.factionWatched or nil

	if chkFaction then
		for i = 1, GetNumFactions() do
			if GetFactionInfo(i) == chkFaction then
				local name, showValue, level, minVal, maxVal, value, atWar, canBeAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(i)
				start, max, starttime = value, maxVal, GetTime()
				XanREP_DB.factionIndex = i
				XanREP_DB.factionWatched = name
				if sSwitch then SetWatchedFactionIndex(i) end
			end
		end
	end
	
	XanREP_DB.factionCount = GetNumFactions()
end

------------------------------
--         DropDown         --
------------------------------

function f:SetupDropDown()

	--close the dropdown menu if shown
	if f.DD and f.DD:IsShown() then
		CloseDropDownMenus()
	end

	local t = {}
	local q = {}
	for i = 1, GetNumFactions() do
		local name, showValue, level, minVal, maxVal, value, atWar, canBeAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(i)
		if value and not isHeader then
			table.insert(t, name)
			q[name] = level
		end
	end

	table.sort(t, function(a,b) return a < b end)

	local dd1 = LibStub('LibXMenu-1.0'):New("XanReputation_DD", XanREP_DB)
	dd1.initialize = function(self, lvl)
		if lvl == 1 then
			self:AddList(lvl, "Reputation", "rep")
			self:AddList(lvl, "Settings", "settings")
			self:AddCloseButton(lvl,  "Close")
		elseif lvl and lvl > 1 then
			local sub = UIDROPDOWNMENU_MENU_VALUE
			if sub == "rep" then
				local starti = (30 * (lvl - 2)) + 1
				local endi = (30 * (lvl - 1)) - 1
				for i = starti, endi, 1 do
					if not t[i] then break end
					local status = "??"
					if q[t[i]] then
						status = string.format("|cFF%s%s|r", colors[q[t[i]]], levels[q[t[i]]])
					end
					self:AddSelect(lvl, string.format("%s      (%s)", t[i], status), t[i], "factionWatched")
					if i == endi and t[i + 1] then
						self:AddList(lvl, "More", sub)
						break
					end
				end
			elseif sub == "settings" then
				self:AddList(lvl, "Scale", "scale")
				self:AddToggle(lvl, "Toggle background", "bgShown", nil, nil, nil, 1)
				self:AddToggle(lvl, "Auto switch reputation", "autoSwitch")
			elseif sub == "scale" then
				for i = 1, 2.6, 0.1 do
					self:AddSelect(lvl, i, i, "scale", nil, nil, 2)
				end
			end	
		end
	end

	dd1.doUpdate = function(bOpt)
		if bOpt and bOpt == 1 then
			self:BackgroundToggle(true)
			return
		elseif bOpt and bOpt == 2 then
			XanReputation:SetScale(XanREP_DB.scale)
			return
		end
		self:GetFactionWatched(true)
	end

	f.DD = dd1
end

------------------------------
--      Event Handlers      --
------------------------------

local org_SetWatchedFactionIndex = SetWatchedFactionIndex
function SetWatchedFactionIndex(...)
	org_SetWatchedFactionIndex(...)
	XanREP_DB.factionWatched = GetFactionInfo(...)
	XanREP_DB.factionIndex = ...
	if XanReputation then XanReputation:UpdateREP_Frame() end
end

local factionUp = gsub(FACTION_STANDING_INCREASED:gsub("%%d", "([0-9]+)"), "%%s", "(.*)")
local factionDown = gsub(FACTION_STANDING_DECREASED:gsub("%%d", "([0-9]+)"), "%%s", "(.*)")
local newRep = string.gsub(FACTION_STANDING_CHANGED, "%%%d?%$?s", "(.+)")

function f:CHAT_MSG_COMBAT_FACTION_CHANGE(event, msg)

	local faction, value, decrease = strmatch( msg, factionUp )
	if not faction then
		faction, value = strmatch( msg, factionDown )
		if not faction then return end
		decrease = true
	end
	if tonumber(faction) then faction, value = value, tonumber(faction) else value = tonumber(value) end

	if XanREP_DB.factionCount ~= GetNumFactions() then
		--a new faction was added so lets update the display
		XanREP_DB.factionCount = GetNumFactions()
		f:SetupDropDown()
	end
	
	if not decrease and XanREP_DB.autoSwitch then
		for i = 1, GetNumFactions() do
			if GetFactionInfo(i) == faction then
				return SetWatchedFactionIndex(i)
			end
		end
	end
	if faction == XanREP_DB.factionWatched then f:UpdateREP_Frame() end
	
end

local repPattern = string.gsub(FACTION_STANDING_CHANGED,"%%%d?%$?s", "(.+)")

function f:CHAT_MSG_SYSTEM(event, msg)
	if not msg or not type(msg)=="string" then return end
	local newstanding, withfaction = strmatch(msg, repPattern)
	if not newstanding then return end
	--since we are now a new standing lets redo the dropdown just in case we just got a new rep we didn't have
	if XanREP_DB.factionCount ~= GetNumFactions() then
		--a new faction was added so lets update the display
		XanREP_DB.factionCount = GetNumFactions()
		f:SetupDropDown()
	end
end

function f:UPDATE_FACTION()
	--now that our faction information is loaded, lets populate the dropdown and setup the display
	
	--setup startup faction information
	self:GetFactionWatched(true)
	
	--do the dropdown
	self:SetupDropDown()
	
	--do rep frame update
	self:UpdateREP_Frame()

	self:UnregisterEvent("UPDATE_FACTION")
	self.UPDATE_FACTION = nil
end

------------------------
--      Tooltip!      --
------------------------

function f:GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
