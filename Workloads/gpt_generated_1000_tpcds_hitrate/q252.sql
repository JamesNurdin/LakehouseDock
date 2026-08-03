WITH agg_all AS (
  SELECT
    d.d_year,
    hd.hd_buy_potential,
    sm.sm_carrier,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_ext_sales_price) AS total_sales_price,
    COUNT(*) AS transaction_cnt
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
    AND hd.hd_buy_potential = '1001-5000'
    AND sm.sm_carrier = 'UPS'
    AND cr.cr_return_amount > 500
  GROUP BY CUBE (d.d_year, hd.hd_buy_potential, sm.sm_carrier)
  HAVING SUM(cr.cr_return_amount) > 1000
),
agg_high AS (
  SELECT
    d_year,
    hd_buy_potential,
    sm_carrier,
    total_return_amount,
    total_sales_price,
    transaction_cnt
  FROM agg_all
  WHERE total_return_amount > 2000
)
SELECT
  d_year,
  hd_buy_potential,
  sm_carrier,
  total_return_amount,
  total_sales_price,
  transaction_cnt
FROM agg_all
EXCEPT
SELECT
  d_year,
  hd_buy_potential,
  sm_carrier,
  total_return_amount,
  total_sales_price,
  transaction_cnt
FROM agg_high
ORDER BY d_year, hd_buy_potential, sm_carrier
LIMIT 100
