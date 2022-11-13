---------------------------------------------------------------------------------------------------------------------------------------
local MODULE_NAME = "SkuNav"
local _G = _G
local L = Sku.L

SkuNav = SkuNav or LibStub("AceAddon-3.0"):NewAddon("SkuNav", "AceConsole-3.0", "AceEvent-3.0")

SkuDrawFlag = false

local slower = string.lower
local sfind = string.find
local ssub = string.sub
local tinsert = table.insert

------------------------------------------------------------------------------------------------------------------------
WaypointCache = {}
local WaypointCacheLookupAll = {}
local WaypointCacheLookupIdForCacheIndex = {}
local WaypointCacheLookupCacheNameForId = {}
local WaypointCacheLookupPerContintent = {}

function SkuNav:CreateWaypointCache(aAddLocalizedNames)
	SkuDrawFlag = false

	WaypointCache = {}
	WaypointCacheLookupAll = {}
	WaypointCacheLookupIdForCacheIndex = {}
	WaypointCacheLookupCacheNameForId = {}
	WaypointCacheLookupPerContintent = {}
	for i, v in pairs(SkuDB.ContinentIds) do
		WaypointCacheLookupPerContintent[i] = {}
	end

	C_Timer.After(2, function()
		--add creatures
		for i, v in pairs(SkuDB.NpcData.Names[Sku.Loc]) do		
			if SkuDB.NpcData.Data[i] then
				local tRoles
				local tName
				local tSubname
				if SkuDB.NpcData.Names[Sku.Loc][i] then
					tName = SkuDB.NpcData.Names[Sku.Loc][i][1]
					tSubname = SkuDB.NpcData.Names[Sku.Loc][i][2]
					tRoles = SkuNav:GetNpcRoles(v[1], i)
				else
					tName = SkuDB.NpcData.Data[i][1]
					tSubname = SkuDB.NpcData.Data[i][14]
					tRoles = SkuNav:GetNpcRoles(SkuDB.NpcData.Data[i][1], i)
				end			
				local tSpawns = SkuDB.NpcData.Data[i][7]
				if tSpawns then
					if not sfind(slower(tName), "trigger") then
						for is, vs in pairs(tSpawns) do
							local isUiMap = SkuNav:GetUiMapIdFromAreaId(is)
							--we don't care for stuff that isn't in the open world
							if isUiMap then
								local tData = SkuDB.InternalAreaTable[is]
								if tData then
									local tNumberOfSpawns = #vs
									local tRolesString = ""
									if not tSubname then
										if #tRoles > 0 then
											for i, v in pairs(tRoles) do
												tRolesString = tRolesString..";"..v
											end
											tRolesString = tRolesString..""
										end
									else
										tRolesString = tRolesString..";"..tSubname
									end
									for sp = 1, tNumberOfSpawns do
										local _, worldPosition = C_Map.GetWorldPosFromMapPos(isUiMap, CreateVector2D(vs[sp][1] / 100, vs[sp][2] / 100))
										if worldPosition then
											local tWorldX, tWorldY = worldPosition:GetXY()
											local tNewIndex = #WaypointCache + 1
											local tFinalName = tName..tRolesString..";"..tData.AreaName_lang[Sku.Loc]..";"..sp..";"..vs[sp][1]..";"..vs[sp][2]
											local tWpId = SkuNav:BuildWpIdFromData(2, i, sp, is)
											if not WaypointCacheLookupPerContintent[tData.ContinentID] then
												WaypointCacheLookupPerContintent[tData.ContinentID] = {}
											end
											WaypointCacheLookupPerContintent[tData.ContinentID][tNewIndex] = tFinalName
											WaypointCacheLookupAll[tFinalName] = tNewIndex
											WaypointCacheLookupIdForCacheIndex[tWpId] =  tNewIndex
											WaypointCacheLookupCacheNameForId[tFinalName] = tWpId
											WaypointCache[tNewIndex] = {
												name = tFinalName,
												role = tRolesString,
												typeId = 2,
												dbIndex = i,
												spawn = sp,
												contintentId = tData.ContinentID,
												areaId = is,
												uiMapId = isUiMap,
												worldX = tWorldX,
												worldY = tWorldY,
												createdAt = GetTime(),
												createdBy = "SkuNav",
												size = 1,
												spawnNr = sp,
												links = {
													byId = nil,
													byName = nil,
												},
											}
										end
									end
								end
							end
						end
					end
				end
			end
		end

		C_Timer.After(2, function()			
			--add objects
			for i, v in pairs(SkuDB.objectLookup[Sku.Loc]) do
				--we don't want stuff like ores, herbs, etc.
				if not SkuDB.objectResourceNames[Sku.Loc][v] or SkuOptions.db.profile[MODULE_NAME].showGatherWaypoints == true then
					if SkuDB.objectDataTBC[i] then
						local tSpawns = SkuDB.objectDataTBC[i][4]
						if tSpawns then
							for is, vs in pairs(tSpawns) do
								local isUiMap = SkuNav:GetUiMapIdFromAreaId(is)
								--we don't care for stuff that isn't in the open world
								if isUiMap then
									local tData = SkuDB.InternalAreaTable[is]
									if tData then
										local tNumberOfSpawns = #vs
										for sp = 1, tNumberOfSpawns do
											local _, worldPosition = C_Map.GetWorldPosFromMapPos(isUiMap, CreateVector2D(vs[sp][1] / 100, vs[sp][2] / 100))
											if worldPosition then
												local tWorldX, tWorldY = worldPosition:GetXY()
												local tNewIndex = #WaypointCache + 1
												local tRessourceType = ""
												if SkuDB.objectResourceNames[Sku.Loc][v] == 1 then
													tRessourceType = ";"..L["herbalism"]
												elseif SkuDB.objectResourceNames[Sku.Loc][v] == 2 then
													tRessourceType = ";"..L["mining"]
												end

												local tFinalName = L["OBJECT"]..";"..i..";"..v..tRessourceType..";"..tData.AreaName_lang[Sku.Loc]..";"..sp..";"..vs[sp][1]..";"..vs[sp][2]
												local tWpId = SkuNav:BuildWpIdFromData(3, i, sp, is)
												if not WaypointCacheLookupPerContintent[tData.ContinentID] then
													WaypointCacheLookupPerContintent[tData.ContinentID] = {}
												end
												WaypointCacheLookupPerContintent[tData.ContinentID][tNewIndex] = tFinalName
												WaypointCacheLookupAll[tFinalName] = tNewIndex
												WaypointCacheLookupIdForCacheIndex[tWpId] =  tNewIndex
												WaypointCacheLookupCacheNameForId[tFinalName] = tWpId										
												WaypointCache[tNewIndex] = {
													name = tFinalName,
													role = "",
													typeId = 3,
													dbIndex = i,
													spawn = sp,
													contintentId = tData.ContinentID,
													areaId = is,
													uiMapId = isUiMap,
													worldX = tWorldX,
													worldY = tWorldY,
													createdAt = GetTime(),
													createdBy = "SkuNav",
													size = 1,
													spawnNr = sp,
													links = {
														byId = nil,
														byName = nil,
													},
												}
											end
										end
									end
								end
							end
						end
					end
				end
			end

			C_Timer.After(2, function()
				--add custom
				if SkuOptions.db.global[MODULE_NAME].Waypoints then
					for tIndex, tData in ipairs(SkuOptions.db.global[MODULE_NAME].Waypoints) do
						--check if that wp was deleted
						if tData[1] ~= false then
							local tName = tData.names[Sku.Loc]

							local tWaypointData = tData
							if tWaypointData then
								if tWaypointData.contintentId then
									local isUiMap = SkuNav:GetUiMapIdFromAreaId(tWaypointData.areaId)
									local tWpIndex = (#WaypointCache + 1)
									local tOldLinks = {
										byId = nil,
										byName = nil,
									}
									if WaypointCacheLookupAll[tName] then
										if WaypointCacheLookupPerContintent[WaypointCache[WaypointCacheLookupAll[tName]].contintentId] then
											WaypointCacheLookupPerContintent[WaypointCache[WaypointCacheLookupAll[tName]].contintentId][WaypointCacheLookupAll[tName]] = nil
										end
										tOldLinks = WaypointCache[WaypointCacheLookupAll[tName]].links
										tWpIndex = WaypointCacheLookupAll[tName]
									end

									WaypointCache[tWpIndex] = {
										name = tName,
										role = "",
										typeId = 1,
										dbIndex = tIndex,
										spawn = 1,
										contintentId = tWaypointData.contintentId,
										areaId = tWaypointData.areaId,
										uiMapId = isUiMap,
										worldX = tWaypointData.worldX,
										worldY = tWaypointData.worldY,
										createdAt = tWaypointData.createdAt,
										createdBy = tWaypointData.createdBy,
										size = tWaypointData.size or 1,
										comments = tWaypointData.lComments or {["deDE"] = {},["enUS"] = {},},
										spawnNr = nil,
										links = tOldLinks,
									}

									WaypointCacheLookupAll[tName] = tWpIndex
									local tWpId = SkuNav:BuildWpIdFromData(1, tIndex, 1, tWaypointData.areaId)
									WaypointCacheLookupIdForCacheIndex[tWpId] =  tWpIndex
									WaypointCacheLookupCacheNameForId[tName] = tWpId										

									if not WaypointCacheLookupPerContintent[tWaypointData.contintentId] then
										WaypointCacheLookupPerContintent[tWaypointData.contintentId] = {}
									end
									WaypointCacheLookupPerContintent[tWaypointData.contintentId][tWpIndex] = tName
								end
							end
						else
							--print("error: tried caching deleted custom wp", tIndex, tData)
						end
					end
				end

				SkuNav:LoadLinkDataFromProfile()
				C_Timer.NewTimer(5, function() SkuDrawFlag = true end)

				print("SkuMapper cache ready")
			end)
		end)
	end)
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:LoadLinkDataFromProfile()
	--print("LoadLinkDataFromProfile")
	if SkuOptions.db.global[MODULE_NAME].Links then
		SkuNav:CheckAndUpdateProfileLinkData()
		for tSourceWpID, tSourceWpLinks in pairs(SkuOptions.db.global[MODULE_NAME].Links) do
			if not WaypointCacheLookupIdForCacheIndex[tSourceWpID] then
				print("Error: This should not happen. NO WaypointCacheLookupIdForCacheIndex[tSourceWpID]", tSourceWpID, tSourceWpLinks)
			end
			local tSourceWpName = WaypointCache[WaypointCacheLookupIdForCacheIndex[tSourceWpID]].name
			WaypointCacheLookupCacheNameForId[tSourceWpName] = tSourceWpID

			if WaypointCacheLookupAll[tSourceWpName] then
				WaypointCache[WaypointCacheLookupAll[tSourceWpName]].links.byName = {}
				WaypointCache[WaypointCacheLookupAll[tSourceWpName]].links.byId = {}
				for tTargetWpID, tTargetWpDistance in pairs(tSourceWpLinks) do
					local tTargetWpName = WaypointCache[WaypointCacheLookupIdForCacheIndex[tTargetWpID]].name
					WaypointCacheLookupCacheNameForId[tTargetWpName] = tTargetWpID
					if WaypointCacheLookupAll[tTargetWpName] then
						WaypointCache[WaypointCacheLookupAll[tSourceWpName]].links.byName[tTargetWpName] = tTargetWpDistance
						WaypointCache[WaypointCacheLookupAll[tSourceWpName]].links.byId[WaypointCacheLookupAll[tTargetWpName]] = tTargetWpDistance
					end
				end
			end
		end
	end
	SkuNav:SaveLinkDataToProfile()
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:CheckAndUpdateProfileLinkData()
	local tDeletedCounter = 0

	if SkuOptions.db.global[MODULE_NAME].Links then
		for tSourceWpID, tSourceWpLinks in pairs(SkuOptions.db.global[MODULE_NAME].Links) do
			if not WaypointCacheLookupIdForCacheIndex[tSourceWpID] then
				local typeId, dbIndex, spawn, areaId = SkuNav:GetWpDataFromId(tSourceWpID)
				--print("UPDATED source deleted, not in db", tSourceWpID, typeId, dbIndex, spawn, areaId)
				SkuOptions.db.global[MODULE_NAME].Links[tSourceWpID] = nil
				tDeletedCounter = tDeletedCounter + 1
			else
				local tSourceWpName = WaypointCache[WaypointCacheLookupIdForCacheIndex[tSourceWpID]].name
				if SkuNav:GetWaypointData2(tSourceWpName) then
					for tTargetWpID, tTargetWpDistance in pairs(tSourceWpLinks) do
						if not WaypointCacheLookupIdForCacheIndex[tTargetWpID] then
							--print("UPDATED Target deleted, not in db", tSourceWpID, tSourceWpLinks, tSourceWpName, "-", tTargetWpID, tTargetWpDistance, WaypointCacheLookupIdForCacheIndex[tTargetWpID])
							SkuOptions.db.global[MODULE_NAME].Links[tSourceWpID][tTargetWpID] = nil
							tDeletedCounter = tDeletedCounter + 1
						else
							local tTargetWpName = WaypointCache[WaypointCacheLookupIdForCacheIndex[tTargetWpID]].name					
							if tSourceWpName == tTargetWpName then
								SkuOptions.db.global[MODULE_NAME].Links[tSourceWpID][tTargetWpID] = nil
								--print("+++UPDATED deleted", tTargetWpName, "from", tSourceWpName, "because source was linked with self")
							else
								if SkuNav:GetWaypointData2(tTargetWpName) then
									SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID] = SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID] or {}
									if not SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID][tSourceWpID] then
										--print("+++UPDATED added", tSourceWpName, "to", tTargetWpName)
										SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID][tSourceWpID] = tTargetWpDistance
									end
								else
									--print("+++UPDATED deleted", tTargetWpName, "from", tSourceWpName, "because target does not exist")
									SkuOptions.db.global[MODULE_NAME].Links[tSourceWpID][tTargetWpID] = nil
									--print("  +++UPDATED deleted", tTargetWpName, "because target does not exist")
									SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID] = nil
								end
							end
						end
					end
				else
					for tTargetWpID, tTargetWpDistance in pairs(tSourceWpLinks) do
						local tTargetWpName = WaypointCache[WaypointCacheLookupIdForCacheIndex[tTargetWpID]].name										
						SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID] = SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID] or {}
						if not SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID][tSourceWpID] then
							--print("+++UPDATED deleted", tSourceWpName, "from", tTargetWpName, "because source does not exist")
							SkuOptions.db.global[MODULE_NAME].Links[tTargetWpID][tSourceWpID] = nil
						end
					end
					--print("  +++UPDATED delted", tSourceWpName, "because source does not exist")
					SkuOptions.db.global[MODULE_NAME].Links[tSourceWpID] = nil
				end
			end
		end
	end

	if tDeletedCounter and tDeletedCounter > 0 then
		--print("Error: deletedCounter > 0; this should not happen", tDeletedCounter)
	end
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:SaveLinkDataToProfile(aWpName)
	--print("SaveLinkDataToProfile", aWpName)
	if aWpName then
		SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[aWpName]] = {}
		for twname, twdist in pairs(WaypointCache[WaypointCacheLookupAll[aWpName]].links.byName) do
			SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[aWpName]][WaypointCacheLookupCacheNameForId[twname]] = twdist
		end		
	else
		SkuOptions.db.profile[MODULE_NAME].Links = nil
		SkuOptions.db.global[MODULE_NAME].Links = {}
		for tSourceWpIndex, tSourceWpData in pairs(WaypointCache) do
			if tSourceWpData.links then
				if tSourceWpData.links.byId then
					SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[tSourceWpData.name]] = {}
					for twname, twdist in pairs(tSourceWpData.links.byName) do
						SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[tSourceWpData.name]][WaypointCacheLookupCacheNameForId[twname]] = twdist
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetWaypointData2(aName, aIndex)
	if aName then
		return WaypointCache[WaypointCacheLookupAll[aName]]
	elseif aIndex then
		return WaypointCache[aIndex]
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:ListWaypoints2(aSort, aFilter, aAreaId, aContinentId, aExcludeRoute, aRetAsTable, aIgnoreAuto)
	aSort = aSort or false
	aFilter = aFilter or "custom;creature;object;standard"
	local tFilterTypes = {}
	if string.find(aFilter, "custom") then tFilterTypes[1] = 1 end
	if string.find(aFilter, "creature") then tFilterTypes[2] = 2 end
	if string.find(aFilter, "object") then tFilterTypes[3] = 3 end
	if string.find(aFilter, "standard") then tFilterTypes[4] = 4 end

	local UiMapId
	if aAreaId then
		UiMapId = SkuNav:GetUiMapIdFromAreaId(aAreaId)
	end

	aContinentId = aContinentId or select(3, SkuNav:GetAreaData(SkuNav:GetCurrentAreaId()))
	if not aContinentId or not WaypointCacheLookupPerContintent[aContinentId] then
		return
	end

	local tWpList = {}
	for tIndex, tName in pairs(WaypointCacheLookupPerContintent[aContinentId]) do
		if tFilterTypes[WaypointCache[tIndex].typeId] then
			if not UiMapId or UiMapId == WaypointCache[tIndex].uiMapId then
				--tWpList[tIndex] = tName
				if not string.find(tName, "%[DND%]") and not string.find(tName, "%(DND%)") then
					tWpList[#tWpList + 1] = tName
				end
			end
		end
	end

	if aSort == true then
		local tSortedList = {}
		for k, v in SkuSpairs(tWpList, function(t,a,b) return t[b] > t[a] end) do --nach wert
			tSortedList[#tSortedList+1] = v
		end
		if aRetAsTable then
			return tSortedList
		else
			return pairs(tSortedList)
		end
	end

	if aRetAsTable then
		return tWpList
	else
		return pairs(tWpList)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:DeleteWpLink(aWpAName, aWpBName)
	--print("DeleteWpLink", aWpAName, aWpBName)
	local tWpAIndex = WaypointCacheLookupAll[aWpAName]
	local tWpBIndex = WaypointCacheLookupAll[aWpBName]
	local tWpAData = SkuNav:GetWaypointData2(nil, tWpAIndex)
	local tWpBData = SkuNav:GetWaypointData2(nil, tWpBIndex)

	if not tWpAData or not tWpBData then
		return false
	end

	if not tWpAData.links.byId or not tWpBData.links.byId then
		return
	end
	
	if not tWpAData.links.byId[tWpBIndex] or not tWpBData.links.byId[tWpAIndex] then
		return false
	end

	WaypointCache[tWpAIndex].links.byId[tWpBIndex] = nil
	WaypointCache[tWpBIndex].links.byId[tWpAIndex] = nil
	WaypointCache[tWpAIndex].links.byName[aWpBName] = nil
	WaypointCache[tWpBIndex].links.byName[aWpAName] = nil
	
	local tWpAId = WaypointCacheLookupCacheNameForId[aWpAName]
	local tWpBId = WaypointCacheLookupCacheNameForId[aWpBName]

	SkuOptions.db.global[MODULE_NAME].Links[tWpAId][tWpBId] = nil
	SkuOptions.db.global[MODULE_NAME].Links[tWpBId][tWpAId] = nil

	SkuNav:SaveLinkDataToProfile(aWpAName)
	SkuNav:SaveLinkDataToProfile(aWpBName)

	SkuOptions.db.global["SkuNav"].hasCustomMapData = true
end

--------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:CreateWpLink(aWpAName, aWpBName)
	--print("CreateWpLink", aWpAName, aWpBName)
	if aWpAName ~= aWpBName then
		local tWpAIndex = WaypointCacheLookupAll[aWpAName]
		local tWpBIndex = WaypointCacheLookupAll[aWpBName]
		local tWpAData = SkuNav:GetWaypointData2(nil, tWpAIndex)
		local tWpBData = SkuNav:GetWaypointData2(nil, tWpBIndex)

		local tDistance = SkuNav:Distance(tWpAData.worldX, tWpAData.worldY, tWpBData.worldX, tWpBData.worldY)

		WaypointCache[tWpAIndex].links.byId = WaypointCache[tWpAIndex].links.byId or {}
		WaypointCache[tWpAIndex].links.byName = WaypointCache[tWpAIndex].links.byName or {}
		WaypointCache[tWpAIndex].links.byId[tWpBIndex] = tDistance
		WaypointCache[tWpAIndex].links.byName[aWpBName] = tDistance

		WaypointCache[tWpBIndex].links.byId = WaypointCache[tWpBIndex].links.byId or {}
		WaypointCache[tWpBIndex].links.byName = WaypointCache[tWpBIndex].links.byName or {}
		WaypointCache[tWpBIndex].links.byId[tWpAIndex] = tDistance
		WaypointCache[tWpBIndex].links.byName[aWpAName] = tDistance

		local tWpAId = WaypointCacheLookupCacheNameForId[aWpAName]
		local tWpBId = WaypointCacheLookupCacheNameForId[aWpBName]

		SkuOptions.db.global[MODULE_NAME].Links[tWpAId] = SkuOptions.db.global[MODULE_NAME].Links[tWpAId] or {}
		SkuOptions.db.global[MODULE_NAME].Links[tWpAId][tWpBId] = tDistance
		SkuOptions.db.global[MODULE_NAME].Links[tWpBId] = SkuOptions.db.global[MODULE_NAME].Links[tWpBId] or {}
		SkuOptions.db.global[MODULE_NAME].Links[tWpBId][tWpAId] = tDistance

		SkuOptions.db.global["SkuNav"].hasCustomMapData = true

		SkuNav:SaveLinkDataToProfile(aWpAName)
		SkuNav:SaveLinkDataToProfile(aWpBName)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:UpdateWpLinks(aWpAName)
	local tWpAIndex = WaypointCacheLookupAll[aWpAName]
	local tWpAData = SkuNav:GetWaypointData2(nil, tWpAIndex)

	if not WaypointCache[tWpAIndex].links.byId then
		return
	end

	for tWpBIndex, _ in pairs(tWpAData.links.byId) do
		local tDistance = SkuNav:Distance(tWpAData.worldX, tWpAData.worldY, WaypointCache[tWpBIndex].worldX, WaypointCache[tWpBIndex].worldY)
		WaypointCache[tWpAIndex].links.byId[tWpBIndex] = tDistance
		WaypointCache[tWpAIndex].links.byName[WaypointCache[tWpBIndex].name] = tDistance
		WaypointCache[tWpBIndex].links.byId[tWpAIndex] = tDistance
		WaypointCache[tWpBIndex].links.byName[aWpAName] = tDistance

		local tWpAId = WaypointCacheLookupCacheNameForId[aWpAName]
		local tWpBId = WaypointCacheLookupCacheNameForId[aWpBName]

		SkuOptions.db.global[MODULE_NAME].Links[tWpAId] = SkuOptions.db.global[MODULE_NAME].Links[tWpAId] or {}
		SkuOptions.db.global[MODULE_NAME].Links[tWpAId][WaypointCacheLookupCacheNameForId[WaypointCache[tWpBIndex].name]] = tDistance
		SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[WaypointCache[tWpBIndex].name]] = SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[WaypointCache[tWpBIndex].name]] or {}
		SkuOptions.db.global[MODULE_NAME].Links[WaypointCacheLookupCacheNameForId[WaypointCache[tWpBIndex].name]][tWpAId] = tDistance
	end

	SkuOptions.db.global["SkuNav"].hasCustomMapData = true
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetBestMapForUnit(aUnitId)
	local tPlayerUIMap = C_Map.GetBestMapForUnit(aUnitId)

	if tPlayerUIMap == 1415 or tPlayerUIMap == 1414 then
		local tMMZoneText = GetMinimapZoneText()

		--this is because of strange areas where C_Map.GetBestMapForUnit is returning continent IDs
		if tMMZoneText == L["Timbermaw Hold"] then
			tPlayerUIMap = 1448
		elseif tMMZoneText == L["Der Südstrom"] then
			tPlayerUIMap = 1413
		elseif tMMZoneText == L["Die Höhlen des Wehklagens"] or tMMZoneText == L["Höhle der Nebel"]  then
			tPlayerUIMap = 1413
		elseif tMMZoneText == L["Schmiedevaters Grabmal"] or tMMZoneText == L["Schwarzfelsspitze"] then
			tPlayerUIMap = 1428
		else
			for i, v in pairs(SkuDB.InternalAreaTable) do
				if v.AreaName_lang[Sku.Loc] == tMMZoneText then
					tPlayerUIMap = SkuNav:GetUiMapIdFromAreaId(v.ParentAreaID)
				end
			end
		end
	end

	return tPlayerUIMap
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnInitialize()
	SkuNav:RegisterEvent("PLAYER_LOGIN")
	SkuNav:RegisterEvent("PLAYER_ENTERING_WORLD")
	SkuNav:RegisterEvent("PLAYER_LEAVING_WORLD")
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetDirectionTo(aP1x, aP1y, aP2x, aP2y)
	if aP1x == nil or aP1y == nil or aP2x == nil or aP2y == nil or GetPlayerFacing() == nil then
		return 0
	end
	if aP2x == 0 and aP2y == 0 then
		return 0
	end
		
	local ep2x = (aP2x - aP1x)
	local ep2y = (aP2y - aP1y)
	
	local Wa = math.acos(ep2x / math.sqrt(ep2x^2 + ep2y^2)) * (180 / math.pi)
	
	if ep2y > 0 then
		Wa = Wa * -1
	end
	local facing = (GetPlayerFacing() * (180 / math.pi))
	local facingfinal = facing
	if facing > 180 then
		facingfinal = (360 - facing) * -1
	end
	
	local afinal = Wa + facingfinal
	if afinal > 180 then
		afinal = afinal - 360
	elseif afinal < -180 then
		afinal = 360 + afinal
	end
	
	local uhrfloat = (afinal + 15) / 30
	local uhr = math.floor((afinal + 15) / 30)
	if uhr < 0 then
		uhr = 12 + uhr
	end
	if uhr == 0 then
		uhr = 12
	end

	return uhr, uhrfloat, afinal
