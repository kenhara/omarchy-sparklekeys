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
  property string selectedFriend: "unicorn"
  property string currentBoardId: "friends"
  // Old closet keys round-trip so we do not wipe a 0.3 file. Unused for play.
  property var unlockedByPack: ({})
  property var equippedByPack: ({})
  property int lettersTyped: 0
  property int bestStreak: 0
  property int lessonsDone: 0
  property string lastDay: ""
  property int todayCount: 0
  property bool dailyGoalHit: false
  property int boardRev: 0

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

  readonly property string packDisplayName: {
    var p = store.currentPack()
    return (p && p.displayName) ? String(p.displayName) : "Sparklekeys"
  }
  readonly property string skinAura: {
    var p = store.currentPack()
    return (p && p.aura) ? String(p.aura) : "#ff9ad5"
  }
  readonly property string skinAccent: {
    var p = store.currentPack()
    return (p && p.accent) ? String(p.accent) : "#ff6bb5"
  }
  readonly property string effectStyle: "sparkles"
  readonly property string selectedEmoji: {
    var f = packLib.friend(store.selectedFriend)
    return (f && f.emoji) ? String(f.emoji) : "🦄"
  }
  readonly property string selectedFriendLabel: {
    var f = packLib.friend(store.selectedFriend)
    return (f && f.label) ? String(f.label) : "Unicorn"
  }
  readonly property var currentBoard: {
    var _ = store.boardRev
    var b = packLib.board(store.currentBoardId)
    return b ? b : packLib.boardAt(0)
  }
  readonly property string currentBoardTitle: {
    var b = store.currentBoard
    return (b && b.title) ? String(b.title) : "Friends"
  }
  readonly property var currentBoardFriends: {
    var b = store.currentBoard
    return (b && b.friends) ? b.friends : []
  }
  readonly property bool canPrevBoard: {
    var _ = store.boardRev
    return packLib.boardIndex(store.currentBoardId) > 0
  }
  readonly property bool canNextBoard: {
    var _ = store.boardRev
    var n = store.peekNextBoard()
    return !!(n && store.isBoardUnlocked(n.id))
  }
  readonly property int nextBoardLevel: {
    var n = store.peekNextBoard()
    return n ? Math.max(0, Math.floor(Number(n.unlockLevel) || 0)) : 0
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

  function bumpBoard() {
    store.boardRev = store.boardRev + 1
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

  function normalizeFriend(id) {
    var s = String(id || packLib.defaultFriendId).trim().toLowerCase()
    if (packLib.friend(s))
      return s
    return packLib.defaultFriendId
  }

  function normalizeBoard(id) {
    var s = String(id || "friends").trim().toLowerCase()
    if (packLib.board(s))
      return s
    return "friends"
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
    store.ensureTarget()
  }

  function currentPack() {
    return packLib.get(store.effectivePack)
  }

  function isFriendUnlocked(id) {
    var f = packLib.friend(id)
    if (!f)
      return false
    var lv = Math.max(1, Math.floor(Number(f.level) || 1))
    return store.level >= lv
  }

  function isBoardUnlocked(id) {
    var b = packLib.board(id)
    if (!b)
      return false
    var lv = Math.max(1, Math.floor(Number(b.unlockLevel) || 1))
    return store.level >= lv
  }

  function peekNextBoard() {
    var ids = packLib.boardIds()
    var idx = packLib.boardIndex(store.currentBoardId)
    if (idx < 0 || idx >= ids.length - 1)
      return null
    return packLib.board(ids[idx + 1])
  }

  function peekPrevBoard() {
    var ids = packLib.boardIds()
    var idx = packLib.boardIndex(store.currentBoardId)
    if (idx <= 0)
      return null
    return packLib.board(ids[idx - 1])
  }

  function showBoard(id) {
    var sid = store.normalizeBoard(id)
    if (!store.isBoardUnlocked(sid))
      return
    store.currentBoardId = sid
    store.bumpBoard()
    store.scheduleSave()
  }

  function nextBoard() {
    var n = store.peekNextBoard()
    if (!n || !store.isBoardUnlocked(n.id))
      return
    store.showBoard(n.id)
  }

  function prevBoard() {
    var n = store.peekPrevBoard()
    if (!n)
      return
    store.showBoard(n.id)
  }

  function selectFriend(id) {
    var sid = store.normalizeFriend(id)
    if (!store.isFriendUnlocked(sid))
      return
    store.selectedFriend = sid
    var b = packLib.boardForFriend(sid)
    if (b && b.id)
      store.currentBoardId = String(b.id)
    store.bumpBoard()
    store.scheduleSave()
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
    store.bumpBoard()
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
    store.selectedFriend = packLib.defaultFriendId
    store.currentBoardId = "friends"
    store.unlockedByPack = ({})
    store.equippedByPack = ({})
    store.letterCursor = 0
    store.wordPick = 0
    store.wordCursor = 0
    store.ensureTarget()
    store.bumpBoard()
    store.hydrated = true
    store.askingName = true
  }

  function toProgress() {
    return {
      "schemaVersion": 3,
      "activePack": store.effectivePack,
      "childName": store.childName,
      "stars": store.stars,
      "totalEarned": store.totalEarned,
      "selectedFriend": store.selectedFriend,
      "currentBoardId": store.currentBoardId,
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
      var friendId = store.normalizeFriend(obj.selectedFriend || packLib.defaultFriendId)
      if (!store.isFriendUnlocked(friendId))
        friendId = packLib.defaultFriendId
      store.selectedFriend = friendId
      var boardId = store.normalizeBoard(obj.currentBoardId || "friends")
      if (!store.isBoardUnlocked(boardId))
        boardId = "friends"
      store.currentBoardId = boardId
      store.rollDay()
      store.letterCursor = 0
      store.wordPick = 0
      store.wordCursor = 0
      store.ensureTarget()
      store.bumpBoard()
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
      store.flushSave()
    } else {
      store.rollDay()
      store.ensureTarget()
    }
  }

  onEffectivePackChanged: {
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
