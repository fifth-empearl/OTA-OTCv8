-- private variables
local topMenu
local fpsUpdateEvent = nil

-- list of predefined categories
local categories = {
  {name = "Player", icon = "/images/topbuttons/inventory", tooltip = "Player", index = 4},
  {name = "Others", icon = "/images/topbuttons/options", tooltip = "Others", index = 5},
}
local categoryMap = {}
local currentMenu = nil
local settingsKey = "TopMenu"

local function sortByIndex(list)
  table.sort(list, function(a, b)
    return (a.index or 9999) < (b.index or 9999)
  end)
end

local function updateCurrentMenuPosition()
  if currentMenu and currentMenu:isVisible() then
    local category = currentMenu.category
    if category and category.button then
      local pos = category.button:getPosition()
      pos.y = pos.y + category.button:getHeight() + 1
      currentMenu:setPosition(pos)
    end
  end
end

local function updateTopMenuWidth()
  if not topMenu or not topMenu.buttonsPanel then
    return
  end

  local spacing = 0
  local layout = topMenu.buttonsPanel:getLayout()
  if layout and layout.getSpacing then
    spacing = layout:getSpacing()
  end

  local panelWidth = -spacing
  for _, child in ipairs(topMenu.buttonsPanel:getChildren()) do
    if child:isExplicitlyVisible() then
      panelWidth = panelWidth + child:getWidth() + spacing
    end
  end

  panelWidth = math.max(0, panelWidth)
  panelWidth =
    panelWidth + topMenu.buttonsPanel:getPaddingLeft() + topMenu.buttonsPanel:getPaddingRight() +
    topMenu.buttonsPanel:getMarginLeft() +
    topMenu.buttonsPanel:getMarginRight() +
    topMenu.buttonsPanel:getBorderLeftWidth() +
    topMenu.buttonsPanel:getBorderRightWidth()

  topMenu:setWidth(panelWidth)
  updateCurrentMenuPosition()
end

local function savePosition()
  if topMenu then
    local settings = {}
    settings.position = pointtostring(topMenu:getPosition())
    g_settings.mergeNode(settingsKey, settings)
  end
end

local function loadPosition()
  local settings = g_settings.getNode(settingsKey)
  if settings and settings.position then
    topMenu:breakAnchors()
    topMenu:setPosition(topoint(settings.position))
  end
end

-- private functions
local function createButton(id, description, icon, callback, index, hasMenu)
  hasMenu = hasMenu or false
  local class = hasMenu and "TopButton2" or "TopButton"
  local button = g_ui.createWidget(class, topMenu.buttonsPanel)
  button:setId(id)
  button:setTooltip(description)
  button:setIcon(resolvepath(icon, 3))
  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton and mouseButton ~= MouseTouch then
      callback()
      return true
    end
  end
  button.onTouchRelease = button.onMouseRelease
  if type(index) == "number" then
    button.index = index
  end
  local children = topMenu.buttonsPanel:getChildren()
  sortByIndex(children)
  for i, child in ipairs(children) do
    topMenu.buttonsPanel:moveChildToIndex(child, i)
  end
  updateTopMenuWidth()
  return button
end

local function hideCategoryMenu(name)
  local category = categoryMap[name]
  if category and category.menu and category.menu:isVisible() then
    category.menu:hide()
    category.button:setChecked(false)
    if currentMenu == category.menu then
      currentMenu = nil
    end
  end
end

local function ensureCategoryMenu(category)
  if category.menu and not category.menu:isDestroyed() then
    category.menu.category = category
    return category.menu
  end

  local menu = g_ui.createWidget("TopCategoryMenu", g_ui.getRootWidget())
  menu:hide()
  menu.category = category

  menu.onHoverChange = function(widget, hovered)
    if not hovered then
      local thisMenu = menu
      scheduleEvent(
        function()
          if currentMenu == thisMenu and not category.button:isHovered() then
            local mousePos = g_window.getMousePosition()
            if not thisMenu:containsPoint(mousePos) then
              hideCategoryMenu(category.name)
            end
          end
        end,
        100
      )
    end
  end

  category.menu = menu
  return menu
