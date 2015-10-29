--[[----------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

--------------------------------------------------------------------------------

Info.lua
Summary information for Export Video plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'ch.andyhermann.videorenderer',

	LrPluginName = LOC "$$$/VideoRenderer/PluginName=Video Renderer",
	
	-- Add the menu item to the File menu.
	
	LrExportMenuItems = {
		title = "Render Sequence as Video",
		file = "ExportMenuItem.lua",
		enabledWhen = "photosSelected",
	},
	
	LrExportServiceProvider = {
		title = LOC "$$$/VideoRenderer/Export-title=Render Video",
		file = 'RenderVideoExportServiceProvider.lua',
	},
	
	VERSION = { major=1, minor=0, revision=0, build=0, string="1.0.0.0" },

}


	