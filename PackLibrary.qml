import QtQuick

// Built-in packs (tiered practice words + static accent/aura) and the Trophies boards.
// Access packs through get() / ids() / exists(); boards through board() / friend().
// Practice words are 4 tiers (keys "1".."4"), one every 10 levels — see wordTierForLevel.
// ✨ sparkles is identity-only (product mark) — not a board tile. friend() still
// resolves it so the bar chip can wear it. First-run avatars / avatar() is the
// 12-pick catalog; friend() falls back there for eagle (not a board trophy).
QtObject {
  id: library

  readonly property var packs: ({
    "unicorn": {
      "id": "unicorn",
      "displayName": "Unicorn",
      "practiceWords": {
        "1": [
          "cat", "dog", "sun", "moon", "star", "pink", "wing", "glow", "frog", "owl",
          "rose", "hat", "bee", "key", "wish", "wand", "pony", "horn", "elf", "gem",
          "dust", "song", "hop", "hug", "yes", "love", "cake", "rain", "snow", "fish",
          "bird", "tree", "leaf", "book", "play", "jump", "sing", "blue", "gold", "map",
          "bed", "cup", "ball", "duck", "kite", "bell", "doll", "milk", "jam", "pie",
          "nest", "egg", "fox", "ant", "bug", "sky", "wind", "lake", "hill", "boat",
          "flag", "gift", "kiss", "luck", "peek", "skip", "sand", "wave", "dew", "mist",
          "park", "drum", "harp", "note", "tune", "grin", "wink", "clap", "spin", "swim",
          "kick", "toss", "roll", "hide", "seek", "find", "look",
        ],
        "2": [
          "magic", "fairy", "knight", "crown", "horse", "cloud", "shine", "spark", "quest", "happy",
          "dream", "light", "candy", "apple", "berry", "smile", "green", "heart", "pixie", "spell",
          "dance", "sweet", "peach", "grape", "lemon", "bloom", "petal", "flute", "story", "angel",
          "pearl", "jewel", "twirl", "swirl", "sunny", "gnome", "charm", "lucky", "cocoa", "honey",
          "bells", "grass", "river", "ocean", "daisy", "tulip", "lilac", "coral", "gleam", "glint",
          "prism", "satin", "silk", "mint", "cream", "fudge", "sugar", "merry", "jolly", "shiny",
        ],
        "3": [
          "dragon", "castle", "forest", "sparkle", "garden", "purple", "kitten", "puppy", "sunset", "rocket",
          "planet", "wizard", "potion", "bubble", "summer", "flower", "meadow", "stream", "valley", "winter",
          "spring", "autumn", "fluffy", "cuddle", "giggle", "cherry", "orange", "yellow", "silver", "golden",
          "bunny", "ribbon", "picnic", "puddle", "pillow", "cookie", "muffin", "banana",
        ],
        "4": [
          "unicorn", "rainbow", "morning", "balloon", "thunder", "evening", "sunshine", "twinkle", "glitter", "treasure",
          "princess", "cupcake", "pancake", "popcorn", "snowman", "starfish", "seashell", "mermaid", "dolphin", "penguin",
          "pumpkin", "birthday", "present", "confetti", "carnival", "sparkler", "lantern", "parade", "holiday", "blossom",
          "firefly", "ladybug", "mountain", "crystal"
        ]
      },
      "aura": "#ff9ad5",
      "accent": "#ff6bb5"
    },
    "dragon": {
      "id": "dragon",
      "displayName": "Dragon",
      "practiceWords": {
        "1": [
          "fire", "wing", "gold", "roar", "cave", "egg", "claw", "hot", "ash", "lava",
          "coal", "heat", "bite", "tail", "fang", "horn", "red", "burn", "soar", "fly",
          "sky", "nest", "rock", "hill", "dark", "deep", "hiss", "snap", "grit", "iron",
          "ore", "gem", "ruby", "soot", "glow", "puff", "hide", "hunt", "prey", "bone",
          "jaw", "dent", "scar", "snug", "peak", "crag", "wyrm", "slag", "melt", "boil",
          "spit", "gulp", "bash", "slam", "ram", "poke", "stab", "rage", "fury", "war",
          "pit", "den", "lair", "hole", "drip",
        ],
        "2": [
          "flame", "scale", "knight", "ember", "blaze", "torch", "spark", "growl", "snarl", "talon",
          "tooth", "skull", "magma", "drake", "hoard", "jewel", "crown", "armor", "spear", "sword",
          "tower", "crypt", "stone", "fiery", "scaly", "wings", "horns", "teeth", "claws", "roost",
          "perch", "cliff", "steam", "vapor", "flare", "flash", "burst", "blast", "comet", "storm",
          "cloud", "night", "dusk", "dawn", "beast", "hydra", "snake", "smoke",
        ],
        "3": [
          "dragon", "castle", "cavern", "tunnel", "crater", "canyon", "keeper", "rider", "hunter", "scales",
          "flames", "embers", "sparks", "flight", "diving", "swoop", "hover", "glide", "breath", "molten",
          "heated", "burned", "stormy", "cloudy", "grotto", "hollow", "eyrie", "shield", "helmet", "charge",
          "battle", "mighty", "fierce", "winged", "scaled", "golden", "amber", "orange",
        ],
        "4": [
          "thunder", "volcano", "inferno", "furnace", "fortress", "warrior", "soaring", "scorched", "crimson", "scarlet",
          "treasure", "dragonet", "wyvern", "griffin", "phoenix", "monster", "creature", "caverns", "dungeon", "catacomb",
          "mountain", "fireball", "wingbeat", "roaring", "growling", "blazing", "burning", "glowing", "overlord", "tyrant",
          "emperor", "kingdom", "empire", "legend", "mythical", "ancient", "nightsky", "starfire", "sunfire", "moonfire",
          "jeweled", "crowned", "armored"
        ]
      },
      "aura": "#ff7a3a",
      "accent": "#ff4d00"
    }
  })

  // Product mark. Always unlocked (level 1). Not a 21st Friends tile.
  readonly property var identity: ({
    "id": "sparkles",
    "label": "Sparkles",
    "emoji": "✨",
    "level": 1,
    "blurb": "Tiny lights that twinkle."
  })

  // First-run avatar catalog (id, emoji, label). Horse and cow also live on
  // Friends; eagle is catalog-only — not a board trophy. friend() falls back
  // here so the bar chip and signup tiles always resolve the twelve.
  readonly property var avatars: [
    { "id": "unicorn", "label": "Unicorn", "emoji": "🦄" },
    { "id": "dragon", "label": "Dragon", "emoji": "🐉" },
    { "id": "pig", "label": "Pig", "emoji": "🐷" },
    { "id": "lion", "label": "Lion", "emoji": "🦁" },
    { "id": "cat", "label": "Cat", "emoji": "🐱" },
    { "id": "dog", "label": "Dog", "emoji": "🐶" },
    { "id": "bunny", "label": "Bunny", "emoji": "🐰" },
    { "id": "frog", "label": "Frog", "emoji": "🐸" },
    { "id": "panda", "label": "Panda", "emoji": "🐼" },
    { "id": "eagle", "label": "Eagle", "emoji": "🦅" },
    { "id": "horse", "label": "Horse", "emoji": "🐴" },
    { "id": "cow", "label": "Cow", "emoji": "🐮" }
  ]

  readonly property var avatarIdList: {
    var list = library.avatars || []
    var out = []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && list[i].id)
        out.push(String(list[i].id))
    }
    return out
  }

  // Four themed boards of 20 (4 row × 5 col). Four trophies unlock per level (cap 20).
  // Emoji are wide-adoption (Unicode 6.0; unicorn + sun-with-face are 8.0). No new-era glyphs.
  readonly property var boards: [
    {
      "id": "friends",
      "title": "Friends",
      "unlockLevel": 1,
      "friends": [
        { "id": "unicorn", "label": "Unicorn", "emoji": "🦄", "level": 1, "blurb": "A horse with a horn. It is magic." },
        { "id": "cat", "label": "Cat", "emoji": "🐱", "level": 1, "blurb": "A small animal that says meow." },
        { "id": "dog", "label": "Dog", "emoji": "🐶", "level": 1, "blurb": "A small animal that says woof." },
        { "id": "bunny", "label": "Bunny", "emoji": "🐰", "level": 1, "blurb": "A small animal with long ears." },
        { "id": "frog", "label": "Frog", "emoji": "🐸", "level": 2, "blurb": "A green jumper that says ribbit." },
        { "id": "hamster", "label": "Hamster", "emoji": "🐹", "level": 2, "blurb": "A tiny pet with round cheeks." },
        { "id": "mouse", "label": "Mouse", "emoji": "🐭", "level": 2, "blurb": "A tiny animal with a long tail." },
        { "id": "pig", "label": "Pig", "emoji": "🐷", "level": 2, "blurb": "A pink animal that says oink." },
        { "id": "cow", "label": "Cow", "emoji": "🐮", "level": 3, "blurb": "A farm animal that says moo." },
        { "id": "monkey", "label": "Monkey", "emoji": "🐵", "level": 3, "blurb": "An animal that likes to climb." },
        { "id": "chick", "label": "Chick", "emoji": "🐔", "level": 3, "blurb": "A bird that says cluck." },
        { "id": "hatch", "label": "Hatch", "emoji": "🐣", "level": 3, "blurb": "A baby bird coming out of an egg." },
        { "id": "baby-chick", "label": "Baby chick", "emoji": "🐤", "level": 4, "blurb": "A little yellow bird." },
        { "id": "bird", "label": "Bird", "emoji": "🐦", "level": 4, "blurb": "An animal that can fly." },
        { "id": "penguin", "label": "Penguin", "emoji": "🐧", "level": 4, "blurb": "A bird that waddles on ice." },
        { "id": "horse", "label": "Horse", "emoji": "🐴", "level": 4, "blurb": "A big animal you can ride." },
        { "id": "wolf", "label": "Wolf", "emoji": "🐺", "level": 5, "blurb": "A wild dog that howls." },
        { "id": "koala", "label": "Koala", "emoji": "🐨", "level": 5, "blurb": "A gray animal that sits in trees." },
        { "id": "poodle", "label": "Poodle", "emoji": "🐩", "level": 5, "blurb": "A dog with curly fur." },
        { "id": "front-chick", "label": "Chick", "emoji": "🐥", "level": 5, "blurb": "A baby bird standing up." }
      ]
    },
    {
      "id": "garden",
      "title": "Garden",
      "unlockLevel": 6,
      "friends": [
        { "id": "blossom", "label": "Blossom", "emoji": "🌸", "level": 6, "blurb": "A pink flower on a tree." },
        { "id": "rose", "label": "Rose", "emoji": "🌹", "level": 6, "blurb": "A flower with soft petals." },
        { "id": "sunflower", "label": "Sunflower", "emoji": "🌻", "level": 6, "blurb": "A tall flower that looks at the sun." },
        { "id": "tulip", "label": "Tulip", "emoji": "🌷", "level": 6, "blurb": "A flower that looks like a cup." },
        { "id": "daisy", "label": "Daisy", "emoji": "🌼", "level": 7, "blurb": "A small flower with a yellow middle." },
        { "id": "hibiscus", "label": "Hibiscus", "emoji": "🌺", "level": 7, "blurb": "A big bright flower." },
        { "id": "seedling", "label": "Seedling", "emoji": "🌱", "level": 7, "blurb": "A tiny plant just starting to grow." },
        { "id": "herb", "label": "Herb", "emoji": "🌿", "level": 7, "blurb": "A green plant that smells nice." },
        { "id": "clover", "label": "Clover", "emoji": "🍀", "level": 8, "blurb": "A lucky plant with round leaves." },
        { "id": "maple", "label": "Maple", "emoji": "🍁", "level": 8, "blurb": "A red leaf from a tree." },
        { "id": "fallen", "label": "Fallen", "emoji": "🍂", "level": 8, "blurb": "A brown leaf that fell down." },
        { "id": "leaves", "label": "Leaves", "emoji": "🍃", "level": 8, "blurb": "Green leaves blowing in the wind." },
        { "id": "evergreen", "label": "Evergreen", "emoji": "🌲", "level": 9, "blurb": "A tall tree that stays green." },
        { "id": "deciduous", "label": "Tree", "emoji": "🌳", "level": 9, "blurb": "A big tree with lots of leaves." },
        { "id": "palm", "label": "Palm", "emoji": "🌴", "level": 9, "blurb": "A tree with long leaves at the top." },
        { "id": "cactus", "label": "Cactus", "emoji": "🌵", "level": 9, "blurb": "A plant with spines. It lives in the sand." },
        { "id": "sheaf", "label": "Sheaf", "emoji": "🌾", "level": 10, "blurb": "A bundle of grain from the farm." },
        { "id": "bouquet", "label": "Bouquet", "emoji": "💐", "level": 10, "blurb": "A bunch of pretty flowers." },
        { "id": "white-flower", "label": "Flower", "emoji": "💮", "level": 10, "blurb": "A pretty white flower." },
        { "id": "tanabata", "label": "Tanabata", "emoji": "🎋", "level": 10, "blurb": "A green plant with long leaves." }
      ]
    },
    {
      "id": "sky",
      "title": "Sky",
      "unlockLevel": 11,
      "friends": [
        { "id": "star", "label": "Star", "emoji": "⭐", "level": 11, "blurb": "A bright light in the night sky." },
        { "id": "glow-star", "label": "Glow star", "emoji": "🌟", "level": 11, "blurb": "A star that shines extra bright." },
        { "id": "fireworks", "label": "Fireworks", "emoji": "🎆", "level": 11, "blurb": "Bright lights that pop in the sky." },
        { "id": "moon", "label": "Moon", "emoji": "🌙", "level": 11, "blurb": "The moon in the night sky." },
        { "id": "first-quarter", "label": "Moon", "emoji": "🌛", "level": 12, "blurb": "The moon with a face. It is smiling." },
        { "id": "last-quarter", "label": "Moon", "emoji": "🌜", "level": 12, "blurb": "The moon with a face. It looks sleepy." },
        { "id": "sun", "label": "Sun", "emoji": "🌞", "level": 12, "blurb": "The sun with a happy face." },
        { "id": "sun-plain", "label": "Sun", "emoji": "☀️", "level": 12, "blurb": "The bright sun in the day." },
        { "id": "cloud", "label": "Cloud", "emoji": "☁️", "level": 13, "blurb": "A fluffy cloud in the sky." },
        { "id": "partly", "label": "Cloud", "emoji": "⛅", "level": 13, "blurb": "The sun peeking out from a cloud." },
        { "id": "rainbow", "label": "Rainbow", "emoji": "🌈", "level": 13, "blurb": "A curve of many colors after rain." },
        { "id": "zap", "label": "Zap", "emoji": "⚡", "level": 13, "blurb": "A flash of lightning." },
        { "id": "snow", "label": "Snow", "emoji": "❄️", "level": 14, "blurb": "A tiny ice star that falls." },
        { "id": "snowman", "label": "Snowman", "emoji": "⛄", "level": 14, "blurb": "A snow person with a hat." },
        { "id": "dizzy", "label": "Dizzy", "emoji": "💫", "level": 14, "blurb": "Stars spinning around and around." },
        { "id": "cyclone", "label": "Cyclone", "emoji": "🌀", "level": 14, "blurb": "Wind spinning in a circle." },
        { "id": "shooting", "label": "Shooting", "emoji": "🌠", "level": 15, "blurb": "A star that flies across the sky." },
        { "id": "full-moon-face", "label": "Moon", "emoji": "🌝", "level": 15, "blurb": "A round moon with a face." },
        { "id": "new-moon-face", "label": "Moon", "emoji": "🌚", "level": 15, "blurb": "A dark moon with a face." },
        { "id": "wave", "label": "Wave", "emoji": "🌊", "level": 15, "blurb": "Water that rolls onto the sand." }
      ]
    },
    {
      "id": "wild",
      "title": "Wild",
      "unlockLevel": 16,
      "friends": [
        { "id": "bear", "label": "Bear", "emoji": "🐻", "level": 16, "blurb": "A big furry animal." },
        { "id": "panda", "label": "Panda", "emoji": "🐼", "level": 16, "blurb": "A black and white bear." },
        { "id": "tiger", "label": "Tiger", "emoji": "🐯", "level": 16, "blurb": "A big cat with stripes." },
        { "id": "elephant", "label": "Elephant", "emoji": "🐘", "level": 16, "blurb": "A huge animal with a long nose." },
        { "id": "dragon", "label": "Dragon", "emoji": "🐉", "level": 17, "blurb": "A long magic animal. It can fly." },
        { "id": "lion", "label": "Lion", "emoji": "🦁", "level": 17, "blurb": "A big cat with a fluffy neck." },
        { "id": "crocodile", "label": "Crocodile", "emoji": "🐊", "level": 17, "blurb": "A long animal with lots of teeth." },
        { "id": "turtle", "label": "Turtle", "emoji": "🐢", "level": 17, "blurb": "An animal with a hard shell." },
        { "id": "snake", "label": "Snake", "emoji": "🐍", "level": 18, "blurb": "A long animal with no legs." },
        { "id": "octopus", "label": "Octopus", "emoji": "🐙", "level": 18, "blurb": "A sea animal with eight arms." },
        { "id": "fish", "label": "Fish", "emoji": "🐠", "level": 18, "blurb": "A small fish that swims." },
        { "id": "whale", "label": "Whale", "emoji": "🐳", "level": 18, "blurb": "A huge animal that lives in the sea." },
        { "id": "dolphin", "label": "Dolphin", "emoji": "🐬", "level": 19, "blurb": "A sea animal that likes to jump." },
        { "id": "camel", "label": "Camel", "emoji": "🐫", "level": 19, "blurb": "An animal with humps. It lives in the sand." },
        { "id": "boar", "label": "Boar", "emoji": "🐗", "level": 19, "blurb": "A wild pig with sharp teeth." },
        { "id": "ape", "label": "Monkey", "emoji": "🐒", "level": 19, "blurb": "A monkey that runs on the ground." },
        { "id": "tiger2", "label": "Tiger", "emoji": "🐅", "level": 20, "blurb": "A big striped cat walking." },
        { "id": "leopard", "label": "Leopard", "emoji": "🐆", "level": 20, "blurb": "A spotted cat that runs fast." },
        { "id": "ram", "label": "Ram", "emoji": "🐏", "level": 20, "blurb": "A sheep with big horns." },
        { "id": "whale2", "label": "Whale", "emoji": "🐋", "level": 20, "blurb": "A big whale in the deep sea." }
      ]
    }
  ]

  readonly property string defaultFriendId: "sparkles"

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

  // Tiers every 10 levels: 1–10 → 1, 11–20 → 2, 21–30 → 3, 31+ → 4.
  function wordTierForLevel(level) {
    var lv = Math.max(1, Math.floor(Number(level) || 1))
    if (lv <= 10)
      return 1
    if (lv <= 20)
      return 2
    if (lv <= 30)
      return 3
    return 4
  }

  function practiceWordsForTier(pack, tier) {
    var t = Math.max(1, Math.min(4, Math.floor(Number(tier) || 1)))
    var buckets = pack && pack.practiceWords
    if (!buckets)
      return ["star"]
    var list = buckets[String(t)]
    if (list && list.length)
      return list
    if (typeof buckets.length === "number" && buckets.length)
      return buckets
    return ["star"]
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

  function avatarIds() {
    return library.avatarIdList
  }

  function avatar(id) {
    var want = String(id || "")
    var list = library.avatars || []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && String(list[i].id) === want)
        return list[i]
    }
    return null
  }

  function friend(id) {
    var want = String(id || "")
    if (library.identity && String(library.identity.id) === want)
      return library.identity
    var list = library.boards || []
    for (var b = 0; b < list.length; b++) {
      var friends = (list[b] && list[b].friends) ? list[b].friends : []
      for (var i = 0; i < friends.length; i++) {
        if (friends[i] && String(friends[i].id) === want)
          return friends[i]
      }
    }
    return library.avatar(want)
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
