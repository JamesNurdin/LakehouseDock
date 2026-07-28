WITH filtered_sales AS (
    SELECT
        w.w_city AS city,
        w.w_state AS state,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM warehouse w
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
           AND ws.ws_ship_mode_sk IN (1, 8, 19)
           AND ws.ws_wholesale_cost > 20
    WHERE w.w_country = 'United States'
      AND w.w_city IN ('Pleasant Hill', 'Riverside')
)
SELECT
    COALESCE(city, 'ALL') AS city,
    COALESCE(state, 'ALL') AS state,
    total_quantity,
    total_sales,
    total_profit,
    RANK() OVER (PARTITION BY COALESCE(city, 'ALL') ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        city,
        state,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM filtered_sales
    GROUP BY GROUPING SETS (
        (city, state),
        (city),
        ()
    )
) agg
ORDER BY city, state, profit_rank
LIMIT 100
