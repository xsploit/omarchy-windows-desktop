import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    function open(cmd) { Quickshell.execDetached(cmd) }
    ContextMenu { id: desktopMenu }
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "windows-desktop-icons"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // Preferred wallpaper is a local file that is not redistributed; fall back
        // to the packaged SVG on machines that do not have it.
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: "file://@HOME@/.config/omarchy-undercover/wallpapers/win11_bloom_dark.jpg"
            onStatusChanged: if (status === Image.Error) source = "file://@HOME@/.config/omarchy-undercover/wallpapers/desktop.svg"
        }
        // Right-click on bare wallpaper opens the Windows desktop menu. Declared
        // before the icon column so icons stay on top and keep their own clicks.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: function(mouse) { desktopMenu.openAt(mouse.x, mouse.y) } }
        Column {
            x: 12; y: 12; spacing: 12
            Repeater {
                model: [
                    {name:"Recycle Bin",icon:"user-trash",cmd:["nautilus","trash:///"]},
                    {name:"This PC",icon:"computer",cmd:["nautilus","computer:///"]},
                    {name:"Google Chrome",icon:"google-chrome",cmd:["omarchy","launch","browser"]},
                    {name:"Discord",icon:"discord",cmd:["gtk-launch","discord"]},
                    {name:"Files",custom:"icons/files.svg",cmd:["nautilus"]},
                    {name:"Downloads",icon:"folder-download",cmd:["nautilus","@HOME@/Downloads"]},
                    {name:"Task Manager",custom:"icons/task-manager.svg",cmd:["@HOME@/.local/bin/tmog-task-manager"]}
                ]
                Rectangle {
                    required property var modelData
                    width: 96; height: 100; radius: 4
                    color: mouse.containsMouse ? "#20ffffff" : "transparent"
                    border.width: mouse.containsMouse ? 1 : 0; border.color: "#45ffffff"
                    Image { y: 7; anchors.horizontalCenter: parent.horizontalCenter; width: 46; height: 46; source: modelData.custom ? Qt.resolvedUrl(modelData.custom) : Quickshell.iconPath(modelData.icon); sourceSize.width: 92; sourceSize.height: 92 }
                    Text { x: 3; y: 61; width: parent.width - 6; text: modelData.name; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; style: Text.Outline; styleColor: "#80000000" }
                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onDoubleClicked: root.open(modelData.cmd) }
                }
            }
        }
    }
}
