WITH catalog_data AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    'Catalog' AS sales_channel,
    SUM(cs.cs_net_paid) AS total_net_paid
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND sm.sm_code = 'AIR'
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_item_sk = cs.cs_item_sk
    )
  GROUP BY i.i_item_id, i.i_product_name
),
web_data AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    'Web' AS sales_channel,
    SUM(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND sm.sm_code = 'AIR'
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_item_sk = ws.ws_item_sk
    )
  GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM catalog_data
UNION ALL
SELECT *
FROM web_data
ORDER BY total_net_paid DESC
LIMIT 100
