WITH
  refund_summary AS (
    SELECT cr_refunded_customer_sk,
           SUM(cr_return_amount) AS total_refund
    FROM catalog_returns
    GROUP BY cr_refunded_customer_sk
  ),
  diff_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
  )
SELECT
  cust_ref.c_first_name,
  cust_ref.c_last_name,
  sm.sm_ship_mode_id,
  sm.sm_type,
  w.w_city,
  td_cr.t_hour,
  wp.wp_url,
  rs.total_refund,
  LAG(rs.total_refund) OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY td_cr.t_time) AS lag_total_refund,
  la.addr_count
FROM catalog_returns cr
RIGHT OUTER JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer cust_ref
  ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN refund_summary rs
  ON rs.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN diff_orders do
  ON do.cr_order_number = cr.cr_order_number
-- Join the second fact table through the shared time dimension
JOIN time_dim td_wr
  ON cr.cr_returned_time_sk = td_wr.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer cust_ret
  ON wp.wp_customer_sk = cust_ret.c_customer_sk
-- Lateral sub‑query to count addresses in the same state as the refunded address
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS addr_count
  FROM customer_address ca2
  WHERE ca2.ca_state = ca_ref.ca_state
) la ON TRUE
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr2
  WHERE wr2.wr_order_number = cr.cr_order_number
)
ORDER BY rs.total_refund DESC
LIMIT 100
