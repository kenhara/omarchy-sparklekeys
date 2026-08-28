import QtQuick

// Built-in packs as data. Adding a world = add one object here (+ schema enum).
// Future: merge packs/*.json and ~/.config/sparklekeys/packs/*.json via FileView.
// Access only through get() / ids() / exists() so that path stays one change.
QtObject {
  id: library

  // Unicorn (full) + dragon (stub). character is a PhosphorIcon name, not emoji.
  readonly property var packs: ({
    "unicorn": {
      "id": "unicorn",
      "displayName": "Unicorn",
      "character": "unicorn",
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
          { "id": "rainbow-burst", "label": "Rainbow Burst", "cost": 15, "style": "rainbow" },
          { "id": "stars", "label": "Star Shower", "cost": 20, "style": "stars" },
          { "id": "confetti", "label": "Confetti", "cost": 20, "style": "confetti" }
        ],
        "hats": [
          { "id": "none", "label": "None", "cost": 0, "phosphor": "" },
          { "id": "crown", "label": "Crown", "cost": 10, "phosphor": "crown" },
          { "id": "cap", "label": "Cap", "cost": 10, "phosphor": "baseball-cap" },
          { "id": "flower", "label": "Lotus", "cost": 15, "phosphor": "flower-lotus" }
        ],
        "companions": [
          { "id": "none", "label": "None", "cost": 0, "phosphor": "" },
          { "id": "star", "label": "Star", "cost": 10, "phosphor": "star" },
          { "id": "butterfly", "label": "Butterfly", "cost": 15, "phosphor": "butterfly" },
          { "id": "kitten", "label": "Kitten", "cost": 25, "phosphor": "cat" }
        ]
      }
    },
    "dragon": {
      "id": "dragon",
      "displayName": "Dragon",
      "character": "dragon",
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
        "hats": [
          { "id": "none", "label": "None", "cost": 0, "phosphor": "" },
          { "id": "crown", "label": "Crown", "cost": 10, "phosphor": "crown" },
          { "id": "cap", "label": "Cap", "cost": 10, "phosphor": "baseball-cap" },
          { "id": "flower", "label": "Lotus", "cost": 15, "phosphor": "flower-lotus" }
        ],
        "companions": [
          { "id": "none", "label": "None", "cost": 0, "phosphor": "" },
          { "id": "egg", "label": "Egg", "cost": 10, "phosphor": "egg" },
          { "id": "star", "label": "Star", "cost": 15, "phosphor": "star" }
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
    if (!p || !p.cosmetics) return ["none"]
    var cats = ["skins", "effects", "hats", "companions"]
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
      "hat": "none"
    }
  }
}
