#!/usr/bin/env python3
"""boss: "The Factor" (recipes/western_ambient.md). The man who owns the road:
E Phrygian dominant (the notes of A harmonic minor), a twang ostinato that
circles E-F, a chanting choir, timpani, the anvil, a bell tolling at each
section, trumpets in thirds, whips.
138 BPM, 4/4. Intro 2 | A 8 | B 8 (Am, trumpets in thirds) | A' 8 (choir
chant) | Turn 8 (the Sword theme's first notes on the trumpet). Ends on E.
34 bars = 59 s.
"""
from western_kit import WSong, echo, harmonize, voicing, root_in, main, pitch

I_CH = ["E", "F"]
A_CH = ["E", "F", "E", "F", "E", "Dm", "F", "E"]
B_CH = ["Am", "Dm", "E", "Am", "F", "Dm", "E", "E"]
T_CH = ["Am", "Am", "F", "E", "Am", "Dm", "F", "E"]
TP_A = ["E5:2 F5:1 G#5:1", "A5:2 G#5:1 F5:1", "E5:1 G#5:1 B5:2", "A5:3f r:1",
        "E5:1 F5:1 G#5:1 B5:1", "D6:2 C6:1 A5:1", "A5:1 F5:1 C6:1 A5:1", "G#5:2 F5:1 E5:1"]
TP_B = ["C6:2 B5:1 A5:1", "F5:2 A5:2", "G#5:1.5 A5:.5 B5:2", "A5:3 r:1",
        "A5:2 C6:2", "D6:1 C6:1 A5:2", "B5:1 G#5:1 E5:1 F5:1", "E5:3f r:1"]
# the Sword Stories theme's opening (A D E F E) in A minor, then answered
TP_T = ["E5:1 A5:1 B5:.5 C6:.5 B5:1", "A5:2.5 G#5:1.5", "C6:1 B5:.5 A5:.5 F5:1 A5:1", "G#5:3 B5:1",
        "E5:1 A5:1 B5:.5 C6:.5 B5:1", "A5:2 F5:1 D5:1", "F5:1 A5:1 C6:1 A5:1", "G#5:2 B5:1 G#5:1"]
CHANT = {"E": ["E4", "G#4", "B4"], "F": ["F4", "A4", "C5"], "Dm": ["D4", "F4", "A4"],
         "Am": ["E4", "A4", "C5"]}

PROG = I_CH + A_CH + B_CH + A_CH + T_CH
song = WSong(138, 4, 34, PROG)
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
twang = song.part("twang")
techo = song.part("twang_echo")
choir = song.part("choir")
drone = song.part("drone")
bell = song.part("bell")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)

A0, B0, A1, T0 = 2, 10, 18, 26


def build(out):
    tp1.melody(TP_A, song.t(A0), 1.2, hold=.85)
    tp1.melody(TP_B, song.t(B0), 1.3, hold=.85)
    tp1.melody(TP_T, song.t(T0), 1.3, hold=.85)
    tmp = song.part("_tmp", "trumpet")
    tmp.melody(TP_B, song.t(B0), 1.0, hold=.85)
    tmp.melody(TP_T, song.t(T0), 1.0, hold=.85)
    harmonize(tmp, tp2, .7)
    song.parts.remove(tmp)
    osti = ["E3", "E3", "F3", "E3", "G#3", "E3", "F3", "E3"]
    for b, ch in enumerate(PROG):
        t = song.t(b)
        shift = (root_in(ch, 40) - 40) if ch in ("Am", "Dm") else 0
        for k, n in enumerate(osti):
            twang.note(pitch(n) + (shift if shift < 6 else shift - 12), t + k * .5, .35, .75 if k % 4 == 0 else .5)
        r = root_in(ch, 28)
        bass.note(r, t, 1.4, .9)
        bass.note(r, t + 1.5, .4, .6)
        bass.note(r + 12, t + 2, .9, .7)
        bass.note(r, t + 3, .9, .6)
        if b % 2 == 0:
            drone.note(pitch("E2"), t, 7.8, .7)
            drone.note(pitch("B2"), t, 7.8, .5)
        drums.hit("boom", t, .85)
        drums.hit("boom", t + 1.5, .5)
        drums.hit("snare", t + 1, .55)
        drums.hit("snare", t + 3, .6)
        drums.hit("hat", t + .5, .4)
        drums.hit("hat", t + 2.5, .4)
        if b % 2 == 0 and b >= A0:
            drums.hit("anvil", t, .6)
        if b >= A1:
            chant = [pitch(x) for x in CHANT[ch]]
            for p in chant:
                choir.note(p, t, 1.8, .6)
                choir.note(p, t + 2, 1.8, .5)
        if b in (A0, B0, A1, T0):
            drums.hit("crash", t, .7)
            bell.note(pitch("E3"), t, 4, 1)
            bell.note(pitch("B4"), t, 4, .25)
        if b in (B0 - 1, A1 - 1, T0 - 1, 33):
            drums.hit("whip", t + 3.5, .9)
    echo(twang, techo, .75, .6)
    techo.soften()
    return song.write(out, "The Factor", "A harmonic minor",
                      "Boss (The Caravan Thief), recipes/western_ambient.md. E Phrygian dominant (A harmonic minor "
                      "notes): twang E-F ostinato, choir chant, timpani, anvil, bell, trumpets in thirds; the turn "
                      "quotes the Sword Stories theme. Ends on E.", gain=1.5, kit_vol=.6)


if __name__ == "__main__":
    main(build, "boss")
