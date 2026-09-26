import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Hover preview for a taskbar tile. One tile can stand for several windows of
// the same app, so this renders a strip of live thumbnails — one card per
// window — and clicking a card switches to that window directly, instead of
// clicking the tile repeatedly to cycle.
Item {
    id: root
    // The hovered taskbar tile. Item-typed, so it nulls itself when the tile
    // is destroyed — and the taskbar rebuilds every tile whenever any window
    // opens, closes or retitles. Reading the windows live from the tile also
    // drops closed windows from the strip instead of keeping dead cards.
    property Item owner: null
    readonly property var targetWindows: owner && owner.appWindows ? owner.appWindows : []
    property string appName: ""
    property var controller: null
    property real anchorX: 960
    property bool opened: false
    readonly property bool ownerHovered: !!owner && owner.tooltipHovered

    readonly property int count: targetWindows ? targetWindows.length : 0
    readonly property bool grouped: count > 1
    // A single window keeps the old roomy card; a group trades per-card width
    // for seeing them all at once.
    readonly property int cardWidth: grouped ? 196 : 304
    readonly property int shotHeight: grouped ? 108 : 162
    readonly property int panelWidth: Math.min(1480, 16 + count * cardWidth + (count - 1) * 8)
    readonly property int panelHeight: shotHeight + 70

    function show(tile, name, x) {
        owner = tile
        appName = name || ""
        anchorX = x
        hideDelay.stop()
        showDelay.restart()
    }
    function leave() { showDelay.stop(); hideDelay.restart() }
    function close() { opened = false; showDelay.stop(); hideDelay.stop(); owner = null }

    Timer { id: showDelay; interval: 450; onTriggered: if (root.count > 0 && root.ownerHovered) root.opened = true }
    Timer { id: hideDelay; interval: 280; onTriggered: if (!root.ownerHovered && !hover.hovered) root.close() }
    // Failsafe: a tile destroyed mid-hover never sends onExited, which used to
    // leave the preview pinned on screen. Close once nothing is hovered.
    Timer {
        interval: 400; repeat: true; running: root.opened
        onTriggered: if (!root.ownerHovered && !hover.hovered) root.close()
    }

    PanelWindow {
        id: panel
        visible: root.opened && root.count > 0
        anchors { bottom: true; left: true }
        margins.bottom: 44
        margins.left: Math.max(8, Math.min(screen.width - root.panelWidth - 8, root.anchorX - root.panelWidth / 2))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "windows-app-preview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#252c3b"; radius: 8; border.color: "#505e70"

            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hovered) hideDelay.stop()
                    else hideDelay.restart()
                }
            }

            Row {
                id: strip
                x: 8; y: 8
                spacing: 8

                Repeater {
                    model: root.targetWindows

                    Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property var win: modelData
                        width: root.cardWidth
                        height: root.shotHeight + 32

                        Text {
                            x: 4; y: 2
                            width: card.width - 32; height: 22
                            text: card.win ? (card.win.title || card.win.appId || "") : ""
                            color: "white"; font.family: "sans-serif"; font.pixelSize: 12
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            x: card.width - 26; y: 0; width: 24; height: 24; radius: 4
                            color: closeMouse.containsMouse ? "#c42b1c" : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 17; color: "white" }
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.win) card.win.close()
                                    // Closing the last window leaves nothing to preview.
                                    if (root.count <= 1) root.close()
                                }
                            }
                        }

                        Rectangle {
                            y: 26
                            width: card.width; height: root.shotHeight
                            color: "#151b27"; radius: 4; clip: true
                            border.width: shotMouse.containsMouse ? 1 : 0
                            border.color: "#60cdff"

                            ScreencopyView {
                                id: capture
                                anchors.centerIn: parent
                                constraintSize: Qt.size(parent.width, parent.height)
                                captureSource: panel.visible ? card.win : null
                                // Live-capturing every window in a big group is
                                // what made the desktop stutter; beyond two,
                                // refresh a still frame once a second instead.
                                live: panel.visible && root.count <= 2
                                paintCursor: false
                            }

                            Timer {
                                interval: 1000; repeat: true; triggeredOnStart: true
                                running: panel.visible && !capture.live
                                onTriggered: capture.captureFrame()
                            }

                            Image {
                                anchors.centerIn: parent; width: 40; height: 40
                                visible: !capture.hasContent
                                source: card.win && root.controller ? root.controller.appIcon(card.win) : ""
                            }

                            MouseArea {
                                id: shotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.win && root.controller) {
                                        if (root.controller.isMinimized(card.win)) root.controller.windowCommand("restore", card.win)
                                        else root.controller.windowCommand("activate", card.win)
                                    }
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 7
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.grouped
                      ? root.appName + " — " + root.count + " windows • click one to switch, or click the icon to cycle"
                      : "Click preview to switch • Right-click icon for options"
                color: "#bdc9dc"; font.family: "sans-serif"; font.pixelSize: 11
            }
        }
    }
}
