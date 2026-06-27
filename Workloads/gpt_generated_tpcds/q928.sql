WITH sales_by_ship_mode AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_quantity > 0
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier
)
SELECT
    sm_ship_mode_id,
    sm_type,
    sm_carrier,
    total_sales,
    total_profit,
    avg_discount,
    order_count,
    total_sales / SUM(total_sales) OVER () * 100 AS sales_pct,
    SUM(total_sales) OVER (ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_by_ship_mode
ORDER BY total_sales DESC
