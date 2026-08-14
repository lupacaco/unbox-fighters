"""Os efeitos sonoros agora são gravados, não gerados por bip.

Use:

  python tools/fetch_sfx.py
"""
from __future__ import annotations

import runpy
from pathlib import Path

if __name__ == "__main__":
	runpy.run_path(str(Path(__file__).with_name("fetch_sfx.py")), run_name="__main__")
