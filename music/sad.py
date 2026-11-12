#!/usr/bin/env python3
"""sad: "The Pass of Teeth" (recipes/western_ambient.md). A slow waltz for
loss: harmonica over a nylon oom-pah-pah, wind, the choir only in B.
A minor, 63 BPM, 3/4. A 8 | A' 8 (harmonica in thirds) | B 8 (C major,
whistle, choir) | A'' 8 (thinning). Ends on E into Am. 32 bars = 91 s.
"""
from western_kit import WSong, voicing, harmonize, root_in, main

A_CH = ["Am", "Am", "Dm", "Am", "F", "Dm", "E", "E"]
B_CH = ["C", "C", "G", "Am", "F", "C", "Dm", "E"]
MEL_A = ["E5:2 C5:1", "A4:2f B4:1", "C5:1.5 D5:.5 F5:1", "E5:3f", "A5:2 F5:1", "D5:2 F5:1", "E5:1.5 D5:.5 B4:1",
         "G#4:3f"]
MEL_B = ["G5:2 E5:1", "C5:3f", "D5:1.5 E5:.5 G5:1", "A5:3f", "C6:2 A5:1", "G5:2 E5:1", "F5:1 E5:1 D5:1", "B4:3f"]

PROG = A_CH * 2 + B_CH + A_CH
song = WSong(63, 3, 32, PROG)
harm = song.part("harmonica")
harm2 = song.part("harmonica2", "harmonica")
whistle = song.part("whistle")
nylon = song.part("nylon")
choir = song.part("choir")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    harm.melody(MEL_A, song.t(0), .85)
    harm.melody(MEL_A, song.t(8), .95)
    whistle.melody(MEL_B, song.t(16), .9)
    harm.melody(MEL_A[:6] + ["E5:3f", "r:3"], song.t(24), .8)
    tmp = song.part("_tmp", "harmonica")
    tmp.melody(MEL_A, song.t(8), .95)
    harmonize(tmp, harm2, .6)
    song.parts.remove(tmp)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        bass.note(root_in(ch, 40), t, 1.8, .8)
        v = voicing(ch, 52, 3)
        for k in (1, 2):
            for i, p in enumerate(v):
                nylon.note(p, t + k + .03 * i, .7, .5 if k == 1 else .4)
        if 16 <= b < 24:
            for p in voicing(ch, 55, 3):
                choir.note(p, t, 2.9, .55)
        if b % 4 == 0:
            drums.hit("wind", t, .7)
    return song.write(out, "The Pass of Teeth", "A minor",
                      "Sad (The Caravan Thief), recipes/western_ambient.md. Harmonica waltz over nylon, wind; "
                      "whistle and choir in B. Ends on E into Am.", gain=1.9, kit_vol=1.2)


if __name__ == "__main__":
    main(build, "sad")
