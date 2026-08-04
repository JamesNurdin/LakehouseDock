WITH
  base AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_warehouse_sk,
      cr.cr_reason_sk,
      cp.cp_department,
      cp.cp_catalog_page_number,
      w.w_warehouse_name,
      w.w_city,
      r.r_reason_desc,
      t.t_shift,
      t.t_time,
      RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS amt_rank,
      SUM(cr.cr_return_amount) OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY cr.cr_returned_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      ) AS moving_sum_3,
      CASE
        WHEN cr.cr_return_amount > 500 THEN 'High'
        WHEN cr.cr_return_amount > 200 THEN 'Medium'
        ELSE 'Low'
      END AS amount_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w      ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    JOIN reason r         ON cr.cr_reason_sk      = r.r_reason_sk
    JOIN time_dim t       ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE w.w_country = 'United States'
      AND t.t_shift   = 'first'
      AND t.t_time BETWEEN 8 AND 17
  ),

  set_a AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity >= 2
  ),

  set_b AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 300
  ),

  set_c AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_fee > 0
  ),

  intersect_ab AS (
    SELECT cr_order_number FROM set_a INTERSECT SELECT cr_order_number FROM set_b
  ),

  final_set AS (
    SELECT cr_order_number FROM intersect_ab EXCEPT SELECT cr_order_number FROM set_c
  )

SELECT
  b.cr_order_number,
  b.w_warehouse_name,
  b.w_city,
  b.cp_department,
  b.amount_category,
  b.amt_rank,
  b.moving_sum_3
FROM base b
WHERE b.cr_order_number IN (SELECT cr_order_number FROM final_set)
ORDER BY b.amt_rank ASC, b.cr_order_number
LIMIT 100
