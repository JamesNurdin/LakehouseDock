WITH base AS (
  SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    i.inv_quantity_on_hand,
    ws.web_state,
    hd_refunded.hd_income_band_sk,
    hd_refunded.hd_buy_potential
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND cr.cr_return_amount > 50
    AND hd_refunded.hd_income_band_sk IN (4, 5, 6)
    AND sm.sm_type = 'AIR'
    AND i.inv_quantity_on_hand >= 0
    AND ws.web_state = 'CA'
    AND hd_refunded.hd_buy_potential = '1001-5000'
),
agg AS (
  SELECT
    d_year,
    sm_ship_mode_id,
    SUM(cr_return_amount) AS total_cr_return_amount,
    SUM(wr_return_amt) AS total_wr_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT cr_return_quantity) AS distinct_return_qty,
    SUM(cr_return_tax + wr_return_tax) AS total_tax,
    COUNT(*) AS row_cnt
  FROM base
  GROUP BY d_year, sm_ship_mode_id
)
SELECT
  d_year,
  sm_ship_mode_id,
  total_cr_return_amount,
  total_wr_return_amount,
  avg_inventory_qty,
  total_tax,
  row_cnt,
  (total_cr_return_amount / NULLIF(total_wr_return_amount, 0)) AS cr_to_wr_return_ratio
FROM agg
WHERE total_cr_return_amount > 1000
  AND total_wr_return_amount > 500
  AND avg_inventory_qty >= 10
ORDER BY d_year DESC, total_cr_return_amount DESC
LIMIT 100
