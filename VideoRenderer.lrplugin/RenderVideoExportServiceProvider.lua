local LrApplication = import("LrApplication")
local LrDialogs = import("LrDialogs")
local LrFunctionContext = import("LrFunctionContext")
local LrErrors = import("LrErrors")
local LrFileUtils = import("LrFileUtils")
local LrPathUtils = import("LrPathUtils")
local LrTasks = import("LrTasks")
local LrLogger = import("LrLogger")

local prefs = import("LrPrefs").prefsForPlugin() -- plugins own preferences
local myLogger = LrLogger("VideoRenderer")

--myLogger:enable("logfile")
myLogger:enable("print")

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
}

exportServiceProvider.startDialog = function ( propertyTable )

    -- myLogger:info("startDialog")
	
end


exportServiceProvider.sectionsForBottomOfDialog = function ( _, propertyTable )

	local LrView = import 'LrView'

	local f = LrView.osFactory()
	local bind = LrView.bind
	local share = LrView.share

	local result = {
	
		{
			title = LOC "$$$/VideoRenderer/ExportDialog/VideoSettings=Video Settings",
			
			synopsis = bind { key = 'fullPath', object = propertyTable },
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/FileName=File Name:",
					alignment = 'right',
				},

				f:edit_field {
					value = bind 'filename',
					truncation = 'middle',
					immediate = true,
					fill_horizontal = 1,
				},
			},
		},
	}
	
	return result
	
end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	myLogger:info("Start exportServiceProvider.processRenderedPhotos")
	
	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
    
    local numPhotos = exportSession:countRenditions()
    local progressScope = exportContext:configureProgress({
      title = LOC("$$$/VideoRenderer/ProgressExport=Exporting ^1 Images for Video Renderer", numPhotos)
    })
    
    local files = {}
    numFiles = 0
    for i, rendition in exportContext:renditions({stopIfCanceled = true}) do
      local success, pathOrMessage = rendition:waitForRender()
      if progressScope:isCanceled() then
        break
      end
      if success then
        numFiles = numFiles + 1
      else
        LrErrors.throwUserError("Lightroom rendition failed.")
      end
    end
    
    progressScope:setCaption("Rendering Video")
    -- -b 320k # bit rate
	local appPath = LrPathUtils.child(_PLUGIN.path, "ffmpeg")
    local outputPath = exportParams.LR_export_destinationPathPrefix
	local filePattern = "\%05d.jpg" -- LrPathUtils.child
	local frameRate = "30"
	local size = "1920x1080" -- "3840x2160"
	local pixelFormat = "yuv420p"
	local outputFile = exportParams.filename -- LrPathUtils.child
	local command = string.format("\"%s\" -i %s/%s -c:v libx264 -r %s -s %s -pix_fmt %s \"%s/%s\"", 
		appPath, outputPath, filePattern, frameRate, size, pixelFormat, outputPath, outputFile)
    myLogger:info(string.format("command: %s", command))
    result = LrTasks.execute(command)
    myLogger:trace(string.format("ffmpeg result: %d", result))
    
    progressScope:done()
end

return exportServiceProvider