end

local function showCategoryMenu(name)
  local category = categoryMap[name]
  if not category then
    return
  end

  local menu = ensureCategoryMenu(category)

  sortByIndex(category.items)

  if menu.itemCount ~= #category.items then
    menu:destroyChildren()
    local label = g_ui.createWidget("TopCategoryMenuLabel", menu)
    label:setText(name)
    label.onHoverChange = function(_, hovered)
      if hovered then
        return
      end
      scheduleEvent(
      function()
        if currentMenu ~= menu then
          return
        end

        local mousePos = g_window.getMousePosition()
        if not menu:containsPoint(mousePos) and not category.button:isHovered() then
          hideCategoryMenu(name)
        end
      end,
      100)
    end
    for _, item in ipairs(category.items) do
      local option = g_ui.createWidget(menu:getStyleName() .. "IconButton", menu)
      option.onClick = function()
        hideCategoryMenu(name)
        item.callback(menu:getPosition())
      end
      option.onHoverChange = function(_, hovered)
        if hovered then
          return
        end
        local thisMenu = menu
        scheduleEvent(
        function()
          if currentMenu ~= thisMenu then
            return
          end

          local mousePos = g_window.getMousePosition()
          if not thisMenu:containsPoint(mousePos) and not category.button:isHovered() then
            hideCategoryMenu(name)
          end
        end,
        100)
      end
      option:setText(item.description)
      option:setTooltip(item.description)
      option:setIcon(resolvepath(item.icon or "", 3))
      local width = option:getTextSize().width + option:getMarginLeft() + option:getMarginRight() + 40
      menu:setWidth(math.max(menu:getWidth(), width))
    end
    menu.itemCount = #category.items
  end

  if currentMenu and currentMenu ~= menu then
    currentMenu:hide()
    currentMenu.button:setChecked(false)
  end

  local pos = category.button:getPosition()
  pos.y = pos.y + category.button:getHeight() + 1
  menu:setPosition(pos)
  menu:show()
  category.button:setChecked(true)

  updateCurrentMenuPosition()
  currentMenu = menu
  currentMenu.button = category.button
end

function createCategory(name, icon, tooltip, index, hasMenu)
  if categoryMap[name] then
    return categoryMap[name].button
  end

  local catButton =
    createButton(
    "cat_" .. name,
    tooltip or name,
    icon or "",
    function()
    end,
    index,
    hasMenu
  )
  catButton:setTooltip(tooltip or name)
  categoryMap[name] = {button = catButton, items = {}, index = index, name = name}
  catButton.onHoverChange = function(widget, hovered)
    if hovered then
      showCategoryMenu(name)
    else
      local lastMenu = categoryMap[name] and categoryMap[name].menu
      scheduleEvent(
        function()
          local cat = categoryMap[name]
          if cat and cat.menu == lastMenu and not cat.button:isHovered() then
            local mousePos = g_window.getMousePosition()
            if not cat.menu or not cat.menu:isVisible() or not cat.menu:containsPoint(mousePos) then
              hideCategoryMenu(name)
            end
          end
        end,
      100)
    end
  end
  return catButton
end

