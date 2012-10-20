--Inspired by Author Tekkub and his mod PicoEXP
--Special thanks to Aranarth for Ara_Broker_Reputations

local start, max, starttime
local levels = { FACTION_STANDING_LABEL1, FACTION_STANDING_LABEL2, FACTION_STANDING_LABEL3, FACTION_STANDING_LABEL4, FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6, FACTION_STANDING_LABEL7, FACTION_STANDING_LABEL8 }
local colors = { "8b0000", "ff1919", "ff8c00", "dddddd", "ffff00", "19e619", "4169e1", "9932cc", "67009a" }
local GetFactionInfo, FACTION_INACTIVE = GetFactionInfo, FACTION_INACTIVE

local f = CreateFrame("frame","xanReputation",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not XanREP_DB then XanREP_DB = {} end
	if XanREP_DB.bgShown == nil then XanREP_DB.bgShown = true end
	if XanREP_DB.scale == nil then XanREP_DB.scale = 1 end
	if XanREP_DB.autoSwitch == nil then XanREP_DB.autoSwitch = true end
	--check for old db
	if XanREP_DB["XanReputation"] then
		XanREP_DB["xanReputation"] = XanREP_DB["XanReputation"]
		XanREP_DB["XanReputation"] = nil
	end
	
	self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("UPDATE_FACTION")

	--create the default frame and position it
	self:CreateREP_Frame()
	self:RestoreLayout("xanReputation")
	
	SLASH_XANREPUTATION1 = "/xanrep";
	SlashCmdList["XANREPUTATION"] = xanReputation_SlashCommand;

	local ver = GetAddOnMetadata("xanReputation","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /xanrep", "xanReputation", ver or "1.0"))

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function xanReputation_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "reset" then
			DEFAULT_CHAT_FRAME:AddMessage("xanReputation: Frame position has been reset!");
			xanReputation:ClearAllPoints()
			xanReputation:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
			return true
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("xanReputation");
	DEFAULT_CHAT_FRAME:AddMessage("/xanrep reset - resets the frame position");

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
		if not button then return end
		if button == "LeftButton" and IsShiftKeyDown() then
			self.isMoving = true
			self:StartMoving();
		elseif button == "RightButton" then
			self:ShowDropDown(self)
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
				GameTooltip:AddLine("xanReputation")

				maxVal = maxVal - minVal
				value = value - minVal
				local percent = ceil((value / maxVal) * 100)
				local remainXP, toLevelPercent = 0, 0
				
				if percent < 100 then
					remainXP = maxVal - value
					toLevelPercent = ceil((maxVal - value) / maxVal * 100)
				end
				
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
			maxVal = maxVal - minVal
			value = value - minVal
			local percent = ceil((value / maxVal) * 100)
			getglobal("xanReputationText"):SetText(string.format("|cFF%s%d%%|r", colors[level], percent))
			return
		end
	end
	getglobal("xanReputationText"):SetText("None")
end

function f:SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanREP_DB then XanREP_DB = {} end
	
	local opt = XanREP_DB[frame] or nil

	if not opt then
		XanREP_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanREP_DB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function f:RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanREP_DB then XanREP_DB = {} end

	local opt = XanREP_DB[frame] or nil

	if not opt then
		XanREP_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanREP_DB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

function f:BackgroundToggle(switch)
	if not switch then
		if not XanREP_DB then XanREP_DB = {} end
		if XanREP_DB.bgShown == nil then XanREP_DB.bgShown = true end
		
		if not XanREP_DB.bgShown then
			XanREP_DB.bgShown = true
			DEFAULT_CHAT_FRAME:AddMessage("xanReputation: Background Shown");
		elseif XanREP_DB.bgShown then
			XanREP_DB.bgShown = false
			DEFAULT_CHAT_FRAME:AddMessage("xanReputation: Background Hidden");
		else
			XanREP_DB.bgShown = true
			DEFAULT_CHAT_FRAME:AddMessage("xanReputation: Background Shown");
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
				maxVal = maxVal - minVal
				value = value - minVal
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

local function Faded(self)
	self:Release()
end

local function FadeMenu(self)
	local fadeInfo = {}
	fadeInfo.mode = "OUT"
	fadeInfo.timeToFade = 0.1
	fadeInfo.finishedFunc = Faded
	fadeInfo.finishedArg1 = self
	UIFrameFade(self, fadeInfo)
end

