WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        sm.sm_ship_mode_id AS sm_ship_mode_id,
        sm.sm_type AS sm_type,
        sm.sm_contract AS sm_contract
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IN ('EXPRESS', 'REGULAR')
      AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
      AND ws.ws_coupon_amt > 500
      AND ws.ws_quantity >= 2
),
aggregated_sales AS (
    SELECT
        sm_ship_mode_id,
        sm_type,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_coupon_amt) AS avg_coupon
    FROM filtered_sales
    GROUP BY sm_ship_mode_id, sm_type
)
SELECT
    sm_ship_mode_id,
    sm_type,
    distinct_orders,
    total_sales,
    total_profit,
    avg_coupon,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    CASE 
        WHEN total_sales > 100000 THEN 'HIGH'
        WHEN total_sales > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category
FROM aggregated_sales
ORDER BY profit_rank
LIMIT 100
