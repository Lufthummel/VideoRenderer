require 'rake'
require 'rake/clean'
require 'fileutils'

TARGET_DIR = 'target'
PLUGIN_NAME = 'VideoRenderer.lrplugin'
PACKAGE_DIR = TARGET_DIR + '/' + PLUGIN_NAME
CLEAN.include(TARGET_DIR)

task :test do
  puts "Running unit tests"
end

desc "create a package directory"
task :package do
  directory PACKAGE_DIR
  mkdir_p PACKAGE_DIR
end

desc "copy all resources to the target folder"
task :resources => :package do
  cp 'src/ffmpeg', PACKAGE_DIR 
  #cp 'LICENSE', PACKAGE_DIR
  #cp 'README.md', PACKAGE_DIR
end

desc "compile the lua code"
task :compile => :package do
  FileList['src/*.lua'].each {|f|
    cp f, PACKAGE_DIR
  } 
end

desc "compress the target folder and name it .lrplugin"
task :compress, [:version] => [:compile, :resources] do |t, args|
  version = args[:version] 
  sh %{cd target; zip Lightroom.Video.Renderer.#{args.version}.OSX.zip #{PLUGIN_NAME}/*} do |ok, res|
    if !ok
      puts "zip failed (status = #{res.existatus})"
    end
  end
end

desc "build the plugin"
task :plugin, [:version] => :clean do |t, args|
  version = args[:version] 
  puts "Version #{version}"
  Rake::Task[:compress].invoke(args.version)
end

desc "create a release at github and upload the artifact"
  # puts `git tag #{args[:tagname]}` if !TASKENV.eql? "debug"
  # puts `git push --tags` if !TASKENV.eql? "debug"

task :publish => [:compress] do
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
end

task :release => [:compile, :resources, :compress, :publish] do

end

task :default => [:plugin]
