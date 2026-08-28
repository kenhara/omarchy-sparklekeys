import QtQuick
import qs.Commons

// Equipped-effect burst. Pure QML items (no ParticleSystem / PathAnimation).
// Paused and cleared when the panel is closed.
Item {
  id: root

  property bool playing: false
  property bool special: false
  property string effectStyle: "sparkles"
  property color aura: "#ff9ad5"
  property color accent: "#ff6bb5"
  property bool active: true

  visible: playing && active
  clip: true

  property var bits: []

  readonly property int bitPx: root.special
    ? Math.round(Style.font.body * 1.3)
    : Style.font.body

  function glyphFor(style, i) {
    if (style === "confetti") {
      var conf = ["●", "■", "▲", "◆"]
      return conf[i % conf.length]
    }
    if (style === "stars")
      return (i % 2 === 0) ? "star" : "sparkle"
    return (i % 2 === 0) ? "sparkle" : "star"
  }

  function isIcon(g) {
    return g === "sparkle" || g === "star"
  }

  function tintFor(style, i) {
    if (style === "rainbow") {
      var hues = [0.00, 0.08, 0.16, 0.33, 0.55, 0.72, 0.83]
      return Qt.hsla(hues[i % hues.length], 0.7, 0.6, 1)
    }
    if (style === "confetti")
      return (i % 2 === 0) ? root.accent : root.aura
    if (style === "stars")
      return root.accent
    return (i % 3 === 0) ? root.accent : root.aura
  }

  function burst() {
    if (!root.active) {
      root.bits = []
      return
    }
    var n = root.special ? 36 : 20
    var arr = []
    for (var i = 0; i < n; i++) {
      var ang = ((360 / n) * i + ((i * 17) % 24)) * Math.PI / 180
      var dist = 130 + ((i * 29) % 160)
      arr.push({
        "glyph": root.glyphFor(root.effectStyle, i),
        "dx": Math.cos(ang) * dist,
        "dy": Math.sin(ang) * dist,
        "delay": (i % 6) * 28,
        "tint": i
      })
    }
    root.bits = arr
  }

  onPlayingChanged: {
    if (playing && active)
      burst()
    else if (!playing)
      root.bits = []
  }

  onActiveChanged: {
    if (!active)
      root.bits = []
    else if (playing)
      burst()
  }

  Repeater {
    model: root.bits

    Item {
      required property var modelData
      required property int index
      width: 1
      height: 1
      x: root.width / 2
      y: root.height / 3
      opacity: 0

      readonly property real destX: root.width / 2 + (modelData && modelData.dx !== undefined ? modelData.dx : 0)
      readonly property real destY: root.height / 3 + (modelData && modelData.dy !== undefined ? modelData.dy : 0)
      readonly property string g: modelData && modelData.glyph ? String(modelData.glyph) : "sparkle"

      PhosphorIcon {
        visible: root.isIcon(parent.g)
        anchors.centerIn: parent
        width: root.bitPx
        height: width
        name: parent.g
        color: root.tintFor(root.effectStyle, modelData && modelData.tint !== undefined ? modelData.tint : index)
      }

      Text {
        visible: !root.isIcon(parent.g)
        anchors.centerIn: parent
        text: parent.g
        textFormat: Text.PlainText
        color: root.tintFor(root.effectStyle, modelData && modelData.tint !== undefined ? modelData.tint : index)
        font.pixelSize: root.bitPx
      }

      SequentialAnimation {
        running: root.playing && root.active
        loops: 1
        PauseAnimation { duration: modelData && modelData.delay ? modelData.delay : 0 }
        ParallelAnimation {
          NumberAnimation {
            target: parent
            property: "opacity"
            from: 0
            to: 1
            duration: 90
          }
          NumberAnimation {
            target: parent
            property: "x"
            to: destX
            duration: root.special ? 1100 : 800
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: parent
            property: "y"
            to: destY
            duration: root.special ? 1100 : 800
            easing.type: Easing.OutCubic
          }
        }
        NumberAnimation {
          target: parent
          property: "opacity"
          to: 0
          duration: 220
        }
      }
    }
  }
}
