-- @docclass
UIMiniWindow = extends(UIWindow, "UIMiniWindow")

function UIMiniWindow.create()
  local miniwindow = UIMiniWindow.internalCreate()
  miniwindow.UIMiniWindowContainer = true
  return miniwindow
end

function UIMiniWindow:open(dontSave)
  self:setVisible(true)

  if not dontSave then
    self:setSettings({closed = false})
  end

  -- white border flash effect
  self:setBorderWidth(2)
  self:setBorderColor('#FFFFFF')
  scheduleEvent(function()
    self:setBorderWidth(0)
  end, 300)
  if not self:isDraggable() then
    scheduleEvent(function()
      self:setBorderWidth(2)
      self:setBorderColor('#FF5900')
    end, 500)
  end

  signalcall(self.onOpen, self)
end

function UIMiniWindow:close(dontSave)
  if not self:isExplicitlyVisible() then return end
  if self.forceOpen then return end
  self:setVisible(false)

  if not dontSave then
    self:setSettings({closed = true})
  end

  signalcall(self.onClose, self)
end

function UIMiniWindow:minimize(dontSave)
  self:setOn(true)
  self:getChildById('contentsPanel'):hide()
  self:getChildById('miniwindowScrollBar'):hide()
  self:getChildById('bottomResizeBorder'):hide()
  if self.minimizeButton then
    self.minimizeButton:setOn(true)
  end
  self:setHeight(self.minimizedHeight)

  if not dontSave then
    self:setSettings({minimized = true})
  end

  signalcall(self.onMinimize, self)
end

function UIMiniWindow:maximize(dontSave)
  self:setOn(false)
  if self:getChildById('contentsPanel') then self:getChildById('contentsPanel'):show() end
  if self:getChildById('miniwindowScrollBar') then self:getChildById('miniwindowScrollBar'):show() end
  if self:getChildById('bottomResizeBorder') then self:getChildById('bottomResizeBorder'):show() end
  if self.minimizeButton then
    self.minimizeButton:setOn(false)
  end
  self:setHeight(self:getSettings('height') or self.maximizedHeight)

  if not dontSave then
    self:setSettings({minimized = false})
  end

  local parent = self:getParent()
  if parent and parent:getClassName() == 'UIMiniWindowContainer' then
    parent:fitAll(self)
  end

  signalcall(self.onMaximize, self)
end

function UIMiniWindow:lock(dontSave)
  local lockButton = self:getChildById('lockButton')
  if lockButton then
    lockButton:setOn(true)
  end
  self:setDraggable(false)
  self:setBorderWidth(2)
  self:setBorderColor('#FF5900')
  if not dontSave then
    self:setSettings({locked = true})
  end

  signalcall(self.onLockChange, self)
end

function UIMiniWindow:unlock(dontSave)
  local lockButton = self:getChildById('lockButton')
  if lockButton then
    lockButton:setOn(false)
  end
  self:setDraggable(true)
  self:setBorderWidth(0)
  if not dontSave then
    self:setSettings({locked = false})
  end
  signalcall(self.onLockChange, self)
end

function UIMiniWindow:setup()
  self.maximizedHeight = self:getHeight()
  self:getChildById('closeButton').onClick =
    function()
      self:close()
    end
  if self.forceOpen then
      if self.closeButton then
        self.closeButton:hide()
      end
  end

  if(self.minimizeButton) then
    self.minimizeButton.onClick =
      function()
        if self:isOn() then
          self:maximize()
        else
          self:minimize()
        end
      end
  end
  
  local lockButton = self:getChildById('lockButton')
  if lockButton then
    lockButton.onClick = 
      function ()
        if self:isDraggable() then
          self:lock()
        else
          self:unlock()
        end
      end
  end

  self:getChildById('miniwindowTopBar').onDoubleClick =
    function()
      if self:isOn() then
        self:maximize()
      else
        self:minimize()
      end
    end
  self:getChildById('bottomResizeBorder').onDoubleClick = function()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    self:setHeight(resizeBorder:getMinimum())
  end

  local oldParent = self:getParent()

  self:updateFromSettings()

  local newParent = self:getParent()

  self.miniLoaded = true

  if self.save then
    if oldParent and oldParent:getClassName() == 'UIMiniWindowContainer' and not self.containerWindow then
      addEvent(function() oldParent:order() end)
    end
    if newParent and newParent:getClassName() == 'UIMiniWindowContainer' and newParent ~= oldParent then
      addEvent(function() newParent:order() end)
    end
  end

  self:fitOnParent()

  if not self._onlineUpdater then
    self._onlineUpdater = function() self:updateFromSettings() end
    connect(g_game, { onGameStart = self._onlineUpdater })
  end
