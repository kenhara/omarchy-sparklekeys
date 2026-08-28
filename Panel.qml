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

  readonly property int panelBaseHeight: Style.space(760)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(560))
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

            Column {
              id: starsBit
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
          }

          Row {
            width: parent.width
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

            ModeSwitch {
              visible: !liveStore || liveStore.viewMode === "play"
              width: visible ? implicitWidth : 0
              height: visible ? implicitHeight : 0
            }

            SoundToggle {}
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
            height: visible ? Math.min(implicitHeight, Style.space(560)) : 0
            store: liveStore
            opened: root.opened
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

  component TabPill: Rectangle {
    id: pill
    property string label: ""
    property bool selected: false
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

  component SoundToggle: Rectangle {
    id: snd
    readonly property bool on: liveStore && liveStore.soundEnabled
    readonly property bool hovered: sndMa.containsMouse

    implicitWidth: sndLabel.implicitWidth + Style.space(22)
    implicitHeight: Style.space(30)
    width: implicitWidth
    height: implicitHeight
    radius: Style.space(10)
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

  component ModeSwitch: Item {
    id: sw
    readonly property bool words: liveStore && liveStore.startMode === "words"
    readonly property bool hovered: lettersMa.containsMouse || wordsMa.containsMouse

    implicitWidth: Style.space(168)
    implicitHeight: Style.space(30)
    width: implicitWidth
    height: implicitHeight

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.06)
      border.width: 1
      border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
    }

    Rectangle {
      id: slider
      width: parent.width / 2 - 2
      height: parent.height - 4
      y: 2
      x: sw.words ? (parent.width / 2 + 1) : 2
      radius: height / 2
      color: Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.28)
      border.width: 1
      border.color: Qt.rgba(root.packAccent.r, root.packAccent.g, root.packAccent.b, 0.55)
      Behavior on x {
        enabled: root.opened
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }

    Text {
      width: parent.width / 2
      height: parent.height
      text: "Letters"
      textFormat: Text.PlainText
      color: !sw.words ? root.packAccent : root.contentForeground
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.caption
      font.bold: !sw.words
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
    Text {
      x: parent.width / 2
      width: parent.width / 2
      height: parent.height
      text: "Words"
      textFormat: Text.PlainText
      color: sw.words ? root.packAccent : root.contentForeground
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.caption
      font.bold: sw.words
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
      id: lettersMa
      x: 0
      width: parent.width / 2
      height: parent.height
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.persistSetting("startMode", "letters")
    }
    MouseArea {
      id: wordsMa
      x: parent.width / 2
      width: parent.width / 2
      height: parent.height
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.persistSetting("startMode", "words")
    }
  }
}
