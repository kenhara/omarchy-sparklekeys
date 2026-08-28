import QtQuick
import qs.Commons

// Animated star balance. Scale-pop on award (FlipCounter energy, kid-simple).
Item {
  id: root

  property int value: 0
  property int lastAward: 0
  property bool celebrating: false
  property color foreground: "#f2f2f2"
  property color accent: "#ff6bb5"
  property string fontFamily: "monospace"
  property bool opened: true

  implicitWidth: Math.max(row.implicitWidth, Style.space(64))
  implicitHeight: row.implicitHeight

  property real pop: 1

  onValueChanged: {
    if (!root.opened) {
      root.pop = 1
      return
    }
    root.pop = 1.18
    popBack.restart()
  }

  Timer {
    id: popBack
    interval: 180
    repeat: false
    running: false
    onTriggered: root.pop = 1
  }

  Row {
    id: row
    spacing: Style.space(4)
    scale: root.pop
    transformOrigin: Item.Center
    Behavior on scale {
      enabled: root.opened
      NumberAnimation { duration: 160; easing.type: Easing.OutBack }
    }

    Text {
      text: "⭐"
      textFormat: Text.PlainText
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: String(root.value)
      textFormat: Text.PlainText
      color: root.celebrating ? root.accent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
