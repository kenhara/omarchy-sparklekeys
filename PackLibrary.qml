import QtQuick

// Built-in packs (practice words + static accent/aura) and the Trophies boards.
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

  // Four themed boards of 20 (4 row × 5 col). Four trophies unlock per level (cap 20).
  // Emoji are wide-adoption (Unicode 6.0; unicorn + sun-with-face are 8.0). No new-era glyphs.
  readonly property var boards: [
    {
      "id": "friends",
      "title": "Friends",
      "unlockLevel": 1,
      "friends": [
        { "id": "unicorn", "label": "Unicorn", "emoji": "🦄", "level": 1 },
        { "id": "cat", "label": "Cat", "emoji": "🐱", "level": 1 },
        { "id": "dog", "label": "Dog", "emoji": "🐶", "level": 1 },
        { "id": "bunny", "label": "Bunny", "emoji": "🐰", "level": 1 },
        { "id": "frog", "label": "Frog", "emoji": "🐸", "level": 2 },
        { "id": "hamster", "label": "Hamster", "emoji": "🐹", "level": 2 },
        { "id": "mouse", "label": "Mouse", "emoji": "🐭", "level": 2 },
        { "id": "pig", "label": "Pig", "emoji": "🐷", "level": 2 },
        { "id": "cow", "label": "Cow", "emoji": "🐮", "level": 3 },
        { "id": "monkey", "label": "Monkey", "emoji": "🐵", "level": 3 },
        { "id": "chick", "label": "Chick", "emoji": "🐔", "level": 3 },
        { "id": "hatch", "label": "Hatch", "emoji": "🐣", "level": 3 },
        { "id": "baby-chick", "label": "Baby chick", "emoji": "🐤", "level": 4 },
        { "id": "bird", "label": "Bird", "emoji": "🐦", "level": 4 },
        { "id": "penguin", "label": "Penguin", "emoji": "🐧", "level": 4 },
        { "id": "horse", "label": "Horse", "emoji": "🐴", "level": 4 },
        { "id": "wolf", "label": "Wolf", "emoji": "🐺", "level": 5 },
        { "id": "koala", "label": "Koala", "emoji": "🐨", "level": 5 },
        { "id": "poodle", "label": "Poodle", "emoji": "🐩", "level": 5 },
        { "id": "front-chick", "label": "Chick", "emoji": "🐥", "level": 5 }
      ]
    },
    {
      "id": "garden",
      "title": "Garden",
      "unlockLevel": 6,
      "friends": [
        { "id": "blossom", "label": "Blossom", "emoji": "🌸", "level": 6 },
        { "id": "rose", "label": "Rose", "emoji": "🌹", "level": 6 },
        { "id": "sunflower", "label": "Sunflower", "emoji": "🌻", "level": 6 },
        { "id": "tulip", "label": "Tulip", "emoji": "🌷", "level": 6 },
        { "id": "daisy", "label": "Daisy", "emoji": "🌼", "level": 7 },
        { "id": "hibiscus", "label": "Hibiscus", "emoji": "🌺", "level": 7 },
        { "id": "seedling", "label": "Seedling", "emoji": "🌱", "level": 7 },
        { "id": "herb", "label": "Herb", "emoji": "🌿", "level": 7 },
        { "id": "clover", "label": "Clover", "emoji": "🍀", "level": 8 },
        { "id": "maple", "label": "Maple", "emoji": "🍁", "level": 8 },
        { "id": "fallen", "label": "Fallen", "emoji": "🍂", "level": 8 },
        { "id": "leaves", "label": "Leaves", "emoji": "🍃", "level": 8 },
        { "id": "evergreen", "label": "Evergreen", "emoji": "🌲", "level": 9 },
        { "id": "deciduous", "label": "Tree", "emoji": "🌳", "level": 9 },
        { "id": "palm", "label": "Palm", "emoji": "🌴", "level": 9 },
        { "id": "cactus", "label": "Cactus", "emoji": "🌵", "level": 9 },
        { "id": "sheaf", "label": "Sheaf", "emoji": "🌾", "level": 10 },
        { "id": "bouquet", "label": "Bouquet", "emoji": "💐", "level": 10 },
        { "id": "white-flower", "label": "Flower", "emoji": "💮", "level": 10 },
        { "id": "tanabata", "label": "Tanabata", "emoji": "🎋", "level": 10 }
      ]
    },
    {
      "id": "sky",
      "title": "Sky",
      "unlockLevel": 11,
      "friends": [
        { "id": "star", "label": "Star", "emoji": "⭐", "level": 11 },
        { "id": "glow-star", "label": "Glow star", "emoji": "🌟", "level": 11 },
        { "id": "sparkles", "label": "Sparkles", "emoji": "✨", "level": 11 },
        { "id": "moon", "label": "Moon", "emoji": "🌙", "level": 11 },
        { "id": "first-quarter", "label": "Moon", "emoji": "🌛", "level": 12 },
        { "id": "last-quarter", "label": "Moon", "emoji": "🌜", "level": 12 },
        { "id": "sun", "label": "Sun", "emoji": "🌞", "level": 12 },
        { "id": "sun-plain", "label": "Sun", "emoji": "☀️", "level": 12 },
        { "id": "cloud", "label": "Cloud", "emoji": "☁️", "level": 13 },
        { "id": "partly", "label": "Cloud", "emoji": "⛅", "level": 13 },
        { "id": "rainbow", "label": "Rainbow", "emoji": "🌈", "level": 13 },
        { "id": "zap", "label": "Zap", "emoji": "⚡", "level": 13 },
        { "id": "snow", "label": "Snow", "emoji": "❄️", "level": 14 },
        { "id": "snowman", "label": "Snowman", "emoji": "⛄", "level": 14 },
        { "id": "dizzy", "label": "Dizzy", "emoji": "💫", "level": 14 },
        { "id": "cyclone", "label": "Cyclone", "emoji": "🌀", "level": 14 },
        { "id": "shooting", "label": "Shooting", "emoji": "🌠", "level": 15 },
        { "id": "full-moon-face", "label": "Moon", "emoji": "🌝", "level": 15 },
        { "id": "new-moon-face", "label": "Moon", "emoji": "🌚", "level": 15 },
        { "id": "wave", "label": "Wave", "emoji": "🌊", "level": 15 }
      ]
    },
    {
      "id": "wild",
      "title": "Wild",
      "unlockLevel": 16,
      "friends": [
        { "id": "bear", "label": "Bear", "emoji": "🐻", "level": 16 },
        { "id": "panda", "label": "Panda", "emoji": "🐼", "level": 16 },
        { "id": "tiger", "label": "Tiger", "emoji": "🐯", "level": 16 },
        { "id": "elephant", "label": "Elephant", "emoji": "🐘", "level": 16 },
        { "id": "dragon", "label": "Dragon", "emoji": "🐉", "level": 17 },
        { "id": "lion", "label": "Lion", "emoji": "🦁", "level": 17 },
        { "id": "crocodile", "label": "Crocodile", "emoji": "🐊", "level": 17 },
        { "id": "turtle", "label": "Turtle", "emoji": "🐢", "level": 17 },
        { "id": "snake", "label": "Snake", "emoji": "🐍", "level": 18 },
        { "id": "octopus", "label": "Octopus", "emoji": "🐙", "level": 18 },
        { "id": "fish", "label": "Fish", "emoji": "🐠", "level": 18 },
        { "id": "whale", "label": "Whale", "emoji": "🐳", "level": 18 },
        { "id": "dolphin", "label": "Dolphin", "emoji": "🐬", "level": 19 },
        { "id": "camel", "label": "Camel", "emoji": "🐫", "level": 19 },
        { "id": "boar", "label": "Boar", "emoji": "🐗", "level": 19 },
        { "id": "ape", "label": "Monkey", "emoji": "🐒", "level": 19 },
        { "id": "tiger2", "label": "Tiger", "emoji": "🐅", "level": 20 },
        { "id": "leopard", "label": "Leopard", "emoji": "🐆", "level": 20 },
        { "id": "ram", "label": "Ram", "emoji": "🐏", "level": 20 },
        { "id": "whale2", "label": "Whale", "emoji": "🐋", "level": 20 }
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

  function boardForLevel(level) {
    var lv = Math.max(1, Math.min(20, Math.floor(Number(level) || 1)))
    if (lv <= 5)
      return library.board("friends")
    if (lv <= 10)
      return library.board("garden")
    if (lv <= 15)
      return library.board("sky")
    return library.board("wild")
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
