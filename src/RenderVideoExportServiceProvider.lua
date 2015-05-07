local LrApplication = import("LrApplication")
local LrDialogs = import("LrDialogs")
local LrFunctionContext = import("LrFunctionContext")
local LrErrors = import("LrErrors")
local LrFileUtils = import("LrFileUtils")
local LrPathUtils = import("LrPathUtils")
local LrTasks = import("LrTasks")
local LrLogger = import("LrLogger")
local LrProgressScope = import("LrProgressScope")
local LrColor = import("LrColor")
local LrHttp = import("LrHttp")

local prefs = import("LrPrefs").prefsForPlugin() -- plugins own preferences
local myLogger = LrLogger("VideoRenderer")
--myLogger:enable("logfile")
myLogger:enable("print")

local ffmpeg = require("ffmpegRenderer")
local dialogs = require("dialogs")

--------------------------------------------------------------------------------

local exportServiceProvider = {}

exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }
exportServiceProvider.showSections = { 'exportLocation' }
-- exportServiceProvider.canExportToTemporaryLocation = true

exportServiceProvider.updateExportSettings = function ( exportSettings )

	exportSettings.LR_outputSharpeningOn = true
	exportSettings.LR_outputSharpeningMedia = 'screen'
	exportSettings.LR_outputSharpeningLevel = 2 -- medium
	
	-- exportSettings.LR_export_useSubfolder = 'false'
	exportSettings.LR_collisionHandling = 'ask'
	exportSettings.LR_extensionCase = 'lowercase'
	exportSettings.LR_renamingTokensOn = true
	exportSettings.LR_initialSequenceNumber = 1
	exportSettings.LR_tokens = '{{naming_sequenceNumber_5Digits}}'
	exportSettings.LR_jpeg_quality = 1

end

exportServiceProvider.exportPresetFields = {
		{ key = 'filename', default = 'video.mp4' },
		{ key = 'codec', default = 'libx264' },
		{ key = 'container', default = 'mp4' },
		{ key = 'size', default = '1920x1080' },
		{ key = 'framerate', default = '30' },
		{ key = 'pixelFormat', default = 'yuv420p' },
		-- -aspect aspect      set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)
}

exportServiceProvider.startDialog = dialogs.startDialog
exportServiceProvider.sectionsForTopOfDialog = dialogs.sectionsForTopOfDialog
exportServiceProvider.sectionsForBottomOfDialog = dialogs.sectionsForBottomOfDialog

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	myLogger:trace("Start exportServiceProvider.processRenderedPhotos")
	
	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
    
    local numPhotos = exportSession:countRenditions()
    local progressScope = exportContext:configureProgress({
      title = LOC("$$$/VideoRenderer/ProgressExport=Video Renderer")
      --title = LOC("$$$/VideoRenderer/ProgressExport=Video Renderer exports ^1 Images", numPhotos)
    })
    progressScope:setCaption("Exporting Photos")
    
    local files = {}
    numFiles = 0
    for i, rendition in exportContext:renditions({stopIfCanceled = true, progressScope = progressScope, renderProgressPortion = 0.5}) do
      local success, pathOrMessage = rendition:waitForRender()
      if progressScope:isCanceled() then
        break
      end
      if success then
        numFiles = numFiles + 1
        local parent = LrPathUtils.parent(rendition.destinationPath)
        local resizedFile = rendition.destinationPath 
        -- resizedFile = LrPathUtils.child(parent,string.format("%i_resized.jpg",i))
        
		local convertPath = LrPathUtils.child(_PLUGIN.path, "convert")
        local command = string.format("\"%s\" \"%s\" " ..
        	"-resize 1920x1080^ " ..
        	"-gravity center " .. 
        	"-crop 1920x1080+0+0 +repage " .. 
        	"%s", 
        	convertPath,
        	rendition.destinationPath,
        	rendition.destinationPath)
        myLogger:info(string.format("command: %s", command))
        LrTasks.execute(command)
      else
        LrErrors.throwUserError("Lightroom rendition failed.")
      end
    end
    
    local outputPath = exportParams.LR_export_destinationPathPrefix
    local inputPattern = outputPath .. "/" .. "%05d.jpg"
	local outputFile = outputPath .. "/" .. exportParams.filename
	local renderParameters = {
		codec = exportParams.codec, -- default "libx264"
		frameRate = exportParams.framerate, -- default "30"
		scale = "scale=-1:1080",
		pixelFormat = "yuv420p"
	}
    ffmpeg.renderVideo(inputPattern, outputFile, renderParameters)
    
    progressScope:done()
end

return exportServiceProvider