end

---------------------------------------------------------------------------------------------------------------------------------------
local floor = math.floor
local sqrt = math.sqrt
function SkuNav:Distance(sx, sy, dx, dy)
	if sx and sy and dx and dy then
    	return floor(sqrt((sx - dx) ^ 2 + (sy - dy) ^ 2)), sqrt((sx - dx) ^ 2 + (sy - dy) ^ 2)
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetContinentNameFromContinentId(aContinentId)
	if not SkuDB.ContinentIds[aContinentId] then
		return
	end
	return SkuDB.ContinentIds[aContinentId].Name_lang[Sku.Loc]
end

---------------------------------------------------------------------------------------------------------------------------------------
local GetUiMapIdFromAreaIdCache = {}
function SkuNav:GetUiMapIdFromAreaId(aAreaId)
	if not SkuDB.InternalAreaTable[aAreaId] then
		return nil
	end
	if GetUiMapIdFromAreaIdCache[aAreaId] then
		return GetUiMapIdFromAreaIdCache[aAreaId]
	end

	local tCurrentId = aAreaId
	local tPrevId = aAreaId
	while tCurrentId > 0 do
		tPrevId = tCurrentId
		tCurrentId = SkuDB.InternalAreaTable[tCurrentId].ParentAreaID
	end

	for i, v in pairs(SkuDB.ExternalMapID) do
		if v.AreaId == tPrevId then
			GetUiMapIdFromAreaIdCache[aAreaId] = i
			return i
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetAreaIdFromUiMapId(aUiMapId)
	--dprint("GetAreaIdFromUiMapId", aUiMapId)
	local rAreaId
	local tMinimapZoneText = GetMinimapZoneText()
 	if tMinimapZoneText == L["Deeprun Tram"] then --fix for strange DeeprunTram zone
		rAreaId = 2257
	else
		if SkuDB.ExternalMapID[aUiMapId] then
			rAreaId = SkuDB.ExternalMapID[aUiMapId].AreaId
		end
	end
	return rAreaId
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetAreaIdFromAreaName(aAreaName)
	--dprint("GetAreaIdFromAreaName", aAreaName)
	local rAreaId
	local tPlayerUIMap = SkuNav:GetBestMapForUnit("player")
	for i, v in pairs(SkuDB.InternalAreaTable) do
		if (v.AreaName_lang[Sku.Loc] == aAreaName) and (SkuNav:GetUiMapIdFromAreaId(i) == tPlayerUIMap) then
			rAreaId = i
		end
	end
	--dprint("  ", tonumber(rAreaId))
	return rAreaId
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetAreaData(aAreaId)
	--dprint("GetAreaData", aAreaId)
	if not SkuDB.InternalAreaTable[aAreaId] then 
		return
	end
	return SkuDB.InternalAreaTable[aAreaId].ZoneName, SkuDB.InternalAreaTable[aAreaId].AreaName_lang[Sku.Loc], SkuDB.InternalAreaTable[aAreaId].ContinentID, SkuDB.InternalAreaTable[aAreaId].ParentAreaID, SkuDB.InternalAreaTable[aAreaId].Faction, SkuDB.InternalAreaTable[aAreaId].Flags
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetSubAreaIds(aAreaId)
	--dprint("GetSubAreaIds", aAreaId)
	local tAreas = {}
	for i, v in pairs(SkuDB.InternalAreaTable) do
		if v.ParentAreaID == tonumber(aAreaId) then
			tAreas[i] = i
			for i1, v1 in pairs(SkuDB.InternalAreaTable) do
				if v1.ParentAreaID == tonumber(i) then
					tAreas[i1] = i1
				end
			end
		end
	end
	return tAreas
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetCurrentAreaId(aUnitId)
	local tMinimapZoneText = GetMinimapZoneText()
	local tAreaId

	for i, v in pairs(SkuDB.InternalAreaTable) do
		if (v.AreaName_lang[Sku.Loc] == tMinimapZoneText)  and (SkuNav:GetUiMapIdFromAreaId(i) == tPlayerUIMap) then
			tAreaId = i
			break
		end
	end

	if not tAreaId then
		local tExtMapId = SkuDB.ExternalMapID[SkuNav:GetBestMapForUnit("player")]
		if aUnitId then
			tExtMapId = SkuDB.ExternalMapID[SkuNav:GetBestMapForUnit(aUnitId)]
		end
		if tExtMapId then
			for i, v in pairs(SkuDB.InternalAreaTable) do
				if v.AreaName_lang[Sku.Loc] == tExtMapId.Name_lang[Sku.Loc] then
					tAreaId = i
					break
				end
			end
		end
	end

	return tAreaId
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetDistanceToWp(aWpName)
	if not SkuNav:GetWaypointData2(aWpName) then
		return nil
	end

	local tEndx, tEndy = SkuNav:GetWaypointData2(aWpName).worldX, SkuNav:GetWaypointData2(aWpName).worldY

	local x, y = UnitPosition("player")
	if x and y then
		local ep2x = (tEndx - x)
		local ep2y = (tEndy - y)
		if ep2x and ep2y then
			return SkuNav:Distance(0, 0, ep2x, ep2y)
		else
			return nil
		end
	else
		return nil
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetDirectionToWp(aWpName)
	if not SkuNav:GetWaypointData2(aWpName) then
		return nil
	end

	local x, y = UnitPosition("player")

	return SkuNav:GetDirectionTo(x, y, SkuNav:GetWaypointData2(aWpName).worldX, SkuNav:GetWaypointData2(aWpName).worldY)
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:StartRouteRecording(aWPAName, aDeleteFlag)
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp then
		return
	end

	SkuOptions.db.profile[MODULE_NAME].routeRecording = true
	if aDeleteFlag then
		SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete = true
	end
	SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = aWPAName

	SkuOptions.tmpNpcWayPointNameBuilder_Npc = ""
	SkuOptions.tmpNpcWayPointNameBuilder_Zone = ""
	SkuOptions.tmpNpcWayPointNameBuilder_Coords = ""

	if not aDeleteFlag then
		print("Recording started: ", aWPAName)
		SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-on3_1.mp3")
	else
		print("Deleting started: ", aWPAName)
		SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-waterdrop2.mp3")
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:EndRouteRecording(aWpName, aDeleteFlag)
	--print("EndRouteRecording", aWpName, aDeleteFlag) 
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == false or 
		not SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp or 
		SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp == "" 
	then
		return
	end

	if not aDeleteFlag and SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete ~= true then
		if SkuNav:GetWaypointData2(aWpName) then
			--update links
			local tWpAName = aWpName
			local tWpBName = SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp
			if tWpAName ~= tWpBName then
				SkuNav:CreateWpLink(tWpAName, tWpBName)
			end
		end
	end

	if aDeleteFlag and SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
		SkuNav:DeleteWpLink(aWpName, SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp)
		SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete = nil
	end

	SkuOptions.db.profile[MODULE_NAME].routeRecording = false
	SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = nil

	if not aDeleteFlag then
		print("Recording stopped:", aWPAName)
		SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-off2.mp3")
	else
		print("Deleting stopped:", aWPAName)
		SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-waterdrop1.mp3")
	end

