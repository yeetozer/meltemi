# Asset contract (shared between game code and art/audio)

All paths relative to the Godot project root `~/projects/meltemi/game/`.
View: strict TOP-DOWN (bird's-eye), sprites drawn "facing up" (north = travel direction).
Light from top-left, soft shadow baked only where noted (rider/kite shadows are drawn by code).
Style: flat vector with 1–2 tone soft shading, rounded shapes, thin darker outline (ink #2B2B2B at ~35% or a darker shade of the fill).
Palette: cream #F4EBDD, terracotta #C8643B, olive #7A8B4A, sea-glass #8FC9B9, deep sea #1F6F8B, lagoon #4FB3BF,
sand #E8D3A8, foam #FFFFFF, ink #2B2B2B, lemon #F2C14E. Game logical resolution 720x1280 portrait; sizes below are PNG
pixel sizes at 1x logical (export PNGs at exactly these sizes, transparent background, centered pivot unless noted).
Every PNG has an SVG source in `art/src/` (outside game/), rendered by a script in `art/build_assets.py`.

## Sprites — game/assets/sprites/
| file | size | notes |
|---|---|---|
| rider.png | 72x72 | kiter on twin-tip board seen from above, board vertical (nose up), rider body/arms toward kite bar; harness + helmet/cap |
| rider_wipeout.png | 72x72 | rider in water splash, board tilted |
| kite_sunset.png | 140x70 | LEI kite canopy from above: curved arc (C-shape) with struts, leading edge at bottom edge; terracotta + cream |
| kite_seaglass.png / kite_olive.png / kite_lemon.png | 140x70 | same shape, palette variants |
| buoy.png | 40x40 | round orange/red racing buoy with white band |
| rock_small.png | 70x60 | grey-ochre rock with foam ring |
| rock_big.png | 140x110 | rock cluster with foam ring |
| turtle.png | 60x70 | sleeping sea turtle, head up |
| boat_fishing.png | 70x160 | small Mediterranean wooden fishing boat (pointed bow up), blue/white/terracotta, nets |
| jetski.png | 44x90 | jet ski, bow up |
| sailboat.png | 80x180 | small white sailboat seen from above with sail |
| shell.png | 32x32 | scallop shell, cream/coral |
| starfish.png | 40x40 | terracotta/lemon starfish |
| gust.png | 80x80 | stylised swirly wind lines, white/sea-glass, semi-transparent |
| wave.png | 256x48 | horizontally TILEABLE foam wave lip (white crest + turquoise front shade); used as a ramp band |
| wave_gold.png | 256x48 | same, golden/lemon tinted with sparkle |
| splash.png | 96x96 | white water splash burst |
| spray.png | 16x16 | soft white droplet particle |
| sparkle.png | 16x16 | 4-point sparkle particle |

## Shore & scenery — game/assets/sprites/scenery/
| file | size | notes |
|---|---|---|
| shore_left.png | 160x512 | vertically TILEABLE beach strip for the LEFT edge: sand on the left blending to wet sand/foam edge on the right side (transparent beyond foam) |
| shore_right.png | 160x512 | mirror for the right edge |
| house_white.png | 90x90 | whitewashed cube house roof from above, blue door hint |
| house_terracotta.png | 90x90 | terracotta tiled roof house |
| olive_tree.png | 80x80 | olive tree canopy from above |
| umbrella.png | 56x56 | beach umbrella striped (terracotta/cream) |
| lighthouse.png | 90x90 | round white/terracotta lighthouse from above |
| pier.png | 120x320 | wooden harbour pier/jetty, vertical |
| sandbar.png | 200x90 | shallow sandbar patch (light sand + turquoise rim, semi-transparent edges) |

## UI — game/assets/ui/
| file | size | notes |
|---|---|---|
| logo.png | 600x260 | game title wordmark "MELTEMI" + small kite mark, cream/terracotta/sea-glass |
| icon.png | 1024x1024 | app icon: kite + wave mark on sea-glass/cream background, no text, no transparency |
| icon_shell.png | 48x48 | HUD shell icon |
| icon_pause.png | 64x64 | pause glyph |
| icon_sound_on.png / icon_sound_off.png | 64x64 | |
| btn_bg.png | 96x96 | rounded cream button 9-slice-friendly (24 px corner radius) |

## Font — game/assets/fonts/
- `Fredoka-SemiBold.ttf` (or another rounded OFL font) + `OFL.txt` licence.

## Audio — game/assets/audio/ (WAV 44.1 kHz mono 16-bit, short, normalized ≤ -1 dBFS; ambience OGG allowed)
| file | notes |
|---|---|
| sfx_tack.wav | soft whoosh/swish 0.25 s |
| sfx_jump.wav | rising whoosh + pop 0.4 s |
| sfx_land_clean.wav | splashy thud with bright chime 0.4 s |
| sfx_land_bad.wav | heavier splash 0.5 s |
| sfx_splash.wav | wipeout big splash 0.8 s |
| sfx_shell.wav | bright ding 0.2 s |
| sfx_gust.wav | wind swell 0.6 s |
| sfx_trick.wav | quick spin whoosh 0.3 s |
| sfx_click.wav | UI tick 0.08 s |
| sfx_newbest.wav | small fanfare 1.0 s |
| amb_ocean.wav | seamless loop 8 s waves + light wind |
| music_loop.wav (optional) | chill Mediterranean-ish loop 16–30 s, guitar/marimba style |

## Licences
`game/assets/LICENSES.md` lists every file with source (self-generated / OFL font URL). No unlicensed downloads.
