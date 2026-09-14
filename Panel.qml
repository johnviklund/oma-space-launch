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
    readonly property var launches: cache && Array.isArray(cache.launches) ? cache.launches : []
    readonly property var next: Model.nextLaunch(cache)
    readonly property var upcoming: launches.length > 1 ? launches.slice(1, 4) : []
    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property bool stale: display.stale === true
    readonly property string nextArtPath: Model.launchPhoto(next)
    readonly property string whenValue: {
        const now = root.hostWidget ? root.hostWidget.nowMs : Date.now()
        if (root.next && root.next.timePrecision === "exact" && Model.deriveFreshState(root.next, now).state === "countdown")
            return Qt.formatDateTime(new Date(root.next.net), "ddd, MMM d, yyyy · HH:mm t")
        return Model.launchTimeLabel(root.next, now)
    }
    readonly property int bodySize: Math.round(Style.font.body * 7 / 6)

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
        contentWidth: panel.fittedContentWidth(Style.space(560))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

        // Artwork bleeds through the shell padding; text keeps the native inset.
        Item {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -panel.padding
            anchors.rightMargin: -panel.padding
            width: hero.width * 0.43 + panel.padding
            height: Math.max(0, Math.min(parent.height + panel.padding, hero.height + panel.padding - launchScroll.contentY))
            visible: hero.showArt
            clip: true

            Image {
                id: rocketPhoto
                width: parent.width
                height: hero.height + panel.padding
                y: -launchScroll.contentY
                source: hero.showArt ? Qt.resolvedUrl(root.nextArtPath) : ""
                sourceSize.height: Math.round(height * Screen.devicePixelRatio)
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignRight
                opacity: root.stale ? 0.5 : 1
            }

            Rectangle {
                anchors.fill: rocketPhoto
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Color.popups.background }
                    GradientStop { position: 0.35; color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.8) }
                    GradientStop { position: 0.72; color: "transparent" }
                }
            }
        }

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Flickable {
                id: launchScroll
                anchors.fill: parent
                contentWidth: width
                contentHeight: content.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: content
                    width: parent.width
                    spacing: Style.space(20)

                    Item {
                        id: hero
                        width: parent.width
                        implicitHeight: Math.max(heroContent.implicitHeight, root.next ? Style.space(330) : 0)
                        readonly property bool showArt: root.nextArtPath !== "" && width >= Style.space(420)

                        Column {
                            id: heroContent
                            width: hero.showArt ? parent.width * 0.73 : parent.width
                            spacing: Style.space(18)

                            Column {
                                width: parent.width
                                spacing: Style.space(8)

                                SectionLabel {
                                    width: parent.width
                                    text: root.stale ? "NEXT LAUNCH · STALE" : "NEXT LAUNCH"
                                }

                                Text {
                                    width: parent.width
                                    text: root.stale ? Model.deriveFreshState(root.next, root.hostWidget ? root.hostWidget.nowMs : Date.now()).label : root.display.label
                                    textFormat: Text.PlainText
                                    color: root.foreground
                                    opacity: root.stale ? 0.55 : 1
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.space(48)
                                    fontSizeMode: Text.Fit
                                    minimumPixelSize: Style.font.heading
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width
                                    text: root.next ? root.next.mission || "Mission TBD" : root.display.state === "loading" ? "Fetching launch schedule" : "No scheduled launch"
                                    textFormat: Text.PlainText
                                    color: root.foreground
                                    opacity: root.stale ? 0.55 : 1
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.space(28)
                                    wrapMode: Text.Wrap
                                }
                            }

                            PanelSeparator {
                                width: parent.width
                                foreground: root.foreground
                                visible: root.next !== null
                            }

                            Column {
                                width: parent.width
                                spacing: Style.space(14)
                                visible: root.next !== null
                                opacity: root.stale ? 0.55 : 1

                                Repeater {
                                    model: root.next ? [
                                        { label: "WHEN", value: root.whenValue },
                                        { label: "SITE", value: root.next.site || "Site TBD" },
                                        { label: "ROCKET", value: root.next.rocket || "Rocket TBD" }
                                    ] : []

                                    delegate: Row {
                                        required property var modelData
                                        width: parent.width
                                        spacing: Style.space(12)

                                        Text {
                                            width: Style.space(66)
                                            text: modelData.label
                                            color: root.foreground
                                            opacity: 0.65
                                            font.family: root.fontFamily
                                            font.pixelSize: Style.font.caption
                                            font.letterSpacing: 1
                                            topPadding: Style.space(2)
                                        }

                                        Text {
                                            width: parent.width - Style.space(78)
                                            text: modelData.value
                                            textFormat: Text.PlainText
                                            color: root.foreground
                                            font.family: root.fontFamily
                                            font.pixelSize: root.bodySize
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: root.next !== null
                                text: "Open SpaceX launch page  →"
                                color: Color.accent
                                font.family: root.fontFamily
                                font.pixelSize: root.bodySize
                                wrapMode: Text.Wrap
                                font.underline: launchLink.containsMouse
                                opacity: root.stale ? 0.55 : 1

                                MouseArea {
                                    id: launchLink
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.next && root.next.referenceUrl) Quickshell.execDetached(["omarchy-launch-browser", root.next.referenceUrl])
                                }
                            }
                        }
                    }

                    PanelSeparator {
                        width: parent.width
                        visible: root.upcoming.length > 0
                        foreground: root.foreground
                        strength: 0.25
                    }

                    Column {
                        width: parent.width
                        spacing: Style.space(16)
                        visible: root.upcoming.length > 0
                        opacity: root.stale ? 0.55 : 1

                        SectionLabel {
                            width: parent.width
                            text: "UPCOMING"
                        }

                        Repeater {
                            model: root.upcoming

                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: Style.space(18)

                                Text {
                                    width: Math.min(Style.space(132), parent.width * 0.3)
                                    text: Model.formatUpcomingTime(modelData)
                                    textFormat: Text.PlainText
                                    color: root.foreground
                                    font.family: root.fontFamily
                                    font.pixelSize: root.bodySize
                                    wrapMode: Text.Wrap
                                }

                                Rectangle {
                                    width: 1
                                    height: upcomingDetails.implicitHeight
                                    color: root.foreground
                                    opacity: 0.2
                                }

                                Column {
                                    id: upcomingDetails
                                    width: parent.width - Math.min(Style.space(132), parent.width * 0.3) - parent.spacing * 2 - 1
                                    spacing: Style.space(4)

                                    Text {
                                        width: parent.width
                                        text: modelData.mission || "Mission TBD"
                                        textFormat: Text.PlainText
                                        color: root.foreground
                                        font.family: root.fontFamily
                                        font.pixelSize: root.bodySize
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.rocket || "Rocket TBD"
                                        textFormat: Text.PlainText
                                        color: root.foreground
                                        opacity: 0.65
                                        font.family: root.fontFamily
                                        font.pixelSize: root.bodySize
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Row {
        property alias text: sectionText.text
        spacing: Style.space(10)

        Rectangle {
            width: Style.space(28)
            height: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            color: Color.accent
        }

        PanelSectionHeader {
            id: sectionText
            width: parent.width - Style.space(38)
            foreground: root.foreground
            fontFamily: root.fontFamily
            font.letterSpacing: 1
            wrapMode: Text.Wrap
        }
    }
}
