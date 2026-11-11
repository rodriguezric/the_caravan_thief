# Patch Notes

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
