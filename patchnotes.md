# Patch Notes

## 2026-11-12 20:28 EST — `feature_stealth_and_transition_autotests` (v0.10.0)

Automated tests for stealth catches and field flashes between scenes.

- New `CT_TEST=stealth` scenario: in S2, walks Rook into a lantern and checks
  that exactly one fight happens and that he isn't re-spotted while hiding
  (`CT_HIDE_SECS`, default 6). It then walks him into a lantern again and
  checks the second catch is the dragged-out scene, not a second fight, and
  that it gets him into the cream wagon with `noise` and `injured` set.
  Prints `[auto] stealth PASS` or one FAIL line per problem.
- The `story` runner now watches transitions every frame. If the field shows
  for less than `CT_FLASH_MAX` seconds (default 0.8) between a battle,
  minigame or cutscene and the next cutscene, it prints `[auto] FLASH`, takes
  a screenshot (with `CT_OUT`) and counts the flash in a closing
  `[auto] transitions:` line. A full autoplay run currently reports 0.
- `CT_TEST=flashcheck` stages one such flash to prove the watcher catches it.
- `tools/autotest.gd`: `_stealth_test()`, `_watch_transitions()`, `_cover()`.
  `scripts/world.gd`: `spotted_count`. `scripts/story/story_act1.gd`: the S2
  autoplay steps aside when the `ct_hold` flag is preset.

## 2026-11-12 20:14 EST — `feature_close_bridge_backdrop_for_character_shots` (v0.9.0)

A close-up Gorge Bridge backdrop, so the S9 aftermath happens on the bridge
itself.

- New `bridge_near` cine: planks across the lower third with a breathing sag,
  rope rails and hangers, and the canyon's far wall falling away into shadow
  behind. `bridge_near_fall` is the same shot with the middle gone and rope
  ends and a plank swinging over the drop.
- Protect: the crew run across the deck at full size and finish spaced out
  along it, then hop. Payroll: Rook runs off with the strongbox while Bracken
  kneels mid-bridge against three hunters; the ropes go and he falls with the
  nearest one. Pursue: Rook runs at the Factor, the bridge snaps under him,
  and he ends up hanging from a rope end in the gap.
- The wide `gorge` picture stays as S9's establishing shot.
- `scripts/art_cine.gd`: `bridge_near()`, `bridge_near_fall()`,
  `_bridge_deck_y()`. `scripts/story/story_act3.gd`: `_s9_after()`, `_deck()`.
  `tools/autotest.gd`: `s9after:<branch>` plays one aftermath alone.

## 2026-11-12 20:03 EST — `feature_battle_formation_for_large_party` (v0.8.0)

Big parties line up in a readable two-row formation instead of a pile.

- In a battle with four or more party units, or any protected AI units (S9's
  "Ambush on Gorge Bridge!": Rook, Mara, Fen plus Wick and Bracken), the
  fighters stand in a staggered front row nearest the enemy. The protected
  units stand in the back row, in the gaps behind them, and everyone shrinks
  a little as the party grows (1.8x for four, 1.6x for five, 1.45x for six or
  more), so no one is cut off at the screen edge and every head stays visible.
- Parties of up to three fighters keep the classic slots and full size.
- `scripts/battle/battle.gd`: new `Battle.formation()`, used by `_ready()`'s
  party setup. `tools/autotest.gd`: `battle:bridge` plays the S9 lineup.

## 2026-11-12 19:59 EST — `feature_s6_vision_pacing_and_props` (v0.7.0)

S6's vision moves while it's narrated, the waterskin is real, and Wick walks
over in S8.

- S6 vision: Mara starts closer and crosses at 48 px/s while the narration
  line types, instead of about four silent seconds before it. The heartbeat
  and her reach land when she arrives.
- S6 confront: Mara steps back and lobs a small leather waterskin (new
  `waterskin` prop). It arcs into Rook's chest with a thud and drops at his
  feet before "It is, in fact, his waterskin."
- S8 night: Wick walks across the Rookery to sit by Rook at the stairs
  instead of appearing there.
