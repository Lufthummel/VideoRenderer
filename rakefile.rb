require 'rake'
require 'rake/clean'
require 'fileutils'

# dependencies: 
# gimli - sudo gem install gimli
# p7zip - brew install p7zip

TARGET_DIR = 'target'
CLEAN.include(TARGET_DIR)

PLUGIN_NAME = 'VideoRenderer.lrplugin'
PLUGIN_DIR = TARGET_DIR + '/installer/Modules/' + PLUGIN_NAME
PACKAGE_NAME = 'Lightroom Video Renderer Plugin.pkg'
IDENTIFIER = 'ch.andyhermann.videorenderer'
LIGHTROOM_SUPPORT = '~/Library/Application\ Support/Adobe/Lightroom'

task :test do
  puts "Running unit tests"
end

desc "create the necessary directories"
task :init do
  directory PLUGIN_DIR
  mkdir_p PLUGIN_DIR
end

desc "copy all resources to the target plugin"
task :resources => :init do
  cp 'src/ffmpeg', PLUGIN_DIR 
  cp 'src/convert', PLUGIN_DIR 
  cp 'LICENSE', PLUGIN_DIR
end

desc "compile the lua code"
task :compile => :init do
  # TODO: really compile code!
  FileList['src/*.lua'].each {|f|
    cp f, PLUGIN_DIR
  } 
  
  # replace $version$ in Info.lua
  infoFile = PLUGIN_DIR + '/Info.lua'
  infoContent = File.read(infoFile).gsub!(/\$VERSION\$/, "#{version}")
  File.open(infoFile, "w") { |f| f.puts infoContent }
end

desc "prepare the plugin"
task :plugin => [:compile, :resources] do
  # 
end

def version
	v = `git describe --tags --long`
	v.sub! "-", "."
	v.sub "\n", "" # strip undesired new line
end

desc "prepare the presets"
task :presets do
  PRESETS_DIR = TARGET_DIR + '/installer/Export Presets/Video Renderer'
  mkdir_p PRESETS_DIR
  FileList['presets/*'].each {|f|
    cp f, PRESETS_DIR
  }
end

desc "create the installer package"
task :package => [:plugin, :presets] do |t, args|
  PACKAGE_DIR = TARGET_DIR + '/' + PACKAGE_NAME
  sh %{pkgbuild --identifier "#{IDENTIFIER}" --version "#{version}" --install-location #{LIGHTROOM_SUPPORT} --root #{TARGET_DIR}/installer "#{PACKAGE_DIR}" }  do |ok, res|
    if !ok
      puts "pkg creation failed (status = #{res.exitstatus})"
    end
  end
end

desc "generate the documentation"
task :documentation do
	sh %{gimli -f README.md -outputfilename "target/Read Me"}
end

desc "create the disk image"
task :disk_image => [:package,:documentation] do |t, args|
  DISK_IMAGE_DIR = TARGET_DIR + '/disk_image/'
  mkdir_p DISK_IMAGE_DIR
  cp TARGET_DIR + '/' + PACKAGE_NAME, DISK_IMAGE_DIR
  cp 'LICENSE', DISK_IMAGE_DIR
  cp TARGET_DIR + '/Read Me.pdf', DISK_IMAGE_DIR
  image_name = "Lightroom Video Renderer Plugin #{version}.dmg"
  volume_name = "Video Renderer Plugin"
  sh %{hdiutil create "target/#{image_name}" -volname "#{volume_name}" -srcfolder "#{DISK_IMAGE_DIR}"}  do |ok, res|
    if !ok
      puts "disk image creation failed (status = #{res.exitstatus})"
    end
  end
end

desc "updates the ffmpeg binary"
task :ffmpeg_download do
	# download static ffmpeg build for OSX
	# http://evermeet.cx/ffmpeg/ffmpeg-2.6.2.7z
	ffmpeg_version = '2.6.2.7'
	sh %{curl -O http://evermeet.cx/ffmpeg/ffmpeg-#{ffmpeg_version}z} do |ok, res|
		if !ok
      		puts "ffmpeg download failed (status = #{res.exitstatus})"
    	end
	end
	sh %{7za e ffmpeg-#{ffmpeg_version}z}
	rm "ffmpeg-#{ffmpeg_version}z"
	mv "ffmpeg", "src/ffmpeg"
end

desc "updates the imagemagick binary"
task :imagemagick_download do
	sh %{curl -O http://www.imagemagick.org/download/binaries/ImageMagick-x86_64-apple-darwin14.0.0.tar.gz} do |ok, res|
		if !ok
      		puts "imagemagick download failed (status = #{res.exitstatus})"
    	end
	end
	sh %{tar xzvf ImageMagick-x86_64-apple-darwin14.0.0.tar.gz}
	cp "ImageMagick-6.9.0/bin/convert" "src/"
	rm "ImageMagick-x86_64-apple-darwin14.0.0.tar.gz"
end

desc "create a zip file containing the plugin"
task :compress => [:plugin] do |t, args|
  sh %{cd target; zip Lightroom.Video.Renderer.#{version}.OSX.zip #{PLUGIN_NAME}/*} do |ok, res|
    if !ok
      puts "zip failed (status = #{res.exitstatus})"
    end
  end
  # TODO: add Readme.md to zip file
  #cp 'README.md', PACKAGE_DIR
  #cp 'LICENSE', PLUGIN_DIR
end

desc "create a release at github and upload the artifact"
  # puts `git tag #{args[:tagname]}` if !TASKENV.eql? "debug"
  # puts `git push --tags` if !TASKENV.eql? "debug"

task :publish => [:disk_image] do
## create release
#POST /repos/:owner/:repo/releases
#{
#  "tag_name": "v1.0.0",
#  "target_commitish": "master",
#  "name": "v1.0.0",
#  "body": "Description of the release",
#  "draft": false,
#  "prerelease": false
#}

## upload to github via web API
#create release response 
#url = [0]["upload_url"]

#POST https://<upload_url>/repos/:owner/:repo/releases/:id/assets?name=foo.zip
#Content-Type application/zip

# https://developer.github.com/changes/2013-09-25-releases-api/
# https://gist.github.com/caspyin/2288960
#curl -H "Authorization: token TOKEN" \
#     -H "Accept: application/vnd.github.manifold-preview" \
#     -H "Content-Type: application/zip" \
#     --data-binary @build/mac/package.zip \
#     "https://uploads.github.com/repos/hubot/singularity/releases/123/assets?name=1.0.0-mac.zip"
end

task :release => [:compile, :resources, :compress, :publish] do

end

task :default => [:plugin]
