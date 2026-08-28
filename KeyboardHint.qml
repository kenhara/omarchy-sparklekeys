import QtQuick
import qs.Commons

// Simple on-screen QWERTY. Target key glows; wrong key brightens the glow.
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

  implicitHeight: col.implicitHeight

  function showKey(id) {
    var s = String(id || "")
    return root.letterCase === "lower" ? s : s.toUpperCase()
  }

  Column {
    id: col
    width: root.width
    spacing: Style.space(4)

    KeyRow { keys: root.row0; indent: 0 }
    KeyRow { keys: root.row1; indent: Style.space(10) }
    KeyRow { keys: root.row2; indent: Style.space(22) }
  }

  component KeyRow: Row {
    id: kr
    property var keys: []
    property int indent: 0
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(4)
    leftPadding: kr.indent

    Repeater {
      model: kr.keys
      delegate: Rectangle {
        required property var modelData
        readonly property string keyId: String(modelData)
        readonly property bool isTarget: keyId === String(root.targetLetter || "").toLowerCase()
        readonly property real glow: isTarget ? Math.max(1, root.glowBoost) : 1

        width: Style.space(28)
        height: Style.space(30)
        radius: Style.space(6)
        color: isTarget
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, Math.min(0.55, 0.22 * glow))
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
        border.width: isTarget ? 2 : 1
        border.color: isTarget
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, Math.min(1, 0.45 * glow))
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        scale: isTarget ? Math.min(1.12, 0.96 + 0.08 * glow) : 1

        Text {
          anchors.centerIn: parent
          text: root.showKey(keyId)
          textFormat: Text.PlainText
          color: isTarget ? root.accent : root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: isTarget
        }

        Behavior on scale {
          enabled: root.opened
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }
    }
  }
}
