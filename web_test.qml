import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QtWebEngine 1.10

Rectangle {
    id: webWindow
    width: 320
    height: 240

    focus: true
    color: 'black'

    WebEngineView {
        id: webView
        //focus: true

        url: 'https://oneill.app/'

        // On my installation media playback seems to crash the Webkit process... sadface:
        //url: 'https://beta.crunchyroll.com/series/GKEH2G4KD/the-greatest-demon-lord-is-reborn-as-a-typical-nobody'
        //url: 'https://www.youtube.com/watch?v=GcgxXnEVVyM&t=1831s'
        //url: 'chrome://gpu'
        //url: 'https://twitter.com/qtproject/with_replies'
        //url: 'https://www.qt.io/'
        //url: 'http://192.168.0.1/login.php'

        // To be legible, we scale down and stretch:
        scale: 0.5
        transformOrigin: Item.TopLeft
        width: parent.width / scale
        height: parent.height / scale
    }

    Timer {
        interval: 35000
        onTriggered: webView.reload();
        running: webWindow.visible
        repeat: true
    }

    function keyPressed(ev)
    {
         if( ev.key === Qt.Key_Escape )
            topWindow.reset();
    }
}
