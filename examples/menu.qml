import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15

FocusScope {
    id: topWindow
    width: LogiView ? 320 : 1280
    height: LogiView ? 240 : 720

    Material.theme: Material.Dark

    function loadExamples() {
        LogiView.load("examples.qml");
    }

    Connections {
        target: LogiView
        function onGKeyPressed(key) {
            if( key === Qt.Key_Up )
                optionList.decrementCurrentIndex();
            else if( key === Qt.Key_Down )
                optionList.incrementCurrentIndex();
            else if( key === Qt.Key_Go )
                optionList.currentItem.clicked();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: 'black'

        ListView {
            id: optionList
            anchors.fill: parent

            highlightFollowsCurrentItem: true
            delegate: Button {
                highlighted: activeFocus
                text: modelData.label
                onClicked: {
                    if( modelData.action === 'load' )
                        LogiView.showLoadDialogue();
                    else if( modelData.action === 'examples' )
                        topWindow.loadExamples();
                    else if( modelData.action === 'quit' )
                        Qt.quit();
                }
            }

            model: [
                { 'label':'Load File', 'action':'load' },
                { 'label':'Examples...', 'action':'examples' },
                { 'label':'Quit', 'action':'quit' },
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

        Component.onCompleted: Qt.callLater( function() { optionList.forceActiveFocus() } );
    }
}
