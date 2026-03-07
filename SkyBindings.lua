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
	-- create driver frame
	self.frame = frame
	RegisterAttributeDriver(self.frame, "state-skyriding", '[bonusbar:5,flying] on;off')
	-- command line options
	SLASH_SKYBINDINGS1, SLASH_SKYBINDINGS2, SLASH_SKYBINDINGS3 = "/skybind", "/skybinds", "/skybindings"
	SlashCmdList.SKYBINDINGS = function(args) addon:Command(args) end
	-- remove method
	self.Init = nil
end

function addon:Command(args)
	local args = strupper(strtrim(args))
	if args==nil or args=='' or args=='HELP' then
		self:Help( args=='HELP' )
	else
		self:Save( {strsplit(" ,", args, 5)} )
	end
end

function addon:Help(extra)
	print("SkyBindings addon:")
	print("  Configure key binds for Skyriding abilities.")
	print("Current keybinds:")
	if #self.db>0 then
		for idx, spellID in ipairs(SPELLS) do
			local key = self.db[idx]
			local name = C_Spell.GetSpellName(spellID)
			print( string.format('  "%s" : %s', key or 'NONE', name or 'ERROR' ) )
		end
	else
		print("  No bindings configured.")
	end
	print("Commands:")
	print("  /skybinds help")
	print("  /skybinds Key1 Key2 Key3 Key4 Key5")
	if extra then
		for idx, spellID in ipairs(SPELLS) do
			print( string.format('    Key%d: bind for "%s"', idx, C_Spell.GetSpellName(spellID)) )
		end
		print("  Examples:")
		print("    /skybinds 1 2 3 MOUSE4 MOUSE5")
		print("    /skybinds A S D F G")
	end
end

function addon:Reset()
	DRIVER = gsub( DRIVER, "--<.*-->","--<\n-->" )
end

function addon:Bind(key, spellID, pri)
	DRIVER = gsub( DRIVER, "-->", string.format('self:SetBindingSpell(true,"%s","%s")\n-->', key, C_Spell.GetSpellName(spellID) or '') )
end

function addon:Apply()
	self.frame:SetAttribute("_onstate-skyriding", DRIVER)
end

function addon:Load()
	if #self.db>0 then
		self:Reset()
		for idx,key in ipairs(self.db) do
			self:Bind( key, SPELLS[idx] )
		end
		self:Apply()
	end
end

function addon:Save(keys)
	for idx, key in ipairs(keys) do
		self.db[idx] = key
	end
	self:Load()
	self:Help(true)
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
