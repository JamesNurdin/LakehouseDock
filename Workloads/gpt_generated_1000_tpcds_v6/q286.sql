WITH catalog_agg AS (
  SELECT
    i.i_item_id,
    w.w_warehouse_name,
    SUM(cs.cs_quantity) AS total_qty,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_category_id = 3
    AND i.i_formulation LIKE '%ivory%'
    AND w.w_city = 'Washington 7th'
    AND cs.cs_ship_date_sk BETWEEN 2450830 AND 2450914
    AND cs.cs_quantity > 0
  GROUP BY i.i_item_id, w.w_warehouse_name
),
web_agg AS (
  SELECT
    i.i_item_id,
    w.w_warehouse_name,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_category_id = 3
    AND i.i_formulation LIKE '%ivory%'
    AND w.w_city = 'Washington 7th'
    AND ws.ws_sold_date_sk BETWEEN 2450830 AND 2450914
    AND ws.ws_quantity > 0
  GROUP BY i.i_item_id, w.w_warehouse_name
),
combined AS (
  SELECT i_item_id,
         w_warehouse_name,
         total_qty,
         total_sales,
         orders_cnt,
         'catalog' AS sales_channel
  FROM catalog_agg
  UNION ALL
  SELECT i_item_id,
         w_warehouse_name,
         total_qty,
         total_sales,
         orders_cnt,
         'web' AS sales_channel
  FROM web_agg
)
SELECT
  i_item_id,
  w_warehouse_name,
  SUM(total_qty) AS agg_qty,
  SUM(total_sales) AS agg_sales,
  SUM(orders_cnt) AS agg_orders,
  COUNT(DISTINCT sales_channel) AS channels_present
FROM combined
GROUP BY i_item_id, w_warehouse_name
HAVING SUM(total_sales) > 10000
ORDER BY agg_sales DESC
LIMIT 100
