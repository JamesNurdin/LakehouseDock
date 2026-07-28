WITH joined_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        sm.sm_code,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        w.w_gmt_offset
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity BETWEEN 1 AND 5                           -- predicate 1
      AND cs.cs_net_profit > 10.00                                 -- predicate 2
      AND hd.hd_dep_count >= 3                                     -- predicate 3
      AND hd.hd_vehicle_count <> -1                                -- predicate 4
      AND sm.sm_code IN ('SEA', 'AIR')                              -- predicate 5
      AND w.w_warehouse_sq_ft > 300000                             -- predicate 6
      AND w.w_gmt_offset = -6.00                                   -- predicate 7
),
agg_sales AS (
    SELECT
        w_warehouse_name,
        sm_code,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_rows
    FROM joined_sales
    GROUP BY w_warehouse_name, sm_code
),
ranked_sales AS (
    SELECT
        w_warehouse_name,
        sm_code,
        total_quantity,
        total_net_profit,
        sales_rows,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_profit DESC) AS rn_profit,
        RANK() OVER (ORDER BY total_net_profit DESC) AS overall_rank
    FROM agg_sales
)
SELECT
    w_warehouse_name,
    sm_code,
    total_quantity,
    total_net_profit,
    sales_rows,
    rn_profit,
    overall_rank
FROM ranked_sales
WHERE rn_profit <= 3
ORDER BY w_warehouse_name, rn_profit
