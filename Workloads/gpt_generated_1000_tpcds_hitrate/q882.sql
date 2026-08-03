WITH sales_a AS (
  SELECT cs.cs_warehouse_sk,
         cs.cs_ship_mode_sk,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cp.cp_catalog_number IN (3, 5, 7)
    AND cs.cs_sales_price > 50
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp2.cp_department = 'Books'
    )
  GROUP BY cs.cs_warehouse_sk, cs.cs_ship_mode_sk
),

sales_b AS (
  SELECT cs.cs_warehouse_sk,
         cs.cs_ship_mode_sk,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_sales_price BETWEEN 30 AND 80
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp.cp_department = 'Electronics'
    )
  GROUP BY cs.cs_warehouse_sk, cs.cs_ship_mode_sk
),

intersect_keys AS (
  SELECT cs_warehouse_sk FROM sales_a
  INTERSECT
  SELECT cs_warehouse_sk FROM sales_b
),

final_union AS (
  SELECT 
    w.w_warehouse_name AS warehouse_name,
    sm.sm_ship_mode_id AS ship_mode_id,
    sa.total_sales,
    CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (SELECT AVG(cs_inner.cs_ext_sales_price)
     FROM catalog_sales cs_inner
     WHERE cs_inner.cs_warehouse_sk = w.w_warehouse_sk) AS avg_price_warehouse
  FROM sales_a sa
  JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sa.cs_warehouse_sk IN (SELECT cs_warehouse_sk FROM intersect_keys)

  UNION

  SELECT 
    w.w_warehouse_name AS warehouse_name,
    sm.sm_ship_mode_id AS ship_mode_id,
    sb.total_sales,
    CASE WHEN sb.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (SELECT AVG(cs_inner.cs_ext_sales_price)
     FROM catalog_sales cs_inner
     WHERE cs_inner.cs_warehouse_sk = w.w_warehouse_sk) AS avg_price_warehouse
  FROM sales_b sb
  JOIN warehouse w ON sb.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sb.cs_warehouse_sk IN (SELECT cs_warehouse_sk FROM intersect_keys)
)

SELECT DISTINCT
  warehouse_name,
  ship_mode_id,
  total_sales,
  profit_flag,
  avg_price_warehouse
FROM final_union
ORDER BY total_sales DESC
LIMIT 100
