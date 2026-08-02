"""
workload_generation.src.experiments -- incremental overrides on the v8 core.

Each experiment is ONE file that subclasses a core policy (FeedbackPolicy,
DiversityTracker, or ConcurrencyController) and overrides a single decision, then
is injected via pipeline.generate_query_batch(..., tracker=, policy=). Never edit
the core to run an experiment. Copy _template.py to start. See ../README.md.
"""
