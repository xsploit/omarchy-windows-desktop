import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "undercover.win11-clock"

  property var date: new Date()
  property bool isDark: true

  // Responsive scaling based on DPI and bar size
  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0

  implicitWidth: clockBox.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 48

  // Unread notifications: history files newer than the notification center's
  // last-opened mark (it touches the mark on open, so the badge clears itself).
  property int unread: 0

  Process {
    id: unreadProc
    command: ["bash", "-c",
      "d=\"$HOME/.local/state/omarchy/notifications/history\"; s=\"$HOME/.local/state/omarchy/notification-center-seen\"; " +
      "if [ -f \"$s\" ]; then find \"$d\" -name '*.json' -newer \"$s\" 2>/dev/null | wc -l; else find \"$d\" -name '*.json' 2>/dev/null | wc -l; fi"]
    stdout: SplitParser {
      onRead: function(line) { var n = parseInt(line); if (!isNaN(n)) root.unread = n }
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!unreadProc.running) unreadProc.running = true
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.date = new Date()
  }

  // Theme state detection
  FileView {
    id: stateFile
    path: Quickshell.env("HOME") + "/.config/omarchy-undercover/state"
    watchChanges: true
    onLoaded: {
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
  }

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  Rectangle {
    id: clockBox
    anchors.centerIn: parent
    implicitWidth: Math.max(Math.round(76 * root.scaleFactor), clockRow.implicitWidth + Math.round(18 * root.scaleFactor))
    implicitHeight: root.bar ? root.bar.barSize - 8 : 40
    radius: 4
    color: clockMouse.containsMouse
           ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07))
           : "transparent"
    border.color: clockMouse.containsMouse
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                  : "transparent"
    border.width: 1

    RowLayout {
      id: clockRow
      anchors.centerIn: parent
      spacing: 10

    ColumnLayout {
      id: clockCol
      spacing: 1

      Text {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        text: Qt.formatDateTime(root.date, "h:mm A")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: Math.round(12 * Math.min(1.3, root.scaleFactor))
        font.weight: Font.DemiBold
        color: root.isDark ? "#ffffff" : "#1a1a1a"
      }

      Text {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        text: Qt.formatDateTime(root.date, "M/d/yyyy")
        font.family: "Segoe UI, sans-serif"
        font.pixelSize: Math.round(11 * Math.min(1.3, root.scaleFactor))
        color: root.isDark ? Qt.rgba(1, 1, 1, 0.78) : Qt.rgba(0, 0, 0, 0.70)
      }
    }

      // Windows 11 notification bell, right of the clock, with an unread badge.
      Item {
        Layout.preferredWidth: 18
        Layout.preferredHeight: 22
        Layout.alignment: Qt.AlignVCenter

        Text {
          anchors.centerIn: parent
          text: root.unread > 0 ? "󰂚" : "󰂜"
          font.family: Style.font.family
          font.pixelSize: 15
          color: root.isDark ? "#ffffff" : "#1a1a1a"
          opacity: root.unread > 0 ? 1.0 : 0.75
        }

        Rectangle {
          visible: root.unread > 0
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: -3
          anchors.rightMargin: -7
          width: 15; height: 15; radius: 7.5
          color: "#0078d4"
          border.width: 1
          border.color: Qt.rgba(0, 0, 0, 0.35)

          Text {
            anchors.centerIn: parent
            text: root.unread > 9 ? "9+" : root.unread
            font.family: "Segoe UI"
            font.pixelSize: 9
            font.bold: true
            color: "#ffffff"
          }
        }
      }
    }

    MouseArea {
      id: clockMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          root.runCmd("omarchy-win11-settings")
        } else {
          root.runCmd("omarchy-win11-notifications")
        }
      }
    }
  }
}
