local LrHttp = import "LrHttp"
local LrLogger = import "LrLogger"
local LrTasks = import "LrTasks"
local LrPathUtils = import("LrPathUtils")
JSON = loadfile(LrPathUtils.child(_PLUGIN.path, "JSON.lua"))()
local Info = require("Info")

local logger = LrLogger("VideoRenderer")
logger:enable("print")

--------------------------------------------------------------------------------

local updateChecker = {}

updateChecker.check = function () 
    checkLatestRelease()
end

function checkerCallback(latestVersion, downloadUrl)
    logger:infof("LatestVersion is: %d.%d.%d", latestVersion.major, latestVersion.minor, latestVersion.revision)

    local currentVersion = getCurrentVersion()
    logger:infof("CurrentVersion is: %d.%d.%d", currentVersion.major, currentVersion.minor, currentVersion.revision)
	
    if (compareVersions(currentVersion, latestVersion) == -1) then
        logger:info("An update is available")
        -- show update available dialog

        -- download file if user chooses 'update'
        -- LrHttp.openUrlInBrowser( url )
    else
        logger:info("You are up-to-date.")
    end 
	
end

function getCurrentVersion()
    return Info.VERSION
end

function checkLatestRelease() 
    logger:trace("getting latest release...")
    -- send LrApplication.macAddressHash()
    -- send LrSystemInfo.summaryString()
    --local headers = {}
    --    'Accept' = 'application/json',
    --    'User-Agent' = 'Lua UpdateChecker'
    --local timeout = 10
	local RELEASES_URL = "https://api.github.com/repos/andreashermann/VideoRenderer/releases"
	
 	LrTasks.startAsyncTask( function()
    	local response, headers = LrHttp.get( RELEASES_URL )
    	logger:trace("response: %s", response)
    	
    	local result = JSON:decode(response)
    	local latestRelease = result[1]
    	local tag = latestRelease.tag_name
    	local major,minor,revision = tag:match("([^,]+).([^,]+).([^,]+)")
    	local version = { major=tonumber(major), minor=tonumber(minor), revision=tonumber(revision)}
    	local downloadUrl = latestRelease.assets[1].browser_download_url
    	
    	--logger:tracef("version: %s", version)
    	--logger:tracef("downloadUrl: %s", downloadUrl)
    	checkerCallback(version, downloadUrl)
 	end )
end

function compareVersions(a, b) 
    if (a.major > b.major) then 
        return 1
    end 
    if (a.major < b.major) then
        return -1
    end
    if (a.minor > b.minor) then 
        return 1
    end
    if (a.minor < b.minor) then
        return -1
    end
    if (a.revision > b.revision) then
        return 1
    end
    if (a.revision < b.revision) then
        return -1
    end
    return 0
end

return updateChecker
