import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
    id: root
    moduleName: "oma-space-launch"

    readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/oma-space-launch/launches.json"
    readonly property string fetchScript: Qt.resolvedUrl("scripts/fetch-launches.sh").toString()
    readonly property string cacheReaderScript: Qt.resolvedUrl("scripts/read-cache").toString()
    property var cache: null
    property double nowMs: Date.now()
    readonly property var next: Model.nextLaunch(cache)
    readonly property var display: Model.deriveState(cache, nowMs)

    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
    readonly property real openPanelIndicatorWidth: button.labelWidth
    readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

    function open() {
        if (panelLoader.item) panelLoader.item.open()
    }

    function close() {
        if (panelLoader.item) panelLoader.item.close()
    }

    function togglePanel() {
        if (panelLoader.item) panelLoader.item.toggle()
    }

    function closeForPopoutSwitch() {
        if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    }

    function injectPanel() {
        const target = panelLoader.item
        if (!target) return
        if ("bar" in target) target.bar = root.bar
        if ("settings" in target) target.settings = root.settings
        if ("anchorItem" in target) target.anchorItem = button
        if ("hostWidget" in target) target.hostWidget = root
    }

    function refresh(force) {
        if (fetchProcess.running) return
        fetchProcess.command = force ? [fetchScript, "--force"] : [fetchScript]
        fetchProcess.running = true
    }

    function loadCache() {
        if (cacheReader.running) cacheReader.reloadRequested = true
        else cacheReader.running = true
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()

    FileView {
        // Watch metadata only. Never ask FileView to load untrusted cache data.
        preload: false
        path: root.cachePath
        watchChanges: true
        printErrors: false
        onFileChanged: root.loadCache()
    }

    Process {
        id: cacheReader
        property bool reloadRequested: false
        command: [root.cacheReaderScript, root.cachePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cache = Model.parseCache(text)
        }
        onExited: {
            if (reloadRequested) {
                reloadRequested = false
                Qt.callLater(root.loadCache)
            }
        }
    }

    Process {
        id: fetchProcess
        command: [root.fetchScript]
        onExited: function(exitCode) {
            if (exitCode === 0) root.loadCache()
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }

    Timer {
        interval: root.display.state === "countdown" && root.next && Date.parse(root.next.net) - root.nowMs < 60 * 60 * 1000 ? 1000 : 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.nowMs = Date.now()
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }

    IpcHandler {
        target: "oma-space-launch"

        function refresh(): void { root.refresh(true) }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.togglePanel() }
    }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.display.label
        hasVisualContent: true
        dimmed: root.display.stale
        tooltipText: "SpaceX launch"

        onPressed: function(button) {
            if (button === Qt.MiddleButton) root.refresh(true)
            else if (button === Qt.LeftButton) root.togglePanel()
        }
    }
}
