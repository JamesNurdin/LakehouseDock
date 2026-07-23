WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sold_year,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE
        d_sold.d_current_month = 'Y'
        AND ws.ws_ship_mode_sk IN (15, 18, 9)
        AND ws.ws_ext_wholesale_cost > 2000
    GROUP BY d_sold.d_year, ws.ws_item_sk
)
SELECT
    sold_year,
    ws_item_sk,
    total_net_profit,
    sales_cnt,
    avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC) AS profit_rank,
    AVG(total_net_profit) OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS profit_moving_avg,
    CASE
        WHEN total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM sales_agg
WHERE ws_item_sk IN (
    SELECT DISTINCT ws_item_sk
    FROM web_sales
    WHERE ws_ship_addr_sk = 4068627
)
ORDER BY sold_year DESC, profit_rank
LIMIT 100
