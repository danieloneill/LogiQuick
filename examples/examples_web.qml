import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore
import QtWebEngine

FocusScope {
    id: topScope
    width: 320
    height: 240

    Rectangle {
        width: 320
        height: 240
        color: 'black'
        focus: true

        Material.theme: Material.Dark

        Connections {
            target: LogiView
            function onGKeyPressed(key) {
                if( key === Qt.Key_Go )
                {
                    // Toggle fullscreen in Youtube, Netflix, etc.
                    LogiView.postKeyPressed(Qt.Key_F);
                    LogiView.postKeyReleased(Qt.Key_F);
                }
                else if( key === Qt.Key_Up )
                    webview.zoomFactor += 0.20;
                else if( key === Qt.Key_Down )
                    webview.zoomFactor -= 0.20;
                else if( key === Qt.Key_Stop )
                    webview.zoomFactor = 1;
                else if( key === Qt.Key_Left || key === Qt.Key_Right )
                {
                    // Back/forward in stream for Netflix, Youtube, etc.
                    LogiView.postKeyPressed(key);
                    LogiView.postKeyReleased(key);
                }
                else if( key === Qt.Key_Favorites )
                {
                    // Pause in Youtube, Netflix, etc.
                    LogiView.postKeyPressed(Qt.Key_Space);
                    LogiView.postKeyReleased(Qt.Key_Space);
                }
                else if( key === Qt.Key_Launch0 )
                {
                    if( clockLabel.anchors.topMargin >= 0 )
                        clockLabel.anchors.topMargin = 0 - clockLabel.height
                    else
                        clockLabel.anchors.topMargin = 5;
                }
                else if( key === Qt.Key_Launch1 )
                    addressBar.m_showme = !addressBar.m_showme;
                else if( key === Qt.Key_HomePage )
                    topWindow.reset();
                else
                    console.log("Unmapped GKey: "+key);
            }
        }

        Rectangle {
            id: webviewContainer
            color: 'transparent'
            anchors {
                top: webview.isFullScreen ? parent.top : clockLabel.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }

            RowLayout {
                id: addressBar
                property bool m_showme: true

                height: webview.isFullScreen || !m_showme ? 0 : urlentry.implicitHeight
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                TextField {
                    id: urlentry
                    Layout.fillWidth: true
                    text: 'https://www.youtube.com/'
                    onAccepted: {
                        let t = text;
                        if( !t.substr(0,8).includes('://') )
                            t = 'https://' + text;
                        webview.url = t;
                    }

                    Component.onCompleted: accepted()
                }
                ToolButton {
                    text: webview.loading ? '⛔' : '↻'
                    onClicked: {
                        if( webview.loading )
                            webview.stop();
                        else
                            webview.reload();
                    }
                }
                Behavior on height {
                    SmoothedAnimation { duration: 500 }
                }
            }

            WebEngineView {
                id: webview
                anchors {
                    top: addressBar.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                profile {
                    offTheRecord: false
                    storageName: 'LogiQuickWWW'
                    persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
                    httpCacheType: WebEngineProfile.DiskHttpCache
                }
                settings {
                    localStorageEnabled: true
                    pluginsEnabled: true
                    webGLEnabled: true
                }
                onFullScreenRequested: function(req) {
                    req.accept();
                }

                url: ''
                onUrlChanged: urlentry.text = url;
            }
        }

        Text {
            id: clockLabel
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 5
            }

            horizontalAlignment: Text.AlignHCenter
            text: 'Loading...'
            font.family: fl.name
            font.pointSize: webview.isFullScreen ? 8 : 16
            style: Text.Outline
            styleColor: "black"
            color: 'white'

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 500
                }
            }
        }

        Timer {
            interval: 1000 * 10 // 10secs
            onTriggered: {
                const d = new Date();
                const dstr = d.toLocaleString('en-CA');
                if( clockLabel.text === dstr )
                    return;

                clockLabel.text = dstr;
            }
            running: true
            triggeredOnStart: true
            repeat: true
        }

        FontLoader {
            id: fl
            source: 'HWYGWDE.TTF'
        }
    }
}
