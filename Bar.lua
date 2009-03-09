﻿local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local LSM = LibStub("LibSharedMedia-3.0")
local Bar = ChocolateBar.Bar
local chocolate = ChocolateBar.ChocolatePiece
local Debug = ChocolateBar.Debug
local jostle = LibStub("LibJostle-3.0-mod")

function Bar:New(name, settings)
	local frame = CreateFrame("Frame",name,UIParent)
	frame.chocolist = {} --create list of chocolate chocolist in the bar
	
	-- add class methods to frame object
	for k, v in pairs(Bar) do
		frame[k] = v
	end
	
	frame:SetHeight(21)
	frame:SetPoint("TOPLEFT",-1,1);
	--frame:SetPoint("TOPLEFT", settings.xoff, settings.yoff);
	frame:SetPoint("RIGHT", "UIParent" ,"RIGHT",0, 0);
	
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", function(self) 
		Debug("OnEnter", self:GetName())
		--self:SetAlpha(1)
		self:ShowAll()
	end)
	--frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnLeave", function(self) 
		if self.autohide then
			--self:SetAlpha(0)
			self:HideAll()
		end
	end)
	
	frame:SetScript("OnMouseUp", function() 
		if arg1 == "RightButton" then
			LibStub("AceConfigDialog-3.0"):Open("ChocolateBar")
		end
	end)
	
	frame.settings = settings
	frame.autohide = settings.hideonleave

	frame:UpdateTexture()
	frame:UpdateColors()
	frame:UpdateScale()
	frame:UpdateAutoHide()
	
	return frame
end

function Bar:UpdateAutoHide() 
	if self.settings.autohide then
		self.autohide = true
		self:HideAll()
		jostle:Unregister(self)
	else
		self.autohide = false
		self:ShowAll()
		jostle:Unregister(self)
		if ChocolateBar.db.profile.moveFrames then
			if self.settings.align == "bottom" then
				jostle:RegisterBottom(self)
			else
				jostle:RegisterTop(self)
			end
		end
	end
end

function Bar:UpdateScale()
	self.scale = ChocolateBar.db.profile.scale
	self:SetScale(self.scale)
end

function Bar:UpdateColors()
	local bg = ChocolateBar.db.profile.background
	local color = bg.borderColor
	self:SetBackdropBorderColor(color.r,color.g,color.b,color.a)
	color = bg.color
	self:SetBackdropColor(color.r,color.g,color.b,color.a)
end

function Bar:UpdateTexture()
	local background = LSM:Fetch("statusbar", ChocolateBar.db.profile.background.texture)
	local bg = {
		bgFile = background, 
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = false, tileSize = 16, edgeSize = 12, 
		--insets = { left = 4, right = 4, top = 4, bottom = 4}
		insets = { left = 0, right = 0, top = 0, bottom = 0}
	}
	bg.bgFile = background
	self:SetBackdrop(bg);
end

local function updateDummy(self, choco, name)
	local dummy = self.dummy
	if not dummy then  
		dummy = CreateFrame("Frame", "ChocolateDummy", self)
		--dummy:SetAllPoints(chocolate.frame)
		dummy.name = "dummy"
		dummy:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = true, tileSize = 16, edgeSize = 6, 
		insets = { left = 0, right = 0, top = 0, bottom = 0}})
		dummy:SetBackdropColor(1,0,0,1)
		dummy:SetBackdropBorderColor(1,0,0,0)
		self.dummy = dummy
	end
	dummy:Show()
	dummy:SetWidth(choco:GetWidth())
	dummy:SetHeight(choco:GetHeight())
	
	local settings = {}
	settings.index = choco.settings.index
	dummy.settings = settings
	dummy.settings.align = choco.settings.align
	templeftchocolate = self.chocolist[name]
	self.saved = choco
	self.chocolist[name] = dummy
end

function GetTexture(frame)
	Debug(frame:GetName())
	regions = frame:GetRegions()
end

-- add some chocolate to a bar
function Bar:AddChocolatePiece(choco, name,noupdate)
	local chocolist = self.chocolist
	if chocolist[name] then
		return
	end
	
	chocolist[name] = choco
	choco:SetParent(self)
	choco.bar = self
	
	local settings = choco.settings
	settings.barName = self:GetName() 
	if not settings.index then
		settings.index = 1
	end
	if not noupdate then
		self:UpdateBar()
	end
end

-- eat some chocolate from a ChocolateBar
function Bar:EatChocolatePiece(name)
	self.chocolist = self.chocolist or {}
	local choco = self.chocolist[name]
	
	if choco then
		choco:Hide()
		self.chocolist[name] = nil
		self:UpdateBar()
	end
end

function Bar:HideAll()
	self:SetAlpha(0)
	for k, v in pairs(self.chocolist) do
		v:Hide()
	end
end

function Bar:ShowAll()
	self:SetAlpha(1)
	for k, v in pairs(self.chocolist) do
		v:Show()
	end
