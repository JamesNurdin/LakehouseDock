WITH catalog_agg AS (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    CAST(NULL AS integer) AS web_site_sk,
    'catalog' AS sales_channel,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ext_list_price > 1000
    AND NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_quantity_on_hand > 0
    )
  GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
),
web_agg AS (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    ws.ws_web_site_sk AS web_site_sk,
    'web' AS sales_channel,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  WHERE ws.ws_ext_list_price > 1000
    AND NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_quantity_on_hand > 0
    )
  GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name, ws.ws_web_site_sk
),
combined AS (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
)
SELECT
  w_warehouse_id,
  w_warehouse_name,
  web_site_sk,
  sales_channel,
  total_net_profit,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_net_profit DESC) AS channel_rank
FROM combined
ORDER BY total_net_profit DESC
OFFSET 0 LIMIT 100