end

---------------------------------------------------------------------------------------------------------------------------------------
local function CheckPolygons(x, y)
	local rPolyIndex = {}
	local fPlayerPosX, fPlayerPosY = UnitPosition("player")
	local _, _, tPlayerContinentID  = SkuNav:GetAreaData(SkuNav:GetCurrentAreaId())

	for i = 1, #SkuDB.Polygons.data do
		if SkuDB.Polygons.data[i].continentId == tPlayerContinentID then
			local tInPolygon = 0
			for q = 1, #SkuDB.Polygons.data[i].nodes do
				local ax, ay, bx, by = SkuDB.Polygons.data[i].nodes[q].x, SkuDB.Polygons.data[i].nodes[q].y
				if q < #SkuDB.Polygons.data[i].nodes then 
					bx, by = SkuDB.Polygons.data[i].nodes[q+1].x, SkuDB.Polygons.data[i].nodes[q+1].y
				else
					bx, by = SkuDB.Polygons.data[i].nodes[1].x, SkuDB.Polygons.data[i].nodes[1].y
				end
				if SkuNav:IntersectionPoint(fPlayerPosX, fPlayerPosY, 50000, 50000, ax, ay, bx, by) then
					tInPolygon = tInPolygon + 1
				end
			end
			if tInPolygon == 1 or (floor(tInPolygon / 2) * 2 ~= tInPolygon) then
				rPolyIndex[#rPolyIndex + 1] = i
			end
		end
	end

	return rPolyIndex
end

---------------------------------------------------------------------------------------------------------------------------------------
local tOldPolyZones = {
   [1] = {[1] = 0,},
   [2] = {[1] = 0,},
   [3] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0,},
   [4] = {[1] = 0,},
}
local tdiold, tdisold = 0,0
local tCurrentDragWpName

