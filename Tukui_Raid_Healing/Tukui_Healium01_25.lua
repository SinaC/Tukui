-- http://www.wowpedia.org/UI_best_practices
-- http://www.wowpedia.org/Category:HOWTOs
-- http://www.wowwiki.com/AddOn_loading_process

-- TESTED:
-- =======
-- buff (must implement move tukui raid frame to test) -> OK
-- debuff -> OK
-- cd -> OK
-- button -> OK
-- dispel -> OK
-- incoming heal ==> C["unitframes"].healcomm = true -> OK
-- disable tukui raid debuff/buff/hots   see \Tukui_Raid_Healing\oUF_hTukz_Raid01_15.lua:139   frame.Debuffs = nil  -> OK
-- mana ==> included in oUF  -> OK
-- special spells (swiftmend allowed only if rejuv or regrowth on member) (see settings) -> OK
-- change alpha when dead/ghost or disconnected -> OK
-- HealiumEnabled -> OK
-- avoid using _G[] to get raid frame, use a local list -> OK
-- pets: could Share be used to create pets ? -> OK
-- spell/buff/debuff size/spacing -> OK
-- sound when a dispellable spell is found -> OK
-- spell/buff/debuff tooltip -> OK
-- buff/debuff are not shown when connecting  this is because unit is not yet set when Shared is called (unit = raid instead of player1) -> OK
-- rebirth not shown when dead while in combat. Forgot to add rez=true =) -> OK
-- settings: highlightDispel, playSoundOnDispel, showBuffDebuffTooltip, showButtonTooltip, showPercentage, frame width/height -> OK
-- sometimes buff/debuff doesn't disappear -> stupid copy/paste
-- doesn't work if no settings found for current spec on priest. Respec works but connecting with a spec without settings doesn't work -> OK
-- use this module only if Healium is enabled and at least a settings for current class is found, else, use classic module -> OK
--	if grid -> raid, party
--	else,
--		create normal grid -> custom [@raid26,exists] show;hide
--		if healium, create healium -> custom [@raid26,exists] hide;show + pets
--		else, create normal custom [@raid26,exists] hide;show
-- spell must be learned to appear in a button (question-mark if not learned) check IsSpellLearned(spellID) -> OK
-- if not enough mana or reactive conditions not met, change heal button color, see http://www.wowwiki.com/API_IsUsableSpell -> OK
--	-> conflict if button is colored for a dispel and nomana ==> set flag on button to determine which color set (settings showNoMana)
-- hPrereqFailed, hOOM, hDispelHighlight, hOOR, hInvalid -> OK
-- settings: showOnlyDispellableDebuff, showPets, showNoMana, showOOR -> OK
-- slash commands -> OK
-- BugGrabber support -> OK
-- aggro ==> C["unitframes"].aggro = true -> OK
-- why error on not-learned spell are not shown when logging in but are shown when /rl -> OK
-- dedicated dump frame
-- showBuff, showDebuff
-- if no settings but showDebuff == true, display debuff
-- delayed healium buttons creation while in combat (call CreateFrameButtons when out of combat) -> OK
-- flash dispel -> OK
-- display Addon version and options when connected -> OK
-- REDO settings: global settings, per character settings and spec settings -> OK
--	on ENTERING_WORLD or TALENT_UPDATE, build settings from HealiumSettings (concat global, per character and spec settings)
--	and use a global variable to store current settings
-- CheckSpellSettings() should be called when respecing -> OK
-- /reloadui: after which event the frames are shown ? -> OK
--		long debuff such as Berserk are not shown after a /reloadui because frame are not shown
--		dump temp fix: ForEachMembers check on unit ~= nil and not on shown
-- dump frame tukui style -> OK
-- localization: http://www.wowpedia.org/Localizing_an_addon  (search for L.) -> OK
-- new folder structure -> OK
-- on /reloadui CheckSpellSettings signals Macro as invalid  --> when connecting, error message are displayed 2 times with PLAYER_LOGIN and PLAYER_ALIVE   when reloadui  displayed only 1 time with PLAYER_LOGIN -> OK
-- new settings structure -> OK
-- range by spell: Tukui\Tukui\modules\unitframes\core\oUF\elements\range.lua (button.hOOR), set C["unitframes"].showrange to false -> OK
-- deletion of non-class specific settings -> OK
-- new performance counter -> OK
-- debuff filter: BLACKLIST, WHITELIST, NONE -> OK
-- while entering raid40 (or alterac), healium frame are considered as shown but are not shown (debuff sound is played when someone is affected by a debuff :p) -> OK (frame:GetParent():IsShown() must be true)

-- TO TEST:
-- ========
-- addon CPU profiling  http://wow.curseforge.com/addons/addon-profiler/   http://www.wowinterface.com/downloads/info13888-AddonProfiler.html
-- OOM (cpu), CD (cpu), buff/debuff (memory/gc) optimization -> SEEMS TO WORK
--	CD optimisation:
-- 	if in raid 1 with 3 spells, when casting an instant with a CD
-- 		before: 3*1 + 3*1 + 3*1 = 9 calls to UpdateButtonCooldown
--		now: 3*1 + 1*1 + 0*1 = 4 calls to UpdateButtonCooldown
--	if in raid 10 with 3 spells,
--		before: 3*10 + 3*10 + 3*10 = 90 calls
--		now: 3*10 + 1*10 + 0 = 40 calls
--	if in raid 10, with 9 spells,
--		before: 9*10 + 9*10 + 9*10 = 270 calls
--		after: 9*10 + 1*10 + 0 = 100

-- ISSUES:
-- =======
-- when connecting in solo (no group, no pet) a raidpet frame is created. After creation, frame.unit = nil and frame:IsShown() returns nil
-- raid member contextual menu (right-click) is not skinned while in a raid group but is skinned in classic heal/dps tukui raidframes

-- TODO:
-- =====
-- resize frame (smaller height) when raid > 15
-- dump perf: sort on count
-- use spellName everywhere instead of spellID
-- Tank frame (attributes: [["groupFilter", "MAINTANK,TANK"]],  [["groupBy", "ROLE"]],    showParty, showRaid but not showSolo)
-- pet spells
-- optimize UpdateCooldown (no need to call it more than once every 0.2sec, maybe not needed to update if already running), OOM, OOR ... in general way, don't call ForEachMembers(UpdateButtonsColor) so often
-- reload settings/UpdateFrameButtons when resetting talents
-- why raid frame moves automatically? -> probably because unitframes are centered in raid frame
-- multirow: 2 rows of spell/buff/debuff (looks ugly :p)
-- character specific settings

local ADDON_NAME, ns = ...
local oUF = oUFTukui or oUF
assert(oUF, "Tukui was unable to locate oUF install.")

ns._Objects = {}
ns._Headers = {}

local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales
if not C["unitframes"].enable == true or C["unitframes"].gridonly == true then return end
if not HealiumSettings or not HealiumSettings.Options or not HealiumSettings.Options.enabled or not HealiumSettings or not HealiumSettings[T.myclass] then return end

-- Aliases
local FlashFrame = _G["FlashFrame"]
local PerformanceCounter = _G["PerformanceCounter"]
local DumpSack = _G["DumpSack"]

-- Fields added to TukuiUnitframe
--		hDisabled: true if unitframe is dead/ghost/disconnected, false otherwise
--		hButtons: heal buttons (SecureActionButtonTemplate)
--		hDebuffs: debuff on unit (no template)
--		hBuffs: buffs on unit (only buff castable by heal buttons)
-- Fields added to hButton
--		hSpellBookID: spellID of spell linked to button
--		hMacroName: name of macro linked to button
--		hPrereqFailed: button is disabled because of prereq
--		hOOM: not enough mana to cast spell
--		hDispelHighlight: debuff dispellable by button
--		hOOR: unit of range
--		hInvalid: spell is not valid

