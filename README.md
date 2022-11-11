# LogiQuick
Qt Quick/QML interface for Logitech G19S keyboards

This renders a Qt Quick scene from a QML file and displays it on a connected Logitech G19 or G19S keyboard LCD via the Logitech G19(s) software.

Keypad events are translated into key press/release events.

Rendering is done in an offscreen FBO and is fairly efficient.

At the moment only Windows 10 will work with this version. For Linux/BSD or other, see the [g19daemon branch](https://github.com/danieloneill/LogiQuick/tree/g19daemon) which provides a direct interface to the keyboard.

## Building

Open LogiQuick.pro in Qt Creator, and configure as you please. The resulting binary will attempt to load **"../LogiQuick/test.qml"**, so if your build path is somewhere other than Qt Creator's default shadow-build path, you may want to update that.

## Running

Double-click the .exe in Explorer or something, I dunno.

## Extending

The point of this is to enable Qt Quick applets, which is my use case. For my purposes the only extending I've done has been in the form of Components, but there are various ways to add functionality.

In particular, G510 / G510S, G13, and G15 series, all monochrome, could be supported with relatively little code modification. I don't own any of those keyboards, but for the enterprising coder just check out LogitechLCDLib.h and method calls in logiview.cpp starting with "LogiLcd". (The surface format being ARGB32 will definitely also need to be changed!)

## Warranty

This project is for a keyboard that Logitech doesn't even make anymore, using an API they stopped supporting in 2014.

For all intents and purposes this is a "code dump" for others to use as they like, but can otherwise be considered abandoned.
