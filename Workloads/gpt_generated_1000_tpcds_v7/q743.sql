WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        wp.wp_url
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://www\\.foo\\.com')
      AND wp.wp_url LIKE '%foo.com%'
)
SELECT
    ws_filtered.ws_web_site_sk,
    web_site.web_site_id,
    concat(web_site.web_city, '-', web_site.web_state) AS location,
    regexp_extract(ws_filtered.wp_url, 'https?://([^/]+)/', 1) AS domain,
    sum(ws_filtered.ws_net_profit) AS total_net_profit,
    count(DISTINCT ws_filtered.ws_order_number) AS total_orders,
    count(DISTINCT ws_filtered.ws_item_sk) AS distinct_items_sold,
    min(i.i_product_name) AS sample_product_name
FROM filtered_sales ws_filtered
JOIN web_site ON ws_filtered.ws_web_site_sk = web_site.web_site_sk
JOIN item i ON ws_filtered.ws_item_sk = i.i_item_sk
WHERE web_site.web_name LIKE 'A%'
GROUP BY
    ws_filtered.ws_web_site_sk,
    web_site.web_site_id,
    concat(web_site.web_city, '-', web_site.web_state),
    regexp_extract(ws_filtered.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_net_profit DESC
LIMIT 10