end

function UIMiniWindow:updateFromSettings()
  local settings = g_settings.getNode('MiniWindows') or {}
  local char = g_game.getCharacterName() or nil
  if char == nil then return end
  local charKey = char
  local charSettings
  if charKey and settings[char] then
    charSettings = settings[charKey]
  elseif charKey then
    charSettings = {}
    settings[charKey] = charSettings
  else
    charSettings = settings
  end

  local selfSettings = charSettings and charSettings[self:getId()]
  if selfSettings then
    if selfSettings.parentId then
      local parent = rootWidget:recursiveGetChildById(selfSettings.parentId)
      if parent then
        if parent:getClassName() == 'UIMiniWindowContainer' and selfSettings.index and parent:isOn() then
          self:setParent(parent, true)
          self.miniIndex = selfSettings.index
          parent:scheduleInsert(self, selfSettings.index)
        elseif selfSettings.position then
          self:setParent(parent, true)
          self:setPosition(topoint(selfSettings.position))
        end
      end
    end

    if selfSettings.minimized then
      self:minimize(true)
    else
      self:maximize(true)
      if selfSettings.height and self:isResizeable() then
        self:setHeight(selfSettings.height)
      elseif selfSettings.height and not self:isResizeable() then
        self:eraseSettings({height = true})
      end
    end
    if selfSettings.closed and not self.forceOpen and not self.containerWindow then
      self:close(true)
    else
      addEvent(function() self:open(true) end)
    end

    if selfSettings.locked then
      scheduleEvent(function() self:lock(true) end, 500)
    else
      self:unlock(true)
    end
  else
    if not self.forceOpen and self.autoOpen ~= nil and (self.autoOpen == 0 or self.autoOpen == false) and not self.containerWindow then
      self:close(true)
    end
  end
end

function UIMiniWindow:onDestroy()
  if self._onlineUpdater then
    disconnect(g_game, { onGameStart = self._onlineUpdater })
    self._onlineUpdater = nil
  end
end

function UIMiniWindow:onVisibilityChange(visible)
  self:fitOnParent()
end

function UIMiniWindow:onDragEnter(mousePos)
  local parent = self:getParent()
  if not parent then return false end

  if parent:getClassName() == 'UIMiniWindowContainer' then
    local containerParent = parent:getParent():getParent()
    parent:removeChild(self)
    containerParent:addChild(self)
    parent:saveChildren()
  end

  local oldPos = self:getPosition()
  self.movingReference = { x = mousePos.x - oldPos.x, y = mousePos.y - oldPos.y }
  self:setPosition(oldPos)
  self.free = true
  return true
end

function UIMiniWindow:onDragLeave(droppedWidget, mousePos)
  if self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
    self.setMovedChildMargin = nil
    self.movedOldMargin = nil
    self.movedIndex = nil
  end

  UIWindow:onDragLeave(self, droppedWidget, mousePos)
  self:saveParent(self:getParent())
end

function UIMiniWindow:onDragMove(mousePos, mouseMoved)
  local oldMousePosY = mousePos.y - mouseMoved.y
  local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
  local overAnyWidget = false
  for i=1,#children do
    local child = children[i]
    if child:getParent():getClassName() == 'UIMiniWindowContainer' then
      overAnyWidget = true

      local childCenterY = child:getY() + child:getHeight() / 2
      if child == self.movedWidget and mousePos.y < childCenterY and oldMousePosY < childCenterY then
        break
      end

      if self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.setMovedChildMargin = nil
      end

      if mousePos.y < childCenterY then
        self.movedOldMargin = child:getMarginTop()
        self.setMovedChildMargin = function(v) child:setMarginTop(v) end
        self.movedIndex = 0
      else
        self.movedOldMargin = child:getMarginBottom()
        self.setMovedChildMargin = function(v) child:setMarginBottom(v) end
        self.movedIndex = 1
      end

      self.movedWidget = child
      self.setMovedChildMargin(self:getHeight())
      break
    end
  end

  if not overAnyWidget and self.movedWidget then
    self.setMovedChildMargin(self.movedOldMargin or 0)
    self.movedWidget = nil
  end

  return UIWindow.onDragMove(self, mousePos, mouseMoved)
end

function UIMiniWindow:onMousePress()
  local parent = self:getParent()
  if not parent then return false end
  if parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
    return true
  end
end

function UIMiniWindow:onFocusChange(focused)
  if not focused then return end
  local parent = self:getParent()
  if parent and parent:getClassName() ~= 'UIMiniWindowContainer' then
    self:raise()
  end
