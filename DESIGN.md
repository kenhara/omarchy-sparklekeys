# Sparklekeys — design notes

**Status:** 0.5.0  
**Id:** `kenhara.sparklekeys`  
**Peers:** Scriptural, Rocketlauncher, Encyclopedic, Enricherino, Compliantish

## Why

A six-year-old cannot hold "type O" and "look at my trophies" at once.
Synthesis-style: one problem owns the screen. Play is the hunt — the target
letter and the keyboard, nothing else. Trophies is a separate room: themed
4×5 emoji boards that light up as she levels up. Tap an unlocked trophy to
wear it on the bar chip. The chip is the persistent tray of who she is, so
the hunt never shares a stage with the collection.

0.1 persisted closet purchases she could not see. 0.2 made dress-up visible
with Phosphor glyphs. 0.3 restaged hunt and closet as separate rooms. 0.4
replaced the dressed-unicorn closet with IXL-style themed emoji boards
(one friend per level, row of five). 0.5 fills each board to a 4×5 grid
(20 trophies, four unlock per level), renames the room **Trophies**, and
auto-opens the board for her current level. Play stays hunt-only. Greeting
uses her saved name (Jane). Default selected trophy is the unicorn.

## The pack is the world

Nothing in the game logic is gendered or unicorn-specific. A pack is data:

- practice words
- default accent / aura (static theme colors — pink for unicorn, ember for
  dragon). No rainbow hue timer.

Unicorn is the default pack. Dragon is a stub so `characterPack: dragon`
swaps words and accents with **zero logic changes**. Kid-facing Look / Hat /
Friend cosmetics are gone from pack objects. Packs do not own the Trophies
boards.

Built-in packs live in `PackLibrary.qml`. Access only through `get` / `ids` /
`exists`. Trophy boards live in the same library (`board` / `friend` /
`boardIds` / `boardForLevel`).

## Trophies boards

Four boards of twenty (4 rows × 5 cols). Level formula is
`1 + floor(totalEarned / 15)`, cap 20. Four trophies unlock per level,
filling left-to-right, top-to-bottom. A board unlocks when she reaches that
board's first trophy level (the previous board is complete at the same
moment).

| Board   | Unlocks | Levels | 4 per level (ids) |
|---------|---------|--------|-------------------|
| Friends | Lv 1    | 1–5    | unicorn…front-chick |
| Garden  | Lv 6    | 6–10   | blossom…tanabata |
| Sky     | Lv 11   | 11–15  | star…wave |
| Wild    | Lv 16   | 16–20  | bear…whale2 |

Wide-adoption emoji only (mostly Unicode 6.0; unicorn and sun-with-face are
8.0). No new-era emoji (no fox, butterfly, owl, fairy, wand).

Emoji `Text` must **not** set `font.family` to monospace / `contentFontFamily`
— that tofu's color emoji. Leave `font.family` unset on emoji-only Text so
the system color-emoji font (Noto Color Emoji) is used. Labels (Lv N, room
chrome) can use `contentFontFamily`.

`isFriendUnlocked(id)` is `level >= that trophy's level`.
`isBoardUnlocked(id)` is `level >= that board's unlockLevel`.
`boardForLevel(level)` is friends (1–5), garden (6–10), sky (11–15),
wild (16–20).
`showBoardForLevel()` sets `currentBoardId` from `boardForLevel(store.level)`
and bumps `boardRev`. Call it from `setViewMode("closet")`, when level
increases while `viewMode` is closet, and on panel open if already in closet.
Do **not** snap back while she is paging Prev/Next in the same visit.

Unlocks are level-gated only — do not spend stars to buy trophies.

`selectedFriend` (default `unicorn`) persists. `selectedEmoji` /
`selectedFriendLabel` are derived. `currentBoardId` is which board is
showing (session-snapped on Trophies enter; still written in schema 3).
`boardRev` bumps on select / page / award / snap so tiles refresh.

Tap an unlocked trophy to select it (accent ring). Locked tiles: stone-gray
background (not accent), emoji at ~0.22 opacity, `Lv N` caption. Color emoji
cannot be tinted with `Text.color`; do not import `QtQuick.Effects` (a failed
import would take down the panel). Unlocked tiles: full opacity, warmer
accent-tinted tile. Next is only tappable when the next board is unlocked;
otherwise dim it (`keep practicing` / `Lv 6`). Prev always works once she
has left board 1.

Opening Trophies (and leveling up while that room is open) loads the board
for her current level. Prev/Next still let her browse unlocked boards after
that.

## Bar chip

