WITH catalog_profit AS (
    SELECT
        ca.ca_state,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_profit / NULLIF(cs.cs_quantity, 0) AS profit_per_unit
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
web_profit AS (
    SELECT
        ca.ca_state,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_profit / NULLIF(ws.ws_quantity, 0) AS profit_per_unit
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
    SELECT ca_state, quantity, net_profit, profit_per_unit, 'catalog' AS channel FROM catalog_profit
    UNION ALL
    SELECT ca_state, quantity, net_profit, profit_per_unit, 'web' AS channel FROM web_profit
),
agg AS (
    SELECT
        ca_state,
        channel,
        AVG(profit_per_unit) AS avg_profit_per_unit,
        SUM(profit_per_unit) AS total_profit_per_unit
    FROM combined
    GROUP BY ca_state, channel
)
SELECT
    ca_state,
    channel,
    avg_profit_per_unit,
    DENSE_RANK() OVER (PARTITION BY channel ORDER BY avg_profit_per_unit DESC) AS profit_rank,
    CASE
        WHEN avg_profit_per_unit >= 100 THEN 'Very High'
        WHEN avg_profit_per_unit >= 50 THEN 'High'
        WHEN avg_profit_per_unit >= 20 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM agg
ORDER BY channel, profit_rank
LIMIT 50
