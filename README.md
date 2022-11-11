# LogiQuick
Qt Quick/QML interface for Logitech G19/G19S keyboards

This renders a Qt Quick scene(s) from a QML file and displays it on a connected Logitech G19 or G19S keyboard LCD via the Logitech G19(s) software (on windows, or directly on Linux via the [g19daemon branch](https://github.com/danieloneill/LogiQuick/tree/g19daemon)).

![Tray icon and menu](https://i.imgur.com/Vvf5EiU.png)

![Input interface](https://i.imgur.com/kvKCpTo.png)

Rendering is done in an offscreen FBO and is fairly efficient.

Keypad events are translated into key press/release events. These events are exposed to the QML via Qt signals and can be used to change options, switch QML scenes, or whatever.

[Video demonstration](https://imgur.com/9lEaqJg)

[Another video demonstration](https://imgur.com/ewIb7jS)

## Windows

At the moment only Windows 10 will work with the "master" branch. For Linux/BSD or other, see the [g19daemon branch](https://github.com/danieloneill/LogiQuick/tree/g19daemon) which provides a direct interface to the keyboard.

The **Input Window** isn't a thing in the Windows version since I haven't been using Windows, but I may add it at some point.

A standalone version not requiring the Logitech software seems theoretically possible, but my experiments with libusb-1.0 on Windows suggest it would take somewhat significant amounts of fiddling to accomplish.

## Linux/BSD

The only hard requirements are Qt 5+ and libusb-1.0.

There are some substantial differences between Qt5 and Qt6, so you may have to crack open the example QML files and massage them for whichever version you're using. In particular MediaPlayer and DropShadow come to mind, both of which are in use in the examples.

The Input Window should properly handle whatever keyboard or mouse events you throw at it, but I haven't implemented tablet, joystick, steering wheel, light pen, touchscreen, or camel interfaces for it.

## Building

Open LogiQuick.pro in Qt Creator, and configure as you please. The resulting binary will attempt to load **"../LogiQuick/test.qml"**, so if your build path is somewhere other than Qt Creator's default shadow-build path, you may want to update that.

## Running

If you don't want to build it, [download a release here](https://github.com/danieloneill/LogiQuick/releases/tag/0.1).

Then double-click the .exe in Explorer or something, I dunno.

## Extending

The point of this is to enable Qt Quick applets, which is my use case. For my purposes the only extending I've done has been in the form of Components, but there are various ways to add functionality.

In particular, G510 / G510S, G13, and G15 series, all monochrome, could possibly be supported with some code modification. I don't own any of those keyboards, but for the enterprising coder just check out LogitechLCDLib.h and method calls in logiview.cpp starting with "LogiLcd". (The surface format being ARGB32 will definitely also need to be changed!)

## Writing your own QML for it

The examples are a good starting point, but here are some methods, signals, and wigglings that may help:

### Methods:
 * LogiView.showLoadDialogue() - Offers a *File Open* dialogue on the desktop for the user to select a qml file to load
 * LogiView.load(path:string) - Load a qml file at *path*
 * LogiView.setDisplayBrightness(brightness:int) - Sets the screen brightness between 0 and 127 inclusive
 * LogiView.postKeyPressed(key:Qt.Key, [modifiers:Qt.KeyboardModifiers]) - Simulate a key press to any control with active focus in the loaded qml scene.
 * LogiView.postKeyReleased(key:Qt.Key, [modifiers:Qt.KeyboardModifiers]) - Simulate a key release to any control with active focus in the loaded qml scene.
 * LogiView.getOpenFileName(caption:string, dir:string, filter:string) -> string - Prompt the user with a *File Open* dialogue and return the filepath.

### Signals:
 * stop() - Application is about to close
 * currentFrameChanged() - A new frame was drawn
 * deferredLoad(path:string) - A new QML file is loading
 * framebufferUpdated(image:QImage) - Basically useless on the QML side, but it's our current framebuffer grab
 * gKeyPressed(Qt.Key key) - Called whenever a macro key (G1:12, M1:MR, or LCD keys) are pressed. Codes are as follows:

| key code         | physical key |
|------------------|--------------|
| Qt.Key_Launch0   | G1           |
| Qt.Key_Launch1   | G2           |
| Qt.Key_Launch2   | G3           |
| Qt.Key_Launch3   | G4           |
| Qt.Key_Launch4   | G5           |
| Qt.Key_Launch5   | G6           |
| Qt.Key_Launch6   | G7           |
| Qt.Key_Launch7   | G8           |
| Qt.Key_Launch8   | G9           |
| Qt.Key_Launch9   | G10          |
| Qt.Key_LaunchA   | G11          |
| Qt.Key_LaunchB   | G12          |
| Qt.Key_LaunchC   | M1           |
| Qt.Key_LaunchD   | M2           |
| Qt.Key_LaunchE   | M3           |
| Qt.Key_LaunchF   | MR           |
| Qt.Key_HomePage  | "Sprocket"   |
| Qt.Key_Stop      | Back Arrow   |
| Qt.Key_Favorites | Menu         |
| Qt.Key_Go        | OK           |
| Qt.Key_Right     | DPad Right   |
| Qt.Key_Left      | DPad Left    |
| Qt.Key_Down      | DPad Down    |
| Qt.Key_Up        | DPad Up      |
| Qt.Key_LightBulb | Light Button |

I connect by using a *Connections* component thing:

```
    Connections {
        target: LogiView
        function onGKeyPressed(key) {
            if( key === Qt.Key_Up )
                optionList.decrementCurrentIndex();
            else if( key === Qt.Key_Down )
                optionList.incrementCurrentIndex();
            else if( key === Qt.Key_Go )
                optionList.currentItem.clicked();
            else if( key === Qt.Key_Stop )
                Qt.quit();
        }
    }
```

## Warranty

This project is for a keyboard that Logitech doesn't even make anymore, using an API they stopped supporting in 2014.

For all intents and purposes this is a "code dump" for others to use as they like, but can otherwise be considered abandoned.

## Cool uses of

Here's my Twitch stream chat on there:

![Screenshot of the Twitch chat window](https://i.imgur.com/NkxH1No.png)

![Photo of my G19s showing the chat](https://i.imgur.com/hKhIny0.png)
