WITH filtered_sales AS (
    SELECT
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        i.i_product_name,
        w.web_name,
        w.web_site_id,
        sm.sm_code,
        td.t_am_pm
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE i.i_product_name LIKE '%Bike%'
      AND REGEXP_LIKE(sm.sm_code, '^SM[0-9]$')
      AND REGEXP_LIKE(td.t_am_pm, 'PM')
)
SELECT
    regexp_extract(web_name, '^([A-Za-z]+)', 1) AS site_prefix,
    web_site_id,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
FROM filtered_sales
GROUP BY
    regexp_extract(web_name, '^([A-Za-z]+)', 1),
    web_site_id
ORDER BY total_net_profit DESC
LIMIT 100
