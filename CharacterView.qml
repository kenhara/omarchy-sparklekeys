import QtQuick
import QtQuick.Shapes
import qs.Commons

// Phosphor character + aura + hat + friend. Isolated so packs stay data.
// Unicorn horn is a Shape (triangle), not another Phosphor horse.
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
  readonly property bool showHorn: root.glyph === "unicorn"

  property real hueShift: 0
  property real sparkleAngle: 0

  readonly property color fillColor: root.isRainbow
    ? Qt.hsla(root.hueShift / 360, 0.62, 0.62, 1)
    : root.accentColor

  readonly property int twinklePx: Math.max(8, Math.round(root.glyphPx * 0.2))

  signal tapped()

  implicitWidth: Style.space(56)
  implicitHeight: Style.space(56)

  Timer {
    interval: 70
    running: root.opened && root.isRainbow
    repeat: true
    onTriggered: root.hueShift = (root.hueShift + 4) % 360
  }

  NumberAnimation {
    target: root
    property: "sparkleAngle"
    from: 0
    to: 360
    duration: 16000
    loops: Animation.Infinite
    running: root.opened
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
    z: 1
    visible: root.hat && root.hat.length
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Math.round(parent.height * 0.02)
    width: Math.round(root.glyphPx * 0.72)
    height: width
    name: root.hat
    color: root.fillColor
  }

  // Forehead horn: horse faces left, so upper face slightly toward the snout.
  // z above the hat so a crown never fully hides it.
  Shape {
    id: horn
    visible: root.showHorn
    z: 4
    width: Math.round(face.width * 0.36)
    height: Math.round(face.height * 0.56)
    x: face.x + Math.round(face.width * 0.18)
    y: face.y - Math.round(height * 0.1)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.fillColor
      fillRule: ShapePath.WindingFill
      strokeWidth: 0
      strokeColor: "transparent"
      startX: horn.width * 0.52
      startY: horn.height
      PathLine { x: horn.width * 0.06; y: 0 }
      PathLine { x: horn.width * 0.78; y: horn.height * 0.82 }
      PathLine { x: horn.width * 0.52; y: horn.height }
    }
  }

  PhosphorIcon {
    z: 2
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

  Repeater {
    model: 3
    delegate: Item {
      required property int index
      visible: root.opened
      z: 5
      width: root.twinklePx
      height: width
      readonly property real ang: (root.sparkleAngle + index * 120) * Math.PI / 180
      readonly property real radius: halo.width * 0.42
      x: halo.x + halo.width / 2 + Math.cos(ang) * radius - width / 2
      y: halo.y + halo.height / 2 + Math.sin(ang) * radius - height / 2
      opacity: 0.28 + 0.4 * (0.5 + 0.5 * Math.sin((root.sparkleAngle * 2.4 + index * 90) * Math.PI / 180))
      scale: 0.82 + 0.22 * (0.5 + 0.5 * Math.sin((root.sparkleAngle * 3 + index * 110) * Math.PI / 180))

      PhosphorIcon {
        anchors.fill: parent
        name: index === 1 ? "star" : "sparkle"
        color: root.fillColor
      }
    }
  }

  MouseArea {
    z: 8
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.tapped()
  }
}
