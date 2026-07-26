WITH customer_warehouse_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_ship_customer_sk AS cust_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_ship_customer_sk
)
SELECT
    w.w_warehouse_name,
    c.c_first_name,
    c.c_last_name,
    cs.total_profit,
    cs.total_quantity,
    COALESCE(i.inv_quantity_on_hand, 0) AS inventory_on_hand,
    CASE
        WHEN COALESCE(i.inv_quantity_on_hand, 0) < cs.total_quantity * 0.5 THEN 'Low Stock'
        ELSE 'Sufficient Stock'
    END AS stock_status,
    RANK() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cs.total_profit DESC) AS profit_rank
FROM customer_warehouse_sales cs
JOIN warehouse w
    ON cs.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c
    ON cs.cust_sk = c.c_customer_sk
LEFT JOIN (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
) i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
WHERE cs.total_profit > 0
ORDER BY w.w_warehouse_name, profit_rank
