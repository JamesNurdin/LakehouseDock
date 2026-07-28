WITH avg_profit AS (
    SELECT avg(ws_net_profit) AS overall_avg_profit
    FROM web_sales
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE
        WHEN ws.ws_net_profit > (SELECT overall_avg_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    RANK() OVER (PARTITION BY w.w_state ORDER BY ws.ws_net_profit DESC) AS profit_rank_state
FROM web_sales ws
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    ws.ws_ext_ship_cost > 1000
    AND ws.ws_wholesale_cost BETWEEN 5 AND 50
    AND ws.ws_list_price > 150
    AND w.w_state IN ('CA', 'TX', 'NY')
    AND w.w_zip LIKE '4%'
    AND w.w_street_type = 'Avenue'
    AND ws.ws_quantity > 1
    AND EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
          AND w2.w_city = 'Seattle'
    )
ORDER BY profit_rank_state, ws.ws_net_profit DESC
LIMIT 100
