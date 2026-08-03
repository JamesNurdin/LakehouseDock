WITH sales_first_shift AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Medium' END AS sales_category
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE td.t_shift = 'first'
     AND td.t_second < 5
   GROUP BY cc.cc_call_center_sk, cc.cc_name
),
sales_zip AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Medium' END AS sales_category
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   WHERE ca.ca_zip LIKE '9%'
   GROUP BY cc.cc_call_center_sk, cc.cc_name
),
combined AS (
   SELECT DISTINCT cc_call_center_sk, cc_name, total_sales, sales_category FROM sales_first_shift
   UNION
   SELECT DISTINCT cc_call_center_sk, cc_name, total_sales, sales_category FROM sales_zip
),
years AS (
   SELECT 2023 AS yr UNION ALL SELECT 2024 AS yr
)
SELECT
   c.cc_name,
   c.total_sales,
   c.sales_category,
   y.yr,
   CASE WHEN c.total_sales > 50000 THEN 'Above 50k' ELSE 'Below 50k' END AS tier
FROM combined c
CROSS JOIN years y
WHERE c.cc_call_center_sk NOT IN (
   SELECT DISTINCT cs_call_center_sk FROM catalog_sales WHERE cs_ext_sales_price > 50000
)
ORDER BY c.total_sales DESC, y.yr
LIMIT 100
