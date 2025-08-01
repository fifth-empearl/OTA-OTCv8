-- @docclass
-- UIMapDrawing renders a grid of items and creatures using UIItem and UICreature widgets.
--
-- Example usage:
-- local data = {
--   -- each inner table is a row. the longest row defines the grid width
--   {
--     -- a cell can be a single item id
--     100,
--     -- or a table describing multiple entries to draw on the same tile
--     { 200, { outfit = { lookType = 128 }, animate = false } }
--   },
--   {
--     -- a table with "outfit" (or "creature") draws a creature
--     { outfit = { lookType = 128 }, animate = true },
--     -- an empty table leaves the tile blank
--     {}
--   }
-- }
-- local widget = UIMapDrawing.create(data, 32)
-- widget:setParent(gameRootPanel)
--
-- -- capture a piece of the current map and print its definition
-- UIMapDrawing.printMapArea({x = 100, y = 100}, {x = 110, y = 110})
--
-- Map data format:
--   mapData = {
--     { cell1, cell2, ... }, -- row 1
--     { cell1, cell2, ... }, -- row 2
--     ...
--   }
-- The number of columns is taken from the longest row and shorter
-- rows will automatically pad with empty tiles.
-- Each cell may be:
--   number            -> single item id
--   { item = id }     -> same as above but explicit
--   { outfit = {...}, [animate=true] } or { creature = Creature, [animate=true] }
--                     -> draw a creature or outfit
--   { entry1, entry2, ... } -> multiple entries on the same tile

UIMapDrawing = extends(UIWidget, 'UIMapDrawing')

function UIMapDrawing.create(mapData, tileSize)
  local widget = UIMapDrawing.internalCreate()
  widget.tileSize = tileSize or g_sprites.spriteSize()

  local layout = UIGridLayout.create(widget)
  layout:setCellSize({ width = widget.tileSize, height = widget.tileSize })
  layout:setFitChildren(true)
  widget:setLayout(layout)

  if mapData then
    widget:setMapData(mapData)
  end

  return widget
end

function UIMapDrawing:setTileSize(size)
  self.tileSize = size
  local layout = self:getLayout()
  if layout and layout.isUIGridLayout and layout:isUIGridLayout() then
    layout:setCellSize({ width = size, height = size })
  end
end

-- Captures items and creature outfits from the game map in the given
-- rectangle. fromPos and toPos are tables with x and y fields, z is optional
-- and defaults to the player's current floor. Returns a mapData table that can
-- be passed to setMapData().
function UIMapDrawing.scanMapArea(fromPos, toPos, z)
  local player = g_game.getLocalPlayer()
  if not z and player then
    local pos = player:getPosition()
    if pos then z = pos.z end
  end
  if not z then return {} end

  local minX, maxX = math.min(fromPos.x, toPos.x), math.max(fromPos.x, toPos.x)
  local minY, maxY = math.min(fromPos.y, toPos.y), math.max(fromPos.y, toPos.y)

  local mapData = {}
  for y = minY, maxY do
    local row = {}
    for x = minX, maxX do
      local tile = g_map.getTile({x = x, y = y, z = z})
      local entries = {}
      if tile then
        for _, item in ipairs(tile:getItems()) do
          table.insert(entries, item:getId())
        end
        for _, creature in ipairs(tile:getCreatures()) do
          table.insert(entries, { outfit = creature:getOutfit() })
        end
      end
      table.insert(row, entries)
    end
    table.insert(mapData, row)
  end
  return mapData
end

-- Serializes mapData to a Lua table string for easier copy/paste.
function UIMapDrawing.mapDataToString(mapData, indent)
  indent = indent or 0
  local pad = string.rep(' ', indent)
  local parts = {'{'}
  local function valueToString(v, level)
    if type(v) == 'number' then
      return tostring(v)
    elseif type(v) == 'string' then
      return string.format('%q', v)
    elseif type(v) == 'table' then
      return UIMapDrawing.mapDataToString(v, level)
    else
      return 'nil'
    end
  end

  local isArray = #mapData > 0
  local first = true
  local nextIndent = indent + 2
  for k, v in pairs(mapData) do
    local key
    if not isArray then
      key = string.format('[%s] = ', valueToString(k, nextIndent))
    end
    if first then
      table.insert(parts, '\n' .. string.rep(' ', nextIndent))
      first = false
    else
      table.insert(parts, ',\n' .. string.rep(' ', nextIndent))
    end
    table.insert(parts, (key or '') .. valueToString(v, nextIndent))
  end
  if not first then
    table.insert(parts, '\n' .. pad)
  end
  table.insert(parts, '}')
  return table.concat(parts)
end

function UIMapDrawing.printMapArea(fromPos, toPos, z)
  local data = UIMapDrawing.scanMapArea(fromPos, toPos, z)
  print(UIMapDrawing.mapDataToString(data))
end

local function createTileEntry(tile, entry)
  if type(entry) == 'number' or (type(entry) == 'table' and entry.item) then
    local id = entry
    if type(entry) == 'table' then id = entry.item end
    local itemWidget = g_ui.createWidget('UIItem', tile)
    itemWidget:setItemId(id)
    itemWidget:setVirtual(true)
    itemWidget:setItemVisible(true)
    itemWidget:setAnchors('fill', 'parent')
  elseif type(entry) == 'table' then
    local creatureWidget = g_ui.createWidget('Creature', tile)
    if entry.creature then
      creatureWidget:setCreature(entry.creature)
    elseif entry.outfit then
      creatureWidget:setOutfit(entry.outfit)
    end
    if entry.animate ~= nil then
      creatureWidget:setAnimate(entry.animate)
    end
    creatureWidget:setAnchors('fill', 'parent')
    creatureWidget:setFixedCreatureSize(true)
  end
end

function UIMapDrawing:setMapData(mapData)
  self:destroyChildren()
  if not mapData then return end

  local layout = self:getLayout()
  local columns = 0
  for _, row in ipairs(mapData) do
    columns = math.max(columns, #row)
  end
  if layout and layout.isUIGridLayout and layout:isUIGridLayout() then
    layout:setNumColumns(columns)
  end
  -- ensure the widget area fits all tiles
  self:setSize(columns * self.tileSize, #mapData * self.tileSize)

  for _, row in ipairs(mapData) do
    for x = 1, columns do
      local cell = row[x]
      local entries = {}
      if type(cell) == 'table' and not cell.item and not cell.creature and not cell.outfit then
        entries = cell
      elseif cell ~= nil then
        entries = { cell }
      end
      local tile = g_ui.createWidget('MapDrawingTile', self)
      for _, entry in ipairs(entries) do
        createTileEntry(tile, entry)
      end
    end
  end
end

return UIMapDrawing
