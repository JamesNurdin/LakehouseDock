WITH
  sales_agg AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_ship_mode_sk,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_quantity > 0
    GROUP BY ws.ws_warehouse_sk, ws.ws_ship_mode_sk
  ),

  ship_modes_small AS (
    SELECT sm_ship_mode_sk, sm_type
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'RAIL')
  ),

  cross_sales AS (
    SELECT
      sm.sm_ship_mode_sk,
      sm.sm_type,
      s.ws_warehouse_sk,
      s.total_net_paid,
      CASE WHEN s.total_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM ship_modes_small sm
    CROSS JOIN (
      SELECT ws_warehouse_sk,
             SUM(ws_net_paid) AS total_net_paid,
             SUM(ws_net_profit) AS total_profit
      FROM web_sales
      GROUP BY ws_warehouse_sk
    ) s
  ),

  inventory_warehouses AS (
    SELECT DISTINCT inv.inv_warehouse_sk AS w_warehouse_sk
    FROM inventory inv
  ),

  sales_warehouses AS (
    SELECT DISTINCT ws.ws_warehouse_sk
    FROM web_sales ws
  ),

  no_sales_warehouses AS (
    SELECT w_warehouse_sk
    FROM inventory_warehouses
    EXCEPT
    SELECT ws_warehouse_sk
    FROM sales_warehouses
  )

SELECT
  w.w_warehouse_sk,
  w.w_warehouse_name,
  cs.sm_type AS ship_mode_type,
  cs.total_net_paid,
  cs.profit_flag
FROM cross_sales cs
JOIN warehouse w ON cs.ws_warehouse_sk = w.w_warehouse_sk

UNION

SELECT
  w.w_warehouse_sk,
  w.w_warehouse_name,
  NULL AS ship_mode_type,
  NULL AS total_net_paid,
  'NoSales' AS profit_flag
FROM no_sales_warehouses ns
JOIN warehouse w ON ns.w_warehouse_sk = w.w_warehouse_sk

LIMIT 100
