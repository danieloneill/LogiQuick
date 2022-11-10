import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: pvtest

    width: 320
    height: 240

    focus: true
    color: 'black'

    property string hostname: '192.168.0.31'
    property int port: 3131

    property real inputWattage: 375.5
    property real outputWattage: 185.3
    property real soc: 88.7

    BusyIndicator {
        id: busyIndicator
        anchors {
            top: parent.top
            left: parent.left
            margins: 5
        }
        running: true
    }

    Label {
        id: statusLabel
        anchors {
            verticalCenter: busyIndicator.verticalCenter
            left: busyIndicator.right
            leftMargin: 10
        }

        text: qsTr('Charging...')
    }

    Item {
        id: centreContainer
        anchors {
            top: busyIndicator.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        GridLayout {
            anchors.centerIn: parent

            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Label {
                Layout.columnSpan: 2
                Layout.bottomMargin: 20
                text: qsTr('Connected to ') + pvtest.hostname + ':' + pvtest.port
            }

            Label { text: qsTr('Input:') }
            Label { text: pvtest.inputWattage.toFixed(1)+'w' }

            Label { text: qsTr('Output:') }
            Label { text: pvtest.outputWattage.toFixed(1)+'w' }

            Label { text: qsTr('SoC:') }
            Label { text: pvtest.soc.toFixed(1)+'%' }
        }
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        onTriggered: {
            const rnd = (Math.random() * 10) - 5;
            pvtest.inputWattage = 375.5 + rnd;
            pvtest.outputWattage = 185.3 + rnd;
            pvtest.soc = 88.7 + (rnd*0.1);
        }
    }

    Connections {
        target: LogiView
        function onGKeyPressed(key) {
             if( key === Qt.Key_HomePage )
                topWindow.reset();
        }
    }
}
