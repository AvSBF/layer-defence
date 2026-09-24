"""Regenerate every sprite in the game.

    python Tools/artgen/main.py

Output goes to Aseprites/Generated/ and a manifest.json describing every sheet.
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import chars  # noqa: E402
import fx  # noqa: E402
import px  # noqa: E402
import sfx  # noqa: E402
import ui  # noqa: E402
import world  # noqa: E402


def main():
    chars.build()
    fx.build()
    ui.build()
    world.build()
    sfx.build()
    px.write_manifest()
    print("[artgen] done")


if __name__ == "__main__":
    main()
