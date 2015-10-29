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
local LrColor = import("LrColor")
local LrView = import 'LrView'

local Info = require("Info")

local prefs = import("LrPrefs").prefsForPlugin() -- plugins own preferences
local myLogger = LrLogger("VideoRenderer2")
--myLogger:enable("logfile")
myLogger:enable("print")

local ffmpeg = require("ffmpegRenderer")
local dialogs = require("dialogs")

--------------------------------------------------------------------------------

local exportServiceProvider = {}

exportServiceProvider.allowFileFormats = { 'JPEG','TIFF' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }
exportServiceProvider.showSections = { 'exportLocation','fileSettings','watermarking' }
exportServiceProvider.canExportToTemporaryLocation = true

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
		{ key = 'cropToFit', default = true },
		{ key = 'framerate', default = '30' },
		{ key = 'pixelFormat', default = 'yuv420p' }, -- yuv420p|yuv444p|yuv410p, yuvj420p|yuvj444p?
		-- prores --> 'yuv422p10le'
		-- h264 profiles: baseline main high high10 high422 high444
		-- prores profiles: 1,2,3
		-- -aspect aspect      set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)
		{ key = 'deleteAfterRendering', default = true },
}

exportServiceProvider.startDialog = function ( propertyTable )
	--myLogger:trace("startDialog")
	local LrView = import 'LrView'
	local f = LrView.osFactory()
	
	local catalog = LrApplication.activeCatalog()
	local photos = catalog:getTargetPhotos()
	
	--local c1 = f:scrolled_view {
	--	horizontal_scroller = false,
	--	width = 600,
	--	background_color = LrColor(0.3, 0.3, 0.3),
	--}
	
	local c = f:column {
			place_vertical = 0.5,
	
			f:row {
				f:static_text({ title = "Photo" }),
				f:static_text({ title = "Exposure" })
			},
			f:row {
				f:catalog_photo({ 
					photo = photos[1]
				}),
				f:static_text({ title = "Photo 1" }),
				f:static_text({ title = "0.5" })
			},
			f:row {
				f:catalog_photo({ 
					photo = photos[2]
				}),
				f:group_box {
					title = "Slider Two",
					font = "<system>",
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "sliderOne" ),
						width_in_digits = 7
					}
				}
			}
		}
	
	--tprint(c._children[1],0)
	--for i=1,10 do
	-- 
	table.insert(c._children, f:row {
				f:group_box {
					title = "Slider Four",
					font = "<system>",
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "sliderThree" ),
						width_in_digits = 7
					}
				}
			})
	-- end
	
	--LrDialogs.presentModalDialog {
	--	title = "Exposure Analysis",
	--	contents = c
	--}
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      myLogger:info(formatting)
      --tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      myLogger:info(formatting .. tostring(v))      
    else
      myLogger:info(formatting .. v)
    end
  end
end

exportServiceProvider.sectionsForTopOfDialog = function ( f , propertyTable )
	return {
		{
			title = 'Information',
			f:column {
				f:static_text {title = 'Video Renderer Plugin ' .. Info.VERSION.string },
				f:static_text {title = 'Author: Andreas Hermann <a.v.hermann@gmail.com>'},
				f:spacer {height = 10},
				f:static_text {title = 'This plugin includes these third-party tools:'},
				f:row {
					f:static_text {title = '- ffmpeg'},
					f:static_text {
						title = 'https://www.ffmpeg.org/',
						mouse_down = function() LrHttp.openUrlInBrowser('https://www.ffmpeg.org/') end,
						text_color = LrColor( 0, 0, 1 )
					}
				},
				f:row {
					f:static_text {title = '- ImageMagick®'},
					f:static_text {
						title = 'http://www.imagemagick.org/',
						mouse_down = function() LrHttp.openUrlInBrowser('http://www.imagemagick.org/') end,
						text_color = LrColor( 0, 0, 1 )
					}
				}
			}
		}
	}
end

