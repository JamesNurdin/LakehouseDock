WITH page_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_order_number,
        ws.ws_item_sk,
        wp.wp_url,
        wp.wp_type,
        (
            SELECT COUNT(*)
            FROM web_returns r
            WHERE r.wr_order_number = ws.ws_order_number
        ) AS return_cnt
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        regexp_like(wp.wp_url, '^https?://[^/]*example\\.com')
        AND wp.wp_type LIKE '%general%'
)
SELECT
    w.w_warehouse_name,
    ps.wp_type,
    regexp_extract(ps.wp_url, '^https?://([^/]+)', 1) AS domain,
    SUM(ps.ws_net_profit) AS total_net_profit,
    SUM(ps.ws_quantity) AS total_quantity,
    SUM(ps.return_cnt) AS total_returns,
    CASE
        WHEN SUM(ps.ws_net_profit) > (SELECT avg(ws_net_profit) FROM web_sales) THEN 'Above Avg Profit'
        ELSE 'Below Avg Profit'
    END AS profit_category,
    COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand,
    CONCAT(w.w_warehouse_name, ' - ', ps.wp_type) AS warehouse_page_label
FROM page_sales ps
JOIN warehouse w ON ps.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
) inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY
    w.w_warehouse_name,
    ps.wp_type,
    regexp_extract(ps.wp_url, '^https?://([^/]+)', 1),
    inv.inv_quantity_on_hand,
    CONCAT(w.w_warehouse_name, ' - ', ps.wp_type)
ORDER BY total_net_profit DESC
LIMIT 100
