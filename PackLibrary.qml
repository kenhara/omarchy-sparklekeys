import QtQuick

// Built-in packs as data. Adding a world = add one object here (+ schema enum).
// Future: merge packs/*.json and ~/.config/sparklekeys/packs/*.json via FileView.
// Access only through get() / ids() / exists() so that path stays one change.
QtObject {
  id: library

  // v1 ships unicorn (full) + dragon (stub) to prove pack-swap with zero logic branches.
  readonly property var packs: ({
    "unicorn": {
      "id": "unicorn",
      "displayName": "Unicorn",
      "character": "🦄",
      "fallback": "U",
      "practiceWords": ["star", "horn", "magic", "pink", "wing", "pony", "glow"],
      "defaultSkin": "pink",
      "cosmetics": {
        "skins": [
          { "id": "pink", "label": "Pink Sparkle", "cost": 0, "aura": "#ff9ad5", "accent": "#ff6bb5" },
          { "id": "sky", "label": "Sky Blue", "cost": 10, "aura": "#7ec8ff", "accent": "#3aa0ff" },
          { "id": "golden", "label": "Golden", "cost": 25, "aura": "#ffd76a", "accent": "#f5b400" },
          { "id": "rainbow", "label": "Rainbow", "cost": 30, "aura": "#ff9ad5", "accent": "#7c6bff" }
        ],
        "effects": [
          { "id": "sparkles", "label": "Sparkles", "cost": 0, "style": "sparkles" },
          { "id": "rainbow", "label": "Rainbow Burst", "cost": 15, "style": "rainbow" },
          { "id": "stars", "label": "Star Shower", "cost": 20, "style": "stars" },
          { "id": "confetti", "label": "Confetti", "cost": 20, "style": "confetti" }
        ],
        "companions": [
          { "id": "none", "label": "None", "cost": 0, "glyph": "" },
          { "id": "star", "label": "Star", "cost": 10, "glyph": "⭐" },
          { "id": "butterfly", "label": "Butterfly", "cost": 15, "glyph": "🦋" },
          { "id": "kitten", "label": "Kitten", "cost": 25, "glyph": "🐱" }
        ],
        "banners": [
          { "id": "classic", "label": "Classic", "cost": 0, "background": "#00000000", "greetingStyle": "plain" },
          { "id": "candy", "label": "Candy", "cost": 20, "background": "#ffd6e8", "greetingStyle": "sweet" },
          { "id": "night", "label": "Night Sky", "cost": 20, "background": "#1a1440", "greetingStyle": "dreamy" }
        ]
      }
    },
    "dragon": {
      "id": "dragon",
      "displayName": "Dragon",
      "character": "🐉",
      "fallback": "D",
      "practiceWords": ["fire", "wing", "gold", "roar", "cave"],
      "defaultSkin": "ember",
      "cosmetics": {
        "skins": [
          { "id": "ember", "label": "Ember", "cost": 0, "aura": "#ff7a3a", "accent": "#ff4d00" },
          { "id": "jade", "label": "Jade", "cost": 10, "aura": "#3dff9a", "accent": "#00c46a" }
        ],
        "effects": [
          { "id": "sparkles", "label": "Embers", "cost": 0, "style": "sparkles" },
          { "id": "stars", "label": "Star Fire", "cost": 20, "style": "stars" }
        ],
        "companions": [
          { "id": "none", "label": "None", "cost": 0, "glyph": "" },
          { "id": "egg", "label": "Egg", "cost": 10, "glyph": "🥚" }
        ],
        "banners": [
          { "id": "classic", "label": "Classic", "cost": 0, "background": "#00000000", "greetingStyle": "plain" },
          { "id": "cave", "label": "Cave", "cost": 20, "background": "#2a1810", "greetingStyle": "bold" }
        ]
      }
    }
  })

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

  function defaultUnlocks(id) {
    var p = library.get(id)
    var out = []
    if (!p || !p.cosmetics) return ["none", "classic"]
    var cats = ["skins", "effects", "companions", "banners"]
    for (var c = 0; c < cats.length; c++) {
      var list = p.cosmetics[cats[c]] || []
      for (var i = 0; i < list.length; i++) {
        if (list[i] && Number(list[i].cost) === 0 && list[i].id)
          out.push(String(list[i].id))
      }
    }
    return out
  }

  function defaultEquipped(id) {
    var p = library.get(id)
    var skin = (p && p.defaultSkin) ? String(p.defaultSkin) : "pink"
    return {
      "skin": skin,
      "effect": "sparkles",
      "companion": "none",
      "banner": "classic"
    }
  }
}
