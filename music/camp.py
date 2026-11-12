#!/usr/bin/env python3
"""camp: "Waystation Embers" (recipes/western_ambient.md). Night by the fire:
a slow harmonica, a nylon arpeggio, crickets and the crackle of a low brush.
E Dorian, 76 BPM, 4/4. A 8 | A' 8 (harmonica in thirds, bass walks) |
B 8 (the whistle takes a quiet tune, choir low) | Tail 8 (A, thinning).
Ends on D (bVII) back into Em. 32 bars = 101 s.
"""
from western_kit import WSong, voicing, harmonize, root_in, main, pitch

A_CH = ["Em", "Em", "A", "A", "Em", "Em", "D", "D"]
B_CH = ["C", "G", "D", "Em", "C", "G", "A", "D"]
MEL_A = ["B4:2 E5:1 F#5:1", "G5:2f r:2", "A5:1.5 G5:.5 F#5:1 E5:1", "C#5:3f r:1",
         "B4:1 D5:1 E5:1 G5:1", "F#5:1.5 E5:.5 D5:2", "A4:1 B4:1 D5:1 E5:1", "D5:3f r:1"]
MEL_B = ["r:1 G5:1 E5:1 C5:1", "D5:3f r:1", "r:1 A5:1 F#5:1 D5:1", "E5:3f r:1",
         "r:1 G5:1 E5:1 C5:1", "B4:2 D5:1 G5:1", "A5:2 E5:1 C#5:1", "D5:3f r:1"]

PROG = A_CH * 2 + B_CH + A_CH
song = WSong(76, 4, 32, PROG)
harm = song.part("harmonica")
harm2 = song.part("harmonica2", "harmonica")
whistle = song.part("whistle")
nylon = song.part("nylon")
choir = song.part("choir")
bass = song.part("bass")
cricket = song.part("cricket")
drums = song.part("drums", "kit", kit=True)


def build(out):
    harm.melody(MEL_A, song.t(0), .85)
    harm.melody(MEL_A, song.t(8), .95)
    tmp = song.part("_tmp", "harmonica")
    tmp.melody(MEL_A, song.t(8), .95)
    harmonize(tmp, harm2, .6)
    song.parts.remove(tmp)
    whistle.melody(MEL_B, song.t(16), .85)
    harm.melody(MEL_A[:4], song.t(24), .8)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        v = voicing(ch, 52, 3)
        r = root_in(ch, 40)
        roll = [r + 12, v[0], v[1], v[2], v[0] + 12, v[2], v[1], v[0]]
        if b >= 28:
            roll = roll[:4]
        for k, p in enumerate(roll):
            nylon.note(p, t + k * .5, .9, .7 if k == 0 else .5)
        if 8 <= b < 24:
            bass.note(r, t, 1.8, .8)
            bass.note(r + 7, t + 2, 1.5, .6)
        else:
            bass.note(r, t, 3.6, .75)
        if 16 <= b < 24:
            for p in voicing(ch, 55, 3):
                choir.note(p, t, 3.8, .5)
        if b % 2 == 1:
            for k in range(3):
                cricket.note(pitch("D7") if k % 2 else pitch("E7"), t + 1.5 + k * .25, .1, .8)
        if b % 4 == 2:
            drums.hit("brush", t + 2.75, .25)
            drums.hit("brush", t + 3.1, .18)
    return song.write(out, "Waystation Embers", "E dorian",
                      "Camp (The Caravan Thief), recipes/western_ambient.md. Slow harmonica (thirds in A'), nylon "
                      "arpeggio, crickets, fire crackle; whistle in B. Ends on D into Em.", gain=2.0, kit_vol=1.2)


if __name__ == "__main__":
    main(build, "camp")
