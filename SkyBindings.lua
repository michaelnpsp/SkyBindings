-- Skyriding Keybinds for Midnight

local addonName, addon = ...

local SPELLS = {
	372608, -- Surge Forward
	372610, -- Skyward Ascent
	361584, -- Whirling Surge
	425782, -- Second Wind
	403092, -- Aerial Halt
}

local DRIVER = [[if newstate == "on" then
  --<
  -->
elseif newstate == "off" then
  self:ClearBindings()
end]]

function addon:Init(frame)
	-- settings database
	local keyDB = addonName .. 'DB'
	_G[keyDB] = type(_G[keyDB])=='table' and _G[keyDB] or {}
	self.db = _G[keyDB]
	-- create skyriding driver frame handler
	if frame then
		self.frame = frame
		RegisterAttributeDriver(self.frame, "state-skyriding", '[bonusbar:5,flying] on;off')
	end
	-- create vehicleui driver frame handler
	if self.db.vehicle then
		self.frameV = CreateFrame("Frame", "SkyBindingsDriverFrameVehicle", nil, "SecureHandlerStateTemplate")
		RegisterAttributeDriver(self.frameV, "state-vehicleui", '[vehicleui][possessbar][overridebar] on;off')
	end
	-- command line options
	SLASH_SKYBINDINGS1, SLASH_SKYBINDINGS2, SLASH_SKYBINDINGS3 = "/skybind", "/skybinds", "/skybindings"
	SlashCmdList.SKYBINDINGS = function(args) addon:Command(args) end
	-- remove method
	self.Init = nil
end

function addon:Reset()
	DRIVER = gsub( DRIVER, "--<.*-->","--<\n-->" )
end

function addon:Bind(bind)
	DRIVER = gsub( DRIVER, "-->", bind..'\n-->' )
end

function addon:Apply(frame, state)
	frame:SetAttribute("_on"..state, DRIVER)
end

function addon:LoadSkyriding()
	if self.frame then
		self:Reset()
		for idx,key in ipairs(self.db) do
			self:Bind( string.format('self:SetBindingSpell(true,"%s","%s")', key, C_Spell.GetSpellName(SPELLS[idx]) or '') )
		end
		self:Apply(self.frame, "state-skyriding")
	end
end

function addon:LoadVehicle()
	if self.frameV then
		self:Reset()
		for idx,key in ipairs(self.db) do
			self:Bind( string.format('self:SetBindingClick(true,"%s","OverrideActionBarButton%d")', key, idx) )
		end
		self:Apply(self.frameV, "state-vehicleui")
	end
end

function addon:Load()
	if #self.db>0 then
		self:LoadSkyriding()
		self:LoadVehicle()
	end
end

function addon:Save(keys)
	for idx, key in ipairs(keys) do
		self.db[idx] = key
	end
end

function addon:Command(args)
	local args = strupper(strtrim(args))
	if args==nil or args=='' or args=='HELP' then
		self:Help( args=='HELP' )
	elseif args=="VEHICLE" then
		self.db.vehicle = (not self.db.vehicle) or nil
		print( string.format('Skybinding vehicle "%s": A Reload UI is required!', self.db.vehicle and "enabled" or "disabled") )
	else
		self:Save( {strsplit(" ,", args, 5)} )
		self:Load()
		self:Help()
	end
end

function addon:Help(extra)
	print("\n")
	print("SkyBindings addon:")
	print("    Keybinding for skyriding abilities, type '/skybinds help' for more info.")
	print("Current keybinds:")
	if #self.db>0 then
		for idx, spellID in ipairs(SPELLS) do
			local key = self.db[idx]
			local name = C_Spell.GetSpellName(spellID)
			print( string.format('    "%s" : %s', key or 'NONE', name or 'ERROR' ) )
		end
		if self.db.vehicle then
			print("    Keybinds are enabled for the vehicle UI too.")
		end
	else
		print("  No keybinds configured.")
	end
	if extra then
		print("Commands:")
		print("  /skybinds vehicle")
		print("      Toggle use of the keybinds for the vehicle UI.")
		print("  /skybinds key1 key2 key3 key4 key5")
		for idx, spellID in ipairs(SPELLS) do
			print( string.format('      key%d: bind for "%s"', idx, C_Spell.GetSpellName(spellID)) )
		end
		print("  Examples:")
		print("      /skybinds 1 2 3 MOUSE4 MOUSE5")
		print("      /skybinds A S D F G")
	end
end

function addon:Run(frame)
	self:Init(frame)
	self:Load()
end

-- Boot
local frame = CreateFrame("Frame", "SkyBindingsDriverFrame", nil, "SecureHandlerStateTemplate")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(frame, event, name)
	if event == "ADDON_LOADED" and name == addonName then
		frame:SetScript("OnEvent", nil)
		addon:Run(frame)
	end
end)
_G[addonName] = addon