function SkuNav:ProcessPolyZones()
	local tPolyZones = CheckPolygons(UnitPosition("player"))
	local tNewPolyZones = {
		[1] = {[1] = 0,},
		[2] = {[1] = 0,},
		[3] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0,},
		[4] = {[1] = 0,},
	}
	for p = 1, #tPolyZones do
		tNewPolyZones[SkuDB.Polygons.data[tPolyZones[p]].type][SkuDB.Polygons.data[tPolyZones[p]].subtype] = tNewPolyZones[SkuDB.Polygons.data[tPolyZones[p]].type][SkuDB.Polygons.data[tPolyZones[p]].subtype] + 1
	end
	--setmetatable(tNewPolyZones, SkuPrintMT)					
	--dprint(tNewPolyZones)
	--world
	if tOldPolyZones[1][1] ~= tNewPolyZones[1][1] then
		if tNewPolyZones[1][1] == 0 then
			--dprint("world left")
		elseif tOldPolyZones[1][1] == 0 then
			--dprint("world entered")
		end
		tOldPolyZones[1][1] = tNewPolyZones[1][1] 
	end
	--fly
	if tOldPolyZones[2][1] ~= tNewPolyZones[2][1] then
		if tNewPolyZones[2][1] == 0 then
			--dprint("fly left")
		elseif tOldPolyZones[2][1] == 0 then
			--dprint("fly entered")
		end
		tOldPolyZones[2][1] = tNewPolyZones[2][1] 
	end
	--faction
	if tOldPolyZones[3][1] ~= tNewPolyZones[3][1] then
		if tNewPolyZones[3][1] == 0 then
			--dprint("alliance left")
		elseif tOldPolyZones[3][1] == 0 then
			--dprint("alliance entered")
		end
		tOldPolyZones[3][1] = tNewPolyZones[3][1] 
	end
	if tOldPolyZones[3][2] ~= tNewPolyZones[3][2] then
		if tNewPolyZones[3][2] == 0 then
			--dprint("horde left")
		elseif tOldPolyZones[3][2] == 0 then
			--dprint("horde entered")
		end
		tOldPolyZones[3][2] = tNewPolyZones[3][2] 
	end
	if tOldPolyZones[3][3] ~= tNewPolyZones[3][3] then
		if tNewPolyZones[3][3] == 0 then
			--dprint("horde left")
		elseif tOldPolyZones[3][3] == 0 then
			--dprint("horde entered")
		end
		tOldPolyZones[3][3] = tNewPolyZones[3][3] 
	end
	if tOldPolyZones[3][4] ~= tNewPolyZones[3][4] then
		if tNewPolyZones[3][4] == 0 then
			--dprint("horde left")
		elseif tOldPolyZones[3][4] == 0 then
			--dprint("horde entered")
		end
		tOldPolyZones[3][4] = tNewPolyZones[3][4] 
	end

	--other
	if tOldPolyZones[4][1] ~= tNewPolyZones[4][1] then
		if tNewPolyZones[4][1] == 0 then
			--dprint("other left")
		elseif tOldPolyZones[4][1] == 0 then
			--dprint("other entered")
		end
		tOldPolyZones[4][1] = tNewPolyZones[4][1] 
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
local mouseMiddleDown = false
local mouseMiddleUp = false
local mouseLeftDown = false
local mouseLeftUp = false
local mouseRightDown = false
local mouseRightUp = false
local mouse4Down = false
local mouse4Up = false
local mouse5Down = false
local mouse5Up = false
function SkuNav:ProcessRecordingMousClickStuff()
	--rt recording per mouse click stuff
	if IsControlKeyDown() == true then
		_G["SkuNavWpDragClickTrap"]:Show()

		if mouse5Down == false then
			if IsMouseButtonDown("Button5") == true then
				mouse5Up = false
				mouse5Down = true
				SkuNav:OnMouse5Down()
			end
		elseif mouse5Down == true then
			SkuNav:OnMouse5Hold()
			if IsMouseButtonDown("Button5") ~= true then
				mouse5Down = false
				mouse5Up = true
				SkuNav:OnMouse5Up()
			end
		end

		if mouse4Down == false then
			if IsMouseButtonDown("Button4") == true then
				mouse4Up = false
				mouse4Down = true
				SkuNav:OnMouse4Down()
			end
		elseif mouse4Down == true then
			SkuNav:OnMouse4Hold()
			if IsMouseButtonDown("Button4") ~= true then
				mouse4Down = false
				mouse4Up = true
				SkuNav:OnMouse4Up()
			end
		end

		if mouseMiddleDown == false then
			if IsMouseButtonDown("MiddleButton") == true then
				mouseMiddleUp = false
				mouseMiddleDown = true
				SkuNav:OnMouseMiddleDown()
			end
		elseif mouseMiddleDown == true then
			SkuNav:OnMouseMiddleHold()
			if IsMouseButtonDown("MiddleButton") ~= true then
				mouseMiddleDown = false
				mouseMiddleUp = true
				SkuNav:OnMouseMiddleUp()
			end
		end

		if mouseLeftDown == false then
			if IsMouseButtonDown("LeftButton") == true then
				mouseLeftUp = false
				mouseLeftDown = true
				SkuNav:OnMouseLeftDown()
			end
		elseif mouseLeftDown == true then
			SkuNav:OnMouseLeftHold()
			if IsMouseButtonDown("LeftButton") ~= true then
				mouseLeftDown = false
				mouseLeftUp = true
				SkuNav:OnMouseLeftUp()
			end
		end

		if mouseRightDown == false then
			if IsMouseButtonDown("RightButton") == true then
				mouseRightUp = false
				mouseRightDown = true
				SkuNav:OnMouseRightDown()
			end
		elseif mouseRightDown == true then
			SkuNav:OnMouseRightHold()
			if IsMouseButtonDown("RightButton") ~= true then
				mouseRightDown = false
				mouseRightUp = true
				SkuNav:OnMouseRightUp()
			end

		end
	else
		mouseMiddleDown = false
		mouseMiddleUp = false
		mouseLeftDown = false
		mouseLeftUp = false
		mouseRightDown = false
		mouseRightUp = false
		_G["SkuNavWpDragClickTrap"]:Hide()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------
