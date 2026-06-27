from __future__ import annotations

from typing import Any, Optional, Sequence

from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from .base_regressor import BaseRuntimeRegressor, RegressorConfig


class MLPRuntimeRegressor(BaseRuntimeRegressor):
    def __init__(
        self,
        config: Optional[RegressorConfig] = None,
        *,
        hidden_layer_sizes: Sequence[int] = (256, 128, 64),
        activation: str = "relu",
        solver: str = "adam",
        alpha: float = 1e-4,
        batch_size: int = 32,
        learning_rate_init: float = 1e-3,
        max_iter: int = 500,
        early_stopping: bool = True,
        validation_fraction: float = 0.1,
        n_iter_no_change: int = 20,
    ) -> None:
        super().__init__(config=config)
        self.hidden_layer_sizes = tuple(hidden_layer_sizes)
        self.activation = activation
        self.solver = solver
        self.alpha = alpha
        self.batch_size = batch_size
        self.learning_rate_init = learning_rate_init
        self.max_iter = max_iter
        self.early_stopping = early_stopping
        self.validation_fraction = validation_fraction
        self.n_iter_no_change = n_iter_no_change

    @property
    def model_name(self) -> str:
        return "mlp"

    def get_search_space(self) -> Dict[str, Any]:
        return {
            "mlp__hidden_layer_sizes": [(64,), (128,), (128, 64), (256, 128, 64)],
            "mlp__alpha": [1e-5, 1e-4, 1e-3],
            "mlp__learning_rate_init": [1e-4, 1e-3, 1e-2],
            "mlp__max_iter": [300, 500],
        }

    def _build_model(self) -> Any:
        mlp = MLPRegressor(
            hidden_layer_sizes=self.hidden_layer_sizes,
            activation=self.activation,
            solver=self.solver,
            alpha=self.alpha,
            batch_size=self.batch_size,
            learning_rate_init=self.learning_rate_init,
            max_iter=self.max_iter,
            early_stopping=self.early_stopping,
            validation_fraction=self.validation_fraction,
            n_iter_no_change=self.n_iter_no_change,
            random_state=self.config.random_state,
        )
        return Pipeline([
            ("scaler", StandardScaler()),
            ("mlp", mlp),
        ])
