WITH sales_air AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND d.d_year = 2020
      AND NOT EXISTS (
            SELECT 1 FROM inventory i
            WHERE i.inv_date_sk = cs.cs_sold_date_sk
              AND i.inv_warehouse_sk = cs.cs_warehouse_sk
          )
      AND cs.cs_warehouse_sk IN (
            SELECT inv_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 0
          )
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year
),
ranked_air AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS rk
    FROM sales_air
),
sales_rail AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'RAIL'
      AND d.d_year = 2021
      AND NOT EXISTS (
            SELECT 1 FROM inventory i
            WHERE i.inv_date_sk = cs.cs_sold_date_sk
              AND i.inv_warehouse_sk = cs.cs_warehouse_sk
          )
      AND cs.cs_warehouse_sk IN (
            SELECT inv_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 0
          )
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year
),
ranked_rail AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS rk
    FROM sales_rail
)
SELECT w_warehouse_id,
       w_warehouse_name,
       d_year,
       total_sales,
       total_profit,
       profit_flag
FROM ranked_air
WHERE rk <= 5
UNION ALL
SELECT w_warehouse_id,
       w_warehouse_name,
       d_year,
       total_sales,
       total_profit,
       profit_flag
FROM ranked_rail
WHERE rk <= 5
ORDER BY total_profit DESC
LIMIT 100
