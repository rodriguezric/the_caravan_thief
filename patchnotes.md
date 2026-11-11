# Patch Notes

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
