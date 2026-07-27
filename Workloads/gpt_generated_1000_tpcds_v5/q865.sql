WITH filtered_sales AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        wp.wp_url,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://')
      AND wp.wp_url LIKE '%.com%'
)
SELECT
    regexp_extract(wp_url, '^https?://([^/]+)', 1) AS domain,
    ws_web_site_sk,
    ws_sold_date_sk,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
FROM filtered_sales
JOIN web_site we ON filtered_sales.ws_web_site_sk = we.web_site_sk
WHERE we.web_name LIKE 'A%'
GROUP BY
    regexp_extract(wp_url, '^https?://([^/]+)', 1),
    ws_web_site_sk,
    ws_sold_date_sk
ORDER BY total_net_profit DESC
LIMIT 100