exportServiceProvider.sectionsForBottomOfDialog = function ( _, propertyTable )

	local f = LrView.osFactory()
	local bind = LrView.bind
	local share = LrView.share

	--local photo = catalog:getTargetPhoto()
	--photo:requestJpegThumbnail(320,240,function(data,err)
	--	
	--end)
	--local dim = photo:getRawMetadata("croppedDimensions")
	--local aspect = aspectRatio
	local catalog = LrApplication.activeCatalog()
	local targetPhoto = catalog:getTargetPhoto()

	-- needs to run in LrTask
	--local croppedDimensions = ".x."
	--LrTasks.startAsyncTask(function() 
	--	croppedDimensions = targetPhoto:getFormattedMetadata("croppedDimensions")
	--end)

	local result = {
		{
			title = LOC "$$$/VideoRenderer/ExportDialog/VideoSettings=Render Settings",
			synopsis = bind { key = 'fullPath', object = propertyTable },
		
			--f:row {
			--	f:static_text {
			--		title = LOC "$$$/VideoRenderer/ExportDialog/Size=Original Image:",
			--		alignment = 'right',
			--		width = share 'leftLabel',
			--	},
			--	f:catalog_photo({
			--		photo = targetPhoto,
			--		width = 320,
			--		height = 240,
			--	})
			--},
		
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Size=Format:",
					alignment = 'right',
					width = share 'leftLabel',
				},
			
				f:popup_menu {
					value = bind 'size',
					items = {
						--{ value = '3840x2160', title = "4K" },
						--{ value = '2048x1024', title = "2K - 2048x1024" },
						{ value = '1920x1080', title = "1080p HD" },
						{ value = '1280x720', title = "720p HD" },
						--{ value = '720x576', title = "PAL SD - 720x576" },
						--{ value = '720x480', title = "NTSC SD - 720x480" },
					},
					-- Standard 4:3: 320x240, 640x480, 800x600, 1024x768
					-- Widescreen 16:9: 640x360, 800x450, 960x540, 1024x576, 1280x720, and 1920x1080
				},
			},
			
			f:row {
				f:static_text {
					title = "",
					width = share 'leftLabel',
				},
				
				f:checkbox {
					value = bind 'cropToFit',
				},
			
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/CropLabel=Crop To Fit",
				},
			},
		
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Codec=Video Codec:",
					alignment = 'right',
					width = share 'leftLabel',
				},
			
				f:popup_menu {
					value = bind 'codec',
					items = {
						{ value = 'libx264', title = "H.264" },
						{ value = 'prores', title = "Apple ProRes" },
						--{ value = 'gif', title = "GIF" },
						-- extensionForFormat
					},
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
						{ value = '23.98', title = "23.98 Frames/s" },
						{ value = '24', title = "24 Frames/s" },
						{ value = '25', title = "25 Frames/s" },
						{ value = '29.97', title = "29.97 Frames/s" },
						{ value = '30', title = "30 Frames/s" },
						--{ value = '50', title = "50 Frames/s" },
						--{ value = '59.94', title = "59.94 Frames/s" },
						--{ value = '60', title = "60 Frames/s" },
					},
				},
			},
		
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
		
			--f:row {
			--	f:checkbox {
			--		value = bind 'deleteAfterRendering',
			--		alignment = 'right',
			--	},
			--	
			--	f:static_text {
			--		title = LOC "$$$/VideoRenderer/ExportDialog/KeepImages=Delete exported frames after rendering.",
			--		alignment = 'right',
			--	},
			--}
		}
	}

	return result
end

function exportServiceProvider.postProcessRenderedPhotos ( functionContext, filterContext )
	local renditionOptions = {
		plugin = _PLUGIN,
		renditionToSatisfy = filterContext.renditionToSatisfy,
		filterSettings = function (renditionToSatisfy, exportSettings) 
			-- hook to change render settings
			-- e.g. exportSettings.LR_format = TIFF
		end
	}
end

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
      if success and exportParams.cropToFit then
        numFiles = numFiles + 1
        local parent = LrPathUtils.parent(rendition.destinationPath)
        local resizedFile = rendition.destinationPath
		local convertPath = LrPathUtils.child(_PLUGIN.path, "convert")
        local command = string.format("\"%s\" \"%s\" " ..
        	"-resize " .. exportParams.size .. "^ " ..
        	"-gravity center " .. 
        	"-crop " .. exportParams.size .. "+0+0 +repage " .. 
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
    -- TODO: find out sub folder setting
    --if exportParams.LR_export_useSubfolder then
    --	inputPattern = inputPattern .. LR_export_destination
    --end
    --inputPattern = inputPattern .. "%05d.jpg"
    
	local outputFile = outputPath .. "/" .. exportParams.filename
	local renderParameters = {
		codec = exportParams.codec, -- default "libx264"
		frameRate = exportParams.framerate, -- default "30"
		pixelFormat = "yuv420p"
	}
	
	if (exportParams.size == "1920x1080") then
		renderParameters.scale = "scale=-1:1080"
	elseif (exportParams.size == "3840x2160") then
		renderParameters.scale = "scale=-1:2160"
	end
	
	if (exportParams.codec == "prores") then
		renderParameters.pixelFormat = "yuv422p10le"
	elseif (exportParams.codec == "libx264") then
		renderParameters.pixelFormat = "yuv420p"
	end
    
    --ffmpeg.renderVideo(inputPattern, outputFile, renderParameters, progressScope)
    progressScope:setCaption("Rendering Video")
	render(inputPattern, outputFile, renderParameters)
    
    progressScope:done()
end

function render( inputPattern, outputFile, params )
	local ffmpegPath = LrPathUtils.child(_PLUGIN.path, "ffmpeg")
	
	local command = string.format("\"%s\" ", ffmpegPath)
	command = command .. "-y "
	command = command .. string.format("-progress %s ","/tmp/status.txt")
	command = command .. string.format("-i \"%s\" ", inputPattern)
	command = command .. string.format("-c:v %s ", params.codec)
	
	if (params.codec == "prores") then
		-- 0 : ProRes422 (Proxy)
		-- 1 : ProRes422 (LT)
		-- 2 : ProRes422 (Normal)
		-- 3 : ProRes422 (HQ)
		command = command .. string.format("-profile:v %s ", 2)
	end
	
	command = command .. string.format("-r %s ", params.frameRate)
	command = command .. string.format("-vf %s ", params.scale)
	command = command .. string.format("-pix_fmt %s ", params.pixelFormat)
	command = command .. string.format("\"%s\" 2>/dev/null", outputFile)
	
    myLogger:info(string.format("render command: %s", command))
    --LrErrors.throwUserError("Export failed." .. command)
	
    result = LrTasks.execute(command)
    myLogger:trace(string.format("ffmpeg finished with exit code: %d", result))
    if (result > 0) then
    	LrErrors.throwUserError(string.format("Rendering failed with error code %d", result))
    end
    
    return result
end

return exportServiceProvider