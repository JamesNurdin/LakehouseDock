WITH catalog_sales_agg AS (
   SELECT
       d.d_year AS year,
       SUM(cs.cs_net_paid) AS total_sales,
       CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM tpcds.catalog_sales cs
   JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
     AND NOT EXISTS (
         SELECT 1 FROM tpcds.catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
     )
   GROUP BY d.d_year
),
web_sales_agg AS (
   SELECT
       d.d_year AS year,
       SUM(ws.ws_net_paid) AS total_sales,
       CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
     AND NOT EXISTS (
         SELECT 1 FROM tpcds.web_returns wr
         WHERE wr.wr_order_number = ws.ws_order_number
     )
   GROUP BY d.d_year
)
SELECT *
FROM (
   SELECT year, total_sales, sales_category FROM catalog_sales_agg
   UNION ALL
   SELECT year, total_sales, sales_category FROM web_sales_agg
) AS combined
ORDER BY year, total_sales DESC
LIMIT 100
