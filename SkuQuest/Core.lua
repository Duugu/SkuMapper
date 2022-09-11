---@diagnostic disable: undefined-global
local MODULE_NAME = "SkuQuest"
local _G = _G

SkuQuest = LibStub("AceAddon-3.0"):NewAddon("SkuQuest", "AceConsole-3.0", "AceEvent-3.0")
local L = Sku.L

---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:OnInitialize()
	SkuQuest:RegisterEvent("PLAYER_ENTERING_WORLD")
	SkuQuest:RegisterEvent("PLAYER_LOGIN")
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:OnEnable()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:OnDisable()
	
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:PLAYER_LOGIN(...)
	--print("SkuQuest:PLAYER_LOGIN")

	--apply fixed on tbc dbs
	SkuDB:FixQuestDB(SkuDB)
	SkuDB:FixItemDB(SkuDB)
	SkuDB:FixCreaturesDB(SkuDB)
	SkuDB:FixObjectsDB(SkuDB)

	--apply fixed on wrath dbs
	SkuDB:WotLKFixQuestDB(SkuDB.WotLK)
	SkuDB:WotLKFixItemDB(SkuDB.WotLK)
	SkuDB:WotLKFixCreaturesDB(SkuDB.WotLK)
	SkuDB:WotLKFixObjectsDB(SkuDB.WotLK)

	--merge creature dbs
	local tcount = 0
	for i, v in pairs(SkuDB.WotLK.NpcData.Data) do
		if not SkuDB.NpcData.Data[i]	then
			SkuDB.NpcData.Data[i] = v
			tcount = tcount + 1
		end
	end

	--take stormwind creatues from wrath data due to changed coordinates
	for i, v in pairs(SkuDB.WotLK.NpcData.Data) do
		if SkuDB.NpcData.Data[i][SkuDB.NpcData.Keys.spawns] then
			for areaid, spawndata in pairs(SkuDB.NpcData.Data[i][SkuDB.NpcData.Keys.spawns]) do
				if areaid == SkuDB.zoneIDs.STORMWIND_CITY then
					if v[SkuDB.NpcData.Keys.spawns] then
						for wareaid, wspandata in pairs(v[SkuDB.NpcData.Keys.spawns]) do
							if wareaid == SkuDB.zoneIDs.STORMWIND_CITY then
								SkuDB.NpcData.Data[i][SkuDB.NpcData.Keys.spawns][wareaid] = wspandata
							end
						end
					end
				end
			end
		end
	end

	SkuDB.NpcData.Names = SkuDB.WotLK.NpcData.Names
	--print("NpcData", tcount)

	--merge items dbs
	local tcount = 0
	for i, v in pairs(SkuDB.WotLK.itemDataTBC) do
		if not SkuDB.itemDataTBC[i]	then
			SkuDB.itemDataTBC[i] = v
			tcount = tcount + 1
		end
	end	
	SkuDB.itemLookup = SkuDB.WotLK.itemLookup
	--print("itemDataTBC", tcount)

	--merge object dbs
	local tcount = 0
	for i, v in pairs(SkuDB.WotLK.objectDataTBC) do
		if not SkuDB.objectDataTBC[i]	then
			SkuDB.objectDataTBC[i] = v
			tcount = tcount + 1
		end
	end	

	--take stormwind objects from wrath data due to changed coordinates
	for i, v in pairs(SkuDB.WotLK.objectDataTBC) do
		if SkuDB.objectDataTBC[i][SkuDB.objectKeys.spawns] then
			for areaid, spawndata in pairs(SkuDB.objectDataTBC[i][SkuDB.objectKeys.spawns]) do
				if areaid == SkuDB.zoneIDs.STORMWIND_CITY then
					if SkuDB.WotLK.objectDataTBC[i][SkuDB.objectKeys.spawns] then
						for wareaid, wspandata in pairs(SkuDB.WotLK.objectDataTBC[i][SkuDB.objectKeys.spawns]) do
							if wareaid == SkuDB.zoneIDs.STORMWIND_CITY then
								SkuDB.objectDataTBC[i][SkuDB.objectKeys.spawns][wareaid] = wspandata
							end
						end
					end
				end
			end
		end
	end

	SkuDB.objectResourceNames = SkuDB.WotLK.objectResourceNames

	for i, v in pairs(SkuDB.WotLK.objectLookup.deDE) do
		if not SkuDB.objectLookup.deDE[i] then
			SkuDB.objectLookup.deDE[i] = v
		end
	end

	SkuDB.objectLookup.enUS = {}
	for i, v in pairs(SkuDB.objectLookup.deDE) do
		SkuDB.objectLookup.enUS[i] = SkuDB.WotLK.objectLookup.enUS[i]
	end

	--SkuDB.objectLookup = SkuDB.WotLK.objectLookup
	--print("objectDataTBC", tcount)
	
	--merge quest dbs
	local tcount = 0
	for i, v in pairs(SkuDB.WotLK.questDataTBC) do
		if not SkuDB.questDataTBC[i]	then
			SkuDB.questDataTBC[i] = v
			tcount = tcount + 1
		end
	end
	SkuDB.questLookup = SkuDB.WotLK.questLookup
	--print("questDataTBC", tcount)

	-- do final stuff
	SkuQuest:BuildQuestZoneCache()
	SkuQuest:UpdateAllQuestObjects()
