# Sparklekeys — design notes

**Status:** 0.7.0  
**Id:** `kenhara.sparklekeys`  
**Peers:** Scriptural, Rocketlauncher, Encyclopedic, Enricherino, Compliantish

## Why

A six-year-old cannot hold "type O" and "look at my trophies" at once.
Synthesis-style: one problem owns the screen. Play is the hunt — the target
letter and the keyboard, nothing else. Trophies is a separate room: themed
4×5 emoji boards that light up as she levels up. Tap a trophy (locked or
unlocked) to inspect it: a zoomed emoji, a title, and a short blurb. Unlocking
also wears it on the bar chip. The chip is the persistent tray of who she is,
so the hunt never shares a stage with the collection.

0.1 persisted closet purchases she could not see. 0.2 made dress-up visible
with Phosphor glyphs. 0.3 restaged hunt and closet as separate rooms. 0.4
replaced the dressed-unicorn closet with IXL-style themed emoji boards
(one friend per level, row of five). 0.5 fills each board to a 4×5 grid
(20 trophies, four unlock per level), renames the room **Trophies**, and
auto-opens the board for her current level. 0.6 makes ✨ the product mark
(header glyph and default bar wear), moves sparkles off the Sky board so it
is not gray-while-worn, and adds in-room trophy inspect. Word Mode picks from
a pack tier every 10 levels (many short words, still no Shift). Displayed
level is uncapped (header can show Lv 21+); trophy boards still cap at 20.
Play stays hunt-only. Greeting uses her saved name (Jane). Default selected
trophy is sparkles. 0.7 adds a first-open avatar pick: twelve animals in a
3×4 (unicorn pre-selected), including eagle / horse / cow. That's me! wears
the pick on the bar chip even if that trophy is still locked. Eagle is
catalog-only (not a board trophy). Skip leaves ✨ and writes progress so the
name screen does not return. Existing progress.json users do not see
askingName again.

## The pack is the world

Nothing in the game logic is gendered or unicorn-specific. A pack is data:

- practice words in 4 tiers (keys `"1"`..`"4"`), one tier every 10 levels
- default accent / aura (static theme colors — pink for unicorn, ember for
  dragon). No rainbow hue timer.

Unicorn is the default pack. Dragon uses the same 4-tier word shape so
`characterPack: dragon` swaps words and accents with **zero logic changes**.
Kid-facing Look / Hat / Friend cosmetics are gone from pack objects. Packs
do not own the Trophies boards.

Built-in packs live in `PackLibrary.qml`. Access only through `get` / `ids` /
`exists`. Trophy boards live in the same library (`board` / `friend` /
`boardIds` / `boardForLevel`). `friend()` also resolves the identity mark
`sparkles` (✨), which is not a board tile, and falls back to the first-run
avatar catalog so eagle 🦅 resolves for the bar chip and signup tiles.

## Trophies boards

Four boards of twenty (4 rows × 5 cols). Level formula is
`1 + floor(totalEarned / 15)` — do not slow stars. Displayed level (header,
bar tooltip) is **uncapped**. `boardForLevel` / trophy unlocks still clamp
at 20. After 20, Trophies stay complete (Wild board); the header can show
Lv 21+. Four trophies unlock per level, filling left-to-right,
top-to-bottom. A board unlocks when she reaches that board's first trophy
level (the previous board is complete at the same moment).

| Board   | Unlocks | Levels | 4 per level (ids) |
|---------|---------|--------|-------------------|
| Friends | Lv 1    | 1–5    | unicorn…front-chick |
| Garden  | Lv 6    | 6–10   | blossom…tanabata |
| Sky     | Lv 11   | 11–15  | star, fireworks…wave |
| Wild    | Lv 16   | 16–20  | bear…whale2 |

Wide-adoption emoji only (mostly Unicode 6.0; unicorn and sun-with-face are
8.0). No new-era emoji on boards (no fox, butterfly, owl, fairy, wand).
Eagle 🦅 is first-run catalog only — do not add it as a 21st Friends tile.

