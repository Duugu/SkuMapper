local MODULE_NAME = "SkuNav"
local L = Sku.L

SkuNav.options = {
	name = MODULE_NAME,
	type = "group",
	args = {
		showGatherWaypoints = {
			order = 16,
			name = L["Show herbs and mining node waypoints"],
			desc = "",
			type = "toggle",
			set = function(info,val)
				SkuOptions.db.profile[MODULE_NAME].showGatherWaypoints = val
			end,
			get = function(info)
				return SkuOptions.db.profile[MODULE_NAME].showGatherWaypoints
			end
		},	
		showRoutesOnMinimap = {
			order = 17,
			name = L["Show routes on minimap"],
			desc = "",
			type = "toggle",
			set = function(info,val)
				SkuOptions.db.profile[MODULE_NAME].showRoutesOnMinimap = val
			end,
			get = function(info)
				return SkuOptions.db.profile[MODULE_NAME].showRoutesOnMinimap
			end
		},
		showSkuMM = {
			order = 18,
			name = L["Show extra minimap"],
			desc = "",
			type = "toggle",
			set = function(info,val)
				SkuOptions.db.profile[MODULE_NAME].showSkuMM = val
			end,
			get = function(info)
				return SkuOptions.db.profile[MODULE_NAME].showSkuMM
			end
		},
	},
}
---------------------------------------------------------------------------------------------------------------------------------------
SkuNav.defaults = {
	showRoutesOnMinimap = false,
	showSkuMM = false,
	showGatherWaypoints = false,
}

