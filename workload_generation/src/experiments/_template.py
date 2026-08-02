"""
experiment template -- copy to experiments/<your_idea>.py and edit.

An experiment overrides ONE decision on the v8 core and is injected at call time.
Constants live HERE as EXP_* (never in config.py). Keep the feedback_enabled=False
control working so every experiment has a clean v6 baseline.

Run:
    from workload_generation.src import pipeline
    from workload_generation.src.experiments.my_idea import MyPolicy, MyTracker
    pipeline.generate_query_batch(..., tracker=MyTracker(), policy=MyPolicy())
"""

from __future__ import annotations

from ..feedback import FeedbackPolicy
from ..diversity_tracker import DiversityTracker

# --- experiment constants (namespaced; do not put these in config.py) ---
EXP_EXAMPLE = 1.0


class MyPolicy(FeedbackPolicy):
    """Override one decision, e.g. how depth or hints are chosen."""
    def choose_hints(self, tracker, rng, *, family_name):
        return super().choose_hints(tracker, rng, family_name=family_name)


class MyTracker(DiversityTracker):
    """Override tracking/acceptance if the experiment needs it; else omit."""
    pass
