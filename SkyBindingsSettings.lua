local addonName, addon = ...

-- command line options

function addon:Command(args)
	local args = strupper(strtrim(args))
	if args==nil or args=='' or args=='HELP' then
		if arg==nil then
			self:OpenSettings()
		end
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
		for idx, spellID in ipairs(self.SPELLS) do
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
		for idx, spellID in ipairs(self.SPELLS) do
			print( string.format('      key%d: bind for "%s"', idx, C_Spell.GetSpellName(spellID)) )
		end
		print("  Examples:")
		print("      /skybinds 1 2 3 MOUSE4 MOUSE5")
		print("      /skybinds A S D F G")
	end
end

-- blizzard settings panel

do
	local invalidKeys = {
		ESCAPE = true,
		LeftButton = true,
		MiddleButton = true,
		MOUSE1 = true,
		MOUSE2 = true,
		MOUSE3 = true,
		LSHIFT = true,
		RSHIFT = true,
		LCTRL = true,
		RCTRL = true,
		LALT = true,
		RALT = true,
	}
	local frameBind = CreateFrame("Frame", nil, UIParent)
	frameBind:Hide()
	frameBind:SetFrameStrata("TOOLTIP")
	frameBind:SetFrameLevel(500)
	frameBind:SetAllPoints()
	frameBind:EnableMouse(true)
	frameBind:EnableKeyboard(true)
	function addon:CreateBindSetting(category, layout, idx)
		local function GetName()
			return (idx==frameBind.idx and ">>> Assign Binding <<<") or self.db[idx] or "Not Bound"
		end
		local function Refresh()
			SettingsPanel:Hide()
			Settings.OpenToCategory(category:GetID())
		end
		local function SetBinding(_, key)
			frameBind.idx = nil
			frameBind:Hide()
			if not invalidKeys[key] then
				self.db[idx] = key~='RightButton' and key or nil
				self:Load()
			end
			Refresh()
		end
		local function WaitBinding()
			frameBind.idx = idx
			frameBind:SetScript("OnMouseDown",SetBinding)
			frameBind:SetScript("OnKeyDown", SetBinding)
			frameBind:Show()
			Refresh()
		end
		local label = C_Spell.GetSpellName(self.SPELLS[idx])
		if self.db.vehicle then
			label = string.format("Button%d / %s", idx, label)
		end
		local button = CreateSettingsButtonInitializer(
			label,
			GetName,
			WaitBinding,
			"Click to start binding mode.\nEscape to exit binding mode.\nRight-Click to unbind current key.",
			false
		)
		layout:AddInitializer(button)
	end
end

function addon:CreateCheckSetting(cat, key, nam, des, def, get, set)
	local set = Settings.RegisterProxySetting( cat, key,
		type(def),
		nam,
		def,
		function() return get(key) end,
		function(val) set(key, val) end
	)
	Settings.CreateCheckbox(cat, set, des)
end

function addon:OpenSettings()
	Settings.OpenToCategory(self.category:GetID())
end

-- init settings

function addon:InitSettings()
	-- command line options
	SLASH_SKYBINDINGS1, SLASH_SKYBINDINGS2, SLASH_SKYBINDINGS3 = "/skybind", "/skybinds", "/skybindings"
	SlashCmdList.SKYBINDINGS = function(args) self:Command(args) end
	-- settings panel
	local cat, lay = Settings.RegisterVerticalLayoutCategory(addonName)
	self.category = cat
	self:CreateBindSetting( cat, lay, 1 )
	self:CreateBindSetting( cat, lay, 2 )
	self:CreateBindSetting( cat, lay, 3 )
	self:CreateBindSetting( cat, lay, 4 )
	self:CreateBindSetting( cat, lay, 5 )
	self:CreateCheckSetting( cat, "SKYBINDINGS_VEHICLE",
		"Enabled for vehicles",
		"Check this option to use these bindings when you are controlling a vehicle or another npc.\nA UI reload is required.",
		true,
		function() return self.db.vehicle end,
		function(_, val) self.db.vehicle = val or nil; end
	)
	Settings.RegisterAddOnCategory(cat)
	self.InitSettings = nil
end
