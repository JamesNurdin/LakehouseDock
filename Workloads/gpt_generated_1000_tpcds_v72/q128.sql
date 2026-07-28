WITH high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
)
SELECT
    i2.i_category AS category,
    td1.t_hour AS hour_of_day,
    SUM(ws.ws_net_paid) AS online_sales,
    SUM(ss.ss_net_paid) AS store_sales,
    CASE
        WHEN SUM(ws.ws_net_profit) > SUM(ss.ss_net_profit) THEN 'Online'
        ELSE 'Store'
    END AS higher_profit_channel,
    COUNT(DISTINCT ws.ws_order_number) AS online_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
FROM store_sales ss
JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
JOIN time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td1.t_time_sk
JOIN time_dim td3 ON ws.ws_sold_time_sk = td3.t_time_sk
JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM high_price_items h WHERE h.i_item_sk = i2.i_item_sk
)
GROUP BY i2.i_category, td1.t_hour
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY online_sales DESC
LIMIT 100
