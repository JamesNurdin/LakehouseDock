WITH agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_catalog_number BETWEEN 5 AND 20
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cs.cs_ext_list_price > 1000
      AND cs.cs_coupon_amt < 1500
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_ship_mode_sk
)
SELECT
    agg.cp_catalog_page_sk,
    agg.cp_department,
    agg.cp_catalog_number,
    agg.sm_ship_mode_id,
    agg.sm_code,
    agg.total_sales,
    agg.avg_net_profit,
    agg.order_cnt,
    RANK() OVER (PARTITION BY agg.cp_department ORDER BY agg.total_sales DESC) AS dept_sales_rank,
    CASE
        WHEN agg.avg_net_profit > (
            SELECT AVG(cs_sub.cs_net_profit)
            FROM catalog_sales cs_sub
            WHERE cs_sub.cs_ship_mode_sk = agg.sm_ship_mode_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_mode_avg
FROM agg
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_check
    WHERE cs_check.cs_catalog_page_sk = agg.cp_catalog_page_sk
      AND cs_check.cs_quantity > 10
)
ORDER BY agg.cp_department, dept_sales_rank
LIMIT 100
