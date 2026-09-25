# Third-party components

Layer Defence ships no third-party art, audio, fonts or gameplay code. The only
third-party software involved is the engine it runs on and the build-time
tooling used to generate the assets.

## Shipped with the game

### Godot Engine 4.7.1

- License: MIT — <https://godotengine.org/license>
- Copyright (c) 2014-present Godot Engine contributors.
- Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
- Used as the runtime for every build (`index.wasm` / `index.pck` in the web
  export, the executable in the desktop export).

The engine is statically linked into the exported binaries, so its own bundled
dependencies are distributed with the game as well. The full, always up-to-date
list lives in the engine repository at
<https://github.com/godotengine/godot/blob/master/THIRD_PARTY.md>; the main
components are:

| Component | License |
|---|---|
| FreeType | FTL / GPLv2 (used under the FTL option) |
| HarfBuzz | MIT |
| ICU (icudt_godot.dat) | Unicode-3.0 |
| libpng | libpng-2.0 |
| zlib | Zlib |
| mbedTLS | Apache-2.0 |
| ENet | MIT |
| libogg / libvorbis / libtheora | BSD-3-Clause |
| Basis Universal | Apache-2.0 |
| Recast & Detour | Zlib |
| ThorVG | MIT |
| MoltenVK (Apple builds) | Apache-2.0 |
| ANGLE (Windows builds) | BSD-3-Clause |

If you redistribute a build, keep this file (or the engine's own
`THIRD_PARTY.md`) next to it.

## Build-time only (not shipped)

| Tool | License | Purpose |
|---|---|---|
| Python 3.13 | PSF-2.0 | runs the asset generators |
| Pillow | MIT-CMU | pixel-art rendering (`Tools/artgen/px.py`) |
| Aseprite (optional) | EULA of the user | only used for the original prototype sketches in `Aseprites/Debug/` |

## Fonts

The in-game font is not a third-party font: it is a 5×7 bitmap typeface
(`Tools/artgen/ui.py`) authored for this project, converted to BMFont format by
the generator, and therefore covered by `LICENSE-ASSETS.md`.

## Attribution line for the store page

```
Engine: Godot Engine 4.7.1 (MIT).
Art, sound effects and bitmap font: generated in-house by AvSGames (CC BY 4.0).
```
