WITH bill_stats AS (
  SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'AIR'
    AND hd.hd_dep_count >= 2
    AND ws.ws_quantity > 5
  GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
),
ship_stats AS (
  SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'AIR'
    AND hd.hd_dep_count >= 2
    AND ws.ws_quantity > 5
  GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential
)
SELECT
  combined.sm_ship_mode_id,
  combined.sm_carrier,
  combined.ib_lower_bound,
  combined.ib_upper_bound,
  combined.hd_buy_potential,
  combined.total_net_profit,
  combined.total_quantity,
  combined.order_cnt,
  RANK() OVER (PARTITION BY combined.sm_carrier ORDER BY combined.total_net_profit DESC) AS profit_rank,
  SUM(combined.total_net_profit) OVER (
    PARTITION BY combined.sm_carrier
    ORDER BY combined.total_net_profit
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_profit
FROM (
  SELECT
    sm_ship_mode_id,
    sm_carrier,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_net_profit,
    total_quantity,
    order_cnt
  FROM bill_stats
  UNION ALL
  SELECT
    sm_ship_mode_id,
    sm_carrier,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_net_profit,
    total_quantity,
    order_cnt
  FROM ship_stats
) AS combined
ORDER BY profit_rank, combined.total_net_profit DESC
LIMIT 100