end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:PLAYER_ENTERING_WORLD(...)
	C_Timer.After(20, function()
		SkuQuest:LoadEventHandler()
	end)
end

---------------------------------------------------------------------------------------------------------------------------------------
SkuQuest.QuestWpCache = {}
function SkuQuest:GetAllQuestWps(aQuestID, aStart, aObjective, aFinish, aOnly3)
	--dprint("GetAllQuestWps", aQuestID, aStart, aObjective, aFinish, aOnly3)

	if aStart == true then
		if SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["startedBy"]][1] 
			or SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["startedBy"]][2]
			or SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["startedBy"]][3]
		then
			local tstartedBy = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["startedBy"]]
			if tstartedBy then
				local tTargets = {}
				local tTargetType = nil
				tTargets, tTargetType = SkuQuest:GetQuestTargetIds(aQuestID, tstartedBy)
				if	tTargetType then
					local tResultWPs = {}
					SkuQuest:GetResultingWps(tTargets, tTargetType, aQuestID, tResultWPs, aOnly3)
					for i, v in pairs(tResultWPs) do
						for ri, rv in pairs(v) do
							SkuQuest.QuestWpCache[rv] = true
						end
					end
				end
			end
		end
	end

	if aObjective == true then
		local tObjectives = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["objectives"]]
		if tObjectives then
			local tTargets = {}
			local tTargetType = nil
			tTargets, tTargetType = SkuQuest:GetQuestTargetIds(aQuestID, tObjectives)
			if	tTargetType then
				local tResultWPs = {}
				SkuQuest:GetResultingWps(tTargets, tTargetType, aQuestID, tResultWPs, aOnly3)
				for i, v in pairs(tResultWPs) do
					for ri, rv in pairs(v) do
						SkuQuest.QuestWpCache[rv] = true
					end
				end
			end
		end
	end
	if aFinish == true then
		if SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["finishedBy"]][1] or SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["finishedBy"]][2] or SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["finishedBy"]][3] then
			local tFinishedBy = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["finishedBy"]]
			if tFinishedBy then
				local tTargets = {}
				local tTargetType = nil
				tTargets, tTargetType = SkuQuest:GetQuestTargetIds(aQuestID, tFinishedBy)
				if	tTargetType then
					local tResultWPs = {}
					SkuQuest:GetResultingWps(tTargets, tTargetType, aQuestID, tResultWPs, aOnly3)
					for i, v in pairs(tResultWPs) do
						for ri, rv in pairs(v) do
							SkuQuest.QuestWpCache[rv] = true
						end
					end
				end
			end
		end
	end

end

---------------------------------------------------------------------------------------------------------------------------------------
local function GetCreatureArea(aQuestID, aCreatureId)
	if SkuDB.NpcData.Data[aCreatureId] then
		local tSpawns = SkuDB.NpcData.Data[aCreatureId][7]
		if tSpawns then
			for is, vs in pairs(tSpawns) do
				SkuQuest.QuestZoneCache[aQuestID][is] = is
			end
		end
	end
end
local function GetObjectArea(aQuestID, aObjectId)
	if not SkuDB.objectDataTBC[aObjectId] then
		return
	end
	if SkuDB.objectDataTBC[aObjectId][SkuDB.objectKeys['spawns']] then
		for sAreaID, vi in pairs(SkuDB.objectDataTBC[aObjectId][SkuDB.objectKeys['spawns']]) do
			SkuQuest.QuestZoneCache[aQuestID][sAreaID] = sAreaID
		end
	end
