WITH sales_returns AS (
    SELECT
        cs.cs_item_sk,
        sm.sm_ship_mode_id,
        sm.sm_code,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cs.cs_quantity > 30
    GROUP BY cs.cs_item_sk, sm.sm_ship_mode_id, sm.sm_code
)
SELECT
    sm_code,
    AVG(total_net_profit) AS avg_net_profit_per_item,
    SUM(total_return_amount) AS total_return_amount_all_items,
    COUNT(*) AS item_count
FROM sales_returns
WHERE sm_code IN ('AIR', 'SEA')
GROUP BY sm_code
HAVING AVG(total_net_profit) > 1000
