#!/usr/bin/env python3
"""town: "Kesh Crossing" (recipes/western_ambient.md). A border-town waltz:
two trumpets in thirds over an oom-pah-pah of bass and nylon, brushes.
F major, 120 BPM, 3/4. A 16 | B 16 | A' 16 (brushes busier, harmonica
doubles the tune low). Ends on a bar of rest over F so the trumpets'
pickup restarts the loop. 48 bars = 72 s.
"""
from western_kit import WSong, voicing, harmonize, root_in, main

A_CH = ["F", "F", "C7", "C7", "C7", "C7", "F", "F", "F", "F", "Bb", "Bb", "F", "C7", "F", "F"]
B_CH = ["Bb", "Bb", "F", "F", "C7", "C7", "F", "F", "Bb", "Bb", "F", "Dm", "Gm", "C7", "F", "F"]
MEL_A = ["C5:1 F5:1 A5:1", "C6:2 A5:1", "G5:1.5 A5:.5 G5:1", "E5:2 C5:1", "Bb4:1 C5:1 E5:1", "G5:2 E5:1",
         "F5:1.5 G5:.5 A5:1", "F5:2 r:1",
         "C5:1 F5:1 A5:1", "C6:2 A5:1", "D6:1.5 C6:.5 Bb5:1", "D5:2 F5:1", "A5:1 G5:1 F5:1", "E5:2 G5:1",
         "F5:3", "r:3"]
MEL_B = ["D5:1 F5:1 Bb5:1", "A5:2 G5:1", "F5:1 A5:1 C6:1", "A5:2 F5:1", "E5:1 G5:1 Bb5:1", "G5:2 E5:1",
         "F5:1 A5:1 C6:1", "A5:2 r:1",
         "D5:1 F5:1 Bb5:1", "D6:2 Bb5:1", "C6:1 A5:1 F5:1", "F5:1 D5:1 A4:1", "Bb4:1 D5:1 G5:1",
         "E5:1 G5:1 C6:1", "A5:2 F5:1", "F5:2 C5:1"]

PROG = A_CH + B_CH + A_CH
song = WSong(120, 3, 48, PROG)
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
harm = song.part("harmonica")
nylon = song.part("nylon")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    tp1.melody(MEL_A, song.t(0), .9, hold=.8)
    tp1.melody(MEL_B, song.t(16), 1.0, hold=.8)
    tp1.melody(MEL_A, song.t(32), 1.0, hold=.8)
    harm.melody(MEL_A, song.t(32), .55, transpose=-12, hold=.85)
    harmonize(tp1, tp2, .75)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 41)
        bass.note(r if b % 2 == 0 else r - 5 if r - 5 >= 36 else r + 7, t, .9, .9)
        v = voicing(ch, 55, 3)
        for k in (1, 2):
            for p in v:
                nylon.note(p, t + k + .02 * v.index(p), .45, .6 if k == 1 else .5)
        drums.hit("brush", t + 1, .5)
        drums.hit("brush", t + 2, .4)
        if b >= 32:
            drums.hit("brush", t + 2.5, .25)
        if b % 8 == 7:
            drums.hit("rim", t + 2, .5)
    return song.write(out, "Kesh Crossing", "F major",
                      "Town (The Caravan Thief), recipes/western_ambient.md. Border-town waltz: two trumpets in "
                      "thirds, oom-pah-pah bass and nylon, brushes.", gain=1.8, kit_vol=.8)


if __name__ == "__main__":
    main(build, "town")
