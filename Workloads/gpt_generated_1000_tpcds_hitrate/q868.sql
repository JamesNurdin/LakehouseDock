WITH base1 AS (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
    (
      SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    ) AS total_warehouse_sales,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_profit DESC) AS rn
  FROM catalog_sales cs
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_list_price > 150
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_sales cs3
      WHERE cs3.cs_warehouse_sk = cs.cs_warehouse_sk
        AND cs3.cs_net_profit > 2000
    )
),
base2 AS (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
    (
      SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    ) AS total_warehouse_sales,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_profit DESC) AS rn
  FROM catalog_sales cs
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ext_ship_cost < 100
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_sales cs3
      WHERE cs3.cs_warehouse_sk = cs.cs_warehouse_sk
        AND cs3.cs_net_profit > 2000
    )
)
SELECT *
FROM (
  SELECT * FROM base1
  UNION ALL
  SELECT * FROM base2
) u
WHERE u.rn <= 5
ORDER BY u.w_warehouse_name ASC, u.cs_net_profit DESC
LIMIT 100
