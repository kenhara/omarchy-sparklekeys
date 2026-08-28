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

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.fittedContentHeight(column.implicitHeight + Style.space(16) * 2)
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

      Item {
        id: body
        anchors.fill: parent
        anchors.margins: Style.space(16)

        Column {
          id: column
          width: body.width
          spacing: Style.space(12)

          Row {
            id: headerRow
            width: parent.width
            spacing: Style.space(10)

            Row {
              id: titleBit
              spacing: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter

              PhosphorIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: Style.font.body
                height: width
                name: "unicorn"
                color: root.packAccent
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Sparklekeys"
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }
            }

            Text {
              id: jobLine
              width: Math.max(
                Style.space(64),
                headerRow.width - titleBit.width - starsBit.width - headerRow.spacing * 2)
              anchors.verticalCenter: parent.verticalCenter
              text: {
                var hi = liveStore ? liveStore.greeting : "Hi!"
                var pack = liveStore ? liveStore.packDisplayName : "Sparklekeys"
                var lv = liveStore ? liveStore.level : 1
                return hi + " · " + pack + " · Lv " + lv
              }
              textFormat: Text.PlainText
              color: root.contentForeground
              opacity: 0.62
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }

            Row {
              id: starsBit
              spacing: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter

              Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                StarCounter {
                  value: liveStore ? liveStore.stars : 0
                  lastAward: liveStore ? liveStore.lastAward : 0
                  celebrating: liveStore ? liveStore.celebrating : false
                  foreground: root.contentForeground
                  accent: root.packAccent
                  fontFamily: root.contentFontFamily
                  opened: root.opened
                }

                Rectangle {
                  visible: liveStore && liveStore.level < 20
                  anchors.right: parent.right
                  width: Style.space(48)
                  height: 3
                  radius: 2
                  color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.1)
                  Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, liveStore ? liveStore.levelProgress : 0))
                    height: parent.height
                    radius: 2
                    color: root.packAccent
                    opacity: 0.8
                  }
                }
              }

              SoundToggle {
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          PlayView {
            width: parent.width
            visible: !liveStore || liveStore.viewMode === "play"
            height: visible ? implicitHeight : 0
            store: liveStore
            opened: root.opened && (!liveStore || liveStore.viewMode === "play")
            foreground: root.contentForeground
            dimForeground: root.dimForeground
            accent: root.packAccent
            aura: root.packAura
            fontFamily: root.contentFontFamily
            onPersistMode: function(mode) { root.persistSetting("startMode", mode) }
          }

          ClosetView {
            width: parent.width
            visible: liveStore && liveStore.viewMode === "closet"
            height: visible ? Math.min(implicitHeight, Style.space(560)) : 0
            store: liveStore
            opened: root.opened && liveStore && liveStore.viewMode === "closet"
            foreground: root.contentForeground
            dimForeground: root.dimForeground
            accent: root.packAccent
            aura: root.packAura
            fontFamily: root.contentFontFamily
          }

          Text {
            width: parent.width
            text: "Unofficial · local only"
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.contentForeground
            opacity: 0.22
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
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

  component SoundToggle: Rectangle {
    id: snd
    readonly property bool on: liveStore && liveStore.soundEnabled
    readonly property bool hovered: sndMa.containsMouse

    implicitWidth: sndLabel.implicitWidth + Style.space(14)
    implicitHeight: Style.space(24)
    width: implicitWidth
    height: implicitHeight
    radius: Style.space(8)
    color: {
      if (snd.on)
        return Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.28)
      if (snd.hovered)
        return Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
      return "transparent"
    }
    border.width: 1
    border.color: snd.on
      ? Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.55)
      : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.28)

    Text {
      id: sndLabel
      anchors.centerIn: parent
      text: "Sound"
      textFormat: Text.PlainText
      color: snd.on ? root.packAccent : root.contentForeground
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: snd.on
    }
    MouseArea {
      id: sndMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.persistSetting("soundEnabled", !(liveStore && liveStore.soundEnabled))
    }
  }
}
