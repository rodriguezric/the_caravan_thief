#!/usr/bin/env python3
"""omen: "What the Blade Hears" (recipes/western_ambient.md). The cursed sword
listening: a whistle wandering in whole tones, a far choir, a tritone in the
drone, the mission bell tolling once per section, wind.
C# Phrygian (with whole-tone runs), 56 BPM, 4/4. A 8 | B 8 (choir) | A' 8.
Never resolves; ends on D (bII) back into C#m. 24 bars = 103 s.
"""
from western_kit import WSong, echo, main, pitch, voicing

A_CH = ["C#m", "D", "C#m", "C#m", "C#m", "D", "G", "C#m"]
B_CH = ["A", "D", "C#m", "G", "A", "D", "G", "D"]
WH_A = ["G#5:2 r:2", "A5:2f r:2", "r:1 C#5:1 D#5:1 F5:1", "G5:3f r:1",
        "r:4", "A5:1 G5:1 F5:2f", "r:4", "r:2 C#5:2f"]
WH_B = ["r:4", "F#5:2 A5:2f", "r:4", "D6:2 B5:1 G5:1f", "r:4", "D5:1 E5:1 F#5:1 G#5:1f", "r:4", "A5:3f r:1"]

PROG = A_CH + B_CH + A_CH
song = WSong(56, 4, 24, PROG)
whistle = song.part("whistle")
twang = song.part("twang")
techo = song.part("twang_echo")
choir = song.part("choir")
drone = song.part("drone")
bell = song.part("bell")
drums = song.part("drums", "kit", kit=True)


def build(out):
    whistle.melody(WH_A, song.t(0), .8, vib=.014)
    whistle.melody(WH_B, song.t(8), .85, vib=.014)
    whistle.melody(WH_A, song.t(16), .85, vib=.014)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        if b % 2 == 0:
            drone.note(pitch("C#2"), t, 7.8, .8)
            drone.note(pitch("G2") if b % 4 == 2 else pitch("G#2"), t, 7.8, .5)
        if b % 2 == 1:
            twang.note(voicing(ch, 49, 1)[0], t + 1, 2, 1.2)
        if 8 <= b < 16:
            for p in voicing(ch, 56, 3):
                choir.note(p, t, 3.8, .55)
        if b % 4 == 0:
            drums.hit("wind", t, .8)
    for s in (0, 8, 16):
        bell.note(pitch("C#3"), song.t(s), 4, 1)
        bell.note(pitch("G#4"), song.t(s), 4, .25)
        bell.note(pitch("C#3"), song.t(s + 2), 4, .55)
    echo(twang, techo, 1.0, .9, second=2.0)
    return song.write(out, "What the Blade Hears", "C# phrygian",
                      "Omen (The Caravan Thief), recipes/western_ambient.md. Whole-tone whistle, far choir, "
                      "C#-G tritone drone, mission bell, wind. Never resolves.", gain=2.2, kit_vol=1.2)


if __name__ == "__main__":
    main(build, "omen")
