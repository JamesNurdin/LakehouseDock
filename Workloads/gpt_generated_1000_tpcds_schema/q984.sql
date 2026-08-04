WITH
sales_by_store AS (
   SELECT
       'store' AS source_type,
       s.s_store_id AS id,
       d.d_year AS year,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY s.s_store_id, d.d_year
),
sales_by_web AS (
   SELECT
       'web' AS source_type,
       w.web_site_id AS id,
       d.d_year AS year,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_net_profit,
       CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag
   FROM web_sales ws
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY w.web_site_id, d.d_year
),
union_sales AS (
   SELECT * FROM sales_by_store
   UNION
   SELECT * FROM sales_by_web
),
inventory_by_date AS (
   SELECT
       d.d_year AS year,
       COALESCE(i.inv_quantity_on_hand, 0) AS quantity_on_hand,
       CASE WHEN i.inv_quantity_on_hand IS NULL THEN 'No Inventory' ELSE 'Has Inventory' END AS inventory_status
   FROM date_dim d
   FULL OUTER JOIN (
       SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
   ) i ON d.d_date_sk = i.inv_date_sk
   WHERE d.d_year = 2001
)
SELECT
    u.source_type,
    u.id,
    u.year,
    u.total_net_paid,
    u.total_net_profit,
    u.profit_flag,
    i.quantity_on_hand,
    i.inventory_status
FROM union_sales u
LEFT JOIN inventory_by_date i ON u.year = i.year
ORDER BY u.total_net_paid DESC, u.source_type
LIMIT 100
