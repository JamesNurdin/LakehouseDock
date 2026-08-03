/*
Goal: Compare the top ship‑mode types per year between catalog_sales and web_sales, showing total sales, profit, discounts and an expanded metric (quantity vs. sales price). The query demonstrates:
- UNION ALL of two sub‑queries
- Explicit joins using the allowed keys
- CASE WHEN aggregation
- UNNEST of an array column
- An uncorrelated scalar sub‑query in a HAVING clause
- A correlated scalar sub‑query per row
- A ranking window function filtered to the top‑10 per year
- LIMIT 100
*/
WITH
-- Catalog sales base with array of two metrics and a correlated scalar sub‑query per row
cs_base AS (
  SELECT
    d.d_year AS year,
    sm.sm_type AS mode_type,
    cs.cs_ext_sales_price AS sales_price,
    cs.cs_net_profit AS profit,
    cs.cs_ext_discount_amt AS discount,
    ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS metrics,
    cs.cs_sold_date_sk,
    (SELECT MAX(cs2.cs_ext_discount_amt)
       FROM catalog_sales cs2
      WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk) AS day_max_discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
),
-- Aggregate catalog data, expand the array, and apply CASE WHEN logic
cs_agg AS (
  SELECT
    year,
    mode_type,
    SUM(sales_price) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(CASE WHEN mode_type = 'OVERNIGHT' THEN profit ELSE 0 END) AS overnight_profit,
    MAX(discount) AS max_discount,
    MAX(day_max_discount) AS max_discount_for_day,
    metric_val
  FROM cs_base
  CROSS JOIN UNNEST(metrics) WITH ORDINALITY AS u(metric_val, pos)
  GROUP BY
    year,
    mode_type,
    metric_val
  HAVING SUM(sales_price) > (SELECT AVG(cs3.cs_ext_sales_price) FROM catalog_sales cs3)
),
-- Rank catalog rows per year and keep top 10
cs_ranked AS (
  SELECT
    year,
    mode_type,
    total_sales,
    total_profit,
    overnight_profit,
    max_discount,
    max_discount_for_day,
    metric_val,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rnk
  FROM cs_agg
),
-- Web sales base with similar structure
ws_base AS (
  SELECT
    d.d_year AS year,
    sm.sm_type AS mode_type,
    ws.ws_ext_sales_price AS sales_price,
    ws.ws_net_profit AS profit,
    ws.ws_ext_discount_amt AS discount,
    ARRAY[ws.ws_quantity, ws.ws_ext_sales_price] AS metrics,
    ws.ws_sold_date_sk,
    (SELECT MAX(ws2.ws_ext_discount_amt)
       FROM web_sales ws2
      WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk) AS day_max_discount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
),
-- Aggregate web data with the same pattern
ws_agg AS (
  SELECT
    year,
    mode_type,
    SUM(sales_price) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(CASE WHEN mode_type = 'OVERNIGHT' THEN profit ELSE 0 END) AS overnight_profit,
    MAX(discount) AS max_discount,
    MAX(day_max_discount) AS max_discount_for_day,
    metric_val
  FROM ws_base
  CROSS JOIN UNNEST(metrics) WITH ORDINALITY AS u(metric_val, pos)
  GROUP BY
    year,
    mode_type,
    metric_val
  HAVING SUM(sales_price) > (SELECT AVG(ws3.ws_ext_sales_price) FROM web_sales ws3)
),
-- Rank web rows per year and keep top 10
ws_ranked AS (
  SELECT
    year,
    mode_type,
    total_sales,
    total_profit,
    overnight_profit,
    max_discount,
    max_discount_for_day,
    metric_val,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rnk
  FROM ws_agg
),
-- Combine the two ranked result sets
combined AS (
  SELECT
    year,
    mode_type,
    total_sales,
    total_profit,
    overnight_profit,
    max_discount,
    max_discount_for_day,
    metric_val,
    'catalog' AS source,
    rnk
  FROM cs_ranked
  WHERE rnk <= 10

  UNION ALL

  SELECT
    year,
    mode_type,
    total_sales,
    total_profit,
    overnight_profit,
    max_discount,
    max_discount_for_day,
    metric_val,
    'web' AS source,
    rnk
  FROM ws_ranked
  WHERE rnk <= 10
)
SELECT
  year,
  mode_type,
  total_sales,
  total_profit,
  overnight_profit,
  max_discount,
  max_discount_for_day,
  metric_val,
  source
FROM combined
ORDER BY year DESC, total_sales DESC
LIMIT 100
