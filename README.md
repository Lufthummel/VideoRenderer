# Render Video Lightroom Plugin

A plugin for Adobe Photoshop Lightroom® to convert a sequence of images into a video.

## Features
This plugin renders an image sequence as video

- Size: 4K, 2.7K, Full HD, HD, VGA
- Frame rate: 60, 48, 30, 25 fps
- Codec: H264
- Pixel format: yuv420p

## Downloads

[Releases for Mac OS X](https://github.com/andreashermann/VideoRenderer/releases)

## Requirements

This plugin has been tested on Mac OS X 10.10 with Lightroom 5.

## Usage Instructions

1. Double click to mount disk image and run the installer package.
   It will copy the plugin to ~/Library/Application Support/Adobe/Lightroom/Modules/

2. Start Lightroom, select a number of images, open the export dialog
   In the export dialog choose Export To "Render Video"

## Dependencies

These open source technologies are used:

- ffmpeg: LGPL 2.1 license
- imagemagick: Apache 2.0 license
