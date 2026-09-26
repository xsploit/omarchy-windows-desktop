import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetWindow: null
    property var controller: null
    property bool opened: false
    property bool confirming: false
    property real anchorX: 960
    function open(window, x) { targetWindow = window; anchorX = x; confirming = false; opened = true }
    function run(action) {
        if (targetWindow) {
            if (action === "close") targetWindow.close()
            else controller.windowCommand(action, targetWindow)
        }
        opened = false
    }
    PanelWindow {
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "windows-taskbar-menu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: root.opened = false }
        Rectangle {
            x: Math.max(8, Math.min(parent.width - width - 8, root.anchorX - width/2))
            anchors.bottom: parent.bottom; anchors.bottomMargin: 44
            width: 274; height: content.height + 20
            radius: 8; color: "#252b39"; border.color: "#515967"
            MouseArea { anchors.fill: parent; onClicked: {} }
            Column {
                id: content
                x: 10; y: 10; width: parent.width - 20; spacing: 3
                Text {
                    width: parent.width - 12; x: 6
                    text: root.targetWindow ? root.targetWindow.title || root.targetWindow.appId : "Taskbar"
                    color: "#bac5d7"; font.family: "sans-serif"; font.pixelSize: 12
                    elide: Text.ElideRight; height: 26
                }
                Text {
                    visible: root.confirming
                    width: parent.width - 12; x: 6
                    text: "Force-close this app? All its windows may close and unsaved work may be lost."
                    color: "white"; font.family: "sans-serif"; font.pixelSize: 13
                    wrapMode: Text.Wrap; height: visible ? implicitHeight + 14 : 0
                }
                Repeater {
                    model: root.confirming ? [
                        {label:"End task", action:"end-task", danger:true},
                        {label:"Cancel", action:"cancel"}
                    ] : root.targetWindow ? [
                        {label:root.controller.isMinimized(root.targetWindow) ? "Restore window" : "Minimize",action:root.controller.isMinimized(root.targetWindow) ? "restore" : "minimize"},
                        {label:root.controller.isMaximized(root.targetWindow) ? "Restore size" : "Maximize",action:"maximize"},
                        {label:"Fit window to screen",action:"fit"},
                        {label:"Close window",action:"close"},
                        {label:"End task…",action:"confirm",danger:true},
                        {label:"Task Manager",action:"task-manager"},
                        {label:"Center taskbar",action:"center-undercover-taskbar"}
                    ] : [
                        {label:"Task Manager",action:"task-manager"},
                        {label:"Center taskbar",action:"center-undercover-taskbar"}
                    ]
                    Rectangle {
                        required property var modelData
                        width: content.width; height: 36; radius: 4
                        color: mouse.containsMouse ? (modelData.danger ? "#82362e" : "#3b455b") : "transparent"
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: modelData.danger ? "#ffbbb4" : "white"; font.family: "sans-serif"; font.pixelSize: 14 }
                        MouseArea {
                            id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const action = modelData.action
                                if (action === "confirm") root.confirming = true
                                else if (action === "cancel") root.confirming = false
                                else if (action === "task-manager") { root.opened = false; Quickshell.execDetached(["@HOME@/.local/bin/tmog-task-manager"]) }
                                else if (action === "center-undercover-taskbar") { root.opened = false; Quickshell.execDetached(["@HOME@/.local/bin/desktop-windows", "center-undercover-taskbar"]) }
                                else root.run(action)
                            }
                        }
                    }
                }
            }
            focus: true
            Keys.onEscapePressed: root.opened = false
        }
    }
}
