#!/usr/bin/env python3
"""defeat: "Buzzards" (recipes/western_ambient.md). A lone harmonica falling
over an E-B drone, wind, and a buzzard's cry overhead.
E minor, 60 BPM, 4/4. A 8 | A' 8. Ends on Em with a bar of wind so the loop
restarts without a seam. 16 bars = 64 s.
"""
from western_kit import WSong, voicing, root_in, main, pitch

PROG = ["Em", "Em", "C", "C", "Am", "Am", "B", "B", "Em", "Em", "C", "C", "Am", "B", "Em", "Em"]
MEL = ["B4:2 G4:1 E4:1", "F#4:3f r:1", "G4:2 E4:1 C4:1", "E4:4f", "A4:2 C5:1 B4:1", "A4:3f r:1",
       "F#4:2 A4:1 B4:1", "D#4:4f", "E5:2 B4:1 G4:1", "F#4:3f r:1", "G4:1.5 A4:.5 B4:1 G4:1", "E4:4f",
       "C5:2 A4:2", "B4:2 D#4:2f", "E4:4", "r:4"]

song = WSong(60, 4, 16, PROG)
harm = song.part("harmonica")
whistle = song.part("whistle")
drone = song.part("drone")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)


def build(out):
    harm.melody(MEL, song.t(0), .9)
    for b in (2, 10):
        whistle.note(pitch("E6"), song.t(b, 1), 1.6, .45, slide=-5)
        whistle.note(pitch("D6"), song.t(b, 3), 1.0, .3, slide=-5)
    for b, ch in enumerate(PROG):
        t = song.t(b)
        if b % 4 == 0:
            drone.note(pitch("E2"), t, 15.8, .8)
            drone.note(pitch("B2"), t, 15.8, .6)
        if b % 2 == 0:
            bass.note(root_in(ch, 40), t, 3.6, .7)
        if b % 4 == 0 or b == 15:
            drums.hit("wind", t, .8)
    return song.write(out, "Buzzards", "E minor",
                      "Defeat (The Caravan Thief), recipes/western_ambient.md. Falling harmonica, E-B drone, wind, "
                      "buzzard cries. Ends on Em.", gain=2.0, kit_vol=.6)


if __name__ == "__main__":
    main(build, "defeat")
