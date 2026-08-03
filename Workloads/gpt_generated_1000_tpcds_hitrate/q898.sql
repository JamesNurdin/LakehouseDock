WITH deep_join AS (
  SELECT
    cr.cr_return_amount,
    d_ret.d_year,
    s.s_store_name
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
  JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
  JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
  WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
      AND cr2.cr_return_amount > 100
  )
),
agg_high AS (
  SELECT
    s_store_name,
    d_year,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt
  FROM deep_join
  WHERE cr_return_amount > 200
  GROUP BY ROLLUP (s_store_name, d_year)
),
agg_low AS (
  SELECT
    s_store_name,
    d_year,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt
  FROM deep_join
  WHERE cr_return_amount <= 200
  GROUP BY ROLLUP (s_store_name, d_year)
),
unioned AS (
  SELECT * FROM agg_high
  UNION DISTINCT
  SELECT * FROM agg_low
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_return_amount DESC) AS rnk,
    LAG(total_return_amount) OVER (PARTITION BY s_store_name ORDER BY d_year) AS lag_total_return,
    SUM(total_return_amount) OVER (PARTITION BY s_store_name ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return
  FROM unioned
)
SELECT
  s_store_name,
  d_year,
  total_return_amount,
  avg_return_amount,
  return_cnt,
  rnk,
  lag_total_return,
  running_total_return
FROM ranked
WHERE rnk <= 5
ORDER BY total_return_amount DESC
LIMIT 100
