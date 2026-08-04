WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
qual_warehouses AS (
    SELECT w_warehouse_id
    FROM warehouse
    WHERE w_zip LIKE '7%'
    INTERSECT
    SELECT DISTINCT w.w_warehouse_id
    FROM warehouse w
    JOIN catalog_sales cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
),
agg_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        sm.sm_code,
        td.t_sub_shift,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN sampled_inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_warehouse_sq_ft > 600000
        AND w.w_state = 'TX'
        AND sm.sm_code IN ('AIR', 'SEA')
        AND td.t_sub_shift = 'morning'
        AND td.t_hour BETWEEN 8 AND 12
        AND cs.cs_quantity > 0
        AND cs.cs_net_paid > 0
        AND w.w_warehouse_id IN (SELECT w_warehouse_id FROM qual_warehouses)
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        sm.sm_code,
        td.t_sub_shift
),
final_agg AS (
    SELECT
        profit_category,
        COUNT(*) AS warehouse_group_cnt,
        AVG(total_sales) AS avg_sales,
        SUM(total_profit) AS sum_profit
    FROM agg_sales
    GROUP BY profit_category
    HAVING COUNT(*) >= 2
)
SELECT
    profit_category,
    warehouse_group_cnt,
    avg_sales,
    sum_profit
FROM final_agg
ORDER BY avg_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
