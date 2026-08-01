WITH agg AS (
  SELECT
    ws_site.web_name AS web_name,
    sm.sm_type AS sm_type,
    i.i_category AS i_category,
    ca_bill.ca_state AS ca_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MIN(ws.ws_sold_date_sk) AS min_sold_date_sk,
    MAX(ws.ws_sold_date_sk) AS max_sold_date_sk,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  WHERE
    i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_rec_start_date <= DATE '2001-12-31'
    AND i.i_category = 'Electronics'
    AND sm.sm_type = 'Standard'
    AND ca_bill.ca_state = 'CA'
    AND ws_site.web_gmt_offset = -5.00
    AND c_bill.c_salutation = 'Mrs.'
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr_ref
      WHERE wr_ref.wr_refunded_customer_sk = c_bill.c_customer_sk
    )
  GROUP BY
    ws_site.web_name,
    sm.sm_type,
    i.i_category,
    ca_bill.ca_state
)
SELECT
  web_name,
  sm_type,
  i_category,
  ca_state,
  total_sales,
  total_quantity,
  avg_discount,
  order_count,
  min_sold_date_sk,
  max_sold_date_sk,
  total_return_amount,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (PARTITION BY web_name ORDER BY total_sales DESC ROWS UNBOUNDED PRECEDING) AS cumulative_sales_by_site
FROM agg
ORDER BY total_sales DESC
LIMIT 100
