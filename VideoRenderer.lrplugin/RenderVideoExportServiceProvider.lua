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
		{ key = 'codec', default = 'libx264' },
		{ key = 'container', default = 'mp4' },
		{ key = 'size', default = '1920x1080' },
		{ key = 'framerate', default = '30' },
		{ key = 'pixelFormat', default = 'yuv420p' },
		-- -aspect aspect      set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)
}

exportServiceProvider.startDialog = function ( propertyTable )

    myLogger:trace("startDialog")
    --local updateChecker = require('UpdateChecker')
    --updateChecker.check()
	
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
					width = share 'leftLabel',
				},

				f:edit_field {
					value = bind 'filename',
					truncation = 'middle',
					immediate = true,
					fill_horizontal = 1,
				},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Size=Size:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'size',
					items = {
						{ value = '3840x2160', title = "4K - 3840x2160" },
						{ value = '2704x1524', title = "2.7K - 2704x1524" },
						{ value = '1920x1080', title = "Full HD - 1920x1080" },
						{ value = '1280x720', title = "HD - 1280x720" },
						{ value = '640x480', title = "VGA - 640x480" },
					},
					-- Standard 4:3: 320x240, 640x480, 800x600, 1024x768
					-- Widescreen 16:9: 640x360, 800x450, 960x540, 1024x576, 1280x720, and 1920x1080
				},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/FrameRate=Frame Rate:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'framerate',
					items = {
						{ value = '25', title = "25 Frames/s" },
						{ value = '30', title = "30 Frames/s" },
						{ value = '48', title = "48 Frames/s" },
						{ value = '60', title = "60 Frames/s" },
					},
				},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Codec=Codec:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'codec',
					items = {
						{ value = 'libx264', title = "H264/MPEG-4 AVC" },
						--{ value = 'libx265', title = "H265/HVEC" },
						{ value = 'gif', title = "GIF" },
					},
				},
			},
		},
	}
	
	return result
	
end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	myLogger:trace("Start exportServiceProvider.processRenderedPhotos")
	
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
	local codec = exportParams.codec -- default "libx264"
	local frameRate = exportParams.framerate -- default "30"
	local size = exportParams.size -- default "1920x1080"
	local pixelFormat = "yuv420p"
	local outputFile = exportParams.filename -- LrPathUtils.child
	local command = string.format("\"%s\" -y -i %s/%s -c:v %s -r %s -s %s -pix_fmt %s \"%s/%s\"", 
		appPath, outputPath, filePattern, codec, frameRate, size, pixelFormat, outputPath, outputFile)
    myLogger:info(string.format("command: %s", command))
    result = LrTasks.execute(command)
    myLogger:trace(string.format("ffmpeg result: %d", result))
    
    progressScope:done()
end

return exportServiceProvider