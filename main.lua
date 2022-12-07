EVENT_LOG = {}
COROUTINE = nil
CANVAS = nil
ACTION = "READ"
COROUTINE = nil
-- testmode exists for developers on mac/linux to avoid dataloss if the migration terminates during a file overwrite
-- instead of the main folder, the files are instead written to a separate "testing" folder
TESTMODE = false

function love.load()
  CANVAS = love.graphics.newCanvas(800, 600)

  if love.system.getOS() == "Android" or TESTMODE == true then
    -- keep the old global instance if we were just rebooting rather than reinitialising
    if AndroidMigration == nil then
      require("migration")
    end
    COROUTINE = coroutine.create(AndroidMigration.run)
  end
  AndroidMigration.saveDirectory = love.filesystem.getSaveDirectory()
end

function love.update(dt)
  if COROUTINE ~= nil and coroutine.status(COROUTINE) ~= "dead" then
    local status, err = coroutine.resume(COROUTINE, AndroidMigration)
    if not status then
      error(err .. "\n\n" .. debug.traceback(COROUTINE))
    end
  end
end

function love.draw()
  love.graphics.setCanvas(CANVAS)
  love.graphics.setBackgroundColor(0, 0, 0, 1)
  love.graphics.clear()

  if AndroidMigration then
    AndroidMigration:printEvents()
  else
    love.graphics.printf("Device is not an android or migration has already finished", 30, 15, CANVAS:getWidth(), "left")
  end
  

  love.graphics.setCanvas()
  love.graphics.draw(CANVAS)
end