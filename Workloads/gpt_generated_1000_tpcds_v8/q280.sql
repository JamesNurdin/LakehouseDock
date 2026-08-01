WITH
  avg_disc AS (
    SELECT AVG(cs_ext_discount_amt) AS avg_disc
    FROM catalog_sales
  ),
  common_cust AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_bill_customer_sk FROM web_sales ws
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price + wsale.ws_ext_sales_price) DESC) AS rn,
  s.s_store_name,
  ws.web_name,
  CASE WHEN d1.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  SUM(cs.cs_ext_sales_price + wsale.ws_ext_sales_price) AS total_sales,
  SUM(cs.cs_quantity + wsale.ws_quantity) AS total_quantity,
  COUNT(DISTINCT CASE WHEN ib.ib_upper_bound > 150000 THEN cs.cs_bill_customer_sk END) AS high_income_customers,
  COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
  (SELECT avg_disc FROM avg_disc) AS avg_catalog_discount
FROM catalog_sales cs
JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN date_dim d2 ON cs.cs_ship_date_sk = d2.d_date_sk
JOIN store s ON s.s_closed_date_sk = d1.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
JOIN web_sales wsale ON wsale.ws_sold_date_sk = d1.d_date_sk
JOIN web_page wp ON wsale.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (5)) inv ON inv.inv_date_sk = d1.d_date_sk
WHERE cs.cs_bill_customer_sk IN (SELECT cust_sk FROM common_cust)
  AND wsale.ws_bill_customer_sk IN (SELECT cust_sk FROM common_cust)
GROUP BY
  s.s_store_name,
  ws.web_name,
  d1.d_weekend
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
