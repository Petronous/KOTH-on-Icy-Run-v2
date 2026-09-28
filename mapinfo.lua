--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- mapinfo.lua
--

local mapinfo = {
	name        = "KOTH Icy Run",
	shortname   = "KOTH Icy Run",
	description = "A king-of-the-hill map modification of Icy Run v2. Score counts up for every captured mex in the 'hill' area, and the side that reaches maximum first wins.",
	author      = "Perrold",
	version     = "0.1.1",
	--mutator   = "deployment",
	mapfile     = "maps/KOTH Icy Run.smf",
	modtype     = 3, --// 1=primary, 0=hidden, 3=map
	depend      = {},
	replace     = {},

	--startpic   = "", --// deprecated
	--StartMusic = "", --// deprecated

	maphardness     = 100,
	notDeformable   = false,
	gravity         = 120,
	tidalStrength   = 0,
	maxMetal        = 1.351,
	extractorRadius = 100,
	voidWater       = false,
	autoShowMetal   = true,


	smf = {
		-- minheight = -105,
		-- maxheight = 360,
		--grassmaptex = "wanderlust_grass.png";
		smtFileName0 = "maps/KOTH Icy Run.smt",
		--smtFileName1 = "",
		--smtFileName.. = "",
		--smtFileNameN = "",
		--minimapTex = "minimap.png",
	},

	-- resources = {
	-- 	--grassBladeTex    	= "grassbladetex.tga",
	-- 	detailTex = "detailtexblurred.bmp",
	-- 	specularTex = "titanduelspec.png",
	-- 	splatDetailTex = "splattex.tga",
	-- 	splatDistrTex = "titandueldist.png",
	-- 	splatDetailNormalDiffuseAlpha = 1,
	-- 	splatDetailNormalTex1 = "earth_NORM.tga";
	-- 	splatDetailNormalTex2 = "pebbles_49_highpass_dnts.tga";
	-- 	splatDetailNormalTex3 = "rock_46_highpass_dnts.tga";
	-- 	splatDetailNormalTex4 = "crystal_245_highpass_dnts.tga";
	-- },

	-- splats = {
	-- 	TexScales		=	{ 0.005, 0.004, 0.006, 0.008 },
	-- 	TexMults		=	{ 0.77, 0.7, 0.65, 0.8 },
	-- },

	atmosphere = {

		minWind      = 14,
		maxWind      = 27,

		fogStart     = 0.3,
		fogEnd       = 1.2,
		fogColor     = {0.75, 0.7, 0.65},

		sunColor     = {0.7, 0.7, 1},
		skycolor     = {0, 0, 0.3},
		skyDir       = {0.0, 0.0, -1.0},
		-- skyBox		 = "spacey.dds",

		cloudDensity = 0.5,
		cloudColor   = {0.2, 0.2, 0.5},
	},

	lighting = {
		--// dynsun
		sunStartAngle = 0.0,
		sunOrbitTime  = 1440.0,
		sundir        = {0.383, 0.573, 0.188},

		--// unit & ground lighting
         groundambientcolor            = {0.4, 0.6, 0.5},
         grounddiffusecolor            = {0.6, 0.4, 0.5},
         groundshadowdensity           = 1.0,
         unitambientcolor           = {0.5, 0.5, 0.8},
         unitdiffusecolor           = { 0.8, 0.8, 0.8 },
         unitshadowdensity          = 0.7,
		 specularsuncolor           = { 1, 0.9, 0.9  },
		 
		specularExponent    = 100.0,
	},
	
	water = {
		absorb    = { 1.0, 0.5, 0.0 },
		basecolor = { 0.4, 0.78, 0.3 },
		mincolor  = { 0.3, 0.56, 0.43 },
		
	
		surfacecolor  = { 0.45, 0.8, 0.45 },
		planeColor = {0.02, 0.05, 0.01},
	},
	

	teams = {
		[0] = {startPos = {x = 522, z = 399}},
		[1] = {startPos = {x = 4628, z = 4618}},
		[2] = {startPos = {x = 1280, z = 389}},
		[3] = {startPos = {x = 3994, z = 4751}},
		[4] = {startPos = {x = 328, z = 901}},
		[5] = {startPos = {x = 4915, z = 4035}},
	},
	
	terrainTypes = {
		[0] = {
			name = "Snow",
			hardness = 5,
			receiveTracks = true,
			moveSpeeds = {
				tank  = 1.0,
				kbot  = 1.0,
				hover = 2.0,
				ship  = 1.0,
			},
		},
		[1] = {
			name = "Mountain",
			hardness = 25,
			receiveTracks = true,
			moveSpeeds = {
				tank  = 1.0,
				kbot  = 1.0,
				hover = 1.0,
				ship  = 1.0,
			},
		},
	},

	custom = {
		fog = {
			color     = {0.75, 0.7, 0.65},
			height   = "40%", --// allows either absolue sizes or in percent of map's MaxHeight
			fogatten = 0.0075,
		},
		precipitation = {
			density   = 30000,
			size      = 1.0,
			speed     = 200,
			windscale = -1.0,
			texture   = 'LuaUI/effects/snowflake.tga',
		},
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper

local function lowerkeys(ta)
	local fix = {}
	for i,v in pairs(ta) do
		if (type(i) == "string") then
			if (i ~= i:lower()) then
				fix[#fix+1] = i
			end
		end
		if (type(v) == "table") then
			lowerkeys(v)
		end
	end
	
	for i=1,#fix do
		local idx = fix[i]
		ta[idx:lower()] = ta[idx]
		ta[idx] = nil
	end
end

lowerkeys(mapinfo)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Map Options

do
	local function tmerge(t1, t2)
		for i,v in pairs(t2) do
			if (type(v) == "table") then
				t1[i] = t1[i] or {}
				tmerge(t1[i], v)
			else
				t1[i] = v
			end
		end
	end

	getfenv()["mapinfo"] = mapinfo
		local files = VFS.DirList("mapconfig/mapinfo/", "*.lua")
		table.sort(files)
		for i=1,#files do
			local newcfg = VFS.Include(files[i])
			if newcfg then
				lowerkeys(newcfg)
				tmerge(mapinfo, newcfg)
			end
		end
	getfenv()["mapinfo"] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return mapinfo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
