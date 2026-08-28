import QtQuick
import qs.Commons

// Simple on-screen QWERTY. Target key glows; wrong key brightens the glow.
// Key size scales with panel width so the 10-key top row fills the play surface.
Item {
  id: root

  property string targetLetter: "a"
  property string letterCase: "upper"
  property real glowBoost: 1.0
  property color accent: "#ff6bb5"
  property color foreground: "#f2f2f2"
  property string fontFamily: "monospace"
  property bool opened: true

  readonly property var row0: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
  readonly property var row1: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
  readonly property var row2: ["z", "x", "c", "v", "b", "n", "m"]

  readonly property int topCount: 10
  readonly property real keyGap: Style.space(3)
  readonly property real keyW: {
    var avail = Math.max(0, root.width)
    var gaps = (topCount - 1) * keyGap
    return Math.max(Style.space(24), Math.floor((avail - gaps) / topCount))
  }
  readonly property real keyH: Math.round(keyW * 1.12)
  readonly property real keyRadius: Math.max(Style.space(6), Math.round(keyW * 0.2))
  readonly property real row1Indent: Math.round(keyW * 0.36)
  readonly property real row2Indent: Math.round(keyW * 0.78)
  readonly property int keyFontPx: Style.font.body

  implicitHeight: col.implicitHeight

  function showKey(id) {
    var s = String(id || "")
    return root.letterCase === "lower" ? s : s.toUpperCase()
  }

  Column {
    id: col
    width: root.width
    spacing: root.keyGap

    KeyRow { keys: root.row0; indent: 0 }
    KeyRow { keys: root.row1; indent: root.row1Indent }
    KeyRow { keys: root.row2; indent: root.row2Indent }
  }

  component KeyRow: Row {
    id: kr
    property var keys: []
    property real indent: 0
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: root.keyGap
    leftPadding: kr.indent

    Repeater {
      model: kr.keys
      delegate: Rectangle {
        required property var modelData
        readonly property string keyId: String(modelData)
        readonly property bool isTarget: keyId === String(root.targetLetter || "").toLowerCase()
        readonly property real glow: isTarget ? Math.max(1, root.glowBoost) : 1

        width: root.keyW
        height: root.keyH
        radius: root.keyRadius
        color: isTarget
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, Math.min(0.7, 0.38 * glow))
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        border.width: isTarget ? 2 : 1
        border.color: isTarget
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, Math.min(1, 0.85 * glow))
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)
        scale: isTarget ? Math.min(1.12, 0.96 + 0.08 * glow) : 1

        Text {
          anchors.centerIn: parent
          text: root.showKey(keyId)
          textFormat: Text.PlainText
          color: isTarget ? root.accent : root.foreground
          opacity: isTarget ? 1 : 0.92
          font.family: root.fontFamily
          font.pixelSize: root.keyFontPx
          font.bold: true
        }

        Behavior on scale {
          enabled: root.opened
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }
    }
  }
}
