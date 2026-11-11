# Patch Notes

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