function f:ShowDropDown(sFrame)

	local dd1 = LibStub("LibDropdown-1.0")

	local t = {
	   type = "group",
	   name = "group",
	   desc = "group",
	   args = {
		reputation = {
			 type = "group",
			 name = "Reputation",
			 desc = "Select a reputation",
			 args = {
				--to be filled by loop below
			 },
			 order = 10
		  },
		settings = {
			 type = "group",
			 name = "Settings",
			 desc = "xanReputation settings",
			 args = {
				range = {
					type = "range",
					name = "Scale",
					desc = "Change the scale size of xanReputation",
					min = 1,
					max = 2.6,
					bigStep = 0.1,
					get = function(info) return XanREP_DB.scale end,
					set = function(info, v)
						XanREP_DB.scale = v
						xanReputation:SetScale(v)
					end,
					order = 10					
				},
				toggleBG = {
					type = "toggle",
					name = "Toggle background",
					desc = "Toggle the xanReputation background",
					get = function() return XanREP_DB.bgShown end,
					set = function(info, v)
						XanREP_DB.bgShown = v 
						f:BackgroundToggle(true)
					end,
					order = 20
				},
				autoSwitchBG = {
					type = "toggle",
					name = "Auto Switch",
					desc = "Auto switch reputation",
					get = function() return XanREP_DB.autoSwitch end,
					set = function(info, v) XanREP_DB.autoSwitch = v end,
					order = 30
				},  				
			 },
			 order = 20
		  },             
		close = {
			 type = "execute",
			 name = "Close",
			 desc = "Close this menu",
			 func = function(self) FadeMenu(f.DD) end,
			 order = 1000
		  }
	   }
	}
		
	--fill the reputation list
	local parentOrder = 1
	for i = 1, GetNumFactions() do
		local name, showValue, level, minVal, maxVal, value, atWar, canBeAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(i)
		if isHeader then
			--check if we have something first
			local processChk = false
			for q = 1, GetNumFactions() do
				local nameSub, _, _, _, _, _, _, _, isHeaderSub = GetFactionInfo(q)
				if isHeaderSub and nameSub == name then
					boolD = true
				elseif isHeaderSub and nameSub ~= name then
					boolD = false
				end
				if boolD and not isHeaderSub then
					processChk = true
					break
				end
			end
		
			if processChk then
				--do the child rep names for the reputation parent
				local boolD = false
				local tableValues = {}
				for q = 1, GetNumFactions() do
					local nameSub, _, _, _, _, _, _, _, isHeaderSub = GetFactionInfo(q)
					if isHeaderSub and nameSub == name then
						boolD = true
					elseif isHeaderSub and nameSub ~= name then
						boolD = false
					end
					if boolD and not isHeaderSub then
						table.insert(tableValues,nameSub)
					end
				end
				
				--add to reputation parent
				t.args.reputation.args[name] = 
				{
					type = "select",
					name = name,
					desc = name,
					values = tableValues,
					order = parentOrder*10,
					get = function(info) return optIndex end,
					set = function(info, v) optIndex = v end
					--XanREP_DB.factionWatched = nameSub
					--f:GetFactionWatched(true)
				}
				
				parentOrder = parentOrder + 1
						
			end
		end
	end
	
	
	f.DD = dd1:OpenAce3Menu(t)
	f.DD:SetClampedToScreen(true)
	f.DD:SetAlpha(1.0)
	f.DD:Show()
	
	f:GetFactionWatched(true)
	
end

------------------------------
--      Event Handlers      --
------------------------------

local org_SetWatchedFactionIndex = SetWatchedFactionIndex
function SetWatchedFactionIndex(...)
	org_SetWatchedFactionIndex(...)
	XanREP_DB.factionWatched = GetFactionInfo(...)
	XanREP_DB.factionIndex = ...
	if xanReputation then xanReputation:UpdateREP_Frame() end
end

local factionUp = gsub(FACTION_STANDING_INCREASED:gsub("%%d", "([0-9]+)"), "%%s", "(.*)")
local factionDown = gsub(FACTION_STANDING_DECREASED:gsub("%%d", "([0-9]+)"), "%%s", "(.*)")
local repPattern = string.gsub(FACTION_STANDING_CHANGED,"%%%d?%$?s", "(.+)")

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

function f:CHAT_MSG_SYSTEM(event, msg)
	if not msg or not type(msg)=="string" then return end
	local newstanding, withfaction = strmatch(msg, repPattern)
	if not newstanding then return end
	--since we are now a new standing lets redo the dropdown just in case we just got a new rep we didn't have
	if XanREP_DB.factionCount ~= GetNumFactions() then
		--a new faction was added so lets update the display
		XanREP_DB.factionCount = GetNumFactions()
	end
end

function f:UPDATE_FACTION()
	--now that our faction information is loaded, lets populate the dropdown and setup the display
	
	--setup startup faction information
	self:GetFactionWatched(true)
	
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
