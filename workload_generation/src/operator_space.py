"""
operator_space -- the hardcoded operator ceiling (C_phys) + lever->operator map.

Loads resources/operators_ground_truth.csv and resources/lever_operator_map.csv
into typed, cached views, and exposes the reachable/structural operator sets used
as the coverage denominator (F-6) and the deficit-hint candidate pool (F-1).

This is the existing ``workload_generation.utils`` module. It already works and
is dependency-free, so for now re-export it here; physically move utils.py into
this file when convenient (and update importers).

PORT FROM: workload_generation/utils.py (v8), backed by workload_generation/resources/.
"""

from __future__ import annotations

from workload_generation.utils import (   # noqa: F401  (re-export)
    Operator, Lever,
    load_operators, load_levers, OPERATORS, LEVERS,
    operator_index, lever_index,
    reachable_operators, structural_operators, trivial_operators,
    expected_operator_types, levers_for_operators, levers_for_deficit,
)
