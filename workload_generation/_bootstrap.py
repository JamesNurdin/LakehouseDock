"""
Path bootstrap.

``workload_generation`` re-uses infrastructure helpers that live in
``src/LakehouseDock/trino_stack`` (config, workload utilities, Trino
connections) and ``.../loader``.  Those modules are imported as top-level
packages (``trino_stack``, ``loader``) exactly the way the
``launch_lakehouse.ipynb`` notebook imports them, i.e. with the
``LakehouseDock`` directory on ``sys.path``.

Since this package lives *inside* ``LakehouseDock`` (as
``LakehouseDock/workload_generation``), ``trino_stack`` / ``loader`` are siblings and
are already importable whenever the notebook cwd is ``LakehouseDock``.  This
module makes that robust for standalone use too by ensuring the enclosing
``LakehouseDock`` directory is on ``sys.path`` so that::

    from trino_stack.workload import ensure_dir
    from trino_stack.config import WORKLOAD_ROOT

works from anywhere.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# src/LakehouseDock/workload_generation/_bootstrap.py  ->  src/LakehouseDock
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
