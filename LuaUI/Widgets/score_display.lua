local version = 2.131
function widget:GetInfo()
  return {
    name      = "KOTH score display",
    desc      = "Shows progress bars that keep track of ally team scores towards victory",
    author    = "Perrold (Petronous on GitHub)",
    date      = "Nov 2026",
    license   = "GPL",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
-- Certain parts are copied from / inspired by the Attrition Counter widget by Anarchid and Klon,
-- available at https://github.com/ZeroK-RTS/Zero-K/blob/master/LuaUI/Widgets/gui_attrition_counter.lua

include("colors.lua")
VFS.Include("LuaRules/Configs/constants.lua")

local GetLeftRightAllyTeamIDs = VFS.Include("LuaUI/Headers/allyteam_selection_utilities.lua")

-- options_path = 'Settings/HUD Panels/Extras/Attrition Counter'
-- options_order = {'updateFrequency'}
-- options = {
-- 	updateFrequency = { -- fixme: this setting should die and the counters should update if and only if needed
-- 		name = "Update every N Frames",
-- 		type = 'number',
-- 		min = 1,
-- 		max = 150,
-- 		value = 10,
-- 		step = 1,
-- 	},
-- }

local Chili
local Window
local Label
local Image

local red = {1,0,0,1}
local green = {0,1,0,1}
local blue = {.2,.2,1,1}
local grey = {.5,.5,.5,1}
local white = {1,1,1,1}

local abs = math.abs
local floor = math.floor
local Echo = Spring.Echo

local GetUnitHealth = Spring.GetUnitHealth
local GetTeamColor = Spring.GetTeamColor
local GetTeamInfo = Spring.GetTeamInfo
local GetPlayerInfo = Spring.GetPlayerInfo
local UnitDestroyed = Spring.UnitDestroyed -- (unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)

local spectating = Spring.GetSpectatingState();

local window_main
local label_rate
local global_command_button

local label_self
local label_other

local label_own_kills_units
local label_own_kills_metal
local label_other_kills_units
local label_other_kills_metal

local icon_own_skull
local icon_own_bars
local icon_other_skull
local icon_other_bars

-- local ICON_LOST_FILE = 'luaui/images/AttritionCounter/chicken.png'
local ICON_KILLS_FILE = 'luaui/images/AttritionCounter/skull.png'
local ICON_METAL_FILE = 'luaui/images/costIcon.png'

local font -- dummy, need this to call GetTextWidth without looking up an instance

local myTeam
local myAllyTeam
local gaiaTeam
local enemyAllyTeam

local h = 0.00000001

local teams = {
	--	[teamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>
	-- 		rate = (allyTeams[other].lostMetal / #allyTeams[other].teamIDs) / lostMetal : <number> -- unused
	--		friendAllyTeamID = teamID <number>
	--		enemyAllyTeamID = teamID <number>
	--		color = {R,G,B,A} <table<number, ..., string>>
	--		name = playername <string>
}setmetatable(teams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1}); return t[k] end})

local allyTeams = {
	--	[allyTeamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>
	-- 		rate = allyTeams[other].lostMetal / lostMetal : <number>
	--		teamIDs = { <number>  teamID = true, ... }
	--		color = {R,G,B,A}
	--		name = allyteam# or playername <string>
	--		numPlayers = <number>
	--		highestElo = teamID <number>
	--      name = <string>
}setmetatable(allyTeams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1, numPlayers = 0, teamIDs = {}}); return t[k] end}) --

local frame = 0 -- options.updateFrequency.value
local doUpdate = false


------------------------------------------------------------------------------------------------------------------------------------
--------------- local functions
------------------------------------------------------------------------------------------------------------------------------------

local function rgbToString(c)
	if(c) then
		return '\255'..string.char(floor(c[1]*255))..string.char(floor(c[2]*255))..string.char(floor(c[3]*255))
	else
		return rgbToString({1,1,1,1});
	end
end

local function cap (x) return math.max(math.min(x,1),0) end

local function GetTeamName(teamID)
	local _,leader,_,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID, false)
	if teamID == gaiaTeamID then
		return "gaia"
	else
		local name = "player";
		if isAI then
			_,name = Spring.GetAIInfo(teamID)
		else
			name = GetPlayerInfo(leader, false)
		end
		return name;
	end
end

local function GetOpposingAllyTeams()
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	local returnData = {}
	local allyTeamList = GetLeftRightAllyTeamIDs()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]

		local teamList = Spring.GetTeamList(allyTeamID)
		if allyTeamID ~= gaiaAllyTeamID and #teamList > 0 then

			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID)
			if string.len(name) > 10 then
				name = Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID)
			end

			returnData[#returnData + 1] = {
				allyTeamID = allyTeamID, -- allyTeamID for the team
				name = name, -- Large display name of the team
				teamID = teamList[1], -- representitive teamID
				color = {Spring.GetTeamColor(teamList[1])} or {1,1,1,1}, -- color of the teams text (color of first player)
			}
		end
	end

	if #returnData ~= 2 then
		return
	end
	
	return returnData
end
