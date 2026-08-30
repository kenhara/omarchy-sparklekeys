import QtQuick
import qs.Commons

// Hunt room: target letter + on-screen keyboard. No character, no closet.
// Name-entry is a centered field (no companion). Letters|Words lives under the letter.
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

  signal persistMode(string mode)

  implicitHeight: col.implicitHeight
  clip: true

  onOpenedChanged: {
    if (root.opened)
      return
    popAnim.stop()
    wiggleAnim.stop()
    letterBox.scale = 1
    letterBox.rotation = 0
  }

  Column {
    id: col
    width: root.width
    spacing: Style.space(14)

    Item {
      width: parent.width
      visible: root.askingName
      height: visible ? nameCol.implicitHeight : 0

      Column {
        id: nameCol
        width: Math.min(parent.width, Style.space(360))
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)

        Text {
          width: parent.width
          text: "Type your name"
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
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

        Text {
          width: parent.width
          text: "Pick a friend"
          textFormat: Text.PlainText
          color: root.foreground
          opacity: 0.7
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }

        Grid {
          id: avatarGrid
          anchors.horizontalCenter: parent.horizontalCenter
          columns: 3
          columnSpacing: Style.space(6)
          rowSpacing: Style.space(6)

          Repeater {
            model: store && store.avatarIds ? store.avatarIds : []
            delegate: Rectangle {
              required property var modelData
              readonly property string avatarId: String(modelData || "")
              readonly property bool chosen: store && String(store.avatarDraft || "") === avatarId
              readonly property bool hovered: avatarMa.containsMouse
              width: Style.space(52)
              height: Style.space(52)
              radius: Style.space(12)
              color: chosen
                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                : (hovered
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07))
              border.width: chosen ? 2 : 1
              border.color: chosen
                ? root.accent
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

              Text {
                anchors.centerIn: parent
                text: store ? store.friendEmoji(avatarId) : ""
                textFormat: Text.PlainText
                font.pixelSize: Style.font.body * 2
              }

              MouseArea {
                id: avatarMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (store) store.avatarDraft = avatarId
              }
            }
          }
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
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
    }

    Column {
      id: huntCol
      visible: !root.askingName
      width: parent.width
      height: visible ? implicitHeight : 0
      spacing: Style.space(8)

      Text {
        width: parent.width
        visible: root.wordMode
        height: visible ? implicitHeight : 0
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
        height: visible ? implicitHeight : 0
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
        height: Math.round(letterBox.height * 1.12)

        Rectangle {
          id: letterBox
          anchors.centerIn: parent
          width: Style.space(216)
          height: Style.space(216)
          radius: Style.space(28)
          color: Qt.rgba(0, 0, 0, 0.58)
          border.width: 3
          border.color: root.accent
          rotation: 0
          scale: 1
          transformOrigin: Item.Center

          Text {
            anchors.centerIn: parent
            text: store ? store.displayTarget : "A"
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body * 8
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

        SequentialAnimation {
          id: popAnim
          running: false
          loops: 1
          NumberAnimation { target: letterBox; property: "scale"; from: 1.0; to: 1.08; duration: 90; easing.type: Easing.OutQuad }
          NumberAnimation { target: letterBox; property: "scale"; to: 1.0; duration: 140; easing.type: Easing.InOutQuad }
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
          function onCelebratingChanged() {
            if (!root.opened) {
              popAnim.stop()
              letterBox.scale = 1
              return
            }
            if (store && store.celebrating)
              popAnim.restart()
            else
              letterBox.scale = 1
          }
        }

        // Award flash overlays the letter. Must not live in the hunt Column
        // with visible/height 0→implicitHeight — that shoves the keyboard.
        Text {
          z: 2
          anchors.horizontalCenter: letterBox.horizontalCenter
          anchors.bottom: letterBox.bottom
          anchors.bottomMargin: Style.space(14)
          visible: store && store.lastAward > 0 && store.celebrating && root.opened
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
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
        }
      }

      ModeSwitch {
        anchors.horizontalCenter: parent.horizontalCenter
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

  component ModeSwitch: Item {
    id: sw
    readonly property bool words: store && store.startMode === "words"
    implicitWidth: Style.space(168)
    implicitHeight: Style.space(28)
    width: implicitWidth
    height: implicitHeight

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
      border.width: 1
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
    }

    Rectangle {
      id: slider
      width: parent.width / 2 - 2
      height: parent.height - 4
      y: 2
      x: sw.words ? (parent.width / 2 + 1) : 2
      radius: height / 2
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.32)
      border.width: 1
      border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
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
      color: !sw.words ? root.accent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
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
      color: sw.words ? root.accent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: sw.words
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
      x: 0
      width: parent.width / 2
      height: parent.height
      cursorShape: Qt.PointingHandCursor
      onClicked: root.persistMode("letters")
    }
    MouseArea {
      x: parent.width / 2
      width: parent.width / 2
      height: parent.height
      cursorShape: Qt.PointingHandCursor
      onClicked: root.persistMode("words")
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
