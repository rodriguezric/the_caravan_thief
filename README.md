# The Caravan Thief

*Sword Stories*, entry one. A heist JRPG about a thief, a cursed sword, and the
difference between taking something and owning it. Made in Godot 4.6.

The story and its systems come from the series bible in
`../sword_stories/docs/00_Sword_Stories_Series_Game_Framework.md` and the story
brief `../sword_stories/docs/01_the_caravan_thief.md`. The engine is built on
the one from `../pumpkin_man`: the same code-drawn chibi art style, screen flow,
achievement pattern, multiple-ending structure and control scheme.

Everything, art and sound included, is generated in code.

## Version

`config/version` in `project.godot` (shown on the title screen), mirrored in
`export_presets.cfg` (`version/name`; Android `version/code` = major*10000 +
minor*100 + patch). Every change bumps it: **release.feature.bugfix**, so a
bug fix bumps the right number, a new feature the middle one (bug fix reset to
0), a release the left one. Counting started at 0.0.0.

## Running

```bash
godot --path .                  # the game: company card -> opening -> title
./run_scene S6                  # jump straight into a scene (nothing is saved)
./faces                         # character / expression viewer
./faces mara worried "A line."  # start on a character and mood, with your own line
```

**Face viewer** (`tools/face_viewer.gd`): every character, every mood, at the sizes
the game uses (dialog portrait, a 3x close-up, 1x field sprites), talking in the
real dialog box. The lines are the ones that character actually says in that
mood in the story. Up/Down character, Left/Right mood (works mid-line too),
Z say the line, N next line, T type your own line, P pose (Shift+P back), F turn,
C copy `who / mood / pose / facing` to the clipboard (also printed in the
terminal), X quit.

Scene ids: `P1 S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11`.

## Controls

Same scheme as Pumpkin Man:

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrows / WASD | D-pad / left stick |
| OK, talk, examine | Z / Enter / Space | A |
| Back, pause menu | X / Esc | B / Start |
| Run | Shift (hold) | X |
| Skip lines you've already read | hold Shift in dialog | hold X |

Touch works too (the shell and `scripts/touch_controls.gd` are shared with Pumpkin Man):
a floating stick on the left, A/B/Menu buttons, tap menus directly, tap the picture to advance.

## Screens

BAYERIAN card -> opening (the blade falling through the ages) -> **Title**:
Continue / Load Game / New Game / Endings / Achievements / Records / Settings / Quit.

- **Save slots**: three. The game saves into the current journey's slot at the
  start of every scene. **Continue** picks up the most recently saved journey;
  **Load Game** lists the slots (scene, play time, act, place, when saved);
  **New Game** asks which slot to start in (overwriting one asks first). A save
  from before slots existed moves into slot 1 on the next launch.
