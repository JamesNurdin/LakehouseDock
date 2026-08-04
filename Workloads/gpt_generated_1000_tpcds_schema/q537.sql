WITH base AS (
  SELECT
    cr.cr_call_center_sk,
    cc.cc_name,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    cr.cr_store_credit,
    hd_refunded.hd_income_band_sk AS refunded_income_band_sk,
    ib_refunded.ib_lower_bound AS refunded_income_lower,
    ib_refunded.ib_upper_bound AS refunded_income_upper,
    hd_returning.hd_income_band_sk AS returning_income_band_sk,
    ib_returning.ib_lower_bound AS returning_income_lower,
    ib_returning.ib_upper_bound AS returning_income_upper,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_state AS returning_state
  FROM catalog_returns cr
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  JOIN income_band ib_refunded
    ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
  JOIN income_band ib_returning
    ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
  WHERE cc.cc_state = 'CA'
),

amounts AS (
  SELECT
    b.*,
    ARRAY[b.cr_return_amount, b.cr_return_tax, b.cr_fee, b.cr_store_credit] AS amounts
  FROM base b
),

unnested AS (
  SELECT
    a.cr_call_center_sk,
    a.cc_name,
    a.refunded_state,
    a.returning_state,
    amt AS monetary_component,
    seq
  FROM amounts a
  CROSS JOIN UNNEST(a.amounts) WITH ORDINALITY AS t(amt, seq)
),

total_per_cc AS (
  SELECT
    cr_call_center_sk,
    SUM(cr_return_amount) AS total_return_amount
  FROM base
  GROUP BY cr_call_center_sk
),

agg1 AS (
  SELECT
    u.cr_call_center_sk,
    u.cc_name,
    u.seq AS component_order,
    SUM(u.monetary_component) AS component_sum,
    tp.total_return_amount,
    LAG(SUM(u.monetary_component)) OVER (PARTITION BY u.cr_call_center_sk ORDER BY u.seq) AS prev_component_sum
  FROM unnested u
  JOIN total_per_cc tp
    ON u.cr_call_center_sk = tp.cr_call_center_sk
  GROUP BY u.cr_call_center_sk, u.cc_name, u.seq, tp.total_return_amount
),

agg2 AS (
  SELECT
    b.cr_call_center_sk,
    b.cc_name,
    COUNT(*) AS return_cnt,
    MAX(b.returning_income_upper) AS max_returning_income_upper,
    MIN(b.refunded_income_lower) AS min_refunded_income_lower
  FROM base b
  WHERE b.returning_state = 'NY'
  GROUP BY b.cr_call_center_sk, b.cc_name
),

unioned AS (
  SELECT cr_call_center_sk, cc_name, component_sum AS metric, component_order AS ord
  FROM agg1
  UNION
  SELECT cr_call_center_sk, cc_name, CAST(return_cnt AS double) AS metric, NULL AS ord
  FROM agg2
),

subset AS (
  SELECT cr_call_center_sk
  FROM unioned
  WHERE metric > 1000
),

except_set AS (
  SELECT cr_call_center_sk
  FROM unioned
  EXCEPT
  SELECT cr_call_center_sk
  FROM subset
),

full_joined AS (
  SELECT
    u.cr_call_center_sk,
    u.cc_name,
    u.metric,
    u.ord,
    e.cr_call_center_sk AS except_cc_sk
  FROM unioned u
  FULL OUTER JOIN except_set e
    ON u.cr_call_center_sk = e.cr_call_center_sk
)
SELECT
  f.cr_call_center_sk,
  f.cc_name,
  f.metric,
  f.ord,
  f.except_cc_sk,
  ROW_NUMBER() OVER (PARTITION BY f.cc_name ORDER BY f.metric DESC) AS rn,
  (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_global
FROM full_joined f
WHERE f.metric IS NOT NULL
ORDER BY f.metric DESC
LIMIT 100
