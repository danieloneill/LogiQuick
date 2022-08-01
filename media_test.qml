import QtQuick 2.15
import QtMultimedia 5.15

Rectangle {
    id: mediaWindow
    width: 320
    height: 240
    color: 'black'

    function keyPressed(ev)
    {
        if( ev.key === Qt.Key_Return )
        {
            console.log("Pause/Play");
            if( player.playbackState == MediaPlayer.PausedState )
                player.play();
            else
                player.pause();
        }
        else if( ev.key === Qt.Key_Escape )
            topWindow.reset();
    }

    MediaPlayer {
        id: player
        source: "../LogiQuick/test2.mp4"
        loops: MediaPlayer.Infinite
        autoPlay: true
        muted: true
    }

    VideoOutput {
        id: videoOutput
        source: player
        anchors.fill: parent
    }
}
