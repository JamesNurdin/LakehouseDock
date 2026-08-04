WITH
  catalog_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
  ),
  web_orders AS (
    SELECT ws_order_number
    FROM web_sales
  ),
  exclusive_catalog_orders AS (
    SELECT cs_order_number
    FROM catalog_orders
    EXCEPT
    SELECT ws_order_number
    FROM web_orders
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  sm.sm_type AS ship_mode_type,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
  l.tax_estimate
FROM
  (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i
  LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  FULL OUTER JOIN customer cust_cur ON cust_cur.c_current_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN LATERAL (
    SELECT ws.ws_sales_price * 0.1 AS tax_estimate
  ) l ON true
  LEFT JOIN exclusive_catalog_orders eco ON cs.cs_order_number = eco.cs_order_number
WHERE
  i.i_current_price > 10
GROUP BY
  i.i_item_id,
  i.i_product_name,
  sm.sm_type,
  l.tax_estimate
ORDER BY
  total_web_sales DESC
OFFSET 10
LIMIT 100