Emoji `Text` must **not** set `font.family` to monospace / `contentFontFamily`
— that tofu's color emoji. Leave `font.family` unset on emoji-only Text so
the system color-emoji font (Noto Color Emoji) is used. The mixed `+N ⭐`
award overlay is the same: do not set `font.family` (bar/system emoji font).
Labels (Lv N, room chrome) can use `contentFontFamily`.

`isFriendUnlocked(id)` is `level >= that trophy's level` (identity `sparkles` is always unlocked).
`isBoardUnlocked(id)` is `level >= that board's unlockLevel`.
`boardForLevel(level)` is friends (1–5), garden (6–10), sky (11–15),
wild (16–20); the argument is clamped to 20 so Lv 21+ still opens Wild.
`showBoardForLevel()` sets `currentBoardId` from `boardForLevel(store.level)`
and bumps `boardRev`. Call it from `setViewMode("closet")`, when level
increases while `viewMode` is closet, and on panel open if already in closet.
Do **not** snap back while she is paging Prev/Next in the same visit.

Unlocks are level-gated only — do not spend stars to buy trophies.

`selectedFriend` (default `sparkles`) persists. `selectedEmoji` /
`selectedFriendLabel` are derived. `currentBoardId` is which board is
showing (session-snapped on Trophies enter; still written in schema 3).
`boardRev` bumps on select / page / award / snap so tiles refresh.

✨ is the **product mark**: always unlocked at level 1, identity-only (not a
21st Friends tile, not a Sky tile). `PackLibrary.identity` is
`{ id: "sparkles", label: "Sparkles", emoji: "✨", level: 1 }`; `friend()`
looks there first so the bar chip can wear it. The Sky slot that used to be
sparkles is fireworks `🎆` (`id: fireworks`, same level as that slot: 11).
Unicorn stays a Friends-board trophy; it is no longer the default wear or
header mark. Pack `characterPack: unicorn` is unchanged.

Every board trophy (and identity sparkles) has a kid-simple `blurb`.

Tap a tile (locked or unlocked) to open an in-room inspect overlay: dim
scrim over the board, a card with a huge emoji (~3–4× tile size), **title**,
and one or two short sentences. Unlocked: full-color emoji, and `selectFriend`
so it wears on the bar. Locked: gray/faded emoji (same stone+opacity as
tiles), real title + blurb, plus `Lv N` / keep practicing — do not wear a
locked trophy. Close by tapping the scrim or a **Close** pill. Escape already
closes the whole panel via PanelKeyCatcher; do not steal it for inspect.
One inspect at a time; opening another tile replaces the card. Overlay sits
on the Flickable viewport (not a new room, not a browser). Keep Prev/Next,
Back to hunt, 4×5 grid, auto-open current-level board, Flickable.

Locked tiles: stone-gray background (not accent), emoji at ~0.22 opacity,
`Lv N` caption. Color emoji cannot be tinted with `Text.color`; do not
import `QtQuick.Effects` (a failed import would take down the panel).
Unlocked tiles: full opacity, warmer accent-tinted tile. Next is only
tappable when the next board is unlocked; otherwise dim it
(`keep practicing` / `Lv 6`). Prev always works once she has left board 1.

Opening Trophies (and leveling up while that room is open) loads the board
for her current level. Prev/Next still let her browse unlocked boards after
that.

## Bar chip

WidgetButton is text-only. The selected emoji goes in an overlay `Text`
(no `font.family`) beside `WidgetButton.text`, plus an optional star count.
No Phosphor overlay, no hat overlay, no horn Shape. Tooltip:
`Sparklekeys · Friend · Lv N · stars`. This chip is the tray of who she is
during a lesson — first-open That's me! puts the chosen animal here (the old
unicorn slot). Skip / seed default is ✨. Header product mark stays ✨.

## Header

Two-line header so `Hi, Jane!` never clips:

