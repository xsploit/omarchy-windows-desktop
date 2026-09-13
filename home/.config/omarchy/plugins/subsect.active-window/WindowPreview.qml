import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetWindow: null
    property var controller: null
    property real anchorX: 960
    property bool opened: false
    property bool ownerHovered: false
    readonly property bool hasContent: capture.hasContent
    function show(window, x) {
        targetWindow = window; anchorX = x; ownerHovered = true
        hideDelay.stop(); showDelay.restart()
    }
    function leave() { ownerHovered = false; showDelay.stop(); hideDelay.restart() }
    function close() { opened = false; showDelay.stop(); hideDelay.stop(); targetWindow = null }
    Timer { id: showDelay; interval: 450; onTriggered: if (root.targetWindow && root.ownerHovered) root.opened = true }
    Timer { id: hideDelay; interval: 280; onTriggered: if (!root.ownerHovered && !hover.hovered) root.close() }
    Connections { target: root.targetWindow; function onClosed() { root.close() } }
    PanelWindow {
        id: panel
        visible: root.opened && root.targetWindow !== null
        anchors { bottom: true; left: true }
        margins.bottom: 60
        margins.left: Math.max(8, Math.min(screen.width - 328, root.anchorX - 160))
        implicitWidth: 320; implicitHeight: 232
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
            Text {
                x: 12; y: 10; width: parent.width - 56; height: 24
                text: root.targetWindow ? root.targetWindow.title || root.targetWindow.appId : ""
                color: "white"; font.family: "sans-serif"; font.pixelSize: 13; elide: Text.ElideRight
            }
            Rectangle {
                x: parent.width - 38; y: 5; width: 30; height: 30; radius: 4
                color: closeMouse.containsMouse ? "#c42b1c" : "transparent"
                Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 22; color: "white" }
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { if (root.targetWindow) root.targetWindow.close(); root.close() } }
            }
            Rectangle {
                x: 8; y: 40; width: parent.width - 16; height: 162
                color: "#151b27"; radius: 4; clip: true
                ScreencopyView {
                    id: capture
                    anchors.centerIn: parent
                    constraintSize: Qt.size(parent.width, parent.height)
                    captureSource: panel.visible ? root.targetWindow : null
                    live: panel.visible
                    paintCursor: false
                }
                Image {
                    anchors.centerIn: parent; width: 48; height: 48
                    visible: !capture.hasContent
                    source: root.targetWindow ? root.controller.appIcon(root.targetWindow) : ""
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.targetWindow) {
                            if (root.controller.isMinimized(root.targetWindow)) root.controller.windowCommand("restore", root.targetWindow)
                            else root.controller.windowCommand("activate", root.targetWindow)
                        }
                        root.close()
                    }
                }
            }
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter
                text: root.targetWindow && root.controller.isMinimized(root.targetWindow) ? "Minimized — click to restore" : "Click preview to switch • Right-click icon for options"
                color: "#bdc9dc"; font.family: "sans-serif"; font.pixelSize: 11
            }
        }
    }
}
