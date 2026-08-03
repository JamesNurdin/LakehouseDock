WITH
  sampled_cc AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (20)
    WHERE regexp_like(cc_name, '^.*Center.*$')
  ),
  returns_agg AS (
    SELECT
      cr.cr_call_center_sk,
      cr.cr_ship_mode_sk,
      sum(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN sampled_cc cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_contract, '^.*[A-Z]{2}$')
      AND sm.sm_code LIKE 'A%'
    GROUP BY cr.cr_call_center_sk, cr.cr_ship_mode_sk
  ),
  all_calls AS (
    SELECT cc.cc_call_center_sk
    FROM sampled_cc cc
  ),
  filtered_calls AS (
    SELECT cc_call_center_sk
    FROM all_calls
    EXCEPT
    SELECT cr_call_center_sk
    FROM returns_agg
    WHERE total_return_amount < 1000
  )
SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  sm.sm_ship_mode_id,
  ra.total_return_amount,
  (
    SELECT avg(cr2.cr_refunded_cash)
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
  ) AS avg_refunded_cash,
  regexp_extract(sm.sm_contract, '([A-Z]+)', 1) AS contract_prefix,
  substring(cc.cc_city FROM 1 FOR 3) AS city_prefix
FROM filtered_calls fc
JOIN sampled_cc cc ON fc.cc_call_center_sk = cc.cc_call_center_sk
JOIN returns_agg ra ON ra.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY ra.total_return_amount DESC
OFFSET 0 FETCH NEXT 50 ROWS ONLY
