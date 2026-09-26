import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Windows 11 desktop context menu. Opened by DesktopIcons on a right-click
// over the wallpaper; lives on its own Overlay layer so it sits above every
// window. Click anywhere outside the menu, or press Escape, to close.
Item {
  id: root

  property bool opened: false
  property real menuX: 0
  property real menuY: 0

  readonly property int menuWidth: 248
  readonly property int rowHeight: 34
  readonly property string uiFont: "Segoe UI"
  readonly property string glyphFont: Style.font.family
  readonly property string home: Quickshell.env("HOME")

  // Each entry: label, Nerd glyph, and the command it launches. A `sep`
  // entry draws a divider. Refresh has no command: Windows' Refresh just
  // redraws the desktop, and closing the menu is the whole effect here.
  // Other surfaces (the taskbar's own right-click menu) supply their own
  // list; the desktop set below is the default.
  property var entries: defaultEntries
  readonly property var defaultEntries: [
    { label: "View (unavailable)", glyph: "󰕰", disabled: true, cmd: null },
    { label: "Refresh",          glyph: "󰑐", cmd: null },
    { sep: true },
    { label: "New folder",       glyph: "󰉋", cmd: ["bash", "-c", "mkdir -p \"$HOME/Desktop/New folder\" && exec nautilus \"$HOME/Desktop\""] },
    { sep: true },
    { label: "Display settings", glyph: "󰍹", cmd: ["omarchy-win11-settings", "display"] },
    { label: "Personalize",      glyph: "󰏘", cmd: ["omarchy", "menu", "summon", "style.theme"] },
    { sep: true },
    { label: "Open in Terminal", glyph: "",  cmd: ["xdg-terminal-exec"] },
    { label: "Task Manager",     glyph: "󰨇", cmd: [root.home + "/.local/bin/tmog-task-manager"] }
  ]

  function openAt(x, y) {
    menuX = x
    menuY = y
    opened = true
    Qt.callLater(function() { if (root.opened) keyCatcher.forceActiveFocus() })
  }

  function close() { opened = false }

  // Place the menu with its bottom edge `bottom` px above the screen bottom,
  // horizontally at x — how a menu rises from a click on the taskbar.
  function openAbove(x, bottom) {
    openAt(x, panel.height - bottom - menuHeight)
  }

  function activate(entry) {
    close()
    if (entry && !entry.disabled && entry.cmd) Quickshell.execDetached(entry.cmd)
  }

  readonly property int menuHeight: {
    var h = 8
    for (var i = 0; i < entries.length; i++) h += entries[i].sep ? 9 : rowHeight
    return h
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "win11-desktop-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.close()
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.close()
    }

    Rectangle {
      id: menu
      // Keep the whole menu on screen when the click lands near an edge:
      // Windows flips it to open leftward / upward in the same situation.
      x: Math.max(4, Math.min(root.menuX, panel.width - root.menuWidth - 4))
      y: Math.max(4, Math.min(root.menuY, panel.height - root.menuHeight - 4))
      width: root.menuWidth
      height: root.menuHeight
      radius: 8
      color: Qt.rgba(0.16, 0.16, 0.16, 0.9)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.1)

      opacity: root.opened ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 90 } }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        Repeater {
          model: root.entries

          Item {
            id: row
            required property var modelData
            width: menu.width
            height: modelData.sep ? 9 : root.rowHeight

            Rectangle {
              visible: row.modelData.sep === true
              anchors.centerIn: parent
              width: parent.width - 20
              height: 1
              color: Qt.rgba(1, 1, 1, 0.1)
            }

            Rectangle {
              visible: row.modelData.sep !== true
              anchors.fill: parent
              anchors.leftMargin: 5
              anchors.rightMargin: 5
              radius: 4
              color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : "transparent"

              Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                text: row.modelData.glyph || ""
                color: "#ffffff"
                font.family: root.glyphFont
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                x: 42
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.label || ""
                color: row.modelData.disabled ? "#888888" : "#ffffff"
                font.family: root.uiFont
                font.pixelSize: 13
              }

              // Submenu hint (View ▸ Large icons). Display-only for now.
              Text {
                visible: !!row.modelData.sub
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: root.glyphFont
                font.pixelSize: 13
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !row.modelData.disabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.activate(row.modelData)
              }
            }
          }
        }
      }
    }
  }
}