end

function UIMiniWindow:onHeightChange(height)
  if not self:isOn() then
    self:setSettings({height = height})
  end
  self:fitOnParent()
end

function UIMiniWindow:getSettings(name)
  if not self.save then return nil end
  local char = (g_game.isOnline() and g_game.getCharacterName())
  if char == '' then char = nil end
  if not char then return nil end
  local settings = g_settings.getNode('MiniWindows') or {}
  if settings[char] then
    settings = settings[char]
  else
    return nil
  end
  local selfSettings = settings[self:getId()]
  if selfSettings then
    return selfSettings[name]
  end
  return nil
end

function UIMiniWindow:setSettings(data)
  if not self.save then return end
  local char = (g_game.isOnline() and g_game.getCharacterName())
  if char == '' then char = nil end
  if not char then return end

  local settings = g_settings.getNode('MiniWindows') or {}
  settings[char] = settings[char] or {}
  settings = settings[char]

  local id = self:getId()
  settings[id] = settings[id] or {}

  for key,value in pairs(data) do
    settings[id][key] = value
  end

  local all = g_settings.getNode('MiniWindows') or {}
  all[char] = settings
  g_settings.setNode('MiniWindows', all)
end

function UIMiniWindow:eraseSettings(data)
  if not self.save then return end
  local char = (g_game.isOnline() and g_game.getCharacterName())
  if char == '' then char = nil end
  if not char then return end

  local settings = g_settings.getNode('MiniWindows') or {}
  settings[char] = settings[char] or {}
  settings = settings[char]

  local id = self:getId()
  settings[id] = settings[id] or {}

  for key,value in pairs(data) do
    settings[id][key] = nil
  end

  local all = g_settings.getNode('MiniWindows') or {}
  all[char] = settings
  g_settings.setNode('MiniWindows', all)
end

function UIMiniWindow:clearSettings()
  if not self.save then return end
  local char = (g_game.isOnline() and g_game.getCharacterName())
  if char == '' then char = nil end
  if not char then return end

  local settings = g_settings.getNode('MiniWindows') or {}
  settings[char] = settings[char] or {}
  settings = settings[char]

  local id = self:getId()
  settings[id] = {}

  local all = g_settings.getNode('MiniWindows') or {}
  all[char] = settings
  g_settings.setNode('MiniWindows', all)
end

function UIMiniWindow:saveParent(parent)
  local parent = self:getParent()
  if parent then
    if parent:getClassName() == 'UIMiniWindowContainer' then
      parent:saveChildren()
    else
      self:saveParentPosition(parent:getId(), self:getPosition())
    end
  end
end

function UIMiniWindow:saveParentPosition(parentId, position)
  local selfSettings = {}
  selfSettings.parentId = parentId
  selfSettings.position = pointtostring(position)
  self:setSettings(selfSettings)
end

function UIMiniWindow:saveParentIndex(parentId, index)
  local selfSettings = {}
  selfSettings.parentId = parentId
  selfSettings.index = index
  self:setSettings(selfSettings)
  self.miniIndex = index
end

function UIMiniWindow:disableResize()
  self:getChildById('bottomResizeBorder'):disable()
end

function UIMiniWindow:enableResize()
  self:getChildById('bottomResizeBorder'):enable()
end

function UIMiniWindow:fitOnParent()
  local parent = self:getParent()
  if self:isVisible() and parent and parent:getClassName() == 'UIMiniWindowContainer' then
    parent:fitAll(self)
  end
end

function UIMiniWindow:setParent(parent, dontsave)
  UIWidget.setParent(self, parent)
  if not dontsave then
    self:saveParent(parent)
  end
  self:fitOnParent()
end

function UIMiniWindow:setHeight(height)
  UIWidget.setHeight(self, height)
  signalcall(self.onHeightChange, self, height)
end

function UIMiniWindow:setContentHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setParentSize(minHeight + height)
end

function UIMiniWindow:setContentMinimumHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setMinimum(minHeight + height)
end

function UIMiniWindow:setContentMaximumHeight(height)
  local contentsPanel = self:getChildById('contentsPanel')
  local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()

  local resizeBorder = self:getChildById('bottomResizeBorder')
  resizeBorder:setMaximum(minHeight + height)
end

function UIMiniWindow:getMinimumHeight()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:getMinimum()
end

function UIMiniWindow:getMaximumHeight()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:getMaximum()
end

function UIMiniWindow:isResizeable()
  local resizeBorder = self:getChildById('bottomResizeBorder')
  return resizeBorder:isExplicitlyVisible() and resizeBorder:isEnabled()
end