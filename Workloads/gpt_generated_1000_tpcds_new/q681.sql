WITH avg_store_sales AS (
   SELECT avg(ss_ext_sales_price) AS avg_price
   FROM store_sales
   WHERE ss_sold_date_sk BETWEEN 2450000 AND 2455000
),
avg_web_sales AS (
   SELECT avg(ws_ext_sales_price) AS avg_price
   FROM web_sales
   WHERE ws_sold_date_sk BETWEEN 2450000 AND 2455000
)

SELECT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   ss.ss_ext_sales_price AS sales_amount,
   CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
   LAG(ss.ss_ext_sales_price) OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_sold_date_sk) AS prior_sales
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_ext_sales_price > (SELECT avg_price FROM avg_store_sales)

UNION

SELECT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   ws.ws_ext_sales_price AS sales_amount,
   CASE WHEN sm.sm_contract = 'P7FBIt8yd' THEN 'Special' ELSE 'Regular' END AS cust_type,
   LAG(ws.ws_ext_sales_price) OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sold_date_sk) AS prior_sales
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_ext_sales_price > (SELECT avg_price FROM avg_web_sales)
