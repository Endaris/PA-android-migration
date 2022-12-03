-- Put any local development changes you need in here that you don't want commited.

for _, value in pairs(arg) do
  if value == "debug" then
    -- zerobrane debugging
    -- io.stdout:setvbuf("no")
    -- require("mobdebug").start()
    -- require("mobdebug").coro() 
    require("lldebugger").start()
  end
end