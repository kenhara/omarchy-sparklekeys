import QtQuick

// Built-in packs (practice words + static accent/aura) and the Friends boards.
// Access packs through get() / ids() / exists(); boards through board() / friend().
QtObject {
  id: library

  readonly property var packs: ({
    "unicorn": {
      "id": "unicorn",
      "displayName": "Unicorn",
      "practiceWords": ["star", "horn", "magic", "pink", "wing", "pony", "glow", "elf", "fairy", "knight", "wand", "moon", "spell", "wish", "pixie", "crown", "spark", "dust", "quest", "gem", "owl", "frog", "rose", "song"],
      "aura": "#ff9ad5",
      "accent": "#ff6bb5"
    },
    "dragon": {
      "id": "dragon",
      "displayName": "Dragon",
      "practiceWords": ["fire", "wing", "gold", "roar", "cave", "knight", "flame", "claw", "egg", "scale"],
      "aura": "#ff7a3a",
      "accent": "#ff4d00"
    }
  })

  // Four themed boards of five. One friend unlocks per level (cap 20).
  // Emoji are wide-adoption (Unicode 6.0; unicorn is 8.0). No new-era glyphs.
  readonly property var boards: [
    {
      "id": "friends",
      "title": "Friends",
      "unlockLevel": 1,
      "friends": [
        { "id": "unicorn", "label": "Unicorn", "emoji": "🦄", "level": 1 },
        { "id": "cat", "label": "Cat", "emoji": "🐱", "level": 2 },
        { "id": "dog", "label": "Dog", "emoji": "🐶", "level": 3 },
        { "id": "bunny", "label": "Bunny", "emoji": "🐰", "level": 4 },
        { "id": "frog", "label": "Frog", "emoji": "🐸", "level": 5 }
      ]
    },
    {
      "id": "garden",
      "title": "Garden",
      "unlockLevel": 6,
      "friends": [
        { "id": "blossom", "label": "Blossom", "emoji": "🌸", "level": 6 },
        { "id": "rose", "label": "Rose", "emoji": "🌹", "level": 7 },
        { "id": "sunflower", "label": "Sunflower", "emoji": "🌻", "level": 8 },
        { "id": "tulip", "label": "Tulip", "emoji": "🌷", "level": 9 },
        { "id": "daisy", "label": "Daisy", "emoji": "🌼", "level": 10 }
      ]
    },
    {
      "id": "sky",
      "title": "Sky",
      "unlockLevel": 11,
      "friends": [
        { "id": "star", "label": "Star", "emoji": "⭐", "level": 11 },
        { "id": "moon", "label": "Moon", "emoji": "🌙", "level": 12 },
        { "id": "rainbow", "label": "Rainbow", "emoji": "🌈", "level": 13 },
        { "id": "sparkles", "label": "Sparkles", "emoji": "✨", "level": 14 },
        { "id": "sun", "label": "Sun", "emoji": "🌞", "level": 15 }
      ]
    },
    {
      "id": "wild",
      "title": "Wild",
      "unlockLevel": 16,
      "friends": [
        { "id": "bear", "label": "Bear", "emoji": "🐻", "level": 16 },
        { "id": "panda", "label": "Panda", "emoji": "🐼", "level": 17 },
        { "id": "tiger", "label": "Tiger", "emoji": "🐯", "level": 18 },
        { "id": "elephant", "label": "Elephant", "emoji": "🐘", "level": 19 },
        { "id": "dragon", "label": "Dragon", "emoji": "🐉", "level": 20 }
      ]
    }
  ]

  readonly property string defaultFriendId: "unicorn"

  function ids() {
    return ["unicorn", "dragon"]
  }

  function exists(id) {
    var key = String(id || "")
    return !!(library.packs && library.packs[key])
  }

  function get(id) {
    var key = String(id || "unicorn")
    if (library.packs && library.packs[key])
      return library.packs[key]
    return library.packs.unicorn
  }

  function boardIds() {
    var list = library.boards || []
    var out = []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && list[i].id)
        out.push(String(list[i].id))
    }
    return out
  }

  function boardIndex(id) {
    var want = String(id || "")
    var list = library.boards || []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && String(list[i].id) === want)
        return i
    }
    return -1
  }

  function boardAt(i) {
    var list = library.boards || []
    var n = Math.floor(Number(i) || 0)
    if (n < 0 || n >= list.length)
      return list.length ? list[0] : null
    return list[n]
  }

  function board(id) {
    var idx = library.boardIndex(id)
    if (idx < 0)
      return null
    return library.boardAt(idx)
  }

  function friend(id) {
    var want = String(id || "")
    var list = library.boards || []
    for (var b = 0; b < list.length; b++) {
      var friends = (list[b] && list[b].friends) ? list[b].friends : []
      for (var i = 0; i < friends.length; i++) {
        if (friends[i] && String(friends[i].id) === want)
          return friends[i]
      }
    }
    return null
  }

  function boardForFriend(id) {
    var want = String(id || "")
    var list = library.boards || []
    for (var b = 0; b < list.length; b++) {
      var friends = (list[b] && list[b].friends) ? list[b].friends : []
      for (var i = 0; i < friends.length; i++) {
        if (friends[i] && String(friends[i].id) === want)
          return list[b]
      }
    }
    return null
  }
}
