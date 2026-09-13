import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root
    property bool opened: false
    property bool allApps: false
    function toggle() { opened = !opened; if (opened) { allApps = false; search.text = ""; search.forceActiveFocus() } }
    function launch(app) {
        opened = false
        if (app.cmd) Quickshell.execDetached(app.cmd)
        else Quickshell.execDetached(["gtk-launch", app.id])
    }
    function icon(app) {
        if (app.custom) return Qt.resolvedUrl(app.custom)
        const entry = app.id ? DesktopEntries.byId(app.id) : null
        return Quickshell.iconPath(app.icon || (entry ? entry.icon : "application-x-executable"))
    }
    readonly property var pinned: [
        {name:"Chrome",id:"google-chrome"},
        {name:"Discord",id:"discord"},
        {name:"Files",id:"org.gnome.Nautilus",custom:"icons/files.svg"},
        {name:"Writer",id:"libreoffice-writer"},
        {name:"Spreadsheets",id:"libreoffice-calc"},
        {name:"Presentations",id:"libreoffice-impress"},
        {name:"ChatGPT",id:"Chatgpt",icon:"chatgpt"},
        {name:"Task Manager",id:"com.tmog.taskmanager",custom:"icons/task-manager.svg"},
        {name:"Settings",icon:"preferences-system",cmd:["omarchy","menu","summon","root"]},
        {name:"Photos",id:"Google Photos"},
        {name:"Paint",id:"com.github.PintaProject.Pinta"},
        {name:"Downloads",icon:"folder-download",cmd:["nautilus","@HOME@/Downloads"]},
        {name:"YouTube",id:"YouTube"},
        {name:"Zoom",id:"Zoom"},
        {name:"WhatsApp",id:"WhatsApp"},
        {name:"Documents",icon:"folder-documents",cmd:["nautilus","@HOME@/Documents"]},
        {name:"Terminal",id:"foot"},
        {name:"Recycle Bin",icon:"user-trash",cmd:["nautilus","trash:///"]}
    ]
    readonly property var results: {
        const query = search.text.toLowerCase()
        const seen = {}
        return DesktopEntries.applications.values.filter(a => {
            if (!a.name || a.noDisplay || seen[a.name.toLowerCase()]) return false
            seen[a.name.toLowerCase()] = true
            return a.name.toLowerCase().includes(query)
        }).sort((a,b) => a.name.localeCompare(b.name))
    }
    IpcHandler {
        target: "windows-start"
        function toggle(): void { root.toggle() }
        function close(): void { root.opened = false }
    }
    PanelWindow {
        id: overlay
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "windows-start-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        MouseArea { anchors.fill: parent; onClicked: root.opened = false }
        Rectangle {
            id: card
            width: Math.min(720, parent.width - 32)
            height: Math.min(780, parent.height - 90)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 66
            radius: 10
            color: "#ed1c2639"
            border.color: "#475164"; border.width: 1
            gradient: Gradient {
                GradientStop { position: 0; color: "#23303d" }
                GradientStop { position: .55; color: "#202851" }
                GradientStop { position: 1; color: "#2c203d" }
            }
            MouseArea { anchors.fill: parent; onClicked: {} }
            Rectangle {
                id: searchBox
                x: 32; y: 32; width: parent.width - 64; height: 46
                radius: 5; color: "#242529"; border.color: "#454a52"
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: "#cb9dde"; radius: 1 }
                Text { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: "#c3c6cd"; font.pixelSize: 28 }
                TextInput {
                    id: search
                    x: 48; width: parent.width - 60; height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    color: "white"; font.family: "sans-serif"; font.pixelSize: 16
                    clip: true; selectByMouse: true
                    Keys.onEscapePressed: root.opened = false
                    Text { anchors.verticalCenter: parent.verticalCenter; visible: !search.text; text: "Type here to search"; color: "#bdc2ca"; font: search.font }
                }
            }
            Text { x: 48; y: 111; text: root.allApps || search.text ? "All apps" : "Pinned"; color: "white"; font.family: "sans-serif"; font.pixelSize: 16; font.bold: true }
            Rectangle {
                x: parent.width - 142; y: 103; width: 100; height: 30; radius: 5
                color: allHover.containsMouse ? "#526079" : "#343d55"
                Text { anchors.centerIn: parent; text: root.allApps ? "‹  Back" : "All apps  ›"; color: "white"; font.family: "sans-serif"; font.pixelSize: 13 }
                MouseArea { id: allHover; anchors.fill: parent; hoverEnabled: true; onClicked: { root.allApps = !root.allApps; search.text = "" } }
            }
            Flickable {
                x: 24; y: 150; width: parent.width - 48
                height: root.allApps || search.text ? card.height - 236 : 302
                contentHeight: appGrid.height
                clip: true
                Grid {
                    id: appGrid
                    columns: root.allApps || search.text ? 4 : 6
                    Repeater {
                        model: root.allApps || search.text ? root.results : root.pinned
                        Rectangle {
                            required property var modelData
                            width: appGrid.parent.width / appGrid.columns; height: 96
                            radius: 5; color: itemHover.containsMouse ? "#22ffffff" : "transparent"
                            Image { width: 36; height: 36; y: 10; anchors.horizontalCenter: parent.horizontalCenter; source: root.icon(modelData); sourceSize.width: 72; sourceSize.height: 72 }
                            Text { x: 3; y: 56; width: parent.width-6; height: 35; text: modelData.name; color: "#f4f4f4"; font.family: "sans-serif"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                            MouseArea { id: itemHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(modelData) }
                        }
                    }
                }
            }
            Column {
                x: 48; y: 477; spacing: 20
                visible: !root.allApps && !search.text
                Text { text: "Quick access"; color: "white"; font.family: "sans-serif"; font.pixelSize: 16; font.bold: true }
                Grid {
                    columns: 2; columnSpacing: 30; rowSpacing: 8
                    Repeater {
                        model: [
                            {name:"Downloads",detail:"Your downloaded files",icon:"folder-download",cmd:["nautilus","@HOME@/Downloads"]},
                            {name:"Documents",detail:"Browse your documents",icon:"folder-documents",cmd:["nautilus","@HOME@/Documents"]},
                            {name:"Task Manager",detail:"Apps and performance",custom:"icons/task-manager.svg",id:"com.tmog.taskmanager"},
                            {name:"Desktop settings",detail:"Appearance and system",icon:"preferences-system",cmd:["omarchy","menu","summon","root"]}
                        ]
                        Rectangle {
                            required property var modelData
                            width: (card.width-126)/2; height: 64; radius: 5
                            color: quickHover.containsMouse ? "#22ffffff" : "transparent"
                            Image { x: 8; y: 16; width: 32; height: 32; source: root.icon(modelData) }
                            Text { x: 52; y: 12; text: modelData.name; color: "white"; font.family: "sans-serif"; font.pixelSize: 14 }
                            Text { x: 52; y: 35; text: modelData.detail; color: "#bbc4d4"; font.family: "sans-serif"; font.pixelSize: 12 }
                            MouseArea { id: quickHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launch(modelData) }
                        }
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom; width: parent.width; height: 70
                color: "#29101728"; radius: 10
                Rectangle { width: parent.width; height: 1; color: "#485268" }
                Rectangle { x: 48; y: 17; width: 36; height: 36; radius: 18; color: "#456980"
                    Text { anchors.centerIn: parent; text: "S"; color: "white"; font.family: "sans-serif"; font.pixelSize: 18 }
                }
                Text { x: 98; anchors.verticalCenter: parent.verticalCenter; text: Quickshell.env("USER"); color: "white"; font.family: "sans-serif"; font.pixelSize: 14 }
                Rectangle {
                    x: parent.width - 86; y: 14; width: 44; height: 44; radius: 5
                    color: powerHover.containsMouse ? "#28ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: "⏻"; color: "white"; font.pixelSize: 24 }
                    MouseArea { id: powerHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.launch({cmd:["omarchy","menu","summon","system"]}) }
                }
            }
        }
    }
}
