-- goal: combine return amounts per call center with unmatched call centers, filter, expand state/name arrays, and compute rankings using set operations
WITH
  call_center_stats AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(cr.cr_return_amount) DESC) AS state_rn
    FROM tpcds.call_center cc
    LEFT JOIN tpcds.catalog_returns cr
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_state
  ),
  catalog_return_stats AS (
    SELECT
      cr.cr_call_center_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 100
    GROUP BY cr.cr_call_center_sk
  ),
  full_joined AS (
    SELECT
      COALESCE(ccs.cc_call_center_sk, crs.cr_call_center_sk) AS call_center_sk,
      ccs.cc_name,
      ccs.cc_state,
      COALESCE(ccs.total_return_amount, 0) + COALESCE(crs.total_return_amount, 0) AS combined_total
    FROM call_center_stats ccs
    FULL OUTER JOIN catalog_return_stats crs
      ON ccs.cc_call_center_sk = crs.cr_call_center_sk
  ),
  max_return AS (
    SELECT MAX(cr_return_amount) AS max_return_amount FROM tpcds.catalog_returns
  )
-- First part of the UNION ALL
SELECT
  fj.call_center_sk,
  fj.cc_name,
  fj.cc_state,
  fj.combined_total,
  ROW_NUMBER() OVER (ORDER BY fj.combined_total DESC) AS global_rn,
  elem AS attribute,
  (SELECT max_return_amount FROM max_return) AS max_return_amount
FROM full_joined fj
CROSS JOIN LATERAL (SELECT ARRAY[fj.cc_state, fj.cc_name] AS arr) a
CROSS JOIN UNNEST(a.arr) AS t(elem)
WHERE fj.call_center_sk NOT IN (
  SELECT cr_call_center_sk FROM tpcds.catalog_returns WHERE cr_return_amount > 500
)
UNION ALL
-- Second part of the UNION ALL (unmatched call centers)
SELECT
  cc.cc_call_center_sk,
  cc.cc_name,
  cc.cc_state,
  0.0 AS combined_total,
  ROW_NUMBER() OVER (ORDER BY 0) AS global_rn,
  attr AS attribute,
  (SELECT max_return_amount FROM max_return) AS max_return_amount
FROM tpcds.call_center cc
CROSS JOIN LATERAL (SELECT ARRAY[cc.cc_state, cc.cc_country] AS arr) a
CROSS JOIN UNNEST(a.arr) AS t(attr)
WHERE cc.cc_employees > 500000
EXCEPT
SELECT
  call_center_sk,
  cc_name,
  cc_state,
  combined_total,
  global_rn,
  attribute,
  max_return_amount
FROM (
  SELECT
    fj.call_center_sk,
    fj.cc_name,
    fj.cc_state,
    fj.combined_total,
    ROW_NUMBER() OVER (ORDER BY fj.combined_total DESC) AS global_rn,
    elem AS attribute,
    (SELECT max_return_amount FROM max_return) AS max_return_amount
  FROM full_joined fj
  CROSS JOIN LATERAL (SELECT ARRAY[fj.cc_state, fj.cc_name] AS arr) a
  CROSS JOIN UNNEST(a.arr) AS t(elem)
  WHERE fj.call_center_sk NOT IN (
    SELECT cr_call_center_sk FROM tpcds.catalog_returns WHERE cr_return_amount > 500
  )
) sub
ORDER BY combined_total DESC
LIMIT 100
