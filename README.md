# Spatial Player
_An example spatial/immersive video player for Apple Vision Pro_

By [Mike Swanson](https://blog.mikeswanson.com/)

With Vision Pro, Apple has created a device that can playback spatial and immersive video recorded by iPhone 15 Pro, the Vision Pro itself, or created with my [spatial command line tool](https://blog.mikeswanson.com/spatial) (and similar tools). These videos are encoded using MV-HEVC, and each contains a [Video Extended Usage box](https://developer.apple.com/av-foundation/Stereo-Video-ISOBMFF-Extensions.pdf) that describes how to play them back. Unfortunately, even one month after release, Apple has provided no (obvious) method to play these videos in all of their supported formats.

Out of necessity, I created a very bare-bones spatial video player to test the output of my command-line tool. It has also been used to test video samples that have been sent to me by interested parties. I've played up to 12K-per-eye (11520x5760) 360º stereo content (though at a low frame rate).

## Features
I hesitate to list features, because there are so few of them!

* Choose a video from the document picker. Very similar to the built-in Files app.
* The player extracts spatial metadata and creates the correct projection geometry for rectilinear, equirectangular, and half-equirectangular playback. There's no support for `.fisheye` format, since it is currently undocumented. Maybe we'll learn more at WWDC24.
* Playback metadata is displayed in the moveable/resizable window.
* There is a **Show in stereo** switch to toggle between mono and stereo playback (if supported by the video).

That's it. There are no play/pause controls. No seek/scrub controls. If you want to watch a video again, you'll have to re-pick it from the document picker. If you want to do more than that, that's an exercise that is "left to the reader."

## Usage
Clone the repo and open the project in Xcode 15.2 (or later). Then run it in the Simulator or on a device.

## Future

This is an example project that is meant to unblock others. It is not intended to become a fully-featured spatial media player, and I have no plans to make any significant updates. If you make something with it, though, [I'd love to hear from you](https://blog.mikeswanson.com/contact).

Have fun!