local metapathFollowingTargetNameAnnounced = false
SkuNavMmDrawTimer = 0.2
function SkuNav:CreateSkuNavControl()
	local ttimeDegreesChangeInitial = nil
	local ttime = GetServerTime()
	local ttimeDraw = GetServerTime()

	local f = _G["SkuNavControl"] or CreateFrame("Frame", "SkuNavControl", UIParent)
	f:SetScript("OnUpdate", function(self, time) 
		ttime = ttime + time
		ttimeDraw = ttimeDraw + time

		--tmp drawing rts on UIParent for debugging
		if ttimeDraw > (SkuNavMmDrawTimer or 0.2) then
			SkuNav:DrawAll(_G["Minimap"])
			ttimeDraw = 0
		end
		
		SkuWaypointWidgetCurrent = nil
		for i, v in SkuWaypointWidgetRepo:EnumerateActive() do
			if i:IsVisible() == true then
				if i:IsMouseOver() then
					if i.aText ~= SkuWaypointWidgetCurrent then
						SkuWaypointWidgetCurrent = i.aText

						GameTooltip.SkuWaypointWidgetCurrent = i.aText
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(i, "ANCHOR_RIGHT")
						GameTooltip:AddLine(i.aText, 1, 1, 1)
						GameTooltip:Show()
						i:SetSize(3, 3)
						local r, g, b, t = i:GetVertexColor()
						i.oldColor = {r = r, g = g, b = b, t = t}
						i:SetColorTexture(0, 1, 1)
					else
						i:SetSize(2, 2)
						if i.oldColor then
							i:SetColorTexture(i.oldColor.r, i.oldColor.g, i.oldColor.b, i.oldColor.a)
							--i:SetColorTexture(i.oldColor)
						end
					end
				end
			end
		end
		
		if SkuWaypointWidgetRepoMM then
			if _G["SkuNavMMMainFrame"]:IsShown() then
				SkuWaypointWidgetCurrent = nil
				for i, v in SkuWaypointWidgetRepoMM:EnumerateActive() do
					if i:IsVisible() == true then
						if i.aText ~= "line" then
							if i:IsMouseOver() then
								local _, _, _, x, y = i:GetPoint(1)
								local MMx, MMy = _G["SkuNavMMMainFrame"]:GetSize()
								MMx, MMy = MMx / 2, MMy / 2
								if x > -MMx and x < MMx and y > -MMy and y < MMy then
									if i.aText ~= SkuWaypointWidgetCurrent then
										SkuWaypointWidgetCurrent = i.aText

										GameTooltip.SkuWaypointWidgetCurrent = i.aText
										GameTooltip:ClearLines()
										GameTooltip:SetOwner(i, "ANCHOR_RIGHT")
										GameTooltip:AddLine(i.aText, 1, 1, 1)

										if i.aComments then
											for x = 1, #i.aComments do
												GameTooltip:AddLine(i.aComments[x], 1, 1, 0)
											end
										end
										GameTooltip:Show()
										local r, g, b, a = i:GetVertexColor()
										i.oldColor = {r = r, g = g, b = b, a = a}
										--i.oldColor = i:GetVertexColor()
										i:SetColorTexture(0, 1, 1)
									else
										--i:SetSize(2, 2)
										if i.oldColor then
											i:SetColorTexture(i.oldColor.r, i.oldColor.g, i.oldColor.b, i.oldColor.a)
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if GameTooltip:IsShown() and not SkuWaypointWidgetCurrent and GameTooltip.SkuWaypointWidgetCurrent then
			GameTooltip.SkuWaypointWidgetCurrent = nil
			GameTooltip:Hide()
		end

		SkuNav:ProcessRecordingMousClickStuff()

		if ttime > 0.1 then
			SkuNav:ProcessPolyZones()
			ttime = 0
		end
	end)
end

--------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnEnable()
	if not SkuOptions.db.global[MODULE_NAME] then
		SkuOptions.db.global[MODULE_NAME] = {}
	end
	if not SkuOptions.db.global[MODULE_NAME].Waypoints then
		SkuOptions.db.profile[MODULE_NAME].Waypoints = nil
		SkuOptions.db.global[MODULE_NAME].Waypoints = {}
	end

	SkuOptions.db.profile[MODULE_NAME].routeRecording = false
	SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = nil
	SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete = nil

	SkuNav:SkuNavMMOpen()
	SkuNav:CreateSkuNavControl()
end

---------------------------------------------------------------------------------------------------------------------------------------
do
	local f = _G["SkuNavWpDragClickTrap"] or CreateFrame("Frame", "SkuNavWpDragClickTrap", _G["SkuNavMMMainFrameScrollFrame"], BackdropTemplateMixin and "BackdropTemplate" or nil)
	--f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="", tile = false, tileSize = 0, edgeSize = 32, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
	--f:SetBackdropColor(0, 0, 1, 1)
	f:SetFrameStrata("DIALOG")
	f:RegisterForDrag()
	f:SetWidth(1)
	f:SetHeight(1)
	f:SetAllPoints()
	f:EnableMouse(true)
	f:Hide()
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseLeftDown()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseLeftHold()

end



