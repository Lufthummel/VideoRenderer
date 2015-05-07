return {
	startDialog = function ( propertyTable )
		myLogger:trace("startDialog")
		--local updateChecker = require('UpdateChecker')
		--updateChecker.check()
	end,

	sectionsForTopOfDialog = function ( f , propertyTable )
		return {
			{
				title = 'Information',
				f:column {
					f:static_text {title = 'Video Renderer Plugin'},
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
	end,
	
	sectionsForBottomOfDialog = function ( _, propertyTable )

		local LrView = import 'LrView'

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
				
					--f:static_text {
					--	title = LOC "$$$/VideoRenderer/ExportDialog/SourceSizeLabel=Source:",
					--	alignment = 'right',
					--	width = share 'leftLabel',
					--},
					--
					--f:static_text {
					--	title = croppedDimensions,
					--	alignment = 'right',
					--	width = share 'leftLabel'
					--},
				},
			
				f:row {
					f:static_text {
						title = LOC "$$$/VideoRenderer/ExportDialog/Codec=Video Format:",
						alignment = 'right',
						width = share 'leftLabel',
					},
				
					f:popup_menu {
						value = bind 'codec',
						items = {
							{ value = 'libx264', title = "H.264" },
							--{ value = 'libx265', title = "H265/HVEC (Experimental)" },
							--{ value = 'prores', title = "Apple ProRes" },
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
							{ value = '25', title = "25 Frames/s" },
							{ value = '30', title = "30 Frames/s" },
							{ value = '48', title = "48 Frames/s" },
							{ value = '60', title = "60 Frames/s" },
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
				}
			}
		}
	
		return result
	end
}