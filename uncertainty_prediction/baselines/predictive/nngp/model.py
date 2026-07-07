"""
NNGP baseline (T3 retargeted from cardinality; github.com/Kangfei/NNGP-src).

The Neural Network Gaussian Process is the exact GP an infinitely-wide ReLU MLP
induces (Lee et al. 2018). NNGP-src used it for cardinality estimation; here it
is retargeted to log-runtime regression. Because it is an exact GP, prediction
yields a closed-form Gaussian posterior (mu, sigma) per query — no sampling,
and the sigma already includes the observation-noise term — which flows through
the standard Gaussian metric path.

Native-encoder note: the NNGP kernel is defined on a fixed feature vector, so
the honest lakehouse encoder is the shared `PlanFeatureAdapter` vector (same one
the thesis model and the other feature baselines use).

Kernel: recursive arccosine (ReLU) kernel over `depth` layers with weight/bias
variances (sigma_w^2, sigma_b^2); GP regression with noise sigma_n^2.
"""

from __future__ import annotations

from typing import Dict

import numpy as np


class NNGPBaseline:
    def __init__(
        self,
        *,
        depth: int = 3,
        sigma_w2: float = 1.6,
        sigma_b2: float = 0.1,
        noise: float = 0.1,
        seed: int = 42,
    ):
        self.depth = depth
        self.sigma_w2 = sigma_w2
        self.sigma_b2 = sigma_b2
        self.noise = noise
        self.seed = seed

    # ------------------------------------------------------------------
    # NNGP arccosine (ReLU) kernel
    # ------------------------------------------------------------------
    def _base_kernel(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        d = A.shape[1]
        return self.sigma_b2 + self.sigma_w2 * (A @ B.T) / d

    def _recurse(self, K_ab: np.ndarray, K_aa: np.ndarray, K_bb: np.ndarray) -> np.ndarray:
        denom = np.sqrt(np.outer(K_aa, K_bb))
        denom = np.clip(denom, 1e-12, None)
        cos = np.clip(K_ab / denom, -1.0, 1.0)
        theta = np.arccos(cos)
        f = np.sqrt(np.outer(K_aa, K_bb)) * (np.sin(theta) + (np.pi - theta) * cos) / (2.0 * np.pi)
        return self.sigma_b2 + self.sigma_w2 * f

    def _kernel(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        """Full NNGP kernel between rows of A and B."""
        # diagonal self-kernels are needed at each layer for normalisation
        Kaa = self._diag(A)
        Kbb = self._diag(B)
        Kab = self._base_kernel(A, B)
        Kaa_l, Kbb_l = self._base_diag(A), self._base_diag(B)
        for _ in range(self.depth):
            Kab = self._recurse(Kab, Kaa_l, Kbb_l)
            Kaa_l = self._recurse_diag(Kaa_l)
            Kbb_l = self._recurse_diag(Kbb_l)
        return Kab

    def _base_diag(self, A: np.ndarray) -> np.ndarray:
        d = A.shape[1]
        return self.sigma_b2 + self.sigma_w2 * np.sum(A * A, axis=1) / d

    def _recurse_diag(self, Kaa: np.ndarray) -> np.ndarray:
        # for x == x', theta = 0 -> f = Kaa / 2
        return self.sigma_b2 + self.sigma_w2 * (Kaa / 2.0)

    def _diag(self, A: np.ndarray) -> np.ndarray:
        Kaa = self._base_diag(A)
        for _ in range(self.depth):
            Kaa = self._recurse_diag(Kaa)
        return Kaa

    # ------------------------------------------------------------------
    def fit(self, X_train, y_train_log, **kwargs) -> "NNGPBaseline":
        self.X_train = np.asarray(X_train, dtype=np.float64)
        self.y_train = np.asarray(y_train_log, dtype=np.float64).reshape(-1)
        self.y_mean = float(self.y_train.mean())
        yc = self.y_train - self.y_mean

        K = self._kernel(self.X_train, self.X_train)
        K += (self.noise ** 2) * np.eye(K.shape[0])
        # robust solve via Cholesky with jitter fallback
        jitter = 1e-6
        for _ in range(6):
            try:
                self.L = np.linalg.cholesky(K + jitter * np.eye(K.shape[0]))
                break
            except np.linalg.LinAlgError:
                jitter *= 10
        self.alpha = np.linalg.solve(self.L.T, np.linalg.solve(self.L, yc))
        return self

    def predict_gaussian(self, X) -> Dict[str, np.ndarray]:
        Xs = np.asarray(X, dtype=np.float64)
        Ks = self._kernel(self.X_train, Xs)          # [n_train, n_test]
        mu = Ks.T @ self.alpha + self.y_mean
        v = np.linalg.solve(self.L, Ks)              # [n_train, n_test]
        Kss = self._diag(Xs)                         # [n_test]
        var = Kss - np.sum(v * v, axis=0) + self.noise ** 2
        sigma = np.sqrt(np.clip(var, 1e-9, None))
        return {"mu_log": mu.reshape(-1), "sigma_log": sigma.reshape(-1)}
