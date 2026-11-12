#!/usr/bin/env python3
"""victory: "Dust Settles" (recipes/western_ambient.md). A 2-bar trumpet
fanfare with a whip and a crash that plays once, then an 8-bar harmonica loop
over a strum and a trot of hooves.
C major, 124 BPM, 4/4. Fanfare 2 | Loop 8. The game loops from bar 3:
loop_offset = 2 * 4 * 60 / 124 = 3.871 s (Sfx LOOP_FROM). 10 bars = 19 s.
"""
from western_kit import WSong, strum, harmonize, voicing, root_in, gallop, main

F_CH = ["C", "C"]
L_CH = ["C", "F", "C", "G", "C", "F", "G", "C"]
FANFARE = ["G4:.5 C5:.5 E5:.5 G5:1.5 E5:.5 G5:.5", "C6:3 r:1"]
LOOP = ["E5:1 G5:1 C6:1 G5:1", "A5:2 F5:1 A5:1", "G5:1.5 E5:.5 C5:2", "D5:2 B4:1 D5:1",
        "E5:1 G5:1 C6:1.5 B5:.5", "A5:1 C6:1 A5:1 F5:1", "G5:1 D5:1 B4:1 D5:1", "C5:3 r:1"]

PROG = F_CH + L_CH
song = WSong(124, 4, 10, PROG)
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
harm = song.part("harmonica")
nylon = song.part("nylon")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    tp1.melody(FANFARE, song.t(0), 1.0, hold=.85)
    harmonize(tp1, tp2, .75)
    harm.melody(LOOP, song.t(2), .95)
    drums.hit("whip", song.t(0), 1)
    drums.hit("crash", song.t(1), 1)
    drums.hit("boom", song.t(1), 1)
    strum(nylon, voicing("C", 52, 4), song.t(1), 3, .9)
    for b in range(2, 10):
        ch = PROG[b]
        t = song.t(b)
        v = voicing(ch, 52, 4)
        strum(nylon, v, t, 1.4, .45)
        strum(nylon, v, t + 1.5, .9, .35, up=True)
        strum(nylon, v, t + 2, 1.4, .4)
        r = root_in(ch, 36)
        bass.note(r, t, 1.8, .85)
        bass.note(r + 7, t + 2, 1.8, .65)
        gallop(drums, t, 4, .7, trot=True)
    return song.write(out, "Dust Settles", "C major",
                      "Victory (The Caravan Thief), recipes/western_ambient.md. 2-bar trumpet fanfare (plays once; "
                      "the game loops from 3.871 s), then a harmonica loop with strum and trot.",
                      gain=1.6, kit_vol=.8)


if __name__ == "__main__":
    main(build, "victory")
