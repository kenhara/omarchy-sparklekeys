# Sparklekeys — design notes

**Status:** 0.4.0  
**Id:** `kenhara.sparklekeys`  
**Peers:** Scriptural, Rocketlauncher, Encyclopedic, Enricherino, Compliantish

## Why

A six-year-old cannot hold "type O" and "look at my friends board" at once.
Synthesis-style: one problem owns the screen. Play is the hunt — the target
letter and the keyboard, nothing else. Friends is a separate room: themed
emoji boards that unlock as she levels up. Tap an unlocked friend to wear it
on the bar chip. The chip is the persistent tray of who she is, so the hunt
never shares a stage with the collection.

0.1 persisted closet purchases she could not see. 0.2 made dress-up visible
with Phosphor glyphs. 0.3 restaged hunt and closet as separate rooms. 0.4
replaces the dressed-unicorn closet with IXL-style themed emoji boards.
Play stays hunt-only. Greeting uses her saved name (Jane). Default
selected friend is the unicorn.

## The pack is the world

Nothing in the game logic is gendered or unicorn-specific. A pack is data:

- practice words
- default accent / aura (static theme colors — pink for unicorn, ember for
  dragon). No rainbow hue timer.

Unicorn is the default pack. Dragon is a stub so `characterPack: dragon`
swaps words and accents with **zero logic changes**. Kid-facing Look / Hat /
Friend cosmetics are gone from pack objects. Packs do not own the Friends
boards.

Built-in packs live in `PackLibrary.qml`. Access only through `get` / `ids` /
`exists`. Friend boards live in the same library (`board` / `friend` /
`boardIds`).

## Friends boards

Four boards of five. Level formula is `1 + floor(totalEarned / 15)`, cap 20.
One friend unlocks per level. A board unlocks when she reaches that board's
first friend level (the previous board is complete at the same moment).

| Board   | Unlocks | Friends | Emoji | Levels |
|---------|---------|---------|-------|--------|
| Friends | Lv 1    | unicorn, cat, dog, bunny, frog | 🦄 🐱 🐶 🐰 🐸 | 1–5 |
| Garden  | Lv 6    | blossom, rose, sunflower, tulip, daisy | 🌸 🌹 🌻 🌷 🌼 | 6–10 |
| Sky     | Lv 11   | star, moon, rainbow, sparkles, sun | ⭐ 🌙 🌈 ✨ 🌞 | 11–15 |
| Wild    | Lv 16   | bear, panda, tiger, elephant, dragon | 🐻 🐼 🐯 🐘 🐉 | 16–20 |

Wide-adoption emoji only (mostly Unicode 6.0; unicorn is 8.0). No new-era
emoji (no wands, fairies, pixies).

Emoji `Text` must **not** set `font.family` to monospace / `contentFontFamily`
— that tofu's color emoji. Leave `font.family` unset on emoji-only Text so
the system color-emoji font (Noto Color Emoji) is used.

`isFriendUnlocked(id)` is `level >= that friend's level`.
`isBoardUnlocked(id)` is `level >= that board's unlockLevel`.
Unlocks are level-gated only — do not spend stars to buy friends.

`selectedFriend` (default `unicorn`) persists. `selectedEmoji` /
`selectedFriendLabel` are derived. `currentBoardId` is which board is
showing (persisted as last viewed). `boardRev` bumps on select / page /
award so tiles refresh.

Tap an unlocked friend to select it (accent ring). Locked tiles show the
same emoji at low opacity plus `Lv N`. Next is only tappable when the next
board is unlocked; otherwise dim it (`keep practicing` / `Lv 6`). Prev
always works once she has left board 1.

## Bar chip

WidgetButton is text-only. The selected emoji goes in `WidgetButton.text`,
plus an optional star count. No Phosphor overlay, no hat overlay, no horn
Shape. Tooltip: `Sparklekeys · Friend · Lv N · stars`. This chip is the
tray of who she is during a lesson.

## Header

Two-line header so `Hi, Jane!` never clips:

1. Title (tiny 🦄 Text, no Phosphor glyph) + Play | Friends room switch
2. Greeting on its own line (`Hi, Name!`, wrap, no ElideRight) with Lv,
   stars, and Sound on the right

Unofficial footer under the body. Room switch is hidden until That's me! /
Skip. Internal `viewMode` stays `"closet"` so call sites do not churn; the
kid-facing label is **Friends**.

## Scroll

The body below the header (Play / Friends) sits in a `Flickable` with
`clip: true`, vertical flick, `contentHeight` from the inner column.
`KeyboardPanel.contentHeight` uses `fittedContentHeight` of the desired
(unclamped) height: if the board is short, hug content; if clamped, the
Flickable fills the leftover height and overflow scrolls.

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
- Big letter + keyboard hint carry Play. Emoji friends carry the Friends
  room and the bar chip.

## Progress lives in share, not cache

`${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`

A one-shot `mkdir -p -m 0700` runs before the first FileView save so a
missing data dir does not drop stars. FileView I/O itself is unchanged.

`childName` is typed in-panel (first exercise) and stored here, not in the
manifest schema.

`schemaVersion` 3. Persist `selectedFriend` and last-viewed `currentBoardId`.
Hydrate old stars / name / stats. Ignore old `unlocked` / `equipped` / hat /
skin for gameplay; do not wipe those file keys if present.

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
- Two-line header: title + Play | Friends, then greeting line (Lv + stars +
  Sound), unofficial footer. `contentHeight` uses `fittedContentHeight`.
- Play is hunt-only (target + keyboard floor). Friends is themed unlock
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
- Friends unlock by level from `totalEarned` (spending is gone; buying does
  not exist, so earning never de-levels)

## Sound

Kenney Interface Sounds (CC0) bundled as `sounds/hit.wav` (correct letter)
and `sounds/sparkle.wav` (word / daily / special). `SoundEffect` +
`Qt.resolvedUrl` only — no user path, no Image/file tricks, no freedesktop
theme, no `pw-play`. `playHit(special)` from `awardStars` (which
`noteCorrectLetter` already calls). `miss()` is silence. Volume 0.5.
Cooldown 90 ms. Stop when `!panelOpen`. Default `soundEnabled` ON.
In-panel Sound toggle via `persistSetting('soundEnabled', …)`.

## Non-goals (0.4)

Network, multi-child profiles, marketplace submit, home-row curriculum,
user-dropped packs, dressing-room cosmetics, Phosphor character overlays,
tap-name, remote Image/SVG, CI / GitHub Actions.
