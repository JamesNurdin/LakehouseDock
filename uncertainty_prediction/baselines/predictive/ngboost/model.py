"""
NGBoost baseline (T2 mechanism).

Natural Gradient Boosting (Duan et al. 2020, github.com/stanfordmlgroup/ngboost)
fits a full probabilistic regression by gradient-boosting the parameters of a
chosen distribution. We use a Normal distribution over log-runtime, which gives
a per-query (mu_log, sigma_log) directly usable by the Gaussian metric path.

Native-encoder note: NGBoost is a tabular gradient-boosting method; its "native
encoder" is simply a feature table. Postgres reproductions feed it planner
row/cost estimates and table statistics. In the lakehouse we feed the same
`PlanFeatureAdapter` vector (operator counts + Trino cost estimates + coarse
structure), which is the honest lakehouse analogue.

Requires the `ngboost` package:  pip install ngboost
"""

from __future__ import annotations

from typing import Dict

import numpy as np


class NGBoostBaseline:
    def __init__(
        self,
        *,
        n_estimators: int = 500,
        learning_rate: float = 0.01,
        minibatch_frac: float = 1.0,
        seed: int = 42,
        verbose: bool = False,
    ):
        # imported lazily so the rest of the baselines don't hard-depend on ngboost
        from ngboost import NGBRegressor
        from ngboost.distns import Normal
        from ngboost.scores import LogScore

        self.model = NGBRegressor(
            Dist=Normal,
            Score=LogScore,
            n_estimators=n_estimators,
            learning_rate=learning_rate,
            minibatch_frac=minibatch_frac,
            random_state=seed,
            verbose=verbose,
        )

    def fit(self, X_train, y_train_log, **kwargs) -> "NGBoostBaseline":
        self.model.fit(np.asarray(X_train, dtype=float), np.asarray(y_train_log, dtype=float).reshape(-1))
        return self

    def predict_gaussian(self, X) -> Dict[str, np.ndarray]:
        """Return (mu_log, sigma_log) from the fitted Normal distribution."""
        dist = self.model.pred_dist(np.asarray(X, dtype=float))
        mu = np.asarray(dist.params["loc"], dtype=float).reshape(-1)
        sigma = np.asarray(dist.params["scale"], dtype=float).reshape(-1)
        return {"mu_log": mu, "sigma_log": np.clip(sigma, 1e-9, None)}
