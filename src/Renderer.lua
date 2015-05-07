local LrPathUtils = import "LrPathUtils"
local LrTasks = import "LrTasks"
local LrLogger = import "LrLogger"

local myLogger = LrLogger("VideoRenderer")
myLogger:enable("print")

return {
}

--local renderProgress = LrProgressScope({
-- parent = progressScope,
--  parentEndRange = 1,
--  caption = LOC("$$$/VideoRenderer/ProgressExport=Rendering ^1 Frames", numPhotos),
--  functionContext = functionContext
--})
--io.open("/tmp/status.txt", "w"):close() -- touch to ensure file exists
--LrTasks.startAsyncTask(function ()
--	renderProgress:setPortionComplete(0,nil)
--	local result = LrTasks.execute(command)
--	myLogger:trace(string.format("ffmpeg finished with exit code: %d", result))
--	renderProgress:setPortionComplete(1,nil)
--	renderProgress:done()
--end, "rendererTask")
--fh,err = io.open("/tmp/status.txt","r")
--if err then myLogger:error("Could not open file /tmp/status.txt" .. err); return; end
--while true do
--	line = fh:read()
--    if line == nil then break end
--    myLogger:trace("status.txt: " .. line)
--    if string.find(line,"frame") then
--            --myLogger:trace(line)
--    end
--    if (renderProgress:isDone()) then break end
--end
--fh:close()
--io.delete("/tmp/status.txt")