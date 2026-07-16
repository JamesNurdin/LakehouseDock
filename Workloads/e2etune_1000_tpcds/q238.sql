WITH dept_ship_agg AS (
    SELECT
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450906 AND 2451088
      AND cp.cp_type = 'Catalog'
      AND sm.sm_type NOT IN ('UNKNOWN')
    GROUP BY cp.cp_department, sm.sm_type
    HAVING SUM(cs.cs_net_profit) > 500
)
SELECT
    cp_department,
    ship_mode_type,
    total_net_profit,
    avg_sales_price,
    distinct_orders,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM dept_ship_agg
ORDER BY profit_rank
LIMIT 20
