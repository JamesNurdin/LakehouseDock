WITH sales_data AS (
   SELECT
       d.d_year,
       'CATALOG' AS channel,
       p.p_promo_id,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
       CASE WHEN SUM(cs.cs_net_paid) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, p.p_promo_id)
),
web_sales_data AS (
   SELECT
       d.d_year,
       'WEB' AS channel,
       p.p_promo_id,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
       CASE WHEN SUM(ws.ws_net_paid) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY ROLLUP (d.d_year, p.p_promo_id)
)
SELECT DISTINCT
   sd.d_year,
   sd.channel,
   sd.p_promo_id,
   sd.total_net_paid,
   sd.distinct_items,
   sd.sales_level
FROM sales_data sd
WHERE sd.d_year IS NOT NULL
UNION ALL
SELECT DISTINCT
   wd.d_year,
   wd.channel,
   wd.p_promo_id,
   wd.total_net_paid,
   wd.distinct_items,
   wd.sales_level
FROM web_sales_data wd
WHERE wd.d_year IS NOT NULL
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
