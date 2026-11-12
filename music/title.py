#!/usr/bin/env python3
"""title: "The Caravan Thief" (recipes/western_ambient.md).

The Sword Stories theme (songs.gd _sword_theme) whistled over an echoing twang
guitar. D minor, 72 BPM, 4/4.
Intro 4 (wind, bell, open D-A twang) | A 16 (the theme; nylon and a boom on
bar starts join for the second half) | B 8 (Andalusian Dm C Bb A: the twang
takes a low melody, the choir swells, the whistle answers with falls) |
Tail 8 (the theme's first and last phrases, thinning; ends on Dm add9 back
into the quiet intro). 36 bars = 120 s.
"""
from western_kit import WSong, echo, strum, main, pitch

THEME_CH = ["Dm", "Dm", "Dm", "G", "Bb", "Gm", "A", "Dm"]
THEME_BASS = ["D2", "C#2", "C2", "B1", "Bb1", "G1", "A1", "D2"]
THEME_TONES = [["D4", "F4", "A4"], ["C#4", "F4", "A4"], ["C4", "F4", "A4"], ["D4", "G4", "B4"],
               ["D4", "F4", "A4"], ["D4", "E4", "Bb4"], ["D4", "E4", "A4"], ["D4", "E4", "A4"]]
THEME = ["A4:1 D5:1 E5:.5 F5:.5 E5:1", "D5:2.5 C#5:1.5", "F5:1 E5:.5 D5:.5 C5:1 A4:1", "B4:3 D5:1",
         "F5:1.5 E5:.5 D5:1 A4:1", "Bb4:1 D5:1 E5:2", "D5:2 C#5:1 E5:1", "D5:1 E5:.5 D5:.5 A4:2f",
         "A5:1 F5:1 E5:.5 D5:.5 E5:1", "F5:2 E5:1 C#5:1", "C5:1 D5:1 F5:1 A5:1", "G5:2 D5:1 B4:1",
         "A5:1.5 F5:.5 E5:1 D5:1", "Bb4:1 D5:1 G5:1 E5:1", "E5:2 C#5:1 A4:1", "D5:2 r:.5 E5:1.5f"]
B_CH = ["Dm", "C", "Bb", "A", "Dm", "C", "Bb", "A"]
B_TWANG = ["D4:1.5 A3:.5 D4:1 F4:1", "E4:2 C4:1 G3:1", "F4:1.5 D4:.5 Bb3:1 D4:1", "C#4:3 E4:1",
           "A4:1.5 F4:.5 D4:1 F4:1", "G4:2 E4:1 C4:1", "D4:1 F4:1 Bb4:1 A4:1", "A4:2 G4:1 E4:1"]
B_WHISTLE = ["r:4", "r:2 G5:2f", "r:4", "r:1 E5:3f", "r:4", "r:2 G5:2f", "r:4", "r:2 C#5:2"]
INTRO_CH = ["Dm", "Dm", "Bb", "A"]
TAIL_CH = THEME_CH[:4] + THEME_CH[4:]

PROG = INTRO_CH + THEME_CH * 2 + B_CH + TAIL_CH
song = WSong(72, 4, 36, PROG)
whistle = song.part("whistle")
twang = song.part("twang")
techo = song.part("twang_echo")
nylon = song.part("nylon")
choir = song.part("choir")
drone = song.part("drone")
bell = song.part("bell")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)

I0, A0, B0, T0 = 0, 4, 20, 28


def theme_bar(b, i, strum_it):
    """Accompaniment for theme bar i (0-7) at song bar b."""
    t = song.t(b)
    bs = pitch(THEME_BASS[i])
    ts = [pitch(x) for x in THEME_TONES[i]]
    bass.note(bs, t, 3.6, .9)
    # slow twang arpeggio: low root, then up through the chord, room on beat 4
    twang.note(bs + 12, t, 1.4, .8)
    twang.note(ts[0] - 12, t + 1, 1, .6)
    twang.note(ts[1] - 12, t + 1.5, 1, .55)
    twang.note(ts[2] - 12, t + 2, 1.5, .6)
    if strum_it:
        strum(nylon, [bs + 24] + [x - 12 for x in ts], t, 1.8, .55)
        strum(nylon, [x - 12 for x in ts], t + 2.5, 1.2, .5, up=True)


