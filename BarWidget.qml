import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Sparklekeys bar entry — Scriptural / Rocketlauncher pattern:
// BarWidget loads nested Panel.qml via Loader. kinds: ["bar-widget"] only.
BarWidget {
  id: root
  moduleName: "kenhara.sparklekeys"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  property string characterPack: {
    try {
      if (root.settings && root.settings.characterPack !== undefined)
        return sparkleStore.normalizePack(root.settings.characterPack)
      if (typeof root.setting === "function")
        return sparkleStore.normalizePack(root.setting("characterPack", "unicorn"))
    } catch (e) {}
    return "unicorn"
  }

  property string letterCase: {
    try {
      if (root.settings && root.settings.letterCase !== undefined)
        return sparkleStore.normalizeCase(root.settings.letterCase)
      if (typeof root.setting === "function")
        return sparkleStore.normalizeCase(root.setting("letterCase", "upper"))
    } catch (e) {}
    return "upper"
  }

  property string startMode: {
    try {
      if (root.settings && root.settings.startMode !== undefined)
        return sparkleStore.normalizeMode(root.settings.startMode)
      if (typeof root.setting === "function")
        return sparkleStore.normalizeMode(root.setting("startMode", "letters"))
    } catch (e) {}
    return "letters"
  }

  property int dailyGoal: {
    var n = 20
    try {
      if (root.settings && root.settings.dailyGoal !== undefined)
        n = Number(root.settings.dailyGoal)
      else if (typeof root.setting === "function")
        n = Number(root.setting("dailyGoal", 20))
    } catch (e) {}
    if (!isFinite(n)) n = 20
    return Math.max(5, Math.min(200, Math.round(n)))
  }

  property bool showStarsOnBar: {
    try {
      if (root.settings && root.settings.showStarsOnBar !== undefined)
        return !!root.settings.showStarsOnBar
      if (typeof root.setting === "function")
        return !!root.setting("showStarsOnBar", true)
    } catch (e) {}
    return true
  }

  property bool soundEnabled: {
    try {
      if (root.settings && root.settings.soundEnabled !== undefined)
        return !!root.settings.soundEnabled
      if (typeof root.setting === "function")
        return !!root.setting("soundEnabled", true)
    } catch (e) {}
    return true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) {
      panelLoader.item.toggle()
      return
    }
    var detail = root.panelLoadError && root.panelLoadError.length
      ? (" load error: " + root.panelLoadError)
      : (" Loader.status=" + panelLoader.status)
    console.warn(moduleName + " toggle ignored — panelLoader.item is null;" + detail)
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("store" in target) target.store = sparkleStore
  }

  function syncStoreSettings() {
    sparkleStore.applySettings({
      characterPack: root.characterPack,
      letterCase: root.letterCase,
      startMode: root.startMode,
      dailyGoal: root.dailyGoal,
      showStarsOnBar: root.showStarsOnBar,
      soundEnabled: root.soundEnabled
    })
    sparkleStore.panelOpen = root.opened
  }

  function mirrorSetting(key, value) {
    if (!root.settings) return
    try {
      root.settings[key] = value
    } catch (e) {}
  }

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    syncStoreSettings()
  }
  onOpenedChanged: {
    sparkleStore.panelOpen = root.opened
  }
  onCharacterPackChanged: syncStoreSettings()
  onLetterCaseChanged: syncStoreSettings()
  onStartModeChanged: syncStoreSettings()
  onDailyGoalChanged: syncStoreSettings()
  onShowStarsOnBarChanged: syncStoreSettings()
  onSoundEnabledChanged: syncStoreSettings()

  SparkleStore {
    id: sparkleStore
  }

  Component.onCompleted: {
    syncStoreSettings()
  }

  property string panelLoadError: ""

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.panelLoadError = ""
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
    onStatusChanged: {
      if (status === Loader.Error) {
        var err = ""
        try {
          if (sourceComponent)
            err = String(sourceComponent.errorString || "")
        } catch (e) {}
        root.panelLoadError = err.length ? err : "Panel.qml failed to load"
        console.warn(moduleName + " panel load failed: " + root.panelLoadError)
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Em-space reserves the emoji slot. WidgetButton inherits the bar font,
    // which can tofu color emoji, so the friend sits in a sibling Text.
    text: sparkleStore.showStarsOnBar ? ("\u2003 " + String(sparkleStore.stars)) : "\u2003"
    fontSize: Style.font.caption
    horizontalMargin: 8.5
    tooltipText: {
      var tip = "Sparklekeys · " + String(sparkleStore.selectedFriendLabel || "Sparkles")
      tip += " · Lv " + String(sparkleStore.level)
      tip += " · " + String(sparkleStore.stars)
      if (root.panelLoadError && root.panelLoadError.length) {
        var pe = root.panelLoadError
        if (pe.length > 120)
          pe = pe.substring(0, 117) + "…"
        tip += " · panel load error — " + pe
      }
      return tip
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }

  Text {
    z: 1
    anchors.verticalCenter: button.verticalCenter
    anchors.left: button.left
    anchors.leftMargin: 8.5
    text: sparkleStore.selectedEmoji && sparkleStore.selectedEmoji.length
      ? sparkleStore.selectedEmoji
      : "✨"
    textFormat: Text.PlainText
    font.pixelSize: Style.font.caption
  }
}