- `scripts/story/story_act2.gd`: `scene_s6()`, new `_s6_throw_waterskin()`,
  `_s8_night()`. `scripts/art_props.gd`: `waterskin()`.

## 2026-11-12 19:46 EST — `feature_stealth_caught_consequence` (v0.6.0)

Getting caught at the Dry Well now has consequences instead of repeating the
same fight.

- First catch: the escape fight as before, then Rook comes to hidden behind
  the west wagon and the camp is awake: a fourth lantern guard walks the
  middle of the camp, every patrol walks faster and sees further, and the eye
  meter drains more slowly.
- Second catch: no second fight. The guards drag Rook to the fire, Wick
  stampedes the oxen from the dark, and in the chaos Rook cuts his way into
  the cream wagon: flags `injured` and `noise`, then on to S3. This also ends
  any chance of a caught-fight loop.
- `scripts/world.gd`: `alert_decay`, `raise_alertness()`.
  `scripts/story/story_act1.gd`: `_s2_spotted()` split into a first catch
  and `_s2_dragged_out()`; S2 autoplay with `CT_STATE=ct_caught` walks Rook
  into a lantern so test runs play both catches.

## 2026-11-12 19:35 EST — `feature_dont_show_sword_portrait` (v0.5.0)

The blade's lines no longer show a portrait.

- When the sword talks, the dialog box keeps its violet "omen" frame, its
  name tag and its voice, but no portrait frame, so it reads as a voice
  rather than a face on screen.
- `scripts/story/story.gd` `speaker("blade")`: dropped the `portrait` and
  `side` opts.

## 2026-11-12 03:28 EST — `feature_chipwave_songs` (v0.4.0)

A composed soundtrack: every music cue is now an ambient spaghetti-western
song instead of the generated chiptune.

- 16 cues, each written for its moment: a whistled version of the Sword
  Stories theme on the title (and in D major for the ending), a harmonica and
  hoof gallop on the road, a border-town trumpet waltz, harmonica and crickets
  by the camp fire, pizzicato twang for heists, a pocket-watch tick for
  tension, a whole-tone whistle and mission bell for the cursed blade, a
  harmonica waltz for loss, a twang-and-trumpet gallop for battles, an
  E Phrygian-dominant boss theme with choir, anvil and whips, a quick
  minigame tune, a victory fanfare that plays once before its loop, and
  buzzards on defeat.
- Shipped as Ogg Vorbis (about 7.3 MB for all 16, against roughly 60 MB
  as WAV).
