#!/usr/bin/env python3
"""heist: "Light Fingers" (recipes/western_ambient.md). Sneaking: a plucked
low twang ostinato like pizzicato, rim ticks, a rattle in the gaps, and a
whistle that only dares a few notes at a time.
D minor, 104 BPM, 4/4. A 8 | B 8 (bII colour, twang melody) | A' 8 (whistle
fuller) | Turn 8 (Andalusian, back to A). Ends on A into Dm. 32 bars = 74 s.
"""
from western_kit import WSong, echo, root_in, voicing, main

A_CH = ["Dm", "Dm", "Bb", "A", "Dm", "Dm", "Gm", "A"]
B_CH = ["Dm", "Eb", "Dm", "Eb", "Gm", "Dm", "Eb", "A"]
T_CH = ["Dm", "C", "Bb", "A", "Dm", "C", "Bb", "A"]
WH_A = ["r:2 A5:.5 F5:.5 D5:1", "r:4", "r:2 D6:.5 Bb5:.5 F5:1", "E5:2f r:2",
        "r:2 A5:.5 C6:.5 A5:1", "r:4", "r:1 Bb5:.5 G5:.5 D5:2", "C#5:2f r:2"]
WH_A2 = ["A5:1 F5:.5 D5:.5 A5:1 r:1", "r:2 G5:.5 F5:.5 E5:1", "D6:1 Bb5:.5 F5:.5 D6:1 r:1", "C#6:2f r:2",
         "A5:1 C6:.5 A5:.5 F5:1 r:1", "r:2 E5:.5 F5:.5 A5:1", "Bb5:1 G5:.5 D5:.5 G5:1 r:1", "E5:2f r:2"]
TW_B = ["D3:.5 F3:.5 A3:.5 r:.5 D4:1 r:1", "Eb3:.5 G3:.5 Bb3:.5 r:.5 Eb4:1 r:1",
        "F3:.5 A3:.5 D4:.5 r:.5 F4:1 r:1", "G3:.5 Bb3:.5 Eb4:.5 r:.5 G4:1 r:1",
        "G3:.5 Bb3:.5 D4:.5 r:.5 G4:1 r:1", "F3:.5 A3:.5 D4:.5 r:.5 A4:1 r:1",
        "Eb4:1 D4:.5 Bb3:.5 G3:1 r:1", "A3:.5 C#4:.5 E4:.5 r:.5 A4:1 r:1"]

PROG = A_CH + B_CH + A_CH + T_CH
song = WSong(104, 4, 32, PROG)
whistle = song.part("whistle")
twang = song.part("twang")
techo = song.part("twang_echo")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    whistle.melody(WH_A, song.t(0), .85, hold=.8)
    twang.melody(TW_B, song.t(8), .85, hold=.7)
    whistle.melody(WH_A2, song.t(16), .9, hold=.8)
    whistle.melody(WH_A[:4], song.t(24), .8, hold=.8)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 38)
        # tiptoe bass ostinato: short root/fifth/octave plucks
        for k, (iv, d) in enumerate([(0, 0), (7, .75), (12, 1.5), (7, 2.5), (0, 3)]):
            bass.note(r + iv, t + d, .3, .9 if k == 0 else .6)
        if not 8 <= b < 16:
            v = voicing(ch, 50, 3)
            twang.note(v[0], t + 1, .3, .45)
            twang.note(v[2], t + 3.5, .3, .4)
        drums.hit("rim", t + 1, .5)
        drums.hit("rim", t + 3, .45)
        drums.hit("rim", t + 3.75, .3)
        if b % 4 == 1:
            drums.hit("rattle", t + 2, .7)
        if b % 8 == 7:
            drums.hit("brush", t + 3.5, .4)
    echo(twang, techo, .75, .8)
    techo.soften()
    return song.write(out, "Light Fingers", "D minor",
                      "Heist (The Caravan Thief), recipes/western_ambient.md. Pizzicato twang and bass, rim ticks, "
                      "rattle; B leans on bII (Eb). Ends on A into Dm.", gain=2.1, kit_vol=1.2)


if __name__ == "__main__":
    main(build, "heist")
