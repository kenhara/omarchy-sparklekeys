# Sparklekeys

Letter Hunt for a first keyboard. Play is hunt-only (the letter and the
keyboard). Closet is the dressing room. The bar chip is the character — who
she is during a lesson. Stars buy a look, hat, and friend she can **see**.

The world is a **pack** — unicorn ships as the default; dragon is a stub so
switching characters is data, not a rewrite. Local only. No network.

**ID:** `kenhara.sparklekeys`  
**Author:** Harris Kenny  
**License:** MIT  
**Version:** 0.3.0

**Repo:** https://github.com/kenhara/omarchy-sparklekeys

### 0.3.0

- Play is hunt-only: the target letter and the on-screen keyboard. Closet is
  the dressing room. The bar chip is the character during a lesson.
- One quiet Play | Closet pair in the header. Sound stays by the stars.
  Letters|Words stays under the letter on Play. No tap-the-unicorn to switch.
- Closet hero is a large CharacterView (top-center) with Look / Hat / Friend
  under it and a Back to hunt pill. Name-entry is a centered field.

### 0.2.1

- Unicorn horn (Shape on the Phosphor horse), idle sparkles, punchier correct-key burst. Panel hugs the keyboard. Sound sits by the stars; Letters|Words by the letter; tap the unicorn for the Closet.

### 0.2.0

- Phosphor character, hats, and friends (local Shape/Path, tintable). Closet
  purchases show on the character in Play and on the bar chip.
- Closet is Look / Hat / Friend only. No kid-facing Effects or Banners.
- Levels from total stars earned (`Lv N`, cap 20). Buying does not de-level.
- Letters | Words sliding switch on Play (not a third tab).
- Greeting is not a tap-to-rename control. First-open name flow stays.
- One play room: slim product header, companion + giant letter on a stage,
  keyboard as the floor. Closet keeps a live preview on the left.
- Cartoon sounds (Kenney Interface Sounds, CC0) bundled as
  `sounds/hit.wav` / `sounds/sparkle.wav`. In-panel Sound toggle; default ON.
  Misses stay silent.

### 0.1.0

- Letter Hunt (big target + on-screen keyboard hint). Wrong key wiggles; no
  penalty; Shift never required.
- Word Mode (schema `startMode`) using the active pack's short words.
- Stars: +1 per letter, +2 every 5-streak, +5 at the daily goal.
- Closet spends stars on pack cosmetics.
- Child types their name in-panel (first exercise). Greeting becomes `Hi, Name!`.
- Unicorn pack + dragon stub. `characterPack` swaps the whole world.
- Progress at `~/.local/share/sparklekeys/progress.json` (not cache).
- Pure QML. No Python, no network.

## Discoverability

Marketplace filing draft: category **Widgets** · tags `bar, quickshell`.
Display name stays **Sparklekeys**. Top-level `keywords` and
`barWidget.aliases` are for filing drafts — the bar-widget loader ignores them.

## Install

### From GitHub

```sh
omarchy plugin add https://github.com/kenhara/omarchy-sparklekeys.git --enable
omarchy bar move kenhara.sparklekeys --section right
```

### Local copy (this tree)

The **git repo root is the plugin** (`manifest.json` at root). On an Omarchy
machine:

```sh
mkdir -p ~/.config/omarchy/plugins ~/.local/share/sparklekeys
chmod 0700 ~/.local/share/sparklekeys
cp -a . ~/.config/omarchy/plugins/kenhara.sparklekeys

omarchy plugin validate ~/.config/omarchy/plugins/kenhara.sparklekeys
omarchy-shell shell rescanPlugins
omarchy plugin enable kenhara.sparklekeys
omarchy bar move kenhara.sparklekeys --section right
```

Hot reload applies on save under `~/.config/omarchy/plugins/`.

### Symlink (dev)

On the Omarchy machine (Latitude / UTM / the box that runs `omarchy-shell`):

```sh
mkdir -p ~/.config/omarchy/plugins ~/.local/share/sparklekeys
chmod 0700 ~/.local/share/sparklekeys
ln -sfn /path/to/omarchy-sparklekeys ~/.config/omarchy/plugins/kenhara.sparklekeys
omarchy plugin validate ~/.config/omarchy/plugins/kenhara.sparklekeys
omarchy-shell shell rescanPlugins
omarchy plugin enable kenhara.sparklekeys
omarchy bar move kenhara.sparklekeys --section right
```

Saving any file under the symlink hot-reloads the plugin.

Optional pre-flight if `qmllint` and `$OMARCHY_PATH` are available:

```sh
qmllint -I "$OMARCHY_PATH/shell" *.qml
```

## Play

1. **Left-click** the bar character (optional star count) to open the panel.
   That chip is who she is — the dressed unicorn lives there during a lesson.
2. First open: type a name (letters only) in the centered field and tap
   **That's me!** — or **Skip**.
3. Hunt the big letter. The matching key glows on the hint keyboard. Play is
   the hunt only — no companion, no Closet caption.
4. Right key → stars + celebration + next letter. Wrong key → wiggle + brighter
   glow. No timers, no game over, no score loss.
