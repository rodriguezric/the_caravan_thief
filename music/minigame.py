#!/usr/bin/env python3
"""minigame: "Quick Hands" (recipes/western_ambient.md). Lockpicking and card
tricks: a nimble twang tune, a trotting clop, rim clicks, whistle pings in
the gaps.
E Dorian, 126 BPM, 4/4. A 8 | B 8. Ends on A into Em. 16 bars = 30 s.
"""
from western_kit import WSong, echo, voicing, root_in, main, pitch

A_CH = ["Em", "A", "Em", "A", "G", "D", "A", "A"]
B_CH = ["C", "D", "Em", "Em", "C", "D", "A", "A"]
TW_A = ["E4:.5 G4:.5 B4:.5 G4:.5 A4:.5 B4:.5 D5:1", "C#5:.5 B4:.5 A4:.5 E4:.5 F#4:1 A4:1",
        "E4:.5 G4:.5 B4:.5 E5:.5 D5:.5 B4:.5 G4:1", "A4:1.5 C#5:.5 E5:2",
        "D5:.5 B4:.5 G4:.5 B4:.5 D5:1 G5:1", "F#5:.5 E5:.5 D5:.5 A4:.5 F#4:1 A4:1",
        "E5:.5 C#5:.5 A4:.5 C#5:.5 E5:1 F#5:.5 E5:.5", "C#5:2 r:2"]
TW_B = ["E5:1 G5:1 E5:.5 D5:.5 C5:1", "D5:1 F#5:1 A5:2", "G5:.5 F#5:.5 E5:.5 D5:.5 B4:1 G4:1", "E4:2 r:2",
        "C5:.5 E5:.5 G5:.5 E5:.5 C6:1 B5:1", "A5:1 F#5:1 D5:1 A4:1", "C#5:.5 E5:.5 A5:.5 E5:.5 C#5:1 B4:1",
        "A4:2 r:2"]

PROG = A_CH + B_CH
song = WSong(126, 4, 16, PROG)
twang = song.part("twang")
techo = song.part("twang_echo")
whistle = song.part("whistle")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    twang.melody(TW_A, song.t(0), .6, hold=.75)
    twang.melody(TW_B, song.t(8), .65, hold=.75)
    for b in (3, 7, 11, 15):
        ch = PROG[b]
        tops = voicing(ch, 76, 2)
        whistle.note(tops[0], song.t(b, 2.5), .4, .8)
        whistle.note(tops[1], song.t(b, 3), .8, .8, slide=-1)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 40)
        for k, iv in enumerate([0, 7, 0, 7]):
            bass.note(r + iv, t + k, .45, .85 if k == 0 else .6)
        for k in range(4):
            drums.hit("clop", t + k, .7)
            drums.hit("clop2", t + k + .5, .5)
        drums.hit("rim", t + 1, .5)
        drums.hit("rim", t + 3, .5)
        drums.hit("rim", t + 3.75, .3)
    echo(twang, techo, .75, .6)
    techo.soften()
    return song.write(out, "Quick Hands", "E dorian",
                      "Minigame (The Caravan Thief), recipes/western_ambient.md. Nimble twang tune, trotting clop, "
                      "rim clicks, whistle pings. Ends on A into Em.", gain=1.7, kit_vol=.7)


if __name__ == "__main__":
    main(build, "minigame")
