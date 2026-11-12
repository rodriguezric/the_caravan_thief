#!/usr/bin/env python3
"""hope: "Salt at Dawn" (recipes/western_ambient.md). The Sword Stories theme
turned major and slowed: the whistle at sunrise over a nylon strum, a soft
trot of hooves from A', the choir and bell at B.
F major, 80 BPM, 4/4. A 8 | A' 8 (hooves, twang answers) | B 8 (Dm-Bb-C,
choir) | A'' 8. Ends on C into F. 32 bars = 96 s.
"""
from western_kit import WSong, echo, strum, voicing, root_in, gallop, main, pitch

A_CH = ["F", "F", "Bb", "F", "Dm", "Bb", "C", "C"]
B_CH = ["Dm", "Bb", "F", "C", "Dm", "Bb", "Gm", "C"]
MEL_A = ["C5:1 F5:1 G5:.5 A5:.5 G5:1", "F5:2.5 E5:1.5", "D5:1 F5:1 Bb5:1 A5:1", "A5:3f C5:1",
         "D5:1 F5:1 A5:1 D6:1", "D6:2 C6:1 Bb5:1", "G5:2 E5:1 G5:1", "C5:3f r:1"]
MEL_B = ["A5:2 F5:1 D5:1", "D5:2 F5:1 Bb5:1", "A5:2 C6:2", "G5:3f r:1",
         "F5:2 A5:1 D6:1", "D6:2 Bb5:2", "Bb5:1 A5:1 G5:1 D5:1", "E5:3f r:1"]

PROG = A_CH * 2 + B_CH + A_CH
song = WSong(80, 4, 32, PROG)
whistle = song.part("whistle")
twang = song.part("twang")
techo = song.part("twang_echo")
nylon = song.part("nylon")
choir = song.part("choir")
bass = song.part("bass")
bell = song.part("bell")
drums = song.part("drums", "kit", kit=True)


def build(out):
    whistle.melody(MEL_A, song.t(0), .9)
    whistle.melody(MEL_A, song.t(8), .95)
    whistle.melody(MEL_B, song.t(16), 1.0)
    whistle.melody(MEL_A, song.t(24), .95)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        v = voicing(ch, 53, 4)
        r = root_in(ch, 41)
        strum(nylon, v, t, 1.8, .7)
        strum(nylon, v, t + 2, 1.4, .55, up=True)
        if b >= 8:
            strum(nylon, v, t + 3, .9, .5)
        bass.note(r, t, 1.8, .8)
        bass.note(r + 7, t + 2, 1.8, .6)
        if 8 <= b < 16 and b % 2 == 1:
            twang.note(r + 12, t + 2.5, 1, 1.1)
            twang.note(r + 19, t + 3, 1, 1.0)
        if b >= 8:
            gallop(drums, t, 4, .45, trot=True)
        if 16 <= b < 24:
            for p in voicing(ch, 57, 3):
                choir.note(p, t, 3.8, .55)
    for s in (0, 16):
        bell.note(pitch("F3"), song.t(s), 4, .9)
        bell.note(pitch("C5"), song.t(s), 4, .25)
    echo(twang, techo, .75, .9, second=1.5)
    techo.soften()
    return song.write(out, "Salt at Dawn", "F major",
                      "Hope (The Caravan Thief), recipes/western_ambient.md. The theme's shape in major: whistle, "
                      "nylon strum, soft trot, choir and bell in B. Ends on C into F.", gain=1.75, kit_vol=.9)


if __name__ == "__main__":
    main(build, "hope")
