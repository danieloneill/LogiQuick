import QtQuick 2.15

Text {
    id: framerate
    
    property real lastTime: (new Date()).getTime();
    property real currentFPS: 0
    property real lastFPS: 0
    
    color: 'white'
    font.pointSize: 8
    
    // Only update once per second to limit triggering
    // redraws. Optionally one can simply do:
    //
    // text: currentFPS
    Timer {
        running: true
        interval: 1000
        repeat: true 
        onTriggered: {
            if( framerate.currentFPS == framerate.lastFPS )
                return;
            
            framerate.lastFPS = framerate.currentFPS;
            framerate.text = framerate.currentFPS.toFixed(1);
        }
    }
    
    Connections {
        target: LogiView
        function onCurrentFrameChanged() {
            const now = new Date();
            const curms = now.getTime();
            const delta = curms - framerate.lastTime;
            framerate.lastTime = curms;

            const fps = 1000/delta;
            framerate.currentFPS = fps;
        }
    }
}

