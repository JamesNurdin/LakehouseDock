WITH
  sampled_catalog_sales AS (
    SELECT cs_order_number, cs_ship_customer_sk
    FROM catalog_sales TABLESAMPLE BERNOULLI (5)
    WHERE regexp_like(CAST(cs_ship_customer_sk AS varchar), '^1[0-9]{6}$')
  ),
  sampled_web_sales AS (
    SELECT ws_order_number, ws_ship_customer_sk
    FROM web_sales TABLESAMPLE BERNOULLI (5)
    WHERE CAST(ws_ship_customer_sk AS varchar) LIKE '8%'
  ),
  intersect_orders AS (
    SELECT cs_order_number AS order_number
    FROM sampled_catalog_sales
    INTERSECT
    SELECT ws_order_number
    FROM sampled_web_sales
  ),
  union_sales AS (
    SELECT
      cs.cs_order_number AS order_number,
      cs.cs_sales_price AS revenue,
      CASE WHEN cs.cs_ship_mode_sk IS NULL THEN 'UNKNOWN' ELSE CAST(cs.cs_ship_mode_sk AS varchar) END AS ship_mode,
      'catalog' AS source,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sales_price > 100
    UNION
    SELECT
      ws.ws_order_number,
      ws.ws_sales_price,
      CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 'UNKNOWN' ELSE CAST(ws.ws_ship_mode_sk AS varchar) END,
      'web',
      CONCAT(c.c_first_name, ' ', c.c_last_name)
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sales_price > 100
  )
SELECT
  i.order_number,
  COUNT(DISTINCT u.source) AS distinct_sources,
  COUNT(DISTINCT u.ship_mode) AS distinct_ship_modes,
  SUM(DISTINCT u.revenue) AS sum_distinct_revenue,
  MAX(CASE WHEN u.ship_mode = 'UNKNOWN' THEN u.revenue ELSE 0 END) AS max_unknown_ship_rev,
  MAX(u.customer_name) AS example_customer_name
FROM intersect_orders i
JOIN union_sales u ON i.order_number = u.order_number
GROUP BY i.order_number
ORDER BY sum_distinct_revenue DESC
LIMIT 100
