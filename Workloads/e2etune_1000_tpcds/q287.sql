WITH sales_agg AS (
    SELECT
        sm.sm_type,
        w.w_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450975
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND w.w_country = 'USA'
    GROUP BY sm.sm_type, w.w_city
)
SELECT
    sm_type,
    w_city,
    total_sales,
    total_profit,
    avg_discount,
    total_quantity,
    order_count,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 10
