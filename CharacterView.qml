import QtQuick
import qs.Commons

// Character + aura + companion. Isolated so a future pack can drop in Shape art.
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property string fontFamily: "monospace"
  property int glyphPx: Style.font.body * 2

  readonly property bool isRainbow: store ? store.skinRainbow : false
  readonly property color auraColor: store && store.skinAura ? store.skinAura : "#ff9ad5"
  readonly property string glyph: store ? store.characterGlyph : "★"
  readonly property string companion: store ? store.companionGlyph : ""

  property real hueShift: 0

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

  Text {
    id: face
    anchors.centerIn: parent
    text: root.glyph && root.glyph.length ? root.glyph : "★"
    textFormat: Text.PlainText
    font.family: "Noto Color Emoji, emoji, " + root.fontFamily
    font.pixelSize: root.glyphPx
  }

  Text {
    visible: root.companion && root.companion.length
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: -2
    anchors.bottomMargin: -2
    text: root.companion
    textFormat: Text.PlainText
    font.family: "Noto Color Emoji, emoji, " + root.fontFamily
    font.pixelSize: Math.max(Style.font.caption, root.glyphPx * 0.45)
  }
}
