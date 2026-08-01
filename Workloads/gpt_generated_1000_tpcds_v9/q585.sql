WITH page_sales AS (
    SELECT
        cp.cp_department,
        sm_l.sm_code,
        cp.cp_catalog_page_number,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN LATERAL (
        SELECT sm.sm_code, sm.sm_contract
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    ) sm_l
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cp.cp_catalog_page_number IN (6, 13, 17)
      AND sm_l.sm_code = 'AIR'
      AND cs.cs_coupon_amt > 100.00
    GROUP BY
        cp.cp_department,
        sm_l.sm_code,
        cp.cp_catalog_page_number
),
avg_profit AS (
    SELECT
        cp_department,
        sm_code,
        AVG(total_profit) AS avg_total_profit,
        SUM(total_quantity) AS sum_quantity,
        COUNT(*) AS num_pages
    FROM page_sales
    GROUP BY cp_department, sm_code
    HAVING SUM(total_quantity) > 500
)
SELECT DISTINCT
    cp_department AS department,
    sm_code AS ship_mode,
    avg_total_profit,
    sum_quantity,
    num_pages
FROM avg_profit
ORDER BY avg_total_profit DESC
LIMIT 100
