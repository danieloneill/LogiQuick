import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import QtMultimedia

import Qt.labs.settings

import 'owncast.js' as OwnCast

Rectangle {
    id: chatter
    width: 320
    height: 240

    focus: true
    color: 'black'

    property alias model: chatModel

    property string streamId: settings.value("owncast_streamId", "");
    property string accessToken: settings.value("owncast_accessToken", undefined)
    property string owncastHost: settings.value("owncast_host", undefined)
    property string bgimage: "file:///home/doneill/.steam/debian-installation/steamapps/compatdata/1151340/pfx/drive_c/users/steamuser/Documents/My Games/Fallout 76/Photos/e9462e2a36c6407a833b688dae560b12/Photo_2022-11-19-063339.png"
    property bool timestampsEnabled: true
    property int fadeoutdelay: 600
    property real overlayscale: 1.0

    function sendMessage(message) { return OwnCast.api.sendMessage(message); }

    onWidthChanged: scrollDown();
    onHeightChanged: scrollDown();

    Settings {
        id: settings
    }

    function scrollDown()
    {
        chatView.positionViewAtBeginning();
    }

    function appendMessage(msg)
    {
        msg['timestamp'] = new Date();
        chatModel.insert(0, msg);
        while( chatModel.count > 20 )
            chatModel.remove(chatModel.count-1, 1);

        notifySound.play();
    }

    Component.onCompleted: {
        OwnCast.api.hookChat(function(msg) {
            appendMessage(msg);
        });

        OwnCast.api.create(chatModel);

        if( owncastHost && accessToken )
        {
            OwnCast.api.setHostAndToken( owncastHost, accessToken );
            OwnCast.api.open();
        } else
            settingsWindow.show();
    }

    Timer {
        id: statsTimer
        interval: 10000
        repeat: true
        running: true
        property bool online: false
        onTriggered: {
            //console.log(`Requesting statistics...`);
            OwnCast.api.serverStats( function(resp)
            {
                const json = JSON.parse(resp);

                serverStats.text = `"${json['streamTitle']}" ${json['online'] ? "●" : "○" } [${json['viewerCount']}]`;

                statsTimer.online = json['online'];
                if( !statsTimer.online && streamPlayer.playbackState === MediaPlayer.PlayingState )
                    streamPlayer.stop();
                else if( statsTimer.online && streamPlayer.playbackState !== MediaPlayer.PlayingState )
                    streamPlayer.play();
            } );
        }
    }

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: bgimage
        visible: streamPlayer.playbackState !== MediaPlayer.PlayingState
        smooth: true
    }

    MediaPlayer {
        id: streamPlayer
        source: `${owncastHost}/hls/${streamId.length > 0 ? streamId + '/' : ''}stream.m3u8`
        loops: MediaPlayer.Infinite
        videoOutput: streamView
        audioOutput: streamAudio
    }
    VideoOutput {
        id: streamView
        anchors.fill: parent
    }
    AudioOutput {
        id: streamAudio
        muted: true
    }

    MediaPlayer {
        id: notifySound
        source: 'ding.aac'
        audioOutput: notifyAudio
    }
    AudioOutput {
        id: notifyAudio
    }

    Text {
        id: serverStats
        color: 'pink'
        anchors {
            top: parent.top
            right: parent.right
            margins: 2
        }
        font.pointSize: 8
    }

    Text {
        id: currentTime
        color: 'teal'
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 2
            leftMargin: 25
        }
        font.pointSize: 8
    }

    ListView {
        id: chatView
        anchors.fill: parent
        anchors.margins: 4 * overlayscale
        spacing: 4 * overlayscale
        verticalLayoutDirection: ListView.BottomToTop

        clip: true

        addDisplaced: Transition {
            SmoothedAnimation { properties: "x,y"; duration: 250 }
        }
        removeDisplaced: Transition {
            SmoothedAnimation { properties: "x,y"; duration: 250 }
        }
        add: Transition {
            ParallelAnimation {
                SmoothedAnimation { properties: "y"; duration: 250; from: height }
                PropertyAction { properties: "opacity"; value: 1 }
            }
        }
        remove: Transition {
            PropertyAnimation { properties: "opacity"; duration: 250; to: 0; from: 1 }
        }

        model: chatter.positioning ? demoModel : chatModel
        delegate: Item {
            width: chatView.width
            height: childrenRect.height + 8
            clip: true

            Column {
                x: 4 * overlayscale
                y: 4 * overlayscale
                width: parent.width
                spacing: 3
                clip: true

                ToonLabel {
                    width: parent.width
                    text: type === 'chat' ? styledusername : message
                    color: 'white'
                    font.pointSize: 9 * overlayscale
                }
                ToonLabel {
                    width: parent.width
                    text: ''+timestamp
                    color: 'white'
                    font.pointSize: 6 * overlayscale
                    shadow.radius: 5
                    //shadow.color: '#999900aa'
                    visible: chatter.timestampsEnabled
                }

                ToonLabel {
                    visible: type === 'chat'
                    text: message
                    width: parent.width
                    color: 'white'
                    font.pointSize: 8 * overlayscale
                    shadow.radius: 5
                }
            }
        }

        onModelChanged: scrollDown();
    }

    ListModel { id: chatModel }

    // Only for layering over content, to auto-expire the chat:
    Timer {
        id: chatRemover
        repeat: true
        interval: 5000
        running: true
        onTriggered: {
            var now = new Date();
            for( var j=0; j < chatModel.count; j++ )
            {
                var idx = chatModel.count-1;
                var msg = chatModel.get(idx);
                const ts = new Date(msg['timestamp']);
                if( ts.getTime() + (chatter.fadeoutdelay * 1000) < now.getTime()
                 || chatModel.count > 20 )
                    chatModel.remove(idx, 1);
            }

            // Update current time...
            let ts = new Date();
            let shortTime = `[ ${ts.getHours()}:${(''+ts.getMinutes()).padStart(2, '0')} ]`;
            currentTime.text = shortTime;
        }
    }

    Connections {
        target: LogiView
        function onGKeyPressed(key) {
             if( key === Qt.Key_HomePage )
                topWindow.reset();
             else if( key === Qt.Key_Favorites )
             {
                 if( settingsWindow.visible )
                     settingsWindow.close();
                 else
                     settingsWindow.show();
             }
             else if( key === Qt.Key_Left )
             {
                 console.log("Stopping");
                 streamPlayer.stop();
             }
             else if( key === Qt.Key_Right )
             {
                 const url = `${owncastHost}/hls/${streamId.length > 0 ? streamId + '/' : ''}stream.m3u8`;
                 console.log(`Playing: ${url}`);
                 streamPlayer.source = url;
                 streamPlayer.play();
             }
        }
    }

    Window {
        id: settingsWindow
        width: 500
        height: 280

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Text { text: qsTr('OwnCast Host: (eg; https://my.owncast.stream/)') }
            TextField { id: editOwncastUrl; Layout.fillWidth: true; text: settings.value("owncast_host"); }

            Text { text: qsTr('OwnCast AccessToken: (from <yourhost>/admin/access-tokens/)') }
            TextField { id: editOwncastAccessToken; Layout.fillWidth: true; echoMode: TextInput.Password; text: settings.value("owncast_accessToken"); }

            Text { text: qsTr('Stream Index #: (from <yourhost>/admin/config-video/)') }
            TextField { id: editOwncastStreamId; Layout.fillWidth: true; validator: IntValidator {} text: settings.value("owncast_streamId", ""); }

            Row {
                spacing: 5
                Button { text: qsTr('Save'); onClicked: {
                        const url = editOwncastUrl.text;
                        const token = editOwncastAccessToken.text;
                        const streamId = editOwncastStreamId.text;
                        settings.setValue("owncast_host", url);
                        settings.setValue("owncast_accessToken", token);
                        settings.setValue("owncast_streamId", streamId);
                        chatter.owncastHost = url;
                        chatter.accessToken = token;
                        chatter.streamId = streamId;

                        settingsWindow.close();
                        OwnCast.api.setHostAndToken( owncastHost, accessToken );
                        OwnCast.api.open();
                } }
                Button { text: qsTr('Close'); onClicked: { settingsWindow.close(); } }
            }
        }
    }
}
