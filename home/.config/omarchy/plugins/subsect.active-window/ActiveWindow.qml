import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "subsect.active-window"
    readonly property var windows: ToplevelManager.toplevels.values
    readonly property var active: ToplevelManager.activeToplevel
    readonly property color ink: "#f4f4f4"
    visible: !vertical
    implicitWidth: mainRow.implicitWidth
    implicitHeight: barSize

    StartMenu { id: startMenu }
    DesktopIcons {}
    WindowMenu { id: windowMenu; controller: root }
    WindowPreview { id: windowPreview; controller: root }

    function handleFor(window) {
        return Hyprland.toplevels.values.find(t => t.wayland === window) || null
    }
    function isMaximized(window) {
        const handle = handleFor(window)
        return handle && handle.lastIpcObject.fullscreen === 1
    }
    function isMinimized(window) {
        const handle = handleFor(window)
        return handle && handle.workspace && handle.workspace.name === "special:desktop-minimized"
    }
    function windowCommand(action, window) {
        const handle = handleFor(window)
        if (handle) Quickshell.execDetached(["@HOME@/.local/bin/desktop-windows", action, "0x" + handle.address.replace(/^0x/, "")])
    }

    IpcHandler {
        target: "desktop-controls"
        function menuFor(address: string): void {
            const t = Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, "") === address.replace(/^0x/, ""))
            if (t && t.wayland) windowMenu.open(t.wayland, 960)
        }
        function previewFor(address: string): void {
            const t = Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, "") === address.replace(/^0x/, ""))
            if (t && t.wayland) windowPreview.show(t.wayland, 960)
        }
        function previewStatus(): string { return windowPreview.opened + " " + windowPreview.hasContent }
        function closePreview(): void { windowPreview.close() }
        function closeMenu(): void { windowMenu.opened = false }
        function maximizeActive(): void { if (root.active) root.windowCommand("maximize", root.active) }
        function minimizeActive(): void { if (root.active) root.windowCommand("minimize", root.active) }
        function toggleWindow(address: string): void {
            const t = Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, "") === address.replace(/^0x/, ""))
            if (t && t.wayland) root.windowCommand("toggle", t.wayland)
        }
    }


    function appIcon(window) {
        if (window.appId === "com.tmog.taskmanager") return Qt.resolvedUrl("icons/task-manager.svg")
        if (window.appId === "org.omarchy.agent") return Quickshell.iconPath("utilities-terminal")
        if (window.appId.toLowerCase() === "chatgpt") return "file:///usr/share/icons/hicolor/256x256/apps/chatgpt.png"
        const app = DesktopEntries.heuristicLookup(window.appId)
        return Quickshell.iconPath(app && app.icon ? app.icon : "application-x-executable")
    }

    component DesktopButton: Rectangle {
        id: button
        property string label: ""
        property string tip: label
        property url icon: ""
        property bool selected: false
        property bool running: false
        property bool minimized: false
        property bool danger: false
        property var targetWindow: null
        readonly property bool tooltipHovered: mouse.containsMouse
        signal clicked()
        width: 44
        height: 44
        radius: 5
        color: mouse.pressed ? "#414141" : mouse.containsMouse ? (danger ? "#c42b1c" : "#373737") : selected ? "#303030" : "transparent"
        border.width: selected ? 1 : 0
        border.color: "#424242"
        Behavior on color { ColorAnimation { duration: 110 } }
        Image {
            anchors.centerIn: parent
            width: 28; height: 28
            source: button.icon
            sourceSize.width: 56; sourceSize.height: 56
            fillMode: Image.PreserveAspectFit
            visible: button.icon.toString().length > 0
            opacity: button.minimized ? 0.65 : 1
            scale: mouse.pressed ? 0.88 : 1
            Behavior on scale { NumberAnimation { duration: 110 } }
        }
        Text {
            anchors.centerIn: parent
            visible: button.icon.toString().length === 0
            text: button.label
            color: root.ink
            font.family: "sans-serif"
            font.pixelSize: 22
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            visible: button.running
            width: button.selected ? 18 : 6
            height: 3; radius: 2
            color: button.selected ? "#60cdff" : "#858585"
            Behavior on width { NumberAnimation { duration: 140 } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(event) {
                windowPreview.close()
                if (event.button === Qt.RightButton) {
                    if (root.bar) root.bar.hideTooltip(button)
                    windowMenu.open(button.targetWindow, button.mapToItem(null, button.width/2, 0).x)
                } else button.clicked()
            }
            onEntered: {
                if (button.targetWindow) windowPreview.show(button.targetWindow, button.mapToItem(null, button.width/2, 0).x)
                else if (root.bar) root.bar.showTooltip(button, button.tip)
            }
            onExited: {
                if (button.targetWindow) windowPreview.leave()
                if (root.bar) root.bar.hideTooltip(button)
            }
        }
    }
    component Divider: Rectangle {
        width: 1; height: 24
        anchors.verticalCenter: parent.verticalCenter
        color: "#414141"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: function(event) { windowMenu.open(null, mapToItem(null, event.x, event.y).x) }
    }
    Row {
        id: mainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        DesktopButton {
            tip: "Start — all applications"
            Grid {
                anchors.centerIn: parent
                columns: 2; spacing: 2
                Repeater { model: 4; Rectangle { width: 12; height: 12; color: "#51baff" } }
            }
            onClicked: startMenu.toggle()
        }
        DesktopButton {
            tip: "Google Chrome"
            icon: "file:///usr/share/icons/hicolor/256x256/apps/google-chrome.png"
            onClicked: Quickshell.execDetached(["omarchy", "launch", "browser"])
        }
        DesktopButton {
            tip: "Files — browse your computer"
            icon: Qt.resolvedUrl("icons/files.svg")
            onClicked: Quickshell.execDetached(["omarchy", "launch", "nautilus"])
        }
        DesktopButton {
            label: "↓"; tip: "Downloads"
            onClicked: Quickshell.execDetached(["nautilus", "@HOME@/Downloads"])
        }
        DesktopButton {
            label: "⚙"; tip: "Settings"
            onClicked: Quickshell.execDetached(["omarchy", "menu", "toggle", "root"])
        }
        DesktopButton {
            tip: "Task Manager — Dave Plummer’s TMOG"
            icon: Qt.resolvedUrl("icons/task-manager.svg")
            onClicked: Quickshell.execDetached(["@HOME@/.local/bin/tmog-task-manager"])
        }
        Divider {}
        DesktopButton {
            label: "‹"; width: 26
            visible: taskList.contentWidth > taskList.width
            tip: "Previous applications"
            onClicked: taskList.contentX = Math.max(0, taskList.contentX - 196)
        }
        Flickable {
            id: taskList
            width: Math.min(294, tasks.implicitWidth)
            height: 44
            contentWidth: tasks.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            Row {
                id: tasks
                spacing: 5
                Repeater {
                    model: root.windows
                    DesktopButton {
                        required property var modelData
                        targetWindow: modelData
                        tip: (modelData.title || modelData.appId) + (root.isMinimized(modelData) ? " — click to restore" : " — click to switch or minimize")
                        icon: root.appIcon(modelData)
                        selected: modelData.activated
                        running: true
                        minimized: root.isMinimized(modelData)
                        onClicked: root.windowCommand("toggle", modelData)
                    }
                }
            }
        }
        DesktopButton {
            label: "›"; width: 26
            visible: taskList.contentWidth > taskList.width
            tip: "More applications"
            onClicked: taskList.contentX = Math.min(taskList.contentWidth - taskList.width, taskList.contentX + 196)
        }
        Divider {}
        DesktopButton {
            label: "⏻"; tip: "Power — lock, sleep, restart, or shut down"
            onClicked: Quickshell.execDetached(["omarchy", "menu", "toggle", "system"])
        }
    }
}
