WITH
  sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  agg_returns AS (
    SELECT
      cr_call_center_sk,
      cr_reason_sk,
      cr_returned_date_sk,
      SUM(cr_return_amount)          AS total_return_amount,
      SUM(cr_return_quantity)        AS total_return_quantity,
      COUNT(*)                       AS cnt_returns
    FROM sampled_returns
    WHERE cr_return_amount > 100
    GROUP BY cr_call_center_sk, cr_reason_sk, cr_returned_date_sk
  ),
  reason_a AS (
    SELECT ar.cr_call_center_sk
    FROM agg_returns ar
    JOIN reason r ON ar.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
  ),
  reason_b AS (
    SELECT ar.cr_call_center_sk
    FROM agg_returns ar
    JOIN reason r ON ar.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer Not Satisfied'
  ),
  call_centers_excluded AS (
    SELECT cr_call_center_sk FROM reason_a
    EXCEPT
    SELECT cr_call_center_sk FROM reason_b
  ),
  joined AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_state,
      cc.cc_employees,
      r.r_reason_desc,
      d.d_year,
      ar.total_return_amount,
      ar.total_return_quantity,
      ar.cnt_returns,
      RANK() OVER (PARTITION BY d.d_year ORDER BY ar.total_return_amount DESC) AS revenue_rank
    FROM agg_returns ar
    JOIN call_center cc   ON ar.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d        ON ar.cr_returned_date_sk = d.d_date_sk
    JOIN reason r          ON ar.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_employees > 150
      AND d.d_year = 2002
      AND r.r_reason_desc LIKE '%damage%'
      AND ar.total_return_amount > 500
      AND cc.cc_call_center_sk IN (SELECT cr_call_center_sk FROM call_centers_excluded)
  )
SELECT
  cc_call_center_id,
  cc_state,
  cc_employees,
  r_reason_desc,
  d_year,
  total_return_amount,
  total_return_quantity,
  cnt_returns,
  revenue_rank
FROM joined
ORDER BY d_year, revenue_rank, cc_call_center_id
LIMIT 100