def build(out):
    # intro: wind, bell, open fifths on the twang
    for k, ch in enumerate(INTRO_CH):
        t = song.t(I0 + k)
        root = {"Dm": "D3", "Bb": "Bb2", "A": "A2"}[ch]
        r = pitch(root)
        twang.note(r, t, 2, .8)
        twang.note(r + 7, t + 1.5, 1.5, .6)
        twang.note(r + 12, t + 2.5, 1.2, .5)
        bass.note(r - 12, t, 3.8, .6)
    drone.note(pitch("D2"), song.t(0), 7.8, .8)
    drone.note(pitch("A2"), song.t(0), 7.8, .7)
    bell.note(pitch("D3"), song.t(0), 3.5, 1)
    bell.note(pitch("A4"), song.t(0), 3.5, .25)
    bell.note(pitch("D3"), song.t(2), 3.5, .6)
    # A: the theme
    whistle.melody(THEME, song.t(A0), .95)
    for k in range(16):
        theme_bar(A0 + k, k % 8, strum_it=k >= 8)
        if k < 8:
            if k % 2 == 0:
                drone.note(pitch("D2"), song.t(A0 + k), 7.8, .6)
                drone.note(pitch("A2"), song.t(A0 + k), 7.8, .5)
        else:
            drums.hit("boom", song.t(A0 + k), .55 if k % 4 else .8)
    bell.note(pitch("D3"), song.t(A0 + 8), 3.5, .7)
    # B: twang melody, choir swell, whistle answers
    twang.melody(B_TWANG, song.t(B0), .95, hold=.9)
    whistle.melody(B_WHISTLE, song.t(B0), .85)
    for k, ch in enumerate(B_CH):
        t = song.t(B0 + k)
        r = pitch({"Dm": "D2", "C": "C2", "Bb": "Bb1", "A": "A1"}[ch])
        bass.note(r, t, 1.8, .9)
        bass.note(r + 7, t + 2, 1.8, .7)
        voice = {"Dm": ["A3", "D4", "F4"], "C": ["G3", "C4", "E4"], "Bb": ["F3", "Bb3", "D4"],
                 "A": ["E3", "A3", "C#4"]}[ch]
        for p in voice:
            choir.note(pitch(p), t, 3.8, .55 + .1 * (k % 4 == 0) + .05 * k)
        drums.hit("boom", t, .8 if k % 2 == 0 else .5)
        if k in (3, 7):
            drums.hit("boom", t + 3.5, .45)
    bell.note(pitch("D3"), song.t(B0), 3.5, .9)
    bell.note(pitch("A4"), song.t(B0), 3.5, .25)
    drums.hit("wind", song.t(B0 + 4), .8)
    # tail: the theme's first phrase, then its last, thinning out
    whistle.melody(THEME[:4] + THEME[12:], song.t(T0), .9)
    for k in range(8):
        i = k if k < 4 else k + 4
        theme_bar(T0 + k, i % 8, strum_it=k < 4)
    bell.note(pitch("D3"), song.t(T0), 3.5, .6)
    drums.hit("wind", song.t(T0 + 4), .7)
    for b in (0, 8, 12, 16):
        drums.hit("wind", song.t(b), .8)
    echo(twang, techo, .75, .9, second=1.5)
    techo.soften()
    return song.write(out, "The Caravan Thief", "D minor",
                      "Title (The Caravan Thief), recipes/western_ambient.md. The Sword Stories theme whistled over "
                      "echo twang; B is an Andalusian cadence with the choir. Ends on Dm(add9) into the quiet intro.",
                      gain=1.7, voice_over={"nylon": "wave=sq duty=.25 vol=.11 attack=.002 decay=.3 sus=.05 release=.2"})


if __name__ == "__main__":
    main(build, "title")
