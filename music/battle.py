#!/usr/bin/env python3
"""battle: "Draw!" (recipes/western_ambient.md). A gallop that never stops:
a low twang lead, strum stabs, a hoof-and-kit beat, two trumpets in thirds in
B, an Andalusian turn with the choir, whips at the section ends.
A minor, 152 BPM, 4/4. Intro 2 | A 8 | B 8 | A' 8 | Turn 8. Ends on E into
the intro's Am. 34 bars = 54 s.
"""
from western_kit import WSong, echo, harmonize, voicing, root_in, main, strum

I_CH = ["Am", "E"]
A_CH = ["Am", "Am", "F", "G", "Am", "Am", "F", "E"]
B_CH = ["Dm", "Am", "E", "Am", "Dm", "Am", "F", "E"]
T_CH = ["Am", "G", "F", "E", "Am", "G", "F", "E"]
TW_A = ["A3:.5 A3:.5 C4:.5 E4:.5 A4:1 G4:.5 E4:.5", "A4:1.5 C5:.5 B4:.5 A4:.5 G4:1",
        "F4:.5 F4:.5 A4:.5 C5:.5 F5:1 E5:.5 C5:.5", "D5:1.5 B4:.5 G4:1 D4:1",
        "A3:.5 A3:.5 C4:.5 E4:.5 A4:1 C5:.5 E5:.5", "E5:1.5 D5:.5 C5:.5 B4:.5 A4:1",
        "C5:.5 A4:.5 F4:.5 A4:.5 C5:1 D5:1", "B4:1.5 G#4:.5 E4:1 r:1"]
TP_B = ["D5:1 F5:1 A5:2", "E5:1 A5:1 C6:2", "B5:1.5 G#5:.5 E5:2", "A5:3 r:1",
        "F5:1 A5:1 D6:2", "C6:1 B5:1 A5:2", "A5:1 C6:1 F5:1 A5:1", "G#5:2 B5:1 E5:1"]
TP_T = ["A5:4", "G5:4", "F5:4", "E5:3 r:1", "C6:4", "B5:4", "A5:4", "G#5:2 B5:2"]

PROG = I_CH + A_CH + B_CH + A_CH + T_CH
song = WSong(152, 4, 34, PROG)
twang = song.part("twang")
techo = song.part("twang_echo")
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
nylon = song.part("nylon")
choir = song.part("choir")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)

A0, B0, A1, T0 = 2, 10, 18, 26


def build(out):
    # intro: a whip, a crash, the twang sliding down, a snare roll on E
    drums.hit("whip", song.t(0), 1)
    drums.hit("crash", song.t(0), .9)
    twang.note(57, song.t(0), 3.5, 1, slide=-12)
    for k in range(16):
        drums.hit("snare", song.t(1, k * .25), .3 + k * .04)
    strum(nylon, voicing("E", 52, 4), song.t(1), 3.5, .8)
    twang.melody(TW_A, song.t(A0), .6, hold=.8)
    tp1.melody(TP_B, song.t(B0), 1.4, hold=.85)
    twang.melody(TW_A, song.t(A1), .65, hold=.8)
    tp1.melody(TP_T, song.t(T0), 1.2, hold=.9)
    tmp = song.part("_tmp", "trumpet")
    tmp.melody(TP_B + TP_T, song.t(B0), 1.0, hold=.85)
    tmp.bars[A1:T0] = [[] for _ in range(8)]
    harmonize(tmp, tp2, .9)
    song.parts.remove(tmp)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        r = root_in(ch, 33)
        if b >= A0:
            for k in range(4):
                bass.note(r, t + k, .4, .9)
                bass.note(r + 12 if k % 2 else r + 7, t + k + .5, .2, .6)
                bass.note(r + 7 if k % 2 else r, t + k + .75, .2, .6)
            v = voicing(ch, 52, 4)
            strum(nylon, v, t, .4, .55)
            strum(nylon, v, t + 1.5, .4, .4, up=True)
            strum(nylon, v, t + 2.5, .4, .45)
            for k in range(4):
                drums.hit("clop", t + k, .7)
                drums.hit("clop2", t + k + .5, .45)
                drums.hit("kick" if k % 2 == 0 else "snare", t + k, .8 if k % 2 == 0 else .7)
                drums.hit("hat", t + k + .5, .5)
            if b in (A0, B0, A1, T0):
                drums.hit("crash", t, .8)
            if b in (B0 - 1, A1 - 1, T0 - 1, 33):
                drums.hit("whip", t + 3.5, .9)
        if b >= T0:
            for p in voicing(ch, 57, 3):
                choir.note(p, t, 3.8, .6)
            for k in range(8):
                twang.note(root_in(ch, 45), t + k * .5, .3, .45)
    echo(twang, techo, .5, .7)
    techo.soften()
    return song.write(out, "Draw!", "A minor",
                      "Battle (The Caravan Thief), recipes/western_ambient.md. Gallop beat, twang lead, trumpets "
                      "in thirds in B, Andalusian turn with choir, whips. Ends on E into Am.", gain=1.6, kit_vol=.6)


if __name__ == "__main__":
    main(build, "battle")