---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseLeftUp()
	if IsShiftKeyDown() then
		--Create WP
		if SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
			print("not possible. link deleting in progress.")
			SkuNav:PlayFailSound()
			return
		end
		local tWy, tWx = SkuNavMMContentToWorld(SkuNavMMGetCursorPositionContent2())
		local tWpSize = 1
		--if IsShiftKeyDown() then
			--tWpSize = 5
		--end
		local tNewWpName = SkuNav:CreateWaypoint(nil, tWx, tWy, tWpSize)
		if SkuOptions.db.profile[MODULE_NAME].routeRecording == true and SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp then
			SkuNav:CreateWpLink(tNewWpName, SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp)
			SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = tNewWpName
		end
		SkuOptions.db.global["SkuNav"].hasCustomMapData = true
		print("Waypoint created")

	elseif IsAltKeyDown() then
		--Add comment to WP
		if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
			print("not possible. link recording or deleting in progress.")
			SkuNav:PlayFailSound()
		else
			if SkuWaypointWidgetCurrent then
				SkuOptions:AddCommentToWp(SkuWaypointWidgetCurrent)
			end
		end
	else
		--Start/end link add
		if SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
			print("not possible. link deleting in progress.")
			SkuNav:PlayFailSound()
		else
			local tWpName = SkuWaypointWidgetCurrent
			if not tWpName then
				return
			end
		
			local wpObj = SkuNav:GetWaypointData2(tWpName)
			if not wpObj then
				return
			end
		
			if SkuOptions.db.profile[MODULE_NAME].routeRecording ~= true then
				--print("Start:", tWpName)
				SkuNav:StartRouteRecording(tWpName)
			else
				if SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete ~= true then
					--print("End:", tWpName)
					SkuNav:EndRouteRecording(tWpName)
				end
			end
			SkuOptions.db.global["SkuNav"].hasCustomMapData = true
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseRightDown()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseRightHold()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseRightUp()
	if IsAltKeyDown() then
		--Delete comments from WP
		if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
			print("not possible. link recording or deleting in progress.")
			SkuNav:PlayFailSound()
		else

			if not SkuWaypointWidgetCurrent then
				return
			end
			local wpObj = SkuNav:GetWaypointData2(SkuWaypointWidgetCurrent)
			if not wpObj then
				return
			end
			SkuNav:SetWaypoint(SkuWaypointWidgetCurrent, {comments = 
				{
					["deDE"] = {},
					["enUS"] = {},
				}
			})
			SkuOptions.db.global["SkuNav"].hasCustomMapData = true
		end

	elseif IsShiftKeyDown() then
		--Delete WP
		if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
			print("not possible. link recording or deleting in progress.")
			SkuNav:PlayFailSound()
		else
			if SkuWaypointWidgetCurrent then
				local wpObj = SkuNav:GetWaypointData2(SkuWaypointWidgetCurrent)
				if wpObj then
					SkuNav:DeleteWaypoint(SkuWaypointWidgetCurrent)
					SkuOptions.db.global["SkuNav"].hasCustomMapData = true
				end
			end
		end
	else
		--Start/end link delete
		if SkuOptions.db.profile[MODULE_NAME].routeRecording == true and SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete ~= true then
			print("not possible. link recording in progress.")
			SkuNav:PlayFailSound()
		else
			local tWpName = SkuWaypointWidgetCurrent
			if not tWpName then
				return
			end
		
			local wpObj = SkuNav:GetWaypointData2(tWpName)
			if not wpObj then
				return
			end
		
			if SkuOptions.db.profile[MODULE_NAME].routeRecording ~= true then
				--print("Start:", tWpName)
				SkuNav:StartRouteRecording(tWpName, true)
			else
				if SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
					--print("End:", tWpName)	
					SkuNav:EndRouteRecording(tWpName, true)
				end
			end
			SkuOptions.db.global["SkuNav"].hasCustomMapData = true
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse4Down()
	--start Move WP
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
		print("not possible. link recording or deleting in progress.")
		SkuNav:PlayFailSound()
	else
		local tWpName = SkuWaypointWidgetCurrent
		if tWpName then
			local wpObj = SkuNav:GetWaypointData2(tWpName)
			if wpObj then
				tCurrentDragWpName = tWpName
				SkuOptions.db.global["SkuNav"].hasCustomMapData = true
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse4Hold()
	--Hold Move WP
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
	else
		if tCurrentDragWpName then
			local tWpData = SkuNav:GetWaypointData2(tCurrentDragWpName)
			if tWpData then
				local tDragY, tDragX = SkuNavMMContentToWorld(SkuNavMMGetCursorPositionContent2())
				if tDragX and tDragY then
					SkuNav:SetWaypoint(tCurrentDragWpName, {
						worldX = tDragX,
						worldY = tDragY,
					})
					SkuOptions.db.global["SkuNav"].hasCustomMapData = true
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse4Up()
	--End Move WP
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
		print("not possible. link recording or deleting in progress.")
		SkuNav:PlayFailSound()
	else
		if tCurrentDragWpName then
			local tWpData = SkuNav:GetWaypointData2(tCurrentDragWpName)
			if tWpData then
				local tDragY, tDragX = SkuNavMMContentToWorld(SkuNavMMGetCursorPositionContent2())
				if tDragX and tDragY then
					SkuNav:SetWaypoint(tCurrentDragWpName, {
						worldX = tDragX,
						worldY = tDragY,
					})
					SkuOptions.db.global["SkuNav"].hasCustomMapData = true
				end
			end
		end
		_G["SkuNavWpDragClickTrap"]:Hide()
		SkuWaypointWidgetCurrent = nil
		SkuWaypointWidgetCurrentMMX = nil
		SkuWaypointWidgetCurrentMMY = nil
		tCurrentDragWpName = nil
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseMiddleDown()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseMiddleHold()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouseMiddleUp()
	--Rename WP
	if SkuOptions.db.profile[MODULE_NAME].routeRecording == true or SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete == true then
		print("not possible. link recording or deleting in progress.")
		SkuNav:PlayFailSound()
	else
		if SkuWaypointWidgetCurrent then
			local tOldName = SkuWaypointWidgetCurrent
			local tWpData = SkuNav:GetWaypointData2(SkuWaypointWidgetCurrent)
			if tWpData then
				if tWpData.typeId ~= 1 then
					print("only custom waypoints can be renamed")
					SkuNav:PlayFailSound()
					return
				end
				SkuOptions:EditBoxShow("", function(a, b, c) 
					local tText = SkuOptionsEditBoxEditBox:GetText() 
					if tText ~= "" then
						if SkuOptions:RenameWp(tOldName, tText) ~= false then
							SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-notification15.mp3")
							print("renamed")
						else
							print("renaming failed")
							SkuNav:PlayFailSound()
						end
					else
						print("renaming failed")
						print("name empty")
						SkuNav:PlayFailSound()
					end
				end)
				print("enter new name and press enter or press escape to cancel")
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse5Down()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse5Hold()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnMouse5Up()
	-- create poly point
	if SkuNavRecordingPoly > 0 and SkuNavRecordingPolyFor then
		local tWorldY, tWorldX = SkuNavMMContentToWorld(SkuNavMMGetCursorPositionContent2())
		SkuDB.Polygons.data[SkuNavRecordingPolyFor].nodes[#SkuDB.Polygons.data[SkuNavRecordingPolyFor].nodes + 1] = {x = tWorldX, y = tWorldY,}
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:IntersectionPoint(x1, y1, x2, y2, x3, y3, x4, y4)
	if x1 and y1 and x2 and y2 and x3 and y3 and x4 and y4 then
		 local d 
		 local Ua 
		 local Ub 
		 --Pre calc the denominator, if zero then both lines are parallel and there is no intersection
		 d = ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
		 if d ~= 0 then
			  --Solve for the simultaneous equations
			  Ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / d
			  Ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / d
		 end 
		 if Ua and Ub then
			  --Could the lines intersect?
			  if Ua >= -0.0 and Ua <= 1.0 and Ub >= -0.0 and Ub <= 1.0 then
					--Calculate the intersection point
					local x = x1 + Ua * (x2 - x1)
					local y = y1 + Ua * (y2 - y1)
					--Yes, they do
					return x, y, Ua
			  end
		 end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnDisable()

end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:PLAYER_LEAVING_WORLD(...)
	if SkuOptions.db.profile[MODULE_NAME].SkuNavMMMainIsCollapsed == false then
		if _G["SkuNavMMMainFrameOptionsParent"]:IsShown() then
			_G["SkuNavMMMainFrameOptionsParent"]:SetWidth(0)
			_G["SkuNavMMMainFrameOptionsParent"]:Hide()
			_G["SkuNavMMMainFrame"]:ClearAllPoints()
			_G["SkuNavMMMainFrame"]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (_G["SkuNavMMMainFrame"]:GetLeft() + 300 ), (_G["SkuNavMMMainFrame"]:GetBottom()))
			_G["SkuNavMMMainFrame"]:SetWidth(_G["SkuNavMMMainFrame"]:GetWidth() - 300)

			_G["SkuNavMMMainFrameScrollFrame"]:SetPoint("TOPLEFT", _G["SkuNavMMMainFrame"], "TOPLEFT", _G["SkuNavMMMainFrameOptionsParent"]:GetWidth() + 5, -5)
			_G["SkuNavMMMainFrameScrollFrame1"]:SetPoint("TOPLEFT", _G["SkuNavMMMainFrame"], "TOPLEFT", _G["SkuNavMMMainFrameOptionsParent"]:GetWidth() + 5, -5)
			--SkuOptions.db.profile[MODULE_NAME].SkuNavMMMainIsCollapsed = true
		end
	end	
	SkuOptions.db.profile["SkuNav"].metapathFollowingMetapaths = {}
	if SkuOptions.db.global["SkuNav"].hasCustomMapData ~= true then
		SkuOptions.db.global["SkuNav"].Waypoints = {}
		SkuOptions.db.global["SkuNav"].Links = {}
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:PLAYER_LOGIN(...)
	SkuNav.MinimapFull = false
	SkuOptions.db.global["SkuNav"] = SkuOptions.db.global["SkuNav"] or {}

	--load default data if there isn't custom data
	SkuNav:LoadDefaultMapData()

	SkuOptions.db.profile[MODULE_NAME].routeRecording = false
	SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = nil

	SkuNav:SkuNavMMOpen()
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:LoadDefaultMapData(aForce)
	if SkuOptions.db.global["SkuNav"].hasCustomMapData ~= true or aForce then
		local t = SkuDB.routedata["global"]["Waypoints"]
		SkuOptions.db.global["SkuNav"].Waypoints = t
		local tl = SkuDB.routedata["global"]["Links"]
		SkuOptions.db.global["SkuNav"].Links = tl
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:PLAYER_ENTERING_WORLD(aEvent, aIsInitialLogin, aIsReloadingUi)
	SkuOptions.db.profile[MODULE_NAME].metapathFollowing = false
	SkuOptions.db.profile[MODULE_NAME].routeRecording = false
	SkuOptions.db.profile["SkuNav"].waypointFilterString = ""

	SkuNav:CreateWaypointCache()

	if _G["SkuNavMMMainFrameZoneSelect"] then
		C_Timer.NewTimer(1, function()
			if SkuNav:GetCurrentAreaId() then
				_G["SkuNavMMMainFrameZoneSelect"].value = -1 --SkuNav:GetCurrentAreaId()
				_G["SkuNavMMMainFrameZoneSelect"]:SetText("Current Zone")--SkuDB.InternalAreaTable[SkuNav:GetCurrentAreaId()].AreaName_lang[Sku.Loc])	
			end
		end)
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
local function SkuSpairs(t, order)
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:CreateWaypoint(aName, aX, aY, aSize, aForcename, aIsTempWaypoint)
	--dprint("CreateWaypoint", aName, aX, aY, aSize, aForcename, aIsTempWaypoint)
	aSize = aSize or 1
	local tPName = UnitName("player")

	if aName == nil then
		-- this generates (almost) unique auto wp numbers, to avoid duplicates and renaming on import/export of WPs and Rts later on
		-- numbers > 1000000 are not vocalized by SkuVoice; thus they are silent, even if they are part of the auto WP names
		local tNumber = string.gsub(tostring(GetServerTime()..format("%.2f", GetTimePreciseSec())), "%.", "")
		local tAutoIndex = tNumber:gsub("%.", "")
		if SkuNav:GetWaypointData2(L["auto"]..";"..tAutoIndex) ~= nil then
			while SkuNav:GetWaypointData2(L["auto"]..";"..tAutoIndex)  ~= nil do
				tAutoIndex = tAutoIndex + 1
			end
		end
		aName = L["auto"]..";"..tAutoIndex
		tPName = "SkuNav"
	end

	local tAreaId = SkuNav:GetCurrentAreaId()
	local tZoneName, tAreaName_lang, tContinentID, tParentAreaID, tFaction, tFlags = SkuNav:GetAreaData(tAreaId)

	--add number if name already exists
	if tZoneName then
		if SkuNav:GetWaypointData2(aName) and not aForcename then
			local q = 1
			while SkuNav:GetWaypointData2(aName..q) do
				q = q + 1
			end
			aName = aName..q
		end

		local worldx, worldy = UnitPosition("player")
		if aX and aY then
			worldx, worldy = aX, aY
		end
		local tPlayerContintentId = select(3, SkuNav:GetAreaData(SkuNav:GetCurrentAreaId()))

		SkuNav:SetWaypoint(aName,  {
			["contintentId"] = tPlayerContintentId,
			["areaId"] = tAreaId,
			["worldX"] = worldx,
			["worldY"] = worldy,
			["createdAt"] = GetTime(),
			["createdBy"] = tPName,
			["size"] = aSize,
		}, aIsTempWaypoint)
	else
		aName = nil
	end

	if aName and not aIsTempWaypoint then
		if not string.find(aName, L["Einheiten;Route;"]) then
			SkuOptions.db.global["SkuNav"].hasCustomMapData = true
		end
	end

	SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-notification15.mp3")

	return aName
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:SetWaypoint(aName, aData, aIsTempWaypoint)
	--print("SetWaypoint", aName, aData)

	local tWpIndex
	local tIsNew

	if WaypointCacheLookupAll[aName] then
		if WaypointCacheLookupPerContintent[WaypointCache[WaypointCacheLookupAll[aName]].contintentId] then
			WaypointCacheLookupPerContintent[WaypointCache[WaypointCacheLookupAll[aName]].contintentId][WaypointCacheLookupAll[aName]] = nil
		end
		tWpIndex = WaypointCacheLookupAll[aName]
		if WaypointCache[tWpIndex].typeId ~= 1 then
			tIsNew = true
		end
	else
		if not string.find(aName, L["Quick waypoint"]) then
			tWpIndex = #WaypointCache + 1
			WaypointCache[tWpIndex] = {
				name = aName,
				typeId = 1,
			}
			tIsNew = true
		else
			print("ERROR - THIS SHOULD NOT HAPPEN:")
			print("tried to add quick waypoint as new waypoint", aName)
			return
		end
	end
	
	if (not aData.contintentId and not WaypointCache[tWpIndex].contintentId) == true or (not aData.contintentId and not WaypointCache[tWpIndex].contintentId) == true then
		print("ERROR - THIS SHOULD NOT HAPPEN:")
		print("SetWaypoint", aData)
		print("no areaid, nocontinentid")
		return
	end

	WaypointCache[tWpIndex].name = aName
	WaypointCache[tWpIndex].role = aData.role or WaypointCache[tWpIndex].role or ""
	WaypointCache[tWpIndex].typeId = 1
	WaypointCache[tWpIndex].spawn = 1
	WaypointCache[tWpIndex].contintentId = aData.contintentId or WaypointCache[tWpIndex].contintentId
	WaypointCache[tWpIndex].areaId = aData.areaId or WaypointCache[tWpIndex].areaId
	WaypointCache[tWpIndex].uiMapId = SkuNav:GetUiMapIdFromAreaId(aData.areaId) or WaypointCache[tWpIndex].uiMapId
	WaypointCache[tWpIndex].worldX = aData.worldX or WaypointCache[tWpIndex].worldX
	WaypointCache[tWpIndex].worldY = aData.worldY or WaypointCache[tWpIndex].worldY
	WaypointCache[tWpIndex].createdAt = aData.createdAt or WaypointCache[tWpIndex].createdAt or 0
	WaypointCache[tWpIndex].createdBy = aData.createdBy or WaypointCache[tWpIndex].createdBy or "SkuNav"
	WaypointCache[tWpIndex].size = aData.size or WaypointCache[tWpIndex].size or 1
	WaypointCache[tWpIndex].comments = aData.comments or WaypointCache[tWpIndex].comments or {
		["deDE"] = {},
		["enUS"] = {},
	}
	WaypointCache[tWpIndex].links = aData.links or WaypointCache[tWpIndex].links or {byId = nil, byName = nil,}

	WaypointCacheLookupAll[aName] = tWpIndex

	if not WaypointCacheLookupPerContintent[WaypointCache[tWpIndex].contintentId] then
		WaypointCacheLookupPerContintent[WaypointCache[tWpIndex].contintentId] = {}
	end
	WaypointCacheLookupPerContintent[WaypointCache[tWpIndex].contintentId][tWpIndex] = aName

	if tIsNew then
		table.insert(SkuOptions.db.global[MODULE_NAME].Waypoints, {
			["names"] = {
				[Sku.Loc] = WaypointCache[tWpIndex].name,
			},
			["contintentId"] = WaypointCache[tWpIndex].contintentId,
			["areaId"] = WaypointCache[tWpIndex].areaId,
			["worldX"] = WaypointCache[tWpIndex].worldX,
			["worldY"] = WaypointCache[tWpIndex].worldY,
			["createdAt"] = WaypointCache[tWpIndex].createdAt,
			["createdBy"] = WaypointCache[tWpIndex].createdBy,
			["size"] = WaypointCache[tWpIndex].size,
			["lComments"] = {
				["deDE"] = {},
				["enUS"] = {},
			},
		})

		WaypointCache[tWpIndex].dbIndex = #SkuOptions.db.global[MODULE_NAME].Waypoints

		WaypointCacheLookupCacheNameForId[aName] = SkuNav:BuildWpIdFromData(1, WaypointCache[tWpIndex].dbIndex, 1, WaypointCache[tWpIndex].areaId)

		if not string.find(WaypointCache[tWpIndex].name, L["Quick waypoint"]) then
			for i, v in pairs(Sku.Locs) do
				if not SkuOptions.db.global[MODULE_NAME].Waypoints[WaypointCache[tWpIndex].dbIndex].names[v] or SkuOptions.db.global[MODULE_NAME].Waypoints[WaypointCache[tWpIndex].dbIndex].names[v] == "" then
					if string.find(WaypointCache[tWpIndex].name, "auto;") then
						SkuOptions.db.global[MODULE_NAME].Waypoints[WaypointCache[tWpIndex].dbIndex].names[v] = WaypointCache[tWpIndex].name
					else
						SkuOptions.db.global[MODULE_NAME].Waypoints[WaypointCache[tWpIndex].dbIndex].names[v] = "UNTRANSLATED "..WaypointCache[tWpIndex].name
					end
				end
			end
		end
	else
		local tWpId = WaypointCache[tWpIndex].dbIndex
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["names"][Sku.Loc] = WaypointCache[tWpIndex].name
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["contintentId"] = WaypointCache[tWpIndex].contintentId 
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["areaId"] = WaypointCache[tWpIndex].areaId
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["worldX"] = WaypointCache[tWpIndex].worldX
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["worldY"] = WaypointCache[tWpIndex].worldY
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["createdAt"] = WaypointCache[tWpIndex].createdAt
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["createdBy"] = WaypointCache[tWpIndex].createdBy
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["size"] = WaypointCache[tWpIndex].size
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpId]["lComments"] = WaypointCache[tWpIndex].comments
	end	

	SkuNav:UpdateWpLinks(aName)
