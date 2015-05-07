-- test harness for lightroom SDK

_G._PLUGIN = {
	path = ""
}
  
local mocks = {
	LrLogger = function() 
		return {
			enable = function() end,
			trace = function(message) 
				--print("TRACE:") 
			end,
			info = function(message) 
				--print("INFO:") 
			end
		}
	end,

	LrPathUtils = {
		child = function(parent, c) 
			if (c == "ffmpeg") then return "/Users/ahermann/Workspaces/VideoRenderer/src/ffmpeg" end
			return ""
		end
	},

	LrTasks = {
		execute = function(command) 
			print(command)
			local b = os.execute(command)
			if (b) then return 0 else return -1 end
			--local handle = io.popen(command)
			--local result = handle:read("*a")
			--handle:close()
			--return 0
		end
	},
}

_G.import = function(name)
	return mocks[name]
end