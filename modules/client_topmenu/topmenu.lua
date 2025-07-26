-- private variables
local topMenu
local fpsUpdateEvent = nil

-- list of predefined categories
-- each element can contain: name, icon, tooltip, index (order)
local categories = {
        -- example predefined category
        {name = "HUD", icon = "/images/topbuttons/options", tooltip = "HUD", index = 1}
}

-- helper table mapping category names to their data
local categoryMap = {}

-- private functions
local function createButton(id, description, icon, callback, toggle, index)
        local class = toggle and 'TopToggleButton' or 'TopButton'
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
        if type(index) == 'number' then
                button.index = index
        end
        local children = topMenu.buttonsPanel:getChildren()
        table.sort(children, function(a,b) return (a.index or 9999) < (b.index or 9999) end)
        for i,child in ipairs(children) do
                topMenu.buttonsPanel:moveChildToIndex(child, i)
        end
        return button
end

local function showCategoryMenu(name)
        local category = categoryMap[name]
        if not category then
                return
        end

        if category.menu and not category.menu:isDestroyed() then
                category.menu:destroy()
        end

        local menu = g_ui.createWidget('PopupMenu')
        menu:setGameMenu(true)

        table.sort(category.items, function(a, b)
                return (a.index or 9999) < (b.index or 9999)
        end)

        for _, item in ipairs(category.items) do
                local option = g_ui.createWidget(menu:getStyleName() .. 'IconButton', menu)
                option.onClick = function()
                        if not menu:isDestroyed() then
                                menu:destroy()
                        end
                        item.callback(menu:getPosition())
                end
                option:setText(item.description)
                option:setTooltip(item.description)
                option:setIcon(resolvepath(item.icon or '', 3))
                local width = option:getTextSize().width + option:getMarginLeft() + option:getMarginRight() + 25
                menu:setWidth(math.max(menu:getWidth(), width))
        end

        local pos = category.button:getPosition()
        pos.y = pos.y + category.button:getHeight()
        menu:display(pos)

        menu.onHoverChange = function(widget, hovered)
                if not hovered then
                        scheduleEvent(function()
                                if category.menu and not category.menu:isDestroyed() and not category.button:isHovered() and not category.menu:isHovered() then
                                        category.menu:destroy()
                                end
                        end, 50)
                end
        end

        menu.onDestroy = function()
                category.menu = nil
        end

        category.menu = menu
end

local function hideCategoryMenu(name)
        local category = categoryMap[name]
        if category and category.menu and not category.menu:isDestroyed() then
                category.menu:destroy()
        end
end

function createCategory(name, icon, tooltip, index)
        if categoryMap[name] then
                return categoryMap[name].button
        end

        local catButton = createButton('cat_' .. name, tooltip or name, icon or '', function() end, false, index)
        catButton:setTooltip(tooltip or name)
        categoryMap[name] = {button = catButton, items = {}, index = index}
        catButton.onHoverChange = function(widget, hovered)
                if hovered then
                        showCategoryMenu(name)
                else
                        scheduleEvent(function()
                                local cat = categoryMap[name]
                                if cat and not cat.button:isHovered() and (not cat.menu or not cat.menu:isHovered()) then
                                        hideCategoryMenu(name)
                                end
                        end, 50)
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
        topMenu.buttonsPanel = topMenu:getChildById('buttonsPanel')
        topMenu.fpsLabel = topMenu:getChildById('fpsLabel')
        topMenu.pingLabel = topMenu:getChildById('pingLabel')

        -- create predefined categories
        table.sort(categories, function(a, b)
                return (a.index or 9999) < (b.index or 9999)
        end)
        for _, cat in ipairs(categories) do
                createCategory(cat.name, cat.icon, cat.tooltip, cat.index)
        end

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

	topMenu:destroy()
end

function online()
	modules.game_interface.getRootPanel():addAnchor(AnchorTop, "parent", AnchorTop)
	topMenu:show()

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
	text = "FPS: " .. g_app.getFps()
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

-- new category based functions
function addOwnListing(id, description, icon, callback, index, toggle)
        return createButton(id, description, icon, callback, toggle, index)
end

function addCategoryListing(id, description, icon, callback, category, index)
        if not categoryMap[category] then
                createCategory(category)
        end

        local cat = categoryMap[category]
        table.insert(cat.items, {
                id = id,
                description = description,
                icon = icon,
                callback = callback,
                index = index
        })
        return cat.button
end

function getButton(id)
	return topMenu:recursiveGetChildById(id)
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
