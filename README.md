# Render Video Lightroom Plugin

A plugin for Adobe Photoshop Lightroom® to convert a sequence of images into a video.

## Features

This plugin renders an image sequence as video

- Size: 4K, 2.7K, Full HD, HD, VGA
- Frame rate: 60, 48, 30, 25 fps
- Codec: H264
- Pixel format: yuv420p

## Download

[Latest Release for Mac OS X](https://github.com/andreashermann/VideoRenderer/releases/latest)

## Installation

Double click to mount disk image and run the installer package.

The installer will copy the plugin to ~/Library/Application Support/Adobe/Lightroom/Modules/

Presets for the plugin are copied to ~/Library/Application Support/Adobe/Lightroom/Export Presets/Video Renderer/

## Requirements

This plugin has been tested on Mac OS X 10.10 with Lightroom 5.

## Usage Instructions


1. Start Lightroom
2. Select a number of images
3. Open the export dialog
4. In the export dialog choose Export To "Render Video" and enter a path

## Third Party Tools 

These open source technologies are used:

- ffmpeg: LGPL 2.1 license
- imagemagick: Apache 2.0 license
- Jeffs Lua JSON implementation: Creative Commons
