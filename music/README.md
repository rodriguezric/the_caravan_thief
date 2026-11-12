# Music

The western score, from `../../midi_maker/recipes/western_ambient.md` (chipwave-song skill).

Each cue is `<cue>.py` → `<cue>.chipwave` (the song, built with `mt`) → `<cue>.ogg` (what the
game ships; `Sfx.music("<cue>")` loads it and loops it). Shared code: `western_kit.py` (voices,
kit, strum/gallop/echo helpers, `ship()` = render + ffmpeg to OGG) on top of `story_kit.py`.

    python3 title.py              # rebuild title.chipwave and title.ogg
    python3 title.py --no-ship    # .chipwave only
    python3 measure.py title.chipwave "I:0-4,A:4-20,B:20-28,T:28-36"   # levels per track/section
    ../../music_tracker/mt play title.chipwave --loops 2

| Cue | Title | Key, tempo, meter |
|---|---|---|
| title | The Caravan Thief | D minor, 72, 4/4 |
| road | The Saltway | A minor, 96, 4/4 |
| town | Kesh Crossing | F major, 120, 3/4 |
| camp | Waystation Embers | E Dorian, 76, 4/4 |
| heist | Light Fingers | D minor, 104, 4/4 |
| tension | Hooks in the Dark | E Phrygian, 72, 4/4 |
| omen | What the Blade Hears | C# Phrygian, 56, 4/4 |
| sad | The Pass of Teeth | A minor, 63, 3/4 |
| hope | Salt at Dawn | F major, 80, 4/4 |
| legend | What the Road Remembers | G harmonic minor, 88, 4/4 |
| battle | Draw! | A minor, 152, 4/4 |
| boss | The Factor | E Phrygian dominant, 138, 4/4 |
| minigame | Quick Hands | E Dorian, 126, 4/4 |
| victory | Dust Settles | C major, 124, 4/4 (fanfare once; loops from 3.871 s) |
| defeat | Buzzards | E minor, 60, 4/4 |
| ending | The Long Road Home | D major, 72, 4/4 |

A cue without an `.ogg` falls back to the generated song in `scripts/songs.gd`.
