WITH base AS (
  SELECT
    s.s_store_id          AS store_id,
    d.d_year              AS year,
    sr.sr_return_amt      AS sr_return,
    cr.cr_return_amount   AS cr_return,
    i.i_current_price    AS item_price,
    cc.cc_state           AS cc_state,
    sm.sm_type            AS ship_type,
    hd.hd_income_band_sk  AS income_band,
    cd.cd_education_status AS education
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2002
    AND sm.sm_type IN ('NEXT DAY', 'REGULAR')
    AND cc.cc_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND hd.hd_income_band_sk BETWEEN 5 AND 10
    AND cd.cd_education_status = 'College'
),
agg1 AS (
  SELECT
    store_id,
    year,
    SUM(sr_return + cr_return) AS total_return,
    COUNT(*) AS txn_count
  FROM base
  GROUP BY store_id, year
),
agg2 AS (
  SELECT
    store_id,
    year,
    SUM(sr_return) AS total_return,
    COUNT(*) AS txn_count
  FROM base
  WHERE item_price > 100
  GROUP BY store_id, year
)
SELECT
  store_id,
  year,
  SUM(total_return)            AS grand_total_return,
  SUM(txn_count)               AS total_txns,
  AVG(total_return)            AS avg_return_per_store_year
FROM (
  SELECT store_id, year, total_return, txn_count FROM agg1
  UNION DISTINCT
  SELECT store_id, year, total_return, txn_count FROM agg2
) u
GROUP BY store_id, year
HAVING SUM(total_return) > 10000
ORDER BY grand_total_return DESC
LIMIT 100
