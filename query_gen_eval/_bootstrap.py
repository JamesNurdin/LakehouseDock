"""
Path bootstrap.

``query_gen_eval`` re-uses the QueryDock generation/validation helpers that
live in ``src/LakehouseDock/trino_stack`` (and ``.../loader``).  Those modules
are imported as top-level packages (``trino_stack``, ``loader``) exactly the
way the ``launch_lakehouse.ipynb`` notebook imports them, i.e. with the
``LakehouseDock`` directory on ``sys.path``.

Since this package now lives *inside* ``LakehouseDock`` (as
``LakehouseDock/query_gen_eval``), ``trino_stack`` / ``loader`` are siblings and
are already importable whenever the notebook cwd is ``LakehouseDock``.  This
module makes that robust for standalone use too by ensuring the enclosing
``LakehouseDock`` directory is on ``sys.path`` so that::

    from trino_stack.query_generator import load_schema, make_openai_client

works from anywhere.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# src/LakehouseDock/query_gen_eval/_bootstrap.py  ->  src/LakehouseDock
_THIS_DIR = Path(__file__).resolve().parent
_LAKEHOUSE_DIR = _THIS_DIR.parent


def _candidate_lakehouse_dirs():
    # 1. explicit override, 2. enclosing dir, 3. anything already on the path.
    env = os.environ.get("LAKEHOUSEDOCK_ROOT")
    if env:
        yield Path(env)
    yield _LAKEHOUSE_DIR
    for entry in list(sys.path):
        cand = Path(entry) / "LakehouseDock"
        if cand.exists():
            yield cand


def ensure_lakehouse_on_path() -> Path | None:
    """Add the LakehouseDock directory to ``sys.path`` (idempotent)."""
    for cand in _candidate_lakehouse_dirs():
        if cand.exists() and (cand / "trino_stack").exists():
            cand_str = str(cand)
            if cand_str not in sys.path:
                sys.path.insert(0, cand_str)
            return cand
    return None


LAKEHOUSE_ROOT = ensure_lakehouse_on_path()