5. Tap **Closet** in the header (or open it from Play | Closet) to enter the
   dressing room. The large unicorn is the hero. Tap an affordable locked look
   to buy; tap an unlocked look to wear. Can't afford it yet? It says
   **keep practicing** with a progress bar. **Back to hunt** returns to Play.
   A hat you buy stays on the unicorn in Closet and on the bar chip.
6. Escape or click-away closes. Progress survives a shell restart.

Letter order starts with the letters of the child's name (when set), then a
curated easy cycle.

Level is `1 + floor(totalEarned / 15)`, capped at 20. Spending stars does not
lower the level.

### Controls

| Input | Action |
|-------|--------|
| Left-click bar | Toggle panel |
| Escape | Close panel |
| Letter keys | Hunt / type (case-insensitive) |
| Play / Closet (header) | Switch hunt ↔ dressing room |
| Back to hunt (Closet) | Return to the hunt |
| Letters / Words switch (under the letter, Play only) | Toggle start mode (mirrors `startMode`) |
| Sound pill (by stars) | Toggle cartoon hit / sparkle |
| Closet card | Buy if locked and affordable; else equip |
| Name: Enter | Save name (first-open flow) |
| Name: Backspace | Delete a letter |

## Configure

Parent-facing knobs. Child name, stars, unlocks, and equips live in
`progress.json`, not `shell.json`.

| Schema key | Type | Default | Purpose |
|------------|------|---------|---------|
| `characterPack` | enum `unicorn` `dragon` | `unicorn` | Character / theme world |
| `letterCase` | enum `upper` `lower` | `upper` | How targets are shown |
| `startMode` | enum `letters` `words` | `letters` | Letter Hunt or Word Mode |
| `dailyGoal` | integer 5–200 | `20` | Correct letters/day for the +5 bonus |
| `showStarsOnBar` | boolean | `true` | Star count on the bar chip |
| `soundEnabled` | boolean | `true` | Cartoon hit / sparkle (in-panel toggle) |

```sh
omarchy bar set kenhara.sparklekeys characterPack dragon
omarchy bar set kenhara.sparklekeys letterCase lower
omarchy bar set kenhara.sparklekeys startMode words
omarchy bar set kenhara.sparklekeys dailyGoal 20
omarchy bar set kenhara.sparklekeys showStarsOnBar true
omarchy bar set kenhara.sparklekeys soundEnabled true
```

Pack-swap proof: `characterPack dragon` switches glyph, words, and Closet
catalog with **zero logic changes**.

## Remove

```sh
omarchy plugin remove kenhara.sparklekeys
```

Optional progress cleanup (this **deletes earned stars**):

```sh
rm -rf ~/.local/share/sparklekeys
```

## Sound

Two tiny Kenney **Interface Sounds** clips (CC0) live in `sounds/`:

| File | When | Source clip |
|------|------|-------------|
| `hit.wav` | Correct letter | `confirmation_001.ogg` |
| `sparkle.wav` | Word complete, daily goal, special burst | `confirmation_002.ogg` |

Played with QtMultimedia `SoundEffect` via `Qt.resolvedUrl("sounds/hit.wav")`
(plugin-local only). Volume is modest (~0.5). A miss is silence — no-fail.
Toggle **Sound** in the panel (filled = on, outline = off). No extra package.
No freedesktop theme chimes. Credit: [Kenney.nl](https://kenney.nl/assets/interface-sounds)
— see `sounds/ATTRIBUTION.txt`.

## Data

- **Progress:** `${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`
  Written with Quickshell `FileView` (`atomicWrites`). The plugin `mkdir`s the
  data dir `0700` before the first save. Missing or corrupt file seeds a
  working default game.
- **Why not `~/.cache`:** this is earned progress. A cache cleaner must not
  wipe her stars. Intentional divergence from sibling plugins.
- **No network.** No Python. No clipboard or `xdg-open` helpers.

## Layout

```
manifest.json       # kenhara.sparklekeys @ 0.3.0
qmldir
BarWidget.qml       # bar chip + Loader → Panel; owns SparkleStore
Panel.qml           # KeyboardPanel + slim header (Play|Closet, Sound by stars)
SparkleStore.qml    # state, economy, FileView progress, SoundEffect
PackLibrary.qml     # unicorn + dragon stub (Phosphor names, hats)
PhosphorIcon.qml    # local Phosphor regular paths (MIT)
PlayView.qml
ClosetView.qml
CharacterView.qml
KeyboardHint.qml
Celebration.qml
StarCounter.qml
sounds/             # Kenney CC0 hit.wav + sparkle.wav
DESIGN.md
REPO.md
LICENSE
README.md
```

## Security baseline

- No API keys. No outbound network.
- Disk: one progress file under `~/.local/share/sparklekeys/` (dir 0700).
- Child name is letters-only, length-capped, shown as `Text.PlainText`.
- MIT at repo root. Phosphor regular glyphs bundled locally (MIT).
- Two Kenney Interface Sounds clips (CC0) under `sounds/`. No remote audio.

## License

MIT — see [LICENSE](LICENSE). Phosphor Icons path data is MIT
(https://phosphoricons.com).
