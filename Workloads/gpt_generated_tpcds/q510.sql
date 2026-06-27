WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        sm.sm_carrier,
        t.t_hour,
        site.web_name
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE t.t_hour BETWEEN 9 AND 17
)
SELECT
    s.i_category,
    s.i_brand,
    s.sm_type,
    s.sm_carrier,
    s.t_hour,
    s.web_name,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_net_paid) AS total_net_paid,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.wr_net_loss, 0)) AS total_return_net_loss,
    (SUM(s.ws_net_profit) - SUM(COALESCE(r.wr_net_loss, 0))) AS net_gain_after_returns,
    COUNT(DISTINCT s.ws_order_number) AS distinct_orders
FROM sales s
LEFT JOIN web_returns r
    ON r.wr_order_number = s.ws_order_number
    AND r.wr_item_sk = s.ws_item_sk
GROUP BY
    s.i_category,
    s.i_brand,
    s.sm_type,
    s.sm_carrier,
    s.t_hour,
    s.web_name
ORDER BY net_gain_after_returns DESC
LIMIT 100
