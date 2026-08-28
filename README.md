# Sparklekeys

Letter Hunt for a first keyboard. A six-year-old types a letter, earns a star,
and spends stars in the Closet on skins, effects, friends, and banners.

The world is a **pack** — unicorn ships as the default; dragon is a stub so
switching characters is data, not a rewrite. Local only. No network.

**ID:** `kenhara.sparklekeys`  
**Author:** Harris Kenny  
**License:** MIT  
**Version:** 0.1.0

**Repo:** https://github.com/kenhara/omarchy-sparklekeys

### 0.1.0

- Letter Hunt (big target + on-screen keyboard hint). Wrong key wiggles; no
  penalty; Shift never required.
- Word Mode (schema `startMode`) using the active pack's short words.
- Stars: +1 per letter, +2 every 5-streak, +5 at the daily goal.
- Closet spends stars on pack cosmetics that change aura, celebration, friend,
  and banner wash.
- Child types their name in-panel (first exercise). Greeting becomes `Hi, Name!`.
- Unicorn pack + dragon stub. `characterPack` swaps the whole world.
- Progress at `~/.local/share/sparklekeys/progress.json` (not cache).
- Pure QML. No Python, no Process, no network.

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

1. **Left-click** the bar character (optional ⭐ count) to open the panel.
2. First open: type a name (letters only) and tap **That's me!** — or **Skip**.
3. Hunt the big letter. The matching key glows on the hint keyboard.
4. Right key → stars + celebration + next letter. Wrong key → wiggle + brighter
   glow. No timers, no game over, no score loss.
5. Open **Closet**. Tap an affordable locked look to buy; tap an unlocked look
   to wear. Can't afford it yet? It says **keep practicing** with a progress bar.
6. Escape or click-away closes. Progress survives a shell restart.

Letter order starts with the letters of the child's name (when set), then a
curated easy cycle.

### Controls

| Input | Action |
|-------|--------|
| Left-click bar | Toggle panel |
| Escape | Close panel |
| Letter keys | Hunt / type (case-insensitive) |
| Play / Closet | Switch views |
| Letters / Words | Toggle start mode (mirrors `startMode`) |
| Tap greeting | Edit name |
| Closet card | Buy if locked and affordable; else equip |
| Name: Enter | Save name |
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
| `showStarsOnBar` | boolean | `true` | ⭐ count on the bar chip |
| `soundEnabled` | boolean | `false` | Reserved; no audio in v1 |

```sh
omarchy bar set kenhara.sparklekeys characterPack dragon
omarchy bar set kenhara.sparklekeys letterCase lower
omarchy bar set kenhara.sparklekeys startMode words
omarchy bar set kenhara.sparklekeys dailyGoal 20
omarchy bar set kenhara.sparklekeys showStarsOnBar true
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

## Data

- **Progress:** `${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`
  Written with Quickshell `FileView` (`atomicWrites`). Missing or corrupt file
  seeds a working default game.
- **Why not `~/.cache`:** this is earned progress. A cache cleaner must not
  wipe her stars. Intentional divergence from sibling plugins.
- **No network.** No Python. No `Process`. No clipboard or `xdg-open` helpers.

## Layout

```
manifest.json       # kenhara.sparklekeys @ 0.1.0
qmldir
BarWidget.qml       # bar chip + Loader → Panel; owns SparkleStore
Panel.qml           # KeyboardPanel + Play / Closet
SparkleStore.qml    # state, economy, FileView progress
PackLibrary.qml     # unicorn + dragon stub
PlayView.qml
ClosetView.qml
CharacterView.qml
KeyboardHint.qml
Celebration.qml
StarCounter.qml
DESIGN.md
REPO.md
LICENSE
README.md
```

## Security baseline

- No API keys. No outbound network.
- Disk: one progress file under `~/.local/share/sparklekeys/`.
- Child name is letters-only, length-capped, shown as `Text.PlainText`.
- MIT at repo root.

## License

MIT — see [LICENSE](LICENSE).
