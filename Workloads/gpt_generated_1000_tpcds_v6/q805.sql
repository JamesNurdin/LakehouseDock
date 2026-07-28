WITH base AS (
  SELECT
    d.d_year AS year,
    hd_ret.hd_income_band_sk AS income_band,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN inventory i ON i.inv_date_sk = d.d_date_sk
  WHERE d.d_fy_year = 1915
    AND d.d_following_holiday = 'N'
    AND cr.cr_fee BETWEEN 20 AND 80
    AND cr.cr_store_credit > 10
    AND hd_ret.hd_income_band_sk IN (12, 15, 16)
    AND hd_ret.hd_dep_count <= 3
    AND i.inv_quantity_on_hand > 0
  GROUP BY ROLLUP (d.d_year, hd_ret.hd_income_band_sk)
)
SELECT
  year,
  income_band,
  total_return_amount,
  avg_fee,
  total_store_credit,
  return_cnt,
  CASE WHEN total_net_loss > 5000 THEN 'High' ELSE 'Low' END AS loss_category,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_return_amount DESC) AS rn_year
FROM base
ORDER BY year, income_band
LIMIT 100