WidgetButton is text-only. The selected emoji goes in an overlay `Text`
(no `font.family`) beside `WidgetButton.text`, plus an optional star count.
No Phosphor overlay, no hat overlay, no horn Shape. Tooltip:
`Sparklekeys · Friend · Lv N · stars`. This chip is the tray of who she is
during a lesson.

## Header

Two-line header so `Hi, Jane!` never clips:

1. Title (tiny 🦄 Text, no Phosphor glyph) + Play | Trophies room switch
   (Trophies is longer than Friends — size the switch so the label fits)
2. Greeting on its own line (`Hi, Name!`, wrap, no ElideRight) with Lv,
   stars, and Sound on the right

Unofficial footer under the body. Room switch is hidden until That's me! /
Skip. Internal `viewMode` stays `"closet"` so call sites do not churn; the
kid-facing label is **Trophies**.

## Scroll

The body below the header (Play / Trophies) sits in a `Flickable` with
`clip: true`, vertical flick, `contentHeight` from the inner column.
`KeyboardPanel.contentHeight` uses `fittedContentHeight` of the desired
(unclamped) height: if the board is short, hug content; if clamped, the
Flickable fills the leftover height and overflow scrolls. Four rows overflow
more often than 0.4's single row — keep the Flickable; do not drop it.

## Letters / Words

A two-sided switch (Letters | Words) with a sliding selected pill. Only
on Play, under the letter. Not a third TabPill. `persistSetting('startMode', …)` the same
way Panel already persists schema knobs.

## Name

First-open `askingName` flow stays. Centered field, no companion on the
left. Tapping the greeting does **not** edit the name (`beginNameEdit`
remains unused). No `· tap name` subtitle.

## No-fail, shift-free, low text

- Wrong key: target wiggles, hint key glows brighter. No red X, no timer, no
  score loss, no streak reset.
- Match compares `event.text.toLowerCase()` — she never needs Shift.
- Big letter + keyboard hint carry Play. Emoji trophies carry the Trophies
  room and the bar chip (kid reads the picture; tiles are emoji-only, with
  `Lv N` on locked).

## Progress lives in share, not cache

`${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`

A one-shot `mkdir -p -m 0700` runs before the first FileView save so a
missing data dir does not drop stars. FileView I/O itself is unchanged.

`childName` is typed in-panel (first exercise) and stored here, not in the
manifest schema.

`schemaVersion` 3. Persist `selectedFriend` (and last-viewed `currentBoardId`
for shape stability). Hydrate old `selectedFriend` ids that still exist
(unicorn, cat, …). Unknown ids → unicorn. Hydrate old stars / name / stats.
Ignore old `unlocked` / `equipped` / hat / skin for gameplay; do not wipe
those file keys if present.

Pack accent / aura come from the pack's default skin colors (pink / ember)
as static theme accents. Celebration keeps default sparkles.

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
- Pause celebration / wiggle when `!opened`
- Store is `Item`-wrapped
- Two-line header: title + Play | Trophies, then greeting line (Lv + stars +
  Sound), unofficial footer. `contentHeight` uses `fittedContentHeight`.
- Play is hunt-only (target + keyboard floor). Trophies is themed 4×5 unlock
  boards. Do not invent menus. Letters|Words stays under the letter on Play.
  Sound stays by the stars.

`CharacterView` is unused (file may remain on disk). `PhosphorIcon.qml` can
stay on disk for Celebration bursts; do not load it from Panel / Bar /
Closet.

## Economy

- +1 ⭐ per correct letter
- +2 ⭐ every 5-in-a-row (no reset on a miss)
- +5 ⭐ the first time `dailyGoal` is hit in a local day
- Word complete: +2 bonus and a bigger burst
- Trophies unlock by level from `totalEarned` (spending is gone; buying does
  not exist, so earning never de-levels)

## Sound

Kenney Interface Sounds (CC0) bundled as `sounds/hit.wav` (correct letter)
and `sounds/sparkle.wav` (word / daily / special). `SoundEffect` +
`Qt.resolvedUrl` only — no user path, no Image/file tricks, no freedesktop
theme, no `pw-play`. `playHit(special)` from `awardStars` (which
`noteCorrectLetter` already calls). `miss()` is silence. Volume 0.5.
Cooldown 90 ms. Stop when `!panelOpen`. Default `soundEnabled` ON.
In-panel Sound toggle via `persistSetting('soundEnabled', …)`.

## Non-goals (0.5)

Network, multi-child profiles, marketplace submit, home-row curriculum,
user-dropped packs, dressing-room cosmetics, Phosphor character overlays,
tap-name, remote Image/SVG, CI / GitHub Actions, `QtQuick.Effects` (do not
risk panel load).
