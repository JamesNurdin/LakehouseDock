WITH daily_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS daily_net_paid,
        SUM(ws.ws_net_profit) AS daily_profit
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk
),
 daily_inventory AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS daily_stock
    FROM inventory i
    GROUP BY i.inv_warehouse_sk, i.inv_date_sk
),
 shipping_counts AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        ws.ws_ship_customer_sk,
        COUNT(*) AS ship_cnt
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk, ws.ws_ship_customer_sk
),
 shipping_customers AS (
    SELECT
        sc.ws_warehouse_sk,
        sc.ws_sold_date_sk,
        sc.ws_ship_customer_sk,
        sc.ship_cnt,
        ROW_NUMBER() OVER (PARTITION BY sc.ws_warehouse_sk, sc.ws_sold_date_sk ORDER BY sc.ship_cnt DESC) AS rn
    FROM shipping_counts sc
),
 top_ship_customer AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_ship_customer_sk
    FROM shipping_customers
    WHERE rn = 1
)
SELECT
    w.w_warehouse_name,
    ds.ws_sold_date_sk AS date_sk,
    ds.daily_net_paid,
    ds.daily_profit,
    di.daily_stock,
    LAG(di.daily_stock) OVER (PARTITION BY w.w_warehouse_sk ORDER BY ds.ws_sold_date_sk) AS prev_stock,
    LEAD(di.daily_stock) OVER (PARTITION BY w.w_warehouse_sk ORDER BY ds.ws_sold_date_sk) AS next_stock,
    c.c_first_name || ' ' || c.c_last_name AS top_ship_customer_name,
    CASE
        WHEN di.daily_stock < COALESCE(LAG(di.daily_stock) OVER (PARTITION BY w.w_warehouse_sk ORDER BY ds.ws_sold_date_sk), 0) THEN 'Decreasing Stock'
        WHEN di.daily_stock > COALESCE(LAG(di.daily_stock) OVER (PARTITION BY w.w_warehouse_sk ORDER BY ds.ws_sold_date_sk), 0) THEN 'Increasing Stock'
        ELSE 'Stable Stock'
    END AS stock_trend,
    CASE
        WHEN ds.daily_profit > 0 AND di.daily_stock > 0 THEN 'Profitable & Stocked'
        WHEN ds.daily_profit > 0 AND di.daily_stock = 0 THEN 'Profitable but Out of Stock'
        ELSE 'Loss or No Stock'
    END AS profit_stock_status
FROM daily_sales ds
JOIN daily_inventory di
    ON ds.ws_warehouse_sk = di.inv_warehouse_sk
    AND ds.ws_sold_date_sk = di.inv_date_sk
JOIN warehouse w
    ON ds.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN top_ship_customer tsc
    ON ds.ws_warehouse_sk = tsc.ws_warehouse_sk
    AND ds.ws_sold_date_sk = tsc.ws_sold_date_sk
LEFT JOIN customer c
    ON tsc.ws_ship_customer_sk = c.c_customer_sk
ORDER BY w.w_warehouse_name, ds.ws_sold_date_sk
