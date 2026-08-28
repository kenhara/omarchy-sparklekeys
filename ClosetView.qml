import QtQuick
import qs.Commons

// Dressing room: large CharacterView as the hero. Hunt is gone.
// Look / Hat / Friend cards sit under the character. Back to hunt is the door.
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property color dimForeground: "#999999"
  property color accent: "#ff6bb5"
  property color aura: "#ff9ad5"
  property string fontFamily: "monospace"

  readonly property int heroSize: Style.space(200)

  implicitHeight: roomCol.implicitHeight

  Column {
    id: roomCol
    width: root.width
    spacing: Style.space(12)

    CharacterView {
      store: root.store
      opened: root.opened
      foreground: root.foreground
      fontFamily: root.fontFamily
      tappable: false
      glyphPx: Style.font.body * 5.4
      implicitWidth: root.heroSize
      implicitHeight: root.heroSize
      width: implicitWidth
      height: implicitHeight
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
      width: parent.width
      text: {
        var pack = store && store.packDisplayName ? String(store.packDisplayName).toLowerCase() : "unicorn"
        return "Buy a look. It stays on your " + pack + "."
      }
      textFormat: Text.PlainText
      color: root.foreground
      opacity: 0.5
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    BackPill {
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      id: shop
      width: parent.width
      spacing: Style.space(10)

      CategoryBlock {
        title: "Look"
        category: "skins"
        model: store ? store.closetSkins : []
      }
      CategoryBlock {
        title: "Hat"
        category: "hats"
        model: store ? store.closetHats : []
      }
      CategoryBlock {
        title: "Friend"
        category: "companions"
        model: store ? store.closetCompanions : []
      }
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

  component CategoryBlock: Column {
    id: block
    property string title: ""
    property string category: ""
    property var model: []
    width: Math.floor((shop.width - shop.spacing * 2) / 3)
    spacing: Style.space(8)

    Text {
      width: parent.width
      text: block.title
      textFormat: Text.PlainText
      color: root.foreground
      opacity: 0.55
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
      horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
      model: block.model
      delegate: CosmeticCard {
        required property var modelData
        item: modelData
        category: block.category
        width: block.width
      }
    }
  }

  component CosmeticCard: Rectangle {
    id: card
    property var item: ({})
    property string category: ""

    readonly property int rev: store ? store.closetRev : 0
    readonly property string itemId: item && item.id ? String(item.id) : ""
    readonly property string itemLabel: item && item.label ? String(item.label) : ""
    readonly property int itemCost: item ? Math.max(0, Math.floor(Number(item.cost) || 0)) : 0
    readonly property string previewName: {
      var _ = card.rev
      if (card.category === "skins")
        return store ? store.characterGlyph : "unicorn"
      if (card.item && card.item.phosphor)
        return String(card.item.phosphor)
      return ""
    }
    readonly property color previewTint: {
      if (card.category === "skins" && card.item && card.item.accent)
        return card.item.accent
      return root.accent
    }
    readonly property color previewAura: {
      if (card.category === "skins" && card.item && card.item.aura)
        return card.item.aura
      return root.aura
    }
    readonly property bool unlocked: {
      var _ = card.rev
      return store ? store.isUnlocked(card.itemId) : false
    }
    readonly property bool equipped: {
      var _ = card.rev
      return store ? store.isEquipped(card.category, card.itemId) : false
    }
    readonly property bool affordable: store ? store.stars >= card.itemCost : false
    readonly property real progress: {
      var _ = card.rev
      var s = store ? store.stars : 0
      return store ? store.affordProgress(card.item) : 0
    }
    readonly property bool hovered: cardMa.containsMouse

    height: Style.space(112)
    radius: Style.space(12)
    color: {
      if (card.equipped)
        return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.26)
      if (card.hovered)
        return Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
      return Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
    }
    border.width: card.equipped ? 2 : 1
    border.color: card.equipped
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.65)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
    opacity: (!card.unlocked && !card.affordable) ? 0.78 : 1

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(8)
      spacing: Style.space(4)

      Item {
        width: parent.width
        height: Style.space(36)

        Rectangle {
          visible: card.category === "skins"
          anchors.centerIn: parent
          width: Style.space(34)
          height: width
          radius: width / 2
          color: Qt.rgba(card.previewAura.r, card.previewAura.g, card.previewAura.b, 0.4)
        }

        PhosphorIcon {
          visible: card.previewName.length > 0
          anchors.centerIn: parent
          width: Style.space(32)
          height: width
          name: card.previewName
          color: card.previewTint
        }

        Text {
          visible: card.previewName.length === 0
          anchors.centerIn: parent
          text: "·"
          textFormat: Text.PlainText
          color: root.dimForeground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }

      Text {
        width: parent.width
        text: card.itemLabel
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: card.equipped
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: {
          if (card.equipped) return "wearing"
          if (card.unlocked) return "tap to wear"
          if (card.affordable) return "⭐ " + card.itemCost
          return "keep practicing"
        }
        textFormat: Text.PlainText
        color: card.equipped || card.affordable ? root.accent : root.dimForeground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
      }

      Rectangle {
        visible: !card.unlocked
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, card.progress))
          height: parent.height
          radius: 2
          color: root.accent
          opacity: 0.7
        }
      }
    }

    MouseArea {
      id: cardMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (!store || !card.item) return
        store.buyOrEquip(card.category, card.item)
      }
    }
  }
}
