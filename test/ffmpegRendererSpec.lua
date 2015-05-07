require "test/sdk"

describe("Testing VideoRenderer", function()

  function fileExists(path) 
	local f=io.open(path,"r")
	if f~=nil then 
		io.close(f) 
		return true 
	else 
		return false
	end
  end

  describe("ffmpegRenderer", function()
    it("should render H.264 1080p 30fps", function()
      local ffmpegRenderer = require("ffmpegRenderer")
      local params = {
      	codec = "libx264",
      	frameRate = "30",
      	pixelFormat = "yuv420p",
      	scale = "scale=-1:1080",
      }
      local result = ffmpegRenderer.renderVideo("test/resources/%05d.jpg", "target/video-1080p-30fps.mp4", params)
      assert.are.equals(0, result)
      assert.is_true(fileExists("target/video-1080p-30fps.mp4"))
    end)
    
    it("should render H.264 720p 25fps", function()
      local ffmpegRenderer = require("ffmpegRenderer")
      local params = {
      	codec = "libx264",
      	frameRate = "25",
      	pixelFormat = "yuv420p",
      	scale = "scale=-1:720",
      }
      local result = ffmpegRenderer.renderVideo("test/resources/%05d.jpg", "target/video-720p-25fps.mp4", params)
      assert.are.equals(0, result)
      assert.is_true(fileExists("target/video-720p-25fps.mp4"))
    end)
    
  end)
end)