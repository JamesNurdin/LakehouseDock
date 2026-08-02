WITH filtered_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(p.p_channel_details, '(?i)high')
      AND wp.wp_web_page_id LIKE 'AAAAAA%C%'
      AND ws.ws_quantity > (SELECT MAX(p2.p_cost) FROM promotion p2)
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    COUNT(*) AS sales_count,
    SUM(fs.ws_net_profit) AS total_profit,
    CONCAT(w.w_warehouse_name, ' - ', p.p_promo_name) AS warehouse_promo_label,
    SUBSTRING(p.p_promo_name, 1, 10) AS promo_name_prefix,
    REGEXP_EXTRACT(p.p_channel_details, '(?i)(high\\s\\w+)', 1) AS high_phrase
FROM filtered_sales fs
JOIN promotion p ON fs.ws_promo_sk = p.p_promo_sk
JOIN warehouse w ON fs.ws_warehouse_sk = w.w_warehouse_sk
GROUP BY
    w.w_warehouse_name,
    p.p_promo_name,
    CONCAT(w.w_warehouse_name, ' - ', p.p_promo_name),
    SUBSTRING(p.p_promo_name, 1, 10),
    REGEXP_EXTRACT(p.p_channel_details, '(?i)(high\\s\\w+)', 1)
ORDER BY total_profit DESC
LIMIT 100
