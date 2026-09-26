// User-owned Windows-style Settings. Changes are explicit; opening is read-only.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root
    property string section: Quickshell.env("DESKTOP_SETTINGS_SECTION") || "display"
    property string query: ""
    property var state: ({})
    property string message: ""
    property bool failed: false
    property real textDraft: 1
    property real terminalDraft: 11
    property int hdrDraft: 0
    property real originalText: -1
    property real originalTerminal: -1
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/desktop-settings-control"
    readonly property color foreground: "#f4f4f4"
    readonly property color secondary: "#b4b7c0"
    readonly property color accent: "#60cdff"
    readonly property var categories: [
        {id:"display", label:"Display & brightness", glyph:"▣"},
        {id:"sizing", label:"Text & app sizing", glyph:"Aa"},
        {id:"sound", label:"Sound & devices", glyph:"♫"},
        {id:"network", label:"Network & Bluetooth", glyph:"⌁"},
        {id:"files", label:"Files & storage", glyph:"▱"},
        {id:"personalization", label:"Personalization", glyph:"◐"},
        {id:"input", label:"Keyboard & mouse", glyph:"⌨"},
        {id:"advanced", label:"More settings", glyph:"⚙"}
    ]
    readonly property var cards: [
        {section:"display", title:"HDR brightness", kind:"hdr", keywords:"display brightness exposure luminance", details:"Uses your existing desktop HDR brightness control. Opening Settings does not change its level."},
        {section:"display", title:"Whole-display scaling", kind:"monitor", keywords:"resolution screen dpi scaling monitor refresh rate", details:"Changes the size of everything, including the taskbar and desktop icons. For text without resizing the desktop, use Text & app sizing.", actions:[{id:"display", label:"Advanced display configuration"}]},
        {section:"sizing", title:"GTK application text", kind:"text", keywords:"scale scaling font size accessibility bigger smaller text", details:"Text sizing for GTK apps such as Files. Does not set monitor scale or taskbar/icon dimensions. It is not a universal Chrome, Electron or Qt zoom control; some apps need reopening."},
        {section:"sizing", title:"Terminal text", kind:"terminal", keywords:"foot console font size scaling", details:"Point size for new Foot windows. Keeps your font family, copy/paste bindings and running terminals intact."},
        {section:"sizing", title:"Browser & Electron content zoom", kind:"info", keywords:"chrome claude browser electron web zoom scaling accessibility", details:"In Chrome and apps that support these shortcuts: Ctrl + + makes content larger, Ctrl + − makes it smaller, and Ctrl + 0 resets it. Chrome also has Settings → Appearance → Page zoom. App support varies; GTK text sizing does not replace these controls."},
        {section:"sound", title:"Sound output", keywords:"volume speaker headphones output device", details:"Choose output devices and volume in your sound flyout.", actions:[{id:"sound",label:"Open sound controls"}]},
        {section:"sound", title:"Microphone & input devices", keywords:"microphone recording input audio", details:"The installed sound flyout does not provide full recording-device settings. No microphone settings are changed here. Advanced recording controls are not installed.", unavailable:true},
        {section:"network", title:"Wi-Fi", keywords:"wireless wifi internet network", details:"Open available wireless connections and the Wi-Fi radio control.", actions:[{id:"wifi",label:"Wi-Fi connections"}]},
        {section:"network", title:"Bluetooth", keywords:"bluetooth pairing devices headphones", details:"Open the existing Bluetooth device panel.", actions:[{id:"bluetooth",label:"Bluetooth devices"}]},
        {section:"network", title:"Advanced network settings", keywords:"dns network internet", details:"Native Omarchy network options, including DNS.", actions:[{id:"network",label:"Network options"}]},
        {section:"files", title:"This PC", keywords:"computer drives disk filesystem mount usb files explorer", details:"Your computer, connected volumes and file systems—not just the home folder.", actions:[{id:"computer",label:"Open This PC"},{id:"home",label:"Home"}]},
        {section:"files", title:"Folders & Recycle Bin", keywords:"downloads trash deleted recycle folders", details:"Open your existing folders in Files.", actions:[{id:"downloads",label:"Downloads"},{id:"trash",label:"Recycle Bin"}]},
        {section:"files", title:"Disks & storage", keywords:"disk storage partitions drive usb space", details:"Open the installed Disks utility. Opening it makes no disk changes; formatting and partition operations remain explicit actions inside that app.", actions:[{id:"disks",label:"Open Disks"}]},
        {section:"personalization", title:"Taskbar", keywords:"bar position layout alignment transparency icons", details:"Native taskbar options. Current dimensions, gradient and appearance are left unchanged until you select a setting.", actions:[{id:"taskbar",label:"Taskbar options"}]},
        {section:"personalization", title:"Theme & wallpaper", keywords:"background wallpaper color colour theme personalization", details:"Choose only when you want to replace the current appearance. A theme change can affect your custom styling.", actions:[{id:"wallpaper",label:"Wallpaper"},{id:"theme",label:"Choose theme"}]},
        {section:"personalization", title:"Window appearance", keywords:"gaps rounding border corner animations", details:"Advanced configuration editor for your existing Hyprland appearance. No non-persistent placeholder sliders.", actions:[{id:"appearance",label:"Edit window appearance"}]},
        {section:"input", title:"Keyboard, mouse & touchpad", keywords:"pointer cursor speed sensitivity scroll keyboard layout repeat mouse touchpad", details:"Open your native input configuration. This is an advanced configuration editor, not a graphical input panel.", actions:[{id:"input",label:"Input configuration"}]},
        {section:"input", title:"Keyboard shortcuts", keywords:"hotkeys shortcuts keybindings keys win super", details:"Browse current shortcuts or edit your user bindings.", actions:[{id:"shortcuts",label:"Browse shortcuts"},{id:"edit-shortcuts",label:"Edit shortcuts"}]},
        {section:"advanced", title:"Notifications", keywords:"notifications calendar dnd focus disturb", details:"Notification history, calendar and Do not disturb.", actions:[{id:"notifications",label:"Notification center"}]},
        {section:"advanced", title:"Default applications", keywords:"default apps browser terminal editor associations", details:"Choose supported default applications through Omarchy.", actions:[{id:"defaults",label:"Default applications"}]},
        {section:"advanced", title:"Idle, lock & power", keywords:"sleep suspend lock idle power screensaver timeout", details:"Advanced shell configuration: idle lock/screensaver times are under idle. This opens the configuration editor; it does not suspend or change timers.", actions:[{id:"power",label:"Edit idle configuration"}]},
        {section:"advanced", title:"All native settings", keywords:"setup system security plugins configuration updates settings", details:"Access the installed Omarchy setup menu. No update-status claim is made without checking updates.", actions:[{id:"advanced",label:"Open native setup"}]}
    ]
    readonly property var shownCards: cards.filter(function(card) {
        if (!query.trim()) return card.section === section
        var text = (card.title + " " + card.details + " " + (card.keywords || "")).toLowerCase()
        return query.toLowerCase().trim().split(/\s+/).every(function(word) { return text.indexOf(word) !== -1 })
    })
    function chooseSection(value) {
        section = categories.some(function(c) { return c.id === value }) ? value : "display"
        search.text = ""
        win.visible = true
    }
    function call(args) {
        if (backend.running) return
        message = ""
        failed = false
        backend.command = [helper].concat(args)
        backend.running = true
    }
    function applyResult(text) {
        try {
            var result = JSON.parse(text)
            failed = !result.ok
            message = result.error || result.message || ""
            if (!result.ok || !result.available) return
            state = result
            if (typeof result.textScale === "number") {
                textDraft = result.textScale
                if (originalText < 0) originalText = result.textScale
            }
            if (typeof result.terminalSize === "number") {
                terminalDraft = result.terminalSize
                if (originalTerminal < 0) originalTerminal = result.terminalSize
            }
            if (result.hdr && typeof result.hdr.level === "number") hdrDraft = result.hdr.level
            if (result.warnings.length) {
                message = [message].concat(result.warnings).filter(Boolean).join("\n")
                failed = true
            }
        } catch (error) {
            failed = true
            message = "Could not read settings: " + error
        }
    }
    IpcHandler {
        target: "settings"
        function open(section: string): void { root.chooseSection(section) }
        function status(): string { return JSON.stringify({section:root.section, query:root.query, count:root.shownCards.length, busy:backend.running, message:root.message, state:root.state}) }
    }
    Process {
        id: backend
        stdout: StdioCollector { onStreamFinished: root.applyResult(text) }
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) { root.failed = true; root.message = text.trim() } } }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0 && !root.message) { root.failed = true; root.message = "The settings operation failed (exit " + exitCode + ")." }
        }
    }
    Component.onCompleted: call(["status"])

    FloatingWindow {
        id: win
        title: "Desktop Settings"
        implicitWidth: 1020
        implicitHeight: 730
        minimumSize: Qt.size(840, 560)
        color: "#202126"
        Pane {
            anchors.fill: parent
            padding: 0
            palette.window: "#202126"
            palette.windowText: root.foreground
            palette.text: root.foreground
            palette.base: "#292b32"
            palette.button: "#35373f"
            palette.buttonText: root.foreground
            palette.highlight: "#0078d4"
            palette.highlightedText: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 13
            background: Rectangle { color: "#202126"; border.color: "#45474e"; radius: 10 }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16
                RowLayout {
                    Layout.fillWidth: true
                    Text { text:"⚙  Settings"; color:root.foreground; font.family:"Segoe UI"; font.pixelSize:20; font.bold:true }
                    Item { Layout.fillWidth: true }
                    BusyIndicator { running: backend.running; visible: running; implicitWidth:24; implicitHeight:24 }
                    Button { text:"Refresh"; enabled:!backend.running; onClicked:root.call(["status"]) }
                    Button { text:"Close"; onClicked:Qt.quit() }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 20
                    ColumnLayout {
                        Layout.preferredWidth: 225
                        Layout.fillHeight: true
                        spacing: 8
                        TextField {
                            id: search
                            Layout.fillWidth:true
                            placeholderText:"Find a setting…"
                            selectByMouse:true
                            onTextChanged: root.query = text
                        }
                        Repeater {
                            model: root.categories
                            Button {
                                required property var modelData
                                Layout.fillWidth:true
                                implicitHeight:40
                                text: modelData.glyph + "   " + modelData.label
                                highlighted: root.section === modelData.id && !root.query
                                onClicked: root.chooseSection(modelData.id)
                            }
                        }
                        Item { Layout.fillHeight:true }
                        Text {
                            Layout.fillWidth:true
                            text:"Your desktop, not a mockup.\nAdvanced links open native tools or clearly labelled configuration editors."
                            wrapMode:Text.WordWrap
                            color:root.secondary
                            font.pixelSize:11
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth:true
                        Layout.fillHeight:true
                        spacing:12
                        Text {
                            text:root.query ? "Search results" : (root.categories.find(function(c) {return c.id === root.section}) || root.categories[0]).label
                            color:root.foreground
                            font.family:"Segoe UI"
                            font.pixelSize:26
                            font.bold:true
                        }
                        ScrollView {
                            id: scroll
                            Layout.fillWidth:true
                            Layout.fillHeight:true
                            contentWidth:availableWidth
                            clip:true
                            ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
                            ColumnLayout {
                                width:scroll.availableWidth
                                spacing:12
                                Text {
                                    visible:root.shownCards.length === 0
                                    text:"No matching settings. Try text, drives, sound or mouse."
                                    color:root.secondary
                                    Layout.fillWidth:true
                                    wrapMode:Text.WordWrap
                                }
                                Repeater {
                                    model:root.shownCards
                                    Rectangle {
                                        id: card
                                        required property var modelData
                                        Layout.fillWidth:true
                                        implicitHeight:body.implicitHeight + 32
                                        color:"#2a2c32"
                                        radius:8
                                        border.color:"#40424a"
                                        readonly property string kind:modelData.kind || "links"
                                        readonly property bool isText:kind === "text"
                                        readonly property bool isTerminal:kind === "terminal"
                                        readonly property bool isHdr:kind === "hdr"
                                        readonly property bool adjustable:isText || isTerminal || isHdr
                                        readonly property bool ready:isText ? typeof root.state.textScale === "number" : (isTerminal ? typeof root.state.terminalSize === "number" : (isHdr ? !!root.state.hdr && typeof root.state.hdr.level === "number" && root.state.hdr.enabled === true : false))
                                        readonly property real draft:isText ? root.textDraft : (isTerminal ? root.terminalDraft : root.hdrDraft)
                                        readonly property real saved:isText ? (root.state.textScale || 0) : (isTerminal ? (root.state.terminalSize || 0) : (root.state.hdr ? root.state.hdr.level : 0))
                                        function save(value) { root.call([isText ? "text-size" : (isTerminal ? "terminal-size" : "hdr-level"), String(value)]) }
                                        ColumnLayout {
                                            id:body
                                            x:16; y:16
                                            width:parent.width - 32
                                            spacing:10
                                            Text { Layout.fillWidth:true; text:card.modelData.title; color:root.foreground; font.family:"Segoe UI"; font.pixelSize:15; font.bold:true; wrapMode:Text.WordWrap }
                                            Text { Layout.fillWidth:true; text:card.modelData.details; color:root.secondary; font.family:"Segoe UI"; font.pixelSize:12; wrapMode:Text.WordWrap }
                                            Text {
                                                visible:card.kind === "monitor"
                                                Layout.fillWidth:true
                                                text:root.state.monitors ? root.state.monitors.map(function(m) { return m.name + ": " + Math.round(m.scale*100) + "% display scale" }).join("\n") : "Display state unavailable"
                                                color:root.accent; font.pixelSize:12; wrapMode:Text.WordWrap
                                            }
                                            Text {
                                                visible:card.modelData.unavailable === true
                                                text:"Not available in this panel"
                                                color:root.secondary; font.pixelSize:12
                                            }
                                            ColumnLayout {
                                                visible:card.adjustable
                                                Layout.fillWidth:true
                                                Text {
                                                    Layout.fillWidth:true
                                                    text:card.ready ? (card.isText ? Math.round(card.draft*100) + "% — preview text" : (card.isTerminal ? card.draft.toFixed(1) + " pt" : card.draft + "%")) : "Control unavailable"
                                                    color:root.foreground
                                                    font.pixelSize:card.isText ? 14*root.textDraft : 16
                                                    wrapMode:Text.WordWrap
                                                }
                                                Slider {
                                                    Layout.fillWidth:true
                                                    from:card.isText ? 0.75 : (card.isTerminal ? 6 : 0)
                                                    to:card.isText ? 2 : (card.isTerminal ? 32 : 100)
                                                    stepSize:card.isText ? 0.01 : (card.isTerminal ? 0.5 : 1)
                                                    value:card.draft
                                                    enabled:card.ready && !backend.running
                                                    onMoved: {
                                                        if (card.isText) root.textDraft = value
                                                        else if (card.isTerminal) root.terminalDraft = value
                                                        else root.hdrDraft = Math.round(value)
                                                    }
                                                }
                                                RowLayout {
                                                    Button { text:"Apply"; enabled:card.ready && !backend.running && Math.abs(card.draft-card.saved)>0.00001; onClicked:card.save(card.draft) }
                                                    Button {
                                                        visible:!card.isHdr
                                                        text:"Restore opening value"
                                                        enabled:card.ready && !backend.running && Math.abs(card.saved-(card.isText ? root.originalText : root.originalTerminal))>0.00001
                                                        onClicked:card.save(card.isText ? root.originalText : root.originalTerminal)
                                                    }
                                                    Button { visible:card.isTerminal; text:"New terminal"; enabled:!backend.running; onClicked:root.call(["open","terminal"]) }
                                                }
                                            }
                                            Flow {
                                                Layout.fillWidth:true
                                                spacing:8
                                                Repeater {
                                                    model:card.modelData.actions || []
                                                    Button {
                                                        required property var modelData
                                                        text:modelData.label
                                                        enabled:!backend.running && !!root.state.available && root.state.available[modelData.id] === true
                                                        onClicked:root.call(["open",modelData.id])
                                                        ToolTip.visible:hovered && !enabled
                                                        ToolTip.text:"Unavailable or another operation is running"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            visible:root.message.length > 0
                            Layout.fillWidth:true
                            implicitHeight:notice.implicitHeight+20
                            color:root.failed ? "#4a292d" : "#243b42"
                            radius:6
                            Text { id:notice; x:10; y:10; width:parent.width-20; text:root.message; color:root.foreground; wrapMode:Text.WrapAnywhere; font.pixelSize:12 }
                        }
                    }
                }
            }
        }
    }
}