-- public functions
function init()
  connect(
    g_game,
    {
      onGameStart = online,
      onGameEnd = offline,
      onPingBack = updatePing
    }
  )

  topMenu = g_ui.createWidget("TopMenu", g_ui.getRootWidget())
  topMenu:hide()
  topMenu.buttonsPanel = topMenu:getChildById("buttonsPanel")
  topMenu.fpsLabel = topMenu:getChildById("fpsLabel")
  topMenu.pingLabel = topMenu:getChildById("pingLabel")
  topMenu.onGeometryChange = function()
    updateCurrentMenuPosition()
  end
  topMenu.onDragLeave = function()
    savePosition()
    return true
  end

  -- create predefined categories
  sortByIndex(categories)
  for _, cat in ipairs(categories) do
    createCategory(cat.name, cat.icon, cat.tooltip, cat.index, true)
  end

  updateTopMenuWidth()

  Keybind.new("UI", "Toggle Top Menu", "Ctrl+Shift+T", "")
  Keybind.bind(
    "UI",
    "Toggle Top Menu",
    {
      {
        type = KEY_DOWN,
        callback = toggle
      }
    }
  )

  if g_game.isOnline() then
    scheduleEvent(online, 10)
  end

  updateFps()
end

function terminate()
  disconnect(
    g_game,
    {
      onGameStart = online,
      onGameEnd = offline,
      onPingBack = updatePing
    }
  )
  removeEvent(fpsUpdateEvent)

  Keybind.delete("UI", "Toggle Top Menu")

  for _, cat in pairs(categoryMap) do
    if cat.menu then
      cat.menu:destroy()
    end
  end

  if topMenu then
    topMenu:destroy()
  end
end

function online()
  modules.game_interface.getRootPanel():addAnchor(AnchorTop, "parent", AnchorTop)
  topMenu:show()
  loadPosition()

  if topMenu.pingLabel then
    addEvent(
      function()
        if
          modules.client_options.getOption("showPing") and
            (g_game.getFeature(GameClientPing) or g_game.getFeature(GameExtendedClientPing))
         then
          topMenu.pingLabel:show()
        else
          topMenu.pingLabel:hide()
        end
      end
    )
  end
end

function offline()
  topMenu:hide()

  if topMenu.pingLabel then
    topMenu.pingLabel:hide()
  end
end

function updateFps()
  if not topMenu.fpsLabel then
    return
  end
  fpsUpdateEvent = scheduleEvent(updateFps, 500)
  local text = "FPS: " .. g_app.getFps()
  topMenu.fpsLabel:setText(text)
end

function updatePing(ping)
  if not topMenu.pingLabel then
    return
  end
  if g_proxy and g_proxy.getPing() > 0 then
    ping = g_proxy.getPing()
  end

  local text = "Ping: "
  local color
  if ping < 0 then
    text = text .. "??"
    color = "yellow"
  else
    text = text .. ping .. " ms"
    if ping >= 500 then
      color = "red"
    elseif ping >= 250 then
      color = "yellow"
    else
      color = "green"
    end
  end
  topMenu.pingLabel:setColor(color)
  topMenu.pingLabel:setText(text)
end

function setPingVisible(enable)
  if not topMenu.pingLabel then
    return
  end
  topMenu.pingLabel:setVisible(enable)
end

function setFpsVisible(enable)
  if not topMenu.fpsLabel then
    return
  end
  topMenu.fpsLabel:setVisible(enable)
end

function addOwnListing(id, description, icon, callback, index)
  return createButton(id, description, icon, callback, index, false)
end

function addCategoryListing(id, description, icon, callback, category, index)
  if not categoryMap[category] then
    createCategory(category)
  end

  local cat = categoryMap[category]
  table.insert(
    cat.items,
    {
      id = id,
      description = description,
      icon = icon,
      callback = callback,
      index = index
    }
  )
  return cat.button
end

function getTopMenu()
  return topMenu
end

function toggle()
  if not topMenu then
    return
  end

  if topMenu:isVisible() then
    hide()
  else
    show()
  end
end

function hide()
  topMenu:hide()
  modules.game_interface.getRootPanel():addAnchor(AnchorTop, "parent", AnchorTop)
  if modules.game_stats then
    modules.game_stats.show()
  end
end

function show()
  topMenu:show()
  modules.game_interface.getRootPanel():addAnchor(AnchorTop, "parent", AnchorTop)
  if modules.game_stats then
    modules.game_stats.hide()
  end
end
