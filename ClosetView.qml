import QtQuick
import qs.Commons

// Trophies room: themed 4×5 emoji boards. Hunt is gone.
// Unlocks are level-gated (4 per level). Tap an unlocked trophy to wear it
// on the bar chip. Color emoji cannot be tinted with Text.color — locked
// tiles use a stone background + low emoji opacity (no QtQuick.Effects).
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property color dimForeground: "#999999"
  property color accent: "#ff6bb5"
  property color aura: "#ff9ad5"
  property string fontFamily: "monospace"

  readonly property int rev: store ? store.boardRev : 0
  readonly property string boardTitle: {
    var _ = root.rev
    return store ? String(store.currentBoardTitle || "Friends") : "Friends"
  }
  readonly property var friends: {
    var _ = root.rev
    return store && store.currentBoardFriends ? store.currentBoardFriends : []
  }
  readonly property bool canPrev: {
    var _ = root.rev
    return store ? !!store.canPrevBoard : false
  }
  readonly property bool canNext: {
    var _ = root.rev
    return store ? !!store.canNextBoard : false
  }
  readonly property int nextLevel: {
    var _ = root.rev
    return store ? Math.max(0, Number(store.nextBoardLevel) || 0) : 0
  }

  implicitHeight: roomCol.implicitHeight

  Column {
    id: roomCol
    width: root.width
    spacing: Style.space(12)

    Text {
      width: parent.width
      text: root.boardTitle
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      width: parent.width
      text: "Trophies light up as you level up."
      textFormat: Text.PlainText
      color: root.foreground
      opacity: 0.5
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Item {
      width: parent.width
      height: navRow.implicitHeight

      Row {
        id: navRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(10)

        NavPill {
          label: "Prev"
          tappable: root.canPrev
          onClicked: if (store) store.prevBoard()
        }

        NavPill {
          label: root.canNext ? "Next" : (root.nextLevel > 0 ? ("Lv " + root.nextLevel) : "Next")
          tappable: root.canNext
          onClicked: if (store) store.nextBoard()
        }
      }
    }

    Text {
      width: parent.width
      visible: !root.canNext && root.nextLevel > 0
      height: visible ? implicitHeight : 0
      text: "keep practicing"
      textFormat: Text.PlainText
      color: root.dimForeground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
    }

    Grid {
      id: tileGrid
      width: parent.width
      columns: 5
      columnSpacing: Style.space(6)
      rowSpacing: Style.space(6)

      Repeater {
        model: root.friends
        delegate: TrophyTile {
          required property var modelData
          item: modelData
          width: Math.max(
            Style.space(48),
            Math.floor((tileGrid.width - tileGrid.columnSpacing * 4) / 5))
        }
      }
    }

    BackPill {
      anchors.horizontalCenter: parent.horizontalCenter
    }
  }

  component NavPill: Rectangle {
    id: nav
    property string label: ""
    property bool tappable: true
    signal clicked()
    readonly property bool hovered: nav.tappable && navMa.containsMouse
    implicitWidth: Math.max(Style.space(56), navLabel.implicitWidth + Style.space(18))
    implicitHeight: Style.space(28)
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
    opacity: nav.tappable ? 1 : 0.4
    color: nav.hovered
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
    border.width: 1
    border.color: nav.tappable
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)

    Text {
      id: navLabel
      anchors.centerIn: parent
      text: nav.label
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: nav.tappable
    }
    MouseArea {
      id: navMa
      anchors.fill: parent
      enabled: nav.tappable
      hoverEnabled: true
      cursorShape: nav.tappable ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: nav.clicked()
    }
  }

  component BackPill: Rectangle {
    id: back
    readonly property bool hovered: backMa.containsMouse
    implicitWidth: backLabel.implicitWidth + Style.space(20)
    implicitHeight: Style.space(28)
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
    color: back.hovered
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)

    Text {
      id: backLabel
      anchors.centerIn: parent
      text: "Back to hunt"
      textFormat: Text.PlainText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }
    MouseArea {
      id: backMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (store) store.setViewMode("play")
    }
  }

  component TrophyTile: Rectangle {
    id: tile
    property var item: ({})

    readonly property int rev: root.rev
    readonly property string itemId: item && item.id ? String(item.id) : ""
    readonly property string itemEmoji: item && item.emoji ? String(item.emoji) : ""
    readonly property int itemLevel: item ? Math.max(1, Math.floor(Number(item.level) || 1)) : 1
    readonly property bool unlocked: {
      var _ = tile.rev
      return store ? store.isFriendUnlocked(tile.itemId) : false
    }
    readonly property bool selected: {
      var _ = tile.rev
      return store && String(store.selectedFriend || "") === tile.itemId
    }
    readonly property bool hovered: tile.unlocked && tileMa.containsMouse

    implicitHeight: Math.max(
      width * 0.78,
      tileCol.implicitHeight + Style.space(10))
    height: implicitHeight
    radius: Style.space(10)
    color: {
      if (!tile.unlocked)
        return Qt.rgba(0.50, 0.50, 0.52, 0.22)
      if (tile.selected)
        return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
      if (tile.hovered)
        return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
      return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
    }
    border.width: tile.selected ? 2 : 1
    border.color: {
      if (tile.selected)
        return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.8)
      if (!tile.unlocked)
        return Qt.rgba(0.55, 0.55, 0.58, 0.28)
      return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
    }

    Column {
      id: tileCol
      anchors.centerIn: parent
      width: parent.width - Style.space(6)
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: tile.itemEmoji
        textFormat: Text.PlainText
        font.pixelSize: Style.font.body * 2
        opacity: tile.unlocked ? 1 : 0.22
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        visible: !tile.unlocked
        height: visible ? implicitHeight : 0
        text: "Lv " + tile.itemLevel
        textFormat: Text.PlainText
        color: root.dimForeground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
      }
    }

    MouseArea {
      id: tileMa
      anchors.fill: parent
      enabled: tile.unlocked
      hoverEnabled: true
      cursorShape: tile.unlocked ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        if (!store || !tile.unlocked)
          return
        store.selectFriend(tile.itemId)
      }
    }
  }
}
