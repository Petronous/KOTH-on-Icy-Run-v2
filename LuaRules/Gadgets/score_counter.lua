function gadget:GetInfo()
	return {
		name    = "KOTH score counter",
		desc    = "Counts the allyteam score based on the captured mexes in the 'hill' area",
		author  = "Perrold (Petronous on GitHub)",
		date    = "2026",
		license = "The Unlicense",
		layer   = 0,
		enabled = true -- loaded by default?
	}
end

-- Certain parts are copied from / inspired by Chilli Core Selector by KingRaptor and GoogleFrog,
-- available at https://github.com/ZeroK-RTS/Zero-K/blob/master/LuaUI/Widgets/gui_chili_core_selector.lua
-- Certain parts are similarly also copied from / inspired by Shield Link by Lurker, available at
-- https://github.com/ZeroK-RTS/Zero-K/blob/master/LuaRules/Gadgets/unit_shield_link.lua

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if gadgetHandler:IsSyncedCode() then
	local spGetUnitPosition     = Spring.GetUnitPosition
	local spGetUnitDefID        = Spring.GetUnitDefID
	local spGetUnitTeam         = Spring.GetUnitTeam
	local spGetTeamInfo         = Spring.GetTeamInfo
	local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
	local spGetUnitIsStunned    = Spring.GetUnitIsStunned
	local spSetUnitRulesParam   = Spring.SetUnitRulesParam
	local spGetUnitRulesParam   = Spring.GetUnitRulesParam
	local spGetAllyTeamList		= Spring.GetAllyTeamList
	local SendToUnsynced = SendToUnsynced

	local allyTeamScores = {}
	local allyTeamMexes = {}
	local SCORE_LIMIT = 1000
	local SCORE_GAIN_PER_CAPPED = 4


	local function IsMex(unitDefID)
		local ud = UnitDefs[unitDefID]
		return ud.customParams.metal_extractor_mult ~= nil
	end

	local function GetTableSize(table)
		local size = 0
		for _,_ in pairs(table) do
			size = size + 1
		end
		return size
	end

	function gadget:Initialize()
		for _,unitID in ipairs(Spring.GetAllUnits()) do
			local teamID = spGetUnitTeam(unitID)
			local unitDefID = spGetUnitDefID(unitID)
			gadget:UnitCreated(unitID, unitDefID, teamID)
		end
		local gaiaTeam = Spring.GetGaiaTeamID()
		local _,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam, false)
		for _,atID in ipairs(spGetAllyTeamList()) do
			if atID == gaiaAlliance then 
				Spring.Echo("AllyTeam " .. atID .. " is Gaia, SKIPPING")
			else
				allyTeamScores[atID] = 0
				allyTeamMexes[atID] = {}
			end
		end
	end

	function gadget:UnitCreated(unitID, unitDefID)
		local stunned_or_inbuild, _, inbuild = spGetUnitIsStunned(unitID)
		if stunned_or_inbuild ~= nil and inbuild then
			return
		end

		if not IsMex(unitDefID) then
			return
		end

		local allyTeamID = spGetUnitAllyTeam(unitID)
		if allyTeamMexes[allyTeamID] == nil then
			allyTeamMexes[allyTeamID] = {}
		end
		allyTeamMexes[allyTeamID][unitID] = true
	end

	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		gadget:UnitCreated(unitID, unitDefID)
	end

	function gadget:UnitDestroyed(unitID, unitDefID)
		if not IsMex(unitDefID) then
			return
		end

		local allyTeamID = spGetUnitAllyTeam(unitID)
		if allyTeamMexes[allyTeamID] == nil then
			allyTeamMexes[allyTeamID] = {}
		end
		allyTeamMexes[allyTeamID][unitID] = nil
	end

	function gadget:UnitGiven(unitID, unitDefID, _, _)
		gadget:UnitCreated(unitID, unitDefID)
	end

	function gadget:UnitTaken(unitID, unitDefID, _, _)
		gadget:UnitDestroyed(unitID, unitDefID)
	end

	function gadget:GameFrame(n)
		if n % 120 ~= 27 then
			return
		end
		for aTID, mexes in pairs(allyTeamMexes) do
			local score = allyTeamScores[aTID] or 0
			allyTeamScores[aTID] = score + GetTableSize(mexes)
		end
		SendToUnsynced("ScoreCounterUpdate", allyTeamScores)
	end
else  -- end of synced code, start of unsynced code
	
	local spSendMessage			= Spring.SendMessage

	local function HandleScoreCounterUpdate(_, allyTeamScores) -- first arg is name of event
		if Script.LuaUI("KOTH_ScoreChange") then
			Script.LuaUI.KOTH_ScoreChange(allyTeamScores)
		else
			spSendMessage("No ScoreChange listener widget registered!")
			for aTID, score in pairs(allyTeamScores) do
				spSendMessage("Score for "..aTID..": "..score)
			end
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("ScoreCounterUpdate", HandleScoreCounterUpdate)
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveSyncAction("ScoreCounterUpdate")
	end

end  -- end of unsynced code
