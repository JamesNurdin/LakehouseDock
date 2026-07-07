WITH store_sales_agg AS (
  SELECT
    i.i_category AS category,
    s.s_store_name AS store_name,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(ss.ss_quantity * i.i_price) AS store_revenue
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  JOIN stores s ON ss.ss_store_id = s.s_store_id
  GROUP BY i.i_category, s.s_store_name
),
web_sales_agg AS (
  SELECT
    i.i_category AS category,
    SUM(ws.ws_quantity) AS web_quantity,
    SUM(ws.ws_quantity * i.i_price) AS web_revenue
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY i.i_category
)
SELECT
  ss.category,
  ss.store_name,
  ss.store_quantity,
  ss.store_revenue,
  COALESCE(ws.web_quantity, 0) AS web_quantity,
  COALESCE(ws.web_revenue, 0) AS web_revenue,
  CASE
    WHEN COALESCE(ws.web_quantity, 0) = 0 THEN NULL
    ELSE (COALESCE(ws.web_quantity, 0) * 1.0) / ss.store_quantity
  END AS web_to_store_quantity_ratio
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
  ON ss.category = ws.category
ORDER BY ss.category, ss.store_name
