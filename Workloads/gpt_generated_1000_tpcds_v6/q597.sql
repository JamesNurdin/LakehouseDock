WITH catalog_data AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       sm.sm_type AS ship_type,
       cd.cd_gender AS gender,
       cs.cs_ext_sales_price AS sales,
       cs.cs_ext_discount_amt AS discount,
       cs.cs_order_number AS order_num,
       sr.sr_return_quantity AS return_qty
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND sm.sm_carrier = 'UPS'
     AND cp.cp_type = 'PROMO'
     AND cd.cd_gender = 'M'
     AND t.t_hour BETWEEN 9 AND 17
),
web_data AS (
   SELECT
       d.d_year AS year,
       i.i_category AS category,
       sm.sm_type AS ship_type,
       cd.cd_gender AS gender,
       ws.ws_ext_sales_price AS sales,
       ws.ws_ext_discount_amt AS discount,
       ws.ws_order_number AS order_num,
       sr.sr_return_quantity AS return_qty
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#19'
     AND sm.sm_carrier = 'FedEx'
     AND wp.wp_type = 'CONTENT'
     AND cd.cd_gender = 'F'
     AND t.t_hour BETWEEN 10 AND 18
),
combined AS (
   SELECT * FROM catalog_data
   UNION ALL
   SELECT * FROM web_data
)
SELECT
   year,
   category,
   ship_type,
   gender,
   SUM(sales) AS total_sales,
   SUM(return_qty) AS total_returns,
   COUNT(DISTINCT order_num) AS order_cnt,
   AVG(discount) AS avg_discount
FROM combined
GROUP BY GROUPING SETS (
   (year, category, ship_type, gender),
   (year, category, ship_type),
   (year, category),
   (year),
   ()
)
ORDER BY total_sales DESC
LIMIT 100
