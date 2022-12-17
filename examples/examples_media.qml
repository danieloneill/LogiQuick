import QtQuick 2.15
import QtQuick.Dialogs 1.3
//import QtMultimedia 5.15
import QtAV 1.7

Rectangle {
    id: mediaWindow
    width: 320
    height: 240
    color: 'black'

    Connections {
        target: LogiView
        function onGKeyPressed(key) {

            if( key === Qt.Key_Go )
            {
                if( player.playbackState == MediaPlayer.PausedState )
                    player.play();
                else
                    player.pause();
            }
            else if( key === Qt.Key_Up )
                player.cycleSubtitleTrack();
            else if( key === Qt.Key_Left )
                player.cycleAudioTrack();
            else if( key === Qt.Key_HomePage )
                topWindow.reset();
            else if( key === Qt.Key_Right )
            {
                player.source = LogiView.getOpenFileName(qsTr("Select a file..."), "", qsTr("Media Files (*.mp4 *.mkv *.webm *.avi *.mpeg *.ts *.ps *.rmvb)"));
                player.play();
            }
            else if( key === Qt.Key_Down )
                player.muted = !player.muted;
        }
    }
/*
    MediaPlayer {
        id: player
        loops: MediaPlayer.Infinite
        muted: true

        onErrorChanged: {
            console.log(`Error: ${error} -> ${errorString}`);
        }

        function cycleSubtitleTrack() {
            console.log(`Subtitle track selection isn't supported.`);
        }

        function cycleAudioTrack() {
            console.log(`Audio track selection isn't supported.`);
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        source: player
    }
*/

    Video {
        id: player
        anchors.fill: parent
        autoLoad: true
        muted: true

        metaData.onTitleChanged: {
            console.log(`Now playing: "${metaData.title}"`);
            console.log(` \`-> "${metaData.subTitle}"`);
        }

        onStatusChanged: {
            console.log(`Status => ${status} (Loaded = ${MediaPlayer.Loaded})`);
            if( status === MediaPlayer.Loaded )
            {
                //setAudio('jpn');
                setSubtitle('eng');
            }
            player.play();
        }

        onErrorChanged: {
            console.log(`Error: ${error} -> ${errorString}`);
        }

        function setAudio(lang) {
            for( let a=0; a < internalAudioTracks.length; a++ )
            {
                let ent = internalAudioTracks[a];
                if( ent['language'] === lang )
                {
                    audioTrack = a;
                    console.log(`Audio track switched to: ${JSON.stringify(ent,null,2)}`);
                    return;
                }
            }
        }

        function setSubtitle(lang) {
            for( let a=0; a < internalSubtitleTracks.length; a++ )
            {
                let ent = internalSubtitleTracks[a];
                if( ent['language'] === lang )
                {
                    internalSubtitleTrack = a;
                    console.log(`Subtitle track switched to: ${JSON.stringify(ent,null,2)}`);
                    return;
                }
            }
        }

        function cycleSubtitleTrack() {
            console.log(`Subtitle tracks: ${internalSubtitleTrack} / ${JSON.stringify(internalSubtitleTracks,null,2)}`);

            for( let a=0; a < internalSubtitleTracks.length; a++ )
            {
                let ent = internalSubtitleTracks[a];
                if( ent['id'] > internalSubtitleTrack )
                {
                    internalSubtitleTrack = a;
                    console.log(`Subtotal track switched to: ${JSON.stringify(ent,null,2)}`);
                    return;
                }
            }
            internalSubtitleTrack = 0;
            console.log(`Subtotal track switched to: ${JSON.stringify(internalSubtitleTracks[0],null,2)}`);
        }

        function cycleAudioTrack() {
            console.log(`Audio tracks: ${audioTrack} / ${JSON.stringify(internalAudioTracks,null,2)}`);

            for( let a=0; a < internalAudioTracks.length; a++ )
            {
                let ent = internalAudioTracks[a];
                if( ent['id'] > audioTrack )
                {
                    audioTrack = a;
                    console.log(`Audio track switched to: ${JSON.stringify(ent,null,2)}`);
                    return;
                }
            }
            audioTrack = 0;
            console.log(`Audio track switched to: ${JSON.stringify(internalAudioTracks[0],null,2)}`);
        }
    }

    Item {
        width: 16*3
        height: 16*3
        opacity: 0.3

        anchors {
            top: parent.top
            right: parent.right
            margins: 3
        }

        Grid {
            anchors.fill: parent
            columns: 3

            Item {
                height: 16
                width: 16
            }
            Rectangle {
                height: 16
                width: 16
                Text {
                    anchors.centerIn: parent
                    font.pointSize: 6
                    text: '⏯️'
                }
            }
            Item {
                height: 16
                width: 16
            }

            Rectangle {
                height: 16
                width: 16
                Text {
                    anchors.centerIn: parent
                    font.pointSize: 6
                    text: '✖'
                }
            }
            Item {
                height: 16
                width: 16
            }
            Rectangle {
                height: 16
                width: 16
                Text {
                    anchors.centerIn: parent
                    font.pointSize: 6
                    text: '📁'
                }
            }

            Item {
                height: 16
                width: 16
            }
            Rectangle {
                height: 16
                width: 16
                Text {
                    anchors.centerIn: parent
                    font.pointSize: 6
                    text: '🔇'
                }
            }
            Item {
                height: 16
                width: 16
            }
        }
    }
}
