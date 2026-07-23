WITH distinct_ship_modes AS (
    SELECT DISTINCT sm_ship_mode_sk, sm_ship_mode_id, sm_code, sm_type, sm_contract
    FROM ship_mode
    WHERE sm_contract IS NOT NULL
)
SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_ship_cost,
    sm.sm_ship_mode_id,
    sm.sm_code,
    sm.sm_type,
    CASE 
        WHEN sm.sm_code = 'AIR' THEN 'Air Freight'
        WHEN sm.sm_code = 'SEA' THEN 'Sea Freight'
        WHEN sm.sm_code = 'BIKE' THEN 'Bike Delivery'
        ELSE 'Other'
    END AS shipping_category,
    cr.cr_return_amount,
    CASE 
        WHEN cr.cr_net_loss > 100 THEN 'High Loss'
        WHEN cr.cr_net_loss > 0 THEN 'Medium Loss'
        ELSE 'No Loss'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY sm.sm_code ORDER BY ws.ws_ext_ship_cost DESC) AS cost_rank,
    SUM(ws.ws_ext_ship_cost) OVER (
        PARTITION BY sm.sm_code 
        ORDER BY ws.ws_order_number 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_ship_cost_3
FROM web_sales ws
JOIN distinct_ship_modes sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    ws.ws_ext_ship_cost > 150.00
    AND ws.ws_ext_ship_cost < 2000.00
    AND ws.ws_quantity >= 1
    AND ws.ws_quantity <= 100
    AND ws.ws_net_profit > 0
    AND sm.sm_code IN ('AIR', 'SEA', 'BIKE')
    AND cr.cr_reversed_charge < 500.00
ORDER BY profit_rank ASC, ws.ws_net_profit DESC
LIMIT 100