end

function Bar:Disable()
	self:Hide()
	jostle:Unregister(self)
end

function Bar:Drop(choco, pos)
	Debug("Bar:Drop", choco.name, pos)
	self.dummy:Hide()
	self.chocolist[choco.obj.name] = choco
	Debug("frame:GetWidth() ", choco:GetWidth())
	choco.settings.index = self.dummy.settings.index
	choco.settings.align = self.dummy.settings.align
	self:UpdateBar(true)
end

function Bar:LoseFocus(name)
	self.dummy:Hide()
	self.chocolist[name] = nil
	self:UpdateBar(true)
end

function Bar:GetChocolateAtCursor()
	local s = self:GetEffectiveScale()
	local x, y = GetCursorPosition()
	local align
	if x < 50 then
		align = "left"
	end
	if x > 850 then
		align =  "right"
	end
	
	x = x/s
	for k, v in pairs(self.chocolist) do
		if x > v:GetLeft() and x < v:GetRight() then
			return v, align
		end
	end
	return nil, align
end

function Bar:UpdateDragChocolate()
	local choco, align = self:GetChocolateAtCursor()
	if self.dummy.settings.align ~= align then
		if align == "left"  then
			self.dummy.settings.index = -1
			self.dummy.settings.align = "left"
		end
		if align == "right" then
			self.dummy.settings.index = -1
			self.dummy.settings.align = "right"
		end
		if align == "center" then
			self.dummy.settings.index = -1
			self.dummy.settings.align = "center"
		end
	end
	if not choco then 
		--Debug("Bar:UpdateDragChocolate(pos) cursour above: nil")
		self.dummy.settings.index = 500
		self:UpdateBar()
	else
		--Debug("cursour above: ",choco.name)
		if self.last ~= choco then
			self.last = choco
			self.dummy.settings.index = choco.settings.index - 0.5
			self.dummy.settings.align = choco.settings.align
			self:UpdateBar()
		end
	end
end

function Bar:GetFocus(name)
	local choco = ChocolateBar:GetChocolate(name)
	--choco.bar:EatChocolate()
	--self:AddChocolatePiece(choco, name)
	choco.bar = self
	choco.settings.barName = self:GetName()
	updateDummy(self, choco, name)
	self:UpdateBar()
end

function Bar:Drag(name)
	local choco = self.chocolist[name]
	if not choco then 
		if self.saved then
			--if self.saved.name == name then
				choco = self.saved	
		end
	end
	updateDummy(self, choco, name)
	self:UpdateBar()
end

local templeft = {}
local tempright = {}
local tempcenter = {}
local function SortTab(tab)
	templeft = {}
	tempright = {}
	tempcenter = {}
	
	for k,v in pairs(tab) do
		local index = v["settings"]["index"]
		if not index then
			index = 500
		end
		if v.settings.align == "left" then
			table.insert(templeft,{v,index})
		elseif v.settings.align == "center" then
			table.insert(tempcenter,{v,index})
		else
			table.insert(tempright,{v,index})
		end
	end
	table.sort(templeft, function(a,b)return a[2] < b[2] end)
	table.sort(tempcenter, function(a,b)return a[2] < b[2] end)
	table.sort(tempright, function(a,b)return a[2] < b[2] end)
	return templeft, tempcenter, tempright
end

-- rearange all chocolate chocolist in a given bar
-- called when chocolates are added, removed, moved
function Bar:UpdateBar(updateindex)
	local chocolates =  self.chocolist
	templeft, tempcenter ,tempright = SortTab(chocolates)
	
	local yoff = 0
	local relative = nil
	for i, v in ipairs(templeft) do
		local choco = v[1]
		choco:ClearAllPoints()
		if(relative)then
			choco:SetPoint("TOPLEFT",relative,"TOPRIGHT", 0,0)
		else
			choco:SetPoint("TOPLEFT",self, 6,yoff)
		end
		if updateindex then
			choco.settings.index = i
		end
		relative = choco
	end
	
	local relative = nil
	for i, v in ipairs(tempcenter) do
		local choco = v[1]
		choco:ClearAllPoints()
		if(relative)then
			choco:SetPoint("TOPRIGHT",relative,"TOPLEFT", 0,0)
		else
			choco:SetPoint("CENTER",self, 6,yoff)
		end
		if updateindex then
			choco.settings.index = i
		end
		relative = choco
	end
	
	relative = nil
	for i, v in ipairs(tempright) do
		local choco = v[1]
		choco:ClearAllPoints()
		if(relative)then
			choco:SetPoint("TOPRIGHT",relative,"TOPLEFT", 0,0)
			--list them downwards
			--chocolates[k]:SetPoint("TOPLEFT",relative,"BOTTOMLEFT", 0,-yoffset)
		else
			choco:SetPoint("TOPRIGHT",self, 6,yoff)
		end
		if updateindex then
			choco.settings.index = i
		end
		relative = choco
	end
end
