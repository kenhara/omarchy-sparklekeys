# Sparklekeys — design notes

**Status:** 0.2.0  
**Id:** `kenhara.sparklekeys`  
**Peers:** Scriptural, Rocketlauncher, Encyclopedic, Enricherino, Compliantish

## Why

A six-year-old who loves unicorns *and* loves configuring things. The loop is
tiny on purpose: type a letter → earn a star → buy a hat or look → **see it**
on the character and the bar.

0.1 persisted closet purchases she could not see (emoji face, faint halo,
tiny friend, banner wash). 0.2 makes dress-up visible: Phosphor character,
hat overlay, friend overlay, skin tint, bar chip icon.

## The pack is the world

Nothing in the game logic is gendered or unicorn-specific. A pack is data:

- `character` — PhosphorIcon name (`unicorn` / `dragon`), not emoji
- practice words
- default skin
- cosmetics: skins (aura/accent tint), hats (phosphor overlay), companions
  (friend glyph). Effects stay in data for celebration bursts but are not a
  Closet row. Banners dropped from closet data.

Unicorn is the default pack. Dragon is a stub so `characterPack: dragon`
swaps the whole world with **zero logic changes**.

Built-in packs live in `PackLibrary.qml`. Access only through `get` / `ids` /
`exists`.

Cosmetic ids are unique across a pack (rainbow skin is `rainbow`; the
celebration style is `rainbow-burst`, never the same id). Hat `none` and
friend `none` share the free `none` unlock — both cost 0.

## Character rendering

`CharacterView` draws a local PhosphorIcon (Item + Shape + PathSvg,
viewBox 0 0 256 256, tint via `color`). No `Image.source`, no remote SVG,
no webfont. Phosphor has no unicorn or dragon glyph — both alias to the
official regular `horse` path. Hats and friends use crown, baseball-cap,
flower-lotus, star, butterfly, cat, egg.

Skins tint the halo **and** the Phosphor fill. Rainbow hue-shifts both
while the panel is open (timer paused when `!opened`).

Emoji `Text` is last-resort fallback if a path is missing.

`CharacterView` is the companion on the Play stage (left) and the live
Closet preview (left). The header is a slim product title — no second
character. Buying a hat updates the Closet model in place.

## Bar chip

WidgetButton is text-only. Match Rocketlauncher: em-space in `text` plus a
sibling PhosphorIcon overlay tinted with `skinAccent`. Optional star count
as the text after the em-space. Tooltip: `Sparklekeys · Lv N · stars`.

## Closet

Kid-facing rows: **Look / Hat / Friend** only. No Effects or Banners
store rows. `equippedEffect` defaults to sparkles; rainbow skin maps to
the rainbow burst internally.

Cards show a Phosphor preview plus wearing / tap to wear / ⭐ cost /
keep practicing. Lede: "Buy a look. It stays on your unicorn."

`closetRev` bumps on buy/equip/award so function-backed card state
notifies.

Hats persist as `hat` in `equippedByPack`. Old `banner` keys are ignored
on hydrate. `schemaVersion` 2.

## Levels

From `totalEarned` (never spendable `stars`, so buying does not de-level):

`level = 1 + floor(totalEarned / 15)`, cap 20.

Shown as `Lv N` in the header job-line (`Hi, Name!` · pack · Lv N) next
to the product title, with stars and a thin progress to the next level.

## Letters / Words

A two-sided switch (Letters | Words) with a sliding selected pill. Only
on Play. Not a third TabPill. `persistSetting('startMode', …)` the same
way Panel already persists schema knobs.

## Name

First-open `askingName` flow stays. Tapping the greeting does **not**
edit the name (`beginNameEdit` remains unused). No `· tap name` subtitle.

## No-fail, shift-free, low text

- Wrong key: target wiggles, hint key glows brighter. No red X, no timer, no
  score loss, no streak reset.
- Match compares `event.text.toLowerCase()` — she never needs Shift.
- Big letter + keyboard hint + Phosphor character carry the UI.

## Progress lives in share, not cache

`${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`

A one-shot `mkdir -p -m 0700` runs before the first FileView save so a
missing data dir does not drop stars. FileView I/O itself is unchanged.

`childName` is typed in-panel (first exercise) and stored here, not in the
manifest schema.

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
- Slim header: Phosphor unicorn + "Sparklekeys", then
  `Hi, Name!` · pack · Lv N, then stars. Unofficial footer.
- Play is a two-column stage (companion | letter box) over a full-width
  keyboard floor. Closet is preview | cards, not a card dump.
- Distinct primary vs secondary: Play/Closet tabs; Letters/Words is a switch;
  Sound is filled when on, outline when off

## Economy

- +1 ⭐ per correct letter
- +2 ⭐ every 5-in-a-row (no reset on a miss)
- +5 ⭐ the first time `dailyGoal` is hit in a local day
- Word complete: +2 bonus and a bigger burst
- Closet: free default in every kid-facing category; cheap first unlocks (10 ⭐)

## Sound

Kenney Interface Sounds (CC0) bundled as `sounds/hit.wav` (correct letter)
and `sounds/sparkle.wav` (word / daily / special). `SoundEffect` +
`Qt.resolvedUrl` only — no user path, no Image/file tricks, no freedesktop
theme, no `pw-play`. `playHit(special)` from `awardStars` (which
`noteCorrectLetter` already calls). `miss()` is silence. Volume 0.5.
Cooldown 90 ms. Stop when `!panelOpen`. Default `soundEnabled` ON.
In-panel Sound toggle via `persistSetting('soundEnabled', …)`.

## Non-goals (0.2)

Network, multi-child profiles, marketplace submit, home-row curriculum,
user-dropped packs, kid-facing Effects/Banners store.
