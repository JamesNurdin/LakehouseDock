WITH intersect_items AS (
  SELECT ss2.ss_item_sk AS i_item_sk
  FROM store_sales ss2
  INTERSECT
  SELECT ws2.ws_item_sk
  FROM web_sales ws2
)
SELECT
  i.i_category,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(ss.ss_ext_sales_price) AS total_store_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  (SELECT SUM(ws2.ws_ext_sales_price)
   FROM web_sales ws2
   JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
   WHERE i2.i_category = i.i_category) AS cat_total_web_sales,
  COUNT(DISTINCT cust.c_customer_sk) AS distinct_customers,
  AVG(ss.ss_net_profit) AS avg_store_profit,
  AVG(ws.ws_net_profit) AS avg_web_profit
FROM store_sales ss
JOIN date_dim ds_sales ON ss.ss_sold_date_sk = ds_sales.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN date_dim ds_return ON sr.sr_returned_date_sk = ds_return.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim ds_websold ON ws.ws_sold_date_sk = ds_websold.d_date_sk
JOIN date_dim ds_webship ON ws.ws_ship_date_sk = ds_webship.d_date_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
WHERE ds_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND NOT EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = cust.c_customer_sk
  )
  AND i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
GROUP BY GROUPING SETS (
  (i.i_category, ib.ib_lower_bound, ib.ib_upper_bound),
  (i.i_category, ib.ib_lower_bound),
  (i.i_category)
)
ORDER BY total_store_sales DESC
LIMIT 100
