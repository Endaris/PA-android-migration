ACTION = "READ"
DATA_LOCATION = "INTERNAL"

AndroidMigration = { eventLog = {}, progress = "Waiting for confirmation" }

require("file")

function AndroidMigration.readStorage(self)
  self:updateProgress("Reading all files in " .. DATA_LOCATION .. " storage into memory...")
  self.filetree = {}
  coroutine.yield()
  self:recursiveRead("", self.filetree) -- "" refers to the root directory
  self:updateProgress("Finished reading all files in " .. DATA_LOCATION .. " storage into memory")
end

function AndroidMigration.wipeStorage(self)
  local successMessage = "All files have been wiped from " .. DATA_LOCATION
  if TESTMODE == true then
    successMessage = successMessage .. " (not)"
  else
    self:recursiveRemoveFiles("") -- "" is the root directory
  end
  self:updateProgress(successMessage)
end

function AndroidMigration.writeStorage(self)
  self:updateProgress("Writing all files in memory to " .. DATA_LOCATION .. " storage")
  coroutine.yield()
  self:recursiveWrite(self.filetree)
  self:updateProgress("Finished writing all files from memory to " .. DATA_LOCATION .. " storage")
end

function AndroidMigration.validateWrite(self)
  self.action = "VALIDATE"
  self.oldFiletree = self.filetree
  self:updateProgress("Confirming results of write process in " .. DATA_LOCATION .. " storage")
  self:readStorage()
  self:updateProgress("Comparing write results with internal memory to validate successful migration")
  return self:recursiveCompare(self.oldFiletree, self.filetree)
end

function AndroidMigration.reboot(self, intendedLocation, action)
  self:updateProgress("Restart to " .. action .. DATA_LOCATION .. " imminent")
  self:logEvent(".")
  for i = 0, 300 do
    self.eventLog[#self.eventLog] = self.eventLog[#self.eventLog] .. "."
    self:printEvents()
  end
  self:logEvent("Setting " .. action .. " location to " .. intendedLocation)
  DATA_LOCATION = intendedLocation
  ACTION = action
  package.loaded.conf = nil
  love.conf = nil
  love.init()
  love.load()
end

function AndroidMigration.terminateMigration(self, intendedLocation)
  self:logEvent(".")
  for i = 0, 300 do
    self.eventLog[#self.eventLog] = self.eventLog[#self.eventLog] .. "."
    self:printEvents()
  end
  
  self:logEvent("Please confirm via touch to terminate the application")
  self:printEvents()
  while not self:touchConfirmation() do
    coroutine.yield()
  end
  love.event.quit()
end

function AndroidMigration.updateProgress(self, newProgress)
  self:logEvent(newProgress)
  self.progress = newProgress
end

function AndroidMigration.logEvent(self, ...)
  self.eventLog[#self.eventLog+1] = ...
  self:printEvents()
end

function AndroidMigration.printEvents(self)
  local i = 0


  for y_offset = CANVAS:getHeight() - 50, 60, -15 do
    if self.eventLog[#self.eventLog - i] then
      love.graphics.print(self.eventLog[#self.eventLog - i], 30, y_offset)
      i = i + 1
    end
  end
  if self.progress then
    love.graphics.printf(self.progress, 15, 45, CANVAS:getWidth() - 30, "left")
  end
  love.graphics.printf("save location: " .. self.saveDirectory, 15, 30, CANVAS:getWidth() - 30, "left")
end

function AndroidMigration.writeLog(self)
  self:logEvent("Writing log to " .. DATA_LOCATION .. " storage")
  local text = table.concat(self.eventLog, "\n")
  self.eventLog = { self.eventLog[#self.eventLog] }
  print(text)
  love.filesystem.append("migration.log", text)
end

AndroidMigration.infoMessage = "Your device has been detected by Panel Attack as an Android device.\n" ..
"To facilitate the installation of mods and retrieval of data (e.g. for moving data or using the same user_id between PC and phone) Panel Attack will attempt to migrate its data from internal storage to external storage.\n"..
"Internal storage = only accessible by the app, users can't read or write | External storage = accessible by the app and the user, you can read and write (aka install mods, retrieve replays and user id)\n" ..
"No data will be lost in this process. In case something goes wrong, old data is retained and the game will start as normal afterwards.\n" ..
"If you encounter an issue with the migration, please notify us by creating an issue on https://github.com/panel-attack/panel-attack/issues or posting in the bugs channel in the panel attack discord server under https://discord.panelattack.com \n\n" ..
"Touch your display to start the migration."

function AndroidMigration.displayInfoMessage(self)
  self.progress = self.infoMessage
end

function AndroidMigration.touchConfirmation()
  if #love.touch.getTouches() > 0 or love.mouse.isDown(1, 2, 3, 4, 5, 6, 7) then
    return true
  end

  return false
end

function AndroidMigration.promptStart(self)
  self:displayInfoMessage()
  while not self.touchConfirmation() do
    coroutine.yield()
  end
end

function AndroidMigration.run(self)
  if DATA_LOCATION == "INTERNAL" then
    if ACTION == "READ" then
      self:promptStart()

      self:readStorage()
      coroutine.yield()
      self:reboot("EXTERNAL", "WRITE")
      coroutine.yield()

    elseif ACTION == "WIPE" then
      self:wipeStorage()
      coroutine.yield()
      self:terminateMigration("EXTERNAL")
    end
  else
    self:writeStorage()
    coroutine.yield()
    if self:validateWrite() then
      self:updateProgress("Comparison of files finished, all write results are valid")
      coroutine.yield()
      self:logEvent("Rebooting to wipe internal storage")
      coroutine.yield()
      self:reboot("INTERNAL", "WIPE")
      coroutine.yield()
    else
      self:updateProgress("Validation of migration process failed, check migration.log for further information")
      coroutine.yield()
      self:writeLog()
      coroutine.yield()
      self:terminateMigration()
    end
  end
end

return AndroidMigration