end
function SkuQuest:BuildQuestZoneCache()
	SkuQuest.QuestZoneCache = {}
	for aQuestID = 1, 100000 do
		if SkuDB.questDataTBC[aQuestID] then
			SkuQuest.QuestZoneCache[aQuestID] = {}

			--starts
			local tstartedBy = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["startedBy"]]
			if tstartedBy[1] then
				--creatureStart
				for i, v in pairs(tstartedBy[1]) do
					GetCreatureArea(aQuestID, v)
				end
			end
			if tstartedBy[2] then
				--objectStart
				for i, id in pairs(tstartedBy[2]) do
					GetObjectArea(aQuestID, id)
				end
			end
			if tstartedBy[3] then
				--itemStart
				for i, v in pairs(tstartedBy[3]) do
					--dprint("  itemStart", i, v)
					if SkuDB.itemDataTBC[v][SkuDB.itemKeys['npcDrops']] then
						for z = 1, #SkuDB.itemDataTBC[v][SkuDB.itemKeys['npcDrops']] do
							GetCreatureArea(aQuestID, SkuDB.itemDataTBC[v][SkuDB.itemKeys['npcDrops']][z])
						end
					end
					if SkuDB.itemDataTBC[v][SkuDB.itemKeys['objectDrops']] then
						for z = 1, #SkuDB.itemDataTBC[v][SkuDB.itemKeys['objectDrops']] do
							GetObjectArea(aQuestID, SkuDB.itemDataTBC[v][SkuDB.itemKeys['objectDrops']][z])
						end
					end
					if SkuDB.itemDataTBC[v][SkuDB.itemKeys['itemDrops']] then
						for z = 1, #SkuDB.itemDataTBC[v][SkuDB.itemKeys['itemDrops']] do
							local tItemId = SkuDB.itemDataTBC[v][SkuDB.itemKeys['itemDrops']][z]
							if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] then
								for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] do
									GetCreatureArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']][z])
								end
							end
							if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] then
								for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] do
									GetObjectArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']][z])
								end
							end
						end
					end
				end
			end

			--objectives
			local objectives = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["objectives"]]
			if objectives then
				--['creatureObjective'] = 1, -- table {{creature(int), text(string)},...}, If text is nil the default "<Name> slain x/y" is used
				if objectives[1] then
					for i, v in pairs(objectives[1]) do
						GetCreatureArea(aQuestID, v[1])
					end
				end
				--['objectObjective'] = 2, -- table {{object(int), text(string)},...}
				if objectives[2] then
					for i, v in pairs(objectives[2]) do
						GetCreatureArea(aQuestID, v[1])
					end
				end
				--['itemObjective'] = 3, -- table {{item(int), text(string)},...}
				if objectives[3] then
					--dprint("  objectives itemObjective")
					for i, v in pairs(objectives[3]) do
						local tItemId = v[1]
						if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] then
							for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] do
								GetCreatureArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']][z])
							end
						end
						if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] then
							for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] do
								GetObjectArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']][z])
							end
						end
						if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['itemDrops']] then
							for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['itemDrops']] do
								local tItemId = SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['itemDrops']][z]
								if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] then
									for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']] do
										GetCreatureArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['npcDrops']][z])
									end
								end
								if SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] then
									for z = 1, #SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']] do
										GetObjectArea(aQuestID, SkuDB.itemDataTBC[tItemId][SkuDB.itemKeys['objectDrops']][z])
									end
								end
							end
						end
					end
				end
			end

			--finishs
			local finishedBy = SkuDB.questDataTBC[aQuestID][SkuDB.questKeys["finishedBy"]]
			if finishedBy[1] then
				--creature
				for i, v in pairs(finishedBy[1]) do
					GetCreatureArea(aQuestID, v)
				end
			end
			if finishedBy[2] then
				--object
				for i, id in pairs(finishedBy[2]) do
					GetObjectArea(aQuestID, id)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
SkuQuest.questObjects = {}
function SkuQuest:GetAllQuestObjects()
	return SkuQuest.questObjects
end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuQuest:UpdateAllQuestObjects()
	SkuQuest.questObjects = {}
	if GetNumQuestLogEntries() > 0 then
		for x = 1, GetNumQuestLogEntries() do
			if GetNumQuestLeaderBoards(x) > 0 then
				for y = 1, GetNumQuestLeaderBoards(x) do
					local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(y, x)
					if isCompleted == false then
						if objectiveType == "object" then
							dprint(x, y, description)
						elseif objectiveType == "item" then
							for i, v in pairs(SkuDB.itemLookup[Sku.L["locale"]]) do
								if string.find(description, v) then
									if SkuDB.itemDataTBC[i] and SkuDB.itemDataTBC[i][SkuDB.itemKeys.objectDrops] then
										for _, tObjectId in pairs(SkuDB.itemDataTBC[i][SkuDB.itemKeys.objectDrops]) do
											dprint(v, tObjectId, SkuDB.objectLookup[Sku.L["locale"]][tObjectId])
											if SkuDB.objectLookup[Sku.L["locale"]][tObjectId] then
												SkuQuest.questObjects[SkuDB.objectLookup[Sku.L["locale"]][tObjectId]] = tObjectId
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end