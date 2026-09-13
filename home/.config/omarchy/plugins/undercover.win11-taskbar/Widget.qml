import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Ui
import Quickshell.Hyprland

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

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

    property var indexedApps: []
    FileView {
        path: root.homeDir + "/.config/omarchy-undercover/apps.json"
        watchChanges: true
        onLoaded: { try { root.indexedApps = JSON.parse(text()) } catch(e) {} }
        onFileChanged: reload()
    }
    function appIcon(window) {
        const id = (window.appId || "").toLowerCase()
        if (id === "com.tmog.taskmanager") return Qt.resolvedUrl("icons/task-manager.svg")
        if (id === "org.omarchy.agent") return Quickshell.iconPath("utilities-terminal")
        const indexed = root.indexedApps.find(a =>
            (a.desktopId || "").toLowerCase() === id ||
            (a.startupWMClass || "").toLowerCase() === id)
        if (indexed && indexed.iconUrl) return indexed.iconUrl
        const app = DesktopEntries.heuristicLookup(window.appId)
        if (app && app.icon) {
            if (app.icon.startsWith("/")) return "file://" + app.icon
            return Quickshell.iconPath(app.icon)
        }
        return Quickshell.iconPath("application-x-executable")
    }


  property string homeDir: Quickshell.env("HOME")
  property bool isDark: true
  property var winPinsConfig: ({})

  readonly property real scaleFactor: (false) ? 1.0 : 1.0
  readonly property int tileHeight: Math.max(34, (root.barSize - 8))
  readonly property int tileWidth: Math.round(tileHeight * 1.15)
  readonly property int iconSize: Math.round(tileHeight * 0.60)

  implicitWidth: taskbarRow.implicitWidth + Math.round(24 * root.scaleFactor)
  implicitHeight: root.barSize

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  function matches(tl, matchers) {
    if (!tl || !matchers || matchers.length === 0) return false
    var target = (tl.appId || "").toLowerCase()
    return matchers.some(function(p) { return target === p.toLowerCase() })
  }

  function findRunningToplevel(matchers) {
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    const active = ToplevelManager.activeToplevel
    if (active && root.matches(active, matchers)) return active
    return list.filter(tl => root.matches(tl, matchers)).sort(function(a, b) {
      const ah = root.handleFor(a), bh = root.handleFor(b)
      const ar = ah && ah.lastIpcObject ? ah.lastIpcObject.focusHistoryID : 99999
      const br = bh && bh.lastIpcObject ? bh.lastIpcObject.focusHistoryID : 99999
      return (ar === undefined ? 99999 : ar) - (br === undefined ? 99999 : br)
    })[0]
  }

  function isRunning(matchers) {
    return findRunningToplevel(matchers) !== undefined
  }

  function isFocused(matchers) {
    return root.matches(ToplevelManager.activeToplevel, matchers)
  }

  // Reactive Theme state watcher via FileView
  FileView {
    id: stateWatcher
    path: root.homeDir + "/.config/omarchy-undercover/state"
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

  // Defaults & pinned apps poller via FileView
  FileView {
    id: defaultsFile
    path: root.homeDir + "/.config/omarchy-undercover/defaults.json"
    watchChanges: true
    onLoaded: {
      try {
        var d = JSON.parse(text())
        if (d && d.win11_pins) root.winPinsConfig = d.win11_pins
      } catch(e) {}
    }
    onFileChanged: {
      reload()
      try {
        var d = JSON.parse(text())
        if (d && d.win11_pins) root.winPinsConfig = d.win11_pins
      } catch(e) {}
    }
  }

  // Windows 11 Taskbar Pinned Apps
  property var winApps: [{"id": "start", "name": "Start", "isStart": true, "iconFile": "start.svg", "exec": "omarchy-win11-start", "matchers": []}, {"id": "explorer", "name": "Files", "iconFile": "explorer.svg", "exec": "nautilus", "matchers": ["org.gnome.nautilus"]}, {"id": "browser", "name": "Google Chrome", "iconFile": "google-chrome.svg", "exec": "/usr/bin/google-chrome-stable", "matchers": ["google-chrome"]}, {"id": "terminal", "name": "Terminal", "iconFile": "terminal.svg", "exec": "xdg-terminal-exec", "matchers": ["foot"]}, {"id": "taskmanager", "name": "Task Manager", "iconFile": "task-manager.svg", "exec": "@HOME@/.local/bin/tmog-task-manager", "matchers": ["com.tmog.taskmanager"]}, {"id": "settings", "name": "Settings", "iconFile": "settings.svg", "exec": "omarchy menu summon setup", "matchers": ["undercover-settings"]}]

  function getVisiblePinnedApps() {
    return root.winApps.filter(function(app) {
      if (root.winPinsConfig && root.winPinsConfig[app.id] !== undefined) {
        return root.winPinsConfig[app.id] === true
      }
      return true
    })
  }

  // Dynamically discover all running unpinned applications
  function getUnpinnedRunningApps() {
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    var pinned = root.getVisiblePinnedApps()
    var unpinned = []
    var seenAppIds = {}

    for (var i = 0; i < list.length; i++) {
      var tl = list[i]
      if (!tl) continue
      var isPinned = pinned.some(function(p) { return root.matches(tl, p.matchers) })
      if (!isPinned) {
        var aid = (tl.appId || "app").toLowerCase()
        if (!seenAppIds[aid]) {
          seenAppIds[aid] = true
          unpinned.push({
            id: "running_" + aid,
            name: tl.title || tl.appId || "Application",
            toplevel: tl,
            isStart: false,
            isTaskView: false,
            isDynamic: true,
            appId: tl.appId || "",
            iconFile: "",
            exec: "",
            matchers: [tl.appId || ""]
          })
        }
      }
    }
    return unpinned
  }

  function getAllTaskbarItems() {
    var pinned = root.getVisiblePinnedApps()
    var running = root.getUnpinnedRunningApps()
    return pinned.concat(running)
  }

  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: Math.max(4, Math.round(6 * root.scaleFactor))

    Repeater {
      model: root.getAllTaskbarItems()

      Rectangle {
        id: itemBox
        readonly property bool tooltipHovered: itemMouse.containsMouse
        implicitWidth: root.tileWidth
        implicitHeight: root.tileHeight
        radius: 4

        property bool appRunning: modelData.isDynamic ? true : root.isRunning(modelData.matchers)
        property bool appFocused: root.isFocused(modelData.matchers)
        property var activeTl: root.findRunningToplevel(modelData.matchers)

        color: itemMouse.pressed
               ? (root.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12))
               : (appFocused
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(0, 0, 0, 0.08))
                  : (itemMouse.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"))

        border.color: itemMouse.containsMouse
                      ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                      : "transparent"
        border.width: 1

        scale: itemMouse.pressed ? 0.94 : (itemMouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale {
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        // 1. Windows 11 Start Icon (Vector 4-Square Grid)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          GridLayout {
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
              model: 4
              Rectangle {
                width: Math.round(root.iconSize * 0.40)
                height: Math.round(root.iconSize * 0.40)
                radius: 1
                color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
              }
            }
          }
        }

        // 2. Icon-Only Display with Authentic Windows 11 SVGs
        Item {
          visible: !modelData.isStart && !modelData.isDynamic
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: modelData.isTaskView ? Math.round(root.iconSize * 0.85) : root.iconSize
            height: modelData.isTaskView ? Math.round(root.iconSize * 0.85) : root.iconSize
            source: modelData.iconFile ? "file://" + root.homeDir + "/.local/share/icons/win11/" + modelData.iconFile : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }
        }

        // 3. Dynamic Application Icon (For unpinned running windows)
        Item {
          visible: modelData.isDynamic === true
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            source: itemBox.activeTl ? root.appIcon(itemBox.activeTl) : ""
            fillMode: Image.PreserveAspectFit
            onStatusChanged: if (status === Image.Error) source = Quickshell.iconPath("application-x-executable")
          }
        }

        // 4. Windows 11 Running/Focus Pill Indicator Under Icon
        Rectangle {
          id: bottomIndicator
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          width: itemBox.appFocused ? Math.round(root.tileWidth * 0.45) : 6
          height: 3
          radius: 1.5
          color: itemBox.appFocused ? (root.isDark ? "#60cdff" : "#0067c0") : (root.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.40))

          Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

          onEntered: { if (itemBox.activeTl) windowPreview.show(itemBox.activeTl, itemBox.mapToItem(null, itemBox.width / 2, 0).x); else if (root.bar) root.bar.showTooltip(itemBox, modelData.name) }
          onExited: { windowPreview.leave(); if (root.bar) root.bar.hideTooltip(itemBox) }
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) windowMenu.open(itemBox.activeTl, itemBox.mapToItem(null, itemBox.width / 2, 0).x)
            else if (mouse.button === Qt.LeftButton) {
              windowPreview.close()
              if (itemBox.activeTl) Quickshell.execDetached(["@HOME@/.local/bin/desktop-windows", "app-toggle", itemBox.activeTl.appId])
              else if (modelData.exec) root.runCmd(modelData.exec)
            }
          }
        }
      }
    }
  }
}
