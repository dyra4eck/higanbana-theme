import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    property var now: new Date()
    readonly property var kanjiDays: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
    readonly property var months: ["января", "февраля", "марта", "апреля", "мая", "июня",
                                   "июля", "августа", "сентября", "октября", "ноября", "декабря"]

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 460
        Layout.preferredHeight: 240
        Layout.minimumWidth: 220
        Layout.minimumHeight: 120

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.kanjiDays[root.now.getDay()]
                color: "#c4161c"
                font.family: "Noto Serif CJK JP"
                font.pixelSize: 26
                font.letterSpacing: 6
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, "HH:mm")
                color: "#e6e1df"
                font.family: "Inter"
                font.weight: Font.Thin
                font.pixelSize: 112
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 48
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                Layout.bottomMargin: 10
                color: "#8c1016"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.now.getDate() + " " + root.months[root.now.getMonth()] + "  ·  " + root.now.getFullYear()
                color: "#8a8486"
                font.family: "Inter"
                font.pixelSize: 15
                font.letterSpacing: 2
            }
        }
    }
}
