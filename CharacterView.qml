import QtQuick
import qs.Commons

// Phosphor character + aura + hat + friend. Isolated so packs stay data.
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property string fontFamily: "monospace"
  property int glyphPx: Style.font.body * 2

  readonly property bool isRainbow: store ? store.skinRainbow : false
  readonly property color auraColor: store && store.skinAura ? store.skinAura : "#ff9ad5"
  readonly property color accentColor: store && store.skinAccent ? store.skinAccent : "#ff6bb5"
  readonly property string glyph: store ? store.characterGlyph : "unicorn"
  readonly property string fallbackGlyph: store ? store.characterFallback : "★"
  readonly property string companion: store ? store.companionPhosphor : ""
  readonly property string hat: store ? store.hatPhosphor : ""

  property real hueShift: 0

  readonly property color fillColor: root.isRainbow
    ? Qt.hsla(root.hueShift / 360, 0.62, 0.62, 1)
    : root.accentColor

  implicitWidth: Style.space(56)
  implicitHeight: Style.space(56)

  Timer {
    interval: 70
    running: root.opened && root.isRainbow
    repeat: true
    onTriggered: root.hueShift = (root.hueShift + 4) % 360
  }

  Rectangle {
    id: halo
    anchors.centerIn: parent
    width: Math.min(parent.width, parent.height)
    height: width
    radius: width / 2
    color: root.isRainbow
      ? Qt.hsla(root.hueShift / 360, 0.62, 0.58, 0.42)
      : Qt.rgba(root.auraColor.r, root.auraColor.g, root.auraColor.b, 0.38)
    border.width: 1
    border.color: Qt.rgba(root.auraColor.r, root.auraColor.g, root.auraColor.b, 0.55)
  }

  PhosphorIcon {
    id: face
    visible: face.known
    anchors.centerIn: parent
    width: Math.round(root.glyphPx * 1.35)
    height: width
    name: root.glyph
    color: root.fillColor
  }

  Text {
    visible: !face.known
    anchors.centerIn: parent
    text: root.fallbackGlyph && root.fallbackGlyph.length ? root.fallbackGlyph : "★"
    textFormat: Text.PlainText
    font.family: root.fontFamily
    font.pixelSize: root.glyphPx
    color: root.fillColor
  }

  PhosphorIcon {
    visible: root.hat && root.hat.length
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Math.round(parent.height * 0.02)
    width: Math.round(root.glyphPx * 0.72)
    height: width
    name: root.hat
    color: root.fillColor
  }

  PhosphorIcon {
    visible: root.companion && root.companion.length
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: -2
    anchors.bottomMargin: -2
    width: Math.max(Style.font.caption, Math.round(root.glyphPx * 0.55))
    height: width
    name: root.companion
    color: root.fillColor
  }
}
