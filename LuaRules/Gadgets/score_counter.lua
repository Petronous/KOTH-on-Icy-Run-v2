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
	local spGetUnitIsStunned    = Spring.GetUnitIsStunned

	local allyTeamScores = {}
	local allyTeamScoreGains = {}
	local SCORE_LIMIT = 1000
	local SCORE_GAIN_PER_CAPPED = 4


	function gadget:UnitCreated(unitID, unitDefID)
		local stunned_or_inbuild, _, inbuild = spGetUnitIsStunned(unitID)
		if stunned_or_inbuild ~= nil and inbuild then
			return
		end

		local ud = UnitDefs[unitDefID]
		
	end
else  -- end of synced code, start of unsynced code

end  -- end of unsynced code
