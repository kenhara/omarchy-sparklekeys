import QtQuick
import qs.Commons

// Spend stars on pack cosmetics. Affordable buy / equip / calm "keep practicing".
Item {
  id: root

  property var store: null
  property bool opened: false
  property color foreground: "#f2f2f2"
  property color dimForeground: "#999999"
  property color accent: "#ff6bb5"
  property color aura: "#ff9ad5"
  property string fontFamily: "monospace"

  implicitHeight: flick.contentHeight

  Flickable {
    id: flick
    anchors.fill: parent
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: col.implicitHeight
    flickableDirection: Flickable.VerticalFlick
    interactive: true

    Column {
      id: col
      width: flick.width
      spacing: Style.space(14)

      Text {
        width: parent.width
        text: "Tap to wear. Stars buy new looks."
        textFormat: Text.PlainText
        color: root.foreground
        opacity: 0.5
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      CategoryBlock {
        title: "Skins"
        category: "skins"
        model: store ? store.closetSkins : []
      }
      CategoryBlock {
        title: "Effects"
        category: "effects"
        model: store ? store.closetEffects : []
      }
      CategoryBlock {
        title: "Friends"
        category: "companions"
        model: store ? store.closetCompanions : []
      }
      CategoryBlock {
        title: "Banners"
        category: "banners"
        model: store ? store.closetBanners : []
      }
    }
  }

  component CategoryBlock: Column {
    id: block
    property string title: ""
    property string category: ""
    property var model: []
    width: col.width
    spacing: Style.space(8)

    Text {
      text: block.title
      textFormat: Text.PlainText
      color: root.foreground
      opacity: 0.55
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
    }

    Flow {
      width: parent.width
      spacing: Style.space(8)

      Repeater {
        model: block.model
        delegate: CosmeticCard {
          required property var modelData
          item: modelData
          category: block.category
        }
      }
    }
  }

  component CosmeticCard: Rectangle {
    id: card
    property var item: ({})
    property string category: ""

    readonly property string itemId: item && item.id ? String(item.id) : ""
    readonly property string itemLabel: item && item.label ? String(item.label) : ""
    readonly property int itemCost: item ? Math.max(0, Math.floor(Number(item.cost) || 0)) : 0
    readonly property bool unlocked: store ? store.isUnlocked(card.itemId) : false
    readonly property bool equipped: store ? store.isEquipped(card.category, card.itemId) : false
    readonly property bool affordable: store ? store.stars >= card.itemCost : false
    readonly property real progress: store ? store.affordProgress(card.item) : 0
    readonly property bool hovered: cardMa.containsMouse

    width: Style.space(112)
    height: Style.space(78)
    radius: Style.space(10)
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

      Text {
        width: parent.width
        text: card.itemLabel
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: card.equipped
        elide: Text.ElideRight
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
      }

      Rectangle {
        visible: !card.unlocked
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
