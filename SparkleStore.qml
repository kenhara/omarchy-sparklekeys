import QtQuick
import Quickshell
import Quickshell.Io
import QtMultimedia

// Sparklekeys state + economy + persistence.
// Item-wrapped (family contract). No Python, no network.
// Progress lives in ~/.local/share (earned stars — never a cache wipe).
Item {
  id: store

  PackLibrary { id: packLib }

  // Settings (injected from BarWidget)
  property string characterPack: "unicorn"
  property string letterCase: "upper"
  property string startMode: "letters"
  property int dailyGoal: 20
  property bool showStarsOnBar: true
  property bool soundEnabled: true
  property bool panelOpen: false

  // Progress (persisted)
  property string childName: ""
  property int stars: 0
  property int totalEarned: 0
  property var unlockedByPack: ({})
  property var equippedByPack: ({})
  property int lettersTyped: 0
  property int bestStreak: 0
  property int lessonsDone: 0
  property string lastDay: ""
  property int todayCount: 0
  property bool dailyGoalHit: false

  // Equipped primitives for the active pack (bindable)
  property string equippedSkin: "pink"
  property string equippedEffect: "sparkles"
  property string equippedCompanion: "none"
  property string equippedHat: "none"
  property int closetRev: 0

  // Bundled Kenney CC0 clips only — Qt.resolvedUrl stays inside the plugin.
  readonly property url hitSoundUrl: Qt.resolvedUrl("sounds/hit.wav")
  readonly property url sparkleSoundUrl: Qt.resolvedUrl("sounds/sparkle.wav")

  // Play state (not persisted, except via award/save)
  property string viewMode: "play"
  property bool askingName: false
  property string nameDraft: ""
  property int streak: 0
  property string targetLetter: "a"
  property int letterCursor: 0
  property string currentWord: "star"
  property int wordPick: 0
  property int wordCursor: 0
  property bool celebrating: false
  property bool specialCelebrate: false
  property bool wiggle: false
  property real hintBoost: 1.0
  property int lastAward: 0
  property string lastAwardReason: ""
  property bool hydrated: false
  property bool _dirty: false

  readonly property var easyLetters: [
    "a", "s", "e", "t", "r", "n", "i", "o", "l", "d",
    "h", "c", "m", "u", "p", "b", "g", "f", "w", "y",
    "k", "v", "j", "x", "q", "z"
  ]

  readonly property string dataHome: {
    var xdg = ""
    try { xdg = String(Quickshell.env("XDG_DATA_HOME") || "") } catch (e) {}
    if (xdg && xdg.length)
      return xdg
    var home = ""
    try { home = String(Quickshell.env("HOME") || "") } catch (e2) {}
    if (home && home.length)
      return home + "/.local/share"
    return ""
  }
  readonly property string progressDir: store.dataHome + "/sparklekeys"
  readonly property string progressPath: store.progressDir + "/progress.json"

  readonly property string effectivePack: store.normalizePack(store.characterPack)

  readonly property string characterGlyph: {
    var p = store.currentPack()
    return (p && p.character) ? String(p.character) : "unicorn"
  }
  readonly property string characterFallback: {
    var p = store.currentPack()
    return (p && p.fallback) ? String(p.fallback) : "★"
  }
  readonly property string packDisplayName: {
    var p = store.currentPack()
    return (p && p.displayName) ? String(p.displayName) : "Sparklekeys"
  }
  readonly property string companionPhosphor: {
    var item = store.itemIn("companions", store.equippedCompanion)
    return (item && item.phosphor) ? String(item.phosphor) : ""
  }
  readonly property string hatPhosphor: {
    var item = store.itemIn("hats", store.equippedHat)
    return (item && item.phosphor) ? String(item.phosphor) : ""
  }
  readonly property string skinAura: {
    var item = store.itemIn("skins", store.equippedSkin)
    return (item && item.aura) ? String(item.aura) : "#ff9ad5"
  }
  readonly property string skinAccent: {
    var item = store.itemIn("skins", store.equippedSkin)
    return (item && item.accent) ? String(item.accent) : "#ff6bb5"
  }
  readonly property bool skinRainbow: store.equippedSkin === "rainbow"
  readonly property string effectStyle: {
    if (store.equippedSkin === "rainbow")
      return "rainbow"
    var item = store.itemIn("effects", store.equippedEffect)
    return (item && item.style) ? String(item.style) : "sparkles"
  }
  readonly property string displayTarget: {
    var ch = String(store.targetLetter || "a")
    return store.letterCase === "lower" ? ch.toLowerCase() : ch.toUpperCase()
  }
  readonly property string greeting: {
    var name = String(store.childName || "").trim()
    if (name.length)
      return "Hi, " + name + "!"
    return "Hi!"
  }
  readonly property int level: {
    var n = 1 + Math.floor(Math.max(0, Number(store.totalEarned) || 0) / 15)
    return Math.max(1, Math.min(20, n))
  }
  readonly property real levelProgress: {
    if (store.level >= 20)
      return 1
    return (Math.max(0, Number(store.totalEarned) || 0) % 15) / 15
  }
  readonly property var closetSkins: store.closetItems("skins")
  readonly property var closetHats: store.closetItems("hats")
  readonly property var closetCompanions: store.closetItems("companions")

  function bumpCloset() {
    store.closetRev = store.closetRev + 1
  }

  function normalizePack(id) {
    var s = String(id || "unicorn").trim().toLowerCase()
    if (packLib.exists(s))
      return s
    return "unicorn"
  }

  function normalizeCase(v) {
    var s = String(v || "upper").trim().toLowerCase()
    return s === "lower" ? "lower" : "upper"
  }

  function normalizeMode(v) {
    var s = String(v || "letters").trim().toLowerCase()
    return s === "words" ? "words" : "letters"
  }

  function clampGoal(n) {
    var v = Number(n)
    if (!isFinite(v)) v = 20
    return Math.max(5, Math.min(200, Math.round(v)))
  }

  function applySettings(opts) {
    opts = opts || {}
    if (opts.characterPack !== undefined)
      store.characterPack = store.normalizePack(opts.characterPack)
    if (opts.letterCase !== undefined)
      store.letterCase = store.normalizeCase(opts.letterCase)
    if (opts.startMode !== undefined)
      store.startMode = store.normalizeMode(opts.startMode)
    if (opts.dailyGoal !== undefined)
      store.dailyGoal = store.clampGoal(opts.dailyGoal)
    if (opts.showStarsOnBar !== undefined)
      store.showStarsOnBar = !!opts.showStarsOnBar
    if (opts.soundEnabled !== undefined)
      store.soundEnabled = !!opts.soundEnabled
    store.syncPackWorld()
    store.ensureTarget()
  }

  function currentPack() {
    return packLib.get(store.effectivePack)
  }

  function closetItems(category) {
    var p = store.currentPack()
    if (!p || !p.cosmetics) return []
    return p.cosmetics[category] || []
  }

  function itemIn(category, id) {
    var list = store.closetItems(category)
    var want = String(id || "")
    for (var i = 0; i < list.length; i++) {
      if (list[i] && String(list[i].id) === want)
        return list[i]
    }
    return list.length ? list[0] : null
  }

  function unlockedList(packId) {
    var key = store.normalizePack(packId || store.effectivePack)
    var map = store.unlockedByPack || ({})
    var list = map[key]
    if (!list || !list.length)
      return packLib.defaultUnlocks(key)
    return list
  }

  function isUnlocked(id) {
    var list = store.unlockedList(store.effectivePack)
    return list.indexOf(String(id || "")) >= 0
  }

  function equippedId(category) {
    if (category === "skins") return store.equippedSkin
    if (category === "effects") return store.equippedEffect
    if (category === "companions") return store.equippedCompanion
    if (category === "hats") return store.equippedHat
    return ""
  }

  function isEquipped(category, id) {
    return store.equippedId(category) === String(id || "")
  }

  function syncPackWorld() {
    var key = store.effectivePack
    var map = store.equippedByPack || ({})
    var eq = map[key] || packLib.defaultEquipped(key)
    store.equippedSkin = String((eq && eq.skin) || packLib.defaultEquipped(key).skin)
    store.equippedEffect = String((eq && eq.effect) || "sparkles")
    if (store.equippedEffect === "rainbow")
      store.equippedEffect = "sparkles"
    store.equippedCompanion = String((eq && eq.companion) || "none")
    store.equippedHat = String((eq && eq.hat) || "none")
    store.bumpCloset()
    if (store.startMode === "words")
      store.ensureWord()
  }

  function letterQueue() {
    var seen = ({})
    var out = []
    var name = String(store.childName || "").toLowerCase()
    for (var i = 0; i < name.length; i++) {
      var ch = name.charAt(i)
      if (ch >= "a" && ch <= "z" && !seen[ch]) {
        seen[ch] = true
        out.push(ch)
      }
    }
    for (var j = 0; j < store.easyLetters.length; j++) {
      var e = store.easyLetters[j]
      if (!seen[e]) {
        seen[e] = true
        out.push(e)
      }
    }
    return out.length ? out : store.easyLetters
  }

  function ensureTarget() {
    if (store.startMode === "words") {
      store.ensureWord()
      return
    }
    var q = store.letterQueue()
    if (store.letterCursor < 0 || store.letterCursor >= q.length)
      store.letterCursor = 0
    store.targetLetter = q[store.letterCursor]
  }

  function advanceLetter() {
    var q = store.letterQueue()
    store.letterCursor = (store.letterCursor + 1) % q.length
    store.targetLetter = q[store.letterCursor]
  }

  function ensureWord() {
    var p = store.currentPack()
    var words = (p && p.practiceWords && p.practiceWords.length) ? p.practiceWords : ["star"]
    if (store.wordPick < 0 || store.wordPick >= words.length)
      store.wordPick = 0
    store.currentWord = String(words[store.wordPick] || "star")
    if (store.wordCursor < 0 || store.wordCursor >= store.currentWord.length)
      store.wordCursor = 0
    store.targetLetter = store.currentWord.charAt(store.wordCursor)
  }

  function nextWord() {
    var p = store.currentPack()
    var words = (p && p.practiceWords && p.practiceWords.length) ? p.practiceWords : ["star"]
    store.wordPick = (store.wordPick + 1) % words.length
    store.currentWord = String(words[store.wordPick] || "star")
    store.wordCursor = 0
    store.targetLetter = store.currentWord.charAt(0)
  }

  function todayLocal() {
    var d = new Date()
    var y = d.getFullYear()
    var m = d.getMonth() + 1
    var day = d.getDate()
    return y + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day
  }

  function rollDay() {
    var day = store.todayLocal()
    if (store.lastDay !== day) {
      store.lastDay = day
      store.todayCount = 0
      store.dailyGoalHit = false
    }
  }

  function awardStars(n, reason, special) {
    n = Math.max(0, Math.floor(Number(n) || 0))
    if (n <= 0) {
      store.lastAward = 0
      store.lastAwardReason = reason || ""
      return
    }
    store.stars += n
    store.totalEarned += n
    store.lastAward = n
    store.lastAwardReason = reason || ""
    store.celebrating = true
    store.specialCelebrate = !!special
    store.playHit(!!special)
    celebTimer.restart()
    store.bumpCloset()
    store.scheduleSave()
  }

  function noteCorrectLetter(opts) {
    opts = opts || {}
    store.rollDay()
    store.todayCount += 1
    store.lettersTyped += 1
    store.streak += 1
    if (store.streak > store.bestStreak)
      store.bestStreak = store.streak

    var gained = 1
    var special = !!opts.special
    var reason = "letter"
    if (store.streak > 0 && (store.streak % 5) === 0) {
      gained += 2
      reason = "streak"
    }
    if (opts.wordBonus) {
      gained += 2
      reason = "word"
      special = true
      store.lessonsDone += 1
    }
    if (!store.dailyGoalHit && store.todayCount >= store.dailyGoal) {
      store.dailyGoalHit = true
      gained += 5
      reason = "daily"
      special = true
    }
    store.awardStars(gained, reason, special)
  }

  function miss() {
    store.wiggle = true
    store.hintBoost = 1.85
    wiggleTimer.restart()
    hintTimer.restart()
  }

  function handleLetterKey(typed) {
    var want = String(store.targetLetter || "").toLowerCase()
    if (typed === want) {
      store.noteCorrectLetter({})
      store.advanceLetter()
    } else {
      store.miss()
    }
  }

  function handleWordKey(typed) {
    store.ensureWord()
    var word = String(store.currentWord || "")
    var want = word.charAt(store.wordCursor).toLowerCase()
    if (typed === want) {
      store.wordCursor += 1
      var done = store.wordCursor >= word.length
      store.noteCorrectLetter({ wordBonus: done, special: done })
      if (done)
        store.nextWord()
      else
        store.targetLetter = word.charAt(store.wordCursor)
    } else {
      store.miss()
    }
  }

  function handleKey(event) {
    if (!event) return false
    var key = event.key
    if (key === Qt.Key_Escape)
      return false
    if (key === Qt.Key_Tab)
      return false

    if (store.askingName) {
      if (key === Qt.Key_Backspace) {
        store.nameDraft = String(store.nameDraft || "").slice(0, -1)
        event.accepted = true
        return true
      }
      if (key === Qt.Key_Return || key === Qt.Key_Enter) {
        store.commitName()
        event.accepted = true
        return true
      }
      var raw = String(event.text || "")
      if (/^[A-Za-z]$/.test(raw) && String(store.nameDraft || "").length < 16) {
        store.nameDraft = String(store.nameDraft || "") + raw
        event.accepted = true
        return true
      }
      return false
    }

    if (store.viewMode !== "play")
      return false

    var typed = String(event.text || "").toLowerCase()
    if (!typed.length || !/^[a-z]$/.test(typed))
      return false
    event.accepted = true
    if (store.startMode === "words")
      store.handleWordKey(typed)
    else
      store.handleLetterKey(typed)
    return true
  }

  function beginNameEdit() {
    store.nameDraft = String(store.childName || "")
    store.askingName = true
  }

  function skipName() {
    store.askingName = false
    store.nameDraft = ""
  }

  function sanitizeName(s) {
    var t = String(s || "").replace(/[^A-Za-z]/g, "")
    if (t.length > 16)
      t = t.substring(0, 16)
    return t
  }

  function commitName() {
    var next = store.sanitizeName(store.nameDraft)
    store.childName = next
    store.askingName = false
    store.nameDraft = ""
    store.letterCursor = 0
    store.ensureTarget()
    store.scheduleSave()
  }

  function setViewMode(mode) {
    store.viewMode = (mode === "closet") ? "closet" : "play"
    if (store.viewMode === "play")
      store.ensureTarget()
  }

  function addUnlock(id) {
    var key = store.effectivePack
    var map = store.unlockedByPack || ({})
    var list = []
    var cur = map[key] || packLib.defaultUnlocks(key)
    for (var i = 0; i < cur.length; i++)
      list.push(String(cur[i]))
    var sid = String(id || "")
    if (sid.length && list.indexOf(sid) < 0)
      list.push(sid)
    map[key] = list
    store.unlockedByPack = map
  }

  function persistEquipped() {
    var key = store.effectivePack
    var map = store.equippedByPack || ({})
    map[key] = {
      "skin": store.equippedSkin,
      "effect": store.equippedEffect,
      "companion": store.equippedCompanion,
      "hat": store.equippedHat
    }
    store.equippedByPack = map
  }

  function equip(category, id) {
    var sid = String(id || "")
    if (!sid.length || !store.isUnlocked(sid))
      return
    if (category === "skins") store.equippedSkin = sid
    else if (category === "effects") store.equippedEffect = sid
    else if (category === "companions") store.equippedCompanion = sid
    else if (category === "hats") store.equippedHat = sid
    else return
    store.persistEquipped()
    store.bumpCloset()
    store.scheduleSave()
  }

  function buyOrEquip(category, item) {
    if (!item || !item.id) return "none"
    var sid = String(item.id)
    if (store.isUnlocked(sid)) {
      store.equip(category, sid)
      return "equip"
    }
    var cost = Math.max(0, Math.floor(Number(item.cost) || 0))
    if (store.stars >= cost) {
      store.stars -= cost
      store.addUnlock(sid)
      store.equip(category, sid)
      return "buy"
    }
    return "need"
  }

  function affordProgress(item) {
    if (!item) return 0
    if (store.isUnlocked(item.id)) return 1
    var cost = Math.max(1, Math.floor(Number(item.cost) || 1))
    return Math.max(0, Math.min(1, store.stars / cost))
  }

  function seedMaps() {
    var ids = packLib.ids()
    var unlocks = store.unlockedByPack || ({})
    var eqs = store.equippedByPack || ({})
    for (var i = 0; i < ids.length; i++) {
      var id = ids[i]
      if (!unlocks[id] || !unlocks[id].length)
        unlocks[id] = packLib.defaultUnlocks(id)
      var eq = eqs[id] || packLib.defaultEquipped(id)
      if (!eq.hat)
        eq.hat = "none"
      if (eq.effect === "rainbow")
        eq.effect = "sparkles"
      eqs[id] = eq
    }
    store.unlockedByPack = unlocks
    store.equippedByPack = eqs
  }

  function seedDefaults() {
    store.childName = ""
    store.stars = 0
    store.totalEarned = 0
    store.lettersTyped = 0
    store.bestStreak = 0
    store.lessonsDone = 0
    store.lastDay = store.todayLocal()
    store.todayCount = 0
    store.dailyGoalHit = false
    store.unlockedByPack = ({})
    store.equippedByPack = ({})
    store.seedMaps()
    store.syncPackWorld()
    store.letterCursor = 0
    store.wordPick = 0
    store.wordCursor = 0
    store.ensureTarget()
    store.hydrated = true
    store.askingName = true
  }

  function toProgress() {
    store.seedMaps()
    store.persistEquipped()
    return {
      "schemaVersion": 2,
      "activePack": store.effectivePack,
      "childName": store.childName,
      "stars": store.stars,
      "totalEarned": store.totalEarned,
      "unlocked": store.unlockedByPack,
      "equipped": store.equippedByPack,
      "stats": {
        "lettersTyped": store.lettersTyped,
        "bestStreak": store.bestStreak,
        "lessonsDone": store.lessonsDone,
        "lastDay": store.lastDay,
        "todayCount": store.todayCount,
        "dailyGoalHit": store.dailyGoalHit
      }
    }
  }

  function hydrate(text) {
    if (store.hydrated)
      return
    var raw = String(text || "").trim()
    if (!raw.length) {
      store.seedDefaults()
      return
    }
    try {
      var obj = JSON.parse(raw)
      if (!obj || typeof obj !== "object") {
        store.seedDefaults()
        return
      }
      store.childName = store.sanitizeName(obj.childName || "")
      store.stars = Math.max(0, Math.floor(Number(obj.stars) || 0))
      store.totalEarned = Math.max(0, Math.floor(Number(obj.totalEarned) || 0))
      store.unlockedByPack = (obj.unlocked && typeof obj.unlocked === "object") ? obj.unlocked : ({})
      store.equippedByPack = (obj.equipped && typeof obj.equipped === "object") ? obj.equipped : ({})
      var stats = (obj.stats && typeof obj.stats === "object") ? obj.stats : ({})
      store.lettersTyped = Math.max(0, Math.floor(Number(stats.lettersTyped) || 0))
      store.bestStreak = Math.max(0, Math.floor(Number(stats.bestStreak) || 0))
      store.lessonsDone = Math.max(0, Math.floor(Number(stats.lessonsDone) || 0))
      store.lastDay = String(stats.lastDay || "")
      store.todayCount = Math.max(0, Math.floor(Number(stats.todayCount) || 0))
      store.dailyGoalHit = !!stats.dailyGoalHit
      store.seedMaps()
      store.rollDay()
      store.syncPackWorld()
      store.letterCursor = 0
      store.wordPick = 0
      store.wordCursor = 0
      store.ensureTarget()
      store.askingName = false
      store.hydrated = true
    } catch (e) {
      console.warn("kenhara.sparklekeys: progress.json corrupt — seeding defaults")
      store.seedDefaults()
    }
  }

  function ensureProgressDir() {
    if (!store.progressDir || !store.progressDir.length)
      return
    mkdirProc.running = false
    mkdirProc.running = true
  }

  function flushSave() {
    saveDebounce.stop()
    if (!store.progressPath || !store.progressPath.length)
      return
    store.ensureProgressDir()
    try {
      var body = JSON.stringify(store.toProgress(), null, 2) + "\n"
      progressFile.setText(body)
      store._dirty = false
    } catch (e) {
      console.warn("kenhara.sparklekeys: save failed")
    }
  }

  function scheduleSave() {
    store._dirty = true
    saveDebounce.restart()
  }

  onPanelOpenChanged: {
    if (!store.panelOpen) {
      store.wiggle = false
      store.celebrating = false
      store.specialCelebrate = false
      store.hintBoost = 1.0
      wiggleTimer.stop()
      hintTimer.stop()
      celebTimer.stop()
      store.hushSounds()
      huePause()
      store.flushSave()
    } else {
      store.rollDay()
      store.ensureTarget()
    }
  }

  onEffectivePackChanged: {
    store.syncPackWorld()
    store.wordPick = 0
    store.wordCursor = 0
    store.letterCursor = 0
    store.ensureTarget()
  }

  onStartModeChanged: store.ensureTarget()
  onChildNameChanged: {
    if (store.startMode === "letters")
      store.ensureTarget()
  }

  function huePause() {}

  Component.onCompleted: store.ensureProgressDir()

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", "-m", "0700", store.progressDir]
    running: false
  }

  Timer {
    id: saveDebounce
    interval: 280
    repeat: false
    onTriggered: store.flushSave()
  }

  Timer {
    id: wiggleTimer
    interval: 320
    repeat: false
    onTriggered: store.wiggle = false
  }

  Timer {
    id: hintTimer
    interval: 900
    repeat: false
    onTriggered: store.hintBoost = 1.0
  }

  Timer {
    id: celebTimer
    interval: store.specialCelebrate ? 1400 : 900
    repeat: false
    onTriggered: {
      store.celebrating = false
      store.specialCelebrate = false
    }
  }

  function allowedSoundUrl(u) {
    var s = String(u || "")
    if (!s.length)
      return false
    return s === String(store.hitSoundUrl) || s === String(store.sparkleSoundUrl)
  }

  function playHit(special) {
    if (!store.soundEnabled || !store.panelOpen)
      return
    if (soundCooldown.running)
      return
    soundCooldown.restart()
    var fx = special ? sparkleFx : hitFx
    if (!fx || !store.allowedSoundUrl(fx.source))
      return
    fx.play()
  }

  function hushSounds() {
    hitFx.stop()
    sparkleFx.stop()
  }

  SoundEffect {
    id: hitFx
    source: store.hitSoundUrl
    volume: 0.5
  }

  SoundEffect {
    id: sparkleFx
    source: store.sparkleSoundUrl
    volume: 0.5
  }

  Timer {
    id: soundCooldown
    interval: 90
    repeat: false
  }

  FileView {
    id: progressFile
    path: store.progressPath
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: store.hydrate(text())
    onLoadFailed: store.seedDefaults()
  }
}