- **Endings**: the ending gallery (hints for the ones you haven't found), the last
  route's decisive choices and which other endings it could have reached, and the
  **legacy records** the anthology keeps (Rook's fate, his closest bond, the blade's
  fate, the mark carved on it).
- **Settings**: volumes, reduced motion, screen shake, text speed, battle speed,
  controls, and stored-data clearing (each names its scope and asks first).
- In the field, **X/Esc** opens the pause menu: Status (Finesse, Suspicion,
  Loyalty, relationships, the blade's mastery tier, what Rook carries, lore and
  vault clues), Log (the dialog backlog), Achievements, Settings, Save & quit.

## The story

| Id | Scene | What it decides |
|---|---|---|
| P1 | Rope Burns | What Rook wants (a name, bread, never being poor) |
| S1 | The Broken Wheel | Help, watch, or rob the stranded caravan. Meeting Mara |
| S2 | The Dry Well | A stealth heist through a lantern-lit camp; looting under a time limit; lockpicking |
| S3 | The Sealed Chest | Draw the sword, call Fen, or leave it (Wick takes it instead) |
| S4 | The Rookery | Taking the blade from Wick; carving a name on it; Mara at the gate (talk her down or fight) |
| S5 | Kesh Crossing | The fence, the wanted poster, giving stolen things back, the Factor in a crowd |
| S6 | Campfire Accusation | The blade shows Mara reaching for it: confront, search her pack, or confess |
| S7 | The Shrine of the Unnamed | Faceless statues, a previous bearer's memory, three questions for the Factor |
| S8 | Fen's Bargain | Trade the blade for the crew's lives, refuse, or draw on Fen |
| S9 | The Bridge Ambush | Protect the crew, seize the payroll, or pursue the Factor |
| S10 | Teeth of the Pass | The cost, counted. A door where there is only rock |
| S11 | No Thief Can Reach | The Factor; the keystone choice; the epilogue |

Thematic variables: **Finesse** (evasion, crits, lock and pocket skill),
**Suspicion** (raised by the blade's arts and paranoid choices; at 6+ allies flicker
into violet-eyed thieves in battle and can be targeted), **Loyalty** (powers ally
assists). Relationships: **Mara** and **Fen**. The blade's mastery tier
(Invitation, Reliance, Dominion) grows with reliance and unlocks stronger arts.
Every change pops a small note on screen so choices visibly land.

### Endings

| Ending | How to reach it |
|---|---|
| The Legendary Thief | Finesse 6+ and Suspicion 6+, beat the Factor in battle, keep the blade, then beat your former friends too |
| Honor Among Thieves | Loyalty 6+, confess the visions to Mara (S6), protect the crew at the bridge (S9), give her the blade |
| The Unreachable Vault | Learn 2+ of the Factor's secrets (S7), find all three vault clues (the ledger in S3, Dosha's map in S5, the shrine altar in S7), find the door (S10), seal the blade inside |
| Empty Hands | Give back 2+ stolen things (S5), refuse the blade twice (leave it in S3, refuse to carve it in S4, agree to the trade in S8), kill no one you love; drop the blade |
| The Fence's Price | Sell it to Dosha (always available) |
| The Bearer Claimed | Keep it without the strength to keep it (Keep, when the Legendary route isn't earned) |

## Battles

Side-view, turn-based, built to feel physical. Turn order is a strip of faces at
the top. Enemies choose their move at the start of each round.

Commands follow the series' six families: **ATTACK**, **SKILL** (techniques, TP),
**SWORD** (Rook only, once he carries it: Foreknowledge, then Omen Edge, Parry
Sight, Thousand Hands, Mine as mastery grows; free, strong, each raises
Suspicion), **ITEM**, **GUARD** and **ACT** (steal, talk, run, objective actions).

- **Foreknowledge** (3 per battle, free) opens the blade's eye: violet lines show
  each enemy's target, and intent icons appear over their heads and in the turn strip.
- **Objectives** vary: defeat, escape (survive N turns or run for it), protect
  (crew members fight on their own; losses are casualties that carry into the
  story), persuade (ACT > Talk fills a meter), disarm (nonlethal foes kneel).
- **Fail forward**: losing a fight continues the story with injuries or changed
  circumstances. There is no game over.
- **Juice**: wind-ups, dashes that leave afterimages, hit-stop on impact, a camera
  punch toward each blow, sparks and blood flecks, knockback, damage numbers that
  pop and bounce, white hit flashes, a lagging white chunk on HP bars, CRITICAL
  stamps with slow motion, parries with sparks and counter-cuts, arrows and stones
  with trails, smoke bombs, assists with banners, victory poses. Omen Edge sends a
  violet ghost of Rook ahead along the path the blade has foreseen; Thousand Hands
  stops time, greys the world, and lands every cut at once when it restarts.
- Reduced motion turns off shake, hit-stop, camera punches and slow motion.

## Cutscenes

Most scenes are staged on the field maps with the walkabout characters, and the
full-screen vignettes use the same Actors at 2x. Everyone blinks, mouths move
while lines are typed (in the field, in vignettes and in battle), moods squash
the sprite, and actors strike poses: point, bow, shrug, think, cross arms, hands
on hips, laugh, facepalm, wave, kneel, cower, sit, sneak, pick a lock, reach,
raise a fist, hold the blade up. They hop, jump back, nod, shake their heads,
tremble, sigh, look around, lunge, and kick up dust when they run. Emote bubbles
pop over heads. Visions from the blade play in a violet world.

## Achievements (39)

Endings (each of the six, all six, three legacy records), choices (drawing or
leaving the blade, carving your name, confessing, searching, giving things back,
the poster, lore, the previous bearer's memory, the vault clues, the three bridge
choices, full trust with Mara and with Fen, maximum Suspicion, a clean run),
battle (talking Mara down, Foreknowledge, Thousand Hands, assists, a flawless
win, steals, losing and carrying on, striking a friend, escaping) and thievery
(an unseen heist, a clean lock, a clean lift, a full bag). They're saved
separately from progress, as in Protektor and Pumpkin Man.

## Art direction

The palette is "dusk on the Saltway" (`scripts/pal.gd`): a warm purple-black ink,
parchment highlights, dust, clay and canvas. Saturated colours each mean one
thing: **OMEN violet** is the blade (its voice, visions, Foreknowledge, Suspicion),
**BLOOD** is damage, **GLOW** is healing and trust, **CANDLE** is the interface.

## Code map

```
scripts/
  main.gd             shell: layers, screen flow, fades/wipes, choice notes, toasts, pause
  game.gd             autoload: profile, run save, variables, inventory, achievements store, settings
  data.gd             cast specs, items, supplies, scenes, endings
  achievements.gd     definitions + checks
  pal.gd pixbuf.gd pixfont.gd art*.gd    the code-drawn art
  art_people.gd       the chibi rig with poses and held weapons (48 x 40 canvas)
  sfx.gd songs.gd     synthesized effects, voices and procedural music
  actor.gd world.gd dialog.gd menu.gd cinema.gd fx.gd   field, stealth, dialogue, vignettes, particles
  battle/             battle.gd (flow + choreography), battle_unit.gd, battle_defs.gd, battle_results.gd
  minigames/          lockpick, pickpocket, loot grab
  screens/            opening, title, endings, settings, records, achievements, ending card, pause
  story/              story.gd (director), story_part.gd, story_act1..3.gd (the scenes)
tools/
  autotest.gd         automated runs and screenshots
  peek.gd             character contact sheets without running the game
```

## Testing

All runs write saves to `CT_DIR`, never to your real saves.

```bash
# play the whole story by itself, screenshots every 2 s
CT_TEST=story CT_AUTOPLAY=win CT_DIR=/tmp/ct CT_OUT=/tmp/ct CT_SHOT_EVERY=2 CT_EXPLORE=1 godot --path .
# steer it: CT_CHOICES=0,2,1 (choice indices in order), CT_SCENE=S6 (start there),
# CT_STATE="loyalty=7,confessed" (preset variables/flags), CT_SWORD=1 (use the blade's arts)
CT_TEST=battle:hunters CT_AUTOPLAY=win CT_SWORD=1 CT_OUT=/tmp/ct CT_SHOT_EVERY=0.25 godot --path .
CT_TEST=minigame:lockpick CT_DIR=/tmp/ct godot --path .
# balance: each key story fight N times with a sensible autopilot (heals, uses techniques)
CT_TEST=balance CT_AUTOPLAY=win CT_SPEED=6 CT_N=3 CT_DIR=/tmp/ct godot --headless --path .
# CT_ACT=talk makes the autopilot use ACT > Talk (persuasion routes); CT_SPEED sets autopilot battle speed
CT_TEST=shell CT_DIR=/tmp/ct CT_OUT=/tmp/ct godot --path .
CT_TEST=slots CT_DIR=/tmp/ct CT_OUT=/tmp/ct godot --path .   # save slots: old save -> slot 1, slot lists
CT_TEST=check godot --headless --path .          # parse-check every script
CT_TEST=icon godot --headless --path .           # regenerate icon.png
godot --headless --path . -s tools/peek.gd -- /tmp/ct poses   # people|poses|gestures|moods|creatures
```
