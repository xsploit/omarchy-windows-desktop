import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Windows 11 notification center + calendar flyout.
//
// Standalone panel plugin, toggled with
// `omarchy-shell shell toggle subsect.notification-center` (the taskbar clock
// does this via omarchy-win11-notifications). Two stacked acrylic cards sit
// above the taskbar at the bottom-right: notification history on top, a
// month calendar underneath. Click anywhere else, or press Escape, to close.
//
// The history is read straight from the notifications service's on-disk
// history directory rather than through the service object: third-party
// panels only get narrow proxies for first-party services, and the clone we
// run is not on that list. Actions go through the service's IPC target.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string home: Quickshell.env("HOME")
  readonly property string historyDir: home + "/.local/state/omarchy/notifications/history"
  readonly property string imagesDir: home + "/.local/state/omarchy/notifications/images"
  readonly property string settingsPath: home + "/.local/state/omarchy/notifications.json"

  // Windows 11 dark Fluent tokens. Hardcoded on purpose, like the other
  // win11 widgets: this shell is a Windows replica, not a themed surface.
  readonly property color panelBg: Qt.rgba(0.125, 0.125, 0.125, 0.86)
  readonly property color panelBorder: Qt.rgba(1, 1, 1, 0.08)
  readonly property color cardBg: Qt.rgba(1, 1, 1, 0.045)
  readonly property color cardHover: Qt.rgba(1, 1, 1, 0.09)
  readonly property color textColor: "#ffffff"
  readonly property color textDim: Qt.rgba(1, 1, 1, 0.62)
  readonly property color textFaint: Qt.rgba(1, 1, 1, 0.38)
  readonly property color accent: "#60cdff"
  readonly property color accentFill: "#0078d4"
  readonly property string uiFont: "Segoe UI"
  // Nerd Font glyphs (chevrons, bell) live in the shell's mono family.
  readonly property string glyphFont: Style.font.family

  readonly property int panelWidth: 380
  readonly property int gap: 12
  readonly property int barSize: shell && shell.bar ? Math.max(0, shell.bar.barSize || 0) : 40

  // ------------------------------------------------------------ history
  property var rows: []
  property var groups: []
  readonly property int count: rows.length
  property bool dnd: false
  property var now: new Date()

  function refresh() {
    if (readProc.running) return
    readProc.running = true
  }

  function applyHistory(raw) {
    var parsed = Model.parseHistory(raw)
    root.rows = parsed
    root.groups = Model.groupByApp(parsed)
  }

  function dismissEntry(stem) {
    // Same shape the service's own clear uses: the JSON plus any image copy
    // carrying its stem, so nothing is orphaned in images/.
    Quickshell.execDetached(["bash", "-c",
      "rm -f -- \"$1/$3.json\" \"$2/$3\"-*", "--", historyDir, imagesDir, stem])
    refreshSoon.restart()
  }

  function clearAll() {
    Quickshell.execDetached(["omarchy-shell", "notifications", "clear"])
    // The clear goes through the service's file-job queue, so give it a beat.
    refreshSoon.interval = 350
    refreshSoon.restart()
  }

  function toggleDnd() {
    Quickshell.execDetached(["omarchy-shell", "notifications", "toggleDnd"])
    // The service persists DND on a debounced timer; flip locally so the
    // switch answers the click, and let the file watcher settle it.
    root.dnd = !root.dnd
  }

  // ----------------------------------------------------------- calendar
  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth()
  readonly property string todayKey: Model.keyForDate(root.now)
  readonly property var weeks: Model.monthGrid(viewYear, viewMonth, todayKey)
  readonly property bool viewingToday: viewYear === now.getFullYear() && viewMonth === now.getMonth()

  function resetCalendar() {
    var d = new Date()
    root.now = d
    root.viewYear = d.getFullYear()
    root.viewMonth = d.getMonth()
  }

  function moveMonth(delta) {
    var next = Model.stepMonth(root.viewYear, root.viewMonth, delta)
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  // ---------------------------------------------------------- lifecycle
  function open(payloadJson) {
    resetCalendar()
    refresh()
    // Everything in history is "seen" once the center is open; the taskbar
    // bell counts files newer than this mark.
    Quickshell.execDetached(["touch", root.home + "/.local/state/omarchy/notification-center-seen"])
    settingsFile.reload()
    root.opened = true
    Qt.callLater(function() {
      if (root.opened) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
  }

  // Route through the host so its open-state bookkeeping matches ours;
  // a bare close() would leave `toggle` thinking we are still open.
  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "subsect.notification-center")
    else close()
  }

  Process {
    id: readProc
    running: false
    command: ["bash", "-c", "awk 1 \"$1\"/*.json 2>/dev/null || true", "--", root.historyDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyHistory(text)
    }
  }

  Timer {
    id: refreshSoon
    interval: 150
    onTriggered: { root.refresh(); interval = 150 }
  }

  // Keeps "5m" ticking and catches notifications that land while open.
  Timer {
    interval: 5000
    running: root.opened
    repeat: true
    onTriggered: { root.now = new Date(); root.refresh() }
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: true
    onLoaded: root.applyDnd(text())
    onFileChanged: { reload(); root.applyDnd(text()) }
  }

  function applyDnd(raw) {
    try {
      var parsed = JSON.parse(String(raw || "").trim() || "{}")
      if (parsed && typeof parsed.dnd === "boolean") root.dnd = parsed.dnd
    } catch (e) {}
  }

  function iconSource(icon) {
    var value = String(icon || "")
    if (value.length === 0) return ""
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return "file://" + value
    return Quickshell.iconPath(value, true)
  }

  // --------------------------------------------------------------- window
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "win11-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Click-away scrim. Invisible: Windows does not dim the desktop for this
    // flyout, it just closes on the next click anywhere else.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.dismiss()
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.dismiss()
    }

    // Plain Item wrapper: the click-swallowing MouseArea must not be a
    // layout child (anchors inside a layout are undefined behaviour), so it
    // and the ColumnLayout are siblings here instead.
    Item {
      id: flyout
      width: root.panelWidth
      height: stack.implicitHeight
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: root.gap
      // Flush on the bar: the wallpaper slot between a flyout and the taskbar
      // read as a seam, so the cards sit directly on the bar's top stroke.
      anchors.bottomMargin: root.barSize

      // Slide up and fade in, the Fluent flyout entrance.
      opacity: root.opened ? 1 : 0
      transform: Translate { y: root.opened ? 0 : 24 }
      Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      // Swallow clicks inside the cards so only the scrim dismisses.
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: function(mouse) { mouse.accepted = true }
      }

    ColumnLayout {
      id: stack
      anchors.fill: parent
      spacing: root.gap

      // ------------------------------------------------ notifications
      Rectangle {
        id: notifCard
        Layout.fillWidth: true
        Layout.preferredHeight: notifColumn.implicitHeight
        radius: 8
        color: root.panelBg
        border.width: 1
        border.color: root.panelBorder
        clip: true

        ColumnLayout {
          id: notifColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          spacing: 0

          // Header
          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 12
            Layout.topMargin: 12
            Layout.bottomMargin: 8

            Text {
              text: "Notifications"
              color: root.textColor
              font.family: root.uiFont
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              visible: root.count > 0
              implicitWidth: clearLabel.implicitWidth + 16
              implicitHeight: 26
              radius: 4
              color: clearMouse.containsMouse ? root.cardHover : "transparent"

              Text {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear all"
                color: clearMouse.containsMouse ? root.textColor : root.textDim
                font.family: root.uiFont
                font.pixelSize: 12
              }

              MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAll()
              }
            }
          }

          // Empty state
          Item {
            visible: root.count === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 150

            Column {
              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂚"
                color: root.textFaint
                font.family: root.glyphFont
                font.pixelSize: 34
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No new notifications"
                color: root.textDim
                font.family: root.uiFont
                font.pixelSize: 13
              }
            }
          }

          // List
          Flickable {
            visible: root.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(listColumn.implicitHeight, 420)
            contentHeight: listColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: listColumn
              width: parent.width
              spacing: 10

              Repeater {
                model: root.groups

                ColumnLayout {
                  id: group
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.leftMargin: 12
                  Layout.rightMargin: 12
                  spacing: 4

                  // Group header: app icon + name, the way Windows stacks a
                  // sender's notifications under one label.
                  RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 6

                    Image {
                      source: root.iconSource(group.modelData.appIcon)
                      sourceSize.width: 16 * Screen.devicePixelRatio
                      sourceSize.height: 16 * Screen.devicePixelRatio
                      width: 16; height: 16
                      visible: status === Image.Ready
                      asynchronous: true
                    }

                    Text {
                      Layout.fillWidth: true
                      text: group.modelData.app || "App"
                      color: root.textDim
                      font.family: root.uiFont
                      font.pixelSize: 12
                      elide: Text.ElideRight
                    }
                  }

                  Repeater {
                    model: group.modelData.items

                    Rectangle {
                      id: card
                      required property var modelData
                      Layout.fillWidth: true
                      implicitHeight: cardRow.implicitHeight + 20
                      radius: 6
                      color: cardMouse.containsMouse ? root.cardHover : root.cardBg

                      MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                      }

                      RowLayout {
                        id: cardRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 10

                        // Per-notification image (avatar, thumbnail) first,
                        // then the app icon, then a glyph, then nothing.
                        Item {
                          Layout.preferredWidth: 32
                          Layout.preferredHeight: 32
                          Layout.alignment: Qt.AlignTop
                          visible: cardImage.status === Image.Ready || card.modelData.glyph.length > 0

                          Image {
                            id: cardImage
                            anchors.fill: parent
                            source: root.iconSource(card.modelData.image.length > 0 ? card.modelData.image : card.modelData.appIcon)
                            sourceSize.width: 32 * Screen.devicePixelRatio
                            sourceSize.height: 32 * Screen.devicePixelRatio
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                          }

                          Text {
                            anchors.centerIn: parent
                            visible: cardImage.status !== Image.Ready
                            text: card.modelData.glyph
                            color: root.textColor
                            font.family: root.glyphFont
                            font.pixelSize: 22
                          }
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 2

                          RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                              Layout.fillWidth: true
                              text: card.modelData.summary
                              color: root.textColor
                              font.family: root.uiFont
                              font.pixelSize: 13
                              font.weight: Font.DemiBold
                              wrapMode: Text.WordWrap
                              elide: Text.ElideRight
                              maximumLineCount: 2
                              textFormat: Text.PlainText
                            }

                            Text {
                              text: Model.timeAgo(card.modelData.timestamp, root.now.getTime())
                              color: root.textFaint
                              font.family: root.uiFont
                              font.pixelSize: 11
                              Layout.alignment: Qt.AlignTop
                            }
                          }

                          Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: Model.plainBody(card.modelData.body)
                            color: root.textDim
                            font.family: root.uiFont
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 3
                            textFormat: Text.PlainText
                          }
                        }
                      }

                      // Close button, revealed on hover like Windows.
                      Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 22; height: 22; radius: 4
                        visible: cardMouse.containsMouse || closeMouse.containsMouse
                        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                        Text {
                          anchors.centerIn: parent
                          text: "✕"
                          color: root.textColor
                          font.family: root.uiFont
                          font.pixelSize: 10
                        }

                        MouseArea {
                          id: closeMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.dismissEntry(card.modelData.fileStem)
                        }
                      }
                    }
                  }
                }
              }

              Item { Layout.preferredHeight: 2 }
            }
          }

          // Focus assist row
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.panelBorder
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 10
            Layout.bottomMargin: 12
            spacing: 10

            Text {
              text: root.dnd ? "󰂛" : "󰂚"
              color: root.dnd ? root.accent : root.textDim
              font.family: root.glyphFont
              font.pixelSize: 15
            }

            Text {
              Layout.fillWidth: true
              text: "Do not disturb"
              color: root.textColor
              font.family: root.uiFont
              font.pixelSize: 13
            }

            ToggleSwitch {
              checked: root.dnd
              accent: root.accentFill
              foreground: root.textColor
              onToggled: root.toggleDnd()
            }
          }
        }
      }

      // ------------------------------------------------------ calendar
      Rectangle {
        id: calCard
        Layout.fillWidth: true
        Layout.preferredHeight: calColumn.implicitHeight + 24
        radius: 8
        color: root.panelBg
        border.width: 1
        border.color: root.panelBorder

        ColumnLayout {
          id: calColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          spacing: 6

          // Month header with stepping chevrons.
          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 2
            spacing: 4

            Rectangle {
              implicitWidth: monthLabel.implicitWidth + 12
              implicitHeight: 28
              radius: 4
              color: monthMouse.containsMouse ? root.cardHover : "transparent"

              Text {
                id: monthLabel
                anchors.centerIn: parent
                text: Model.monthTitle(root.viewYear, root.viewMonth)
                color: root.textColor
                font.family: root.uiFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: monthMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.viewingToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.resetCalendar()
              }
            }

            Item { Layout.fillWidth: true }

            Repeater {
              model: [{ glyph: "󰅃", delta: -1 }, { glyph: "󰅀", delta: 1 }]

              Rectangle {
                required property var modelData
                implicitWidth: 30; implicitHeight: 28; radius: 4
                color: chevMouse.containsMouse ? root.cardHover : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.glyph
                  color: root.textColor
                  font.family: root.glyphFont
                  font.pixelSize: 16
                }

                MouseArea {
                  id: chevMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.moveMonth(parent.modelData.delta)
                }
              }
            }
          }

          // Weekday row
          Row {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Repeater {
              model: Model.WEEKDAYS

              Text {
                required property var modelData
                width: calColumn.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: root.textDim
                font.family: root.uiFont
                font.pixelSize: 11
              }
            }
          }

          // Six rows of days; today is the filled accent circle.
          Repeater {
            model: root.weeks

            Row {
              required property var modelData
              Layout.fillWidth: true

              Repeater {
                model: parent.modelData

                Item {
                  id: dayCell
                  required property var modelData
                  width: calColumn.width / 7
                  height: 38

                  Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 16
                    color: dayCell.modelData.today
                      ? root.accentFill
                      : (dayMouse.containsMouse ? root.cardHover : "transparent")
                    border.width: dayCell.modelData.today && dayMouse.containsMouse ? 1 : 0
                    border.color: root.accent
                  }

                  Text {
                    anchors.centerIn: parent
                    text: dayCell.modelData.day
                    color: dayCell.modelData.today
                      ? "#ffffff"
                      : (dayCell.modelData.inMonth ? root.textColor : root.textFaint)
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: dayCell.modelData.today ? Font.DemiBold : Font.Normal
                  }

                  MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                  }
                }
              }
            }
          }
        }
      }
    }
    }
  }
}
