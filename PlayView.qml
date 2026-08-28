import QtQuick
import qs.Commons

// One play room: companion stage + letter box, keyboard as the floor.
// Name-entry uses the same stage. No hunt until That's me! / Skip.
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property color dimForeground: "#999999"
  property color accent: "#ff6bb5"
  property color aura: "#ff9ad5"
  property string fontFamily: "monospace"

  readonly property bool askingName: store ? store.askingName : false
  readonly property bool wordMode: store && store.startMode === "words" && !root.askingName
  readonly property int companionSize: Style.space(152)

  implicitHeight: col.implicitHeight
  clip: true

  Column {
    id: col
    width: root.width
    spacing: Style.space(14)

    Row {
      id: stage
      width: parent.width
      spacing: Style.space(16)

      CharacterView {
        store: root.store
        opened: root.opened
        foreground: root.foreground
        fontFamily: root.fontFamily
        glyphPx: Style.font.body * 4.2
        implicitWidth: root.companionSize
        implicitHeight: root.companionSize
        width: implicitWidth
        height: implicitHeight
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: Math.max(0, parent.width - root.companionSize - stage.spacing)
        height: Math.max(root.companionSize, nameCol.implicitHeight, huntCol.implicitHeight)

        Column {
          id: nameCol
          visible: root.askingName
          width: parent.width
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: "Type your name"
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Rectangle {
            width: parent.width
            height: Style.space(64)
            radius: Style.space(12)
            color: Qt.rgba(root.aura.r, root.aura.g, root.aura.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)

            Text {
              anchors.centerIn: parent
              text: {
                var draft = store ? String(store.nameDraft || "") : ""
                return draft.length ? draft : "…"
              }
              textFormat: Text.PlainText
              color: root.foreground
              opacity: store && store.nameDraft && store.nameDraft.length ? 1 : 0.4
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          Row {
            spacing: Style.space(8)

            RectButton {
              label: "That's me!"
              accented: true
              onClicked: if (store) store.commitName()
            }
            RectButton {
              label: "Skip"
              onClicked: if (store) store.skipName()
            }
          }
        }

        Column {
          id: huntCol
          visible: !root.askingName
          width: parent.width
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          Text {
            width: parent.width
            visible: root.wordMode
            text: "Type the word"
            textFormat: Text.PlainText
            color: root.foreground
            opacity: 0.5
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }

          Row {
            visible: root.wordMode
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(8)

            Repeater {
              model: store ? String(store.currentWord || "").length : 0
              delegate: Rectangle {
                required property int index
                readonly property string ch: {
                  var w = store ? String(store.currentWord || "") : ""
                  var c = w.charAt(index)
                  return store && store.letterCase === "lower" ? c.toLowerCase() : c.toUpperCase()
                }
                readonly property bool done: store && index < store.wordCursor
                readonly property bool current: store && index === store.wordCursor
                width: Style.space(40)
                height: Style.space(46)
                radius: Style.space(8)
                color: done
                  ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: current ? 2 : 1
                border.color: current
                  ? root.accent
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
                Text {
                  anchors.centerIn: parent
                  text: ch
                  textFormat: Text.PlainText
                  color: done ? root.accent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: current || done
                }
              }
            }
          }

          Item {
            width: parent.width
            height: letterBox.height

            Rectangle {
              id: letterBox
              anchors.horizontalCenter: parent.horizontalCenter
              width: Style.space(200)
              height: Style.space(200)
              radius: Style.space(28)
              color: Qt.rgba(root.aura.r, root.aura.g, root.aura.b, 0.18)
              border.width: 2
              border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
              rotation: 0

              Text {
                anchors.centerIn: parent
                text: store ? store.displayTarget : "A"
                textFormat: Text.PlainText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body * 7
                font.bold: true
              }
            }

            SequentialAnimation {
              id: wiggleAnim
              running: store && store.wiggle && root.opened
              loops: 1
              NumberAnimation { target: letterBox; property: "rotation"; to: -9; duration: 45; easing.type: Easing.OutQuad }
              NumberAnimation { target: letterBox; property: "rotation"; to: 9; duration: 70; easing.type: Easing.InOutQuad }
              NumberAnimation { target: letterBox; property: "rotation"; to: -5; duration: 60 }
              NumberAnimation { target: letterBox; property: "rotation"; to: 0; duration: 55; easing.type: Easing.OutQuad }
            }

            Connections {
              target: store
              function onWiggleChanged() {
                if (!root.opened) {
                  letterBox.rotation = 0
                  return
                }
                if (store && store.wiggle)
                  wiggleAnim.restart()
                else
                  letterBox.rotation = 0
              }
            }
          }

          Text {
            width: parent.width
            visible: store && store.lastAward > 0 && store.celebrating
            text: {
              var n = store ? store.lastAward : 0
              var why = store ? String(store.lastAwardReason || "") : ""
              if (why === "daily") return "+" + n + " ⭐  daily goal!"
              if (why === "streak") return "+" + n + " ⭐  streak!"
              if (why === "word") return "+" + n + " ⭐  word!"
              return "+" + n + " ⭐"
            }
            textFormat: Text.PlainText
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }

    KeyboardHint {
      width: parent.width
      visible: !root.askingName
      height: visible ? implicitHeight : 0
      targetLetter: store ? store.targetLetter : "a"
      letterCase: store ? store.letterCase : "upper"
      glowBoost: store ? store.hintBoost : 1.0
      accent: root.accent
      foreground: root.foreground
      fontFamily: root.fontFamily
      opened: root.opened
    }
  }

  component RectButton: Rectangle {
    id: rb
    property string label: ""
    property bool accented: false
    signal clicked()
    readonly property bool hovered: rbMa.containsMouse
    implicitWidth: rbText.implicitWidth + Style.space(20)
    implicitHeight: Style.space(28)
    width: implicitWidth
    height: implicitHeight
    radius: Style.space(8)
    color: rb.accented
      ? (rb.hovered
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.36)
          : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24))
      : (rb.hovered
          ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07))
    border.width: 1
    border.color: rb.accented
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
    Text {
      id: rbText
      anchors.centerIn: parent
      text: rb.label
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: rb.accented
    }
    MouseArea {
      id: rbMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: rb.clicked()
    }
  }
}
