import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15

FocusScope {
    id: topWindow
    width: LogiView ? 320 : 1280
    height: LogiView ? 240 : 720

    Material.theme: Material.Dark

    function reset() {
        mainLoader.clear();
        optionList.forceActiveFocus();
    }

    // Also available are onLeftPressed or onRightPressed,
    // but onXxxReleased will also work:
    Keys.onPressed: function(ev) {
        if( mainLoader.status === Loader.Ready )
        {
            // Just pass input "el cheapo".
            // Input focus without a mouse is a pain in Qt Quick.
            mainLoader.item.keyPressed(ev);
            return;
        }

        if( ev.key === Qt.Key_Up )
            optionList.decrementCurrentIndex();
        else if( ev.key === Qt.Key_Down )
            optionList.incrementCurrentIndex();
        else if( ev.key === Qt.Key_Return )
            optionList.currentItem.clicked();
        else if( ev.key === Qt.Key_Escape )
            Qt.quit();
    }

    Rectangle {
        anchors.fill: parent
        color: 'black'

        ListView {
            id: optionList
            //focus: true
            anchors.fill: parent

            highlightFollowsCurrentItem: true
            delegate: Button {
                highlighted: activeFocus
                text: modelData.label
                onClicked: {
                    if( modelData.source )
                    {
                        debugText.text = '';
                        mainLoader.load(modelData.source);
                    } else
                        debugText.text = modelData.label
                }
            }

            model: [
                { 'label':'Media Test', 'source':'media_test.qml' },
                { 'label':'Web Test', 'source':'web_test.qml' },
                { 'label':'Solar PV Test', 'source':'solarpv_test.qml' },
            ]
        }

        Text {
            id: debugText
            anchors {
                top: parent.top
                right: parent.right
                margins: 5
            }
            color: 'white'
            font.pointSize: 8
        }


        // This shouldn't be necessary but it kinda is:
        Component.onCompleted: Qt.callLater( function() { optionList.forceActiveFocus() } );

        // Just some content, I dunno.
        Loader {
            id: mainLoader
            anchors.fill: parent

            function load(inSource) {
                source = inSource;
                visible = true;
            }

            function clear() {
                source = '';
                visible = false;
            }
        }

        // El-cheapo FPS counter:
        Text {
            id: framerate
            color: 'white'
            font.pointSize: 8
            anchors {
                top: parent.top
                left: parent.left
                margins: 5
            }
            text: parent.currentFPS
        }

        property int lastCount: 0
        property real currentFPS: 0
        Timer {
            interval: 1000
            repeat: true
            running: true
            onTriggered: {
                parent.currentFPS = LogiView.currentFrame - parent.lastCount;
                parent.lastCount = LogiView.currentFrame;
            }
        }
    }
}
