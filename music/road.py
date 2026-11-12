#!/usr/bin/env python3
"""road: "The Saltway" (recipes/western_ambient.md). The open road between
waystations: harmonica over a nylon strum and walking bass, hooves trotting
then galloping, wind, one whip crack before the return.
A minor, 96 BPM, 4/4. A 8 (trot) | A' 8 (gallop, whistle answers) |
B 8 (relative major, harmonica up high, choir) | A'' 8 (whip, all in).
Ends on E (major V) back into Am. 32 bars = 80 s.
"""
from western_kit import WSong, strum, voicing, gallop, walk, root_in, main

A_CH = ["Am", "Am", "Dm", "Am", "Am", "G", "F", "E"]
B_CH = ["C", "G", "Am", "Em", "F", "C", "Dm", "E"]
MEL_A = ["E5:1.5 A4:.5 C5:1 B4:1", "A4:3f r:1", "D5:1.5 F5:.5 E5:1 D5:1", "C5:2 B4:1 A4:1",
         "E5:1 E5:.5 G5:.5 A5:1.5 G5:.5", "G5:1 E5:1 D5:2", "C5:1.5 A4:.5 F4:1 A4:1", "B4:3f r:1"]
MEL_B = ["G5:2 E5:1 C5:1", "D5:3f r:1", "C5:1.5 E5:.5 A5:2", "G5:2 E5:1 B4:1",
         "A5:1.5 G5:.5 F5:1 C5:1", "E5:2 G5:1 E5:1", "F5:1 E5:1 D5:1 A4:1", "G#4:2 B4:1 E5:1"]
ANSWER = ["r:4", "r:3 E6:1", "C6:2f r:2", "r:4", "r:4", "r:4", "r:4", "r:2 G#5:2f"]

PROG = A_CH * 2 + B_CH + A_CH
song = WSong(96, 4, 32, PROG)
harm = song.part("harmonica")
whistle = song.part("whistle")
nylon = song.part("nylon")
choir = song.part("choir")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    harm.melody(MEL_A, song.t(0), .85)
    harm.melody(MEL_A, song.t(8), .95)
    whistle.melody(ANSWER, song.t(8), .8)
    harm.melody(MEL_B, song.t(16), 1.0)
    harm.melody(MEL_A, song.t(24), 1.0)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        nxt = PROG[(b + 1) % len(PROG)]
        v = voicing(ch, 52, 4)
        strum(nylon, v, t, 1.4, .5)
        strum(nylon, v, t + 1.5, .9, .38, up=True)
        strum(nylon, v, t + 2, 1.4, .45)
        strum(nylon, v, t + 3.5, .5, .33, up=True)
        if b < 8:
            r = root_in(ch, 40)
            bass.note(r, t, 1.8, .85)
            bass.note(r + 7, t + 2, 1.8, .7)
        else:
            walk(bass, ch, nxt, t)
        if b < 8:
            gallop(drums, t, 4, .6, trot=True)
        else:
            gallop(drums, t, 4, .8 if b < 16 else .9)
        if b % 4 == 0:
            drums.hit("wind", t, .7)
        if 16 <= b < 24:
            for p in voicing(ch, 57, 3):
                choir.note(p, t, 3.8, .6)
    drums.hit("whip", song.t(23, 3.5), 1.0)
    return song.write(out, "The Saltway", "A minor",
                      "Road (The Caravan Thief), recipes/western_ambient.md. Harmonica, nylon strum, walking bass, "
                      "hooves; one whip before the return. Ends on E into Am.", gain=1.6, kit_vol=.9)


if __name__ == "__main__":
    main(build, "road")
