WITH base AS (
  SELECT
    wd.t_hour,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wr.wr_return_amt,
    wr.wr_net_loss,
    wr.wr_return_quantity
  FROM web_returns wr
  JOIN time_dim wd
    ON wr.wr_returned_time_sk = wd.t_time_sk
  JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib
    ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
  WHERE wd.t_hour BETWEEN 8 AND 20
    AND wd.t_meal_time = 'Lunch'
    AND hd_ret.hd_vehicle_count >= 2
    AND hd_ret.hd_dep_count <= 3
    AND ib.ib_upper_bound >= 50000
    AND wr.wr_return_amt > 100.00
    AND wr.wr_return_quantity >= 1
    AND wr.wr_return_ship_cost < 500.00
    AND wr.wr_reversed_charge BETWEEN 10 AND 200
),
agg AS (
  SELECT
    t_hour,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS returns_count,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_quantity) AS avg_quantity
  FROM base
  GROUP BY t_hour, ib_lower_bound, ib_upper_bound
)
SELECT
  t_hour,
  ib_lower_bound,
  ib_upper_bound,
  returns_count,
  total_return_amount,
  total_net_loss,
  avg_quantity,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 100
