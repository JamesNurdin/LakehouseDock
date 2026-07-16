WITH catalog_ship AS (
    SELECT
        ca.ca_state AS ship_state,
        cs.cs_ext_ship_cost AS ship_cost,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
),
web_ship AS (
    SELECT
        ca.ca_state AS ship_state,
        ws.ws_ext_ship_cost AS ship_cost,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
    SELECT ship_state, ship_cost, net_profit FROM catalog_ship
    UNION ALL
    SELECT ship_state, ship_cost, net_profit FROM web_ship
),
state_agg AS (
    SELECT
        ship_state,
        SUM(ship_cost) AS total_ship_cost,
        SUM(net_profit) AS total_net_profit
    FROM combined
    GROUP BY ship_state
)
SELECT
    RANK() OVER (ORDER BY ship_cost_per_profit DESC) AS shipping_ratio_rank,
    ship_state,
    total_ship_cost,
    total_net_profit,
    ship_cost_per_profit,
    CASE
        WHEN total_ship_cost > 50000 THEN 'Expensive'
        WHEN total_ship_cost > 20000 THEN 'Moderate'
        ELSE 'Cheap'
    END AS shipping_category
FROM (
    SELECT
        ship_state,
        total_ship_cost,
        total_net_profit,
        CAST(total_ship_cost AS DOUBLE) / NULLIF(total_net_profit, 0) AS ship_cost_per_profit
    FROM state_agg
) s
ORDER BY shipping_ratio_rank
LIMIT 10
