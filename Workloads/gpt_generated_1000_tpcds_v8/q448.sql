WITH
  base AS (
    SELECT
      cr.cr_returned_date_sk,
      td.t_hour,
      i.i_item_id,
      i.i_category,
      p.p_promo_name,
      w.w_warehouse_name,
      r.r_reason_desc,
      c.c_customer_id,
      ca.ca_state,
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wr.wr_return_amt,
      wr.wr_net_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                      AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_returned_time_sk = td.t_time_sk
                         AND wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_reason_sk = r.r_reason_sk
                         AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND w.w_gmt_offset = -5.00
      AND p.p_discount_active = 'Y'
  ),
  high_value_sales AS (
    SELECT ws_order_number, ws_ext_sales_price
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
  ),
  returned_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
  ),
  order_exceptions AS (
    SELECT ws_order_number
    FROM high_value_sales
    EXCEPT
    SELECT cr_order_number
    FROM returned_orders
  ),
  profit_customers AS (
    SELECT c.c_customer_id AS c_id
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_net_profit > 0
  ),
  loss_customers AS (
    SELECT c.c_customer_id AS c_id
    FROM customer c
    JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
    WHERE cr.cr_net_loss > 0
  ),
  common_customers AS (
    SELECT c_id
    FROM profit_customers
    INTERSECT
    SELECT c_id
    FROM loss_customers
  ),
  state_subset AS (
    SELECT ca_state
    FROM customer_address
    WHERE ca_state IN ('CA','TX','NY')
  ),
  cross_vals AS (
    SELECT 1 AS val UNION ALL SELECT 2 UNION ALL SELECT 3
  ),
  cross_joined AS (
    SELECT ss.ca_state, cv.val
    FROM state_subset ss
    CROSS JOIN cross_vals cv
  )
SELECT
  COALESCE(b.i_category, 'ALL') AS category,
  COALESCE(b.w_warehouse_name, 'ALL') AS warehouse,
  SUM(b.ws_ext_sales_price) AS total_sales,
  AVG(b.ws_net_profit) AS avg_profit,
  SUM(b.wr_return_amt) AS total_return_amount,
  COUNT(DISTINCT b.ws_order_number) AS distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(b.i_category, 'ALL') ORDER BY SUM(b.ws_ext_sales_price) DESC) AS sales_rank,
  COUNT(*) OVER () AS total_rows,
  COUNT(*) FILTER (WHERE b.ws_order_number IN (SELECT ws_order_number FROM order_exceptions)) AS exception_orders,
  COUNT(*) FILTER (WHERE b.c_customer_id IN (SELECT c_id FROM common_customers)) AS common_customer_rows,
  cj.ca_state,
  cj.val
FROM base b
LEFT JOIN cross_joined cj ON TRUE
GROUP BY ROLLUP (b.i_category, b.w_warehouse_name), cj.ca_state, cj.val
ORDER BY total_sales DESC
LIMIT 100
