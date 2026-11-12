#!/usr/bin/env python3
"""legend: "What the Road Remembers" (recipes/western_ambient.md). Lore told
by the fire as if it were already a ballad: a trumpet theme over a low twang
ostinato, timpani booms, a brushed march, the anvil every second bar, the
choir from A'.
G harmonic minor, 88 BPM, 4/4. A 8 | A' 8 (choir) | B 8 (Eb, trumpets in
thirds) | A'' 8. Ends on D into Gm. 32 bars = 87 s.
"""
from western_kit import WSong, echo, harmonize, voicing, root_in, main

A_CH = ["Gm", "Gm", "Cm", "D", "Gm", "Eb", "Cm", "D"]
B_CH = ["Eb", "Bb", "Cm", "Gm", "Eb", "F", "D", "D"]
MEL_A = ["G4:1.5 Bb4:.5 D5:2", "C5:1 Bb4:1 A4:2f", "G4:1 C5:1 Eb5:1.5 D5:.5", "D5:3 r:1",
         "G5:1.5 F5:.5 D5:2", "Eb5:1 D5:1 Bb4:2", "C5:1 Eb5:1 G5:1 Eb5:1", "F#5:3f r:1"]
MEL_B = ["Bb5:2 G5:1 Eb5:1", "F5:2 D5:2", "Eb5:1.5 G5:.5 C6:2", "Bb5:3f r:1",
         "G5:2 Bb5:1 G5:1", "A5:2 F5:2", "F#5:1 A5:1 D6:2", "A5:2 F#5:1 D5:1"]

PROG = A_CH * 2 + B_CH + A_CH
song = WSong(88, 4, 32, PROG)
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
twang = song.part("twang")
techo = song.part("twang_echo")
choir = song.part("choir")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    tp1.melody(MEL_A, song.t(0), .85, hold=.85)
    tp1.melody(MEL_A, song.t(8), .95, hold=.85)
    tp1.melody(MEL_B, song.t(16), 1.0, hold=.85)
    tp1.melody(MEL_A, song.t(24), 1.0, hold=.85)
    tmp = song.part("_tmp", "trumpet")
    tmp.melody(MEL_B, song.t(16), 1.0, hold=.85)
    harmonize(tmp, tp2, .7)
    song.parts.remove(tmp)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 43)
        for k, iv in enumerate([0, 7, 12, 7, 0, 7, 12, 7]):
            twang.note(r + iv - 12 if r > 50 else r + iv, t + k * .5, .35, .7 if k % 4 == 0 else .45)
        bass.note(root_in(ch, 31), t, 1.8, .85)
        bass.note(root_in(ch, 31) + 7, t + 2, 1.8, .65)
        drums.hit("boom", t, .7)
        drums.hit("boom", t + 2, .45)
        drums.hit("brush", t + 1, .5)
        drums.hit("brush", t + 3, .55)
        drums.hit("brush", t + 3.5, .3)
        if b % 2 == 0:
            drums.hit("anvil", t, .55)
        if b >= 8:
            for p in voicing(ch, 55, 3):
                choir.note(p, t, 3.8, .5 if b < 16 or b >= 24 else .6)
    echo(twang, techo, .75, .6)
    techo.soften()
    return song.write(out, "What the Road Remembers", "G harmonic minor",
                      "Legend (The Caravan Thief), recipes/western_ambient.md. Trumpet ballad over twang ostinato, "
                      "timpani, brushed march, anvil; choir from A'. Ends on D into Gm.", gain=1.6, kit_vol=.4)


if __name__ == "__main__":
    main(build, "legend")
