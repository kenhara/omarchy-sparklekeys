import QtQuick
import Quickshell
import Quickshell.Io
import QtMultimedia

// Sparklekeys state + economy + persistence.
// Item-wrapped (family contract). No network.
// Progress I/O is scripts/progress.py (HC-05 read + exclusive write), not FileView.
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
  property string selectedFriend: "sparkles"
  property string currentBoardId: "friends"
  // currentBoardId is session-snapped on Trophies enter / level-up; still
  // written in schema 3 so persist shape does not change.
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
  // First-run avatar pick. Unicorn is pre-selected so That's me! needs no extra tap.
  property string avatarDraft: "unicorn"
  readonly property var avatarIds: packLib.avatarIdList
  property int streak: 0
  property string targetLetter: "a"
  property int letterCursor: 0
  property string currentWord: "star"
  property int wordPick: 0
  property int wordCursor: 0
  property int _wordTierUsed: 0
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
  readonly property string pluginDir: {
    var raw = String(Qt.resolvedUrl("."))
      .replace(/^file:\/\//, "")
      .replace(/\/$/, "")
    try {
      return decodeURIComponent(raw)
    } catch (e) {
      return raw
    }
  }
  readonly property string helperPath: store.pluginDir + "/scripts/progress.py"
  readonly property int maxProgressBytes: 65536
  readonly property int maxHelperOutput: 69632
  readonly property var helperEnv: ({
    "PATH": "/usr/bin:/bin",
    "PYTHONDONTWRITEBYTECODE": "1"
  })
  property string progressBuf: ""
  property bool progressOverflow: false

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
    return (f && f.emoji) ? String(f.emoji) : "✨"
  }
  readonly property string selectedFriendLabel: {
    var f = packLib.friend(store.selectedFriend)
    return (f && f.label) ? String(f.label) : "Sparkles"
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
    return Math.max(1, n)
  }
  readonly property real levelProgress: {
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
    if (packLib.identity && String(packLib.identity.id) === String(id || ""))
      return true
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

  function boardForLevel(level) {
    var lv = Math.max(1, Math.min(20, Math.floor(Number(level) || 1)))
    if (typeof packLib.boardForLevel === "function")
      return packLib.boardForLevel(lv)
    if (lv <= 5)
      return packLib.board("friends")
    if (lv <= 10)
      return packLib.board("garden")
    if (lv <= 15)
      return packLib.board("sky")
    return packLib.board("wild")
  }

  // Snap to the board for her current level. Room enter / level-up only —
  // Prev/Next paging in the same visit must not call this.
  function showBoardForLevel() {
    var b = store.boardForLevel(store.level)
    var sid = (b && b.id) ? String(b.id) : "friends"
    store.currentBoardId = store.normalizeBoard(sid)
    store.bumpBoard()
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

  function isAvatarId(id) {
    var s = String(id || "").trim().toLowerCase()
    if (packLib && typeof packLib.avatar === "function" && packLib.avatar(s))
      return true
    var ids = store.avatarIds || []
    for (var i = 0; i < ids.length; i++) {
      if (String(ids[i]) === s)
        return true
    }
    return false
  }

  function normalizeAvatar(id) {
    var s = String(id || "unicorn").trim().toLowerCase()
    if (store.isAvatarId(s))
      return s
    return "unicorn"
  }

  function friendEmoji(id) {
    var f = packLib.friend(id)
    return (f && f.emoji) ? String(f.emoji) : ""
  }

  // The twelve first-run avatars may be worn even when that trophy is still
  // locked on the board (lion / dragon / panda / horse / cow). Eagle is
  // catalog-only (not a board tile). Inspect still only calls selectFriend
  // for unlocked tiles.
  function canWearFriend(id) {
    var sid = String(id || "")
    if (!packLib.friend(sid))
      return false
    if (store.isAvatarId(sid))
      return true
    return store.isFriendUnlocked(sid)
  }

  function selectFriend(id) {
    var sid = store.normalizeFriend(id)
    if (!store.canWearFriend(sid))
      return
    store.selectedFriend = sid
    var b = packLib.boardForFriend(sid)
    // Do not snap Trophies onto a board she has not unlocked (first-run panda).
    if (b && b.id && store.isBoardUnlocked(String(b.id)))
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

  function wordTierForLevel(level) {
    if (typeof packLib.wordTierForLevel === "function")
      return packLib.wordTierForLevel(level)
    var lv = Math.max(1, Math.floor(Number(level) || 1))
    if (lv <= 10)
      return 1
    if (lv <= 20)
      return 2
    if (lv <= 30)
      return 3
    return 4
  }

  function wordsForCurrentTier() {
    var p = store.currentPack()
    var tier = store.wordTierForLevel(store.level)
    if (typeof packLib.practiceWordsForTier === "function")
      return packLib.practiceWordsForTier(p, tier)
    return ["star"]
  }

  function ensureWord() {
    var tier = store.wordTierForLevel(store.level)
    var words = store.wordsForCurrentTier()
    if (store._wordTierUsed !== tier) {
      store._wordTierUsed = tier
      store.wordPick = 0
      store.wordCursor = 0
    }
    if (store.wordPick < 0 || store.wordPick >= words.length)
      store.wordPick = 0
    store.currentWord = String(words[store.wordPick] || "star")
    if (store.wordCursor < 0 || store.wordCursor >= store.currentWord.length)
      store.wordCursor = 0
    store.targetLetter = store.currentWord.charAt(store.wordCursor)
  }

  function nextWord() {
    var tier = store.wordTierForLevel(store.level)
    var words = store.wordsForCurrentTier()
    if (store._wordTierUsed !== tier) {
      store._wordTierUsed = tier
      store.wordPick = 0
    } else {
      store.wordPick = (store.wordPick + 1) % Math.max(1, words.length)
    }
    if (store.wordPick < 0 || store.wordPick >= words.length)
      store.wordPick = 0
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
    var prevLevel = store.level
    store.stars += n
    store.totalEarned += n
    store.lastAward = n
    store.lastAwardReason = reason || ""
    store.celebrating = true
    store.specialCelebrate = !!special
    store.playHit(!!special)
    celebTimer.restart()
    if (store.viewMode === "closet" && store.level > prevLevel)
      store.showBoardForLevel()
    else
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
      var prevTier = store.wordTierForLevel(store.level)
      store.noteCorrectLetter({ wordBonus: done, special: done })
      var newTier = store.wordTierForLevel(store.level)
      if (newTier !== prevTier)
        store.ensureWord()
      else if (done)
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
    store.avatarDraft = "unicorn"
    store.askingName = true
  }

  function skipName() {
    store.childName = ""
    store.selectedFriend = packLib.defaultFriendId
    store.askingName = false
    store.nameDraft = ""
    store.avatarDraft = "unicorn"
    // Empty name; bar stays product default ✨. Persist so hydrate does
    // not re-show the name screen on the next open.
    store.scheduleSave()
  }

  function sanitizeName(s) {
    var t = String(s || "").replace(/[^A-Za-z]/g, "")
    if (t.length > 16)
      t = t.substring(0, 16)
    return t
  }

  function capField(s, n) {
    var t = String(s || "")
    var max = Math.max(0, Math.floor(Number(n) || 0))
    if (t.length > max)
      t = t.substring(0, max)
    return t
  }

  function capInt(n) {
    var v = Math.floor(Number(n) || 0)
    if (!isFinite(v) || v < 0)
      return 0
    if (v > 1e12)
      return 1e12
    return v
  }

  function capObject(obj, maxBytes) {
    if (!obj || typeof obj !== "object")
      return ({})
    try {
      var s = JSON.stringify(obj)
      if (!s || s.length > maxBytes)
        return ({})
    } catch (e) {
      return ({})
    }
    return obj
  }

  function commitName() {
    var next = store.sanitizeName(store.nameDraft)
    store.childName = next
    store.askingName = false
    store.nameDraft = ""
    var avatar = store.normalizeAvatar(store.avatarDraft)
    store.selectFriend(avatar)
    store.avatarDraft = "unicorn"
    store.letterCursor = 0
    store.ensureTarget()
    store.scheduleSave()
  }

  function setViewMode(mode) {
    store.viewMode = (mode === "closet") ? "closet" : "play"
    if (store.viewMode === "play")
      store.ensureTarget()
    else
      store.showBoardForLevel()
  }

  function seedDefaults() {
    if (store.hydrated)
      return
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
    store.avatarDraft = "unicorn"
    store.currentBoardId = "friends"
    store.unlockedByPack = ({})
    store.equippedByPack = ({})
    store.letterCursor = 0
    store.wordPick = 0
    store.wordCursor = 0
    store._wordTierUsed = 0
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
      store.stars = store.capInt(obj.stars)
      store.totalEarned = store.capInt(obj.totalEarned)
      store.unlockedByPack = store.capObject(obj.unlocked, 8192)
      store.equippedByPack = store.capObject(obj.equipped, 8192)
      var stats = (obj.stats && typeof obj.stats === "object") ? obj.stats : ({})
      store.lettersTyped = store.capInt(stats.lettersTyped)
      store.bestStreak = store.capInt(stats.bestStreak)
      store.lessonsDone = store.capInt(stats.lessonsDone)
      store.lastDay = store.capField(stats.lastDay || "", 16)
      store.todayCount = store.capInt(stats.todayCount)
      store.dailyGoalHit = !!stats.dailyGoalHit
      var friendId = store.normalizeFriend(store.capField(obj.selectedFriend || packLib.defaultFriendId, 32))
      if (!store.canWearFriend(friendId))
        friendId = packLib.defaultFriendId
      store.selectedFriend = friendId
      var boardId = store.normalizeBoard(store.capField(obj.currentBoardId || "friends", 32))
      if (!store.isBoardUnlocked(boardId))
        boardId = "friends"
      store.currentBoardId = boardId
      store.rollDay()
      store.letterCursor = 0
      store.wordPick = 0
      store.wordCursor = 0
      store._wordTierUsed = 0
      store.ensureTarget()
      store.bumpBoard()
      store.askingName = false
      store.hydrated = true
    } catch (e) {
      console.warn("kenhara.sparklekeys: progress.json corrupt — seeding defaults")
      store.seedDefaults()
    }
  }

  function startProgressRead() {
    if (store.hydrated)
      return
    if (!store.progressPath || !store.progressPath.length || !store.helperPath.length) {
      store.seedDefaults()
      return
    }
    if (progressReadProc.running)
      return
    store.progressBuf = ""
    store.progressOverflow = false
    progressReadProc.running = true
  }

  function onProgressReadFinished(exitCode) {
    var over = store.progressOverflow
    var txt = store.progressBuf
    store.progressBuf = ""
    store.progressOverflow = false
    if (over) {
      console.warn("kenhara.sparklekeys: progress helper overflow — seeding defaults")
      store.seedDefaults()
      return
    }
    if (exitCode !== 0) {
      store.seedDefaults()
      return
    }
    store.hydrate(txt)
  }

  function flushSave() {
    saveDebounce.stop()
    if (!store.hydrated)
      return
    if (!store.progressPath || !store.progressPath.length || !store.helperPath.length)
      return
    if (progressWriteProc.running)
      return
    try {
      var body = JSON.stringify(store.toProgress(), null, 2) + "\n"
      if (body.length > store.maxProgressBytes) {
        console.warn("kenhara.sparklekeys: progress too large to save")
        return
      }
      store._dirty = false
      progressWriteProc.command = [
        "python3", "-B", store.helperPath,
        "--write",
        "--file", store.progressPath,
        "--cap", String(store.maxProgressBytes),
        "--data", body
      ]
      progressWriteProc.environment = store.helperEnv
      progressWriteProc.running = true
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
      if (store.viewMode === "closet")
        store.showBoardForLevel()
    }
  }

  onEffectivePackChanged: {
    store.wordPick = 0
    store.wordCursor = 0
    store._wordTierUsed = 0
    store.letterCursor = 0
    store.ensureTarget()
  }

  onStartModeChanged: store.ensureTarget()
  onChildNameChanged: {
    if (store.startMode === "letters")
      store.ensureTarget()
  }

  Component.onCompleted: store.startProgressRead()

  Process {
    id: progressReadProc
    running: false
    command: ["python3", "-B", store.helperPath, "--file", store.progressPath, "--cap", String(store.maxProgressBytes)]
    environment: store.helperEnv
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (store.progressOverflow)
          return
        if (store.progressBuf.length + String(chunk || "").length > store.maxHelperOutput) {
          store.progressOverflow = true
          store.progressBuf = ""
          progressReadProc.running = false
          return
        }
        store.progressBuf += chunk
      }
    }
    onExited: function(exitCode, exitStatus) {
      store.onProgressReadFinished(exitCode)
    }
  }

  Process {
    id: progressWriteProc
    running: false
    environment: store.helperEnv
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        console.warn("kenhara.sparklekeys: progress write failed")
      if (store._dirty)
        saveDebounce.restart()
    }
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

}
