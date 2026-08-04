WITH
  returns_agg AS (
    SELECT
      w.w_warehouse_id,
      w.w_city,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(DISTINCT cr.cr_order_number) AS return_orders,
      cr.cr_warehouse_sk
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY w.w_warehouse_id, w.w_city, cr.cr_warehouse_sk
  ),
  sales_agg AS (
    SELECT
      w.w_warehouse_id,
      w.w_city,
      SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
      ws.ws_warehouse_sk
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY w.w_warehouse_id, w.w_city, ws.ws_warehouse_sk
  ),
  full_warehouses AS (
    SELECT
      COALESCE(r.w_warehouse_id, s.w_warehouse_id) AS warehouse_id,
      COALESCE(r.w_city, s.w_city) AS city,
      r.total_net_loss,
      s.total_net_profit,
      r.return_orders,
      s.sales_orders,
      r.cr_warehouse_sk,
      s.ws_warehouse_sk
    FROM returns_agg r
    FULL OUTER JOIN sales_agg s
      ON r.w_warehouse_id = s.w_warehouse_id
  )
SELECT
  fw.warehouse_id,
  fw.city,
  COALESCE(fw.total_net_loss, 0) - COALESCE(fw.total_net_profit, 0) AS net_diff,
  'warehouse' AS source,
  rc.reason_count
FROM full_warehouses fw
CROSS JOIN LATERAL (
  SELECT COUNT(DISTINCT cr.cr_reason_sk) AS reason_count
  FROM catalog_returns cr
  WHERE cr.cr_warehouse_sk = fw.cr_warehouse_sk
) rc
WHERE NOT EXISTS (
  SELECT 1
  FROM web_sales ws
  WHERE ws.ws_warehouse_sk = fw.ws_warehouse_sk
    AND ws.ws_order_number = fw.sales_orders
)
UNION ALL
SELECT
  NULL AS warehouse_id,
  NULL AS city,
  CAST(od.order_num AS DOUBLE) AS net_diff,
  'order_diff' AS source,
  NULL AS reason_count
FROM (
  SELECT ws.ws_order_number AS order_num
  FROM web_sales ws
  EXCEPT
  SELECT cr.cr_order_number AS order_num
  FROM catalog_returns cr
) od
LIMIT 100
