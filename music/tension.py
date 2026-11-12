#!/usr/bin/env python3
"""tension: "Hooks in the Dark" (recipes/western_ambient.md). Something is
watching: a pocket-watch tick, a heartbeat boom, a twang tremolo that stops
dead, an E-B drone, and a whistle that quotes the theme's first notes and
never finishes them. Mixed quiet for dialogue.
E Phrygian, 72 BPM, 4/4. A 8 | B 8 (F, the bII, presses; rattle) | A' 8.
Ends on F (bII) back into Em. 24 bars = 80 s.
"""
from western_kit import WSong, echo, root_in, voicing, main, pitch

A_CH = ["Em", "Em", "F", "Em", "Em", "Am", "F", "Em"]
B_CH = ["Dm", "Em", "Dm", "Em", "C", "F", "Dm", "F"]
WH_A = ["r:4", "B4:1 E5:1 F#5:.5 G5:.5 F#5:1f", "r:4", "r:2 F5:2f",
        "r:4", "E5:1 A5:1 C6:2f", "r:4", "r:4"]
WH_B = ["r:2 A5:2f", "r:2 B5:1 G5:1", "F5:3f r:1", "r:4", "r:2 G5:1 E5:1", "F5:2 A5:2f", "r:4", "r:4"]

PROG = A_CH + B_CH + A_CH
song = WSong(72, 4, 24, PROG)
whistle = song.part("whistle")
twang = song.part("twang")
techo = song.part("twang_echo")
drone = song.part("drone")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    whistle.melody(WH_A, song.t(0), .8)
    whistle.melody(WH_B, song.t(8), .85)
    whistle.melody(WH_A, song.t(16), .85)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 40)
        if b % 2 == 0:
            drone.note(pitch("E2"), t, 7.8, .8)
            drone.note(pitch("B2"), t, 7.8, .6)
        bass.note(r, t, 1.5, .7)
        # tremolo bar every 4 bars, else two plucks
        if b % 4 == 2:
            for k in range(12):
                twang.note(voicing(ch, 52, 1)[0], t + k * .25, .2, .3 + k * .03)
        else:
            twang.note(r + 12, t + 2.5, 1.2, .55)
        for k in range(4):
            drums.hit("tick", t + k, .6 if k % 2 == 0 else .4)
        drums.hit("boom", t, .55)
        drums.hit("boom", t + .45, .35)
        if 8 <= b < 16 and b % 2 == 1:
            drums.hit("rattle", t + 2, .6)
    echo(twang, techo, .75, .8, second=1.5)
    techo.soften()
    return song.write(out, "Hooks in the Dark", "E phrygian",
                      "Tension (The Caravan Thief), recipes/western_ambient.md. Pocket-watch tick, heartbeat, "
                      "twang tremolo, E-B drone, half-stated theme on the whistle. Quiet for dialogue.", gain=1.8, kit_vol=.6)


if __name__ == "__main__":
    main(build, "tension")
