WITH sales_page AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        wp.wp_url,
        wp.wp_type,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        CONCAT(w.w_city, ', ', w.w_state) AS warehouse_location,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        CASE
            WHEN regexp_like(wp.wp_url, '\\.pdf$') THEN 'PDF'
            ELSE 'Other'
        END AS url_type
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wp.wp_url LIKE 'http%'
      AND regexp_like(wp.wp_url, 'product')
)
SELECT
    warehouse_location,
    domain,
    url_type,
    wp_type,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    RANK() OVER (PARTITION BY warehouse_location ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
FROM sales_page
GROUP BY
    warehouse_location,
    domain,
    url_type,
    wp_type
ORDER BY total_net_paid DESC
LIMIT 100
