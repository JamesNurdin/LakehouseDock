WITH filtered_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_catalog_page_sk,
    cr.cr_call_center_sk,
    cr.cr_refunded_hdemo_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_ship_cost,
    cr.cr_returned_time_sk
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND d.d_month_seq BETWEEN 1 AND 6
)
SELECT
  cp.cp_type,
  cc.cc_state,
  CONCAT(cc.cc_state, '-', cp.cp_type) AS state_type,
  CASE
    WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
    WHEN cr.cr_return_amount > 100 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS return_category,
  COUNT(DISTINCT cr.cr_return_quantity) AS distinct_quantity_cnt,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
  REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word_desc
FROM filtered_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cp.cp_description LIKE '%sale%'
  AND regexp_like(cc.cc_name, '^A.*')
GROUP BY
  cp.cp_type,
  cc.cc_state,
  CONCAT(cc.cc_state, '-', cp.cp_type),
  CASE
    WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
    WHEN cr.cr_return_amount > 100 THEN 'MEDIUM'
    ELSE 'LOW'
  END,
  REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)
ORDER BY total_return_amount DESC
LIMIT 100
