import QtQuick 2.15
import QtQuick.Dialogs 6
import QtMultimedia 6

Rectangle {
    id: mediaWindow
    width: 320
    height: 240
    color: 'black'

    Connections {
        target: LogiView
        function onGKeyPressed(key) {

            if( key === Qt.Key_Go || key === Qt.Key_Up )
            {
                if( player.playbackState == MediaPlayer.PausedState )
                    player.play();
                else
                    player.pause();
            }
            else if( key === Qt.Key_Left || key === Qt.Key_HomePage )
                topWindow.reset();
            else if( key === Qt.Key_Right )
                player.source = LogiView.getOpenFileName(qsTr("Select a file..."), "", qsTr("Media Files (*.mp4 *.mkv *.webm *.avi *.mpeg *.ts *.ps)"));
            else if( key === Qt.Key_Down )
                audioOutput.muted = !audioOutput.muted;
        }
    }

    MediaPlayer {
        id: player
        //source: "test2.mp4"
        //source: 'https://video-weaver.sea02.hls.ttvnw.net/v1/playlist/CrIF5477kcpqBKieJdTBZgP1Ky8mlgcYQDKKN4QrFyrZA58JKV-3jmD3cS_WDwTOVM8A4WyBwu_kRTzllHKx3RQs4CBCSE1BlQaSHj0Mjz3BGg63T0fLjdYiVLgEC14BsiCKfAEYCSDgF_UezpOYJT9mKDqrp0r8KMOOvmpe7UPo_cX-HnAMsCTJAMb9xfBYX-ly7pQDgHjMCK8GhDzAQCTKYtwU03IN4pfc9Wc9y1Pbpc88FeV5364S3rC_g3b3XIIU8KciFx3bcDRyIHwSC_zCyXbSVN616us6oYHUW06f5k4CnrNE4Vgiep5c07Na5bxL2R5SZybAEizPTJR6cHUdq0EfhzcHPaalMDBKxEgtVoPb6MXQNAcx2JwXw-wolFWLsDAkQzX2QtrFD8F5Gdj_dIu2h8W4OWSaNBN1vckzGvEU59ejlOwzYzK0QmkoXWUxK-0yNflj2Rh4fF3i38cj5yVH4c_tJ-DuXNubRH6Th24pF4tibKCE5Lrq2_ctDMRqxBUjWZdSLCzauUDKv1R5Op04oGfCNVGYXHmrsCSUaY8PweO8UYIaZm5VYvPpY0olev2SKG6LIk70CYH-QwB8vevyd7HModW1QAoQtP3zvZtaNCzwcITje91jkxmYA_fD3zdj3uYrTYmKD-zijDO0wGsMUSyXr5AtO7Hvhm55Yct2yHjVh2Al2oNli0d22xDAnIKbyiyN98K1rmTYKw9x_lPLt00I27X2UU0WjSVZbtvf-dsTt7eiOp2BG4xww0B2XToK71TxKHM8Oy-HRJNRDZV9WwStmVwbzdyp0ucGQtBvxCiQ-D5UepFUF7tj7LEjzp4y4h3Kl4URywOJLs9llBLOSWaaA8fspQ9Q0VgzeqsVbAxMWmdYggUpG1HWHAxNH1IQKCturEhqRoaFnE7KFa94Ggy50AfyiQjsRliAkJwgASoJdXMtZWFzdC0yMMgE.m3u8'
        loops: MediaPlayer.Infinite
        audioOutput: audioOutput
        videoOutput: videoOutput

        onPlaybackStateChanged: {
            console.log(`Media playback state: ${playbackState}`);
        }

        // Hack to make it just friggin' loop:
        onPositionChanged: {
            //console.log(`Pos: ${position}/${duration}`);
            if( position >= duration-80 )
            {
                stop();
                Qt.callLater( function() {
                    player.play();
                } );
            }
        }

        // Hack to 'autostart':
        onMediaStatusChanged: {
            console.log(`Media status: ${mediaStatus} (Pos: ${position}/${duration})`);
            if( mediaStatus === MediaPlayer.LoadedMedia )
                play();
        }

        onErrorOccurred: function(e) {
            console.log(`Error: ${e} -> ${errorString}`);
        }
    }

    AudioOutput {
        id: audioOutput
        muted: true
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    FileDialog {
        id: fileDialog
        title: qsTr('Select a video file...')
        onAccepted: {
            player.source = selectedFile;
            close();
        }
    }

    Item {
        width: 16*3
        height: 16*3
        opacity: 0.3

        anchors {
            top: parent.top
            right: parent.right
            margins: 10
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
