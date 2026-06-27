WITH
  catalog_sales_agg AS (
    SELECT
      cs.cs_warehouse_sk      AS warehouse_sk,
      w.w_warehouse_name      AS warehouse_name,
      i.i_category            AS category,
      SUM(cs.cs_net_profit)   AS catalog_net_profit,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cs.cs_warehouse_sk, w.w_warehouse_name, i.i_category
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_warehouse_sk      AS warehouse_sk,
      w.w_warehouse_name      AS warehouse_name,
      i.i_category            AS category,
      SUM(ws.ws_net_profit)   AS web_net_profit,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ws.ws_warehouse_sk, w.w_warehouse_name, i.i_category
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_warehouse_sk      AS warehouse_sk,
      w.w_warehouse_name      AS warehouse_name,
      i.i_category            AS category,
      SUM(cr.cr_return_amount)   AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY cr.cr_warehouse_sk, w.w_warehouse_name, i.i_category
  ),
  inventory_agg AS (
    SELECT
      inv.inv_warehouse_sk    AS warehouse_sk,
      w.w_warehouse_name      AS warehouse_name,
      i.i_category            AS category,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand_quantity
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY inv.inv_warehouse_sk, w.w_warehouse_name, i.i_category
  )
SELECT
  COALESCE(cs.warehouse_name, ws.warehouse_name, cr.warehouse_name, inv.warehouse_name) AS warehouse_name,
  COALESCE(cs.category, ws.category, cr.category, inv.category)                     AS category,
  COALESCE(cs.catalog_net_profit, 0)                                                AS catalog_net_profit,
  COALESCE(ws.web_net_profit, 0)                                                   AS web_net_profit,
  COALESCE(cr.total_return_amount, 0)                                             AS total_return_amount,
  COALESCE(inv.total_on_hand_quantity, 0)                                         AS total_on_hand_quantity,
  COALESCE(cs.catalog_orders, 0)                                                   AS catalog_orders,
  COALESCE(ws.web_orders, 0)                                                       AS web_orders
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
  ON cs.warehouse_sk = ws.warehouse_sk AND cs.category = ws.category
FULL OUTER JOIN catalog_returns_agg cr
  ON COALESCE(cs.warehouse_sk, ws.warehouse_sk) = cr.warehouse_sk
 AND COALESCE(cs.category, ws.category) = cr.category
FULL OUTER JOIN inventory_agg inv
  ON COALESCE(cs.warehouse_sk, ws.warehouse_sk, cr.warehouse_sk) = inv.warehouse_sk
 AND COALESCE(cs.category, ws.category, cr.category) = inv.category
ORDER BY warehouse_name, category
