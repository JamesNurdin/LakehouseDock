WITH
store_sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
  FROM store s
  RIGHT OUTER JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND ca.ca_country = 'United States'
    AND hd.hd_vehicle_count >= 2
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    SUM(cs.cs_ext_sales_price) AS cat_sales,
    SUM(cs.cs_ext_discount_amt) AS cat_discount
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND hd.hd_dep_count = 0
    AND ca.ca_state = 'CA'
    AND t.t_meal_time = 'Lunch'
    AND cs.cs_quantity > 1
  GROUP BY d.d_year, i.i_item_sk
),
returns_agg AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    SUM(wr.wr_return_amt) AS total_returns
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND r.r_reason_desc LIKE '%Defective%'
    AND wp.wp_type = 'Content'
    AND ca.ca_gmt_offset = -5.00
    AND t.t_hour BETWEEN 0 AND 6
    AND i.i_color = 'Red'
  GROUP BY d.d_year, i.i_item_sk
),
inventory_agg AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    SUM(inv.inv_quantity_on_hand) AS total_on_hand
  FROM inventory inv
  JOIN date_dim d
    ON inv.inv_date_sk = d.d_date_sk
  JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_size = 'M'
    AND inv.inv_warehouse_sk IN (1,3,5)
  GROUP BY d.d_year, i.i_item_sk
),
income_band_agg AS (
  SELECT
    ib.ib_income_band_sk,
    COUNT(*) AS hd_count
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_lower_bound >= 50000
  GROUP BY ib.ib_income_band_sk
),
web_site_agg AS (
  SELECT
    ws.web_site_sk,
    ws.web_city,
    COUNT(DISTINCT ws.web_site_id) AS site_cnt
  FROM web_site ws
  JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
  JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
  WHERE d_open.d_year = 2000
    AND d_close.d_year = 2001
    AND ws.web_suite_number = 'Suite 20'
    AND ws.web_street_type = 'Dr.'
  GROUP BY ws.web_site_sk, ws.web_city
),
stores_with_sales AS (
  SELECT s_store_sk FROM store_sales_agg
),
stores_all AS (
  SELECT s_store_sk FROM store
),
stores_sales_not_all AS (
  SELECT s_store_sk FROM stores_with_sales
  EXCEPT
  SELECT s_store_sk FROM stores_all
),
items_sold AS (
  SELECT i_item_sk FROM catalog_sales_agg
),
items_returned AS (
  SELECT i_item_sk FROM returns_agg
),
items_sold_and_returned AS (
  SELECT i_item_sk FROM items_sold
  INTERSECT
  SELECT i_item_sk FROM items_returned
)
SELECT
  ss.s_store_sk,
  ss.s_store_name,
  ss.d_year,
  ss.total_sales,
  ss.distinct_customers,
  ss.avg_discount,
  (SELECT SUM(cat_sales) FROM catalog_sales_agg WHERE d_year = ss.d_year) AS cat_sales_year,
  (SELECT SUM(total_returns) FROM returns_agg WHERE d_year = ss.d_year) AS total_returns_year,
  (SELECT SUM(total_on_hand) FROM inventory_agg WHERE d_year = ss.d_year) AS total_on_hand_year,
  (SELECT MAX(hd_count) FROM income_band_agg) AS max_hd_count,
  (SELECT COUNT(DISTINCT web_city) FROM web_site_agg) AS web_cities,
  (SELECT COUNT(*) FROM stores_sales_not_all) AS stores_no_inventory,
  (SELECT COUNT(*) FROM items_sold_and_returned) AS common_item_count
FROM store_sales_agg ss
ORDER BY ss.total_sales DESC
OFFSET 10 ROWS
FETCH NEXT 100 ROWS ONLY
