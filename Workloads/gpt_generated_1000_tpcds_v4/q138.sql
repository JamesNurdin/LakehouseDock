WITH sold_dates AS (
  SELECT d_date_sk, d_year, d_month_seq, d_date
  FROM date_dim
),
ship_dates AS (
  SELECT d_date_sk, d_year AS ship_year, d_month_seq AS ship_month_seq
  FROM date_dim
),
inv AS (
  SELECT i.inv_date_sk, i.inv_quantity_on_hand
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
)
SELECT
  c.c_customer_id,
  ca.ca_state,
  cd.cd_gender,
  hd.hd_buy_potential,
  ws.ws_order_number,
  ws.ws_ext_sales_price,
  CASE
    WHEN ws.ws_ext_sales_price > 1000 THEN 'High'
    WHEN ws.ws_ext_sales_price > 500 THEN 'Medium'
    ELSE 'Low'
  END AS sales_category,
  SUM(ws.ws_quantity) AS total_quantity,
  COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_sold_date
FROM web_sales ws
JOIN sold_dates d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN ship_dates d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inv ON d_sold.d_date_sk = inv.inv_date_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory i2
    WHERE i2.inv_item_sk = ws.ws_item_sk
      AND i2.inv_quantity_on_hand > 0
)
  AND d_sold.d_year = 2001
  AND ca.ca_gmt_offset = -5.00
GROUP BY
  c.c_customer_id,
  ca.ca_state,
  cd.cd_gender,
  hd.hd_buy_potential,
  ws.ws_order_number,
  ws.ws_ext_sales_price,
  CASE
    WHEN ws.ws_ext_sales_price > 1000 THEN 'High'
    WHEN ws.ws_ext_sales_price > 500 THEN 'Medium'
    ELSE 'Low'
  END
ORDER BY total_sales DESC
LIMIT 100