- Code: `music/<cue>.py` builds `music/<cue>.chipwave` with `mt` and renders
  `music/<cue>.ogg` (`western_kit.py`, `story_kit.py`, `measure.py`,
  `music/README.md`). `Sfx.music()` loads `res://music/<cue>.ogg`, loops it
  (`LOOP_FROM` gives victory's loop point after the fanfare) and falls back to
  the songs.gd generator for a cue without one; `prerender()` skips composed
  cues. The recipe is `midi_maker/recipes/western_ambient.md`.

## 2026-11-11 12:30 EST — `bugfix_stealth_caught_fight_loop` (v0.3.16)

Getting caught sneaking through the S2 camp no longer traps you in a loop of
the same fight.

- After the "Caught in the lanterns!" battle, Rook was left standing exactly
  where he'd been seen, with the alert meter reset to zero; a guard still
  looking his way spotted him again in about half a second and the same
  battle started over, again and again. Now, after the fight:
  - Rook slips back to the dark west edge of the camp where he came in ("Back
    to the edge of the camp, where the lantern light gives out. Slower, this
    time.");
  - the guard who spotted him goes back to the start of his patrol round
    (position, route and facing — before, only his position jumped);
  - the guards can't raise the alert for 4 seconds, so nothing can re-trigger
    the fight immediately.
- `scripts/world.gd`: new `stealth_grace` timer (pauses alert build-up in
  `_update_guards()`), new `reset_guard(actor)`.
- `scripts/story/story_act1.gd`: `_s2_spotted()` uses them and moves Rook to
  tile (1, 9).

## 2026-11-11 12:26 EST — `bugfix_s3_leave_sword_wick_bracken_battle_unstaged` (v0.3.15)

The S3 "Leave it" route now shows how Wick ends up with the blade and how the
fight with Bracken starts, instead of jump-cutting to a battle.

- Before: Wick vanished the instant his hands touched the box, a hunter
  shouted from nowhere, and the battle cut in with Rook and Bracken outdoors
  although Bracken was never shown arriving.
- Now: the blade takes to Wick on screen (violet flash, his sword look and
  "omen" face); a hunter bursts into the wagon doorway and shouts; Rook yells
  "Out. OUT!" and the two of them bowl past him and out; outside in the
  lantern-lit camp, Rook and Wick run in, two hunters and a guard close from
  the other side, and Bracken charges in ("Nobody lays a hook on the boy.")
  before the battle starts. Rook tells Wick to stay behind them, which is why
  Wick only joins the fight on turn 2.
- `scripts/story/story_act1.gd`: `_s3_leave()` restaged (field beats in the
  wagon, then a `night_camp` cutscene leading into the `s3_wick` battle).

## 2026-11-11 12:20 EST — `bugfix_field_flash_between_battle_and_cutscene` (v0.3.14)

No more flashes of the old field map between a battle and a cutscene, between
two cutscenes, or between a cutscene and the next scene's title card.

- After a battle or minigame the game always faded back to the field, and
  closing a cutscene always dissolved to the field underneath — even when the
  very next thing was another cutscene or a scene change. You'd glimpse the
  previous map in between (e.g. S3's wagon interior three times during the
  escape, S1/S9's field with enemies still standing). Now:
  - after a battle/minigame the screen stays dark for a moment; if a cutscene
    or scene card follows, it comes straight up out of the dark; otherwise the
    field fades in as before;
  - a closing cutscene stays on screen if another cutscene is fading in over
    it or the screen is fading to ink, and only dissolves to the field when
    play actually returns to the field.
- `scripts/main.gd`: `screen_claim` / `claim_screen()` (bumped by `fade_out()`
  and `Cinema.open()`), `reveal_soon()` used by `battle()` and `minigame()`
  instead of an unconditional `fade_in()`.
- `scripts/cinema.gd`: `close()` returns at once and `_leave()` decides between
  staying under whatever claimed the screen and dissolving to the field.
- `scripts/story/story.gd`: `cine()` brings a cutscene up out of a dark screen
  instead of fading it in over the field.

## 2026-11-11 12:13 EST — `bugfix_bridge_cutscene_actors_below_bridge` (v0.3.13)

After holding the bridge in S9, the crew now actually run across the bridge.

- In the "Get the crew across" aftermath the runners were placed at the
  bottom of the picture, so they ran along the canyon floor far below the
  bridge. They now start at the near anchor and run along the deck itself,
  following its sag down to mid-span and back up, then step off onto the far
  cliff. Since the bridge is far off in that picture, they're drawn at half
  the usual size.
- `scripts/story/story_act3.gd`: `_s9_after()` "protect" builds each runner's
  path from the gorge bridge's deck curve (x 40-280, y 71-83) and spawns them
  at 1x scale.

## 2026-11-11 12:11 EST — `bugfix_gorge_fall_backdrop_solid_rectangle` (v0.3.12)

The snapped-bridge picture no longer has a flat dark rectangle in the middle.

- When the Gorge Bridge falls (S9 "pursue" route), the missing middle of the
  bridge was painted over with a single row's colour, leaving a solid block
  that stood out against the textured canyon behind Rook. The gap is now
  repainted with the canyon itself, and the far end of the bridge gets a few
  snapped ropes hanging into the drop to match the near end.
- `scripts/art_cine.gd`: the canyon pixel rule moved into `_gorge_px(x, y)`
  (used by `gorge()`, whose picture is unchanged); `gorge_fall()` repaints the
  gap with it and draws the far-end ropes.

## 2026-11-11 12:09 EST — `bugfix_ambush_hunters_spawn_over_chasm` (v0.3.11)

The S9 bridge ambush hunters now land on the bridge instead of hovering over
the canyon.

- The three hunters used to pop into existence on the open-canyon rows above
  and below the deck, floating in mid-air. They now vault up over the rail
  from the drop — starting just off the edge, fading in and hopping onto the
  planks — and land on the deck: one behind the crew, one in front of Rook,
  and one between Rook and the Factor.
- `scripts/story/story_act3.gd`: `scene_s9()` spawns the hunters on deck tiles
  (rows 6-7) and tweens each in from 16px over the edge.

## 2026-11-11 12:06 EST — `bugfix_keystone_defeat_staging_mismatch` (v0.3.10)

The S11 keystone scene after a lost Factor fight now shows what the narration
says, and the crew no longer pop in mid-scene.

- After a defeat, "Rook is on his knees in the road" used to play over Rook
  standing with the blade held high. He now kneels, hurt, for that line, then
  gets back up with the blade raised before the Blade says "Choose."
- Mara, Fen, Wick and Bracken (whoever is still with him) are now in place
  from the first line, spread out behind Rook, instead of appearing all at
  once after the narration, bunched on top of each other.
- `scripts/story/story_act3.gd`: `_keystone()` places the crew before the
  narration (30px apart) and stages Rook kneel → hold_up on defeat.

## 2026-11-11 11:59 EST — `bugfix_factor_kneels_but_fight_continues` (v0.3.9)

"DEFEAT THE FACTOR" now ends when the Factor kneels.

- In the S11 fight (without enough lore to talk him down), the Factor's
  knockout puts him on one knee, but the battle only ended once every enemy
  was down — so it carried on against his two hunters, and a loss after that
  had the Factor "standing over" Rook seconds after kneeling. A defeat
  objective that names its target now ends in victory the moment that target
  is down (fallen or kneeling), even with others still standing.
- `scripts/battle/battle.gd`: new `_objective_enemy()` (the unit an objective
  names with `who`); `_check_end()` returns victory when it is down on a
  `defeat` objective.
- `scripts/story/story_act3.gd`: the Factor's unit now has the id `factor`
  (it was `e0`, so the objective's `who: "factor"` never matched); his
  half-health threshold line uses the new id.

## 2026-11-11 11:51 EST — `bugfix_defeat_results_lists_spared_enemies` (v0.3.8)

Losing a fight no longer says an enemy "was spared".

- An enemy that kneels instead of falling (the Factor) was listed as
  "The Factor was spared." on the results card whatever the outcome, so losing
  the S11 fight showed "DEFEATED ... The Factor was spared." as if Rook had
  won and chosen mercy. Spared lines now appear only after a victory or a
  completed objective.
- `scripts/battle/battle_results.gd`: the spared lines are gated on
  `outcome in ["victory", "objective"]`.

## 2026-11-11 11:50 EST — `bugfix_bearer_moves_when_nobody_holds_blade` (v0.3.7)

Enemies no longer use "bearer" moves when nobody in the fight is carrying the
blade.

- Hunters' "Mark the Bearer" ("points a hook at the blade's bearer") and the
  Factor's bearer moves (Appraise, Seal, Claim) could be picked even when Rook
  didn't have the sword (e.g. the S3 "Leave it" fight, with Wick carrying it),
  landing on a random party member under a name and text that claimed a
  bearer. Those moves are now left out of an enemy's choices unless Rook is in
  the fight, standing, and holding the blade; an enemy with only bearer moves
  falls back to a plain Attack.
- `scripts/battle/battle.gd`: new `_bearer_present()`; `_choose_intent()`
  filters `target: "bearer"` moves when it's false; `_enemy_target()` uses the
  same check.

## 2026-11-11 11:40 EST — `bugfix_bridge_rollcall_names_absent_crew` (v0.3.6)

The S9 "All of them. Every one." line after the bridge crossing now names only
the crew who are actually there.

- When the crew all make it across the gorge, the narration used to list
  "Bracken, Wick, Fen, Mara, Rook" no matter what — naming Wick after he was
  gone, Fen after he was killed, or Mara after she left. It now names exactly
  the people running across on screen, in the same order (two names read
  "X and Y").
- `scripts/story/story_act3.gd`: new `_roll_call(people)` builds the names from
  the same `people` list `_s9_after()` uses to spawn the runners.

## 2026-11-11 11:21 EST — `bugfix_tower_top_carving_scene_on_ground` (v0.3.5)

The S4 blade-carving scene ("The top of the tower...") now actually takes
place on top of the Rookery instead of on the dirt at the tower's foot.

- New tower-top backdrop: stone flagstones and a crenellated parapet in the
  foreground, and beyond it the badlands laid out far below — hazy mesas on
  the horizon, buttes and moonlit gullies on the plain, a pale dry riverbed
  winding off under a big moon. Rook sits on the flagstones with his back to
  the parapet; the crow perches on a merlon beside him.
- At the end of the scene the crow takes off from the parapet and flies off
  into the night; the narration now reads "On the parapet, the crow takes
  off, all at once, into the dark." (it used to refer to a crow "down below
  on the stairs" while the crow was sitting next to Rook).
- `scripts/art_cine.gd`: new `ArtCine.rookery_top(frame)` (`rookery_top` cine,
  4 frames of twinkling stars).
- `scripts/story/story_act2.gd`: `_s4_carve()` uses `rookery_top`, re-places
  Rook and the crow, and flies the crow off at the end.

## 2026-11-11 10:58 EST — `bugfix_alley_battle_uses_town_gate_backdrop` (v0.3.4)

The S5 "alley of hooks" fight now happens in an actual alley instead of in
front of the Kesh Crossing border gate.

- New backdrop: a narrow back alley seen down its length — tall plastered
  walls closing in on either side, a slit of sky between the rooflines,
  doorways and shuttered windows, washing strung wall to wall (it stirs in a
  2-frame loop), and the next street over in full sun at the far end. The
  battle floor's cobbles run straight down the alley.
- `scripts/art_cine.gd`: new `ArtCine.alley(frame)` (one-point perspective onto
  the battle horizon), also available as the `alley` cine.
- `scripts/art_battle.gd`: the `alley` battle backdrop blits `ArtCine.alley()`
  instead of `ArtCine.town()`; 2 animation frames.

## 2026-11-11 10:48 EST — `bugfix_achievement_toast_covers_ending_title` (v0.3.3)

Achievement toasts no longer cover the big title on the ending card.

- Achievements earned at the end of a run (e.g. Clean Hands, The Bearer
  Claimed) used to slide in at the top right over the ending's name while it
  faded in. They now wait until the ending card closes and play afterwards.
  A toast that is already on screen when the card comes up slides away at
  once and replays in full later, so nothing is lost.
- `scripts/main.gd`: `play_story()` holds toasts (`hold_toasts`) from
  `record_ending()` until the card is freed; `_show_toasts()` now tucks away
  and re-queues an in-flight toast when a hold starts (this also applies to
  the battle results screen, which already used the hold).

## 2026-11-11 09:29 EST — `bugfix_s9_choice_text_vs_field_staging` (v0.3.2)

S9 The Bridge Ambush: the field staging now matches the choice prompt
("Hunters on the ropes, the crew on the planks, the payroll on the far side,
and the Factor walking calmly away").

- No-trade path: Rook and the crew (Bracken, Wick, Mara, Fen) now walk out onto
  the bridge deck, and the Factor walks to meet them mid-bridge, so his
  "You came. Good." / "Return what is kept..." lines are spoken on screen
  instead of from ~20 tiles off camera. Previously the crew never left the
  west cliff.
- Trade path: the rest of the crew follows Rook and Fen out onto the planks
  instead of staying on the cliff.
- Both paths: after the ambush, the Factor turns his back and strolls off
  toward the payroll wagon while the choice is on screen, instead of standing
  still.
- New helper `_s9_crew_onto_deck()` in `scripts/story/story_act3.gd`.
