WITH cat_agg AS (
  SELECT
    cr.cr_reason_sk,
    cr.cr_ship_mode_sk,
    cr.cr_returning_hdemo_sk,
    cr.cr_returned_date_sk,
    SUM(cr.cr_return_amount) AS cat_total_return_amount,
    COUNT(*) AS cat_return_cnt
  FROM catalog_returns cr
  GROUP BY cr.cr_reason_sk, cr.cr_ship_mode_sk, cr.cr_returning_hdemo_sk, cr.cr_returned_date_sk
),
web_agg AS (
  SELECT
    wr.wr_reason_sk,
    wr.wr_returned_date_sk,
    SUM(wr.wr_return_amt) AS web_total_return_amount,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  GROUP BY wr.wr_reason_sk, wr.wr_returned_date_sk
)
SELECT
  dd1.d_date                               AS return_date,
  dd1.d_year                               AS year,
  r.r_reason_desc                          AS reason_description,
  sm.sm_type                               AS ship_mode_type,
  hd_ret.hd_vehicle_count                  AS vehicle_count,
  ib.ib_upper_bound                        AS income_upper_bound,
  cat_agg.cat_total_return_amount,
  web_agg.web_total_return_amount,
  (cat_agg.cat_total_return_amount + web_agg.web_total_return_amount) AS combined_total_return,
  ROW_NUMBER() OVER (PARTITION BY dd1.d_year
                     ORDER BY (cat_agg.cat_total_return_amount + web_agg.web_total_return_amount) DESC) AS rank_within_year,
  CASE
    WHEN ib.ib_upper_bound > 80000 THEN 'High Income'
    ELSE 'Mid/Low Income'
  END                                      AS income_category,
  (SELECT AVG(cr2.cr_return_amount)
   FROM catalog_returns cr2
   WHERE cr2.cr_reason_sk = r.r_reason_sk) AS avg_return_amount_for_reason
FROM cat_agg
JOIN date_dim dd1
  ON cat_agg.cr_returned_date_sk = dd1.d_date_sk
JOIN web_agg
  ON cat_agg.cr_reason_sk = web_agg.wr_reason_sk
JOIN date_dim dd2
  ON web_agg.wr_returned_date_sk = dd2.d_date_sk
JOIN reason r
  ON cat_agg.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cat_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_ret
  ON cat_agg.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib
  ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_site ws
  ON ws.web_open_date_sk = dd1.d_date_sk
WHERE dd1.d_year = 2001
  AND ib.ib_upper_bound <= 100000
  AND hd_ret.hd_vehicle_count > 0
  AND r.r_reason_desc NOT LIKE '%defect%'
  AND sm.sm_type = 'AIR'
  AND ws.web_country = 'United States'
  AND dd1.d_year = dd2.d_year
ORDER BY combined_total_return DESC
LIMIT 100
