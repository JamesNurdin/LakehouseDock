WITH profit_by_warehouse_category AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_name, i.i_category
)
SELECT
    w_warehouse_name,
    i_category,
    total_profit,
    total_sales,
    avg_discount,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_profit DESC) AS category_profit_rank
FROM profit_by_warehouse_category
ORDER BY w_warehouse_name, category_profit_rank
LIMIT 20
