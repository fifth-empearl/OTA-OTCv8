function init()
  -- define a basic white line as example
  g_map.defineCreatureLineType(1, '/images/lines/white.png', 255, 255, 255, true, true)
end

function terminate()
  g_map.clearCreatureLines()
end
