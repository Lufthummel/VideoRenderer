local LrPathUtils = import "LrPathUtils"
local LrTasks = import "LrTasks"
local LrLogger = import "LrLogger"

local myLogger = LrLogger("VideoRenderer")
myLogger:enable("print")

function renderImpl( inputPattern, outputFile, params )
	local ffmpegPath = LrPathUtils.child(_PLUGIN.path, "ffmpeg")
	local command = string.format("\"%s\" -y -progress /tmp/status.txt -i %s -c:v %s -r %s -vf %s -pix_fmt %s \"%s\" 2>/dev/null", 
		ffmpegPath, inputPattern, params.codec, params.frameRate, params.scale, params.pixelFormat, outputFile)
    myLogger:info(string.format("render command: %s", command))
    
	myLogger:trace("starting ffmpeg command")
	--progressScope:setCaption("Rendering Video")
    result = LrTasks.execute(command)
    myLogger:trace(string.format("ffmpeg finished with exit code: %d", result))
    return result
end

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

return {
	renderVideo = renderImpl
}