-------------------------------------------------------
-- Constants
-------------------------------------------------------
local Debug = true
local ActivatePrimarySpecSpellName = GetSpellInfo(63645)
local ActivateSecondarySpecSpellName = GetSpellInfo(63644)
local MaxButtonCount = 12 -- TODO: set automatically using max(#spells foreach spec of current player)
local MaxDebuffCount = 8
local MaxBuffCount = 6
local UpdateDelay = 0.2
local DispelSoundFile = "Sound\\Doodad\\BellTollHorde.wav"

-------------------------------------------------------
-- Variables
-------------------------------------------------------
local DelayedButtonsCreation = {}
local Unitframes = {}
local listDebuffsoundTime = GetTime()
local SpecSettings = nil
local LastPerformanceCounterReset = GetTime()
--local HighestCost = 0

-------------------------------------------------------
-- Helpers
-------------------------------------------------------
local function Message(...)
	print("TukuiHealium:", ...)
end

local function ERROR(...)
	print("|CFFFF0000TukuiHealium|r:",...)
end

local function WARNING(...)
	print("|CFF00FFFFTukuiHealium|r:",...)
end

local function DEBUG(...)
	if not Debug or Debug == false then return end
	print("|CFF00FF00TH|r:",...)
end

-- Get value or set to default if nil
local function Getter(value, default)
	return value == nil and default or value
end

-- Format big number
local function ShortValueNegative(v)
	if v <= 999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 1000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

-- Get book spell id from spell name
local function GetSpellBookID(spellName)
	PerformanceCounter:Increment("TukuiHealium", "GetSpellBookID")
	--DEBUG("GetSpellBookID")
	for i = 1, 300, 1 do
		local spellBookName = GetSpellBookItemName(i, SpellBookFrame.bookType)
		if not spellBookName then break end
		if spellName == spellBookName then
			local slotType = GetSpellBookItemInfo(i, SpellBookFrame.bookType)
			if slotType == "SPELL" then
				return i
			end
			return nil
		end
	end
	return nil
end

-- Is spell learned?
local function IsSpellLearned(spellID)
	PerformanceCounter:Increment("TukuiHealium", "IsSpellLearned")
	--DEBUG("IsSpellLearned")
	local spellName = GetSpellInfo(spellID)
	if not spellName then return nil end
	local skillType, globalSpellID = GetSpellBookItemInfo(spellName)
	-- skill type: "SPELL", "PETACTION", "FUTURESPELL", "FLYOUT"
	if skillType == "SPELL" and globalSpellID == spellID then return skillType end
	return nil
end

-- Create a list with spellID and spellName from a list of spellID (+ remove duplicates)
local function CreateDebuffFilterList(listName, list)
	local newList = {}
	local i = 1
	local index = 1
	while i <= #list do
		local spellName = GetSpellInfo(list[i])
		if spellName then
			-- Check for duplicate
			local j = 1
			local found = false
			while j < #newList do
				if newList[j].spellName == spellName then
					found = true
					break
				end
				j = j + 1
			end
			if not found then
				-- Create entry in new list
				newList[index] = { spellID = list[i], spellName = spellName }
				index = index + 1
			-- else
				-- -- Duplicate found
				-- WARNING(string.format(L.healium_SETTINGS_DUPLICATEBUFFDEBUFF, list[i], newList[j].spellID, spellName, listName))
			end
		else
			-- Unknown spell found
			WARNING(string.format(L.healium_SETTINGS_UNKNOWNBUFFDEBUFF, list[i], listName))
		end
		i = i + 1
	end
	return newList
end
-------------------------------------------------------
-- Unitframes management
-------------------------------------------------------
-- Save frame
local function SaveFrame(frame)
	tinsert(Unitframes, frame)
end

-- Get frame from unit
local function GetFrameFromUnit(unit)
	PerformanceCounter:Increment("TukuiHealium", "GetFrameFromUnit")
	--DEBUG("GetFrameFromUnit")
	if not Unitframes then return nil end
	for _, frame in ipairs(Unitframes) do
		--DEBUG("GetFrameFromUnit:"..frame:GetName().."  "..(frame.unit or 'nil').."  "..(frame:IsShown() and 'shown' or 'hidden'))
		if frame and frame:IsShown() and frame.unit == unit then return frame end
	end
	return nil
end

-- Loop among every members in party/raid and call a function
local function ForEachMember(fct, ...)
	PerformanceCounter:Increment("TukuiHealium", "ForEachMember")
	if not Unitframes then return end
	--WARNING("ForEachMember")
	for _, frame in ipairs(Unitframes) do
		--WARNING("ForEachMember:"..frame:GetName().."  "..(frame.unit or 'nil').."  "..(frame:IsShown() and 'shown' or 'hidden'))
		--if frame and frame:IsShown() then -- IsShown is false if /reloadui
		if frame and frame:GetParent():IsShown() and frame.unit ~= nil then -- IsShown is false if /reloadui
			fct(frame, ...)
		-- elseif frame.unit then
			-- WARNING("ForEachMember:"..frame:GetName().."  "..(frame.unit or 'nil').."  "..(frame:IsShown() and 'shown' or 'hidden'))
		end
	end
end

-------------------------------------------------------
-- Settings
-------------------------------------------------------
-- Return settings for current spec
local function GetSpecSettings()
	--DEBUG("GetSettings")
	local ptt = GetPrimaryTalentTree()
	if not ptt then return nil end
	return HealiumSettings[T.myclass][ptt]
end

-- Check spell settings
local function CheckSpellSettings()
	--DEBUG("CheckSpellSettings")
	-- Check settings
	--HighestCost = 0
	if SpecSettings then
		for _, spellSetting in ipairs(SpecSettings.spells) do
			if spellSetting.spellID and not IsSpellLearned(spellSetting.spellID) then
				local name = GetSpellInfo(spellSetting.spellID)
				--local name, _, _, cost = GetSpellInfo(spellSetting.spellID)
				--if cost > HighestCost then HighestCost = cost end
				if name then
					ERROR(string.format(L.healium_CHECKSPELL_SPELLNOTLEARNED, name, spellSetting.spellID))
				else
					ERROR(string.format(L.healium_CHECKSPELL_SPELLNOTEXISTS, spellSetting.spellID))
				end
			elseif spellSetting.macroName and GetMacroIndexByName(spellSetting.macroName) == 0 then
				ERROR(string.format(L.healium_CHECKSPELL_MACRONOTFOUND, spellSetting.macroName))
			end
		end
	end
end

-------------------------------------------------------
-- Debug
-------------------------------------------------------
-- Dump information about frame
local function DumpFrame(frame)
	if not frame then return end
	DumpSack:Add("Frame "..tostring(frame:GetName()).." S="..tostring(frame:IsShown()).." U="..tostring(frame.unit).." D="..tostring(frame.hDisabled).." PS="..tostring(frame:GetParent():IsShown()))
	if frame.hButtons then
		DumpSack:Add("Buttons")
		for i, button in ipairs(frame.hButtons) do
			if button:IsShown() then
				DumpSack:Add("  "..i.." SID="..tostring(button.hSpellBookID).." MN="..tostring(button.hMacroName).." D="..tostring(button.hPrereqFailed).." NM="..tostring(button.hOOM).." DH="..tostring(button.hDispelHighlight).." OOR="..tostring(button.hOOR).." I="..tostring(button.hInvalid))
			end
		end
	else
		DumpSack:Add("Healium buttons not created")
	end
	if frame.hDebuffs then
		DumpSack:Add("Debuffs")
		for i, debuff in ipairs(frame.hDebuffs) do
			if debuff:IsShown() then
				DumpSack:Add("  "..i.." ID="..tostring(debuff:GetID()).." U="..tostring(debuff.unit))
			end
		end
	else
		DumpSack:Add("Healium debuffs not created")
	end
	if frame.hBuffs then
		DumpSack:Add("Buffs")
		for i, buff in ipairs(frame.hBuffs) do
			if buff:IsShown() then
				DumpSack:Add("  "..i.." ID="..tostring(buff:GetID()).." U="..tostring(buff.unit))
			end
		end
	else
		DumpSack:Add("Healium buffs not created")
	end
end

-------------------------------------------------------
-- Tooltips
-------------------------------------------------------
-- Heal buttons tooltip
local function ButtonOnEnter(self)
	-- Heal tooltips are anchored to tukui tooltip
	local TukuiTooltipAnchor = _G["TukuiTooltipAnchor"]
	GameTooltip:SetOwner(TukuiTooltipAnchor, "ANCHOR_NONE")
	if self.hInvalid then
		if self.hSpellBookID then
			local name = GetSpellInfo(self.hSpellBookID) -- in this case, hSpellBookID contains global spellID
			GameTooltip:AddLine(string.format(L.healium_TOOLTIP_UNKNOWNSPELL, name, self.hSpellBookID), 1, 1, 1)
		elseif self.hMacroName then
			GameTooltip:AddLine(string.format(L.healium_TOOLTIP_UNKNOWN_MACRO, self.hMacroName), 1, 1, 1)
		else
			GameTooltip:AddLine(L.healium_TOOLTIP_UNKNOWN, 1, 1, 1)
		end
	else
		if self.hSpellBookID then
			GameTooltip:SetSpellBookItem(self.hSpellBookID, SpellBookFrame.bookType)
		elseif self.hMacroName then
			GameTooltip:AddLine(string.format(L.healium_TOOLIP_MACRO, self.hMacroName), 1, 1, 1)
		else
			GameTooltip:AddLine(L.healium_TOOLTIP_UNKNOWN, 1, 1, 1)
		end
		local unit = SecureButton_GetUnit(self)
		if not UnitExists(unit) then return end
		local unitName = UnitName(unit)
		if not unitName then unitName = "-" end
		GameTooltip:AddLine(string.format(L.healium_TOOLTIP_TARGET, unitName), 1, 1, 1)
	end
	GameTooltip:Show()
end

-- Debuff tooltip
local function DebuffOnEnter(self)
	--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
	if self:GetCenter() > GetScreenWidth()/2 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetUnitDebuff(self.unit, self:GetID())
end

-- Buff tooltip
local function BuffOnEnter(self)
	--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
	if self:GetCenter() > GetScreenWidth()/2 then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetUnitBuff(self.unit, self:GetID())
end

-------------------------------------------------------
-- Healium buttons/buff/debuffs update
-------------------------------------------------------
-- Update healium button cooldown
local function UpdateButtonCooldown(frame, index, start, duration, enabled)
	PerformanceCounter:Increment("TukuiHealium", "UpdateButtonCooldown")
	if not frame.hButtons then return end
	--DEBUG("UpdateButtonCooldown")
	local button = frame.hButtons[index]
	CooldownFrame_SetTimer(button.cooldown, start, duration, enabled)
end

-- Update healium button OOM
local function UpdateButtonOOM(frame, index, OOM)
	PerformanceCounter:Increment("TukuiHealium", "UpdateButtonOOM")
	if not frame.hButtons then return end
	--DEBUG("UpdateButtonOOM")
	local button = frame.hButtons[index]
	--if not button then return end
	button.hOOM = OOM
end

-- Update healium button OOR
local function UpdateButtonOOR(frame, index, spellName)
	PerformanceCounter:Increment("TukuiHealium", "UpdateButtonOOR")
	if not frame.hButtons then return end
	DEBUG("UpdateButtonOOR")
	local button = frame.hButtons[index]
	local inRange = IsSpellInRange(spellName, frame.unit)
	if not inRange or inRange == 0 then
		button.hOOR = true
	else
		button.hOOR = false
	end
end

-- Update healium button color depending on frame and button status
-- frame disabled -> color in dark red except rez if dead or ghost
-- out of range -> color in deep red
-- disabled -> dark gray
-- out of mana -> color in medium blue
-- dispel highlight -> color in debuff color
local function UpdateButtonsColor(frame)
	PerformanceCounter:Increment("TukuiHealium", "UpdateButtonsColor")
	if not SpecSettings then return end
	if not frame.hButtons then return end
	if not frame:IsShown() then return end

	--DEBUG("UpdateButtonsColor:"..frame:GetName())

	if frame.hDisabled then
		-- not (rez and unit is dead) -> color in red
		if frame.hButtons then
			local unit = frame.unit
			for index, spellSetting in ipairs(SpecSettings.spells) do
				local button = frame.hButtons[index]
				if ((UnitIsDead(unit) or UnitIsGhost(unit)) and (not spellSetting.rez or spellSetting.rez == false)) or not UnitIsConnected(unit) then
					-- --button.texture:SetVertexColor(1, 0.1, 0.1)
					-- --button:SetBackdropColor(1,0.1,0.1)
					-- --button:SetBackdropBorderColor(1,0.1,0.1)
					button.texture:SetVertexColor(1, 0.1, 0.1)
				end
			end
		end
	else
		for index, spellSetting in ipairs(SpecSettings.spells) do
			local button = frame.hButtons[index]
			if button.hOOR and not button.hInvalid then
				-- out of range -> color in red
				button.texture:SetVertexColor(1.0, 0.3, 0.3)
			elseif button.hPrereqFailed and not button.hInvalid then
				-- button disabled -> color in gray
				button.texture:SetVertexColor(0.2, 0.2, 0.2)
			elseif button.hOOM and not button.hInvalid then
				-- no mana -> color in blue
				button.texture:SetVertexColor(0.5, 0.5, 1.0)
			elseif button.hDispelHighlight ~= "none" and not button.hInvalid then
				-- dispel highlight -> color with debuff color
				local debuffColor = DebuffTypeColor[button.hDispelHighlight] or DebuffTypeColor["none"]
				button:SetBackdropColor(debuffColor.r, debuffColor.g, debuffColor.b)
				-- --button:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				button.texture:SetVertexColor(debuffColor.r, debuffColor.g, debuffColor.b)
			else
				button.texture:SetVertexColor(1, 1, 1)
				button:SetBackdropColor(0.6, 0.6, 0.6)
				button:SetBackdropBorderColor(0.1, 0.1, 0.1)
			end
		end
	end
end

-- Update healium frame debuff position, debuff must be anchored to last shown button
local function UpdateFrameDebuffsPosition(frame)
	PerformanceCounter:Increment("TukuiHealium", "UpdateFrameDebuffsPosition")
	if not frame.hDebuffs or not frame.hButtons then return end
	--DEBUG("UpdateFrameDebuffsPosition")
	--DEBUG("Update debuff position for "..frame:GetName())
	local anchor = frame
	if SpecSettings then -- if no heal buttons, anchor to unitframe
		anchor = frame.hButtons[#SpecSettings.spells]
	end
	--local anchor = frame.hButtons[#SpecSettings.spells]
	local firstDebuff = frame.hDebuffs[1]
	--DEBUG("anchor: "..anchor:GetName().."  firstDebuff: "..firstDebuff:GetName())
	local debuffSpacing = SpecSettings and SpecSettings.debuffSpacing or 2
	firstDebuff:ClearAllPoints()
	firstDebuff:Point("TOPLEFT", anchor, "TOPRIGHT", debuffSpacing, 0)
end

-- Update healium frame buff/debuff and prereq
local listBuffs = {}
local listDebuffs = {}
local function UpdateFrameBuffsDebuffsPrereqs(frame)
	PerformanceCounter:Increment("TukuiHealium", "UpdateFrameBuffsDebuffsPrereqs")
	local unit = frame.unit
	if not unit then return end

	--DEBUG("UpdateFrameBuffsDebuffsPrereqs: frame: "..frame:GetName().." unit: "..(unit or "nil"))

	-- reset button.hPrereqFailed and button.hDispelHighlight
	if frame.hButtons and not frame.hDisabled then
		--DEBUG("---- reset dispel, disabled")
		for index, button in ipairs(frame.hButtons) do
			button.hDispelHighlight = "none"
			button.hPrereqFailed = false
		end
	end
	
	-- buff: parse buff even if showDebuff is set to false for prereq
	--local buffs = {} -- list of spellID
	local buffCount = 0
	if not frame.hDisabled then
		local buffIndex = 1
		if SpecSettings then
			for i = 1, 40, 1 do
				-- get buff
				name, _, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitAura(unit, i, "PLAYER|HELPFUL")
				if not name then 
					buffCount = i-1
					break 
				end
				--tinsert(buffs, spellID) -- display only buff castable by player but keep whole list of buff to check prereq
				listBuffs[i] = spellID
				-- is buff casted by player and in spell list?
				local found = false
				for index, spellSetting in ipairs(SpecSettings.spells) do
					if spellSetting.spellID and spellSetting.spellID == spellID then
						found = true
					elseif spellSetting.macroName then
						local macroID = GetMacroIndexByName(spellSetting.macroName)
						if macroID > 0 then
							local spellName = GetMacroSpell(macroID)
							if spellName == name then
								found = true
							end
						end
					end
				end
				if found and frame.hBuffs then
					-- buff casted by player and in spell list
					local buff = frame.hBuffs[buffIndex]
					-- id, unit  used by tooltip
					buff:SetID(i)
					buff.unit = unit
					-- texture
					buff.icon:SetTexture(icon)
					-- count
					if count > 1 then
						buff.count:SetText(count)
						buff.count:Show()
					else
						buff.count:Hide()
					end
					-- cooldown
					if duration and duration > 0 then
						local startTime = expirationTime - duration
						buff.cooldown:SetCooldown(startTime, duration)
					else
						buff.cooldown:Hide()
					end
					-- show
					buff:Show()
					-- next buff
					buffIndex = buffIndex + 1
					-- too many buff?
					if buffIndex > MaxBuffCount then
						--WARNING(string.format(L.healium_BUFFDEBUFF_TOOMANYBUFF, frame:GetName(), unit))
						break
					end
				end
			end
		end
		if frame.hBuffs then
			for i = buffIndex, MaxBuffCount, 1 do
				-- hide remainder buff
				local buff = frame.hBuffs[i]
				buff:Hide()
			end
		end
	end

	-- debuff: parse debuff even if showDebuff is set to false for prereq
	--local debuffs = {} -- list of couple (spellID, debuffType)
	local debuffCount = 0
	local debuffIndex = 1
	if SpecSettings or HealiumSettings.Options.showDebuff then
		for i = 1, 40, 1 do
			-- get debuff
			local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID = UnitDebuff(unit, i)
			if not name then
				debuffCount = i-1
				break
			end
			--debuffType = "Poison" -- DEBUG purpose :)
			-- if debuffType then
				-- DEBUG("debuffType: "..debuffType)
			-- end
			--tinsert(debuffs, {spellID, debuffType}) -- display not filtered debuff but keep whole debuff list to check prereq
			listDebuffs[i] = {spellID, debuffType}
			local dispellable = false -- default: non-dispellable
			if debuffType then
				for _, spellSetting in ipairs(SpecSettings.spells) do
					if spellSetting.dispels then
						local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
						if canDispel then
							dispellable = true
							break
						end
					end
				end
			end
			local filtered = false -- default: not filtered
			if not dispellable then
				-- non-dispellable are rejected or filtered using blacklist/whitelist
				if HealiumSettings.Options.debuffFilter == "DISPELLABLE" then
					filtered = true
				elseif HealiumSettings.Options.debuffFilter == "BLACKLIST" and HealiumSettings.Options.debuffBlacklist then
					-- blacklisted ?
					filtered = false -- default: not filtered
					for _, entry in ipairs(HealiumSettings.Options.debuffBlacklist) do
						if entry.spellName == name then
							filtered = true -- found in blacklist -> filtered
							break
						end
					end
				elseif HealiumSettings.Options.debuffFilter == "WHITELIST" and HealiumSettings.Options.debuffWhitelist then
					-- whitelisted ?
					filtered = true -- default: filtered
					for _, entry in ipairs(HealiumSettings.Options.debuffWhitelist) do
						if entry.spellName == name then
							filtered = false -- found in whilelist -> not filtered
							break
						end
					end
				end
			end
			if not filtered and frame.hDebuffs then
				-- debuff not filtered
				local debuff = frame.hDebuffs[debuffIndex]
				-- id, unit  used by tooltip
				debuff:SetID(i)
				debuff.unit = unit
				-- texture
				debuff.icon:SetTexture(icon)
				-- count
				if count > 1 then
					debuff.count:SetText(count)
					debuff.count:Show()
				else
					debuff.count:Hide()
				end
				-- cooldown
				if duration and duration > 0 then
					local startTime = expirationTime - duration
					debuff.cooldown:SetCooldown(startTime, duration)
					debuff.cooldown:Show()
				else
					debuff.cooldown:Hide()
				end
				-- debuff color
				local debuffColor = debuffType and DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
				--DEBUG("debuffType: "..(debuffType or 'nil').."  debuffColor: "..(debuffColor and debuffColor.r or 'nil')..","..(debuffColor and debuffColor.g or 'nil')..","..(debuffColor and debuffColor.b or 'nil'))
				debuff:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
				-- show
				debuff:Show()
				-- next debuff
				debuffIndex = debuffIndex + 1
				--- too many debuff?
				if debuffIndex > MaxDebuffCount then
					--WARNING(string.format(L.healium_BUFFDEBUFF_TOOMANYDEBUFF, frame:GetName(), unit))
					break
				end
			end
		end
	end
	if frame.hDebuffs then
		for i = debuffIndex, MaxDebuffCount, 1 do
			-- hide remainder debuff
			local debuff = frame.hDebuffs[i]
			debuff:Hide()
		end
	end

	--DEBUG("BUFF:"..buffCount.."  DEBUFF:"..debuffCount)

	-- color dispel button if dispellable debuff + prereqs management (is buff or debuff a prereq to enable/disable a spell)
	if SpecSettings and frame.hButtons and not frame.hDisabled then
		local debuffDispellableFound = false
		local highlightDispel = Getter(HealiumSettings.Options.highlightDispel, true)
		local playSound = Getter(HealiumSettings.Options.playSoundOnDispel, true)
		local flashDispel = Getter(HealiumSettings.Options.flashDispel, true)
		for index, spellSetting in ipairs(SpecSettings.spells) do
			local button = frame.hButtons[index]
			-- buff prereq: if not present, spell is inactive
			if spellSetting.buffs then
				--DEBUG("searching buff prereq for "..spellSetting.spellID)
				local prereqBuffFound = false
				for _, prereqBuffSpellID in ipairs(spellSetting.buffs) do
					--DEBUG("buff prereq for "..spellSetting.spellID.." "..prereqBuffSpellID)
					--for _, buff in pairs(listBuffs) do
					for i = 1, buffCount, 1 do
						local buff = listBuffs[i]
						--DEBUG("buff on unit "..buffSpellID)
						if buff == prereqBuffSpellID then
							--DEBUG("PREREQ: "..prereqBuffSpellID.." is a buff prereq for "..spellSetting.spellID.." "..button:GetName())
							prereqBuffFound = true
							break
						end
					end
					if prereqBuffFound then break end
				end
				if not prereqBuffFound then
					--DEBUG("PREREQ: BUFF for "..spellSetting.spellID.." NOT FOUND")
					button.hPrereqFailed = true
				end
			end
			-- debuff prereq: if present, spell is inactive
			if spellSetting.debuffs then
				--DEBUG("searching buff prereq for "..spellSetting.spellID)
				local prereqDebuffFound = false
				for _, prereqDebuffSpellID in ipairs(spellSetting.debuffs) do
					--DEBUG("buff prereq for "..spellSetting.spellID.." "..prereqDebuffSpellID)
					--for _, debuff in ipairs(listDebuffs) do
					for i = 1, debuffCount, 1 do
						local debuff = listDebuffs[i]
						local debuffSpellID = debuff[1] -- [1] = spellID
						--DEBUG("debuff on unit "..debuffSpellID)
						if debuffSpellID == prereqDebuffSpellID then
							--DEBUG("PREREQ: "..prereqDebuffSpellID.." is a debuff prereq for "..spellSetting.spellID.." "..button:GetName())
							prereqDebuffFound = true
							break
						end
					end
					if prereqDebuffFound then break end
				end
				if prereqDebuffFound then
					--DEBUG("PREREQ: DEBUFF for "..spellSetting.spellID.." FOUND")
					button.hPrereqFailed = true
				end
			end
			-- color dispel button if affected by a debuff curable by a player spell
			if spellSetting.dispels and (highlightDispel or playSound or flashDispel) then
				--for _, debuff in ipairs(listDebuffs) do
				for i = 1, debuffCount, 1 do
					local debuff = listDebuffs[i]
					local debuffType = debuff[2] -- [2] = debuffType
					if debuffType then
						--DEBUG("type: "..type(spellSetting.dispels[debuffType]))
						local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
						if canDispel then
							--print("DEBUFF dispellable")
							local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
							-- Highlight dispel button?
							if highlightDispel then
								button.hDispelHighlight = debuffType
							end
							-- Flash dispel?
							if flashDispel and UnitInRange(unit) then
								FlashFrame:ShowFlashFrame(button, debuffColor, 320, 100, false)
							end
							debuffDispellableFound = true
							break -- a debuff dispellable is enough
						end
					end
				end
			end
		end
		if debuffDispellableFound then
			-- Play sound?
			if playSound and UnitInRange(unit) then
				local now = GetTime()
				--print("DEBUFF in range: "..now.."  "..h_listDebuffsoundTime)
				if now > listDebuffsoundTime + 7 then -- no more than once every 7 seconds
					--print("DEBUFF in time")
					PlaySoundFile(DispelSoundFile)
					listDebuffsoundTime = now
				end
			end
		end
	end

	-- Color buttons
	UpdateButtonsColor(frame)
end

-- Update healium frame buttons, set texture, extra attributes and show/hide.
local function UpdateFrameButtons(frame)
	PerformanceCounter:Increment("TukuiHealium", "UpdateFrameButtons")
	if InCombatLockdown() then
		--DEBUG("UpdateFrameButtons: Cannot update buttons while in combat")
		return
	end
	--DEBUG("Update frame buttons for "..frame:GetName())
	if not frame.hButtons then return end
	for i, button in ipairs(frame.hButtons) do
		if SpecSettings and i <= #SpecSettings.spells then
			local spellSetting = SpecSettings.spells[i]
			local icon, name, type
			if spellSetting.spellID then
				if IsSpellLearned(spellSetting.spellID) then
					type = "spell"
					name, _, icon = GetSpellInfo(spellSetting.spellID)
					button.hSpellBookID = GetSpellBookID(name)
					button.hMacroName = nil
				end
			elseif spellSetting.macroName then
				if GetMacroIndexByName(spellSetting.macroName) > 0 then
					type = "macro"
					icon = select(2,GetMacroInfo(spellSetting.macroName))
					name = spellSetting.macroName
					button.hSpellBookID = nil
					button.hMacroName = name
				end
			end
			if type and name and icon then
				--DEBUG("show button "..i.." "..frame:GetName().."  "..name)
				button.texture:SetTexture(icon)
				button:SetAttribute("type", type)
				button:SetAttribute(type, name)
				button.hInvalid = false
			else
				--DEBUG("invalid button "..i.." "..frame:GetName())
				button.hInvalid = true
				button.hSpellBookID = spellSetting.spellID
				button.hMacroName = spellSetting.macroName
				button.texture:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
				button:SetAttribute("type","target") -- action is target if spell is not valid
			end
			button:Show()
		else
			--DEBUG("hide button "..i.." "..frame:GetName())
			button.hInvalid = true
			button.hSpellBookID = nil
			button.hMacroName = nil
			button.texture:SetTexture("")
			button:Hide()
		end
	end
end

-- For each spell, get cooldown then loop among Healium Unitframes and set cooldown
local lastCD = {}
local function UpdateCooldowns()
	PerformanceCounter:Increment("TukuiHealium", "UpdateCooldowns")
	--DEBUG("UpdateCooldowns")
	if not SpecSettings then return end
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local start, duration, enabled
		if spellSetting.spellID then
			start, duration, enabled = GetSpellCooldown(spellSetting.spellID)
		elseif spellSetting.macroName then
			local name = GetMacroSpell(spellSetting.macroName)
			if name then
				start, duration, enabled = GetSpellCooldown(name)
			else
				enabled = false
			end
		end
		if start and start > 0 then
			local arrayEntry = lastCD[index]
			if not arrayEntry or arrayEntry.start ~= start or arrayEntry.duration ~= duration then
				--DEBUG("CD KEEP:"..index.."  "..start.."  "..duration.."  /  "..(arrayEntry and arrayEntry.start or 'nil').."  "..(arrayEntry and arrayEntry.duration or 'nil'))
				ForEachMember(UpdateButtonCooldown, index, start, duration, enabled)
				lastCD[index] = { start = start, duration = duration }
			else
				--DEBUG("CD SKIP:"..index.."  "..start.."  "..duration.."  /  "..(arrayEntry and arrayEntry.start or 'nil').."  "..(arrayEntry and arrayEntry.duration or 'nil'))
			end
		-- else
			-- DEBUG("CD: skipping:"..index)
		end
	end
end

-- Check OOM spells
local lastOOM = {}
local function UpdateOOMSpells()
	PerformanceCounter:Increment("TukuiHealium", "UpdateOOMSpells")
	if not HealiumSettings.Options.showOOM then return end
	--DEBUG("UpdateOOMSpells")
	if not SpecSettings then return end
	local change = false -- TODO: remove this flag by calling a new method ForEachMember(UpdateButtonColor, frame, index) -- update frame.hButtons[index] color
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local spellName
		if spellSetting.spellID then
			spellName = GetSpellInfo(spellSetting.spellID) -- TODO: store spellName in settings or in button
		elseif spellSetting.macroName then
			local macroID = GetMacroIndexByName(spellSetting.macroName)
			if macroID > 0 then
				spellName = GetMacroSpell(macroID)
			end
		end
		if spellName then
			--DEBUG("spellName:"..spellName)
			local OOM = select(2, IsUsableSpell(spellName))
			if lastOOM[index] ~= OOM then
				local change = true
				lastOOM[index] = OOM
				ForEachMember(UpdateButtonOOM, index, OOM)
			-- else
				-- DEBUG("Skipping UpdateButtonOOM:"..index)
			end
		end
	end
	if change then
		ForEachMember(UpdateButtonsColor)
	end
end

-- Check OOR spells
local function UpdateOORSpells()
	PerformanceCounter:Increment("TukuiHealium", "UpdateOORSpells")
	if not HealiumSettings.Options.showOOR then return end
	--DEBUG("UpdateOORSpells")
	if not SpecSettings then return end
	for index, spellSetting in ipairs(SpecSettings.spells) do
		local spellName
		if spellSetting.spellID then
			spellName = GetSpellInfo(spellSetting.spellID) -- TODO: store spellName in settings or in button
		elseif spellSetting.macroName then
			local macroID = GetMacroIndexByName(spellSetting.macroName)
			if macroID > 0 then
				spellName = GetMacroSpell(macroID)
			end
		end
		if spellName then
			--DEBUG("spellName:"..spellName)
			ForEachMember(UpdateButtonOOR, index, spellName)
		end
	end
	ForEachMember(UpdateButtonsColor)
end

-- Change player's name's color if it has aggro or not
local function UpdateThreat(self, event, unit)
	PerformanceCounter:Increment("TukuiHealium", "UpdateThreat")
	if (self.unit ~= unit) or (unit == "target" or unit == "pet" or unit == "focus" or unit == "focustarget" or unit == "targettarget") then return end
	local threat = UnitThreatSituation(self.unit)
	--DEBUG("UpdateThreat:"..tostring(self.unit).." / "..tostring(unit).." --> "..tostring(threat))
	if threat and threat > 1 then
		--self.Name:SetTextColor(1,0.1,0.1)
		local r, g, b = GetThreatStatusColor(threat)
		--DEBUG("==>"..r..","..g..","..b)
		self.Name:SetTextColor(r, g, b)
	else
		self.Name:SetTextColor(1, 1, 1)
	end
end

-- PostUpdateHealth, called after health bar has been updated
local function PostUpdateHealth(health, unit, min, max)
	PerformanceCounter:Increment("TukuiHealium", "PostUpdateHeal")
	--DEBUG("PostUpdateHeal: "..(unit or "nil"))
	-- call normal raid post update heal
	T.PostUpdateHealthRaid(health, unit, min, max)

	local frame = health:GetParent()
	--local unit = frame.unit

	--DEBUG("PostUpdateHeal: "..frame:GetName().."  "..(unit or 'nil'))
	if not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit) then
		--DEBUG("->DISABLE")
		frame.hDisabled = true
		-- hide buff
		if frame.hBuffs then
			--DEBUG("disable healium buffs")
			for _, buff in ipairs(frame.hBuffs) do
				buff:Hide()
			end
		end
		UpdateButtonsColor(frame)
	elseif frame.hDisabled then
		--DEBUG("DISABLED")
		frame.hDisabled = false
		UpdateButtonsColor(frame)
	end
	local showPercentage = Getter(HealiumSettings.Options.showPercentage, false)
	if showPercentage and min ~= max and UnitIsConnected(unit) and not UnitIsDead(unit) and not UnitIsGhost(unit) then
		local r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)
		--health.value:SetText("|cff559655-"..h_ShortValueNegative(max-min).."|r")
		--health.value:SetFormattedText("|cff%02x%02x%02x-"..h_ShortValueNegative(max-min).."|r", r * 255, g * 255, b * 255)
		--health.value:SetFormattedText("|cffAF5050%d|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r", min, r * 255, g * 255, b * 255, floor(min / max * 100))
		health.value:SetFormattedText("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, floor(min / max * 100))
	end
end

-------------------------------------------------------
-- Unitframe and healium buttons/buff/debuffs creation
-------------------------------------------------------
-- Create heal buttons for a frame
local function CreateFrameButtons(frame)
	if not frame then return end
	if frame.hButtons then return end

	--DEBUG("CreateFrameButtons")
	if InCombatLockdown() then
		--DEBUG("CreateFrameButtons: delayed creation of frame "..frame:GetName())
		tinsert(DelayedButtonsCreation, frame)
		return
	end

	frame.hButtons = {}
	local spellSize = frame:GetHeight()
	local spellSpacing = 2
	for i = 1, MaxButtonCount, 1 do
		-- name
		local buttonName = frame:GetName().."_HealiumButton_"..i
		-- frame
		local button = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")
		button:CreatePanel("Default", spellSize, spellSize, "TOPLEFT", frame, "TOPRIGHT", spellSpacing, 0)
		if i == 1 then
			button:Point("TOPLEFT", frame, "TOPRIGHT", spellSpacing, 0)
		else
			button:Point("TOPLEFT", frame.hButtons[i-1], "TOPRIGHT", spellSpacing, 0)
		end
		-- texture setup, texture icon is set in UpdateFrameButtons
		button.texture = button:CreateTexture(nil, "BORDER")
		button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button.texture:SetPoint("TOPLEFT", button ,"TOPLEFT", 0, 0)
		button.texture:SetPoint("BOTTOMRIGHT", button ,"BOTTOMRIGHT", 0, 0)
		button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
		button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
		button.texture:SetVertexColor(1, 1, 1)
		button:SetBackdropColor(0.6, 0.6, 0.6)
		button:SetBackdropBorderColor(0.1, 0.1, 0.1)
		-- cooldown overlay
		button.cooldown = CreateFrame("Cooldown", "$parentCD", button, "CooldownFrameTemplate")
		button.cooldown:SetAllPoints(button.texture)
		-- click event/action, attributes 'type' and 'spell' are set in UpdateFrameButtons
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("useparent-unit","true")
		button:SetAttribute("*unit2", "target")
		-- tooltip
		if HealiumSettings.Options.showButtonTooltip then
			button:SetScript("OnEnter", ButtonOnEnter)
			button:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- custom
		button.hPrereqFailed = false
		button.hOOM = false
		button.hDispelHighlight = "none"
		button.hOOR = false
		button.hInvalid = true
		-- hide
		button:Hide()
		-- save button
		tinsert(frame.hButtons, button)
	end
end

-- Create debuffs for a frame
local function CreateFrameDebuffs(frame)
	if not frame then return end
	if frame.hDebuffs then return end

	--DEBUG("CreateFrameDebuffs")
	frame.hDebuffs = {}
	local debuffSize = frame:GetHeight()
	local debuffSpacing = 2
	for i = 1, MaxDebuffCount, 1 do
		--DEBUG("Create debuff "..i)
		-- name
		local debuffName = frame:GetName().."_HealiumDebuff_"..i
		-- frame
		local debuff = CreateFrame("Frame", debuffName, frame) -- --debuff = CreateFrame("Frame", debuffName, frame, "TargetDebuffFrameTemplate")
		debuff:CreatePanel("Default", debuffSize, debuffSize, "TOPLEFT", frame, "TOPRIGHT", debuffSpacing, 0)
		if i == 1 then
			debuff:Point("TOPLEFT", frame, "TOPRIGHT", debuffSpacing, 0)
		else
			debuff:Point("TOPLEFT", frame.hDebuffs[i-1], "TOPRIGHT", debuffSpacing, 0)
		end
		-- icon
		debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
		debuff.icon:Point("TOPLEFT", 2, -2)
		debuff.icon:Point("BOTTOMRIGHT", -2, 2)
		debuff.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		-- cooldown
		debuff.cooldown = CreateFrame("Cooldown", "$parentCD", debuff, "CooldownFrameTemplate")
		debuff.cooldown:SetAllPoints(debuff.icon)
		debuff.cooldown:SetReverse()
		-- count
		debuff.count = debuff:CreateFontString("$parentCount", "OVERLAY")
		debuff.count:SetFont(C["media"].uffont, 14, "OUTLINE")
		debuff.count:Point("BOTTOMRIGHT", 1, -1)
		debuff.count:SetJustifyH("CENTER")
		-- tooltip
		if HealiumSettings.Options.showBuffDebuffTooltip then
			debuff:SetScript("OnEnter", DebuffOnEnter)
			debuff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- hide
		debuff:Hide()
		-- save debuff
		tinsert(frame.hDebuffs, debuff)
	end
end

-- Create buff for a frame
local function CreateFrameBuffs(frame)
	if not frame then return end
	if frame.hBuffs then return end

	--DEBUG("CreateFrameBuffs")
	frame.hBuffs = {}
	local buffSize = frame:GetHeight()
	local buffSpacing = 2
	for i = 1, MaxBuffCount, 1 do
		local buffName = frame:GetName().."_HealiumBuff_"..i
		local buff = CreateFrame("Frame", buffName, frame) --buff = CreateFrame("Frame", buffName, frame, "TargetBuffFrameTemplate")
		buff:CreatePanel("Default", buffSize, buffSize, "TOPRIGHT", frame, "TOPLEFT", -buffSpacing, 0)
		if i == 1 then
			buff:Point("TOPRIGHT", frame, "TOPLEFT", -buffSpacing, 0)
		else
			buff:Point("TOPRIGHT", frame.hBuffs[i-1], "TOPLEFT", -buffSpacing, 0)
		end
		-- icon
		buff.icon = buff:CreateTexture(nil, "ARTWORK")
		buff.icon:Point("TOPLEFT", 2, -2)
		buff.icon:Point("BOTTOMRIGHT", -2, 2)
		buff.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		-- cooldown
		buff.cooldown = CreateFrame("Cooldown", "$parentCD", buff, "CooldownFrameTemplate")
		buff.cooldown:SetAllPoints(buff.icon)
		buff.cooldown:SetReverse()
		-- count
		buff.count = buff:CreateFontString("$parentCount", "OVERLAY")
		buff.count:SetFont(C["media"].uffont, 14, "OUTLINE")
		buff.count:Point("BOTTOMRIGHT", 1, -1)
		buff.count:SetJustifyH("CENTER")
		-- tooltip
		if HealiumSettings.Options.showBuffDebuffTooltip then
			buff:SetScript("OnEnter", BuffOnEnter)
			buff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- hide
		buff:Hide()
		-- save buff
		tinsert(frame.hBuffs, buff)
	end
end

-- Create delayed frames
local function CreateDelayedButtons()
	if InCombatLockdown() then return false end
	--DEBUG("CreateDelayedButtons:"..tostring(DelayedButtonsCreation).."  "..(#DelayedButtonsCreation))
	if not DelayedButtonsCreation or #DelayedButtonsCreation == 0 then return false end

	for _, frame in ipairs(DelayedButtonsCreation) do
		--DEBUG("Delayed frame creation for "..frame:GetName())
		if not frame.hButtons then
			CreateFrameButtons(frame)
		--else
			--DEBUG("Frame already created for "..frame:GetName())
		end
	end
	DelayedButtonsCreation = {}
	return true
end

local function CreateUnitframe(self, unit)
	--Message("CreateUnitframe: "..(unit or "nil").."  "..self:GetName())

	self.colors = T.oUF_colors
	self:RegisterForClicks("AnyUp")
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self.menu = T.SpawnMenu

	self:SetBackdrop({bgFile = C["media"].blank, insets = {top = -T.mult, left = -T.mult, bottom = -T.mult, right = -T.mult}})
	self:SetBackdropColor(0.1, 0.1, 0.1)

	local health = CreateFrame('StatusBar', nil, self)
	health:SetPoint("TOPLEFT")
	health:SetPoint("TOPRIGHT")
	health:Height(27*T.raidscale)
	health:SetStatusBarTexture(C["media"].normTex)
	self.Health = health

	health.bg = health:CreateTexture(nil, 'BORDER')
	health.bg:SetAllPoints(health)
	health.bg:SetTexture(C["media"].normTex)
	health.bg:SetTexture(0.3, 0.3, 0.3)
	health.bg.multiplier = 0.3
	self.Health.bg = health.bg

	health.value = health:CreateFontString(nil, "OVERLAY")
	health.value:SetPoint("RIGHT", health, -3, 1)
	health.value:SetFont(C["media"].uffont, 12*T.raidscale, "THINOUTLINE")
	health.value:SetTextColor(1,1,1)
	health.value:SetShadowOffset(1, -1)
	self.Health.value = health.value

	health.PostUpdate = PostUpdateHealth
	health.frequentUpdates = true

	if C.unitframes.unicolor == true then
		health.colorDisconnected = false
		health.colorClass = false
		health:SetStatusBarColor(.3, .3, .3, 1)
		health.bg:SetVertexColor(.1, .1, .1, 1)
	else
		health.colorDisconnected = true
		health.colorClass = true
		health.colorReaction = true
	end

	local power = CreateFrame("StatusBar", nil, self)
	power:Height(4*T.raidscale)
	power:Point("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
	power:Point("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
	power:SetStatusBarTexture(C["media"].normTex)
	self.Power = power
	
	power.frequentUpdates = true
	power.colorDisconnected = true

	power.bg = self.Power:CreateTexture(nil, "BORDER")
	power.bg:SetAllPoints(power)
	power.bg:SetTexture(C["media"].normTex)
	power.bg:SetAlpha(1)
	power.bg.multiplier = 0.4
	self.Power.bg = power.bg

	if C.unitframes.unicolor == true then
		power.colorClass = true
		power.bg.multiplier = 0.1
	else
		power.colorPower = true
	end

	local name = health:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", health, 3, 0)
	name:SetFont(C["media"].uffont, 12*T.raidscale, "THINOUTLINE")
	name:SetShadowOffset(1, -1)
	self:Tag(name, "[Tukui:namemedium]")
	self.Name = name

	local leader = health:CreateTexture(nil, "OVERLAY")
	leader:Height(12*T.raidscale)
	leader:Width(12*T.raidscale)
	leader:SetPoint("TOPLEFT", 0, 6)
	self.Leader = leader

	--t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
	--SetRaidTargetIconTexture(t,i);
	local LFDRole = health:CreateTexture(nil, "OVERLAY")
	LFDRole:Height(6*T.raidscale)
	LFDRole:Width(6*T.raidscale)
	LFDRole:Point("TOPRIGHT", -2, -2)
	LFDRole:SetTexture("Interface\\AddOns\\Tukui\\medias\\textures\\lfdicons.blp")
	self.LFDRole = LFDRole

	local masterLooter = health:CreateTexture(nil, "OVERLAY")
	masterLooter:Height(12*T.raidscale)
	masterLooter:Width(12*T.raidscale)
	self.MasterLooter = masterLooter
	self:RegisterEvent("PARTY_LEADER_CHANGED", T.MLAnchorUpdate)
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", T.MLAnchorUpdate)

	if C["unitframes"].aggro == true then
		table.insert(self.__elements, UpdateThreat)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', UpdateThreat)
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', UpdateThreat)
		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', UpdateThreat)
	end

	if C["unitframes"].showsymbols == true then
		local RaidIcon = health:CreateTexture(nil, 'OVERLAY')
		RaidIcon:Height(18*T.raidscale)
		RaidIcon:Width(18*T.raidscale)
		RaidIcon:SetPoint('CENTER', self, 'TOP')
		RaidIcon:SetTexture("Interface\\AddOns\\Tukui\\medias\\textures\\raidicons.blp") -- thx hankthetank for texture
		self.RaidIcon = RaidIcon
	end

	local ReadyCheck = self.Power:CreateTexture(nil, "OVERLAY")
	ReadyCheck:Height(12*T.raidscale)
	ReadyCheck:Width(12*T.raidscale)
	ReadyCheck:SetPoint('CENTER')
	self.ReadyCheck = ReadyCheck

	if C["unitframes"].showrange == true then
		local range = {insideAlpha = 1, outsideAlpha = C["unitframes"].raidalphaoor}
		self.Range = range
	end

	if C["unitframes"].showsmooth == true then
		health.Smooth = true
		power.Smooth = true
	end

	local unitframeWidth = HealiumSettings.Options.unitframeWidth or 120
	if C["unitframes"].healcomm then
		local mhpb = CreateFrame('StatusBar', nil, self.Health)
		mhpb:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		mhpb:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
		mhpb:SetWidth(unitframeWidth*T.raidscale)
		mhpb:SetStatusBarTexture(C["media"].normTex)
		mhpb:SetStatusBarColor(0, 1, 0.5, 0.25)

		local ohpb = CreateFrame('StatusBar', nil, self.Health)
		ohpb:SetPoint('TOPLEFT', mhpb:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		ohpb:SetPoint('BOTTOMLEFT', mhpb:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
		ohpb:SetWidth(unitframeWidth*T.raidscale)
		ohpb:SetStatusBarTexture(C["media"].normTex)
		ohpb:SetStatusBarColor(0, 1, 0, 0.25)

		self.HealPrediction = {
			myBar = mhpb,
			otherBar = ohpb,
			maxOverflow = 1,
		}
	end

	-- heal buttons
	CreateFrameButtons(self)

	-- healium debuffs
	if HealiumSettings.Options.showDebuff then
		CreateFrameDebuffs(self)
	end

	-- healium buffs
	if HealiumSettings.Options.showBuff then
		CreateFrameBuffs(self)
	end

	-- update healium buttons visibility, icon and attributes
	UpdateFrameButtons(self)

	-- update debuff position
	UpdateFrameDebuffsPosition(self)

	-- update buff/debuff/special spells
	--UpdateFrameBuffsDebuffsPrereqs(self) -- unit not yet set, unit passed as argument is "raid" instead of player or party1 or ...

	-- custom
	self.hDisabled = false

	-- save frame in healium frame list
	SaveFrame(self)

	return self
end

-------------------------------------------------------
-- Handle events for Healium features
-------------------------------------------------------
local fSettingsChecked = false
local function OnEvent(self, event, arg1, arg2, arg3)
	--DEBUG("Event: "..event)

	PerformanceCounter:Increment("TukuiHealium", event)

	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		--DEBUG("ADDON_LOADED:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		local version = GetAddOnMetadata(ADDON_NAME, "version")
		if version then
			Message(string.format(L.healium_GREETING_VERSION, tostring(version)))
		else
			Message(L.healium_GREETING_VERSIONUNKNOWN)
		end
		Message(L.healium_GREETING_OPTIONS)
		SpecSettings = GetSpecSettings()
	elseif event == "PLAYER_LOGIN" then
		--DEBUG("PLAYER_LOGIN:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		SpecSettings = GetSpecSettings()
		if SpecSettings then
			fSettingsChecked = true
			CheckSpellSettings()
		end
	elseif event == "PLAYER_ALIVE" then
		--DEBUG("PLAYER_ALIVE:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).."  "..tostring(IsLoggedIn()))
		SpecSettings = GetSpecSettings()
		if SpecSettings and not fSettingsChecked then
			CheckSpellSettings()
		end
		ForEachMember(UpdateFrameButtons)
		ForEachMember(UpdateFrameDebuffsPosition)
		ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PLAYER_ENTERING_WORLD" then
		--DEBUG("PLAYER_ENTERING_WORLD:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing).."  "..tostring(IsLoggedIn()))
		ForEachMember(UpdateFrameButtons)
		ForEachMember(UpdateFrameDebuffsPosition)
		ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		ForEachMember(UpdateFrameButtons)
		ForEachMember(UpdateFrameDebuffsPosition)
		ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
	elseif event == "PLAYER_REGEN_ENABLED" then
		--DEBUG("PLAYER_REGEN_ENABLED")
		local created = CreateDelayedButtons()
		if created then
			ForEachMember(UpdateFrameButtons)
			ForEachMember(UpdateFrameDebuffsPosition)
			ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
		end
	elseif event == "UNIT_SPELLCAST_SENT" and (arg2 == ActivatePrimarySpecSpellName or arg2 == ActivateSecondarySpecSpellName) then
		--DEBUG("UNIT_SPELLCAST_SENT:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		self.hRespecing = 1 -- respec started
	elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED") and arg1 == "player" and (arg2 == ActivatePrimarySpecSpellName or arg2 == ActivateSecondarySpecSpellName) then
		--DEBUG("UNIT_SPELLCAST_INTERRUPTED:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		self.hRespecing = nil --> respec stopped
	elseif event == "PLAYER_TALENT_UPDATE" then
		--DEBUG("PLAYER_TALENT_UPDATE:"..tostring(GetPrimaryTalentTree()).."  "..tostring(IsSpellLearned(974)).." "..tostring(self.hRespecing))
		if self.hRespecing == 2 then -- respec finished
			SpecSettings = GetSpecSettings()
			CheckSpellSettings()
			ForEachMember(UpdateFrameButtons)
			ForEachMember(UpdateFrameDebuffsPosition)
			ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
			self.hRespecing = nil -- no respec running
		elseif self.hRespecing == 1 then -- respec not yet finished
			self.hRespecing = 2 -- respec finished
		else -- respec = nil, not respecing (called while connecting)
			SpecSettings = GetSpecSettings()
			ForEachMember(UpdateFrameButtons)
			ForEachMember(UpdateFrameDebuffsPosition)
			ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
		end
	-- --elseif event == "SPELLS_CHANGED" and not self.hRespecing then
	-- elseif event == "SPELLS_CHANGED" then
		-- DEBUG("SPELLS_CHANGED:"..tostring(GetPrimaryTalentTree()).."  "..IsSpellLearned(974).." "..tostring(self.hRespecing))
		-- -- ForEachMember(UpdateFrameButtons)
		-- -- ForEachMember(UpdateFrameDebuffsPosition)
	-- end
	elseif event == "SPELL_UPDATE_COOLDOWN" then -- TODO: use SPELL_UPDATE_USABLE instead ?
		--DEBUG("SPELL_UPDATE_COOLDOWN:"..tostring(arg1).."  "..tostring(arg2).."  "..tostring(arg2))
		UpdateCooldowns()
	elseif event == "UNIT_AURA" then
		local frame = GetFrameFromUnit(arg1) -- Get frame from unit
		if frame then UpdateFrameBuffsDebuffsPrereqs(frame) end -- Update buff/debuff only for unit
	elseif (event == "UNIT_POWER" or event == "UNIT_MAXPOWER") and arg1 == "player" then-- or event == "SPELL_UPDATE_USABLE" then
		if HealiumSettings.Options.showOOM then
--			-- Update only if not enough power to cast the most expensive spell -> crappy optimisation, a druid will never have enough energy to cast healing spell
--			local currentValue = UnitPower("player")
--			if currentValue <= HighestCost then
			UpdateOOMSpells()
--			end
		end
	end
end

local function OnUpdate(self, elapsed)
	self.hTimeSinceLastUpdate = self.hTimeSinceLastUpdate + elapsed
	if self.hTimeSinceLastUpdate > UpdateDelay then
		if HealiumSettings.Options.showOOR then
			UpdateOORSpells()
		end
		self.hTimeSinceLastUpdate = 0
	end
end

-------------------------------------------------------
-- Slash command handler
-------------------------------------------------------
SLASH_THLM1 = "/th"
SLASH_THLM2 = "/thlm"
SlashCmdList["THLM"] = function(cmd)
	local function ShowHelp()
		Message(string.format(L.healium_CONSOLE_HELP_GENERAL, SLASH_THLM1, SLASH_THLM2))
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DEBUG)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPGENERAL)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPUNIT)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPPERF)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_DUMPSHOW)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_RESETPERF)
		Message(SLASH_THLM1..L.healium_CONSOLE_HELP_REFRESH)
	end
	local switch = cmd:match("([^ ]+)")
	local args = cmd:match("[^ ]+ (.+)")
	-- debug: switch Debug
	if switch == "debug" then
		Debug = not Debug
		Message(Debug == false and L.healium_CONSOLE_DEBUG_DISABLED or L.healium_CONSOLE_DEBUG_ENABLED)
	-- DumpSack: dump frame/button/buff/debuff informations
	elseif switch == "dump" then
		if not args then
			--ForEachMember(DumpFrame)
			for _, frame in ipairs(Unitframes) do -- We want to display every frames, no filter on unit or IsShown
				DumpFrame(frame)
			end
			DumpSack:Flush("TukuiHealium")
		elseif args == "perf" then
			--PerformanceCounter_Dump("TukuiHealium")
			local time = GetTime()
			local counters = PerformanceCounter:Get("TukuiHealium")
			if not counters then
				DumpSack:Add("No performance counters")
				DumpSack:Flush("TukuiHealium")
			else
				local timespan = GetTime() - LastPerformanceCounterReset
				local header = "Performance counters. Elapsed=%.2fsec"
				local line = "%s=#%d L:%.4f  H:%.2f -> %.2f/sec"
				DumpSack:Add(header:format(timespan))
				for key, value in pairs(counters) do
					local count = value.count or 1
					local lowestSpan = value.lowestSpan or 0
					local highestSpan = value.highestSpan or 0
					DumpSack:Add(line:format(key, count, lowestSpan, highestSpan, count/timespan))
				end
				DumpSack:Flush("TukuiHealium")
			end
		elseif args == "show" then
			DumpSack:Show()
		else
			--local frame = GetFrameFromUnit(args) -- Get frame from unit
			local found = false
			for _, frame in ipairs(Unitframes) do
				if frame.unit == args then
					DumpFrame(frame)
					DumpSack:Flush("TukuiHealium")
					found = true
					break
				end
			end
			if not found then
				Message(string.format(L.healium_CONSOLE_DUMP_UNITNOTFOUND,args))
			end
		end
	elseif switch == "reset" then
		if args == "perf" then
			PerformanceCounter:Reset("TukuiHealium")
			LastPerformanceCounterReset = GetTime()
			Message(L.healium_CONSOLE_RESET_PERF)
		end
	elseif switch == "refresh" then
		if InCombatLockdown() then
			Message(L.healium_CONSOLE_REFRESH_NOTINCOMBAT)
		else
			SpecSettings = GetSpecSettings()
			CheckSpellSettings()
			CreateDelayedButtons();
			ForEachMember(UpdateFrameButtons)
			ForEachMember(UpdateFrameDebuffsPosition)
			ForEachMember(UpdateFrameBuffsDebuffsPrereqs)
			UpdateCooldowns()
			if HealiumSettings.Options.showOOM then
				UpdateOOMSpells()
			end
			Message(L.healium_CONSOLE_REFRESH_OK)
		end
	else
		ShowHelp()
	end
end

-------------------------------------------------------
-- Main
-------------------------------------------------------
for class in pairs(HealiumSettings) do
	if class ~= T.myclass and class ~= "Options" then
		HealiumSettings[class] = nil
		--DEBUG("REMOVING "..class.." from settings")
	end
end

-- Fill blacklist and whitelist with spellName instead of spellID
if HealiumSettings.Options.debuffBlacklist and HealiumSettings.Options.debuffFilter == "BLACKLIST" then
	HealiumSettings.Options.debuffBlacklist = CreateDebuffFilterList("debuffBlacklist", HealiumSettings.Options.debuffBlacklist)
else
	--DEBUG("Clearing debuffBlacklist")
	HealiumSettings.Options.debuffBlacklist = nil
end

if HealiumSettings.Options.debuffWhitelist and HealiumSettings.Options.debuffFilter == "WHITELIST" then
	HealiumSettings.Options.debuffWhitelist = CreateDebuffFilterList("debuffWhitelist", HealiumSettings.Options.debuffWhitelist)
else
	--DEBUG("Clearing debuffWhitelist")
	HealiumSettings.Options.debuffWhitelist = nil
end

-- Register style
oUF:RegisterStyle('TukuiHealiumR01R25', CreateUnitframe)

-- Set unitframe creation handler
oUF:Factory(function(self)
	oUF:SetActiveStyle("TukuiHealiumR01R25")

	local unitframeWidth = HealiumSettings.Options.unitframeWidth or 120
	local unitframeHeight = HealiumSettings.Options.unitframeHeight or 28

	-- Players
	local playerRaid = self:SpawnHeader("oUF_TukuiHealiumRaid0125", nil, "custom [@raid26,exists] hide;show",
		'oUF-initialConfigFunction', [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute('initial-width'))
			self:SetHeight(header:GetAttribute('initial-height'))
		]],
		'initial-width', T.Scale(unitframeWidth*T.raidscale),
		'initial-height', T.Scale(unitframeHeight*T.raidscale),
		"showSolo", C["unitframes"].showsolo,
		"showParty", true,
		"showPlayer", C["unitframes"].showplayerinparty,
		"showRaid", true,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"yOffset", T.Scale(-4))
	playerRaid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 150, -300*T.raidscale)

	-- Pets, no pets in a group with 10 or more players
	if HealiumSettings.Options.showPets then
		local petRaid = self:SpawnHeader("oUF_TukuiHealiumRaidPet0125", "SecureGroupPetHeaderTemplate", "custom [@raid11,exists] hide;show",
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('initial-width'))
				self:SetHeight(header:GetAttribute('initial-height'))
			]],
			'initial-width', T.Scale(unitframeWidth*T.raidscale),--T.Scale(66*C["unitframes"].gridscale*T.raidscale),
			'initial-height', T.Scale(unitframeHeight*T.raidscale),--T.Scale(50*C["unitframes"].gridscale*T.raidscale),
			"showSolo", C["unitframes"].showsolo,
			"showParty", true,
			--"showPlayer", C["unitframes"].showplayerinparty,
			"showRaid", true,
			--"xoffset", T.Scale(3),
			"yOffset", T.Scale(-3),
			--"point", "LEFT",
			"groupFilter", "1,2,3,4,5,6,7,8",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"groupBy", "GROUP",
			--"maxColumns", 8,
			--"unitsPerColumn", 5,
			--"columnSpacing", T.Scale(3),
			--"columnAnchorPoint", "TOP",
			"filterOnPet", true,
			"sortMethod", "NAME"
		)
		petRaid:SetPoint("TOPLEFT", playerRaid, "BOTTOMLEFT", 0, -50)
	end
end)

-- Handle healium specific events
local healiumEventHandler = CreateFrame("Frame")
healiumEventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
healiumEventHandler:RegisterEvent("ADDON_LOADED")
healiumEventHandler:RegisterEvent("RAID_ROSTER_UPDATE")
healiumEventHandler:RegisterEvent("PARTY_MEMBERS_CHANGED")
healiumEventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
healiumEventHandler:RegisterEvent("PLAYER_TALENT_UPDATE")
healiumEventHandler:RegisterEvent("SPELL_UPDATE_COOLDOWN")
healiumEventHandler:RegisterEvent("UNIT_AURA")
healiumEventHandler:RegisterEvent("UNIT_POWER")
healiumEventHandler:RegisterEvent("UNIT_MAXPOWER")
healiumEventHandler:RegisterEvent("SPELL_UPDATE_USABLE")
healiumEventHandler:RegisterEvent("PLAYER_LOGIN")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_SENT")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
healiumEventHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
--healiumEventHandler:RegisterEvent("SPELLS_CHANGED")
healiumEventHandler:RegisterEvent("PLAYER_ALIVE")
healiumEventHandler:SetScript("OnEvent", OnEvent)

if HealiumSettings.Options.showOOR then
	healiumEventHandler.hTimeSinceLastUpdate = GetTime()
	healiumEventHandler:SetScript("OnUpdate", OnUpdate)
end