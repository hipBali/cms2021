-- ****************************************
-- CMS2021 Car configurator V1.0
-- Copyright (C) 2026 h1p6al1
-- ****************************************

--
-- lua54 -e "require 'lar' require 'carconfig.main'" [cms=2018]
--

_VERSION = "1.0"

package.path=package.path ..';?.lua;?/init.lua;lar/?.lua;lar/?/init.lua;'
package.path=package.path ..'cms/?.lua;'

local lar = require 'lar'
local json = require 'json'
require 'common'
require 'loader'

local packageName = "cms.zip"

-- ****************************************
-- VCLUA init                         
-- ****************************************
VCL = require 'vcl.core'
VCL.TheApplication():Initialize()

local mainForm, componentsByPath, app = json2Form(json.decode(lar.unzip(packageName,"carconfig.json")))

app.mainForm.caption = app.mainForm.Caption.." ".._VERSION

-- ****************************************
-- includes and globals
-- ****************************************
local CMSVer = arg[#arg]:split("=")[2] or "2021"

local CMSpath = "c:\\Program Files (x86)\\Steam\\steamapps\\common\\Car Mechanic Simulator "..CMSVer
local CARpath = "Car Mechanic Simulator 2021_Data\\StreamingAssets\\Cars\\"
if CMSVer=="2018" then
	CARpath = "cms2018_Data\\StreamingAssets\\Cars\\"
end
local defaultCategory = "Generic V8 Engines"
local engines = json.decode(lar.unzip(packageName,"engines.json"))
local cars = {}
local carConfig = {}
local defaultPlaces = {"Auction","Barn","Junkyard","Salon"}

-- ****************************************
-- init
-- ****************************************
app.PathEdit.text = CMSpath

local function onSelectCar() end -- declare

local function cleanup()
	app.NameEdit.text = ""
	app.SwapListBox:Clear()
	app.EngineEdit.text = ""
	app.YearEdit.text = ""
	app.AuctionCB.checked = false
	app.BarnCB.checked = false
	app.JunkyardCB.checked = false
	app.SalonCB.checked = false
end

local function selectFirst()
	if app.CarListBox.Items:GetText():len() > 0 then
		app.NameEdit.text = app.CarListBox.Items:ValueFromIndex(0)
		app.CarListBox.ItemIndex = 0
		onSelectCar()
		app.CarListBox:SetFocus()
	end
end

---------------------------------------------
-- car config helpers                   -----
---------------------------------------------
local function loadConfigTable(dir)
	local cfg = {}
	local file, errorString = io.open( app.PathEdit.text.."\\"..CARpath..dir.."\\config.txt", "r" )
	if file then
		while 1 do
			local l = file:read('*l')
			if l then
				table.insert(cfg,l)
			else
				break
			end
		end
		io.close( file )
	end
	return cfg
end

local function getSectionIndex(cfg,section)
	for i,l in pairs(cfg) do
		if l and l:len()>0 then
			local cs = l:match("%[(.*)%]")
			if cs and cs==section then
				return i
			end
		end
	end
end

local function getConfigValue(cfg,key,section)
	for i,l in pairs(cfg) do
		if l and l:len()>0 then
			local elem = l:match(string.format("%s=(.*)",key))
			if section then
				local cs = l:match("%[(.*)%]")
				if cs then
					cSection = cs
				elseif cSection == section then
					if elem then
						return elem, i
					end
				end
			elseif elem then
				return elem, i
			end
		end
	end
end

local function swap2Name(swap)
	for cat in pairs(engines) do
		for code,name in pairs(engines[cat]) do
			if swap == code then
				return name
			end
		end
	end
	return swap
end

local function name2Swap(realName)
	for cat in pairs(engines) do
		for code,name in pairs(engines[cat]) do
			if realName == name then
				return code
			end
		end
	end
	return "* Unknown *"
end

---------------------------------------------
-- setup categories and engines         -----
---------------------------------------------
local carEngines = {}

app.CategoryCombo.text = defaultCategory
for cat in pairs(engines) do
	app.CategoryCombo.items:Add(cat)
end
local function onCategoryChange()
	local cat = app.CategoryCombo.text
	app.EngineOptionsList:Clear() 
	for code,name in pairs(engines[cat]) do
		app.EngineOptionsList.items:Add(name)
	end
end
app.CategoryCombo.onChange = onCategoryChange
onCategoryChange()

---------------------------------------------
-- car selected                            --
---------------------------------------------
app.NameEdit.text = ""
local function getCarName(dir)
	local realName = "* Missing data *"
	local file, errorString = io.open( app.PathEdit.text.."\\"..CARpath..dir.."\\name.txt", "r" )
	if errorString == nil then
		realName = file:read('*l')
		io.close( file )
	end
	return realName
end

local function showPlaces(places)
	app.AuctionCB.checked = places:find("Auction")
	app.BarnCB.checked = places:find("Barn")
	app.JunkyardCB.checked = places:find("Junkyard")
	app.SalonCB.checked = places:find("Salon")
end

onSelectCar = function()
	local dir = app.CarListBox:GetSelectedText()
	if dir and dir:len()>0 then
		carConfig = {dir=dir}
		carConfig.name = getCarName(dir)
		app.NameEdit.text = carConfig.name
		app.SwapListBox:Clear()
		local cfg = loadConfigTable(dir)
		carConfig.data = cfg
		app.EngineEdit.text = swap2Name(getConfigValue(cfg,"type","6_engine"))
		app.YearEdit.text = getConfigValue(cfg,"year")
		showPlaces(getConfigValue(cfg,"allowedPlaces"))
		local swaps = getConfigValue(cfg,"swapoptions")
		if swaps then
			swaps = swaps:split(",")
			for _,swap in pairs(swaps) do
				app.SwapListBox.items:Add(swap2Name(swap))
			end
		end
	end
end
app.CarListBox.onClick = onSelectCar

---------------------------------------------
-- Save changes                            --
---------------------------------------------
app.SaveNameButton.onClick = function()
	local s = app.NameEdit.text
	local oldName = carConfig.name
	
	local nameTxtFilename =  app.PathEdit.text.."\\"..CARpath..carConfig.dir.."\\config.txt"
	
	if s and s:len()>0 and oldName~=s then
		if VCL.MessageDlg(string.format("Rename '%s' to '%s'?\n\n",oldName,s),"mtConfirmation",{"mbYes","mbNo"})=="mrNo" then
			return nil
		end
		-- save original name.txt if not exists
		local origFile, errorString = io.open(nameTxtFilename..".ORIG", "r" )
		if not origFile then
			origFile, errorString = io.open(nameTxtFilename, "w" )
			origFile:write(oldName)
			io.close( origFile )
		else
			io.close( origFile )
		end
		local file, errorString = io.open( nameTxtFilename, "w" )
		file:write(s)
		io.close( file )
		carConfig.name = s
	end
end

app.SaveButton.onClick = function()
	local cfg = carConfig.data
	local cfgFilename =  app.PathEdit.text.."\\"..CARpath..carConfig.dir.."\\config.txt"
	
	if VCL.MessageDlg(string.format("Update '%s'´s config?\n\n",carConfig.name),"mtConfirmation",{"mbYes","mbNo"})=="mrNo" then
		return nil
	end
	-- save backup
	local backFile, errorString = io.open(cfgFilename..".BACKUP", "w" )
	backFile:write(table.concat(cfg,"\n"))
	io.close( backFile )
	
	-- ** SWAP **
	-- find section and key
	local secIndex = getSectionIndex(cfg,"6_engine")
	local swaps,swapIndex = getConfigValue(cfg,"swapoptions")
	local list = app.SwapListBox.items:ToStringArray2()
	local swaps = {}
	for _,name in pairs(list) do
		table.insert(swaps, name2Swap(name))
	end
	local str = "swapoptions="..table.concat(swaps,",")
	if swapIndex then
		cfg[swapIndex] = str
	elseif secIndex then
		table.insert(cfg,secIndex+1,str)
	end
	
	-- ** PLACES **
	local newplcs = {}
	local plcs, plcpos = getConfigValue(cfg,"allowedPlaces")
	-- copy orders etc.
	for n,p in pairs(plcs:split(",")) do
		local cb = app[p.."CB"]
		if not cb then
			table.insert(newplcs,p)
		end
	end
	-- filter places
	for n,p in pairs(defaultPlaces) do
		local cb = app[p.."CB"]
		if cb and cb.checked then
			table.insert(newplcs,p)
		end
	end
	str = "allowedPlaces="..table.concat(newplcs,",")
	if plcpos then
		cfg[plcpos] = str
	else
		print("** Original 'swapoptions' not found! **")
	end
	
	-- save new config.txt
	local file, errorString = io.open(cfgFilename, "w" )
	file:write(table.concat(cfg,"\n"))
	io.close( file )
end

app.RemoveButton.onClick = function()
	local idx = app.SwapListBox.ItemIndex
	if idx >= 0 then
		app.SwapListBox.Items:Delete(idx)
	end
end	

app.AddButton.onClick = function()
	local idx = app.EngineOptionsList.ItemIndex
	if idx >= 0 then
		local ex = app.EngineOptionsList.Items:ValueFromIndex(idx)
		-- add if not exists
		local trg = app.SwapListBox.Items:IndexOf(ex)
		if trg == -1 then
			if not carEngines[name2Swap(ex)] then
				if VCL.MessageDlg(string.format("The engine '%s' is not assigned to any car, continue?\n\n",ex),"mtConfirmation",{"mbYes","mbNo"})=="mrNo" then
					return nil
				end
			end
			app.SwapListBox.Items:Add(ex)
		end
	end
end

---------------------------------------------
-- setup working directory and cars list ----
---------------------------------------------
app.CategoryCombo.text = defaultCategory
for cat in pairs(engines) do
	app.CategoryCombo.items:Add(cat)
end
local function onPathChange()
	local path = app.PathEdit.text.."\\"..CARpath
	app.CarListBox:Clear()
	cleanup()
	carEngines = {}
	for dir in io.popen(string.format([[dir "%s" /b]],path)):lines() do 
		app.CarListBox.items:Add(dir) 
		local cfg = loadConfigTable(dir)
		carEngines[getConfigValue(cfg,"type","6_engine")] = 1
	end
	if mainForm.visible then
		selectFirst()
	end
end
app.PathEdit.onChange = onPathChange
onPathChange()
---------------------------------------------
-- Startup                                 --
---------------------------------------------
mainForm.onActivate = function()
	selectFirst()
	mainForm.onActivate = nil
end
mainForm:ShowModal()

