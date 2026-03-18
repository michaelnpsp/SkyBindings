-- Skyriding Keybinds for Midnight

local addonName, addon = ...

addon.SPELLS = {
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
	-- command line & settings panel
	self:InitSettings()
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
			self:Bind( string.format('self:SetBindingSpell(true,"%s","%s")', key, C_Spell.GetSpellName(self.SPELLS[idx]) or '') )
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

function addon:Run(frame)
	self:Init(frame)
	self:Load()
end

-- Boot
local frame = CreateFrame("Frame", "SkyBindingsDriverFrame", nil, "SecureHandlerStateTemplate")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(frame, event, name)
	if name == addonName then
		frame:SetScript("OnEvent", nil)
		addon:Run(frame)
	end
end)
_G[addonName] = addon