1. Title (tiny ✨ Text, no `font.family`, no Phosphor glyph) + Play | Trophies room switch
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

Word Mode does **not** walk a flat `practiceWords` array. SparkleStore
`ensureWord` / `nextWord` call `wordTierForLevel(level)` and pick **only**
from that tier list (`practiceWords["1"]`..`"4"`). Tiers:

| Levels | Tier | Length | Notes |
|--------|------|--------|--------|
| 1–10   | 1    | 3–4    | lots of words, not a tiny loop |
| 11–20  | 2    | 4–5    | |
| 21–30  | 3    | 5–6    | |
| 31+    | 4    | 6–8    | last tier, still typeable |

Crossing a tier boundary picks a new word from the new tier. Lowercase
storage; match is still case-insensitive (no Shift). Unique within a tier
is enough.

## Name

First-open `askingName` flow stays. Centered column, no companion on the
left. Type a name, then pick a friend from a 3×4 of twelve animals
(unicorn 🦄, dragon 🐉, pig 🐷, lion 🦁, cat 🐱, dog 🐶, bunny 🐰, frog 🐸,
panda 🐼, eagle 🦅, horse 🐴, cow 🐮). Unicorn is pre-selected so That's me!
works with no extra tap. If the grid is tight in the first-run column,
tiles are `Style.space(52)` so That's me / Skip still sit on screen.
Emoji `Text` on those tiles has **no** `font.family`. Selected tile gets an
accent ring. Do not gray signup tiles (full color even when that trophy is
locked). The twelve live in `PackLibrary.avatars`; horse and cow are also
Friends trophies; eagle is catalog-only.

That's me! saves name + `selectFriend(avatarDraft)` (ids that are not one
of the twelve fall back to unicorn). Empty name is allowed — still wears
the chosen avatar and `scheduleSave`. Wearing an avatar is allowed even if
that trophy is still locked on the board; inspect still only wears unlocked
trophies. Skip: no name, bar stays product default ✨ — do not force a board
animal — and `scheduleSave` so hydrate sets `askingName` false. `avatarDraft`
lives only while `askingName` (default `unicorn`).

Tapping the greeting does **not** edit the name (`beginNameEdit` remains
unused). No `· tap name` subtitle. Greeting example stays Jane.

## No-fail, shift-free, low text

- Wrong key: target wiggles, hint key glows brighter. No red X, no timer, no
  score loss, no streak reset.
- Match compares `event.text.toLowerCase()` — she never needs Shift.
- Big letter + keyboard hint carry Play. Emoji trophies carry the Trophies
  room and the bar chip (kid reads the picture; tiles are emoji-only, with
  `Lv N` on locked). Tap a tile to inspect (big emoji + title + blurb).
- The +1 ⭐ award flash (and streak / word / daily variants) overlays the
  letter. It must not live in the hunt Column with `visible`/`height`
  0→implicitHeight — that shoves the keyboard down on a hit. Column height
  stays constant. Do not set `font.family` on that mixed `+N ⭐` Text.

## Progress lives in share, not cache

`${XDG_DATA_HOME:-$HOME/.local/share}/sparklekeys/progress.json`

A one-shot `mkdir -p -m 0700` runs before the first FileView save so a
missing data dir does not drop stars. FileView I/O itself is unchanged.

`childName` is typed in-panel (first exercise) and stored here, not in the
manifest schema.

`schemaVersion` 3. Persist `selectedFriend` (and last-viewed `currentBoardId`
for shape stability). Hydrate old `selectedFriend` ids that still exist
(unicorn, cat, sparkles, …). Unknown ids → sparkles. The twelve first-run
avatars stay worn even if that trophy is still locked. Hydrate old stars / name / stats.
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

## Non-goals (0.7)

Network, multi-child profiles, marketplace submit, home-row curriculum,
user-dropped packs, dressing-room cosmetics, Phosphor character overlays,
tap-name, remote Image/SVG, CI / GitHub Actions, `QtQuick.Effects` (do not
risk panel load).
