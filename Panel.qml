import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Nested details panel for Sparklekeys (loaded by BarWidget — not a separate kind).
// KeyboardPanel + PanelKeyCatcher (Rocketlauncher). No import "." (shadows qs.Ui Panel).
Panel {
  id: root
  moduleName: "kenhara.sparklekeys"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var store: null

  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : "monospace"
  readonly property color themeBackground: {
    try {
      if (typeof Color !== "undefined" && Color.popups && Color.popups.background)
        return Color.popups.background
      if (typeof Color !== "undefined" && Color.background)
        return Color.background
    } catch (e) {}
    return Qt.rgba(0.1, 0.1, 0.12, 1)
  }
  readonly property color surfaceColor: Qt.rgba(
    contentForeground.r, contentForeground.g, contentForeground.b, 0.06)
  readonly property color dimForeground: Qt.darker(contentForeground, 1.45)
  readonly property var liveStore: store
  readonly property color packAccent: {
    if (liveStore && liveStore.skinAccent)
      return liveStore.skinAccent
    return Color.accent
  }
  readonly property color packAura: {
    if (liveStore && liveStore.skinAura)
      return liveStore.skinAura
    return Qt.rgba(1, 0.6, 0.84, 1)
  }
  readonly property color bannerWash: {
    if (!liveStore || !liveStore.bannerBackground)
      return Qt.rgba(0, 0, 0, 0)
    try {
      var c = Qt.color(String(liveStore.bannerBackground))
      if (!c || c.a <= 0.01)
        return Qt.rgba(0, 0, 0, 0)
      return Qt.rgba(c.r, c.g, c.b, 0.22)
    } catch (e) {
      return Qt.rgba(0, 0, 0, 0)
    }
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function persistSetting(key, value) {
    if (!liveStore) return
    var opts = ({})
    opts[key] = value
    liveStore.applySettings(opts)
    if (hostWidget && typeof hostWidget.mirrorSetting === "function")
      hostWidget.mirrorSetting(key, value)
    else if (hostWidget && hostWidget.settings) {
      try { hostWidget.settings[key] = value } catch (e) {}
    }
  }

  function handlePlayKeys(event) {
    if (!event || !liveStore) return false
    return liveStore.handleKey(event)
  }

  readonly property int panelBaseHeight: Style.space(580)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(root.panelBaseHeight)
    popoutSwitching: root.popoutSwitching
    popoutSwitchClosing: root.popoutSwitchClosing

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Keys.onPressed: function(event) {
        root.handlePlayKeys(event)
      }

      Rectangle {
        anchors.fill: parent
        color: root.bannerWash
        visible: root.bannerWash.a > 0.01
      }

      Item {
        id: body
        anchors.fill: parent
        anchors.margins: Style.space(16)

        Column {
          id: column
          width: body.width
          spacing: Style.space(12)

          Row {
            width: parent.width
            spacing: Style.space(10)

            CharacterView {
              store: liveStore
              opened: root.opened
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              glyphPx: Style.font.body * 2
              implicitWidth: Style.space(56)
              implicitHeight: Style.space(56)
            }

            Column {
              width: parent.width - Style.space(160)
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                width: parent.width
                text: liveStore ? liveStore.greeting : "Hi!"
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                elide: Text.ElideRight

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (liveStore) liveStore.beginNameEdit()
                }
              }

              Text {
                width: parent.width
                text: liveStore ? (liveStore.packDisplayName + " · tap name") : ""
                textFormat: Text.PlainText
                color: root.contentForeground
                opacity: 0.45
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
              }
            }

            StarCounter {
              anchors.verticalCenter: parent.verticalCenter
              value: liveStore ? liveStore.stars : 0
              lastAward: liveStore ? liveStore.lastAward : 0
              celebrating: liveStore ? liveStore.celebrating : false
              foreground: root.contentForeground
              accent: root.packAccent
              fontFamily: root.contentFontFamily
              opened: root.opened
            }
          }

          Row {
            spacing: Style.space(8)

            TabPill {
              label: "Play"
              selected: !liveStore || liveStore.viewMode === "play"
              onClicked: if (liveStore) liveStore.setViewMode("play")
            }
            TabPill {
              label: "Closet"
              selected: liveStore && liveStore.viewMode === "closet"
              onClicked: if (liveStore) liveStore.setViewMode("closet")
            }
            TabPill {
              label: liveStore && liveStore.startMode === "words" ? "Words" : "Letters"
              selected: false
              dim: true
              visible: !liveStore || liveStore.viewMode === "play"
              onClicked: {
                if (!liveStore) return
                var next = liveStore.startMode === "words" ? "letters" : "words"
                root.persistSetting("startMode", next)
              }
            }
          }

          PlayView {
            width: parent.width
            visible: !liveStore || liveStore.viewMode === "play"
            height: visible ? implicitHeight : 0
            store: liveStore
            opened: root.opened
            foreground: root.contentForeground
            dimForeground: root.dimForeground
            accent: root.packAccent
            aura: root.packAura
            fontFamily: root.contentFontFamily
          }

          ClosetView {
            width: parent.width
            visible: liveStore && liveStore.viewMode === "closet"
            height: visible ? Math.min(implicitHeight, Style.space(420)) : 0
            store: liveStore
            opened: root.opened
            foreground: root.contentForeground
            dimForeground: root.dimForeground
            accent: root.packAccent
            aura: root.packAura
            fontFamily: root.contentFontFamily
          }
        }

        Celebration {
          anchors.fill: parent
          playing: liveStore ? liveStore.celebrating : false
          special: liveStore ? liveStore.specialCelebrate : false
          effectStyle: liveStore ? liveStore.effectStyle : "sparkles"
          aura: root.packAura
          accent: root.packAccent
          active: root.opened
        }
      }
    }
  }

  component TabPill: Rectangle {
    id: pill
    property string label: ""
    property bool selected: false
    property bool dim: false
    signal clicked()

    readonly property bool hovered: pillMa.containsMouse

    implicitWidth: pillText.implicitWidth + Style.space(22)
    implicitHeight: Style.space(30)
    width: implicitWidth
    height: implicitHeight
    radius: Style.space(10)
    color: {
      if (pill.selected)
        return Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.28)
      if (pill.hovered)
        return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
      return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
    }
    border.width: 1
    border.color: pill.selected
      ? Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.55)
      : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
    opacity: pill.dim && !pill.hovered ? 0.85 : 1

    Text {
      id: pillText
      anchors.centerIn: parent
      text: pill.label
      textFormat: Text.PlainText
      color: pill.selected ? root.packAccent : root.contentForeground
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: pill.selected
    }
    MouseArea {
      id: pillMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: pill.clicked()
    }
  }
}
