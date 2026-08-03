WITH
  sales_air AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      sm.sm_code,
      sm.sm_carrier,
      cs.cs_ship_mode_sk
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
      AND cs.cs_list_price > 100
  ),
  sales_sea AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      sm.sm_code,
      sm.sm_carrier,
      cs.cs_ship_mode_sk
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'SEA'
      AND cs.cs_list_price > 150
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM sales_air
    INTERSECT
    SELECT cs_order_number FROM sales_sea
  ),
  filtered_sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      sm.sm_code,
      sm.sm_carrier,
      cs.cs_ship_mode_sk
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
          AND cs2.cs_ship_mode_sk <> cs.cs_ship_mode_sk
      )
  ),
  ranked_sales AS (
    SELECT
      cs_order_number,
      cs_ext_sales_price,
      sm_code,
      sm_carrier,
      ROW_NUMBER() OVER (PARTITION BY sm_code ORDER BY cs_ext_sales_price DESC) AS rnk
    FROM filtered_sales
  ),
  top_sales AS (
    SELECT
      cs_order_number,
      cs_ext_sales_price,
      sm_code,
      sm_carrier
    FROM ranked_sales
    WHERE rnk <= 3
  )
SELECT
  sm_code,
  sm_carrier,
  SUM(cs_ext_sales_price) AS total_sales,
  GROUPING(sm_code)   AS g_sm_code,
  GROUPING(sm_carrier) AS g_sm_carrier
FROM top_sales
GROUP BY ROLLUP (sm_code, sm_carrier)
ORDER BY total_sales DESC, sm_code, sm_carrier
OFFSET 0
LIMIT 100
