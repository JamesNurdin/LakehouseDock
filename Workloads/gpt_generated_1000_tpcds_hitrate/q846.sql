WITH recent_inventory AS (
  SELECT
    d.d_year,
    w.w_warehouse_name,
    i.i_category,
    SUM(inv.inv_quantity_on_hand) AS total_qty,
    CASE WHEN SUM(inv.inv_quantity_on_hand) > 0 THEN 'In Stock' ELSE 'Out of Stock' END AS stock_status
  FROM date_dim d
  RIGHT OUTER JOIN (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
  ) inv ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN item i ON inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, w.w_warehouse_name, i.i_category
),
web_stats AS (
  SELECT
    d.d_year,
    ws.web_city,
    ws.web_state,
    SUM(wp.wp_link_count) AS total_links,
    CASE WHEN SUM(wp.wp_link_count) > 50 THEN 'High' ELSE 'Low' END AS link_intensity
  FROM web_page wp
  JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE wp.wp_autogen_flag = 'N'
    AND d.d_year = 2001
  GROUP BY d.d_year, ws.web_city, ws.web_state
)
SELECT
  ri.d_year,
  ri.w_warehouse_name AS attribute1,
  ri.i_category AS attribute2,
  CAST(ri.total_qty AS BIGINT) AS metric,
  ri.stock_status AS status
FROM recent_inventory ri
UNION ALL
SELECT
  ws.d_year,
  ws.web_city AS attribute1,
  ws.web_state AS attribute2,
  CAST(ws.total_links AS BIGINT) AS metric,
  ws.link_intensity AS status
FROM web_stats ws
ORDER BY d_year DESC, metric DESC
LIMIT 100
