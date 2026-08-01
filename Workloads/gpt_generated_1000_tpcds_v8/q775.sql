WITH page_returns AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    dr.d_year,
    dr.d_fy_week_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    hd_ref.hd_income_band_sk,
    hd_ret.hd_vehicle_count
  FROM catalog_returns cr
  JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  WHERE cp.cp_type = 'monthly'
    AND cp.cp_catalog_page_number BETWEEN 5 AND 20
    AND dr.d_fy_week_seq IN (3, 9, 13)
    AND dr.d_current_quarter = 'Y'
    AND cr.cr_warehouse_sk = 7
    AND cr.cr_returning_addr_sk > 2000000
    AND hd_ret.hd_vehicle_count >= 1
    AND dr.d_year = (SELECT MAX(d_year) FROM date_dim)
  GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id, cp.cp_type,
           cp.cp_catalog_page_number, dr.d_year, dr.d_fy_week_seq,
           hd_ref.hd_income_band_sk, hd_ret.hd_vehicle_count
),

filtered_page_returns AS (
  SELECT *
  FROM page_returns pr
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_page_sk = pr.cp_catalog_page_sk
      AND cp2.cp_type = 'quarterly'
  )
),

union_set AS (
  SELECT DISTINCT cp_type, total_return_amount
  FROM filtered_page_returns
  WHERE total_return_amount > 1000
  UNION
  SELECT DISTINCT cp_type, total_return_amount
  FROM filtered_page_returns
  WHERE avg_return_amount < 5
),

final_agg AS (
  SELECT
    us.cp_type,
    SUM(us.total_return_amount) AS sum_total_return,
    COUNT(*) AS cnt_type
  FROM union_set us
  GROUP BY us.cp_type
)

SELECT
  fa.cp_type,
  fa.sum_total_return,
  fa.cnt_type,
  SUM(fa.sum_total_return) OVER (PARTITION BY fa.cp_type) AS running_total,
  RANK() OVER (ORDER BY fa.sum_total_return DESC) AS revenue_rank
FROM final_agg fa
CROSS JOIN (VALUES (1)) AS t(dummy)
ORDER BY fa.sum_total_return DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
