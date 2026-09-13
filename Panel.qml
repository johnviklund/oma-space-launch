import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
    id: root
    moduleName: "oma-space-launch"
    ipcTarget: "oma-space-launch"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    readonly property var barIdentity: hostWidget || root
    readonly property var cache: hostWidget ? hostWidget.cache : null
    readonly property var display: hostWidget ? hostWidget.display : Model.deriveState(cache, Date.now())
    readonly property var next: cache ? cache.next : null
    readonly property var afterNext: cache ? cache.afterNext : null
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property bool stale: display.stale === true

    function open() {
        root.controller.show()
    }

    function close() {
        root.controller.hide()
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function closeForPopoutSwitch() {
        root.close()
    }

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.barIdentity, direction)
        return false
    }

    function launchTimeLabel() {
        if (display.state === "net" || display.state === "tbd" || display.state === "launching")
            return display.label
        return next ? Model.formatLocalTime(next.net) : "TBD"
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.barIdentity
        bar: root.bar
        open: root.opened
        centerOnBar: true
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(440))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: content
                    width: parent.width
                    spacing: Style.space(12)
                    opacity: root.stale ? 0.55 : 1

                    PanelHero {
                        width: parent.width
                        title: root.display.label
                        meta: root.next ? root.next.mission : "No scheduled launch"
                        detail: root.stale ? "STALE" : ""
                        foreground: root.foreground
                        fontFamily: root.fontFamily
                        metaOpacity: root.stale ? 0.55 : 1
                        iconComponent: Component {
                            Text {
                                text: "󰐥"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.display
                            }
                        }
                    }

                    Column {
                        visible: root.next !== null
                        width: parent.width
                        spacing: Style.space(8)

                        Repeater {
                            model: [
                                { label: "LOCAL TIME", value: root.launchTimeLabel() },
                                { label: "SITE", value: root.next ? root.next.site : "" },
                                { label: "ROCKET", value: root.next ? root.next.rocket : "" },
                                { label: "MISSION", value: root.next ? (root.next.mission || "—") : "" }
                            ]

                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: Style.space(16)

                                Text {
                                    id: label
                                    width: Style.space(104)
                                    text: modelData.label
                                    color: Qt.darker(root.foreground, 1.4)
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                    font.letterSpacing: 1.1
                                }

                                Text {
                                    id: value
                                    width: parent.width - label.width - parent.spacing
                                    text: modelData.value
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.body
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.next !== null
                        text: "Open SpaceX launch page"
                        color: Color.accent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.next && root.next.referenceUrl) Quickshell.execDetached(["omarchy-launch-browser", root.next.referenceUrl])
                        }
                    }

                    PanelSeparator {
                        width: parent.width
                        foreground: root.foreground
                    }

                    Column {
                        width: parent.width
                        spacing: Style.space(4)

                        PanelSectionHeader {
                            text: "NEXT LAUNCH"
                            foreground: root.foreground
                        }

                        Text {
                            width: parent.width
                            text: root.afterNext ? Model.formatAfterNext(root.afterNext) : "No following launch scheduled"
                            color: Qt.darker(root.foreground, 1.4)
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.body
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
