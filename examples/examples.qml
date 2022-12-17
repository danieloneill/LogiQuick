import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15

Rectangle {
    id: topWindow
    width: LogiView ? 320 : 1280
    height: LogiView ? 240 : 720

    Material.theme: Material.Dark
    color: Material.background

    function reset() {
        mainLoader.clear();
        optionList.forceActiveFocus();
    }

    Connections {
        target: LogiView
        function onGKeyPressed(key) {
            // We're currently in an example, so don't handle it.
            if( mainLoader.status === Loader.Ready )
                return;

            // To grab focus, only needed for Button highlighting.
            reset();

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

    ListView {
        id: optionList
        focus: true
        anchors.fill: parent

        highlightFollowsCurrentItem: true
        delegate: Button {
            highlighted: activeFocus
            text: modelData.label
            onClicked: {
                if( modelData.source )
                    mainLoader.load(modelData.source);
            }
        }

        model: [
            { 'label':'OwnCast Monitor', 'source':'examples_owncast.qml' },
            { 'label':'Media Test', 'source':'examples_media.qml' },
            { 'label':'Web Test', 'source':'examples_web.qml' },
            { 'label':'Solar PV Test', 'source':'examples_solarpv.qml' },
        ]
    }

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

    FPSCounter {
        anchors {
            top: parent.top
            right: parent.right
            margins: 5
        }
        opacity: 0.33
    }
}
