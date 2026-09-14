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
	local spSendMessage			= Spring.SendMessage
	local SendToUnsynced = SendToUnsynced

	local allyTeamScores = {}
	local allyTeamMexes = {}
	local SCORE_LIMIT = 1000
	local SCORE_GAIN_PER_CAPPED = 4


	local function IsMex(unitDefID)
		local ud = UnitDefs[unitDefID]
		Spring.Echo(ud.name)
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
		Spring.Echo("-------------\n------------\nSCORE COUNTER INIT-----------\n------------\n")
		for _,unitID in ipairs(Spring.GetAllUnits()) do
			local teamID = spGetUnitTeam(unitID)
			local unitDefID = spGetUnitDefID(unitID)
			gadget:UnitCreated(unitID, unitDefID, teamID)
		end
		for _,atID in ipairs(spGetAllyTeamList()) do
			allyTeamScores[atID] = 0
		end
	end

	function gadget:UnitCreated(unitID, unitDefID)
		Spring.Echo("-------------\n------------\nSCORE COUNTER UNIT CREATED-----------\n------------\n")
		Spring.Echo("uID: "..unitID)
		local stunned_or_inbuild, _, inbuild = spGetUnitIsStunned(unitID)
		if stunned_or_inbuild ~= nil and inbuild then
			return
		end
		Spring.Echo("NOT INBUILD")

		if not IsMex(unitDefID) then
			return
		end
		Spring.Echo("IS MEX")

		local allyTeamID = spGetUnitAllyTeam(unitID)
		Spring.Echo("aTID: "..allyTeamID)
		if allyTeamMexes[allyTeamID] == nil then
			allyTeamMexes[allyTeamID] = {}
		end
		allyTeamMexes[allyTeamID][unitID] = true
		Spring.Echo("aTID.uID: "..tostring(allyTeamMexes[allyTeamID][unitID]))
	end

	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		gadget:UnitCreated(unitID, unitDefID)
	end

	function gadget:UnitDestroyed(unitID, unitDefID)
		Spring.Echo("Unit destroyed: "..unitID)
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
		Spring.Echo(allyTeamMexes)
		for aTID, mexes in pairs(allyTeamMexes) do
			local score = allyTeamScores[aTID] or 0
			for mID, _ in pairs(mexes) do
				Spring.Echo("mID: "..mID)
			end
			allyTeamScores[aTID] = score + GetTableSize(mexes)
			spSendMessage("Score for "..aTID..": "..allyTeamScores[aTID])
		end
		SendToUnsynced("ScoreCounterUpdate")
	end
else  -- end of synced code, start of unsynced code
	local function HandleScoreCounterUpdate()
		
	end

end  -- end of unsynced code
