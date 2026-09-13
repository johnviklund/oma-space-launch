import QtQuick
import QtQuick.Effects
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
    readonly property var launches: cache && Array.isArray(cache.launches) ? cache.launches : []
    readonly property var next: Model.nextLaunch(cache)
    readonly property var upcoming: launches.length > 1 ? launches.slice(1) : []
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property bool stale: display.stale === true
    readonly property string nextArtPath: Model.rocketArt(next)
    readonly property bool nextArtIsPhoto: nextArtPath.endsWith(".jpg") || nextArtPath.endsWith(".jpeg")

    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.barIdentity, direction)
        return false
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

        Image {
            id: backgroundArt
            anchors.fill: parent
            anchors.margins: -panel.padding
            visible: root.nextArtIsPhoto && root.next !== null
            source: Qt.resolvedUrl(root.nextArtPath)
            sourceSize.width: Math.round(width * Screen.devicePixelRatio)
            sourceSize.height: Math.round(height * Screen.devicePixelRatio)
            fillMode: Image.PreserveAspectCrop
            opacity: 0.35
            clip: true
            layer.enabled: true
            layer.effect: MultiEffect {
                saturation: -1.0
            }
        }

        Rectangle {
            anchors.fill: backgroundArt
            visible: backgroundArt.visible
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Color.popups.background }
                GradientStop { position: 0.45; color: Color.popups.background }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

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
                                text: "󰑣"
                                color: root.foreground
                                font.family: root.fontFamily
                                font.pixelSize: Style.font.display
                            }
                        }
                    }

                    Item {
                        id: nextEntry
                        visible: root.next !== null
                        width: parent.width
                        implicitHeight: visible ? nextContent.implicitHeight : 0

                        Column {
                            id: nextContent
                            width: parent.width
                            spacing: Style.space(8)

                            Repeater {
                                model: root.next ? [
                                    { label: "LOCAL TIME", value: Model.launchTimeLabel(root.next, root.hostWidget ? root.hostWidget.nowMs : Date.now()) },
                                    { label: "SITE", value: root.next.site },
                                    { label: "ROCKET", value: root.next.rocket },
                                    { label: "MISSION", value: root.next.mission || "—" }
                                ] : []

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
                                        width: parent.width - label.width - parent.spacing
                                        text: modelData.value
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.body
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            Text {
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
                        }
                    }

                    PanelSeparator {
                        width: parent.width
                        visible: root.next !== null && root.upcoming.length > 0
                        foreground: root.foreground
                    }

                    Column {
                        width: parent.width
                        spacing: Style.space(4)
                        visible: root.upcoming.length > 0

                        PanelSectionHeader {
                            text: "UPCOMING"
                            foreground: root.foreground
                        }

                        Column {
                            width: parent.width
                            spacing: Style.space(12)

                            Repeater {
                                model: root.upcoming

                                delegate: Text {
                                    required property var modelData
                                    width: parent.width
                                    text: Model.formatUpcomingLine(modelData)
                                    color: Qt.darker(root.foreground, 1.2)
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
    }
}