end

---------------------------------------------------------------------------------------------------------------------------------------
local GetNpcRolesCache = {}
function SkuNav:GetNpcRoles(aNpcName, aNpcId, aLocale)
	aLocale = aLocale or Sku.Loc
	if not aNpcId then
		for i, v in pairs(SkuDB.NpcData.Names[aLocale]) do
			if v[1] == aNpcName then
				aNpcId = i
				break
			end
		end
	end

	local tHasNoLocalizedData
	if not aNpcId then
		tHasNoLocalizedData = true
		for i, v in pairs(SkuDB.NpcData.Data) do
			if v[1] == aNpcName then
				aNpcId = i
				break
			end
		end
	end	

	if not GetNpcRolesCache[aLocale] then
		GetNpcRolesCache[aLocale] = {}
	end

	if GetNpcRolesCache[aLocale][aNpcId] then
		return GetNpcRolesCache[aLocale][aNpcId]
	end

	local rRoles = {}
	local tTempLocale = aLocale
	if tHasNoLocalizedData then
		tTempLocale = "enUS"
	end

	for i, v in pairs(SkuNav.NPCRolesToRecognize[tTempLocale]) do
		if SkuDB.NpcData.Data[aNpcId] then
			if bit.band(i, SkuDB.NpcData.Data[aNpcId][SkuDB.NpcData.Keys["npcFlags"]]) > 0 then
				rRoles[#rRoles+1] = v
			end
		end
	end

	GetNpcRolesCache[aLocale][aNpcId] = rRoles
	return rRoles
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:DeleteWaypoint(aWpName, aIsTempWaypoint)
	--print("DeleteWaypoint", aWpName, aIsTempWaypoint)
	local tWpData = SkuNav:GetWaypointData2(aWpName)
	local tWpId = WaypointCacheLookupCacheNameForId[aWpName]
	
	if not tWpData then
		return false
	end

	if tWpData.typeId ~= 1 then
		print("Only custom waypoints can be deleted")
		SkuNav:PlayFailSound()
		return false
	end


	local tCacheIndex = WaypointCacheLookupAll[aWpName] 
	if not SkuOptions.db.global[MODULE_NAME].Waypoints[tWpData.dbIndex] then
		print("Error: waypoint nil in db")
		SkuNav:PlayFailSound()
	else
		--remove from links db

		--remove links in linked wps in cache
		if tWpData.links.byId then
			for index, distance in pairs(tWpData.links.byId) do
				WaypointCache[index].links.byId[tCacheIndex] = nil
				WaypointCache[index].links.byName[aWpName] = nil
				--and in options links
				local tCacheLinksId = SkuNav:BuildWpIdFromData(WaypointCache[index].typeId, WaypointCache[index].dbIndex, WaypointCache[index].spawn, WaypointCache[index].areaId)
				local tLinksId = SkuNav:BuildWpIdFromData(WaypointCache[tCacheIndex].typeId, WaypointCache[tCacheIndex].dbIndex, WaypointCache[tCacheIndex].spawn, WaypointCache[tCacheIndex].areaId)
				SkuOptions.db.global[MODULE_NAME].Links[tCacheLinksId][tLinksId] = nil
			end
		end
		if tWpData.links.byName then
			for name, distance in pairs(tWpData.links.byName) do
				local tCacheLinksId = SkuNav:BuildWpIdFromData(WaypointCache[WaypointCacheLookupAll[name]].typeId, WaypointCache[WaypointCacheLookupAll[name]].dbIndex, WaypointCache[WaypointCacheLookupAll[name]].spawn, WaypointCache[WaypointCacheLookupAll[name]].areaId)
				local tLinksId = SkuNav:BuildWpIdFromData(WaypointCache[tCacheIndex].typeId, WaypointCache[tCacheIndex].dbIndex, WaypointCache[tCacheIndex].spawn, WaypointCache[tCacheIndex].areaId)
				
				SkuOptions.db.global[MODULE_NAME].Links[tCacheLinksId][tLinksId] = nil

				WaypointCache[WaypointCacheLookupAll[aWpName]].links.byId[tCacheIndex] = nil
				WaypointCache[WaypointCacheLookupAll[aWpName]].links.byName[aWpName] = nil

			end
		end

		WaypointCacheLookupIdForCacheIndex[SkuNav:BuildWpIdFromData(WaypointCache[tCacheIndex].typeId, WaypointCache[tCacheIndex].dbIndex, WaypointCache[tCacheIndex].spawn, WaypointCache[tCacheIndex].areaId)] = nil
		WaypointCacheLookupCacheNameForId[aWpName] = nil
		WaypointCacheLookupPerContintent[tWpData.contintentId][tCacheIndex] = nil
		WaypointCacheLookupAll[aWpName] = nil
		WaypointCache[tCacheIndex] = nil

		--delete from waypoint db
		SkuOptions.db.global[MODULE_NAME].Waypoints[tWpData.dbIndex] = {false}

		SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-notification15.mp3")
	end
	
	SkuNav:SaveLinkDataToProfile()

	return true
end

------------------------------------------------------------------------------------------------------------------------
--id bitfield: int64, bits 1-48 used
local dbIndexBits = 20 -- 1-20, max 1,048,576 entries for all waypoints from base1-3
local areaIdBits	= 18 -- 21-38, max 262,144 entries
local spawnBits	= 10 -- 39, 48, max 1,024 entries
--dbIndexBits is splitted
local base1 		= 0			--custom waypoints 1-199,999
local base2 		= 200000		--creatures 200,000-499,999
local base3 		= 500000		--objects 500,000-999,999

------------------------------------------------------------------------------------------------------------------------
function SkuNav:BuildWpIdFromData(typeId, dbIndex, spawn, areaId)
	areaId = areaId or 1
	local tSourceId

	local tBase
	if typeId == 1 then
		tBase = base1
	elseif typeId == 2 then
		tBase = base2
	elseif typeId == 3 then
		tBase = base3
	end

	local vspawnShifted = SkuU64lshift(spawn, dbIndexBits + areaIdBits)
	local vareaIdShifted = SkuU64lshift(areaId, dbIndexBits)
	
	tSourceId = dbIndex + tBase + vareaIdShifted + vspawnShifted
	
	return tSourceId
end

------------------------------------------------------------------------------------------------------------------------
function SkuNav:GetWpDataFromId(id)
	local typeId, dbIndex, spawn, areaId

	spawn = SkuU64rshift(id, dbIndexBits + areaIdBits)
	areaId = SkuU64rshift(id - SkuU64lshift(spawn, dbIndexBits + areaIdBits), dbIndexBits)
	dbIndex = id - SkuU64lshift(areaId, dbIndexBits) - SkuU64lshift(spawn, dbIndexBits + areaIdBits)

	if dbIndex < base2 then
		typeId = 1
	elseif dbIndex < base3 then
		typeId = 2
		dbIndex = dbIndex - base2
	else
		typeId = 3
		dbIndex = dbIndex - base3
	end	

	return typeId, dbIndex, spawn, areaId
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:OnCancelRecording()
	SkuNav:EndRouteRecording(SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp)
	SkuOptions.db.profile[MODULE_NAME].routeRecordingLastWp = nil

	SkuOptions.db.profile[MODULE_NAME].routeRecording = false
	SkuOptions.db.profile[MODULE_NAME].routeRecordingDelete = false

	SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-notification12.mp3")
	print("Recording/deleting stopped or canceled")
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:PlayFailSound()
	SkuNav:PlaySoundFile("Interface\\AddOns\\SkuMapper\\audio\\sound-glass1.mp3", true)
end

---------------------------------------------------------------------------------------------------------------------------------------
function SkuNav:PlaySoundFile(aFileName, aIsFail)
	if SkuOptions.db.profile[MODULE_NAME].enableSounds ~= false then
		PlaySoundFile(aFileName)
	end
end