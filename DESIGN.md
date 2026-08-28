# Sparklekeys — design notes

**Status:** 0.1.0  
**Id:** `kenhara.sparklekeys`  
**Peers:** Scriptural, Rocketlauncher, Encyclopedic, Enricherino, Compliantish

## Why

A six-year-old who loves unicorns *and* loves configuring things. The loop is
tiny on purpose: type a letter → earn a star → spend it on a look she can see.
v1 is something she can use this week, then we iterate from her feedback.

## The pack is the world

Nothing in the game logic is gendered or unicorn-specific. A pack is data:

- character glyph (emoji codepoint in v1)
- practice words
- default skin
- cosmetics: skins (aura/accent), effects (celebration style), companions
  (friend glyph), banners (panel wash + greeting style)

Unicorn is the default pack. Dragon is a stub so `characterPack: dragon`
swaps the whole world with **zero logic changes**. A later "boy version" is
just another pack. Full theming is already in the same shape: skins tint the
scene, banners wash the panel.

Built-in packs live in `PackLibrary.qml`. Access only through `get` / `ids` /
`exists` so a later FileView merge of `packs/*.json` and
`~/.config/sparklekeys/packs/` is one loader change.

## Character rendering

v1 renders a large emoji `Text` (Noto Color Emoji on Arch/Omarchy). Adding a
pig or dog pack is a one-codepoint data change.

Emoji is not recolorable, so **skins recolor the scene**: a soft aura behind
the glyph, pack accent on chrome, celebration tint, banner wash. Isolated in
`CharacterView.qml` so v2 can drop in QML `Shape`/`Path` vector art (the
PhosphorIcon approach) without touching Letter Hunt or the economy.

## No-fail, shift-free, low text

- Wrong key: target wiggles, hint key glows brighter. No red X, no timer, no
  score loss, no streak reset.
- Match compares `event.text.toLowerCase()` — she never needs Shift.
- Big letter + keyboard hint + emoji carry the UI. Words stay short.

## Progress lives in share, not cache

`${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`

Sibling plugins cache under `~/.cache`. Stars are earned. A cache cleaner
must not wipe them. `FileView { atomicWrites: true }` — no Python writer.

`childName` is typed in-panel (first exercise) and stored here, not in the
manifest schema (string knobs may be unsupported; avoids editing `shell.json`
for a name).

Unlocks and equips are keyed by pack so worlds stay separate.

## Shell contract

Copy Scriptural / Rocketlauncher:

- `bar-widget` only, nested `Panel.qml` via `Loader`
- `BarWidget` forwards `opened` / `open()` / `close()` / `toggle()` /
  `closeForPopoutSwitch()` and `injectPanel()` (`bar`, `settings`,
  `anchorItem`, `hostWidget`, `store`)
- `Panel { manageIpc: false }` → `KeyboardPanel { focusTarget: keyCatcher }` →
  `PanelKeyCatcher` (`Keys.onPressed`, Escape closes)
- No `import "."` in Panel (shadows `qs.Ui` Panel under Loader)
- `Style.font.body` / `bodySmall` / `caption` only
- Theme tokens lead (`bar.foreground`, `Color.popups.background`); pack
  accents overlay, they do not replace the palette
- Pause celebration / wiggle / rainbow hue when `!opened`
- Store is `Item`-wrapped

## Economy

- +1 ⭐ per correct letter
- +2 ⭐ every 5-in-a-row (no reset on a miss)
- +5 ⭐ the first time `dailyGoal` is hit in a local day
- Word complete: +2 bonus and a bigger burst
- Closet: free default in every category; cheap first unlocks (10 ⭐)

## Non-goals (v1)

Sound (reserved behind `soundEnabled`), network, multi-child profiles,
marketplace submit, home-row curriculum, vector characters, user-dropped
packs. Those stay data-shaped so they do not require a rewrite.
