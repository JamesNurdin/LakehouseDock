WITH sales_agg AS (
  SELECT
    ws_site.web_name AS website_name,
    td_s.t_shift AS time_shift,
    'sales' AS record_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
  FROM tpcds.web_sales ws
  JOIN tpcds.time_dim td_s
    ON ws.ws_sold_time_sk = td_s.t_time_sk
  JOIN tpcds.customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN tpcds.customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN tpcds.web_page wp_sales
    ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
  JOIN tpcds.customer c_page_owner
    ON wp_sales.wp_customer_sk = c_page_owner.c_customer_sk
  JOIN tpcds.web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN tpcds.warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
  LEFT JOIN tpcds.web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  LEFT JOIN tpcds.time_dim td_r
    ON wr.wr_returned_time_sk = td_r.t_time_sk
  LEFT JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN tpcds.customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
  LEFT JOIN tpcds.customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
  LEFT JOIN tpcds.web_page wp_ret
    ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
  WHERE td_s.t_shift = 'first'
  GROUP BY ws_site.web_name, td_s.t_shift
),
returns_agg AS (
  SELECT
    ws_site.web_name AS website_name,
    td_r.t_shift AS time_shift,
    'returns' AS record_type,
    COUNT(DISTINCT wr.wr_order_number) AS order_count,
    SUM(wr.wr_return_amt) AS total_net_paid,
    SUM(wr.wr_net_loss) AS total_discount,
    SUM(wr.wr_return_quantity) AS total_quantity
  FROM tpcds.web_returns wr
  JOIN tpcds.time_dim td_r
    ON wr.wr_returned_time_sk = td_r.t_time_sk
  JOIN tpcds.web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN tpcds.web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN tpcds.warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
  JOIN tpcds.web_page wp_ret
    ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
  JOIN tpcds.customer c_return_page_owner
    ON wp_ret.wp_customer_sk = c_return_page_owner.c_customer_sk
  JOIN tpcds.web_page wp_sales
    ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
  JOIN tpcds.customer c_sales_page_owner
    ON wp_sales.wp_customer_sk = c_sales_page_owner.c_customer_sk
  JOIN tpcds.customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
  JOIN tpcds.customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
  JOIN tpcds.customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN tpcds.customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE td_r.t_shift = 'first'
  GROUP BY ws_site.web_name, td_r.t_shift
)
SELECT
  website_name,
  time_shift,
  record_type,
  order_count,
  total_net_paid,
  total_discount,
  total_quantity
FROM (
  SELECT website_name, time_shift, record_type, order_count, total_net_paid, total_discount, total_quantity FROM sales_agg
  UNION ALL
  SELECT website_name, time_shift, record_type, order_count, total_net_paid, total_discount, total_quantity FROM returns_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
